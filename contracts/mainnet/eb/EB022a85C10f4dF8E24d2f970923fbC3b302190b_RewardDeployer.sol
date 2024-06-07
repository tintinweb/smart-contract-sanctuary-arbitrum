// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

interface IMulticall {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;
import {IMulticall} from "./IMulticall.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6ba452dea4258afe77726293435f10baf2bed265/contracts/utils/Multicall.sol

/*
 * @notice Multicall
 */
abstract contract Multicall is IMulticall {
    /**
     * @notice This function allows multiple calls to different contract functions
     * in a single transaction.
     * @param data An array of encoded function call data.
     * @return results An array of the results of the function calls.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

// factory contraints on pools
uint8 constant MAX_PROTOCOL_FEE_RATIO_D3 = 0.25e3; // 25%
uint256 constant MAX_PROTOCOL_LENDING_FEE_RATE_D18 = 0.02e18; // 2%
uint64 constant MAX_POOL_FEE_D18 = 0.9e18; // 90%
uint64 constant MIN_LOOKBACK = 1 seconds;
uint64 constant MAX_TICK_SPACING = 10_000;

// pool constraints
uint8 constant NUMBER_OF_KINDS = 4;
int32 constant NUMBER_OF_KINDS_32 = int32(int8(NUMBER_OF_KINDS));
uint256 constant MAX_TICK = 322_378; // max price 1e14 in D18 scale
int32 constant MAX_TICK_32 = int32(int256(MAX_TICK));
int32 constant MIN_TICK_32 = int32(-int256(MAX_TICK));
uint256 constant MAX_BINS_TO_MERGE = 3;
uint128 constant MINIMUM_LIQUIDITY = 1e8;

// accessor named constants
uint8 constant ALL_KINDS_MASK = 0xF; // 0b1111
uint8 constant PERMISSIONED_LIQUIDITY_MASK = 0x10; // 0b010000
uint8 constant PERMISSIONED_SWAP_MASK = 0x20; // 0b100000
uint8 constant OPTIONS_MASK = ALL_KINDS_MASK | PERMISSIONED_LIQUIDITY_MASK | PERMISSIONED_SWAP_MASK; // 0b111111

// named values
address constant MERGED_LP_BALANCE_ADDRESS = address(0);
uint256 constant MERGED_LP_BALANCE_SUBACCOUNT = 0;
uint128 constant ONE = 1e18;
uint128 constant ONE_SQUARED = 1e36;
int256 constant INT256_ONE = 1e18;
uint256 constant ONE_D8 = 1e8;
uint256 constant ONE_D3 = 1e3;
int40 constant INT_ONE_D8 = 1e8;
int40 constant HALF_TICK_D8 = 0.5e8;
uint8 constant DEFAULT_DECIMALS = 18;
uint256 constant DEFAULT_SCALE = 1;
bytes constant EMPTY_PRICE_BREAKS = hex"010000000000000000000000";

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

import {Math as OzMath} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ONE, DEFAULT_SCALE, DEFAULT_DECIMALS, INT_ONE_D8, ONE_SQUARED} from "./Constants.sol";

/**
 * @notice Math functions.
 */
library Math {
    /**
     * @notice Returns the lesser of two values.
     * @param x First uint256 value.
     * @param y Second uint256 value.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /**
     * @notice Returns the lesser of two uint128 values.
     * @param x First uint128 value.
     * @param y Second uint128 value.
     */
    function min128(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /**
     * @notice Returns the lesser of two int256 values.
     * @param x First int256 value.
     * @param y Second int256 value.
     */
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /**
     * @notice Returns the greater of two uint256 values.
     * @param x First uint256 value.
     * @param y Second uint256 value.
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /**
     * @notice Returns the greater of two int256 values.
     * @param x First int256 value.
     * @param y Second int256 value.
     */
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /**
     * @notice Returns the greater of two uint128 values.
     * @param x First uint128 value.
     * @param y Second uint128 value.
     */
    function max128(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /**
     * @notice Thresholds a value to be within the specified bounds.
     * @param value The value to bound.
     * @param lowerLimit The minimum allowable value.
     * @param upperLimit The maximum allowable value.
     */
    function boundValue(
        uint256 value,
        uint256 lowerLimit,
        uint256 upperLimit
    ) internal pure returns (uint256 outputValue) {
        outputValue = min(max(value, lowerLimit), upperLimit);
    }

    /**
     * @notice Returns the difference between two uint128 values or zero if the result would be negative.
     * @param x The minuend.
     * @param y The subtrahend.
     */
    function clip128(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
            return x < y ? 0 : x - y;
        }
    }

    /**
     * @notice Returns the difference between two uint256 values or zero if the result would be negative.
     * @param x The minuend.
     * @param y The subtrahend.
     */
    function clip(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            return x < y ? 0 : x - y;
        }
    }

    /**
     * @notice Divides one uint256 by another, rounding down to the nearest
     * integer.
     * @param x The dividend.
     * @param y The divisor.
     */
    function divFloor(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivFloor(x, ONE, y);
    }

    /**
     * @notice Divides one uint256 by another, rounding up to the nearest integer.
     * @param x The dividend.
     * @param y The divisor.
     */
    function divCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivCeil(x, ONE, y);
    }

    /**
     * @notice Multiplies two uint256 values and then divides by ONE, rounding down.
     * @param x The multiplicand.
     * @param y The multiplier.
     */
    function mulFloor(uint256 x, uint256 y) internal pure returns (uint256) {
        return OzMath.mulDiv(x, y, ONE);
    }

    /**
     * @notice Multiplies two uint256 values and then divides by ONE, rounding up.
     * @param x The multiplicand.
     * @param y The multiplier.
     */
    function mulCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivCeil(x, y, ONE);
    }

    /**
     * @notice Calculates the multiplicative inverse of a uint256, rounding down.
     * @param x The value to invert.
     */
    function invFloor(uint256 x) internal pure returns (uint256) {
        unchecked {
            return ONE_SQUARED / x;
        }
    }

