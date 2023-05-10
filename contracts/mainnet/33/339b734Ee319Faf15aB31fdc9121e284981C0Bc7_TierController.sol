// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import 'oasis-swap/contracts/oasis/interfaces/IRebateEstimator.sol';
import 'oasis-swap/contracts/oasis/interfaces/IERC20.sol';
import { IStaking, UserStake } from './IStaking.sol';
import { ITimeWeightedAveragePricer } from './ITimeWeightedAveragePricer.sol';
import { ISnapshottable } from '../interfaces/ISnapshottable.sol';


struct RebateTier {
    uint256 value;
    uint64 rebate;
    uint24 dexShareFactor;
}


contract TierController is Ownable, IRebateEstimator, ISnapshottable {
    using SafeMath for uint256;

    uint24 public constant FACTOR_DIVISOR = 100000;

    IStaking public staking;
    ITimeWeightedAveragePricer public pricer;
    RebateTier[] public rebateTiers;
    address public token;
    IRebateEstimator internal rebateAlternatives;

    mapping (address => bool) public isSnapshotter;


    constructor(
        address _token,
        address _staking,
        address _pricer,
        RebateTier[] memory _rebateTiers
    ) {
        token = _token;
        setPricer(ITimeWeightedAveragePricer(_pricer));
        setStaking(IStaking(_staking));
        setTiers(_rebateTiers);
    }


    ///////////////////////////////////////
    // View functions
    ///////////////////////////////////////

    function tierToHumanReadable(RebateTier memory tier) public view returns (uint256[] memory output) {
        output = new uint256[](3);
        output[0] = uint256(tier.value).div(10**IERC20Uniswap(address(pricer.token1())).decimals());
        output[1] = tier.rebate;
        output[2] = uint256(tier.dexShareFactor).div(10);
    }
    function getHumanReadableTiers() public view returns (uint256[][] memory output) {
        output = new uint256[][](uint256(rebateTiers.length));
        uint256 invI = 0;
        for (int256 i = int256(rebateTiers.length) - 1;  i >= 0;  --i) {
            output[invI] = tierToHumanReadable(rebateTiers[uint256(i)]);
            invI = invI.add(1);
        }
    }
    function getAllTiers() public view returns (RebateTier[] memory) {
        return rebateTiers;
    }
    function getTierCount() public view returns (uint8) {
        return uint8(rebateTiers.length);
    }
    function getUserTokenValue(address account) public view returns (uint256) {
        uint256 vestedTokens = staking.getVestedTokens(account);
        uint256 value = pricer.getToken0Value(vestedTokens);
        return value;
    }
    function getUserTokenValue(uint256 _blockNumber, address _account) public view returns (uint256) {
        uint256 _vestedTokens = staking.getVestedTokensAtSnapshot(_account, _blockNumber);
        uint256 _value = pricer.getToken0ValueAtSnapshot(_blockNumber, _vestedTokens);
        return _value;
    }
    function getHumanReadableTier(address account) public view returns (uint256, uint[] memory) {
        (uint256 i, RebateTier memory tier) = getTier(account);
        return (i, tierToHumanReadable(tier));
    }
    function getTier(address account) public view returns (uint8, RebateTier memory) {
        uint8 idx = getTierIdx(account);
        return (idx, rebateTiers[idx]);
    }
    function getTierIdx(address account) public view returns (uint8) {
        uint256 value = getUserTokenValue(account);
        uint8 len = uint8(rebateTiers.length);
        for (uint8 i = 0; i < len; i++) {
            if (value >= rebateTiers[i].value) {
                return i;
            }
        }

        // this should be logically impossible
        require(false, "TierController: no rebate tier applicable");
        return 0; // to make compiler happy
    }
    function getTierIdx(uint256 _blockNumber, address _account) public view returns (uint8) {
        uint256 value = getUserTokenValue(_blockNumber, _account);
        uint8 len = uint8(rebateTiers.length);
        for (uint8 i = 0; i < len; i++) {
            if (value >= rebateTiers[i].value) {
                return i;
            }
        }

        // this should be logically impossible
        require(false, "TierController: no rebate tier applicable");
        return 0; // to make compiler happy
    }
    function getDexShareFactor(address account) public view returns (uint24) {
        uint256 i;
        RebateTier memory tier;
        (i, tier) = getTier(account);
        return tier.dexShareFactor;
    }
    function getRebate(address account) external override view returns (uint64) {
        uint64 rebateAlternative = 0;
        if (address(rebateAlternatives) != address(0)) {
            rebateAlternative = rebateAlternatives.getRebate(account);
        }

        uint256 i;
        RebateTier memory tier;
        (i, tier) = getTier(account);

        return uint64(Math.max(tier.rebate, rebateAlternative));
    }


    ///////////////////////////////////////
    // Housekeeping
    ///////////////////////////////////////

    function snapshot() external onlySnapshotter override {
        pricer.snapshot();
        staking.snapshot();
    }
    function setSnapshotter(address _snapshotter, bool _state) external onlyOwner {
        isSnapshotter[_snapshotter] = _state;
    }
    modifier onlySnapshotter() {
        require(isSnapshotter[msg.sender], "Only snapshotter can call this function");
        _;
    }

    function setPricer(ITimeWeightedAveragePricer _pricer) public onlyOwner {
        require(address(_pricer) != address(0), "TierController: pricer contract cannot be 0x0");
        require(token == address(_pricer.token0()), "TierController: staking token mismatch 1");
        pricer = _pricer;
    }
    function setStaking(IStaking _staking) public onlyOwner {
        require(address(_staking) != address(0), "TierController: staking contract cannot be 0x0");
        require(token == address(_staking.token()), "TierController: staking token mismatch 2");
        staking = _staking;
    }
    function setOwner(address _newOwner) external onlyOwner {
        transferOwnership(_newOwner);
    }
    function setRebateAlternatives(IRebateEstimator _rebateAlternatives) external onlyOwner {
        rebateAlternatives = _rebateAlternatives;
    }
    function setTiers(RebateTier[] memory _rebateTiers) public onlyOwner {
        require(_rebateTiers.length > 0, "TierController: rebate tiers list cannot be empty");
        require(_rebateTiers[_rebateTiers.length - 1].value == 0, "TierController: last rebate tier value must be 0");
        require(_rebateTiers.length < type(uint8).max, "TierController: rebate tiers list too long");
        require(_rebateTiers.length == rebateTiers.length || rebateTiers.length == 0, "TierController: can't change number of tiers");

        delete rebateTiers;
        for (uint256 i = 0; i < _rebateTiers.length; i++) {
            require(_rebateTiers[i].rebate <= 10000, "TierController: rebate must be 10000 or less");

            if (i > 0) {
                require(_rebateTiers[i].value < _rebateTiers[i.sub(1)].value, "TierController: rebate tiers list is not sorted in descending order");
            }
            require(_rebateTiers[i].dexShareFactor <= FACTOR_DIVISOR, "TierController: dex share factors must not exceed FACTOR_DIVISOR");

            // set inside loop because not supported by compiler to copy whole array in one
            rebateTiers.push(_rebateTiers[i]);
        }
        require(rebateTiers[0].dexShareFactor == FACTOR_DIVISOR, "TierController: dex share factors must max out at FACTOR_DIVISOR");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISnapshottable } from '../interfaces/ISnapshottable.sol';

interface ITimeWeightedAveragePricer is ISnapshottable {
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);

    /**
     * @dev Calculates the current price based on the stored samples.
     * @return The current price as a uint256.
     */
    function calculateToken0Price() external view returns (uint256);

    /**
     * @dev Returns the current price of token0, denominated in token1.
     * @return The current price as a uint256.
     */
    function getToken0Price() external view returns (uint256);

    /**
     * @dev Returns the current price of token1, denominated in token0.
     * @return The current price as a uint256.
     */
    function getToken1Price() external view returns (uint256);

    function getToken0Value(uint256 amount) external view returns (uint256);
    function getToken0ValueAtSnapshot(uint256 _blockNumber, uint256 amount) external view returns (uint256);

    function getToken1Value(uint256 amount) external view returns (uint256);

    /**
     * @dev Returns the block number of the oldest sample.
     * @return The block number of the oldest sample as a uint256.
     */
    function getOldestSampleBlock() external view returns (uint256);

    /**
     * @dev Returns the current price if the oldest sample is still considered fresh.
     * @return The current price as a uint256.
     */
    function getToken0FreshPrice() external view returns (uint256);

    /**
     * @dev Returns the current price if the oldest sample is still considered fresh.
     * @return The current price as a uint256.
     */
    function getToken1FreshPrice() external view returns (uint256);

    /**
     * @dev Returns the next sample index given the current index and sample count.
     * @param i The current sample index.
     * @param max The maximum number of samples.
     * @return The next sample index as a uint64.
     */
    function calculateNext(uint64 i, uint64 max) external pure returns (uint64);

    /**
     * @dev Returns the previous sample index given the current index and sample count.
     * @param i The current sample index.
     * @param max The maximum number of samples.
     * @return The previous sample index as a uint64.
     */
    function calculatePrev(uint64 i, uint64 max) external pure returns (uint64);

    /**
     * @dev Samples the current spot price of the token pair from all pools.
     * @return A boolean indicating whether the price was sampled or not.
     */
    function samplePrice() external returns (bool);

    /**
     * @dev Samples the current spot price of the token pair from all pools, throwing if the previous sample was too recent.
     */
    function enforcedSamplePrice() external;

    /**
     * @dev Calculates the spot price of the token pair from all pools.
     * @return The spot price as a uint256.
     */
    function calculateToken0SpotPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISnapshottable } from '../interfaces/ISnapshottable.sol';

