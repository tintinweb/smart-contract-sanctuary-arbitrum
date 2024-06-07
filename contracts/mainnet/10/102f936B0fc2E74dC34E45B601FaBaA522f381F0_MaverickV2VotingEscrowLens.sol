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

import {IMaverickV2VotingEscrow} from "./IMaverickV2VotingEscrow.sol";
import {IMaverickV2VotingEscrowWSync} from "./IMaverickV2VotingEscrowWSync.sol";

interface IMaverickV2VotingEscrowLens {
    /**
     * @notice This function retrieves paginated claim information for a specific account
     * and claim index range within a provided Maverick V2 Voting Escrow
     * (veToken) contract.
     * @param ve The address of the IMaverickV2VotingEscrow contract for which to retrieve claim information.
     * @param account The address of the account for which to retrieve claim information.
     * @param startIndex The starting index for the desired range of claims.
     * @param endIndex The ending index for the desired range of claims.
     */
    function claimAndBatchInformation(
        IMaverickV2VotingEscrow ve,
        address account,
        uint256 startIndex,
        uint256 endIndex
    )
        external
        view
        returns (
            IMaverickV2VotingEscrow.ClaimInformation[] memory claimInformation,
            IMaverickV2VotingEscrow.BatchInformation[] memory batchInformation
        );

    /**
     * @notice This function retrieves paginated incentive batch information
     * for a provided Maverick V2 Voting Escrow (veToken) contract.
     * @param ve The address of the IMaverickV2VotingEscrow contract for which to retrieve batch information.
     * @param startIndex The starting index for the desired range of claims.
     * @param endIndex The ending index for the desired range of claims.
     */
    function incentiveBatchInformation(
        IMaverickV2VotingEscrow ve,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2VotingEscrow.BatchInformation[] memory batchInformation);

    /**
     * @notice This function retrieves paginated information on the lockup
     * synchronization status for legacy ve mav.
     * @param ve The address of the ve contract for which to retrieve sync information.
     * @param staker The address of the user for whom to retrieve sync information.
     * @param startIndex The starting index for the desired range of legacy lockups.
     * @param endIndex The ending index for the desired range of legacy lockups.
     * @return legacyLockups An array of `IMaverickV2VotingEscrow.Lockup`
     * structs containing details about the user's legacy lockups within the
     * index range.
     * @return syncedBalances An array of uint256 values representing the
     * synced balances corresponding to the legacy lockups.
     */
    function syncInformation(
        IMaverickV2VotingEscrowWSync ve,
        address staker,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2VotingEscrow.Lockup[] memory legacyLockups, uint256[] memory syncedBalances);

