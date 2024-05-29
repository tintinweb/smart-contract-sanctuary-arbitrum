// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import { Multicall } from "openzeppelin-contracts/utils/Multicall.sol";
import { TwabController } from "pt-v5-twab-controller/TwabController.sol";

import { ITwabRewards, Promotion } from "./interfaces/ITwabRewards.sol";

/* ============ Custom Errors ============ */

/// @notice Thrown when the TwabController address set in the constructor is the zero address.
error TwabControllerZeroAddress();

/// @notice Thrown when a promotion is created with an emission of zero tokens per epoch.
error ZeroTokensPerEpoch();

/// @notice Thrown when a promotion is created with an epoch duration of zero.
error ZeroEpochDuration();

/// @notice Thrown when the number of epochs is zero when it must be greater than zero.
error ZeroEpochs();

/// @notice Thrown if the tokens received at the creation of a promotion is less than the expected amount.
/// @param received The amount of tokens received
/// @param expected The expected amount of tokens
error TokensReceivedLessThanExpected(uint256 received, uint256 expected);

/// @notice Thrown if the address to receive tokens from ending or destroying a promotion is the zero address.
error PayeeZeroAddress();

/// @notice Thrown if an action cannot be completed while the grace period is active.
/// @param gracePeriodEndTimestamp The end timestamp of the grace period
error GracePeriodActive(uint256 gracePeriodEndTimestamp);

/// @notice Thrown if a promotion extension would exceed the max number of epochs.
/// @param epochExtension The number of epochs to extend the promotion by
/// @param currentEpochs The current number of epochs in the promotion
/// @param maxEpochs The max number of epochs that a promotion can have
error ExceedsMaxEpochs(uint8 epochExtension, uint8 currentEpochs, uint8 maxEpochs);

/// @notice Thrown if rewards for the promotion epoch have already been claimed by the user.
/// @param promotionId The ID of the promotion
/// @param user The address of the user that the rewards are being claimed for
/// @param epochId The epoch that rewards are being claimed from
error RewardsAlreadyClaimed(uint256 promotionId, address user, uint8 epochId);

/// @notice Thrown if a promotion is no longer active.
/// @param promotionId The ID of the promotion
error PromotionInactive(uint256 promotionId);

/// @notice Thrown if the sender is not the promotion creator on a creator-only action.
/// @param sender The address of the sender
/// @param creator The address of the creator
error OnlyPromotionCreator(address sender, address creator);

/// @notice Thrown if the promotion is invalid or not initialized.
/// @param promotionId The ID of the promotion
error InvalidPromotion(uint256 promotionId);

/// @notice Thrown if the rewards for an epoch are being claimed before the epoch is over.
/// @param epochEndTimestamp The time at which the epoch will end
error EpochNotOver(uint64 epochEndTimestamp);

/// @notice Thrown if an epoch is outside the range of epochs in a promotion.
/// @param epochId The ID of the epoch
/// @param numberOfEpochs The number of epochs in the promotion
error InvalidEpochId(uint8 epochId, uint8 numberOfEpochs);

/// @notice Thrown if an epoch duration is not a multiple of the TWAB period length.
/// @param epochDuration The duration of the epoch in seconds
/// @param twabPeriodLength The duration of the TWAB period in seconds
error EpochDurationNotMultipleOfTwabPeriod(uint48 epochDuration, uint32 twabPeriodLength);

/// @notice Thrown if a promotion start time is not aligned with the start of a TWAB period.
/// @param startTimePeriodOffset The offset in seconds of the promotion start time from the start of the TWAB period it succeeds
error StartTimeNotAlignedWithTwabPeriod(uint64 startTimePeriodOffset);

/**
 * @title PoolTogether V5 TwabRewards
 * @author PoolTogether Inc. & G9 Software Inc.
 * @notice Contract to distribute rewards to depositors in a PoolTogether V5 Vault.
 * This contract supports the creation of several promotions that can run simultaneously.
 * In order to calculate user rewards, we use the TWAB (Time-Weighted Average Balance) for the vault and depositor.
 * This way, users simply need to hold their vault tokens to be eligible to claim rewards.
 * Rewards are calculated based on the average amount of vault tokens they hold during the epoch duration.
 * @dev This contract does not support the use of fee on transfer tokens.
 */