pragma solidity ^0.8.0;


struct UserStake {
    uint256 amount;
    uint256 depositBlock;
    uint256 withdrawBlock;
    uint256 emergencyWithdrawalBlock;

    uint256 lastSnapshotBlockNumber;
}


interface IStaking is ISnapshottable {
    function getStake(address) external view returns (UserStake memory);
    function isPenaltyCollector(address) external view returns (bool);
    function token() external view returns (IERC20);
    function penalty() external view returns (uint256);

    function stake(uint256 amount) external;
    function stakeFor(address account, uint256 amount) external;
    function withdraw(uint256 amount) external;
    function emergencyWithdraw(uint256 amount) external;
    function changeOwner(address newOwner) external;
    function sendPenalty(address to) external returns (uint256);
    function setPenaltyCollector(address collector, bool status) external;
    function getVestedTokens(address user) external view returns (uint256);
    function getVestedTokensAtSnapshot(address user, uint256 blockNumber) external view returns (uint256);
    function getWithdrawable(address user) external view returns (uint256);
    function getEmergencyWithdrawPenalty(address user) external view returns (uint256);
    function getVestedTokensPercentage(address user) external view returns (uint256);
    function getWithdrawablePercentage(address user) external view returns (uint256);
    function getEmergencyWithdrawPenaltyPercentage(address user) external view returns (uint256);
    function getEmergencyWithdrawPenaltyAmountReturned(address user, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISnapshottable {
    function snapshot() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IRebateEstimator {
    function getRebate(address account) external view returns (uint64);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}