    /**
     * @notice Calculates the multiplicative inverse of a uint256, rounding up.
     * @param denominator The value to invert.
     */
    function invCeil(uint256 denominator) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // divide z - 1 by the denominator and add 1.
            z := add(div(sub(ONE_SQUARED, 1), denominator), 1)
        }
    }

    /**
     * @notice Multiplies two uint256 values and divides by a third, rounding down.
     * @param x The multiplicand.
     * @param y The multiplier.
     * @param k The divisor.
     */
    function mulDivFloor(uint256 x, uint256 y, uint256 k) internal pure returns (uint256 result) {
        result = OzMath.mulDiv(x, y, max(1, k));
    }

    /**
     * @notice Multiplies two uint256 values and divides by a third, rounding up if there's a remainder.
     * @param x The multiplicand.
     * @param y The multiplier.
     * @param k The divisor.
     */
    function mulDivCeil(uint256 x, uint256 y, uint256 k) internal pure returns (uint256 result) {
        result = mulDivFloor(x, y, k);
        if (mulmod(x, y, max(1, k)) != 0) result = result + 1;
    }

    /**
     * @notice Multiplies two uint256 values and divides by a third, rounding
     * down. Will revert if `x * y` is larger than `type(uint256).max`.
     * @param x The first operand for multiplication.
     * @param y The second operand for multiplication.
     * @param denominator The divisor after multiplication.
     */
    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // Store x * y in z for now.
            z := mul(x, y)
            if iszero(denominator) {
                denominator := 1
            }

            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    /**
     * @notice Multiplies two uint256 values and divides by a third, rounding
     * up. Will revert if `x * y` is larger than `type(uint256).max`.
     * @param x The first operand for multiplication.
     * @param y The second operand for multiplication.
     * @param denominator The divisor after multiplication.
     */
    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // Store x * y in z for now.
            z := mul(x, y)
            if iszero(denominator) {
                denominator := 1
            }

            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    /**
     * @notice Multiplies a uint256 by another and divides by a constant,
     * rounding down. Will revert if `x * y` is larger than
     * `type(uint256).max`.
     * @param x The multiplicand.
     * @param y The multiplier.
     */
    function mulDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, ONE);
    }

    /**
     * @notice Divides a uint256 by another, rounding down the result. Will
     * revert if `x * 1e18` is larger than `type(uint256).max`.
     * @param x The dividend.
     * @param y The divisor.
     */
    function divDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, ONE, y);
    }

    /**
     * @notice Divides a uint256 by another, rounding up the result. Will
     * revert if `x * 1e18` is larger than `type(uint256).max`.
     * @param x The dividend.
     * @param y The divisor.
     */
    function divUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, ONE, y);
    }

    /**
     * @notice Scales a number based on a difference in decimals from a default.
     * @param decimals The new decimal precision.
     */
    function scale(uint8 decimals) internal pure returns (uint256) {
        unchecked {
            if (decimals == DEFAULT_DECIMALS) {
                return DEFAULT_SCALE;
            } else {
                return 10 ** (DEFAULT_DECIMALS - decimals);
            }
        }
    }

    /**
     * @notice Adjusts a scaled amount to the token decimal scale.
     * @param amount The scaled amount.
     * @param scaleFactor The scaling factor to adjust by.
     * @param ceil Whether to round up (true) or down (false).
     */
    function ammScaleToTokenScale(uint256 amount, uint256 scaleFactor, bool ceil) internal pure returns (uint256 z) {
        unchecked {
            if (scaleFactor == DEFAULT_SCALE || amount == 0) {
                return amount;
            } else {
                if (!ceil) return amount / scaleFactor;
                assembly ("memory-safe") {
                    z := add(div(sub(amount, 1), scaleFactor), 1)
                }
            }
        }
    }

    /**
     * @notice Adjusts a token amount to the D18 AMM scale.
     * @param amount The amount in token scale.
     * @param scaleFactor The scale factor for adjustment.
     */
    function tokenScaleToAmmScale(uint256 amount, uint256 scaleFactor) internal pure returns (uint256) {
        if (scaleFactor == DEFAULT_SCALE) {
            return amount;
        } else {
            return amount * scaleFactor;
        }
    }

    /**
     * @notice Returns the absolute value of a signed 32-bit integer.
     * @param x The integer to take the absolute value of.
     */
    function abs32(int32 x) internal pure returns (uint32) {
        unchecked {
            return uint32(x < 0 ? -x : x);
        }
    }

    /**
     * @notice Returns the absolute value of a signed 256-bit integer.
     * @param x The integer to take the absolute value of.
     */
    function abs(int256 x) internal pure returns (uint256) {
        unchecked {
            return uint256(x < 0 ? -x : x);
        }
    }

    /**
     * @notice Calculates the integer square root of a uint256 rounded down.
     * @param x The number to take the square root of.
     */
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        // from https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/FixedPointMathLib.sol
        assembly ("memory-safe") {
            let y := x
            z := 181

            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            z := shr(18, mul(z, add(y, 65536)))

            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            z := sub(z, lt(div(x, z), z))
        }
    }

    /**
     * @notice Computes the floor of a D8-scaled number as an int32, ignoring
     * potential overflow in the cast.
     * @param val The D8-scaled number.
     */
    function floorD8Unchecked(int256 val) internal pure returns (int32) {
        int32 val32;
        bool check;
        unchecked {
            val32 = int32(val / INT_ONE_D8);
            check = (val < 0 && val % INT_ONE_D8 != 0);
        }
        return check ? val32 - 1 : val32;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {INft} from "@maverick/v2-supplemental/contracts/positionbase/INft.sol";
import {IMulticall} from "@maverick/v2-common/contracts/base/IMulticall.sol";

import {IMaverickV2VotingEscrow} from "./IMaverickV2VotingEscrow.sol";
import {IMaverickV2RewardVault} from "./IMaverickV2RewardVault.sol";
import {IRewardAccounting} from "../rewardbase/IRewardAccounting.sol";

interface IMaverickV2Reward is INft, IMulticall, IRewardAccounting {
    event NotifyRewardAmount(
        address sender,
        IERC20 rewardTokenAddress,
        uint256 amount,
        uint256 duration,
        uint256 rewardRate
    );
    event GetReward(
        address sender,
        uint256 tokenId,
        address recipient,
        uint8 rewardTokenIndex,
        uint256 stakeDuration,
        IERC20 rewardTokenAddress,
        RewardOutput rewardOutput,
        uint256 lockupId
    );
    event UnStake(
        address sender,
        uint256 tokenId,
        uint256 amount,
        address recipient,
        uint256 userBalance,
        uint256 totalSupply
    );
    event Stake(
        address sender,
        address supplier,
        uint256 amount,
        uint256 tokenId,
        uint256 userBalance,
        uint256 totalSupply
    );
    event AddRewardToken(IERC20 rewardTokenAddress, uint8 rewardTokenIndex);
    event RemoveRewardToken(IERC20 rewardTokenAddress, uint8 rewardTokenIndex);
    event ApproveRewardGetter(uint256 tokenId, address getter);

    error RewardDurationOutOfBounds(uint256 duration, uint256 minDuration, uint256 maxDuration);
    error RewardZeroAmount();
    error RewardNotValidRewardToken(IERC20 rewardTokenAddress);
    error RewardNotValidIndex(uint8 index);
    error RewardTokenCannotBeStakingToken(IERC20 stakingToken);
    error RewardTransferNotSupported();
    error RewardNotApprovedGetter(uint256 tokenId, address approved, address getter);
    error RewardUnboostedTimePeriodNotMet(uint256 timestamp, uint256 minTimestamp);

    struct RewardInfo {
        // Timestamp of when the rewards finish
        uint256 finishAt;
        // Minimum of last updated time and reward finish time
        uint256 updatedAt;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Escrowed rewards
        uint256 escrowedReward;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardPerTokenStored;
        // Reward Token to be emitted
        IERC20 rewardToken;
        // ve locking contract
        IMaverickV2VotingEscrow veRewardToken;
        // amount available to push to ve as incentive
        uint128 unboostedAmount;
        // timestamp of unboosted push
        uint256 lastUnboostedPushTimestamp;
    }

    struct ContractInfo {
        // Reward Name
        string name;
        // Reward Symbol
        string symbol;
        // total supply staked
        uint256 totalSupply;
        // staking token
        IERC20 stakingToken;
    }

    struct EarnedInfo {
        // earned
        uint256 earned;
        // reward token
        IERC20 rewardToken;
    }

    struct RewardOutput {
        uint256 amount;
        bool asVe;
        IMaverickV2VotingEscrow veContract;
    }

    // solhint-disable-next-line func-name-mixedcase
    function MAX_DURATION() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function MIN_DURATION() external view returns (uint256);

    /**
     * @notice This function retrieves the minimum time gap in seconds that
     * must have elasped between calls to `pushUnboostedToVe()`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function UNBOOSTED_MIN_TIME_GAP() external view returns (uint256);

    /**
     * @notice This function retrieves the address of the token used for
     * staking in this reward contract.
     * @return The address of the staking token (IERC20).
     */
    function stakingToken() external view returns (IERC20);

    /**
     * @notice This function retrieves the address of the MaverickV2RewardVault
     * contract associated with this reward contract.
     * @return The address of the IMaverickV2RewardVault contract.
     */
    function vault() external view returns (IMaverickV2RewardVault);

    /**
     * @notice This function retrieves information about all available reward tokens for this reward contract.
     * @return info An array of RewardInfo structs containing details about each reward token.
     */
    function rewardInfo() external view returns (RewardInfo[] memory info);

    /**
     * @notice This function retrieves information about all available reward
     * tokens and overall contract details for this reward contract.
     * @return info An array of RewardInfo structs containing details about each reward token.
     * @return _contractInfo A ContractInfo struct containing overall contract details.
     */
    function contractInfo() external view returns (RewardInfo[] memory info, ContractInfo memory _contractInfo);

    /**
     * @notice This function calculates the total amount of all earned rewards
     * for a specific tokenId across all reward tokens.
     * @param tokenId The address of the tokenId for which to calculate earned rewards.
     * @return earnedInfo An array of EarnedInfo structs containing details about earned rewards for each supported token.
     */
    function earned(uint256 tokenId) external view returns (EarnedInfo[] memory earnedInfo);

    /**
     * @notice This function calculates the total amount of earned rewards for
     * a specific tokenId for a particular reward token.
     * @param tokenId The address of the tokenId for which to calculate earned rewards.
     * @param rewardTokenAddress The address of the specific reward token.
     * @return amount The total amount of earned rewards for the specified token.
     */
    function earned(uint256 tokenId, IERC20 rewardTokenAddress) external view returns (uint256);

    /**
     * @notice This function retrieves the internal index associated with a specific reward token address.
     * @param  rewardToken The address of the reward token to get the index for.
     * @return rewardTokenIndex The internal index of the token within the reward contract (uint8).
     */
    function tokenIndex(IERC20 rewardToken) external view returns (uint8 rewardTokenIndex);

    /**
     * @notice This function retrieves the total number of supported reward tokens in this reward contract.
     * @return count The total number of reward tokens (uint256).
     */
    function rewardTokenCount() external view returns (uint256);

    /**
     * @notice This function transfers a specified amount of reward tokens from
     * the caller to distribute them over a defined duration. The caller will
     * need to approve this rewards contract to make the transfer on the
     * caller's behalf. See `notifyRewardAmount` for details of how the
     * duration is set by the rewards contract.
     * @param rewardToken The address of the reward token to transfer.
     * @param duration The duration (in seconds) over which to distribute the rewards.
     * @param amount The amount of reward tokens to transfer.
     * @return _duration The duration in seconds that the incentives will be distributed over.
     */
    function transferAndNotifyRewardAmount(
        IERC20 rewardToken,
        uint256 duration,
        uint256 amount
    ) external returns (uint256 _duration);

    /**
     * @notice This function notifies the vault to distribute a previously
     * transferred amount of reward tokens over a defined duration. (Assumes
     * tokens are already in the contract).
     * @dev The duration of the distribution may not be the same as the input
     * duration.  If this notify amount is less than the amount already pending
     * disbursement, then this new amount will be distributed as the same rate
     * as the existing rate and that will dictate the duration.  Alternatively,
     * if the amount is more than the pending disbursement, then the input
     * duration will be honored and all pending disbursement tokens will also be
     * distributed at this newly set rate.
     * @param rewardToken The address of the reward token to distribute.
     * @param duration The duration (in seconds) over which to distribute the rewards.
     * @return _duration The duration in seconds that the incentives will be distributed over.
     */
    function notifyRewardAmount(IERC20 rewardToken, uint256 duration) external returns (uint256 _duration);

    /**
     * @notice This function transfers a specified amount of staking tokens
     * from the caller to the staking `vault()` and stakes them on the
     * recipient's behalf.  The user has to approve this reward contract to
     * transfer the staking token on their behalf for this function not to
     * revert.
     * @param tokenId Nft tokenId to stake for the staked tokens.
     * @param _amount The amount of staking tokens to transfer and stake.
     * @return amount The amount of staking tokens staked.  May differ from
     * input if there were unstaked tokens in the vault prior to this call.
     * @return stakedTokenId TokenId where liquidity was staked to.  This may
     * differ from the input tokenIf if the input `tokenId=0`.
     */
    function transferAndStake(
        uint256 tokenId,
        uint256 _amount
    ) external returns (uint256 amount, uint256 stakedTokenId);

    /**
     * @notice This function stakes the staking tokens to the specified
     * tokenId. If `tokenId=0` is passed in, then this function will look up
     * the caller's tokenIds and stake to the zero-index tokenId.  If the user
     * does not yet have a staking NFT tokenId, this function will mint one for
     * the sender and stake to that newly-minted tokenId.
     *
     * @dev The amount staked is derived by looking at the new balance on
     * the `vault()`. So, for staking to yield a non-zero balance, the user
     * will need to have transfered the `stakingToken()` to the `vault()` prior
     * to calling `stake`.  Note, tokens sent to the reward contract instead
     * of the vault will not be stakable and instead will be eligible to be
     * disbursed as rewards to stakers.  This is an advanced usage function.
     * If in doubt about the mechanics of staking, use `transferAndStake()`
     * instead.
     * @param tokenId The address of the tokenId whose tokens to stake.
     * @return amount The amount of staking tokens staked (uint256).
     * @return stakedTokenId TokenId where liquidity was staked to.  This may
     * differ from the input tokenIf if the input `tokenId=0`.
     */
    function stake(uint256 tokenId) external returns (uint256 amount, uint256 stakedTokenId);

    /**
     * @notice This function initiates unstaking of a specified amount of
     * staking tokens for the caller and sends them to a recipient.
     * @param tokenId The address of the tokenId whose tokens to unstake.
     * @param amount The amount of staking tokens to unstake (uint256).
     */
    function unstakeToOwner(uint256 tokenId, uint256 amount) external;

    /**
     * @notice This function initiates unstaking of a specified amount of
     * staking tokens on behalf of a specific tokenId and sends them to a recipient.
     * @dev To unstakeFrom, the caller must have an approval allowance of at
     * least `amount`.  Approvals follow the ERC-721 approval interface.
     * @param tokenId The address of the tokenId whose tokens to unstake.
     * @param recipient The address to which the unstaked tokens will be sent.
     * @param amount The amount of staking tokens to unstake (uint256).
     */
    function unstake(uint256 tokenId, address recipient, uint256 amount) external;

    /**
     * @notice This function retrieves the claimable reward for a specific
     * reward token and stake duration for the caller.
     * @param tokenId The address of the tokenId whose reward to claim.
     * @param rewardTokenIndex The internal index of the reward token.
     * @param stakeDuration The duration (in seconds) for which the rewards were staked.
     * @return rewardOutput A RewardOutput struct containing details about the claimable reward.
     */
    function getRewardToOwner(
        uint256 tokenId,
        uint8 rewardTokenIndex,
        uint256 stakeDuration
    ) external returns (RewardOutput memory rewardOutput);

    /**
     * @notice This function retrieves the claimable reward for a specific
     * reward token, stake duration, and lockup ID for the caller.
     * @param tokenId The address of the tokenId whose reward to claim.
     * @param rewardTokenIndex The internal index of the reward token.
     * @param stakeDuration The duration (in seconds) for which the rewards were staked.
     * @param lockupId The unique identifier for the specific lockup (optional).
     * @return rewardOutput A RewardOutput struct containing details about the claimable reward.
     */
    function getRewardToOwnerForExistingVeLockup(
        uint256 tokenId,
        uint8 rewardTokenIndex,
        uint256 stakeDuration,
        uint256 lockupId
    ) external returns (RewardOutput memory);

    /**
     * @notice This function retrieves the claimable reward for a specific
     * reward token and stake duration for a specified tokenId and sends it to
     * a recipient.  If the reward is staked in the corresponding veToken, a
     * new lockup in the ve token will be created.
     * @param tokenId The address of the tokenId whose reward to claim.
     * @param recipient The address to which the claimed reward will be sent.
     * @param rewardTokenIndex The internal index of the reward token.
     * @param stakeDuration The duration (in seconds) for which the rewards
     * will be staked in the ve contract.
     * @return rewardOutput A RewardOutput struct containing details about the claimable reward.
     */
    function getReward(
        uint256 tokenId,
        address recipient,
        uint8 rewardTokenIndex,
        uint256 stakeDuration
    ) external returns (RewardOutput memory);

    /**
     * @notice This function retrieves a list of all supported tokens in the reward contract.
     * @param includeStakingToken A flag indicating whether to include the staking token in the list.
     * @return tokens An array of IERC20 token addresses.
     */
    function tokenList(bool includeStakingToken) external view returns (IERC20[] memory tokens);

    /**
     * @notice This function retrieves the veToken contract associated with a
     * specific index within the reward contract.
     * @param index The index of the veToken to retrieve.
     * @return output The IMaverickV2VotingEscrow contract associated with the index.
     */
    function veTokenByIndex(uint8 index) external view returns (IMaverickV2VotingEscrow output);

    /**
     * @notice This function retrieves the reward token contract associated
     * with a specific index within the reward contract.
     * @param index The index of the reward token to retrieve.
     * @return output The IERC20 contract associated with the index.
     */
    function rewardTokenByIndex(uint8 index) external view returns (IERC20 output);

    /**
     * @notice This function calculates the boosted amount an tokenId would
     * receive based on their veToken balance and stake duration.
     * @param tokenId The address of the tokenId for which to calculate the boosted amount.
     * @param veToken The IMaverickV2VotingEscrow contract representing the veToken used for boosting.
     * @param rawAmount The raw (unboosted) amount.
     * @param stakeDuration The duration (in seconds) for which the rewards would be staked.
     * @return earnedAmount The boosted amount the tokenId would receive (uint256).
     * @return asVe A boolean indicating whether the boosted amount is
     * staked in the veToken (true) or is disbursed without ve staking required (false).
     */
    function boostedAmount(
        uint256 tokenId,
        IMaverickV2VotingEscrow veToken,
        uint256 rawAmount,
        uint256 stakeDuration
    ) external view returns (uint256 earnedAmount, bool asVe);

    /**
     * @notice This function is used to push unboosted rewards to the veToken
     * contract.  This unboosted reward amount is then distributed to the
     * veToken holders. This function will revert if less than
     * `UNBOOSTED_MIN_TIME_GAP()` seconds have passed since the last call.
     * @param rewardTokenIndex The internal index of the reward token.
     * @return amount The amount of unboosted rewards pushed (uint128).
     * @return timepoint The timestamp associated with the pushed rewards (uint48).
     * @return batchIndex The batch index for the pushed rewards (uint256).
     */
    function pushUnboostedToVe(
        uint8 rewardTokenIndex
    ) external returns (uint128 amount, uint48 timepoint, uint256 batchIndex);

    /**
     * @notice Mints an NFT stake to a user.  This NFT will not possesses any
     * assets until a user `stake`s asset to the NFT tokenId as part of a
     * separate call.
     * @param recipient The address that owns the output NFT
     */
    function mint(address recipient) external returns (uint256 tokenId);

    /**
     * @notice Mints an NFT stake to caller.  This NFT will not possesses any
     * assets until a user `stake`s asset to the NFT tokenId as part of a
     * separate call.
     */
    function mintToSender() external returns (uint256 tokenId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMaverickV2RewardVault {
    error RewardVaultUnauthorizedAccount(address caller, address owner);

    /**
     * @notice This function allows the owner of the reward vault to withdraw a
     * specified amount of staking tokens to a recipient address.  If non-owner
     * calls this function, it will revert.
     * @param recipient The address to which the withdrawn staking tokens will be sent.
     * @param amount The amount of staking tokens to withdraw.
     */
    function withdraw(address recipient, uint256 amount) external;

    /**
     * @notice This function retrieves the address of the owner of the reward
     * vault contract.
     */
    function owner() external view returns (address);

    /**
     * @notice This function retrieves the address of the ERC20 token used for
     * staking within the reward vault.
     */
    function stakingToken() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC6372} from "@openzeppelin/contracts/interfaces/IERC6372.sol";

import {IHistoricalBalance} from "../votingescrowbase/IHistoricalBalance.sol";

interface IMaverickV2VotingEscrowBase is IVotes, IHistoricalBalance {
    error VotingEscrowTransferNotSupported();
    error VotingEscrowInvalidAddress(address);
    error VotingEscrowInvalidAmount(uint256);
    error VotingEscrowInvalidDuration(uint256 duration, uint256 minDuration, uint256 maxDuration);
    error VotingEscrowInvalidEndTime(uint256 newEnd, uint256 oldEnd);
    error VotingEscrowStakeStillLocked(uint256 currentTime, uint256 endTime);
    error VotingEscrowStakeAlreadyRedeemed();
    error VotingEscrowNotApprovedExtender(address account, address extender, uint256 lockupId);
    error VotingEscrowIncentiveAlreadyClaimed(address account, uint256 batchIndex);
    error VotingEscrowNoIncentivesToClaim(address account, uint256 batchIndex);
    error VotingEscrowInvalidExtendIncentiveToken(IERC20 incentiveToken);
    error VotingEscrowNoSupplyAtTimepoint();
    error VotingEscrowIncentiveTimepointInFuture(uint256 timestamp, uint256 claimTimepoint);

    event Stake(address indexed user, uint256 lockupId, Lockup);
    event Unstake(address indexed user, uint256 lockupId, Lockup);
    event ExtenderApproval(address staker, address extender, uint256 lockupId, bool newState);
    event ClaimIncentiveBatch(uint256 batchIndex, address account, uint256 claimAmount);
    event CreateNewIncentiveBatch(
        address user,
        uint256 amount,
        uint256 timepoint,
        uint256 stakeDuration,
        IERC20 incentiveToken
    );

    struct Lockup {
        uint128 amount;
        uint128 end;
        uint256 votes;
    }

    struct ClaimInformation {
        bool timepointInPast;
        bool hasClaimed;
        uint128 claimAmount;
    }

    struct BatchInformation {
        uint128 totalIncentives;
        uint128 stakeDuration;
        uint48 claimTimepoint;
        IERC20 incentiveToken;
    }

    struct TokenIncentiveTotals {
        uint128 totalIncentives;
        uint128 claimedIncentives;
    }

    // solhint-disable-next-line func-name-mixedcase
    function MIN_STAKE_DURATION() external returns (uint256 duration);

    // solhint-disable-next-line func-name-mixedcase
    function MAX_STAKE_DURATION() external returns (uint256 duration);

    // solhint-disable-next-line func-name-mixedcase
    function YEAR_BASE() external returns (uint256);

    /**
     * @notice This function retrieves the address of the ERC20 token used as the base token for staking and rewards.
     * @return baseToken The address of the IERC20 base token contract.
     */
    function baseToken() external returns (IERC20);

    /**
     * @notice This function retrieves the starting timestamp. This may be used
     * for reward calculations or other time-based logic.
     */
    function startTimestamp() external returns (uint256 timestamp);

    /**
     * @notice This function retrieves the details of a specific lockup for a given staker and lockup index.
     * @param staker The address of the staker for which to retrieve the lockup details.
     * @param index The index of the lockup within the staker's lockup history.
     * @return lockup A Lockup struct containing details about the lockup (see struct definition for details).
     */
    function getLockup(address staker, uint256 index) external view returns (Lockup memory lockup);

    /**
     * @notice This function retrieves the total number of lockups associated with a specific staker.
     * @param staker The address of the staker for which to retrieve the lockup count.
     * @return count The total number of lockups for the staker.
     */
    function lockupCount(address staker) external view returns (uint256 count);

    /**
     * @notice This function simulates a lockup scenario, providing details about the resulting lockup structure for a specified amount and duration.
     * @param amount The amount of tokens to be locked.
     * @param duration The duration of the lockup period.
     * @return lockup A Lockup struct containing details about the simulated lockup (see struct definition for details).
     */
    function previewVotes(uint128 amount, uint256 duration) external view returns (Lockup memory lockup);

    /**
     * @notice This function grants approval for a designated extender contract to manage a specific lockup on behalf of the staker.
     * @param extender The address of the extender contract to be approved.
     * @param lockupId The ID of the lockup for which to grant approval.
     */
    function approveExtender(address extender, uint256 lockupId) external;

    /**
     * @notice This function revokes approval previously granted to an extender contract for managing a specific lockup.
     * @param extender The address of the extender contract whose approval is being revoked.
     * @param lockupId The ID of the lockup for which to revoke approval.
     */
    function revokeExtender(address extender, uint256 lockupId) external;

    /**
     * @notice This function checks whether a specific account has been approved by a staker to manage a particular lockup through an extender contract.
     * @param account The address of the account to check for approval (may be the extender or another account).
     * @param extender The address of the extender contract for which to check approval.
     * @param lockupId The ID of the lockup to verify approval for.
     * @return isApproved True if the account is approved for the lockup, False otherwise (bool).
     */
    function isApprovedExtender(address account, address extender, uint256 lockupId) external view returns (bool);

    /**
     * @notice This function extends the lockup period for the caller (msg.sender) for a specified lockup ID, adding a new duration and amount.
     * @param lockupId The ID of the lockup to be extended.
     * @param duration The additional duration to extend the lockup by.
     * @param amount The additional amount of tokens to be locked.
     * @return newLockup A Lockup struct containing details about the newly extended lockup (see struct definition for details).
     */
    function extendForSender(
        uint256 lockupId,
        uint256 duration,
        uint128 amount
    ) external returns (Lockup memory newLockup);

    /**
     * @notice This function extends the lockup period for a specified account, adding a new duration and amount. The caller (msg.sender) must be authorized to manage the lockup through an extender contract.
     * @param account The address of the account whose lockup is being extended.
     * @param lockupId The ID of the lockup to be extended.
     * @param duration The additional duration to extend the lockup by.
     * @param amount The additional amount of tokens to be locked.
     * @return newLockup A Lockup struct containing details about the newly extended lockup (see struct definition for details).
     */
    function extendForAccount(
        address account,
        uint256 lockupId,
        uint256 duration,
        uint128 amount
    ) external returns (Lockup memory newLockup);

    /**
     * @notice This function merges multiple lockups associated with the caller
     * (msg.sender) into a single new lockup.
     * @param lockupIds An array containing the IDs of the lockups to be merged.
     * @return newLockup A Lockup struct containing details about the newly merged lockup (see struct definition for details).
     */
    function merge(uint256[] memory lockupIds) external returns (Lockup memory newLockup);

    /**
     * @notice This function unstakes the specified lockup ID for the caller (msg.sender), returning the details of the unstaked lockup.
     * @param lockupId The ID of the lockup to be unstaked.
     * @param to The address to which the unstaked tokens should be sent (optional, defaults to msg.sender).
     * @return lockup A Lockup struct containing details about the unstaked lockup (see struct definition for details).
     */
    function unstake(uint256 lockupId, address to) external returns (Lockup memory lockup);

    /**
     * @notice This function is a simplified version of `unstake` that automatically sends the unstaked tokens to the caller (msg.sender).
     * @param lockupId The ID of the lockup to be unstaked.
     * @return lockup A Lockup struct containing details about the unstaked lockup (see struct definition for details).
     */
    function unstakeToSender(uint256 lockupId) external returns (Lockup memory lockup);

    /**
     * @notice This function stakes a specified amount of tokens for the caller
     * (msg.sender) for a defined duration.
     * @param amount The amount of tokens to be staked.
     * @param duration The duration of the lockup period.
     * @return lockup A Lockup struct containing details about the newly
     * created lockup (see struct definition for details).
     */
    function stakeToSender(uint128 amount, uint256 duration) external returns (Lockup memory lockup);

    /**
     * @notice This function stakes a specified amount of tokens for a defined
     * duration, allowing the caller (msg.sender) to specify an optional
     * recipient for the staked tokens.
     * @param amount The amount of tokens to be staked.
     * @param duration The duration of the lockup period.
     * @param to The address to which the staked tokens will be credited (optional, defaults to msg.sender).
     * @return lockup A Lockup struct containing details about the newly
     * created lockup (see struct definition for details).
     */
    function stake(uint128 amount, uint256 duration, address to) external returns (Lockup memory);

    /**
     * @notice This function retrieves the total incentive information for a specific ERC-20 token.
     * @param token The address of the ERC20 token for which to retrieve incentive totals.
     * @return totals A TokenIncentiveTotals struct containing details about
     * the token's incentives (see struct definition for details).
     */
    function incentiveTotals(IERC20 token) external view returns (TokenIncentiveTotals memory);

    /**
     * @notice This function retrieves the total number of created incentive batches.
     * @return count The total number of incentive batches.
     */
    function incentiveBatchCount() external view returns (uint256);

    /**
     * @notice This function retrieves claim information for a specific account and incentive batch index.
     * @param account The address of the account for which to retrieve claim information.
     * @param batchIndex The index of the incentive batch for which to retrieve
     * claim information.
     * @return claimInformation A ClaimInformation struct containing details about the
     * account's claims for the specified batch (see struct definition for
     * details).
     * @return batchInformation A BatchInformation struct containing details about the
     * specified batch (see struct definition for details).
     */
    function claimAndBatchInformation(
        address account,
        uint256 batchIndex
    ) external view returns (ClaimInformation memory claimInformation, BatchInformation memory batchInformation);

    /**
     * @notice This function retrieves batch information for a incentive batch index.
     * @param batchIndex The index of the incentive batch for which to retrieve
     * claim information.
     * @return info A BatchInformation struct containing details about the
     * specified batch (see struct definition for details).
     */
    function incentiveBatchInformation(uint256 batchIndex) external view returns (BatchInformation memory info);

    /**
     * @notice This function allows claiming rewards from a specific incentive
     * batch while simultaneously extending a lockup with the claimed tokens.
     * @param batchIndex The index of the incentive batch from which to claim rewards.
     * @param lockupId The ID of the lockup to be extended with the claimed tokens.
     * @return lockup A Lockup struct containing details about the updated
     * lockup after extension (see struct definition for details).
     * @return claimAmount The amount of tokens claimed from the incentive batch.
     */
    function claimFromIncentiveBatchAndExtend(
        uint256 batchIndex,
        uint256 lockupId
    ) external returns (Lockup memory lockup, uint128 claimAmount);

    /**
     * @notice This function allows claiming rewards from a specific incentive
     * batch, without extending any lockups.
     * @param batchIndex The index of the incentive batch from which to claim rewards.
     * @return lockup A Lockup struct containing details about the user's
     * lockup that might have been affected by the claim (see struct definition
     * for details).
     * @return claimAmount The amount of tokens claimed from the incentive batch.
     */
    function claimFromIncentiveBatch(uint256 batchIndex) external returns (Lockup memory lockup, uint128 claimAmount);

    /**
     * @notice This function creates a new incentive batch for a specified amount
     * of incentive tokens, timepoint, stake duration, and associated ERC-20
     * token. An incentive batch is a reward of incentives put up by the
     * caller at a certain timepoint.  The incentive batch is claimable by ve
     * holders after the timepoint has passed.  The ve holders will receive
     * their incentive pro rata of their vote balance (`pastbalanceOf`) at that
     * timepoint.  The incentivizer can specify that users have to stake the
     * resulting incentive for a given `stakeDuration` number of seconds.
     * `stakeDuration` can either be zero, meaning that no staking is required
     * on redemption, or can be a number between `MIN_STAKE_DURATION()` and
     * `MAX_STAKE_DURATION()`.
     * @param amount The total amount of incentive tokens to be distributed in the batch.
     * @param timepoint The timepoint at which the incentive batch starts accruing rewards.
     * @param stakeDuration The duration of the lockup period required to be
     * eligible for the incentive batch rewards.
     * @param incentiveToken The address of the ERC20 token used for the incentive rewards.
     * @return index The index of the newly created incentive batch.
     */
    function createIncentiveBatch(
        uint128 amount,
        uint48 timepoint,
        uint128 stakeDuration,
        IERC20 incentiveToken
    ) external returns (uint256 index);
}

interface IMaverickV2VotingEscrow is IMaverickV2VotingEscrowBase, IERC20Metadata, IERC6372 {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMaverickV2VotingEscrow} from "../interfaces/IMaverickV2VotingEscrow.sol";
import {IMaverickV2Reward} from "../interfaces/IMaverickV2Reward.sol";
import {MaverickV2Reward} from "../MaverickV2Reward.sol";

library RewardDeployer {
    function deploy(
        string memory name_,
        string memory symbol_,
        IERC20 _stakingToken,
        IERC20[] memory rewardTokens,
        IMaverickV2VotingEscrow[] memory veTokens
    ) external returns (IMaverickV2Reward reward) {
        reward = new MaverickV2Reward(name_, symbol_, _stakingToken, rewardTokens, veTokens);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";
import {SafeCast as Cast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {ONE} from "@maverick/v2-common/contracts/libraries/Constants.sol";
import {Math} from "@maverick/v2-common/contracts/libraries/Math.sol";
import {Multicall} from "@maverick/v2-common/contracts/base/Multicall.sol";
import {Nft} from "@maverick/v2-supplemental/contracts/positionbase/Nft.sol";
import {INft} from "@maverick/v2-supplemental/contracts/positionbase/INft.sol";

import {IMaverickV2Reward} from "./interfaces/IMaverickV2Reward.sol";
import {RewardAccounting} from "./rewardbase/RewardAccounting.sol";
import {MaverickV2RewardVault, IMaverickV2RewardVault} from "./MaverickV2RewardVault.sol";
import {IMaverickV2VotingEscrow} from "./interfaces/IMaverickV2VotingEscrow.sol";

/**
 * @notice This reward contract is used to reward users who stake their
 * `stakingToken` in this contract. The `stakingToken` can be any token with an
 * ERC-20 interface including BoostedPosition LP tokens.
 *
 * @notice Incentive providers can permissionlessly add incentives to this
 * contract that will be disbursed to stakers pro rata over a given duration that
 * the incentive provider specifies as they add incentives.
 *
 * Incentives can be denominated in one of 5 possible reward tokens that the
 * reward contract creator specifies on contract creation.
 *
 * @notice The contract creator also has the option of specifying veTokens
 * associated with each of the up-to-5 reward tokens.  When incentivizing a
 * rewardToken that has a veToken specified, the staking users will receive a
 * boost to their rewards depending on 1) how much ve tokens they own and 2) how
 * long they stake their rewards disbursement.
 */
contract MaverickV2Reward is Nft, RewardAccounting, IMaverickV2Reward, Multicall, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Cast for uint256;

    uint256 internal constant FOUR_YEARS = 1460 days;
    uint256 internal constant BASE_STAKING_FACTOR = 0.2e18;
    uint256 internal constant STAKING_FACTOR_SLOPE = 0.8e18;
    uint256 internal constant BASE_PRORATA_FACTOR = 0.75e18;
    uint256 internal constant PRORATA_FACTOR_SLOPE = 0.25e18;

    /// @inheritdoc IMaverickV2Reward
    uint256 public constant UNBOOSTED_MIN_TIME_GAP = 13 weeks;

    /// @inheritdoc IMaverickV2Reward
    IERC20 public immutable stakingToken;

    IERC20 private immutable rewardToken0;
    IERC20 private immutable rewardToken1;
    IERC20 private immutable rewardToken2;
    IERC20 private immutable rewardToken3;
    IERC20 private immutable rewardToken4;
    IMaverickV2VotingEscrow private immutable veToken0;
    IMaverickV2VotingEscrow private immutable veToken1;
    IMaverickV2VotingEscrow private immutable veToken2;
    IMaverickV2VotingEscrow private immutable veToken3;
    IMaverickV2VotingEscrow private immutable veToken4;

    /// @inheritdoc IMaverickV2Reward
    uint256 public constant MAX_DURATION = 40 days;
    /// @inheritdoc IMaverickV2Reward
    uint256 public constant MIN_DURATION = 3 days;

    struct RewardData {
        // Timestamp of when the rewards finish
        uint64 finishAt;
        // Minimum of last updated time and reward finish time
        uint64 updatedAt;
        // Reward to be paid out per second
        uint128 rewardRate;
        // Reward amount escrowed for staked users up to current time. this
        // value is incremented on each action as by the amount of reward
        // globally accumulated since the last action.  when a user collects
        // reward, this amount is decremented.
        uint128 escrowedReward;
        // Accumulator of the amount of this reward token not taken as part of
        // getReward boosting.  this amount gets pushed to the associated ve
        // contract as an incentive for the ve holders.
        uint128 unboostedAmount;
        // Timestamp of last time unboosted reward was pushed to ve contract as
        // incentive
        uint256 lastUnboostedPushTimestamp;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardPerTokenStored;
        // User tokenId => rewardPerTokenStored
        mapping(uint256 tokenId => uint256) userRewardPerTokenPaid;
        // User tokenId => rewards to be claimed
        mapping(uint256 tokenId => uint128) rewards;
    }
    RewardData[5] public rewardData;

    uint256 public immutable rewardTokenCount;
    IMaverickV2RewardVault public immutable vault;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC20 _stakingToken,
        IERC20[] memory rewardTokens,
        IMaverickV2VotingEscrow[] memory veTokens
    ) Nft(name_, symbol_) {
        stakingToken = _stakingToken;
        vault = new MaverickV2RewardVault(_stakingToken);
        rewardTokenCount = rewardTokens.length;
        if (rewardTokenCount > 0) {
            rewardToken0 = rewardTokens[0];
            veToken0 = veTokens[0];
        }
        if (rewardTokenCount > 1) {
            rewardToken1 = rewardTokens[1];
            veToken1 = veTokens[1];
        }
        if (rewardTokenCount > 2) {
            rewardToken2 = rewardTokens[2];
            veToken2 = veTokens[2];
        }
        if (rewardTokenCount > 3) {
            rewardToken3 = rewardTokens[3];
            veToken3 = veTokens[3];
        }
        if (rewardTokenCount > 4) {
            rewardToken4 = rewardTokens[4];
            veToken4 = veTokens[4];
        }
    }

    modifier checkAmount(uint256 amount) {
        if (amount == 0) revert RewardZeroAmount();
        _;
    }

    /////////////////////////////////////
    /// Stake Management Functions
    /////////////////////////////////////

    /// @inheritdoc IMaverickV2Reward
    function mint(address recipient) public returns (uint256 tokenId) {
        tokenId = _mint(recipient);
    }

    /// @inheritdoc IMaverickV2Reward
    function mintToSender() public returns (uint256 tokenId) {
        tokenId = _mint(msg.sender);
    }

    /// @inheritdoc IMaverickV2Reward
    function stake(uint256 tokenId) public returns (uint256 amount, uint256 stakedTokenId) {
        // reverts if token is not owned
        stakedTokenId = tokenId;
        if (stakedTokenId == 0) {
            if (tokenOfOwnerByIndexExists(msg.sender, 0)) {
                stakedTokenId = tokenOfOwnerByIndex(msg.sender, 0);
            } else {
                stakedTokenId = mint(msg.sender);
            }
        }
        amount = _stake(stakedTokenId);
    }

    /// @inheritdoc IMaverickV2Reward
    function transferAndStake(uint256 tokenId, uint256 _amount) public returns (uint256 amount, uint256 stakedTokenId) {
        stakingToken.safeTransferFrom(msg.sender, address(vault), _amount);
        return stake(tokenId);
    }

    /// @inheritdoc IMaverickV2Reward
    function unstakeToOwner(uint256 tokenId, uint256 amount) public onlyTokenIdAuthorizedUser(tokenId) {
        address owner = ownerOf(tokenId);
        _unstake(tokenId, owner, amount);
    }

    /// @inheritdoc IMaverickV2Reward
    function unstake(uint256 tokenId, address recipient, uint256 amount) public onlyTokenIdAuthorizedUser(tokenId) {
        _unstake(tokenId, recipient, amount);
    }

    /// @inheritdoc IMaverickV2Reward
    function getRewardToOwner(
        uint256 tokenId,
        uint8 rewardTokenIndex,
        uint256 stakeDuration
    ) external onlyTokenIdAuthorizedUser(tokenId) returns (RewardOutput memory) {
        address owner = ownerOf(tokenId);
        return _getReward(tokenId, owner, rewardTokenIndex, stakeDuration, type(uint256).max);
    }

    /// @inheritdoc IMaverickV2Reward
    function getRewardToOwnerForExistingVeLockup(
        uint256 tokenId,
        uint8 rewardTokenIndex,
        uint256 stakeDuration,
        uint256 lockupId
    ) external onlyTokenIdAuthorizedUser(tokenId) returns (RewardOutput memory) {
        address owner = ownerOf(tokenId);
        return _getReward(tokenId, owner, rewardTokenIndex, stakeDuration, lockupId);
    }

    /// @inheritdoc IMaverickV2Reward
    function getReward(
        uint256 tokenId,
        address recipient,
        uint8 rewardTokenIndex,
        uint256 stakeDuration
    ) external onlyTokenIdAuthorizedUser(tokenId) returns (RewardOutput memory) {
        return _getReward(tokenId, recipient, rewardTokenIndex, stakeDuration, type(uint256).max);
    }

    /////////////////////////////////////
    /// Admin Functions
    /////////////////////////////////////

    /// @inheritdoc IMaverickV2Reward
    function pushUnboostedToVe(
        uint8 rewardTokenIndex
    ) public returns (uint128 amount, uint48 timepoint, uint256 batchIndex) {
        IMaverickV2VotingEscrow ve = veTokenByIndex(rewardTokenIndex);
        IERC20 token = rewardTokenByIndex(rewardTokenIndex);
        RewardData storage data = rewardData[rewardTokenIndex];
        amount = data.unboostedAmount;
        if (amount == 0) revert RewardZeroAmount();
        if (block.timestamp <= data.lastUnboostedPushTimestamp + UNBOOSTED_MIN_TIME_GAP) {
            // revert if not enough time has passed; will not revert if this is
            // the first call and last timestamp is zero.
            revert RewardUnboostedTimePeriodNotMet(
                block.timestamp,
                data.lastUnboostedPushTimestamp + UNBOOSTED_MIN_TIME_GAP
            );
        }

        data.unboostedAmount = 0;
        data.lastUnboostedPushTimestamp = block.timestamp;

        token.forceApprove(address(ve), amount);

        timepoint = Time.timestamp();
        batchIndex = ve.createIncentiveBatch(amount, timepoint, ve.MAX_STAKE_DURATION().toUint128(), token);
    }

    /////////////////////////////////////
    /// View Functions
    /////////////////////////////////////

    /// @inheritdoc IMaverickV2Reward
    function rewardInfo() public view returns (RewardInfo[] memory info) {
        uint256 length = rewardTokenCount;
        info = new RewardInfo[](length);
        for (uint8 i; i < length; i++) {
            RewardData storage data = rewardData[i];
            info[i] = RewardInfo({
                finishAt: data.finishAt,
                updatedAt: data.updatedAt,
                rewardRate: data.rewardRate,
                rewardPerTokenStored: data.rewardPerTokenStored,
                rewardToken: rewardTokenByIndex(i),
                veRewardToken: veTokenByIndex(i),
                unboostedAmount: data.unboostedAmount,
                escrowedReward: data.escrowedReward,
                lastUnboostedPushTimestamp: data.lastUnboostedPushTimestamp
            });
        }
    }

    /// @inheritdoc IMaverickV2Reward
    function contractInfo() external view returns (RewardInfo[] memory info, ContractInfo memory _contractInfo) {
        info = rewardInfo();
        _contractInfo.name = name();
        _contractInfo.symbol = symbol();
        _contractInfo.totalSupply = stakeTotalSupply();
        _contractInfo.stakingToken = stakingToken;
    }

    /// @inheritdoc IMaverickV2Reward
    function earned(uint256 tokenId) public view returns (EarnedInfo[] memory earnedInfo) {
        uint256 length = rewardTokenCount;
        earnedInfo = new EarnedInfo[](length);
        for (uint8 i; i < length; i++) {
            RewardData storage data = rewardData[i];
            earnedInfo[i] = EarnedInfo({earned: _earned(tokenId, data), rewardToken: rewardTokenByIndex(i)});
        }
    }

    /// @inheritdoc IMaverickV2Reward
    function earned(uint256 tokenId, IERC20 rewardTokenAddress) public view returns (uint256) {
        uint256 rewardTokenIndex = tokenIndex(rewardTokenAddress);
        RewardData storage data = rewardData[rewardTokenIndex];
        return _earned(tokenId, data);
    }

    function _earned(uint256 tokenId, RewardData storage data) internal view returns (uint256) {
        return
            data.rewards[tokenId] +
            Math.mulFloor(
                stakeBalanceOf(tokenId),
                Math.clip(data.rewardPerTokenStored + _deltaRewardPerToken(data), data.userRewardPerTokenPaid[tokenId])
            );
    }

    /// @inheritdoc IMaverickV2Reward
    function tokenIndex(IERC20 rewardToken) public view returns (uint8 rewardTokenIndex) {
        if (rewardToken == rewardToken0) return 0;
        if (rewardToken == rewardToken1) return 1;
        if (rewardToken == rewardToken2) return 2;
        if (rewardToken == rewardToken3) return 3;
        if (rewardToken == rewardToken4) return 4;
        revert RewardNotValidRewardToken(rewardToken);
    }

    /// @inheritdoc IMaverickV2Reward
    function rewardTokenByIndex(uint8 index) public view returns (IERC20 output) {
        if (index >= rewardTokenCount) revert RewardNotValidIndex(index);
        if (index == 0) return rewardToken0;
        if (index == 1) return rewardToken1;
        if (index == 2) return rewardToken2;
        if (index == 3) return rewardToken3;
        return rewardToken4;
    }

    /// @inheritdoc IMaverickV2Reward
    function veTokenByIndex(uint8 index) public view returns (IMaverickV2VotingEscrow output) {
        if (index >= rewardTokenCount) revert RewardNotValidIndex(index);
        if (index == 0) return veToken0;
        if (index == 1) return veToken1;
        if (index == 2) return veToken2;
        if (index == 3) return veToken3;
        return veToken4;
    }

    /// @inheritdoc IMaverickV2Reward
    function tokenList(bool includeStakingToken) public view returns (IERC20[] memory tokens) {
        uint256 length = includeStakingToken ? rewardTokenCount + 1 : rewardTokenCount;
        tokens = new IERC20[](length);
        if (rewardTokenCount > 0) tokens[0] = rewardToken0;
        if (rewardTokenCount > 1) tokens[1] = rewardToken1;
        if (rewardTokenCount > 2) tokens[2] = rewardToken2;
        if (rewardTokenCount > 3) tokens[3] = rewardToken3;
        if (rewardTokenCount > 4) tokens[4] = rewardToken4;
        if (includeStakingToken) tokens[rewardTokenCount] = stakingToken;
    }

    /**
     * @notice Updates the global reward state for a given reward token.
     * @dev Each time a user stakes or unstakes or a incentivizer adds
     * incentives, this function must be called in order to checkpoint the
     * rewards state before the new stake/unstake/notify occurs.
     */
    function _updateGlobalReward(RewardData storage data) internal {
        uint256 reward = _deltaRewardPerToken(data);
        if (reward != 0) {
            data.rewardPerTokenStored += reward;
            // round up to ensure enough reward is set aside
            data.escrowedReward += Math.mulCeil(reward, stakeTotalSupply()).toUint128();
        }
        data.updatedAt = _lastTimeRewardApplicable(data.finishAt).toUint64();
    }

    /**
     * @notice Updates the reward state associated with an tokenId.  Also
     * updates the global reward state.
     * @dev This function checkpoints the data for a user before they
     * stake/unstake.
     */
    function _updateReward(uint256 tokenId, RewardData storage data) internal {
        _updateGlobalReward(data);
        uint256 reward = _deltaEarned(tokenId, data);
        if (reward != 0) data.rewards[tokenId] += reward.toUint128();
        data.userRewardPerTokenPaid[tokenId] = data.rewardPerTokenStored;
    }

    /**
     * @notice Amount an tokenId has earned since that tokenId last did a
     * stake/unstake.
     * @dev `deltaEarned = balance * (rewardPerToken - userRewardPerTokenPaid)`
     */
    function _deltaEarned(uint256 tokenId, RewardData storage data) internal view returns (uint256) {
        return
            Math.mulFloor(
                stakeBalanceOf(tokenId),
                Math.clip(data.rewardPerTokenStored, data.userRewardPerTokenPaid[tokenId])
            );
    }

    /**
     * @notice Amount of new rewards accrued to tokens since last checkpoint.
     */
    function _deltaRewardPerToken(RewardData storage data) internal view returns (uint256) {
        uint256 timeDiff = Math.clip(_lastTimeRewardApplicable(data.finishAt), data.updatedAt);
        if (timeDiff == 0 || stakeTotalSupply() == 0 || data.rewardRate == 0) {
            return 0;
        }
        return Math.mulDivFloor(data.rewardRate, timeDiff * ONE, stakeTotalSupply());
    }

    /**
     * @notice The smaller of: 1) time of end of reward period and 2) current
     * block timestamp.
     */
    function _lastTimeRewardApplicable(uint256 dataFinishAt) internal view returns (uint256) {
        return Math.min(dataFinishAt, block.timestamp);
    }

    /**
     * @notice Update all rewards.
     */
    function _updateAllRewards(uint256 tokenId) internal {
        for (uint8 i; i < rewardTokenCount; i++) {
            RewardData storage data = rewardData[i];

            _updateReward(tokenId, data);
        }
    }

    /////////////////////////////////////
    /// Internal User Functions
    /////////////////////////////////////

    function _stake(uint256 tokenId) internal nonReentrant returns (uint256 amount) {
        _requireOwned(tokenId);
        _updateAllRewards(tokenId);
        amount = Math.clip(stakingToken.balanceOf(address(vault)), stakeTotalSupply());
        if (amount != 0) _mintStake(tokenId, amount);
    }

    /**
     * @notice Functions using this function must check that sender has access
     * to the tokenId for this to be / safely called.
     */
    function _unstake(uint256 tokenId, address recipient, uint256 amount) internal nonReentrant checkAmount(amount) {
        _updateAllRewards(tokenId);
        _burnStake(tokenId, amount);
        vault.withdraw(recipient, amount);
    }

    /// @inheritdoc IMaverickV2Reward
    function boostedAmount(
        uint256 tokenId,
        IMaverickV2VotingEscrow veToken,
        uint256 rawAmount,
        uint256 stakeDuration
    ) public view returns (uint256 earnedAmount, bool asVe) {
        if (address(veToken) != address(0)) {
            address owner = ownerOf(tokenId);
            uint256 userVeProRata = Math.divFloor(veToken.balanceOf(owner), veToken.totalSupply());
            uint256 userRewardProRata = Math.divFloor(stakeBalanceOf(tokenId), stakeTotalSupply());
            // pro rata ratio can be bigger than one: need min operation
            uint256 proRataFactor = Math.min(
                ONE,
                BASE_PRORATA_FACTOR + Math.mulDivFloor(PRORATA_FACTOR_SLOPE, userVeProRata, userRewardProRata)
            );
            uint256 stakeFactor = Math.min(
                ONE,
                BASE_STAKING_FACTOR + Math.mulDivFloor(STAKING_FACTOR_SLOPE, stakeDuration, FOUR_YEARS)
            );

            earnedAmount = Math.mulFloor(Math.mulFloor(rawAmount, stakeFactor), proRataFactor);
            // if duration is non-zero, this reward is collected as ve
            asVe = stakeDuration > 0;
        } else {
            earnedAmount = rawAmount;
        }
    }

    /**
     * @notice Internal function for computing the boost and then
     * transferring/staking the resulting rewards.  Can not be safely called
     * without checking that the caller has permissions to access the tokenId.
     */
    function _boostAndPay(
        uint256 tokenId,
        address recipient,
        IERC20 rewardToken,
        IMaverickV2VotingEscrow veToken,
        uint256 rawAmount,
        uint256 stakeDuration,
        uint256 lockupId
    ) internal returns (RewardOutput memory rewardOutput) {
        (rewardOutput.amount, rewardOutput.asVe) = boostedAmount(tokenId, veToken, rawAmount, stakeDuration);
        if (rewardOutput.asVe) {
            rewardToken.forceApprove(address(veToken), rewardOutput.amount);
            rewardOutput.veContract = veToken;
            if (lockupId == type(uint256).max) {
                veToken.stake(rewardOutput.amount.toUint128(), stakeDuration, recipient);
            } else {
                veToken.extendForAccount(recipient, lockupId, stakeDuration, rewardOutput.amount.toUint128());
            }
        } else {
            rewardToken.safeTransfer(recipient, rewardOutput.amount);
        }
    }

    /**
     * @notice Internal getReward function.  Can not be safely called without
     * checking that the caller has permissions to access the account.
     */
    function _getReward(
        uint256 tokenId,
        address recipient,
        uint8 rewardTokenIndex,
        uint256 stakeDuration,
        uint256 lockupId
    ) internal nonReentrant returns (RewardOutput memory rewardOutput) {
        RewardData storage data = rewardData[rewardTokenIndex];
        _updateReward(tokenId, data);
        uint128 reward = data.rewards[tokenId];
        if (reward != 0) {
            data.rewards[tokenId] = 0;
            data.escrowedReward -= reward;
            rewardOutput = _boostAndPay(
                tokenId,
                recipient,
                rewardTokenByIndex(rewardTokenIndex),
                veTokenByIndex(rewardTokenIndex),
                reward,
                stakeDuration,
                lockupId
            );
            if (reward > rewardOutput.amount) {
                // set aside unboosted amount; unsafe cast is okay given conditional
                data.unboostedAmount += uint128(reward - rewardOutput.amount);
            }
            emit GetReward(
                msg.sender,
                tokenId,
                recipient,
                rewardTokenIndex,
                stakeDuration,
                rewardTokenByIndex(rewardTokenIndex),
                rewardOutput,
                lockupId
            );
        }
    }

    /////////////////////////////////////
    /// Add Reward
    /////////////////////////////////////

    /// @inheritdoc IMaverickV2Reward
    function notifyRewardAmount(IERC20 rewardToken, uint256 duration) public nonReentrant returns (uint256) {
        if (duration < MIN_DURATION) revert RewardDurationOutOfBounds(duration, MIN_DURATION, MAX_DURATION);
        if (duration > MAX_DURATION) revert RewardDurationOutOfBounds(duration, MIN_DURATION, MAX_DURATION);
        return _notifyRewardAmount(rewardToken, duration);
    }

    /// @inheritdoc IMaverickV2Reward
    function transferAndNotifyRewardAmount(
        IERC20 rewardToken,
        uint256 duration,
        uint256 amount
    ) public returns (uint256) {
        rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        return notifyRewardAmount(rewardToken, duration);
    }

    /**
     * @notice Called by reward depositor to recompute the reward rate.  If
     * notifier sends more than remaining amount, then notifier sets the rate.
     * Else, we extend the duration at the current rate.
     */
    function _notifyRewardAmount(IERC20 rewardToken, uint256 duration) internal returns (uint256) {
        uint8 rewardTokenIndex = tokenIndex(rewardToken);
        RewardData storage data = rewardData[rewardTokenIndex];
        _updateGlobalReward(data);
        uint256 remainingRewards = Math.clip(
            rewardTokenByIndex(rewardTokenIndex).balanceOf(address(this)),
            data.escrowedReward
        );
        uint256 timeRemaining = Math.clip(data.finishAt, block.timestamp);

        // timeRemaining * data.rewardRate is the amount of rewards on the
        // contract before the new amount was added. we are checking to see if
        // the reamaining rewards is bigger than twice this value.  in this
        // case, the new notifier has brought more rewards than were already on
        // contract and they get to set the new rewards rate.
        if (remainingRewards > timeRemaining * data.rewardRate * 2 || data.rewardRate == 0) {
            // if notifying new amount is bigger than, notifier gets to set the rate
            data.rewardRate = (remainingRewards / duration).toUint128();
        } else {
            // if notifier doesn't bring enough, we extend the duration at the
            // same rate
            duration = remainingRewards / data.rewardRate;
        }

        data.finishAt = (block.timestamp + duration).toUint64();
        // unsafe case is ok given safe cast in previous statement
        data.updatedAt = uint64(block.timestamp);
        emit NotifyRewardAmount(msg.sender, rewardToken, remainingRewards, duration, data.rewardRate);
        return duration;
    }

    /////////////////////////////////////
    /// Required Overrides
    /////////////////////////////////////

    function tokenURI(uint256 tokenId) public view virtual override(Nft, INft) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function name() public view override(INft, Nft) returns (string memory) {
        return super.name();
    }

    function symbol() public view override(INft, Nft) returns (string memory) {
        return super.symbol();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMaverickV2RewardVault} from "./interfaces/IMaverickV2RewardVault.sol";

/**
 * @notice Vault contract with owner-only withdraw function.  Used by the
 * Reward contract to segregate staking funds from incentive rewards funds.
 */
contract MaverickV2RewardVault is IMaverickV2RewardVault {
    using SafeERC20 for IERC20;

    /// @inheritdoc IMaverickV2RewardVault
    address public immutable owner;

    /// @inheritdoc IMaverickV2RewardVault
    IERC20 public immutable stakingToken;

    constructor(IERC20 _stakingToken) {
        owner = msg.sender;
        stakingToken = _stakingToken;
    }

    /// @inheritdoc IMaverickV2RewardVault
    function withdraw(address recipient, uint256 amount) public {
        if (owner != msg.sender) {
            revert RewardVaultUnauthorizedAccount(msg.sender, owner);
        }
        stakingToken.safeTransfer(recipient, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

interface IRewardAccounting {
    error InsufficientBalance(uint256 tokenId, uint256 currentBalance, uint256 value);

    /**
     * @notice Balance of stake for a given `tokenId` account.
     */
    function stakeBalanceOf(uint256 tokenId) external view returns (uint256 balance);

    /**
     * @notice Sum of all balances across all tokenIds.
     */
    function stakeTotalSupply() external view returns (uint256 supply);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IRewardAccounting} from "./IRewardAccounting.sol";

/**
 * @notice Provides ERC20-like functions for minting, burning, balance tracking
 * and total supply.  Tracking is based on a tokenId user index instead of an
 * address.
 */
abstract contract RewardAccounting is IRewardAccounting {
    mapping(uint256 account => uint256) private _stakeBalances;

    uint256 private _stakeTotalSupply;

    /// @inheritdoc IRewardAccounting
    function stakeBalanceOf(uint256 tokenId) public view returns (uint256 balance) {
        balance = _stakeBalances[tokenId];
    }

    /// @inheritdoc IRewardAccounting
    function stakeTotalSupply() public view returns (uint256 supply) {
        supply = _stakeTotalSupply;
    }

    /**
     * @notice Mint to staking account for a tokenId account.
     */
    function _mintStake(uint256 tokenId, uint256 value) internal {
        // checked; will revert if supply overflows.
        _stakeTotalSupply += value;
        unchecked {
            // unchecked; totalsupply will overflow before balance for a given
            // account does.
            _stakeBalances[tokenId] += value;
        }
    }

    /**
     * @notice Burn from staking account for a tokenId account.
     */
    function _burnStake(uint256 tokenId, uint256 value) internal {
        uint256 currentBalance = _stakeBalances[tokenId];
        if (value > currentBalance) revert InsufficientBalance(tokenId, currentBalance, value);
        unchecked {
            _stakeTotalSupply -= value;
            _stakeBalances[tokenId] = currentBalance - value;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

interface IHistoricalBalance {
    /**
     * @notice This function retrieves the historical balance of an account at
     * a specific point in time.
     * @param account The address of the account for which to retrieve the
     * historical balance.
     * @param timepoint The timepoint (block number or timestamp depending on
     * implementation) at which to query the balance (uint256).
     * @return balance The balance of the account at the specified timepoint.
     */
    function getPastBalanceOf(address account, uint256 timepoint) external view returns (uint256 balance);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INft is IERC721Enumerable {
    /**
     * @notice Check if an NFT exists for a given owner and index.
     */
    function tokenOfOwnerByIndexExists(address owner, uint256 index) external view returns (bool);

    /**
     * @notice Return Id of the next token minted.
     */
    function nextTokenId() external view returns (uint256 nextTokenId_);

    /**
     * @notice Check if the caller has access to a specific NFT by tokenId.
     */
    function checkAuthorized(address spender, uint256 tokenId) external view returns (address owner);

    /**
     * @notice List of tokenIds by owner.
     */
    function tokenIdsOfOwner(address owner) external view returns (uint256[] memory tokenIds);

    /**
     * @notice Get the token URI for a given tokenId.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {ERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import {INft} from "./INft.sol";

/**
 * @notice Extensions to ECR-721 to support an image contract and owner
 * enumeration.
 */
abstract contract Nft is ERC721Enumerable, INft {
    uint256 private _nextTokenId = 1;

    constructor(string memory __name, string memory __symbol) ERC721(__name, __symbol) {}

    /**
     * @notice Internal function to mint a new NFT and assign it to the
     * specified address.
     * @param to The address to which the NFT will be minted.
     * @return tokenId The ID of the newly minted NFT.
     */
    function _mint(address to) internal returns (uint256 tokenId) {
        super._mint(to, _nextTokenId);
        tokenId = _nextTokenId++;
    }

    /**
     * @notice Modifier to restrict access to functions to the owner of a
     * specific NFT by its tokenId.
     */
    modifier onlyTokenIdAuthorizedUser(uint256 tokenId) {
        checkAuthorized(msg.sender, tokenId);
        _;
    }

    /// @inheritdoc INft
    function nextTokenId() public view returns (uint256 nextTokenId_) {
        return _nextTokenId;
    }

    /// @inheritdoc INft
    function tokenOfOwnerByIndexExists(address ownerToCheck, uint256 index) public view returns (bool exists) {
        return index < balanceOf(ownerToCheck);
    }

    /// @inheritdoc INft
    function tokenIdsOfOwner(address owner) public view returns (uint256[] memory tokenIds) {
        uint256 tokenCount = balanceOf(owner);
        tokenIds = new uint256[](tokenCount);
        for (uint256 k; k < tokenCount; k++) {
            tokenIds[k] = tokenOfOwnerByIndex(owner, k);
        }
    }

    /// @inheritdoc INft
    function checkAuthorized(address spender, uint256 tokenId) public view returns (address owner) {
        owner = ownerOf(tokenId);
        _checkAuthorized(owner, spender, tokenId);
    }

    // ************************************************************
    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function name() public view virtual override(INft, ERC721) returns (string memory) {
        return super.name();
    }

    function symbol() public view virtual override(INft, ERC721) returns (string memory) {
        return super.symbol();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(INft, ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.20;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 */
interface IVotes {
    /**
     * @dev The signature used has expired.
     */
    error VotesExpiredSignature(uint256 expiry);

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of voting units.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     */
    function getPastVotes(address account, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC6372.sol)

pragma solidity ^0.8.20;

interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "./IERC721.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC721Metadata} from "./extensions/IERC721Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {Strings} from "../../utils/Strings.sol";
import {IERC165, ERC165} from "../../utils/introspection/ERC165.sol";
import {IERC721Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    mapping(uint256 tokenId => address) private _owners;

    mapping(address owner => uint256) private _balances;

    mapping(uint256 tokenId => address) private _tokenApprovals;

    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        unchecked {
            _balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                _balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.20;

import {ERC721} from "../ERC721.sol";
import {IERC721Enumerable} from "./IERC721Enumerable.sol";
import {IERC165} from "../../../utils/introspection/ERC165.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds enumerability
 * of all the token ids in the contract as well as all token ids owned by each account.
 *
 * CAUTION: `ERC721` extensions that implement custom `balanceOf` logic, such as `ERC721Consecutive`,
 * interfere with enumerability and should not be used together with `ERC721Enumerable`.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address owner => mapping(uint256 index => uint256)) private _ownedTokens;
    mapping(uint256 tokenId => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;
    mapping(uint256 tokenId => uint256) private _allTokensIndex;

    /**
     * @dev An `owner`'s token query was out of bounds for `index`.
     *
     * NOTE: The owner being `address(0)` indicates a global out of bounds index.
     */
    error ERC721OutOfBoundsIndex(address owner, uint256 index);

    /**
     * @dev Batch mint is not allowed.
     */
    error ERC721EnumerableForbiddenBatchMint();

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        if (index >= balanceOf(owner)) {
            revert ERC721OutOfBoundsIndex(owner, index);
        }
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        if (index >= totalSupply()) {
            revert ERC721OutOfBoundsIndex(address(0), index);
        }
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_update}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address previousOwner = super._update(to, tokenId, auth);

        if (previousOwner == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (previousOwner != to) {
            _removeTokenFromOwnerEnumeration(previousOwner, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (previousOwner != to) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }

        return previousOwner;
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to) - 1;
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * See {ERC721-_increaseBalance}. We need that to account tokens that were minted in batch
     */
    function _increaseBalance(address account, uint128 amount) internal virtual override {
        if (amount > 0) {
            revert ERC721EnumerableForbiddenBatchMint();
        }
        super._increaseBalance(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

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
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

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
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
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
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
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
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
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
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
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
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
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
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
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
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
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
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
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
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
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
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
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
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
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
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
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
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
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
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
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
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
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
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
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
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
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
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
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
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
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
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
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
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
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
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
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
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
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
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
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
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
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
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
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
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
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
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
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
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
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
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
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
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
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
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
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
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
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
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
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
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
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
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
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
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
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
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
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
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
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
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
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
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
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
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
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
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
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
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
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
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
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
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
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
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
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
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
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
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
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
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
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
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
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
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
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
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
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
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
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
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
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
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
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
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
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
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/types/Time.sol)

pragma solidity ^0.8.20;

import {Math} from "../math/Math.sol";
import {SafeCast} from "../math/SafeCast.sol";

/**
 * @dev This library provides helpers for manipulating time-related objects.
 *
 * It uses the following types:
 * - `uint48` for timepoints
 * - `uint32` for durations
 *
 * While the library doesn't provide specific types for timepoints and duration, it does provide:
 * - a `Delay` type to represent duration that can be programmed to change value automatically at a given point
 * - additional helper functions
 */
library Time {
    using Time for *;

    /**
     * @dev Get the block timestamp as a Timepoint.
     */
    function timestamp() internal view returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }

    /**
     * @dev Get the block number as a Timepoint.
     */
    function blockNumber() internal view returns (uint48) {
        return SafeCast.toUint48(block.number);
    }

    // ==================================================== Delay =====================================================
    /**
     * @dev A `Delay` is a uint32 duration that can be programmed to change value automatically at a given point in the
     * future. The "effect" timepoint describes when the transitions happens from the "old" value to the "new" value.
     * This allows updating the delay applied to some operation while keeping some guarantees.
     *
     * In particular, the {update} function guarantees that if the delay is reduced, the old delay still applies for
     * some time. For example if the delay is currently 7 days to do an upgrade, the admin should not be able to set
     * the delay to 0 and upgrade immediately. If the admin wants to reduce the delay, the old delay (7 days) should
     * still apply for some time.
     *
     *
     * The `Delay` type is 112 bits long, and packs the following:
     *
     * ```
     *   | [uint48]: effect date (timepoint)
     *   |           | [uint32]: value before (duration)
     *   ↓           ↓       ↓ [uint32]: value after (duration)
     * 0xAAAAAAAAAAAABBBBBBBBCCCCCCCC
     * ```
     *
     * NOTE: The {get} and {withUpdate} functions operate using timestamps. Block number based delays are not currently
     * supported.
     */
    type Delay is uint112;

    /**
     * @dev Wrap a duration into a Delay to add the one-step "update in the future" feature
     */
    function toDelay(uint32 duration) internal pure returns (Delay) {
        return Delay.wrap(duration);
    }

    /**
     * @dev Get the value at a given timepoint plus the pending value and effect timepoint if there is a scheduled
     * change after this timepoint. If the effect timepoint is 0, then the pending value should not be considered.
     */
    function _getFullAt(Delay self, uint48 timepoint) private pure returns (uint32, uint32, uint48) {
        (uint32 valueBefore, uint32 valueAfter, uint48 effect) = self.unpack();
        return effect <= timepoint ? (valueAfter, 0, 0) : (valueBefore, valueAfter, effect);
    }

    /**
     * @dev Get the current value plus the pending value and effect timepoint if there is a scheduled change. If the
     * effect timepoint is 0, then the pending value should not be considered.
     */
    function getFull(Delay self) internal view returns (uint32, uint32, uint48) {
        return _getFullAt(self, timestamp());
    }

    /**
     * @dev Get the current value.
     */
    function get(Delay self) internal view returns (uint32) {
        (uint32 delay, , ) = self.getFull();
        return delay;
    }

    /**
     * @dev Update a Delay object so that it takes a new duration after a timepoint that is automatically computed to
     * enforce the old delay at the moment of the update. Returns the updated Delay object and the timestamp when the
     * new delay becomes effective.
     */
    function withUpdate(
        Delay self,
        uint32 newValue,
        uint32 minSetback
    ) internal view returns (Delay updatedDelay, uint48 effect) {
        uint32 value = self.get();
        uint32 setback = uint32(Math.max(minSetback, value > newValue ? value - newValue : 0));
        effect = timestamp() + setback;
        return (pack(value, newValue, effect), effect);
    }

    /**
     * @dev Split a delay into its components: valueBefore, valueAfter and effect (transition timepoint).
     */
    function unpack(Delay self) internal pure returns (uint32 valueBefore, uint32 valueAfter, uint48 effect) {
        uint112 raw = Delay.unwrap(self);

        valueAfter = uint32(raw);
        valueBefore = uint32(raw >> 32);
        effect = uint48(raw >> 64);

        return (valueBefore, valueAfter, effect);
    }

    /**
     * @dev pack the components into a Delay object.
     */
    function pack(uint32 valueBefore, uint32 valueAfter, uint48 effect) internal pure returns (Delay) {
        return Delay.wrap((uint112(effect) << 64) | (uint112(valueBefore) << 32) | uint112(valueAfter));
    }
}