contract TwabRewards is ITwabRewards, Multicall {
    using SafeERC20 for IERC20;

    /* ============ Global Variables ============ */

    /// @notice TwabController contract from which the promotions read time-weighted average balances from.
    TwabController public immutable twabController;

    /// @notice Period during which the promotion owner can't destroy a promotion.
    uint32 public constant GRACE_PERIOD = 60 days;

    /// @notice Settings of each promotion.
    mapping(uint256 => Promotion) internal _promotions;

    /**
     * @notice Latest recorded promotion id.
     * @dev Starts at 0 and is incremented by 1 for each new promotion. So the first promotion will have id 1, the second 2, etc.
     */
    uint256 internal _latestPromotionId;

    /**
     * @notice Keeps track of claimed rewards per user.
     * @dev _claimedEpochs[promotionId][user] => claimedEpochs
     * @dev We pack epochs claimed by a user into a uint256. So we can't store more than 256 epochs.
     */
    mapping(uint256 => mapping(address => uint256)) internal _claimedEpochs;

    /* ============ Events ============ */

    /**
     * @notice Emitted when a promotion is created.
     * @param promotionId Id of the newly created promotion
     * @param vault The address of the vault that the promotion applies to
     * @param token The token that will be rewarded from the promotion
     * @param startTimestamp The timestamp at which the promotion starts
     * @param tokensPerEpoch The number of tokens emitted per epoch
     * @param epochDuration The duration of epoch in seconds
     * @param initialNumberOfEpochs The initial number of epochs the promotion is set to run for
     */
    event PromotionCreated(
        uint256 indexed promotionId,
        address indexed vault,
        IERC20 indexed token,
        uint64 startTimestamp,
        uint256 tokensPerEpoch,
        uint48 epochDuration,
        uint8 initialNumberOfEpochs
    );

    /**
     * @notice Emitted when a promotion is ended.
     * @param promotionId Id of the promotion being ended
     * @param recipient Address of the recipient that will receive the remaining rewards
     * @param amount Amount of tokens transferred to the recipient
     * @param epochNumber Epoch number at which the promotion ended
     */
    event PromotionEnded(uint256 indexed promotionId, address indexed recipient, uint256 amount, uint8 epochNumber);

    /**
     * @notice Emitted when a promotion is destroyed.
     * @param promotionId Id of the promotion being destroyed
     * @param recipient Address of the recipient that will receive the unclaimed rewards
     * @param amount Amount of tokens transferred to the recipient
     */
    event PromotionDestroyed(uint256 indexed promotionId, address indexed recipient, uint256 amount);

    /**
     * @notice Emitted when a promotion is extended.
     * @param promotionId Id of the promotion being extended
     * @param numberOfEpochs Number of epochs the promotion has been extended by
     */
    event PromotionExtended(uint256 indexed promotionId, uint256 numberOfEpochs);

    /**
     * @notice Emitted when rewards have been claimed.
     * @param promotionId Id of the promotion for which epoch rewards were claimed
     * @param epochIds Ids of the epochs being claimed
     * @param user Address of the user for which the rewards were claimed
     * @param amount Amount of tokens transferred to the recipient address
     */
    event RewardsClaimed(uint256 indexed promotionId, uint8[] epochIds, address indexed user, uint256 amount);

    /* ============ Constructor ============ */

    /**
     * @notice Constructor of the contract.
     * @param _twabController The TwabController contract to reference for vault balance and supply
     */
    constructor(TwabController _twabController) {
        if (address(0) == address(_twabController)) revert TwabControllerZeroAddress();
        twabController = _twabController;
    }

    /* ============ External Functions ============ */

    /**
     * @inheritdoc ITwabRewards
     * @dev For sake of simplicity, `msg.sender` will be the creator of the promotion.
     * @dev `_latestPromotionId` starts at 0 and is incremented by 1 for each new promotion.
     * So the first promotion will have id 1, the second 2, etc.
     * @dev The transaction will revert if the amount of reward tokens provided is not equal to `_tokensPerEpoch * _numberOfEpochs`.
     * This scenario could happen if the token supplied is a fee on transfer one.
     */
    function createPromotion(
        address _vault,
        IERC20 _token,
        uint64 _startTimestamp,
        uint256 _tokensPerEpoch,
        uint48 _epochDuration,
        uint8 _numberOfEpochs
    ) external override returns (uint256) {
        if (_tokensPerEpoch == 0) revert ZeroTokensPerEpoch();
        if (_epochDuration == 0) revert ZeroEpochDuration();
        _requireNumberOfEpochs(_numberOfEpochs);

        uint32 _twabPeriodLength = twabController.PERIOD_LENGTH();
        if (_epochDuration % _twabPeriodLength != 0)
            revert EpochDurationNotMultipleOfTwabPeriod(_epochDuration, _twabPeriodLength);
        uint64 _startTimePeriodOffset = (_startTimestamp - twabController.PERIOD_OFFSET()) % _twabPeriodLength;
        if (_startTimePeriodOffset != 0) revert StartTimeNotAlignedWithTwabPeriod(_startTimePeriodOffset);

        uint256 _nextPromotionId = _latestPromotionId + 1;
        _latestPromotionId = _nextPromotionId;

        uint256 _amount = _tokensPerEpoch * _numberOfEpochs;

        _promotions[_nextPromotionId] = Promotion({
            creator: msg.sender,
            startTimestamp: _startTimestamp,
            numberOfEpochs: _numberOfEpochs,
            vault: _vault,
            epochDuration: _epochDuration,
            createdAt: uint48(block.timestamp),
            token: _token,
            tokensPerEpoch: _tokensPerEpoch,
            rewardsUnclaimed: _amount
        });

        uint256 _beforeBalance = _token.balanceOf(address(this));

        _token.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _afterBalance = _token.balanceOf(address(this));

        if (_afterBalance < _beforeBalance + _amount)
            revert TokensReceivedLessThanExpected(_afterBalance - _beforeBalance, _amount);

        emit PromotionCreated(
            _nextPromotionId,
            _vault,
            _token,
            _startTimestamp,
            _tokensPerEpoch,
            _epochDuration,
            _numberOfEpochs
        );

        return _nextPromotionId;
    }

    /// @inheritdoc ITwabRewards
    function endPromotion(uint256 _promotionId, address _to) external override returns (bool) {
        if (address(0) == _to) revert PayeeZeroAddress();

        Promotion memory _promotion = _getPromotion(_promotionId);
        _requirePromotionCreator(_promotion);
        _requirePromotionActive(_promotionId, _promotion);

        uint8 _epochNumber = uint8(_getCurrentEpochId(_promotion));
        _promotions[_promotionId].numberOfEpochs = _epochNumber;

        uint256 _remainingRewards = _getRemainingRewards(_promotion);
        _promotions[_promotionId].rewardsUnclaimed -= _remainingRewards;

        _promotion.token.safeTransfer(_to, _remainingRewards);

        emit PromotionEnded(_promotionId, _to, _remainingRewards, _epochNumber);

        return true;
    }

    /// @inheritdoc ITwabRewards
    function destroyPromotion(uint256 _promotionId, address _to) external override returns (bool) {
        if (address(0) == _to) revert PayeeZeroAddress();

        Promotion memory _promotion = _getPromotion(_promotionId);
        _requirePromotionCreator(_promotion);

        uint256 _promotionEndTimestamp = _getPromotionEndTimestamp(_promotion);
        uint256 _promotionCreatedAt = _promotion.createdAt;

        uint256 _gracePeriodEndTimestamp = (
            _promotionEndTimestamp < _promotionCreatedAt ? _promotionCreatedAt : _promotionEndTimestamp
        ) + GRACE_PERIOD;

        if (block.timestamp < _gracePeriodEndTimestamp) revert GracePeriodActive(_gracePeriodEndTimestamp);

        uint256 _rewardsUnclaimed = _promotion.rewardsUnclaimed;
        delete _promotions[_promotionId];

        _promotion.token.safeTransfer(_to, _rewardsUnclaimed);

        emit PromotionDestroyed(_promotionId, _to, _rewardsUnclaimed);

        return true;
    }

    /// @inheritdoc ITwabRewards
    function extendPromotion(uint256 _promotionId, uint8 _numberOfEpochs) external override returns (bool) {
        _requireNumberOfEpochs(_numberOfEpochs);

        Promotion memory _promotion = _getPromotion(_promotionId);
        _requirePromotionActive(_promotionId, _promotion);

        uint8 _currentNumberOfEpochs = _promotion.numberOfEpochs;

        if (_numberOfEpochs > (type(uint8).max - _currentNumberOfEpochs))
            revert ExceedsMaxEpochs(_numberOfEpochs, _currentNumberOfEpochs, type(uint8).max);

        _promotions[_promotionId].numberOfEpochs = _currentNumberOfEpochs + _numberOfEpochs;

        uint256 _amount = _numberOfEpochs * _promotion.tokensPerEpoch;

        _promotions[_promotionId].rewardsUnclaimed += _amount;
        _promotion.token.safeTransferFrom(msg.sender, address(this), _amount);

        emit PromotionExtended(_promotionId, _numberOfEpochs);

        return true;
    }

    /// @inheritdoc ITwabRewards
    function claimRewards(
        address _user,
        uint256 _promotionId,
        uint8[] calldata _epochIds
    ) external override returns (uint256) {
        Promotion memory _promotion = _getPromotion(_promotionId);

        uint256 _rewardsAmount;
        uint256 _userClaimedEpochs = _claimedEpochs[_promotionId][_user];
        uint256 _epochIdsLength = _epochIds.length;

        for (uint256 index = 0; index < _epochIdsLength; index++) {
            uint8 _epochId = _epochIds[index];

            if (_isClaimedEpoch(_userClaimedEpochs, _epochId))
                revert RewardsAlreadyClaimed(_promotionId, _user, _epochId);

            _rewardsAmount += _calculateRewardAmount(_user, _promotion, _epochId);
            _userClaimedEpochs = _updateClaimedEpoch(_userClaimedEpochs, _epochId);
        }

        _claimedEpochs[_promotionId][_user] = _userClaimedEpochs;
        _promotions[_promotionId].rewardsUnclaimed -= _rewardsAmount;

        _promotion.token.safeTransfer(_user, _rewardsAmount);

        emit RewardsClaimed(_promotionId, _epochIds, _user, _rewardsAmount);

        return _rewardsAmount;
    }

    /// @inheritdoc ITwabRewards
    function getPromotion(uint256 _promotionId) external view override returns (Promotion memory) {
        return _getPromotion(_promotionId);
    }

    /// @inheritdoc ITwabRewards
    /// @dev Epoch ids and their boolean values are tightly packed and stored in a uint256, so epoch id starts at 0.
    function getCurrentEpochId(uint256 _promotionId) external view override returns (uint256) {
        return _getCurrentEpochId(_getPromotion(_promotionId));
    }

    /// @inheritdoc ITwabRewards
    function getRemainingRewards(uint256 _promotionId) external view override returns (uint256) {
        return _getRemainingRewards(_getPromotion(_promotionId));
    }

    /// @inheritdoc ITwabRewards
    function getRewardsAmount(
        address _user,
        uint256 _promotionId,
        uint8[] calldata _epochIds
    ) external view override returns (uint256[] memory) {
        Promotion memory _promotion = _getPromotion(_promotionId);

        uint256 _epochIdsLength = _epochIds.length;
        uint256[] memory _rewardsAmount = new uint256[](_epochIdsLength);

        for (uint256 index = 0; index < _epochIdsLength; index++) {
            if (_isClaimedEpoch(_claimedEpochs[_promotionId][_user], _epochIds[index])) {
                _rewardsAmount[index] = 0;
            } else {
                _rewardsAmount[index] = _calculateRewardAmount(_user, _promotion, _epochIds[index]);
            }
        }

        return _rewardsAmount;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Allow a promotion to be created or extended only by a positive number of epochs.
     * @param _numberOfEpochs Number of epochs to check
     */
    function _requireNumberOfEpochs(uint8 _numberOfEpochs) internal pure {
        if (0 == _numberOfEpochs) revert ZeroEpochs();
    }

    /**
     * @notice Requires that a promotion is active.
     * @param _promotion Promotion to check
     */
    function _requirePromotionActive(uint256 _promotionId, Promotion memory _promotion) internal view {
        if (_getPromotionEndTimestamp(_promotion) <= block.timestamp) revert PromotionInactive(_promotionId);
    }

    /**
     * @notice Requires that msg.sender is the promotion creator.
     * @param _promotion Promotion to check
     */
    function _requirePromotionCreator(Promotion memory _promotion) internal view {
        if (msg.sender != _promotion.creator) revert OnlyPromotionCreator(msg.sender, _promotion.creator);
    }

    /**
     * @notice Get settings for a specific promotion.
     * @dev Will revert if the promotion does not exist.
     * @param _promotionId Promotion id to get settings for
     * @return Promotion settings
     */
    function _getPromotion(uint256 _promotionId) internal view returns (Promotion memory) {
        Promotion memory _promotion = _promotions[_promotionId];
        if (address(0) == _promotion.creator) revert InvalidPromotion(_promotionId);
        return _promotion;
    }

    /**
     * @notice Compute promotion end timestamp.
     * @param _promotion Promotion to compute end timestamp for
     * @return Promotion end timestamp
     */
    function _getPromotionEndTimestamp(Promotion memory _promotion) internal pure returns (uint256) {
        unchecked {
            return _promotion.startTimestamp + (_promotion.epochDuration * _promotion.numberOfEpochs);
        }
    }

    /**
     * @notice Get the current epoch id of a promotion.
     * @dev Epoch ids and their boolean values are tightly packed and stored in a uint256, so epoch id starts at 0.
     * @dev We return the current epoch id if the promotion has not ended.
     * If the current timestamp is before the promotion start timestamp, we return 0.
     * Otherwise, we return the epoch id at the current timestamp. This could be greater than the number of epochs of the promotion.
     * @param _promotion Promotion to get current epoch for
     * @return Epoch id
     */
    function _getCurrentEpochId(Promotion memory _promotion) internal view returns (uint256) {
        uint256 _currentEpochId;

        if (block.timestamp > _promotion.startTimestamp) {
            unchecked {
                _currentEpochId = (block.timestamp - _promotion.startTimestamp) / _promotion.epochDuration;
            }
        }

        return _currentEpochId;
    }

    /**
     * @notice Get reward amount for a specific user.
     * @dev Rewards can only be calculated once the epoch is over.
     * @dev Will revert if `_epochId` is over the total number of epochs or if epoch is not over.
     * @dev Will return 0 if the user average balance in the vault is 0.
     * @param _user User to get reward amount for
     * @param _promotion Promotion from which the epoch is
     * @param _epochId Epoch id to get reward amount for
     * @return Reward amount
     */
    function _calculateRewardAmount(
        address _user,
        Promotion memory _promotion,
        uint8 _epochId
    ) internal view returns (uint256) {
        uint64 _epochDuration = _promotion.epochDuration;
        uint64 _epochStartTimestamp = _promotion.startTimestamp + (_epochDuration * _epochId);
        uint64 _epochEndTimestamp = _epochStartTimestamp + _epochDuration;

        if (block.timestamp < _epochEndTimestamp) revert EpochNotOver(_epochEndTimestamp);
        if (_epochId >= _promotion.numberOfEpochs) revert InvalidEpochId(_epochId, _promotion.numberOfEpochs);

        uint256 _averageBalance = twabController.getTwabBetween(
            _promotion.vault,
            _user,
            _epochStartTimestamp,
            _epochEndTimestamp
        );

        if (_averageBalance > 0) {
            uint256 _averageTotalSupply = twabController.getTotalSupplyTwabBetween(
                _promotion.vault,
                _epochStartTimestamp,
                _epochEndTimestamp
            );
            return (_promotion.tokensPerEpoch * _averageBalance) / _averageTotalSupply;
        }

        return 0;
    }

    /**
     * @notice Get the total amount of tokens left to be rewarded.
     * @param _promotion Promotion to get the total amount of tokens left to be rewarded for
     * @return Amount of tokens left to be rewarded
     */
    function _getRemainingRewards(Promotion memory _promotion) internal view returns (uint256) {
        if (block.timestamp >= _getPromotionEndTimestamp(_promotion)) {
            return 0;
        }

        return _promotion.tokensPerEpoch * (_promotion.numberOfEpochs - _getCurrentEpochId(_promotion));
    }

    /**
    * @notice Set boolean value for a specific epoch.
    * @dev Bits are stored in a uint256 from right to left.
        Let's take the example of the following 8 bits word. 0110 0011
        To set the boolean value to 1 for the epoch id 2, we need to create a mask by shifting 1 to the left by 2 bits.
        We get: 0000 0001 << 2 = 0000 0100
        We then OR the mask with the word to set the value.
        We get: 0110 0011 | 0000 0100 = 0110 0111
    * @param _userClaimedEpochs Tightly packed epoch ids with their boolean values
    * @param _epochId Id of the epoch to set the boolean for
    * @return Tightly packed epoch ids with the newly boolean value set
    */
    function _updateClaimedEpoch(uint256 _userClaimedEpochs, uint8 _epochId) internal pure returns (uint256) {
        return _userClaimedEpochs | (uint256(1) << _epochId);
    }

    /**
    * @notice Check if rewards of an epoch for a given promotion have already been claimed by the user.
    * @dev Bits are stored in a uint256 from right to left.
        Let's take the example of the following 8 bits word. 0110 0111
        To retrieve the boolean value for the epoch id 2, we need to shift the word to the right by 2 bits.
        We get: 0110 0111 >> 2 = 0001 1001
        We then get the value of the last bit by masking with 1.
        We get: 0001 1001 & 0000 0001 = 0000 0001 = 1
        We then return the boolean value true since the last bit is 1.
    * @param _userClaimedEpochs Record of epochs already claimed by the user
    * @param _epochId Epoch id to check
    * @return true if the rewards have already been claimed for the given epoch, false otherwise
     */
    function _isClaimedEpoch(uint256 _userClaimedEpochs, uint8 _epochId) internal pure returns (bool) {
        return (_userClaimedEpochs >> _epochId) & uint256(1) == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.5) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Context.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * Consider any assumption about calldata validation performed by the sender may be violated if it's not especially
 * careful about sending transactions invoking {multicall}. For example, a relay address that filters function
 * selectors won't filter calls nested within a {multicall} operation.
 *
 * NOTE: Since 5.0.1 and 4.9.4, this contract identifies non-canonical contexts (i.e. `msg.sender` is not {_msgSender}).
 * If a non-canonical context is identified, the following self `delegatecall` appends the last bytes of `msg.data`
 * to the subcall. This makes it safe to use with {ERC2771Context}. Contexts that don't affect the resolution of
 * {_msgSender} are not propagated to subcalls.
 *
 * _Available since v4.1._
 */
abstract contract Multicall is Context {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        bytes memory context = msg.sender == _msgSender()
            ? new bytes(0)
            : msg.data[msg.data.length - _contextSuffixLength():];

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), bytes.concat(data[i], context));
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";
import { TwabLib } from "./libraries/TwabLib.sol";
import { ObservationLib } from "./libraries/ObservationLib.sol";

/// @notice Emitted when an account already points to the same delegate address that is being set
error SameDelegateAlreadySet(address delegate);

/// @notice Emitted when an account tries to transfer to the sponsorship address
error CannotTransferToSponsorshipAddress();

/// @notice Emitted when the period length is too short
error PeriodLengthTooShort();

/// @notice Emitted when the period offset is not in the past.
/// @param periodOffset The period offset that was passed in
error PeriodOffsetInFuture(uint32 periodOffset);

/// @notice Emitted when a user tries to mint or transfer to the zero address
error TransferToZeroAddress();

// The minimum period length
uint32 constant MINIMUM_PERIOD_LENGTH = 1 hours;

// Allows users to revoke their chances to win by delegating to the sponsorship address.
address constant SPONSORSHIP_ADDRESS = address(1);

/**
 * @title  PoolTogether V5 Time-Weighted Average Balance Controller
 * @author PoolTogether Inc. & G9 Software Inc.
 * @dev    Time-Weighted Average Balance Controller for ERC20 tokens.
 * @notice This TwabController uses the TwabLib to provide token balances and on-chain historical
            lookups to a user(s) time-weighted average balance. Each user is mapped to an
            Account struct containing the TWAB history (ring buffer) and ring buffer parameters.
            Every token.transfer() creates a new TWAB observation. The new TWAB observation is
            stored in the circular ring buffer as either a new observation or rewriting a
            previous observation with new parameters. One observation per period is stored.
            The TwabLib guarantees minimum 1 year of search history if a period is a day.
 */
contract TwabController {
  using SafeCast for uint256;

  /// @notice Sets the minimum period length for Observations. When a period elapses, a new Observation is recorded, otherwise the most recent Observation is updated.
  uint32 public immutable PERIOD_LENGTH;

  /// @notice Sets the beginning timestamp for the first period. This allows us to maximize storage as well as line up periods with a chosen timestamp.
  /// @dev Ensure that the PERIOD_OFFSET is in the past.
  uint32 public immutable PERIOD_OFFSET;

  /* ============ State ============ */

  /// @notice Record of token holders TWABs for each account for each vault.
  mapping(address => mapping(address => TwabLib.Account)) internal userObservations;

  /// @notice Record of tickets total supply and ring buff parameters used for observation.
  mapping(address => TwabLib.Account) internal totalSupplyObservations;

  /// @notice vault => user => delegate.
  mapping(address => mapping(address => address)) internal delegates;

  /* ============ Events ============ */

  /**
   * @notice Emitted when a balance or delegateBalance is increased.
   * @param vault the vault for which the balance increased
   * @param user the users whose balance increased
   * @param amount the amount the balance increased by
   * @param delegateAmount the amount the delegateBalance increased by
   */
  event IncreasedBalance(
    address indexed vault,
    address indexed user,
    uint96 amount,
    uint96 delegateAmount
  );

  /**
   * @notice Emitted when a balance or delegateBalance is decreased.
   * @param vault the vault for which the balance decreased
   * @param user the users whose balance decreased
   * @param amount the amount the balance decreased by
   * @param delegateAmount the amount the delegateBalance decreased by
   */
  event DecreasedBalance(
    address indexed vault,
    address indexed user,
    uint96 amount,
    uint96 delegateAmount
  );

  /**
   * @notice Emitted when an Observation is recorded to the Ring Buffer.
   * @param vault the vault for which the Observation was recorded
   * @param user the users whose Observation was recorded
   * @param balance the resulting balance
   * @param delegateBalance the resulting delegated balance
   * @param isNew whether the observation is new or not
   * @param observation the observation that was created or updated
   */
  event ObservationRecorded(
    address indexed vault,
    address indexed user,
    uint96 balance,
    uint96 delegateBalance,
    bool isNew,
    ObservationLib.Observation observation
  );

  /**
   * @notice Emitted when a user delegates their balance to another address.
   * @param vault the vault for which the balance was delegated
   * @param delegator the user who delegated their balance
   * @param delegate the user who received the delegated balance
   */
  event Delegated(address indexed vault, address indexed delegator, address indexed delegate);

  /**
   * @notice Emitted when the total supply or delegateTotalSupply is increased.
   * @param vault the vault for which the total supply increased
   * @param amount the amount the total supply increased by
   * @param delegateAmount the amount the delegateTotalSupply increased by
   */
  event IncreasedTotalSupply(address indexed vault, uint96 amount, uint96 delegateAmount);

  /**
   * @notice Emitted when the total supply or delegateTotalSupply is decreased.
   * @param vault the vault for which the total supply decreased
   * @param amount the amount the total supply decreased by
   * @param delegateAmount the amount the delegateTotalSupply decreased by
   */
  event DecreasedTotalSupply(address indexed vault, uint96 amount, uint96 delegateAmount);

  /**
   * @notice Emitted when a Total Supply Observation is recorded to the Ring Buffer.
   * @param vault the vault for which the Observation was recorded
   * @param balance the resulting balance
   * @param delegateBalance the resulting delegated balance
   * @param isNew whether the observation is new or not
   * @param observation the observation that was created or updated
   */
  event TotalSupplyObservationRecorded(
    address indexed vault,
    uint96 balance,
    uint96 delegateBalance,
    bool isNew,
    ObservationLib.Observation observation
  );

  /* ============ Constructor ============ */

  /**
   * @notice Construct a new TwabController.
   * @dev Reverts if the period offset is in the future.
   * @param _periodLength Sets the minimum period length for Observations. When a period elapses, a new Observation
   *      is recorded, otherwise the most recent Observation is updated.
   * @param _periodOffset Sets the beginning timestamp for the first period. This allows us to maximize storage as well
   *      as line up periods with a chosen timestamp.
   */
  constructor(uint32 _periodLength, uint32 _periodOffset) {
    if (_periodLength < MINIMUM_PERIOD_LENGTH) {
      revert PeriodLengthTooShort();
    }
    if (_periodOffset > block.timestamp) {
      revert PeriodOffsetInFuture(_periodOffset);
    }
    PERIOD_LENGTH = _periodLength;
    PERIOD_OFFSET = _periodOffset;
  }

  /* ============ External Read Functions ============ */

  /**
   * @notice Returns whether the TwabController has been shutdown at the given timestamp
   * If the twab is queried at or after this time, whether an absolute timestamp or time range, it will return 0.
   * @dev This function will return true for any timestamp after the lastObservationAt()
   * @param timestamp The timestamp to check
   * @return True if the TwabController is shutdown at the given timestamp, false otherwise.
   */
  function isShutdownAt(uint256 timestamp) external view returns (bool) {
    return TwabLib.isShutdownAt(timestamp, PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Computes the timestamp after which no more observations will be made.
   * @return The largest timestamp at which the TwabController can record a new observation.
   */
  function lastObservationAt() external view returns (uint256) {
    return TwabLib.lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Loads the current TWAB Account data for a specific vault stored for a user.
   * @dev Note this is a very expensive function
   * @param vault the vault for which the data is being queried
   * @param user the user whose data is being queried
   * @return The current TWAB Account data of the user
   */
  function getAccount(address vault, address user) external view returns (TwabLib.Account memory) {
    return userObservations[vault][user];
  }

  /**
   * @notice Loads the current total supply TWAB Account data for a specific vault.
   * @dev Note this is a very expensive function
   * @param vault the vault for which the data is being queried
   * @return The current total supply TWAB Account data
   */
  function getTotalSupplyAccount(address vault) external view returns (TwabLib.Account memory) {
    return totalSupplyObservations[vault];
  }

  /**
   * @notice The current token balance of a user for a specific vault.
   * @param vault the vault for which the balance is being queried
   * @param user the user whose balance is being queried
   * @return The current token balance of the user
   */
  function balanceOf(address vault, address user) external view returns (uint256) {
    return userObservations[vault][user].details.balance;
  }

  /**
   * @notice The total supply of tokens for a vault.
   * @param vault the vault for which the total supply is being queried
   * @return The total supply of tokens for a vault
   */
  function totalSupply(address vault) external view returns (uint256) {
    return totalSupplyObservations[vault].details.balance;
  }

  /**
   * @notice The total delegated amount of tokens for a vault.
   * @dev Delegated balance is not 1:1 with the token total supply. Users may delegate their
   *      balance to the sponsorship address, which will result in those tokens being subtracted
   *      from the total.
   * @param vault the vault for which the total delegated supply is being queried
   * @return The total delegated amount of tokens for a vault
   */
  function totalSupplyDelegateBalance(address vault) external view returns (uint256) {
    return totalSupplyObservations[vault].details.delegateBalance;
  }

  /**
   * @notice The current delegate of a user for a specific vault.
   * @param vault the vault for which the delegate balance is being queried
   * @param user the user whose delegate balance is being queried
   * @return The current delegate balance of the user
   */
  function delegateOf(address vault, address user) external view returns (address) {
    return _delegateOf(vault, user);
  }

  /**
   * @notice The current delegateBalance of a user for a specific vault.
   * @dev the delegateBalance is the sum of delegated balance to this user
   * @param vault the vault for which the delegateBalance is being queried
   * @param user the user whose delegateBalance is being queried
   * @return The current delegateBalance of the user
   */
  function delegateBalanceOf(address vault, address user) external view returns (uint256) {
    return userObservations[vault][user].details.delegateBalance;
  }

  /**
   * @notice Looks up a users balance at a specific time in the past.
   * @param vault the vault for which the balance is being queried
   * @param user the user whose balance is being queried
   * @param periodEndOnOrAfterTime The time in the past for which the balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @return The balance of the user at the target time
   */
  function getBalanceAt(
    address vault,
    address user,
    uint256 periodEndOnOrAfterTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = userObservations[vault][user];
    return
      TwabLib.getBalanceAt(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(periodEndOnOrAfterTime)
      );
  }

  /**
   * @notice Looks up the total supply at a specific time in the past.
   * @param vault the vault for which the total supply is being queried
   * @param periodEndOnOrAfterTime The time in the past for which the balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @return The total supply at the target time
   */
  function getTotalSupplyAt(
    address vault,
    uint256 periodEndOnOrAfterTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    return
      TwabLib.getBalanceAt(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(periodEndOnOrAfterTime)
      );
  }

  /**
   * @notice Looks up the average balance of a user between two timestamps.
   * @dev Timestamps are Unix timestamps denominated in seconds
   * @param vault the vault for which the average balance is being queried
   * @param user the user whose average balance is being queried
   * @param startTime the start of the time range for which the average balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @param endTime the end of the time range for which the average balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @return The average balance of the user between the two timestamps
   */
  function getTwabBetween(
    address vault,
    address user,
    uint256 startTime,
    uint256 endTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = userObservations[vault][user];
    // We snap the timestamps to the period end on or after the timestamp because the total supply records will be sparsely populated.
    // if two users update during a period, then the total supply observation will only exist for the last one.
    return
      TwabLib.getTwabBetween(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(startTime),
        _periodEndOnOrAfter(endTime)
      );
  }

  /**
   * @notice Looks up the average total supply between two timestamps.
   * @dev Timestamps are Unix timestamps denominated in seconds
   * @param vault the vault for which the average total supply is being queried
   * @param startTime the start of the time range for which the average total supply is being queried
   * @param endTime the end of the time range for which the average total supply is being queried
   * @return The average total supply between the two timestamps
   */
  function getTotalSupplyTwabBetween(
    address vault,
    uint256 startTime,
    uint256 endTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    // We snap the timestamps to the period end on or after the timestamp because the total supply records will be sparsely populated.
    // if two users update during a period, then the total supply observation will only exist for the last one.
    return
      TwabLib.getTwabBetween(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(startTime),
        _periodEndOnOrAfter(endTime)
      );
  }

  /**
   * @notice Computes the period end timestamp on or after the given timestamp.
   * @param _timestamp The timestamp to check
   * @return The end timestamp of the period that ends on or immediately after the given timestamp
   */
  function periodEndOnOrAfter(uint256 _timestamp) external view returns (uint256) {
    return _periodEndOnOrAfter(_timestamp);
  }

  /**
   * @notice Computes the period end timestamp on or after the given timestamp.
   * @param _timestamp The timestamp to compute the period end time for
   * @return A period end time.
   */
  function _periodEndOnOrAfter(uint256 _timestamp) internal view returns (uint256) {
    if (_timestamp < PERIOD_OFFSET) {
      return PERIOD_OFFSET;
    }
    if ((_timestamp - PERIOD_OFFSET) % PERIOD_LENGTH == 0) {
      return _timestamp;
    }
    uint256 period = TwabLib.getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, _timestamp);
    return TwabLib.getPeriodEndTime(PERIOD_LENGTH, PERIOD_OFFSET, period);
  }

  /**
   * @notice Looks up the newest observation for a user.
   * @param vault the vault for which the observation is being queried
   * @param user the user whose observation is being queried
   * @return index The index of the observation
   * @return observation The observation of the user
   */
  function getNewestObservation(
    address vault,
    address user
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = userObservations[vault][user];
    return TwabLib.getNewestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Looks up the oldest observation for a user.
   * @param vault the vault for which the observation is being queried
   * @param user the user whose observation is being queried
   * @return index The index of the observation
   * @return observation The observation of the user
   */
  function getOldestObservation(
    address vault,
    address user
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = userObservations[vault][user];
    return TwabLib.getOldestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Looks up the newest total supply observation for a vault.
   * @param vault the vault for which the observation is being queried
   * @return index The index of the observation
   * @return observation The total supply observation
   */
  function getNewestTotalSupplyObservation(
    address vault
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    return TwabLib.getNewestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Looks up the oldest total supply observation for a vault.
   * @param vault the vault for which the observation is being queried
   * @return index The index of the observation
   * @return observation The total supply observation
   */
  function getOldestTotalSupplyObservation(
    address vault
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    return TwabLib.getOldestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Calculates the period a timestamp falls into.
   * @param time The timestamp to check
   * @return period The period the timestamp falls into
   */
  function getTimestampPeriod(uint256 time) external view returns (uint256) {
    return TwabLib.getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, time);
  }

  /**
   * @notice Checks if the given timestamp is before the current overwrite period.
   * @param time The timestamp to check
   * @return True if the given time is finalized, false if it's during the current overwrite period.
   */
  function hasFinalized(uint256 time) external view returns (bool) {
    return TwabLib.hasFinalized(PERIOD_LENGTH, PERIOD_OFFSET, time);
  }

  /**
   * @notice Computes the timestamp at which the current overwrite period started.
   * @dev The overwrite period is the period during which observations are collated.
   * @return period The timestamp at which the current overwrite period started.
   */
  function currentOverwritePeriodStartedAt() external view returns (uint256) {
    return TwabLib.currentOverwritePeriodStartedAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /* ============ External Write Functions ============ */

  /**
   * @notice Mints new balance and delegateBalance for a given user.
   * @dev Note that if the provided user to mint to is delegating that the delegate's
   *      delegateBalance will be updated.
   * @dev Mint is expected to be called by the Vault.
   * @param _to The address to mint balance and delegateBalance to
   * @param _amount The amount to mint
   */
  function mint(address _to, uint96 _amount) external {
    if (_to == address(0)) {
      revert TransferToZeroAddress();
    }
    _transferBalance(msg.sender, address(0), _to, _amount);
  }

  /**
   * @notice Burns balance and delegateBalance for a given user.
   * @dev Note that if the provided user to burn from is delegating that the delegate's
   *      delegateBalance will be updated.
   * @dev Burn is expected to be called by the Vault.
   * @param _from The address to burn balance and delegateBalance from
   * @param _amount The amount to burn
   */
  function burn(address _from, uint96 _amount) external {
    _transferBalance(msg.sender, _from, address(0), _amount);
  }

  /**
   * @notice Transfers balance and delegateBalance from a given user.
   * @dev Note that if the provided user to transfer from is delegating that the delegate's
   *      delegateBalance will be updated.
   * @param _from The address to transfer the balance and delegateBalance from
   * @param _to The address to transfer balance and delegateBalance to
   * @param _amount The amount to transfer
   */
  function transfer(address _from, address _to, uint96 _amount) external {
    if (_to == address(0)) {
      revert TransferToZeroAddress();
    }
    _transferBalance(msg.sender, _from, _to, _amount);
  }

  /**
   * @notice Sets a delegate for a user which forwards the delegateBalance tied to the user's
   *          balance to the delegate's delegateBalance.
   * @param _vault The vault for which the delegate is being set
   * @param _to the address to delegate to
   */
  function delegate(address _vault, address _to) external {
    _delegate(_vault, msg.sender, _to);
  }

  /**
   * @notice Delegate user balance to the sponsorship address.
   * @dev Must only be called by the Vault contract.
   * @param _from Address of the user delegating their balance to the sponsorship address.
   */
  function sponsor(address _from) external {
    _delegate(msg.sender, _from, SPONSORSHIP_ADDRESS);
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Transfers a user's vault balance from one address to another.
   * @dev If the user is delegating, their delegate's delegateBalance is also updated.
   * @dev If we are minting or burning tokens then the total supply is also updated.
   * @param _vault the vault for which the balance is being transferred
   * @param _from the address from which the balance is being transferred
   * @param _to the address to which the balance is being transferred
   * @param _amount the amount of balance being transferred
   */
  function _transferBalance(address _vault, address _from, address _to, uint96 _amount) internal {
    if (_to == SPONSORSHIP_ADDRESS) {
      revert CannotTransferToSponsorshipAddress();
    }

    if (_from == _to) {
      return;
    }

    // If we are transferring tokens from a delegated account to an undelegated account
    address _fromDelegate = _delegateOf(_vault, _from);
    address _toDelegate = _delegateOf(_vault, _to);
    if (_from != address(0)) {
      bool _isFromDelegate = _fromDelegate == _from;

      _decreaseBalances(_vault, _from, _amount, _isFromDelegate ? _amount : 0);

      // If the user is not delegating to themself, decrease the delegate's delegateBalance
      // If the user is delegating to the sponsorship address, don't adjust the delegateBalance
      if (!_isFromDelegate && _fromDelegate != SPONSORSHIP_ADDRESS) {
        _decreaseBalances(_vault, _fromDelegate, 0, _amount);
      }

      // Burn balance if we're transferring to address(0)
      // Burn delegateBalance if we're transferring to address(0) and burning from an address that is not delegating to the sponsorship address
      // Burn delegateBalance if we're transferring to an address delegating to the sponsorship address from an address that isn't delegating to the sponsorship address
      if (
        _to == address(0) ||
        (_toDelegate == SPONSORSHIP_ADDRESS && _fromDelegate != SPONSORSHIP_ADDRESS)
      ) {
        // If the user is delegating to the sponsorship address, don't adjust the total supply delegateBalance
        _decreaseTotalSupplyBalances(
          _vault,
          _to == address(0) ? _amount : 0,
          (_to == address(0) && _fromDelegate != SPONSORSHIP_ADDRESS) ||
            (_toDelegate == SPONSORSHIP_ADDRESS && _fromDelegate != SPONSORSHIP_ADDRESS)
            ? _amount
            : 0
        );
      }
    }

    // If we are transferring tokens to an address other than address(0)
    if (_to != address(0)) {
      bool _isToDelegate = _toDelegate == _to;

      // If the user is delegating to themself, increase their delegateBalance
      _increaseBalances(_vault, _to, _amount, _isToDelegate ? _amount : 0);

      // Otherwise, increase their delegates delegateBalance if it is not the sponsorship address
      if (!_isToDelegate && _toDelegate != SPONSORSHIP_ADDRESS) {
        _increaseBalances(_vault, _toDelegate, 0, _amount);
      }

      // Mint balance if we're transferring from address(0)
      // Mint delegateBalance if we're transferring from address(0) and to an address not delegating to the sponsorship address
      // Mint delegateBalance if we're transferring from an address delegating to the sponsorship address to an address that isn't delegating to the sponsorship address
      if (
        _from == address(0) ||
        (_fromDelegate == SPONSORSHIP_ADDRESS && _toDelegate != SPONSORSHIP_ADDRESS)
      ) {
        _increaseTotalSupplyBalances(
          _vault,
          _from == address(0) ? _amount : 0,
          (_from == address(0) && _toDelegate != SPONSORSHIP_ADDRESS) ||
            (_fromDelegate == SPONSORSHIP_ADDRESS && _toDelegate != SPONSORSHIP_ADDRESS)
            ? _amount
            : 0
        );
      }
    }
  }

  /**
   * @notice Looks up the delegate of a user.
   * @param _vault the vault for which the user's delegate is being queried
   * @param _user the address to query the delegate of
   * @return The address of the user's delegate
   */
  function _delegateOf(address _vault, address _user) internal view returns (address) {
    address _userDelegate;

    if (_user != address(0)) {
      _userDelegate = delegates[_vault][_user];

      // If the user has not delegated, then the user is the delegate
      if (_userDelegate == address(0)) {
        _userDelegate = _user;
      }
    }

    return _userDelegate;
  }

  /**
   * @notice Transfers a user's vault delegateBalance from one address to another.
   * @param _vault the vault for which the delegateBalance is being transferred
   * @param _fromDelegate the address from which the delegateBalance is being transferred
   * @param _toDelegate the address to which the delegateBalance is being transferred
   * @param _amount the amount of delegateBalance being transferred
   */
  function _transferDelegateBalance(
    address _vault,
    address _fromDelegate,
    address _toDelegate,
    uint96 _amount
  ) internal {
    // If we are transferring tokens from a delegated account to an undelegated account
    if (_fromDelegate != address(0) && _fromDelegate != SPONSORSHIP_ADDRESS) {
      _decreaseBalances(_vault, _fromDelegate, 0, _amount);

      // If we are delegating to the zero address, decrease total supply
      // If we are delegating to the sponsorship address, decrease total supply
      if (_toDelegate == address(0) || _toDelegate == SPONSORSHIP_ADDRESS) {
        _decreaseTotalSupplyBalances(_vault, 0, _amount);
      }
    }

    // If we are transferring tokens from an undelegated account to a delegated account
    if (_toDelegate != address(0) && _toDelegate != SPONSORSHIP_ADDRESS) {
      _increaseBalances(_vault, _toDelegate, 0, _amount);

      // If we are removing delegation from the zero address, increase total supply
      // If we are removing delegation from the sponsorship address, increase total supply
      if (_fromDelegate == address(0) || _fromDelegate == SPONSORSHIP_ADDRESS) {
        _increaseTotalSupplyBalances(_vault, 0, _amount);
      }
    }
  }

  /**
   * @notice Sets a delegate for a user which forwards the delegateBalance tied to the user's
   * balance to the delegate's delegateBalance. "Sponsoring" means the funds aren't delegated
   * to anyone; this can be done by passing address(0) or the SPONSORSHIP_ADDRESS as the delegate.
   * @param _vault The vault for which the delegate is being set
   * @param _from the address to delegate from
   * @param _to the address to delegate to
   */
  function _delegate(address _vault, address _from, address _to) internal {
    address _currentDelegate = _delegateOf(_vault, _from);
    // address(0) is interpreted as sponsoring, so they don't need to know the sponsorship address.
    address to = _to == address(0) ? SPONSORSHIP_ADDRESS : _to;
    if (to == _currentDelegate) {
      revert SameDelegateAlreadySet(to);
    }

    delegates[_vault][_from] = to;

    _transferDelegateBalance(
      _vault,
      _currentDelegate,
      _to,
      SafeCast.toUint96(userObservations[_vault][_from].details.balance)
    );

    emit Delegated(_vault, _from, to);
  }

  /**
   * @notice Increases a user's balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the balance is being increased
   * @param _user the address of the user whose balance is being increased
   * @param _amount the amount of balance being increased
   * @param _delegateAmount the amount of delegateBalance being increased
   */
  function _increaseBalances(
    address _vault,
    address _user,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = userObservations[_vault][_user];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.increaseBalances(PERIOD_LENGTH, PERIOD_OFFSET, _account, _amount, _delegateAmount);

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit IncreasedBalance(_vault, _user, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit ObservationRecorded(
        _vault,
        _user,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }

  /**
   * @notice Decreases the a user's balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the totalSupply balance is being decreased
   * @param _amount the amount of balance being decreased
   * @param _delegateAmount the amount of delegateBalance being decreased
   */
  function _decreaseBalances(
    address _vault,
    address _user,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = userObservations[_vault][_user];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.decreaseBalances(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account,
        _amount,
        _delegateAmount,
        "TC/observation-burn-lt-delegate-balance"
      );

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit DecreasedBalance(_vault, _user, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit ObservationRecorded(
        _vault,
        _user,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }

  /**
   * @notice Decreases the totalSupply balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the totalSupply balance is being decreased
   * @param _amount the amount of balance being decreased
   * @param _delegateAmount the amount of delegateBalance being decreased
   */
  function _decreaseTotalSupplyBalances(
    address _vault,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = totalSupplyObservations[_vault];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.decreaseBalances(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account,
        _amount,
        _delegateAmount,
        "TC/burn-amount-exceeds-total-supply-balance"
      );

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit DecreasedTotalSupply(_vault, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit TotalSupplyObservationRecorded(
        _vault,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }

  /**
   * @notice Increases the totalSupply balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the totalSupply balance is being increased
   * @param _amount the amount of balance being increased
   * @param _delegateAmount the amount of delegateBalance being increased
   */
  function _increaseTotalSupplyBalances(
    address _vault,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = totalSupplyObservations[_vault];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.increaseBalances(PERIOD_LENGTH, PERIOD_OFFSET, _account, _amount, _delegateAmount);

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit IncreasedTotalSupply(_vault, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit TotalSupplyObservationRecorded(
        _vault,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

/**
 * @notice Struct to keep track of each promotion's settings.
 * @param creator Address of the promotion creator
 * @param startTimestamp Timestamp at which the promotion starts
 * @param numberOfEpochs Number of epochs the promotion will last for
 * @param vault Address of the vault that the promotion applies to
 * @param epochDuration Duration of one epoch in seconds
 * @param createdAt Timestamp at which the promotion was created
 * @param token Address of the token to be distributed as reward
 * @param tokensPerEpoch Number of tokens to be distributed per epoch
 * @param rewardsUnclaimed Amount of rewards that have not been claimed yet
 */
struct Promotion {
    address creator;
    uint64 startTimestamp;
    uint8 numberOfEpochs;
    address vault;
    uint48 epochDuration;
    uint48 createdAt;
    IERC20 token;
    uint256 tokensPerEpoch;
    uint256 rewardsUnclaimed;
}

/**
 * @title  PoolTogether V5 ITwabRewards
 * @author PoolTogether Inc. & G9 Software Inc.
 * @notice TwabRewards contract interface.
 */
interface ITwabRewards {
    /**
     * @notice Creates a new promotion.
     * @param vault Address of the vault that the promotion applies to
     * @param token Address of the token to be distributed
     * @param startTimestamp Timestamp at which the promotion starts
     * @param tokensPerEpoch Number of tokens to be distributed per epoch
     * @param epochDuration Duration of one epoch in seconds
     * @param numberOfEpochs Number of epochs the promotion will last for
     * @return Id of the newly created promotion
     */
    function createPromotion(
        address vault,
        IERC20 token,
        uint64 startTimestamp,
        uint256 tokensPerEpoch,
        uint48 epochDuration,
        uint8 numberOfEpochs
    ) external returns (uint256);

    /**
     * @notice End currently active promotion and send promotion tokens back to the creator.
     * @dev Will only send back tokens from the epochs that have not completed.
     * @param promotionId Promotion id to end
     * @param to Address that will receive the remaining tokens if there are any left
     * @return True if operation was successful
     */
    function endPromotion(uint256 promotionId, address to) external returns (bool);

    /**
     * @notice Delete an inactive promotion and send promotion tokens back to the creator.
     * @dev Will send back all the tokens that have not been claimed yet by users.
     * @dev This function will revert if the promotion is still active.
     * @dev This function will revert if the grace period is not over yet.
     * @param promotionId Promotion id to destroy
     * @param to Address that will receive the remaining tokens if there are any left
     * @return True if operation was successful
     */
    function destroyPromotion(uint256 promotionId, address to) external returns (bool);

    /**
     * @notice Extend promotion by adding more epochs.
     * @param promotionId Id of the promotion to extend
     * @param numberOfEpochs Number of epochs to add
     * @return True if the operation was successful
     */
    function extendPromotion(uint256 promotionId, uint8 numberOfEpochs) external returns (bool);

    /**
     * @notice Claim rewards for a given promotion and epoch.
     * @dev Rewards can be claimed on behalf of a user.
     * @dev Rewards can only be claimed for a past epoch.
     * @param user Address of the user to claim rewards for
     * @param promotionId Id of the promotion to claim rewards for
     * @param epochIds Epoch ids to claim rewards for
     * @return Total amount of rewards claimed
     */
    function claimRewards(address user, uint256 promotionId, uint8[] calldata epochIds) external returns (uint256);

    /**
     * @notice Get settings for a specific promotion.
     * @param promotionId Id of the promotion to get settings for
     * @return Promotion settings
     */
    function getPromotion(uint256 promotionId) external view returns (Promotion memory);

    /**
     * @notice Get the current epoch id of a promotion.
     * @param promotionId Id of the promotion to get current epoch for
     * @return Current epoch id of the promotion
     */
    function getCurrentEpochId(uint256 promotionId) external view returns (uint256);

    /**
     * @notice Get the total amount of tokens left to be rewarded.
     * @param promotionId Id of the promotion to get the total amount of tokens left to be rewarded for
     * @return Amount of tokens left to be rewarded
     */
    function getRemainingRewards(uint256 promotionId) external view returns (uint256);

    /**
     * @notice Get amount of tokens to be rewarded for a given epoch.
     * @dev Rewards amount can only be retrieved for epochs that are over.
     * @dev Will revert if `epochId` is over the total number of epochs or if epoch is not over.
     * @dev Will return 0 if the user average balance for the promoted vault is 0.
     * @dev Will be 0 if user has already claimed rewards for the epoch.
     * @param user Address of the user to get amount of rewards for
     * @param promotionId Id of the promotion from which the epoch is
     * @param epochIds Epoch ids to get reward amount for
     * @return Amount of tokens per epoch to be rewarded
     */
    function getRewardsAmount(
        address user,
        uint256 promotionId,
        uint8[] calldata epochIds
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "ring-buffer-lib/RingBufferLib.sol";

import { ObservationLib, MAX_CARDINALITY } from "./ObservationLib.sol";

type PeriodOffsetRelativeTimestamp is uint32;

/// @notice Emitted when a balance is decreased by an amount that exceeds the amount available.
/// @param balance The current balance of the account
/// @param amount The amount being decreased from the account's balance
/// @param message An additional message describing the error
error BalanceLTAmount(uint96 balance, uint96 amount, string message);

/// @notice Emitted when a delegate balance is decreased by an amount that exceeds the amount available.
/// @param delegateBalance The current delegate balance of the account
/// @param delegateAmount The amount being decreased from the account's delegate balance
/// @param message An additional message describing the error
error DelegateBalanceLTAmount(uint96 delegateBalance, uint96 delegateAmount, string message);

/// @notice Emitted when a request is made for a twab that is not yet finalized.
/// @param timestamp The requested timestamp
/// @param currentOverwritePeriodStartedAt The current overwrite period start time
error TimestampNotFinalized(uint256 timestamp, uint256 currentOverwritePeriodStartedAt);

/// @notice Emitted when a TWAB time range start is after the end.
/// @param start The start time
/// @param end The end time
error InvalidTimeRange(uint256 start, uint256 end);

/// @notice Emitted when there is insufficient history to lookup a twab time range
/// @param requestedTimestamp The timestamp requested
/// @param oldestTimestamp The oldest timestamp that can be read
error InsufficientHistory(
  PeriodOffsetRelativeTimestamp requestedTimestamp,
  PeriodOffsetRelativeTimestamp oldestTimestamp
);

/**
 * @title  PoolTogether V5 TwabLib (Library)
 * @author PoolTogether Inc. & G9 Software Inc.
 * @dev    Time-Weighted Average Balance Library for ERC20 tokens.
 * @notice This TwabLib adds on-chain historical lookups to a user(s) time-weighted average balance.
 *         Each user is mapped to an Account struct containing the TWAB history (ring buffer) and
 *         ring buffer parameters. Every token.transfer() creates a new TWAB checkpoint. The new
 *         TWAB checkpoint is stored in the circular ring buffer, as either a new checkpoint or
 *         rewriting a previous checkpoint with new parameters. One checkpoint per day is stored.
 *         The TwabLib guarantees minimum 1 year of search history.
 * @notice There are limitations to the Observation data structure used. Ensure your token is
 *         compatible before using this library. Ensure the date ranges you're relying on are
 *         within safe boundaries.
 */
library TwabLib {
  /**
   * @notice Struct ring buffer parameters for single user Account.
   * @param balance Current token balance for an Account
   * @param delegateBalance Current delegate balance for an Account (active balance for chance)
   * @param nextObservationIndex Next uninitialized or updatable ring buffer checkpoint storage slot
   * @param cardinality Current total "initialized" ring buffer checkpoints for single user Account.
   *                    Used to set initial boundary conditions for an efficient binary search.
   */
  struct AccountDetails {
    uint96 balance;
    uint96 delegateBalance;
    uint16 nextObservationIndex;
    uint16 cardinality;
  }

  /**
   * @notice Account details and historical twabs.
   * @dev The size of observations is MAX_CARDINALITY from the ObservationLib.
   * @param details The account details
   * @param observations The history of observations for this account
   */
  struct Account {
    AccountDetails details;
    ObservationLib.Observation[17520] observations;
  }

  /**
   * @notice Increase a user's balance and delegate balance by a given amount.
   * @dev This function mutates the provided account.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _account The account to update
   * @param _amount The amount to increase the balance by
   * @param _delegateAmount The amount to increase the delegate balance by
   * @return observation The new/updated observation
   * @return isNew Whether or not the observation is new or overwrote a previous one
   * @return isObservationRecorded Whether or not an observation was recorded to storage
   */
  function increaseBalances(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    Account storage _account,
    uint96 _amount,
    uint96 _delegateAmount
  )
    internal
    returns (
      ObservationLib.Observation memory observation,
      bool isNew,
      bool isObservationRecorded,
      AccountDetails memory accountDetails
    )
  {
    accountDetails = _account.details;
    // record a new observation if the delegateAmount is non-zero and time has not overflowed.
    isObservationRecorded =
      _delegateAmount != uint96(0) &&
      block.timestamp <= lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);

    accountDetails.balance += _amount;
    accountDetails.delegateBalance += _delegateAmount;

    // Only record a new Observation if the users delegateBalance has changed.
    if (isObservationRecorded) {
      (observation, isNew, accountDetails) = _recordObservation(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        accountDetails,
        _account
      );
    }

    _account.details = accountDetails;
  }

  /**
   * @notice Decrease a user's balance and delegate balance by a given amount.
   * @dev This function mutates the provided account.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _account The account to update
   * @param _amount The amount to decrease the balance by
   * @param _delegateAmount The amount to decrease the delegate balance by
   * @param _revertMessage The revert message to use if the balance is insufficient
   * @return observation The new/updated observation
   * @return isNew Whether or not the observation is new or overwrote a previous one
   * @return isObservationRecorded Whether or not the observation was recorded to storage
   */
  function decreaseBalances(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    Account storage _account,
    uint96 _amount,
    uint96 _delegateAmount,
    string memory _revertMessage
  )
    internal
    returns (
      ObservationLib.Observation memory observation,
      bool isNew,
      bool isObservationRecorded,
      AccountDetails memory accountDetails
    )
  {
    accountDetails = _account.details;

    if (accountDetails.balance < _amount) {
      revert BalanceLTAmount(accountDetails.balance, _amount, _revertMessage);
    }
    if (accountDetails.delegateBalance < _delegateAmount) {
      revert DelegateBalanceLTAmount(
        accountDetails.delegateBalance,
        _delegateAmount,
        _revertMessage
      );
    }

    // record a new observation if the delegateAmount is non-zero and time has not overflowed.
    isObservationRecorded =
      _delegateAmount != uint96(0) &&
      block.timestamp <= lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);

    unchecked {
      accountDetails.balance -= _amount;
      accountDetails.delegateBalance -= _delegateAmount;
    }

    // Only record a new Observation if the users delegateBalance has changed.
    if (isObservationRecorded) {
      (observation, isNew, accountDetails) = _recordObservation(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        accountDetails,
        _account
      );
    }

    _account.details = accountDetails;
  }

  /**
   * @notice Looks up the oldest observation in the circular buffer.
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @return index The index of the oldest observation
   * @return observation The oldest observation in the circular buffer
   */
  function getOldestObservation(
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails
  ) internal view returns (uint16 index, ObservationLib.Observation memory observation) {
    // If the circular buffer has not been fully populated, we go to the beginning of the buffer at index 0.
    if (_accountDetails.cardinality < MAX_CARDINALITY) {
      index = 0;
      observation = _observations[0];
    } else {
      index = _accountDetails.nextObservationIndex;
      observation = _observations[index];
    }
  }

  /**
   * @notice Looks up the newest observation in the circular buffer.
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @return index The index of the newest observation
   * @return observation The newest observation in the circular buffer
   */
  function getNewestObservation(
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails
  ) internal view returns (uint16 index, ObservationLib.Observation memory observation) {
    index = uint16(
      RingBufferLib.newestIndex(_accountDetails.nextObservationIndex, MAX_CARDINALITY)
    );
    observation = _observations[index];
  }

  /**
   * @notice Looks up a users balance at a specific time in the past. The time must be before the current overwrite period.
   * @dev Ensure timestamps are safe using requireFinalized
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _targetTime The time to look up the balance at
   * @return balance The balance at the target time
   */
  function getBalanceAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    uint256 _targetTime
  ) internal view requireFinalized(PERIOD_LENGTH, PERIOD_OFFSET, _targetTime) returns (uint256) {
    if (_targetTime < PERIOD_OFFSET) {
      return 0;
    }
    // if this is for an overflowed time period, return 0
    if (isShutdownAt(_targetTime, PERIOD_LENGTH, PERIOD_OFFSET)) {
      return 0;
    }
    ObservationLib.Observation memory prevOrAtObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(_targetTime - PERIOD_OFFSET))
    );
    return prevOrAtObservation.balance;
  }

  /**
   * @notice Returns whether the TwabController has been shutdown at the given timestamp
   * If the twab is queried at or after this time, whether an absolute timestamp or time range, it will return 0.
   * @param timestamp The timestamp to check
   * @param PERIOD_OFFSET The offset of the first period
   * @return True if the TwabController is shutdown at the given timestamp, false otherwise.
   */
  function isShutdownAt(
    uint256 timestamp,
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) internal pure returns (bool) {
    return timestamp > lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Computes the largest timestamp at which the TwabController can record a new observation.
   * @param PERIOD_OFFSET The offset of the first period
   * @return The largest timestamp at which the TwabController can record a new observation.
   */
  function lastObservationAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) internal pure returns (uint256) {
    return uint256(PERIOD_OFFSET) + (type(uint32).max / PERIOD_LENGTH) * PERIOD_LENGTH;
  }

  /**
   * @notice Looks up a users TWAB for a time range. The time must be before the current overwrite period.
   * @dev If the timestamps in the range are not exact matches of observations, the balance is extrapolated using the previous observation.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _startTime The start of the time range
   * @param _endTime The end of the time range
   * @return twab The TWAB for the time range
   */
  function getTwabBetween(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    uint256 _startTime,
    uint256 _endTime
  ) internal view requireFinalized(PERIOD_LENGTH, PERIOD_OFFSET, _endTime) returns (uint256) {
    if (_endTime < _startTime) {
      revert InvalidTimeRange(_startTime, _endTime);
    }

    // if the range extends into the shutdown period, return 0
    if (isShutdownAt(_endTime, PERIOD_LENGTH, PERIOD_OFFSET)) {
      return 0;
    }

    uint256 offsetStartTime = _startTime - PERIOD_OFFSET;
    uint256 offsetEndTime = _endTime - PERIOD_OFFSET;

    ObservationLib.Observation memory endObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(offsetEndTime))
    );

    if (offsetStartTime == offsetEndTime) {
      return endObservation.balance;
    }

    ObservationLib.Observation memory startObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(offsetStartTime))
    );

    if (startObservation.timestamp != offsetStartTime) {
      startObservation = _calculateTemporaryObservation(
        startObservation,
        PeriodOffsetRelativeTimestamp.wrap(uint32(offsetStartTime))
      );
    }

    if (endObservation.timestamp != offsetEndTime) {
      endObservation = _calculateTemporaryObservation(
        endObservation,
        PeriodOffsetRelativeTimestamp.wrap(uint32(offsetEndTime))
      );
    }

    // Difference in amount / time
    return
      (endObservation.cumulativeBalance - startObservation.cumulativeBalance) /
      (offsetEndTime - offsetStartTime);
  }

  /**
   * @notice Given an AccountDetails with updated balances, either updates the latest Observation or records a new one
   * @param PERIOD_LENGTH The overwrite period length
   * @param PERIOD_OFFSET The overwrite period offset
   * @param _accountDetails The updated account details
   * @param _account The account to update
   * @return observation The new/updated observation
   * @return isNew Whether or not the observation is new or overwrote a previous one
   * @return newAccountDetails The new account details
   */
  function _recordObservation(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    AccountDetails memory _accountDetails,
    Account storage _account
  )
    internal
    returns (
      ObservationLib.Observation memory observation,
      bool isNew,
      AccountDetails memory newAccountDetails
    )
  {
    PeriodOffsetRelativeTimestamp currentTime = PeriodOffsetRelativeTimestamp.wrap(
      uint32(block.timestamp - PERIOD_OFFSET)
    );

    uint16 nextIndex;
    ObservationLib.Observation memory newestObservation;
    (nextIndex, newestObservation, isNew) = _getNextObservationIndex(
      PERIOD_LENGTH,
      PERIOD_OFFSET,
      _account.observations,
      _accountDetails
    );

    if (isNew) {
      // If the index is new, then we increase the next index to use
      _accountDetails.nextObservationIndex = uint16(
        RingBufferLib.nextIndex(uint256(nextIndex), MAX_CARDINALITY)
      );

      // Prevent the Account specific cardinality from exceeding the MAX_CARDINALITY.
      // The ring buffer length is limited by MAX_CARDINALITY. IF the account.cardinality
      // exceeds the max cardinality, new observations would be incorrectly set or the
      // observation would be out of "bounds" of the ring buffer. Once reached the
      // Account.cardinality will continue to be equal to max cardinality.
      _accountDetails.cardinality = _accountDetails.cardinality < MAX_CARDINALITY
        ? _accountDetails.cardinality + 1
        : MAX_CARDINALITY;
    }

    observation = ObservationLib.Observation({
      cumulativeBalance: _extrapolateFromBalance(newestObservation, currentTime),
      balance: _accountDetails.delegateBalance,
      timestamp: PeriodOffsetRelativeTimestamp.unwrap(currentTime)
    });

    // Write to storage
    _account.observations[nextIndex] = observation;
    newAccountDetails = _accountDetails;
  }

  /**
   * @notice Calculates a temporary observation for a given time using the previous observation.
   * @dev This is used to extrapolate a balance for any given time.
   * @param _observation The previous observation
   * @param _time The time to extrapolate to
   */
  function _calculateTemporaryObservation(
    ObservationLib.Observation memory _observation,
    PeriodOffsetRelativeTimestamp _time
  ) private pure returns (ObservationLib.Observation memory) {
    return
      ObservationLib.Observation({
        cumulativeBalance: _extrapolateFromBalance(_observation, _time),
        balance: _observation.balance,
        timestamp: PeriodOffsetRelativeTimestamp.unwrap(_time)
      });
  }

  /**
   * @notice Looks up the next observation index to write to in the circular buffer.
   * @dev If the current time is in the same period as the newest observation, we overwrite it.
   * @dev If the current time is in a new period, we increment the index and write a new observation.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @return index The index of the next observation slot to overwrite
   * @return newestObservation The newest observation in the circular buffer
   * @return isNew True if the observation slot is new, false if we're overwriting
   */
  function _getNextObservationIndex(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails
  )
    private
    view
    returns (uint16 index, ObservationLib.Observation memory newestObservation, bool isNew)
  {
    uint16 newestIndex;
    (newestIndex, newestObservation) = getNewestObservation(_observations, _accountDetails);

    uint256 currentPeriod = getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, block.timestamp);

    uint256 newestObservationPeriod = getTimestampPeriod(
      PERIOD_LENGTH,
      PERIOD_OFFSET,
      PERIOD_OFFSET + uint256(newestObservation.timestamp)
    );

    // Create a new Observation if it's the first period or the current time falls within a new period
    if (_accountDetails.cardinality == 0 || currentPeriod > newestObservationPeriod) {
      return (_accountDetails.nextObservationIndex, newestObservation, true);
    }

    // Otherwise, we're overwriting the current newest Observation
    return (newestIndex, newestObservation, false);
  }

  /**
   * @notice Computes the start time of the current overwrite period
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @return The start time of the current overwrite period
   */
  function _currentOverwritePeriodStartedAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) private view returns (uint256) {
    uint256 period = getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, block.timestamp);
    return getPeriodStartTime(PERIOD_LENGTH, PERIOD_OFFSET, period);
  }

  /**
   * @notice Calculates the next cumulative balance using a provided Observation and timestamp.
   * @param _observation The observation to extrapolate from
   * @param _offsetTimestamp The timestamp to extrapolate to
   * @return cumulativeBalance The cumulative balance at the timestamp
   */
  function _extrapolateFromBalance(
    ObservationLib.Observation memory _observation,
    PeriodOffsetRelativeTimestamp _offsetTimestamp
  ) private pure returns (uint128) {
    // new cumulative balance = provided cumulative balance (or zero) + (current balance * elapsed seconds)
    unchecked {
      return
        uint128(
          uint256(_observation.cumulativeBalance) +
            uint256(_observation.balance) *
            (PeriodOffsetRelativeTimestamp.unwrap(_offsetTimestamp) - _observation.timestamp)
        );
    }
  }

  /**
   * @notice Computes the overwrite period start time given the current time
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @return The start time for the current overwrite period.
   */
  function currentOverwritePeriodStartedAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) internal view returns (uint256) {
    return _currentOverwritePeriodStartedAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Calculates the period a timestamp falls within.
   * @dev Timestamp prior to the PERIOD_OFFSET are considered to be in period 0.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _timestamp The timestamp to calculate the period for
   * @return period The period
   */
  function getTimestampPeriod(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _timestamp
  ) internal pure returns (uint256) {
    if (_timestamp <= PERIOD_OFFSET) {
      return 0;
    }
    return (_timestamp - PERIOD_OFFSET) / uint256(PERIOD_LENGTH);
  }

  /**
   * @notice Calculates the start timestamp for a period
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _period The period to check
   * @return _timestamp The timestamp at which the period starts
   */
  function getPeriodStartTime(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _period
  ) internal pure returns (uint256) {
    return _period * PERIOD_LENGTH + PERIOD_OFFSET;
  }

  /**
   * @notice Calculates the last timestamp for a period
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _period The period to check
   * @return _timestamp The timestamp at which the period ends
   */
  function getPeriodEndTime(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _period
  ) internal pure returns (uint256) {
    return (_period + 1) * PERIOD_LENGTH + PERIOD_OFFSET;
  }

  /**
   * @notice Looks up the newest observation before or at a given timestamp.
   * @dev If an observation is available at the target time, it is returned. Otherwise, the newest observation before the target time is returned.
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _targetTime The timestamp to look up
   * @return prevOrAtObservation The observation
   */
  function getPreviousOrAtObservation(
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    uint256 _targetTime
  ) internal view returns (ObservationLib.Observation memory prevOrAtObservation) {
    if (_targetTime < PERIOD_OFFSET) {
      return ObservationLib.Observation({ cumulativeBalance: 0, balance: 0, timestamp: 0 });
    }
    uint256 offsetTargetTime = _targetTime - PERIOD_OFFSET;
    // if this is for an overflowed time period, return 0
    if (offsetTargetTime > type(uint32).max) {
      return
        ObservationLib.Observation({
          cumulativeBalance: 0,
          balance: 0,
          timestamp: type(uint32).max
        });
    }
    prevOrAtObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(offsetTargetTime))
    );
  }

  /**
   * @notice Looks up the newest observation before or at a given timestamp.
   * @dev If an observation is available at the target time, it is returned. Otherwise, the newest observation before the target time is returned.
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _offsetTargetTime The timestamp to look up (offset by the period offset)
   * @return prevOrAtObservation The observation
   */
  function _getPreviousOrAtObservation(
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    PeriodOffsetRelativeTimestamp _offsetTargetTime
  ) private view returns (ObservationLib.Observation memory prevOrAtObservation) {
    // If there are no observations, return a zeroed observation
    if (_accountDetails.cardinality == 0) {
      return ObservationLib.Observation({ cumulativeBalance: 0, balance: 0, timestamp: 0 });
    }

    uint16 oldestTwabIndex;

    (oldestTwabIndex, prevOrAtObservation) = getOldestObservation(_observations, _accountDetails);

    // if the requested time is older than the oldest observation
    if (PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime) < prevOrAtObservation.timestamp) {
      // if the user didn't have any activity prior to the oldest observation, then we know they had a zero balance
      if (_accountDetails.cardinality < MAX_CARDINALITY) {
        return
          ObservationLib.Observation({
            cumulativeBalance: 0,
            balance: 0,
            timestamp: PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime)
          });
      } else {
        // if we are missing their history, we must revert
        revert InsufficientHistory(
          _offsetTargetTime,
          PeriodOffsetRelativeTimestamp.wrap(prevOrAtObservation.timestamp)
        );
      }
    }

    // We know targetTime >= oldestObservation.timestamp because of the above if statement, so we can return here.
    if (_accountDetails.cardinality == 1) {
      return prevOrAtObservation;
    }

    // Find the newest observation
    (
      uint16 newestTwabIndex,
      ObservationLib.Observation memory afterOrAtObservation
    ) = getNewestObservation(_observations, _accountDetails);

    // if the target time is at or after the newest, return it
    if (PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime) >= afterOrAtObservation.timestamp) {
      return afterOrAtObservation;
    }
    // if we know there is only 1 observation older than the newest
    if (_accountDetails.cardinality == 2) {
      return prevOrAtObservation;
    }

    // Otherwise, we perform a binarySearch to find the observation before or at the timestamp
    (prevOrAtObservation, oldestTwabIndex, afterOrAtObservation, newestTwabIndex) = ObservationLib
      .binarySearch(
        _observations,
        newestTwabIndex,
        oldestTwabIndex,
        PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime),
        _accountDetails.cardinality
      );

    // If the afterOrAt is at, we can skip a temporary Observation computation by returning it here
    if (afterOrAtObservation.timestamp == PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime)) {
      return afterOrAtObservation;
    }

    return prevOrAtObservation;
  }

  /**
   * @notice Checks if the given timestamp is safe to perform a historic balance lookup on.
   * @dev A timestamp is safe if it is before the current overwrite period
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _time The timestamp to check
   * @return isSafe Whether or not the timestamp is safe
   */
  function hasFinalized(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _time
  ) internal view returns (bool) {
    return _hasFinalized(PERIOD_LENGTH, PERIOD_OFFSET, _time);
  }

  /**
   * @notice Checks if the given timestamp is safe to perform a historic balance lookup on.
   * @dev A timestamp is safe if it is on or before the current overwrite period start time
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _time The timestamp to check
   * @return isSafe Whether or not the timestamp is safe
   */
  function _hasFinalized(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _time
  ) private view returns (bool) {
    // It's safe if equal to the overwrite period start time, because the cumulative balance won't be impacted
    return _time <= _currentOverwritePeriodStartedAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Checks if the given timestamp is safe to perform a historic balance lookup on.
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _timestamp The timestamp to check
   */
  modifier requireFinalized(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _timestamp
  ) {
    // The current period can still be changed; so the start of the period marks the beginning of unsafe timestamps.
    uint256 overwritePeriodStartTime = _currentOverwritePeriodStartedAt(
      PERIOD_LENGTH,
      PERIOD_OFFSET
    );
    // timestamp == overwritePeriodStartTime doesn't matter, because the cumulative balance won't be impacted
    if (_timestamp > overwritePeriodStartTime) {
      revert TimestampNotFinalized(_timestamp, overwritePeriodStartTime);
    }
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "ring-buffer-lib/RingBufferLib.sol";

/**
 * @dev Sets max ring buffer length in the Account.observations Observation list.
 *         As users transfer/mint/burn tickets new Observation checkpoints are recorded.
 *         The current `MAX_CARDINALITY` guarantees a one year minimum, of accurate historical lookups.
 * @dev The user Account.Account.cardinality parameter can NOT exceed the max cardinality variable.
 *      Preventing "corrupted" ring buffer lookup pointers and new observation checkpoints.
 */
uint16 constant MAX_CARDINALITY = 17520; // with min period of 1 hour, this allows for minimum two years of history

/**
 * @title PoolTogether V5 Observation Library
 * @author PoolTogether Inc. & G9 Software Inc.
 * @notice This library allows one to store an array of timestamped values and efficiently search them.
 * @dev Largely pulled from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/c05a0e2c8c08c460fb4d05cfdda30b3ad8deeaac/contracts/libraries/Oracle.sol
 */
library ObservationLib {
  /**
   * @notice Observation, which includes an amount and timestamp.
   * @param cumulativeBalance the cumulative time-weighted balance at `timestamp`.
   * @param balance `balance` at `timestamp`.
   * @param timestamp Recorded `timestamp`.
   */
  struct Observation {
    uint128 cumulativeBalance;
    uint96 balance;
    uint32 timestamp;
  }

  /**
   * @notice Fetches Observations `beforeOrAt` and `afterOrAt` a `_target`, eg: where [`beforeOrAt`, `afterOrAt`] is satisfied.
   * The result may be the same Observation, or adjacent Observations.
   * @dev The _target must fall within the boundaries of the provided _observations.
   * Meaning the _target must be: older than the most recent Observation and younger, or the same age as, the oldest Observation.
   * @dev  If `_newestObservationIndex` is less than `_oldestObservationIndex`, it means that we've wrapped around the circular buffer.
   *       So the most recent observation will be at `_oldestObservationIndex + _cardinality - 1`, at the beginning of the circular buffer.
   * @param _observations List of Observations to search through.
   * @param _newestObservationIndex Index of the newest Observation. Right side of the circular buffer.
   * @param _oldestObservationIndex Index of the oldest Observation. Left side of the circular buffer.
   * @param _target Timestamp at which we are searching the Observation.
   * @param _cardinality Cardinality of the circular buffer we are searching through.
   * @return beforeOrAt Observation recorded before, or at, the target.
   * @return beforeOrAtIndex Index of observation recorded before, or at, the target.
   * @return afterOrAt Observation recorded at, or after, the target.
   * @return afterOrAtIndex Index of observation recorded at, or after, the target.
   */
  function binarySearch(
    Observation[MAX_CARDINALITY] storage _observations,
    uint24 _newestObservationIndex,
    uint24 _oldestObservationIndex,
    uint32 _target,
    uint16 _cardinality
  )
    internal
    view
    returns (
      Observation memory beforeOrAt,
      uint16 beforeOrAtIndex,
      Observation memory afterOrAt,
      uint16 afterOrAtIndex
    )
  {
    uint256 leftSide = _oldestObservationIndex;
    uint256 rightSide = _newestObservationIndex < leftSide
      ? leftSide + _cardinality - 1
      : _newestObservationIndex;
    uint256 currentIndex;

    while (true) {
      // We start our search in the middle of the `leftSide` and `rightSide`.
      // After each iteration, we narrow down the search to the left or the right side while still starting our search in the middle.
      currentIndex = (leftSide + rightSide) / 2;

      beforeOrAtIndex = uint16(RingBufferLib.wrap(currentIndex, _cardinality));
      beforeOrAt = _observations[beforeOrAtIndex];
      uint32 beforeOrAtTimestamp = beforeOrAt.timestamp;

      afterOrAtIndex = uint16(RingBufferLib.nextIndex(currentIndex, _cardinality));
      afterOrAt = _observations[afterOrAtIndex];

      bool targetAfterOrAt = beforeOrAtTimestamp <= _target;

      // Check if we've found the corresponding Observation.
      if (targetAfterOrAt && _target <= afterOrAt.timestamp) {
        break;
      }

      // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower. To the left of the current index.
      if (!targetAfterOrAt) {
        rightSide = currentIndex - 1;
      } else {
        // Otherwise, we keep searching higher. To the right of the current index.
        leftSide = currentIndex + 1;
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * NOTE: There is a difference in meaning between "cardinality" and "count":
 *  - cardinality is the physical size of the ring buffer (i.e. max elements).
 *  - count is the number of elements in the buffer, which may be less than cardinality.
 */
library RingBufferLib {
    /**
    * @notice Returns wrapped TWAB index.
    * @dev  In order to navigate the TWAB circular buffer, we need to use the modulo operator.
    * @dev  For example, if `_index` is equal to 32 and the TWAB circular buffer is of `_cardinality` 32,
    *       it will return 0 and will point to the first element of the array.
    * @param _index Index used to navigate through the TWAB circular buffer.
    * @param _cardinality TWAB buffer cardinality.
    * @return TWAB index.
    */
    function wrap(uint256 _index, uint256 _cardinality) internal pure returns (uint256) {
        return _index % _cardinality;
    }

    /**
    * @notice Computes the negative offset from the given index, wrapped by the cardinality.
    * @dev  We add `_cardinality` to `_index` to be able to offset even if `_amount` is superior to `_cardinality`.
    * @param _index The index from which to offset
    * @param _amount The number of indices to offset.  This is subtracted from the given index.
    * @param _count The number of elements in the ring buffer
    * @return Offsetted index.
     */
    function offset(
        uint256 _index,
        uint256 _amount,
        uint256 _count
    ) internal pure returns (uint256) {
        return wrap(_index + _count - _amount, _count);
    }

    /// @notice Returns the index of the last recorded TWAB
    /// @param _nextIndex The next available twab index.  This will be recorded to next.
    /// @param _count The count of the TWAB history.
    /// @return The index of the last recorded TWAB
    function newestIndex(uint256 _nextIndex, uint256 _count)
        internal
        pure
        returns (uint256)
    {
        if (_count == 0) {
            return 0;
        }

        return wrap(_nextIndex + _count - 1, _count);
    }

    function oldestIndex(uint256 _nextIndex, uint256 _count, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        if (_count < _cardinality) {
            return 0;
        } else {
            return wrap(_nextIndex + _cardinality, _cardinality);
        }
    }

    /// @notice Computes the ring buffer index that follows the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The next index relative to the given index.  Will wrap around to 0 if the next index == cardinality
    function nextIndex(uint256 _index, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        return wrap(_index + 1, _cardinality);
    }

    /// @notice Computes the ring buffer index that preceeds the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The prev index relative to the given index.  Will wrap around to the end if the prev index == 0
    function prevIndex(uint256 _index, uint256 _cardinality)
    internal
    pure
    returns (uint256) 
    {
        return _index == 0 ? _cardinality - 1 : _index - 1;
    }
}