    /**
     * @notice This function retrieves paginated lockup information for a specific
     * account and lockup index range within a provided Maverick V2 Voting
     * Escrow (veToken) contract.
     * @param ve The address of the IMaverickV2VotingEscrow contract for which to retrieve lockup information.
     * @param staker The address of the account for which to retrieve lockup information.
     * @param startIndex The starting index for the desired range of lockups.
     * @param endIndex The ending index for the desired range of lockups.
     * @return returnElements An array of `IMaverickV2VotingEscrow.Lockup`
     * structs containing details about the lockups within the specified index
     * range for the account.
     */
    function getLockups(
        IMaverickV2VotingEscrow ve,
        address staker,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2VotingEscrow.Lockup[] memory returnElements);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMaverickV2VotingEscrowWSync {
    error VotingEscrowLockupEndTooShortToSync(uint256 legacyLockupEnd, uint256 minimumLockupEnd);

    event Sync(address staker, uint256 legacyLockupIndex, uint256 newBalance);

    /**
     * @notice This function retrieves the minimum lockup duration required for
     * a legacy lockup to be eligible for synchronization.
     * @return minSyncDuration The minimum allowed lockup end time.
     */
    // solhint-disable-next-line func-name-mixedcase
    function MIN_SYNC_DURATION() external pure returns (uint256 minSyncDuration);

    /**
     * @notice This function retrieves the address of the legacy Maverick V1
     * Voting Escrow (veMav) token.
     * @return legacyVeMav The address of the IERC20 legacy veMav token.
     */
    function legacyVeMav() external view returns (IERC20);

    /**
     * @notice This function retrieves the synced balance for a specific legacy lockup index of a user.
     * @param staker The address of the user for whom to retrieve the synced balance.
     * @param legacyLockupIndex The index of the legacy lockup for which to
     * retrieve the synced balance.
     * @return balance The synced balance associated with the legacy lockup.
     */
    function syncBalances(address staker, uint256 legacyLockupIndex) external view returns (uint256 balance);

    /**
     * @notice This function synchronizes a specific legacy lockup index for a
     * user within the contract.  If the legacy lockup.end is not at least
     * `block.timestamp + MIN_SYNC_DURATION()`, this function will revert.
     * @param staker The address of the user for whom to perform synchronization.
     * @param legacyLockupIndex The index of the legacy lockup to be
     * synchronized.
     * @return newBalance The new balance resulting from the synchronization
     * process.
     */
    function sync(address staker, uint256 legacyLockupIndex) external returns (uint256 newBalance);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {Math} from "@maverick/v2-common/contracts/libraries/Math.sol";

import {ILegacyVeMav} from "./votingescrowbase/ILegacyVeMav.sol";
import {IMaverickV2VotingEscrow} from "./interfaces/IMaverickV2VotingEscrow.sol";
import {IMaverickV2VotingEscrowLens} from "./interfaces/IMaverickV2VotingEscrowLens.sol";
import {IMaverickV2VotingEscrowWSync} from "./interfaces/IMaverickV2VotingEscrowWSync.sol";

/**
 * @notice Provides view functions for voting escrow information.
 */
contract MaverickV2VotingEscrowLens is IMaverickV2VotingEscrowLens {
    /// @inheritdoc IMaverickV2VotingEscrowLens
    function claimAndBatchInformation(
        IMaverickV2VotingEscrow ve,
        address account,
        uint256 startIndex,
        uint256 endIndex
    )
        public
        view
        returns (
            IMaverickV2VotingEscrow.ClaimInformation[] memory claimInformation,
            IMaverickV2VotingEscrow.BatchInformation[] memory batchInformation
        )
    {
        endIndex = Math.min(ve.incentiveBatchCount(), endIndex);
        claimInformation = new IMaverickV2VotingEscrow.ClaimInformation[](endIndex - startIndex);
        batchInformation = new IMaverickV2VotingEscrow.BatchInformation[](endIndex - startIndex);
        unchecked {
            for (uint256 i = startIndex; i < endIndex; i++) {
                (claimInformation[i - startIndex], batchInformation[i - startIndex]) = ve.claimAndBatchInformation(
                    account,
                    i
                );
            }
        }
    }

    function incentiveBatchInformation(
        IMaverickV2VotingEscrow ve,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2VotingEscrow.BatchInformation[] memory batchInformation) {
        endIndex = Math.min(ve.incentiveBatchCount(), endIndex);
        batchInformation = new IMaverickV2VotingEscrow.BatchInformation[](endIndex - startIndex);
        unchecked {
            for (uint256 i = startIndex; i < endIndex; i++) {
                batchInformation[i - startIndex] = ve.incentiveBatchInformation(i);
            }
        }
    }

    /// @inheritdoc IMaverickV2VotingEscrowLens
    function syncInformation(
        IMaverickV2VotingEscrowWSync ve,
        address staker,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (IMaverickV2VotingEscrow.Lockup[] memory legacyLockups, uint256[] memory syncedBalances) {
        ILegacyVeMav legacyVeMav = ILegacyVeMav(address(ve.legacyVeMav()));
        uint256 legacyLength = legacyVeMav.lockupCount(staker);
        endIndex = Math.min(legacyLength, endIndex);
        legacyLockups = new IMaverickV2VotingEscrow.Lockup[](endIndex - startIndex);
        syncedBalances = new uint256[](endIndex - startIndex);
        unchecked {
            for (uint256 i = startIndex; i < endIndex; i++) {
                legacyLockups[i - startIndex] = legacyVeMav.lockups(staker, i);
                syncedBalances[i - startIndex] = ve.syncBalances(staker, i);
            }
        }
    }

    /// @inheritdoc IMaverickV2VotingEscrowLens
    function getLockups(
        IMaverickV2VotingEscrow ve,
        address staker,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (IMaverickV2VotingEscrow.Lockup[] memory returnElements) {
        endIndex = Math.min(ve.lockupCount(staker), endIndex);
        returnElements = new IMaverickV2VotingEscrow.Lockup[](endIndex - startIndex);
        unchecked {
            for (uint256 i = startIndex; i < endIndex; i++) {
                returnElements[i - startIndex] = ve.getLockup(staker, i);
            }
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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMaverickV2VotingEscrow} from "../interfaces/IMaverickV2VotingEscrow.sol";

interface ILegacyVeMav {
    function epoch() external view returns (uint256);
    function lockups(
        address staker,
        uint256 legacyLockupIndex
    ) external view returns (IMaverickV2VotingEscrow.Lockup memory);
    function lockupCount(address staker) external view returns (uint256 count);
    function mav() external view returns (IERC20);
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