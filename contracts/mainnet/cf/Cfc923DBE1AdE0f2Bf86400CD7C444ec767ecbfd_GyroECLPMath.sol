// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_INVESTMENT_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../openzeppelin/IERC20.sol";

import "./BalancerErrors.sol";

library InputHelpers {
    function ensureInputLengthMatch(uint256 a, uint256 b) internal pure {
        _require(a == b, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureInputLengthMatch(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure {
        _require(a == b && b == c, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureArrayIsSorted(IERC20[] memory array) internal pure {
        address[] memory addressArray;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(address[] memory array) internal pure {
        if (array.length < 2) {
            return;
        }

        address previous = array[0];
        for (uint256 i = 1; i < array.length; ++i) {
            address current = array[i];
            _require(previous < current, Errors.UNSORTED_ARRAY);
            previous = current;
        }
    }
}

// SPDX-License-Identifier: MIT
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        _require(x < 2**255, Errors.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = _ln_36(x_int256);

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = _ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

        // Finally, we compute exp(y * ln(x)) to arrive at x^y
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
            Errors.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

        // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
        // upscaling.

        int256 logBase;
        if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
            logBase = _ln_36(base);
        } else {
            logBase = _ln(base) * ONE_18;
        }

        int256 logArg;
        if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
            logArg = _ln_36(arg);
        } else {
            logArg = _ln(arg) * ONE_18;
        }

        // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
        return (logArg * ONE_18) / logBase;
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        // The real natural logarithm is not defined for negative numbers or zero.
        _require(a > 0, Errors.OUT_OF_BOUNDS);
        if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
            return _ln_36(a) / ONE_18;
        } else {
            return _ln(a);
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-_ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        x *= ONE_18;

        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        return seriesSum * 2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library
 */
library Math {
    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _require(a == 0 || c / a == b, Errors.MUL_OVERFLOW);
        return c;
    }

    function div(
        uint256 a,
        uint256 b,
        bool roundUp
    ) internal pure returns (uint256) {
        return roundUp ? divUp(a, b) : divDown(a, b);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        } else {
            return 1 + (a - 1) / b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "../../libraries/GyroFixedPoint.sol";
import "../../libraries/GyroErrors.sol";
import "../../libraries/SignedFixedPoint.sol";
import "../../libraries/GyroPoolMath.sol";
import "./GyroECLPPoolErrors.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/InputHelpers.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

// solhint-disable private-vars-leading-underscore

/** @dev ECLP math library. Pretty much a direct translation of the python version (see `tests/`).
 * We use *signed* values here because some of the intermediate results can be negative (e.g. coordinates of points in
 * the untransformed circle, "prices" in the untransformed circle).
 */
library GyroECLPMath {
    uint256 internal constant ONEHALF = 0.5e18;
    int256 internal constant ONE = 1e18; // 18 decimal places
    int256 internal constant ONE_XP = 1e38; // 38 decimal places

    using SignedFixedPoint for int256;
    using GyroFixedPoint for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;

    // Anti-overflow limits: Params and DerivedParams (static, only needs to be checked on pool creation)
    int256 internal constant _ROTATION_VECTOR_NORM_ACCURACY = 1e3; // 1e-15 in normal precision
    int256 internal constant _MAX_STRETCH_FACTOR = 1e26; // 1e8   in normal precision
    int256 internal constant _DERIVED_TAU_NORM_ACCURACY_XP = 1e23; // 1e-15 in extra precision
    int256 internal constant _MAX_INV_INVARIANT_DENOMINATOR_XP = 1e43; // 1e5   in extra precision
    int256 internal constant _DERIVED_DSQ_NORM_ACCURACY_XP = 1e23; // 1e-15 in extra precision

    // Anti-overflow limits: Dynamic values (checked before operations that use them)
    int256 internal constant _MAX_BALANCES = 1e34; // 1e16 in normal precision
    int256 internal constant _MAX_INVARIANT = 3e37; // 3e19 in normal precision

    // Note that all t values (not tp or tpp) could consist of uint's, as could all Params. But it's complicated to
    // convert all the time, so we make them all signed. We also store all intermediate values signed. An exception are
    // the functions that are used by the contract b/c there the values are stored unsigned.
    struct Params {
        // Price bounds (lower and upper). 0 < alpha < beta
        int256 alpha;
        int256 beta;
        // Rotation vector:
        // phi in (-90 degrees, 0] is the implicit rotation vector. It's stored as a point:
        int256 c; // c = cos(-phi) >= 0. rounded to 18 decimals
        int256 s; //  s = sin(-phi) >= 0. rounded to 18 decimals
        // Invariant: c^2 + s^2 == 1, i.e., the point (c, s) is normalized.
        // due to rounding, this may not = 1. The term dSq in DerivedParams corrects for this in extra precision

        // Stretching factor:
        int256 lambda; // lambda >= 1 where lambda == 1 is the circle.
    }

    // terms in this struct are stored in extra precision (38 decimals) with final decimal rounded down
    struct DerivedParams {
        Vector2 tauAlpha;
        Vector2 tauBeta;
        int256 u; // from (A chi)_y = lambda * u + v
        int256 v; // from (A chi)_y = lambda * u + v
        int256 w; // from (A chi)_x = w / lambda + z
        int256 z; // from (A chi)_x = w / lambda + z
        int256 dSq; // error in c^2 + s^2 = dSq, used to correct errors in c, s, tau, u,v,w,z calculations
        //int256 dAlpha; // normalization constant for tau(alpha)
        //int256 dBeta; // normalization constant for tau(beta)
    }

    struct Vector2 {
        int256 x;
        int256 y;
    }

    struct QParams {
        int256 a;
        int256 b;
        int256 c;
    }

    /** @dev Enforces limits and approximate normalization of the rotation vector. */
    function validateParams(Params memory params) internal pure {
        _grequire(0 <= params.s && params.s <= ONE, GyroECLPPoolErrors.ROTATION_VECTOR_WRONG);
        _grequire(0 <= params.c && params.c <= ONE, GyroECLPPoolErrors.ROTATION_VECTOR_WRONG);

        Vector2 memory sc = Vector2(params.s, params.c);
        int256 scnorm2 = scalarProd(sc, sc); // squared norm
        _grequire(
            ONE - _ROTATION_VECTOR_NORM_ACCURACY <= scnorm2 && scnorm2 <= ONE + _ROTATION_VECTOR_NORM_ACCURACY,
            GyroECLPPoolErrors.ROTATION_VECTOR_NOT_NORMALIZED
        );

        _grequire(0 <= params.lambda && params.lambda <= _MAX_STRETCH_FACTOR, GyroECLPPoolErrors.STRETCHING_FACTOR_WRONG);
    }

    /** @dev Enforces limits and approximate normalization of the derived values.
    Does NOT check for internal consistency of 'derived' with 'params'. */
    function validateDerivedParamsLimits(Params memory params, DerivedParams memory derived) external pure {
        int256 norm2;
        norm2 = scalarProdXp(derived.tauAlpha, derived.tauAlpha);
        _grequire(
            ONE_XP - _DERIVED_TAU_NORM_ACCURACY_XP <= norm2 && norm2 <= ONE_XP + _DERIVED_TAU_NORM_ACCURACY_XP,
            GyroECLPPoolErrors.DERIVED_TAU_NOT_NORMALIZED
        );
        norm2 = scalarProdXp(derived.tauBeta, derived.tauBeta);
        _grequire(
            ONE_XP - _DERIVED_TAU_NORM_ACCURACY_XP <= norm2 && norm2 <= ONE_XP + _DERIVED_TAU_NORM_ACCURACY_XP,
            GyroECLPPoolErrors.DERIVED_TAU_NOT_NORMALIZED
        );

        _grequire(derived.u <= ONE_XP, GyroECLPPoolErrors.DERIVED_UVWZ_WRONG);
        _grequire(derived.v <= ONE_XP, GyroECLPPoolErrors.DERIVED_UVWZ_WRONG);
        _grequire(derived.w <= ONE_XP, GyroECLPPoolErrors.DERIVED_UVWZ_WRONG);
        _grequire(derived.z <= ONE_XP, GyroECLPPoolErrors.DERIVED_UVWZ_WRONG);

        _grequire(
            ONE_XP - _DERIVED_DSQ_NORM_ACCURACY_XP <= derived.dSq && derived.dSq <= ONE_XP + _DERIVED_DSQ_NORM_ACCURACY_XP,
            GyroECLPPoolErrors.DERIVED_DSQ_WRONG
        );

        // NB No anti-overflow checks are required given the checks done above and in validateParams().
        int256 mulDenominator = ONE_XP.divXpU(calcAChiAChiInXp(params, derived) - ONE_XP);
        _grequire(mulDenominator <= _MAX_INV_INVARIANT_DENOMINATOR_XP, GyroECLPPoolErrors.INVARIANT_DENOMINATOR_WRONG);
    }

    function scalarProd(Vector2 memory t1, Vector2 memory t2) internal pure returns (int256 ret) {
        ret = t1.x.mulDownMag(t2.x).add(t1.y.mulDownMag(t2.y));
    }

    /// @dev scalar product for extra-precision values
    function scalarProdXp(Vector2 memory t1, Vector2 memory t2) internal pure returns (int256 ret) {
        ret = t1.x.mulXp(t2.x).add(t1.y.mulXp(t2.y));
    }

    // "Methods" for Params. We could put these into a separate library and import them via 'using' to get method call
    // syntax.

    /** @dev Calculate A t where A is given in Section 2.2
     *  This is reversing rotation and scaling of the ellipse (mapping back to circle) */
    function mulA(Params memory params, Vector2 memory tp) internal pure returns (Vector2 memory t) {
        // NB: This function is only used inside calculatePrice(). This is why we can make two simplifications:
        // 1. We don't correct for precision of s, c using d.dSq because that level of precision is not important in this context.
        // 2. We don't need to check for over/underflow b/c these are impossible in that context and given the (checked) assumptions on the various values.
        t.x = params.c.mulDownMagU(tp.x).divDownMagU(params.lambda) - params.s.mulDownMagU(tp.y).divDownMagU(params.lambda);
        t.y = params.s.mulDownMagU(tp.x) + params.c.mulDownMagU(tp.y);
    }

    /** @dev Calculate virtual offset a given invariant r.
     *  See calculation in Section 2.1.2 Computing reserve offsets
     *  Note that, in contrast to virtual reserve offsets in CPMM, these are *subtracted* from the real
     *  reserves, moving the curve to the upper-right. They can be positive or negative, but not both can be negative.
     *  Calculates a = r*(A^{-1}tau(beta))_x rounding up in signed direction
     *  Notice that error in r is scaled by lambda, and so rounding direction is important */
    function virtualOffset0(
        Params memory p,
        DerivedParams memory d,
        Vector2 memory r // overestimate in x component, underestimate in y
    ) internal pure returns (int256 a) {
        // a = r lambda c tau(beta)_x + rs tau(beta)_y
        //       account for 1 factors of dSq (2 s,c factors)
        int256 termXp = d.tauBeta.x.divXpU(d.dSq);
        a = d.tauBeta.x > 0
            ? r.x.mulUpMagU(p.lambda).mulUpMagU(p.c).mulUpXpToNpU(termXp)
            : r.y.mulDownMagU(p.lambda).mulDownMagU(p.c).mulUpXpToNpU(termXp);

        // use fact that tau(beta)_y > 0, so the required rounding direction is clear.
        a = a + r.x.mulUpMagU(p.s).mulUpXpToNpU(d.tauBeta.y.divXpU(d.dSq));
    }

    /** @dev calculate virtual offset b given invariant r.
     *  Calculates b = r*(A^{-1}tau(alpha))_y rounding up in signed direction */
    function virtualOffset1(
        Params memory p,
        DerivedParams memory d,
        Vector2 memory r // overestimate in x component, underestimate in y
    ) internal pure returns (int256 b) {
        // b = -r \lambda s tau(alpha)_x + rc tau(alpha)_y
        //       account for 1 factors of dSq (2 s,c factors)
        int256 termXp = d.tauAlpha.x.divXpU(d.dSq);
        b = (d.tauAlpha.x < 0)
            ? r.x.mulUpMagU(p.lambda).mulUpMagU(p.s).mulUpXpToNpU(-termXp)
            : (-r.y).mulDownMagU(p.lambda).mulDownMagU(p.s).mulUpXpToNpU(termXp);

        // use fact that tau(alpha)_y > 0, so the required rounding direction is clear.
        b = b + r.x.mulUpMagU(p.c).mulUpXpToNpU(d.tauAlpha.y.divXpU(d.dSq));
    }

    /** Maximal value for the real reserves x when the respective other balance is 0 for given invariant
     *  See calculation in Section 2.1.2. Calculation is ordered here for precision, but error in r is magnified by lambda
     *  Rounds down in signed direction */
    function maxBalances0(
        Params memory p,
        DerivedParams memory d,
        Vector2 memory r // overestimate in x-component, underestimate in y-component
    ) internal pure returns (int256 xp) {
        // x^+ = r lambda c (tau(beta)_x - tau(alpha)_x) + rs (tau(beta)_y - tau(alpha)_y)
        //      account for 1 factors of dSq (2 s,c factors)
        int256 termXp1 = (d.tauBeta.x - d.tauAlpha.x).divXpU(d.dSq); // note tauBeta.x > tauAlpha.x, so this is > 0 and rounding direction is clear
        int256 termXp2 = (d.tauBeta.y - d.tauAlpha.y).divXpU(d.dSq); // note this may be negative, but since tauBeta.y, tauAlpha.y >= 0, it is always in [-1, 1].
        xp = r.y.mulDownMagU(p.lambda).mulDownMagU(p.c).mulDownXpToNpU(termXp1);
        xp = xp + (termXp2 > 0 ? r.y.mulDownMagU(p.s) : r.x.mulUpMagU(p.s)).mulDownXpToNpU(termXp2);
    }

    /** Maximal value for the real reserves y when the respective other balance is 0 for given invariant
     *  See calculation in Section 2.1.2. Calculation is ordered here for precision, but erorr in r is magnified by lambda
     *  Rounds down in signed direction */
    function maxBalances1(
        Params memory p,
        DerivedParams memory d,
        Vector2 memory r // overestimate in x-component, underestimate in y-component
    ) internal pure returns (int256 yp) {
        // y^+ = r lambda s (tau(beta)_x - tau(alpha)_x) + rc (tau(alpha)_y - tau(beta)_y)
        //      account for 1 factors of dSq (2 s,c factors)
        int256 termXp1 = (d.tauBeta.x - d.tauAlpha.x).divXpU(d.dSq); // note tauBeta.x > tauAlpha.x
        int256 termXp2 = (d.tauAlpha.y - d.tauBeta.y).divXpU(d.dSq);
        yp = r.y.mulDownMagU(p.lambda).mulDownMagU(p.s).mulDownXpToNpU(termXp1);
        yp = yp + (termXp2 > 0 ? r.y.mulDownMagU(p.c) : r.x.mulUpMagU(p.c)).mulDownXpToNpU(termXp2);
    }

    /** @dev Compute the invariant 'r' corresponding to the given values. The invariant can't be negative, but
     *  we use a signed value to store it because all the other calculations are happening with signed ints, too.
     *  Computes r according to Prop 13 in 2.2.1 Initialization from Real Reserves
     *  orders operations to achieve best precision
     *  Returns an underestimate and a bound on error size.
     *  Enforces anti-overflow limits on balances and the computed invariant in the process. */
    function calculateInvariantWithError(
        uint256[] memory balances,
        Params memory params,
        DerivedParams memory derived
    ) public pure returns (int256, int256) {
        (int256 x, int256 y) = (balances[0].toInt256(), balances[1].toInt256());
        _grequire(x.add(y) <= _MAX_BALANCES, GyroECLPPoolErrors.MAX_ASSETS_EXCEEDED);

        int256 AtAChi = calcAtAChi(x, y, params, derived);
        (int256 sqrt, int256 err) = calcInvariantSqrt(x, y, params, derived);
        // calculate the error in the square root term, separates cases based on sqrt >= 1/2
        // somedayTODO: can this be improved for cases of large balances (when xp error magnifies to np)
        // Note: the minimum non-zero value of sqrt is 1e-9 since the minimum argument is 1e-18
        if (sqrt > 0) {
            // err + 1 to account for O(eps_np) term ignored before
            err = (err + 1).divUpMagU(2 * sqrt);
        } else {
            // in the false case here, the extra precision error does not magnify, and so the error inside the sqrt is O(1e-18)
            // somedayTODO: The true case will almost surely never happen (can it be removed)
            err = err > 0 ? GyroPoolMath._sqrt(err.toUint256(), 5).toInt256() : 1e9;
        }
        // calculate the error in the numerator, scale the error by 20 to be sure all possible terms accounted for
        err = ((params.lambda.mulUpMagU(x + y) / ONE_XP) + err + 1) * 20;

        // A chi \cdot A chi > 1, so round it up to round denominator up
        // denominator uses extra precision, so we do * 1/denominator so we are sure the calculation doesn't overflow
        int256 mulDenominator = ONE_XP.divXpU(calcAChiAChiInXp(params, derived) - ONE_XP);
        // NOTE: Anti-overflow limits on mulDenominator are checked on contract creation.

        // as alternative, could do, but could overflow: invariant = (AtAChi.add(sqrt) - err).divXp(denominator);
        int256 invariant = (AtAChi + sqrt - err).mulDownXpToNpU(mulDenominator);
        // error scales if denominator is small
        // NB: This error calculation computes the error in the expression "numerator / denominator", but in this code
        // we actually use the formula "numerator * (1 / denominator)" to compute the invariant. This affects this line
        // and the one below.
        err = err.mulUpXpToNpU(mulDenominator);
        // account for relative error due to error in the denominator
        // error in denominator is O(epsilon) if lambda<1e11, scale up by 10 to be sure we catch it, and add O(eps)
        // error in denominator is lambda^2 * 2e-37 and scales relative to the result / denominator
        // Scale by a constant to account for errors in the scaling factor itself and limited compounding.
        // calculating lambda^2 w/o decimals so that the calculation will never overflow, the lost precision isn't important
        err = err + ((invariant.mulUpXpToNpU(mulDenominator) * ((params.lambda * params.lambda) / 1e36)) * 40) / ONE_XP + 1;

        _grequire(invariant.add(err) <= _MAX_INVARIANT, GyroECLPPoolErrors.MAX_INVARIANT_EXCEEDED);

        return (invariant, err);
    }

    function calculateInvariant(
        uint256[] memory balances,
        Params memory params,
        DerivedParams memory derived
    ) external pure returns (uint256 uinvariant) {
        (int256 invariant, ) = calculateInvariantWithError(balances, params, derived);
        uinvariant = invariant.toUint256();
    }

    /// @dev calculate At \cdot A chi, ignores rounding direction. We will later compensate for the rounding error.
    function calcAtAChi(
        int256 x,
        int256 y,
        Params memory p,
        DerivedParams memory d
    ) internal pure returns (int256 val) {
        // to save gas, pre-compute dSq^2 as it will be used 3 times
        int256 dSq2 = d.dSq.mulXpU(d.dSq);

        // (cx - sy) * (w/lambda + z) / lambda
        //      account for 2 factors of dSq (4 s,c factors)
        int256 termXp = (d.w.divDownMagU(p.lambda) + d.z).divDownMagU(p.lambda).divXpU(dSq2);
        val = (x.mulDownMagU(p.c) - y.mulDownMagU(p.s)).mulDownXpToNpU(termXp);

        // (x lambda s + y lambda c) * u, note u > 0
        int256 termNp = x.mulDownMagU(p.lambda).mulDownMagU(p.s) + y.mulDownMagU(p.lambda).mulDownMagU(p.c);
        val = val + termNp.mulDownXpToNpU(d.u.divXpU(dSq2));

        // (sx+cy) * v, note v > 0
        termNp = x.mulDownMagU(p.s) + y.mulDownMagU(p.c);
        val = val + termNp.mulDownXpToNpU(d.v.divXpU(dSq2));
    }

    /// @dev calculates A chi \cdot A chi in extra precision
    /// Note: this can be >1 (and involves factor of lambda^2). We can compute it in extra precision w/o overflowing b/c it will be
    /// at most 38 + 16 digits (38 from decimals, 2*8 from lambda^2 if lambda=1e8)
    /// Since we will only divide by this later, we will not need to worry about overflow in that operation if done in the right way
    /// TODO: is rounding direction ok?
    function calcAChiAChiInXp(Params memory p, DerivedParams memory d) internal pure returns (int256 val) {
        // to save gas, pre-compute dSq^3 as it will be used 4 times
        int256 dSq3 = d.dSq.mulXpU(d.dSq).mulXpU(d.dSq);

        // (A chi)_y^2 = lambda^2 u^2 + lambda 2 u v + v^2
        //      account for 3 factors of dSq (6 s,c factors)
        // SOMEDAY: In these calcs, a calculated value is multiplied by lambda and lambda^2, resp, which implies some
        // error amplification. It's fine b/c we're doing it in extra precision here, but would still be nice if it
        // could be avoided, perhaps by splitting up the numbers into a high and low part.
        val = p.lambda.mulUpMagU((2 * d.u).mulXpU(d.v).divXpU(dSq3));
        // for lambda^2 u^2 factor in rounding error in u since lambda could be big
        // Note: lambda^2 is multiplied at the end to be sure the calculation doesn't overflow, but this can lose some precision
        val = val + ((d.u + 1).mulXpU(d.u + 1).divXpU(dSq3)).mulUpMagU(p.lambda).mulUpMagU(p.lambda);
        // the next line converts from extre precision to normal precision post-computation while rounding up
        val = val + (d.v).mulXpU(d.v).divXpU(dSq3);

        // (A chi)_x^2 = (w/lambda + z)^2
        //      account for 3 factors of dSq (6 s,c factors)
        int256 termXp = d.w.divUpMagU(p.lambda) + d.z;
        val = val + termXp.mulXpU(termXp).divXpU(dSq3);
    }

    /// @dev calculate -(At)_x ^2 (A chi)_y ^2 + (At)_x ^2, rounding down in signed direction
    function calcMinAtxAChiySqPlusAtxSq(
        int256 x,
        int256 y,
        Params memory p,
        DerivedParams memory d
    ) internal pure returns (int256 val) {
        ////////////////////////////////////////////////////////////////////////////////////
        // (At)_x^2 (A chi)_y^2 = (x^2 c^2 - xy2sc + y^2 s^2) (u^2 + 2uv/lambda + v^2/lambda^2)
        //      account for 4 factors of dSq (8 s,c factors)
        //
        // (At)_x^2 = (x^2 c^2 - xy2sc + y^2 s^2)/lambda^2
        //      account for 1 factor of dSq (2 s,c factors)
        ////////////////////////////////////////////////////////////////////////////////////
        int256 termNp = x.mulUpMagU(x).mulUpMagU(p.c).mulUpMagU(p.c) + y.mulUpMagU(y).mulUpMagU(p.s).mulUpMagU(p.s);
        termNp = termNp - x.mulDownMagU(y).mulDownMagU(p.c * 2).mulDownMagU(p.s);

        int256 termXp = d.u.mulXpU(d.u) + (2 * d.u).mulXpU(d.v).divDownMagU(p.lambda) + d.v.mulXpU(d.v).divDownMagU(p.lambda).divDownMagU(p.lambda);
        termXp = termXp.divXpU(d.dSq.mulXpU(d.dSq).mulXpU(d.dSq).mulXpU(d.dSq));
        val = (-termNp).mulDownXpToNpU(termXp);

        // now calculate (At)_x^2 accounting for possible rounding error to round down
        // need to do 1/dSq in a way so that there is no overflow for large balances
        val = val + (termNp - 9).divDownMagU(p.lambda).divDownMagU(p.lambda).mulDownXpToNpU(SignedFixedPoint.ONE_XP.divXpU(d.dSq));
    }

    /// @dev calculate 2(At)_x * (At)_y * (A chi)_x * (A chi)_y, ignores rounding direction
    //  Note: this ignores rounding direction and is corrected for later
    function calc2AtxAtyAChixAChiy(
        int256 x,
        int256 y,
        Params memory p,
        DerivedParams memory d
    ) internal pure returns (int256 val) {
        ////////////////////////////////////////////////////////////////////////////////////
        // = ((x^2 - y^2)sc + yx(c^2-s^2)) * 2 * (zu + (wu + zv)/lambda + wv/lambda^2)
        //      account for 4 factors of dSq (8 s,c factors)
        ////////////////////////////////////////////////////////////////////////////////////
        int256 termNp = (x.mulDownMagU(x) - y.mulUpMagU(y)).mulDownMagU(2 * p.c).mulDownMagU(p.s);
        int256 xy = y.mulDownMagU(2 * x);
        termNp = termNp + xy.mulDownMagU(p.c).mulDownMagU(p.c) - xy.mulDownMagU(p.s).mulDownMagU(p.s);

        int256 termXp = d.z.mulXpU(d.u) + d.w.mulXpU(d.v).divDownMagU(p.lambda).divDownMagU(p.lambda);
        termXp = termXp + (d.w.mulXpU(d.u) + d.z.mulXpU(d.v)).divDownMagU(p.lambda);
        termXp = termXp.divXpU(d.dSq.mulXpU(d.dSq).mulXpU(d.dSq).mulXpU(d.dSq));

        val = termNp.mulDownXpToNpU(termXp);
    }

    /// @dev calculate -(At)_y ^2 (A chi)_x ^2 + (At)_y ^2, rounding down in signed direction
    function calcMinAtyAChixSqPlusAtySq(
        int256 x,
        int256 y,
        Params memory p,
        DerivedParams memory d
    ) internal pure returns (int256 val) {
        ////////////////////////////////////////////////////////////////////////////////////
        // (At)_y^2 (A chi)_x^2 = (x^2 s^2 + xy2sc + y^2 c^2) * (z^2 + 2zw/lambda + w^2/lambda^2)
        //      account for 4 factors of dSq (8 s,c factors)
        // (At)_y^2 = (x^2 s^2 + xy2sc + y^2 c^2)
        //      account for 1 factor of dSq (2 s,c factors)
        ////////////////////////////////////////////////////////////////////////////////////
        int256 termNp = x.mulUpMagU(x).mulUpMagU(p.s).mulUpMagU(p.s) + y.mulUpMagU(y).mulUpMagU(p.c).mulUpMagU(p.c);
        termNp = termNp + x.mulUpMagU(y).mulUpMagU(p.s * 2).mulUpMagU(p.c);

        int256 termXp = d.z.mulXpU(d.z) + d.w.mulXpU(d.w).divDownMagU(p.lambda).divDownMagU(p.lambda);
        termXp = termXp + (2 * d.z).mulXpU(d.w).divDownMagU(p.lambda);
        termXp = termXp.divXpU(d.dSq.mulXpU(d.dSq).mulXpU(d.dSq).mulXpU(d.dSq));
        val = (-termNp).mulDownXpToNpU(termXp);

        // now calculate (At)_y^2 accounting for possible rounding error to round down
        // need to do 1/dSq in a way so that there is no overflow for large balances
        val = val + (termNp - 9).mulDownXpToNpU(SignedFixedPoint.ONE_XP.divXpU(d.dSq));
    }

    /// @dev Rounds down. Also returns an estimate for the error of the term under the sqrt (!) and without the regular
    /// normal-precision error of O(1e-18).
    function calcInvariantSqrt(
        int256 x,
        int256 y,
        Params memory p,
        DerivedParams memory d
    ) internal pure returns (int256 val, int256 err) {
        val = calcMinAtxAChiySqPlusAtxSq(x, y, p, d) + calc2AtxAtyAChixAChiy(x, y, p, d);
        val = val + calcMinAtyAChixSqPlusAtySq(x, y, p, d);
        // error inside the square root is O((x^2 + y^2) * eps_xp) + O(eps_np), where eps_xp=1e-38, eps_np=1e-18
        // note that in terms of rounding down, error corrects for calc2AtxAtyAChixAChiy()
        // however, we also use this error to correct the invariant for an overestimate in swaps, it is all the same order though
        // Note the O(eps_np) term will be dealt with later, so not included yet
        // Note that the extra precision term doesn't propagate unless balances are > 100b
        err = (x.mulUpMagU(x) + y.mulUpMagU(y)) / 1e38;
        // we will account for the error later after the square root
        // mathematically, terms in square root > 0, so treat as 0 if it is < 0 b/c of rounding error
        val = val > 0 ? GyroPoolMath._sqrt(val.toUint256(), 5).toInt256() : 0;
    }

    /** @dev Spot price of token 0 in units of token 1.
     *  See Prop. 12 in 2.1.6 Computing Prices */
    function calcSpotPrice0in1(
        uint256[] memory balances,
        Params memory params,
        DerivedParams memory derived,
        int256 invariant
    ) external pure returns (uint256 px) {
        // shift by virtual offsets to get v(t)
        Vector2 memory r = Vector2(invariant, invariant); // ignore r rounding for spot price, precision will be lost in TWAP anyway
        Vector2 memory ab = Vector2(virtualOffset0(params, derived, r), virtualOffset1(params, derived, r));
        Vector2 memory vec = Vector2(balances[0].toInt256() - ab.x, balances[1].toInt256() - ab.y);

        // transform to circle to get Av(t)
        vec = mulA(params, vec);
        // compute prices on circle
        Vector2 memory pc = Vector2(vec.x.divDownMagU(vec.y), ONE);

        // Convert prices back to ellipse
        // NB: These operations check for overflow because the price pc[0] might be large when vex.y is small.
        // SOMEDAY I think this probably can't actually happen due to our bounds on the different values. In this case we could do this unchecked as well.
        int256 pgx = scalarProd(pc, mulA(params, Vector2(ONE, 0)));
        px = pgx.divDownMag(scalarProd(pc, mulA(params, Vector2(0, ONE)))).toUint256();
    }

    /** @dev Check that post-swap balances obey maximal asset bounds
     *  newBalance = post-swap balance of one asset
     *  assetIndex gives the index of the provided asset (0 = X, 1 = Y) */
    function checkAssetBounds(
        Params memory params,
        DerivedParams memory derived,
        Vector2 memory invariant,
        int256 newBal,
        uint8 assetIndex
    ) internal pure {
        if (assetIndex == 0) {
            int256 xPlus = maxBalances0(params, derived, invariant);
            if (!(newBal <= _MAX_BALANCES && newBal <= xPlus)) _grequire(false, GyroECLPPoolErrors.ASSET_BOUNDS_EXCEEDED);
            return;
        }
        {
            int256 yPlus = maxBalances1(params, derived, invariant);
            if (!(newBal <= _MAX_BALANCES && newBal <= yPlus)) _grequire(false, GyroECLPPoolErrors.ASSET_BOUNDS_EXCEEDED);
        }
    }

    function calcOutGivenIn(
        uint256[] memory balances,
        uint256 amountIn,
        bool tokenInIsToken0,
        Params memory params,
        DerivedParams memory derived,
        Vector2 memory invariant
    ) external pure returns (uint256 amountOut) {
        function(int256, Params memory, DerivedParams memory, Vector2 memory) pure returns (int256) calcGiven;
        uint8 ixIn;
        uint8 ixOut;
        if (tokenInIsToken0) {
            ixIn = 0;
            ixOut = 1;
            calcGiven = calcYGivenX;
        } else {
            ixIn = 1;
            ixOut = 0;
            calcGiven = calcXGivenY;
        }

        int256 balInNew = balances[ixIn].add(amountIn).toInt256(); // checked because amountIn is given by the user.
        checkAssetBounds(params, derived, invariant, balInNew, ixIn);
        int256 balOutNew = calcGiven(balInNew, params, derived, invariant);
        // Make sub checked as an extra check against numerical error; but this really should never happen
        amountOut = balances[ixOut].sub(balOutNew.toUint256());
        // The above line guarantees that amountOut <= balances[ixOut].
    }

    function calcInGivenOut(
        uint256[] memory balances,
        uint256 amountOut,
        bool tokenInIsToken0,
        Params memory params,
        DerivedParams memory derived,
        Vector2 memory invariant
    ) external pure returns (uint256 amountIn) {
        function(int256, Params memory, DerivedParams memory, Vector2 memory) pure returns (int256) calcGiven;
        uint8 ixIn;
        uint8 ixOut;
        if (tokenInIsToken0) {
            ixIn = 0;
            ixOut = 1;
            calcGiven = calcXGivenY; // this reverses compared to calcOutGivenIn
        } else {
            ixIn = 1;
            ixOut = 0;
            calcGiven = calcYGivenX; // this reverses compared to calcOutGivenIn
        }

        if (!(amountOut <= balances[ixOut])) _grequire(false, GyroECLPPoolErrors.ASSET_BOUNDS_EXCEEDED);
        int256 balOutNew = (balances[ixOut] - amountOut).toInt256();
        int256 balInNew = calcGiven(balOutNew, params, derived, invariant);
        // The checks in the following two lines should really always succeed; we keep them as extra safety against numerical error.
        checkAssetBounds(params, derived, invariant, balInNew, ixIn);
        amountIn = balInNew.toUint256().sub(balances[ixIn]);
    }

    /** @dev Variables are named for calculating y given x
     *  to calculate x given y, change x->y, s->c, c->s, a_>b, b->a, tauBeta.x -> -tauAlpha.x, tauBeta.y -> tauAlpha.y
     *  calculates an overestimate of calculated reserve post-swap */
    function solveQuadraticSwap(
        int256 lambda,
        int256 x,
        int256 s,
        int256 c,
        Vector2 memory r, // overestimate in x component, underestimate in y
        Vector2 memory ab,
        Vector2 memory tauBeta,
        int256 dSq
    ) internal pure returns (int256) {
        // x component will round up, y will round down, use extra precision
        Vector2 memory lamBar;
        lamBar.x = SignedFixedPoint.ONE_XP - SignedFixedPoint.ONE_XP.divDownMagU(lambda).divDownMagU(lambda);
        // Note: The following cannot become negative even with errors because we require lambda >= 1 and
        // divUpMag returns the exact result if the quotient is representable in 18 decimals.
        lamBar.y = SignedFixedPoint.ONE_XP - SignedFixedPoint.ONE_XP.divUpMagU(lambda).divUpMagU(lambda);
        // using qparams struct to avoid "stack too deep"
        QParams memory q;
        // shift by the virtual offsets
        // note that we want an overestimate of offset here so that -x'*lambar*s*c is overestimated in signed direction
        // account for 1 factor of dSq (2 s,c factors)
        int256 xp = x - ab.x;
        if (xp > 0) {
            q.b = (-xp).mulDownMagU(s).mulDownMagU(c).mulUpXpToNpU(lamBar.y.divXpU(dSq));
        } else {
            q.b = (-xp).mulUpMagU(s).mulUpMagU(c).mulUpXpToNpU(lamBar.x.divXpU(dSq) + 1);
        }

        // x component will round up, y will round down, use extra precision
        // account for 1 factor of dSq (2 s,c factors)
        Vector2 memory sTerm;
        // we wil take sTerm = 1 - sTerm below, using multiple lines to avoid "stack too deep"
        sTerm.x = lamBar.y.mulDownMagU(s).mulDownMagU(s).divXpU(dSq);
        sTerm.y = lamBar.x.mulUpMagU(s);
        sTerm.y = sTerm.y.mulUpMagU(s).divXpU(dSq + 1) + 1; // account for rounding error in dSq, divXp
        sTerm = Vector2(SignedFixedPoint.ONE_XP - sTerm.x, SignedFixedPoint.ONE_XP - sTerm.y);
        // ^^ NB: The components of sTerm are non-negative: We only need to worry about sTerm.y. This is non-negative b/c, because of bounds on lambda lamBar <= 1 - 1e-16, and division by dSq ensures we have enough precision so that rounding errors are never magnitude 1e-16.

        // now compute the argument of the square root
        q.c = -calcXpXpDivLambdaLambda(x, r, lambda, s, c, tauBeta, dSq);
        q.c = q.c + r.y.mulDownMagU(r.y).mulDownXpToNpU(sTerm.y);
        // the square root is always being subtracted, so round it down to overestimate the end balance
        // mathematically, terms in square root > 0, so treat as 0 if it is < 0 b/c of rounding error
        q.c = q.c > 0 ? GyroPoolMath._sqrt(q.c.toUint256(), 5).toInt256() : 0;

        // calculate the result in q.a
        if (q.b - q.c > 0) {
            q.a = (q.b - q.c).mulUpXpToNpU(SignedFixedPoint.ONE_XP.divXpU(sTerm.y) + 1);
        } else {
            q.a = (q.b - q.c).mulUpXpToNpU(SignedFixedPoint.ONE_XP.divXpU(sTerm.x));
        }

        // lastly, add the offset, note that we want an overestimate of offset here
        return q.a + ab.y;
    }

    /** @dev Calculates x'x'/λ^2 where x' = x - b = x - r (A^{-1}tau(beta))_x
     *  calculates an overestimate
     *  to calculate y'y', change x->y, s->c, c->s, tauBeta.x -> -tauAlpha.x, tauBeta.y -> tauAlpha.y  */
    function calcXpXpDivLambdaLambda(
        int256 x,
        Vector2 memory r, // overestimate in x component, underestimate in y
        int256 lambda,
        int256 s,
        int256 c,
        Vector2 memory tauBeta,
        int256 dSq
    ) internal pure returns (int256) {
        //////////////////////////////////////////////////////////////////////////////////
        // x'x'/lambda^2 = r^2 c^2 tau(beta)_x^2
        //      + ( r^2 2s c tau(beta)_x tau(beta)_y - rx 2c tau(beta)_x ) / lambda
        //      + ( r^2 s^2 tau(beta)_y^2 - rx 2s tau(beta)_y + x^2 ) / lambda^2
        //////////////////////////////////////////////////////////////////////////////////
        // to save gas, pre-compute dSq^2 as it will be used 3 times, and r.x^2 as it will be used 2-3 times
        // sqVars = (dSq^2, r.x^2)
        Vector2 memory sqVars = Vector2(dSq.mulXpU(dSq), r.x.mulUpMagU(r.x));

        QParams memory q; // for working terms
        // q.a = r^2 s 2c tau(beta)_x tau(beta)_y
        //      account for 2 factors of dSq (4 s,c factors)
        int256 termXp = tauBeta.x.mulXpU(tauBeta.y).divXpU(sqVars.x);
        if (termXp > 0) {
            q.a = sqVars.y.mulUpMagU(2 * s);
            q.a = q.a.mulUpMagU(c).mulUpXpToNpU(termXp + 7); // +7 account for rounding in termXp
        } else {
            q.a = r.y.mulDownMagU(r.y).mulDownMagU(2 * s);
            q.a = q.a.mulDownMagU(c).mulUpXpToNpU(termXp);
        }

        // -rx 2c tau(beta)_x
        //      account for 1 factor of dSq (2 s,c factors)
        if (tauBeta.x < 0) {
            // +3 account for rounding in extra precision terms
            q.b = r.x.mulUpMagU(x).mulUpMagU(2 * c).mulUpXpToNpU(-tauBeta.x.divXpU(dSq) + 3);
        } else {
            q.b = (-r.y).mulDownMagU(x).mulDownMagU(2 * c).mulUpXpToNpU(tauBeta.x.divXpU(dSq));
        }
        // q.a later needs to be divided by lambda
        q.a = q.a + q.b;

        // q.b = r^2 s^2 tau(beta)_y^2
        //      account for 2 factors of dSq (4 s,c factors)
        termXp = tauBeta.y.mulXpU(tauBeta.y).divXpU(sqVars.x) + 7; // +7 account for rounding in termXp
        q.b = sqVars.y.mulUpMagU(s);
        q.b = q.b.mulUpMagU(s).mulUpXpToNpU(termXp);

        // q.c = -rx 2s tau(beta)_y, recall that tauBeta.y > 0 so round lower in magnitude
        //      account for 1 factor of dSq (2 s,c factors)
        q.c = (-r.y).mulDownMagU(x).mulDownMagU(2 * s).mulUpXpToNpU(tauBeta.y.divXpU(dSq));

        // (q.b + q.c + x^2) / lambda
        q.b = q.b + q.c + x.mulUpMagU(x);
        q.b = q.b > 0 ? q.b.divUpMagU(lambda) : q.b.divDownMagU(lambda);

        // remaining calculation is (q.a + q.b) / lambda
        q.a = q.a + q.b;
        q.a = q.a > 0 ? q.a.divUpMagU(lambda) : q.a.divDownMagU(lambda);

        // + r^2 c^2 tau(beta)_x^2
        //      account for 2 factors of dSq (4 s,c factors)
        termXp = tauBeta.x.mulXpU(tauBeta.x).divXpU(sqVars.x) + 7; // +7 account for rounding in termXp
        int256 val = sqVars.y.mulUpMagU(c).mulUpMagU(c);
        return (val.mulUpXpToNpU(termXp)) + q.a;
    }

    /** @dev compute y such that (x, y) satisfy the invariant at the given parameters.
     *  Note that we calculate an overestimate of y
     *   See Prop 14 in section 2.2.2 Trade Execution */
    function calcYGivenX(
        int256 x,
        Params memory params,
        DerivedParams memory d,
        Vector2 memory r // overestimate in x component, underestimate in y
    ) internal pure returns (int256 y) {
        // want to overestimate the virtual offsets except in a particular setting that will be corrected for later
        // note that the error correction in the invariant should more than make up for uncaught rounding directions (in 38 decimals) in virtual offsets
        Vector2 memory ab = Vector2(virtualOffset0(params, d, r), virtualOffset1(params, d, r));
        y = solveQuadraticSwap(params.lambda, x, params.s, params.c, r, ab, d.tauBeta, d.dSq);
    }

    function calcXGivenY(
        int256 y,
        Params memory params,
        DerivedParams memory d,
        Vector2 memory r // overestimate in x component, underestimate in y
    ) internal pure returns (int256 x) {
        // want to overestimate the virtual offsets except in a particular setting that will be corrected for later
        // note that the error correction in the invariant should more than make up for uncaught rounding directions (in 38 decimals) in virtual offsets
        Vector2 memory ba = Vector2(virtualOffset1(params, d, r), virtualOffset0(params, d, r));
        // change x->y, s->c, c->s, b->a, a->b, tauBeta.x -> -tauAlpha.x, tauBeta.y -> tauAlpha.y vs calcYGivenX
        x = solveQuadraticSwap(params.lambda, y, params.c, params.s, r, ba, Vector2(-d.tauAlpha.x, d.tauAlpha.y), d.dSq);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity 0.7.6;

// solhint-disable

library GyroECLPPoolErrors {
    // Input
    uint256 internal constant ADDRESS_IS_ZERO_ADDRESS = 120;
    uint256 internal constant TOKEN_IN_IS_NOT_TOKEN_0 = 121;

    // Math
    uint256 internal constant PRICE_BOUNDS_WRONG = 354;
    uint256 internal constant ROTATION_VECTOR_WRONG = 355;
    uint256 internal constant ROTATION_VECTOR_NOT_NORMALIZED = 356;
    uint256 internal constant ASSET_BOUNDS_EXCEEDED = 357;
    uint256 internal constant DERIVED_TAU_NOT_NORMALIZED = 358;
    uint256 internal constant DERIVED_ZETA_WRONG = 359;
    uint256 internal constant STRETCHING_FACTOR_WRONG = 360;
    uint256 internal constant DERIVED_UVWZ_WRONG = 361;
    uint256 internal constant INVARIANT_DENOMINATOR_WRONG = 362;
    uint256 internal constant MAX_ASSETS_EXCEEDED = 363;
    uint256 internal constant MAX_INVARIANT_EXCEEDED = 363;
    uint256 internal constant DERIVED_DSQ_WRONG = 364;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity ^0.7.0;

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _grequire(bool condition, uint256 errorCode) pure {
    if (!condition) _grevert(errorCode);
}

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _grequire(
    bool condition,
    uint256 errorCode,
    bytes3 prefix
) pure {
    if (!condition) _grevert(errorCode, prefix);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _grevert(uint256 errorCode) pure {
    _grevert(errorCode, 0x475952); // This is the raw byte representation of "GYR"
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _grevert(uint256 errorCode, bytes3 prefix) pure {
    uint256 prefixUint = uint256(uint24(prefix));
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string.
        // We first append the '#' character (0x23) to the prefix. In the case of 'BAL', it results in 0x42414c23 ('BAL#')
        // Then, we shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).
        let formattedPrefix := shl(24, add(0x23, shl(8, prefixUint)))

        let revertReason := shl(200, add(formattedPrefix, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library GyroErrors {
    uint256 internal constant ZERO_ADDRESS = 105;
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-solidity-utils/contracts/math/LogExpMath.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

/* solhint-disable private-vars-leading-underscore */

// Gyroscope: Copied from Balancer's FixedPoint library. We added a few additional functions and made _require()s more
// gas-efficient.
// We renamed this to `GyroFixedPoint` to avoid name clashes with functions used in other Balancer libraries we use.

library GyroFixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant MIDDECIMAL = 1e9; // splits the fixed point decimals into two equal parts.

    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        uint256 c = a + b;
        if (!(c >= a)) {
            _require(false, Errors.ADD_OVERFLOW);
        }
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        if (!(b <= a)) {
            _require(false, Errors.SUB_OVERFLOW);
        }
        uint256 c = a - b;
        return c;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        if (!(a == 0 || product / a == b)) {
            _require(false, Errors.MUL_OVERFLOW);
        }

        return product / ONE;
    }

    /// @dev "U" denotes version of the math function that does not check for overflows in order to save gas
    function mulDownU(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        if (!(a == 0 || product / a == b)) {
            _require(false, Errors.MUL_OVERFLOW);
        }

        if (product == 0) {
            return 0;
        }

        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, which we already tested for.

        return ((product - 1) / ONE) + 1;
    }

    function mulUpU(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        if (product == 0) {
            return 0;
        }
        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, which we already tested for.

        return ((product - 1) / ONE) + 1;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            _require(false, Errors.ZERO_DIVISION);
        }

        if (a == 0) {
            return 0;
        }

        uint256 aInflated = a * ONE;
        if (!(aInflated / a == ONE)) {
            _require(false, Errors.DIV_INTERNAL); // mul overflow
        }

        return aInflated / b;
    }

    function divDownU(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            _require(false, Errors.ZERO_DIVISION);
        }

        return (a * ONE) / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            _require(false, Errors.ZERO_DIVISION);
        }

        if (a == 0) {
            return 0;
        }

        uint256 aInflated = a * ONE;
        if (!(aInflated / a == ONE)) {
            _require(aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow
        }

        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, which we already tested for.

        return ((aInflated - 1) / b) + 1;
    }

    function divUpU(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            _require(false, Errors.ZERO_DIVISION);
        }

        if (a == 0) {
            return 0;
        }
        return ((a * ONE - 1) / b) + 1;
    }

    /**
     * @dev Like mulDown(), but it also works in some situations where mulDown(a, b) would overflow because a * b is too
     * large. We achieve this by splitting up `a` into its integer and its fractional part. `a` should be the bigger of
     * the two numbers to achieve the best overflow guarantees.
     * This won't overflow if both of
     *   - a * b ≤ 1.15e95 (raw values, i.e., a * b ≤ 1.15e59 with respect to the fixed-point values that they describe)
     *   - b ≤ 1.15e59 (raw values, i.e., a ≤ 1.15e41 with respect to the values that a describes)
     * hold. That's better than mulDown(), where we would need a * b ≤ 1.15e77 approximately.
     */
    function mulDownLargeSmall(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(Math.mul(a / ONE, b), mulDown(a % ONE, b));
    }

    function mulDownLargeSmallU(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / ONE) * b + mulDownU(a % ONE, b);
    }

    /**
     * @dev Like divDown(), but it also works when `a` would overflow in `divDown`. This is safe if both of
     * - a ≤ 1.15e68 (raw, i.e., a ≤ 1.15e50 with respect to the value that is represented)
     * - b ≥ 1e9 (raw, i.e., b ≥ 1e-9 with respect to the value represented)
     * hold. For `divDown` it's 1.15e59 and 1.15e41, respectively.
     * Introduces some rounding error that is relevant iff b is small.
     */
    function divDownLarge(uint256 a, uint256 b) internal pure returns (uint256) {
        return divDownLarge(a, b, MIDDECIMAL, MIDDECIMAL);
    }

    function divDownLargeU(uint256 a, uint256 b) internal pure returns (uint256) {
        return divDownLargeU(a, b, MIDDECIMAL, MIDDECIMAL);
    }

    /**
     * @dev Like divDown(), but it also works when `a` would overflow in `divDown`. d and e must be chosen such that
     * d * e = 1e18 (raw numbers, or d * e = 1e-18 with respect to the numbers they represent in fixed point). Note that
     * this requires d, e ≤ 1e18 (raw, or d, e ≤ 1 with respect to the numbers represented).
     * This operation is safe if both of
     * - a * d ≤ 1.15e77 (raw, i.e., a * d ≤ 1.15e41 with respect to the value that is represented)
     * - b ≥ e (with respect to raw or represented numbers)
     * hold.
     * Introduces some rounding error that is relevant iff b is small and is proportional to e.
     */
    function divDownLarge(
        uint256 a,
        uint256 b,
        uint256 d,
        uint256 e
    ) internal pure returns (uint256) {
        return Math.divDown(Math.mul(a, d), Math.divUp(b, e));
    }

    /// @dev e is assumed to be non-zero, and so division by zero is not checked for it
    function divDownLargeU(
        uint256 a,
        uint256 b,
        uint256 d,
        uint256 e
    ) internal pure returns (uint256) {
        // (a * d) / (b / e)

        if (b == 0) {
            // In this case only, the denominator of the outer division is zero, and we revert
            _require(false, Errors.ZERO_DIVISION);
        }

        uint256 denom = 1 + (b - 1) / e;

        return (a * d) / denom;
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

        if (raw < maxError) {
            return 0;
        }
        return sub(raw, maxError);
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 raw = LogExpMath.pow(x, y);
        uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

        return add(raw, maxError);
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity 0.7.6;

// import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "./GyroFixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/InputHelpers.sol";

library GyroPoolMath {
    using GyroFixedPoint for uint256;

    uint256 private constant SQRT_1E_NEG_1 = 316227766016837933;
    uint256 private constant SQRT_1E_NEG_3 = 31622776601683793;
    uint256 private constant SQRT_1E_NEG_5 = 3162277660168379;
    uint256 private constant SQRT_1E_NEG_7 = 316227766016837;
    uint256 private constant SQRT_1E_NEG_9 = 31622776601683;
    uint256 private constant SQRT_1E_NEG_11 = 3162277660168;
    uint256 private constant SQRT_1E_NEG_13 = 316227766016;
    uint256 private constant SQRT_1E_NEG_15 = 31622776601;
    uint256 private constant SQRT_1E_NEG_17 = 3162277660;

    // Note: this function is identical to that in WeightedMath.sol audited by Balancer
    function _calcAllTokensInGivenExactBptOut(
        uint256[] memory balances,
        uint256 bptOut,
        uint256 totalBPT
    ) internal pure returns (uint256[] memory amountsIn) {
        /************************************************************************************
        // tokensInForExactBptOut                                                          //
        //                              /   bptOut   \                                     //
        // amountsIn[i] = balances[i] * | ------------ |                                   //
        //                              \  totalBPT  /                                     //
        ************************************************************************************/
        // We adjust the order of operations to minimize error amplification, assuming that
        // balances[i], totalBPT > 1 (which is usually the case).
        // Tokens in, so we round up overall.

        amountsIn = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            amountsIn[i] = balances[i].mulUp(bptOut).divUp(totalBPT);
        }

        return amountsIn;
    }

    // Note: this function is identical to that in WeightedMath.sol audited by Balancer
    function _calcTokensOutGivenExactBptIn(
        uint256[] memory balances,
        uint256 bptIn,
        uint256 totalBPT
    ) internal pure returns (uint256[] memory amountsOut) {
        /**********************************************************************************************
        // exactBPTInForTokensOut                                                                    //
        // (per token)                                                                               //
        //                                /        bptIn         \                                   //
        // amountsOut[i] = balances[i] * | ---------------------  |                                  //
        //                                \       totalBPT       /                                   //
        **********************************************************************************************/
        // We adjust the order of operations to minimize error amplification, assuming that
        // balances[i], totalBPT > 1 (which is usually the case).
        // Since we're computing an amount out, we round down overall. This means rounding down on both the
        // multiplication and division.

        amountsOut = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; i++) {
            amountsOut[i] = balances[i].mulDown(bptIn).divDown(totalBPT);
        }

        return amountsOut;
    }

    /** @dev Calculates protocol fees due to Gyro and Balancer
     *   Note: we do this differently than normal Balancer pools by paying fees in BPT tokens
     *   b/c this is much more gas efficient than doing many transfers of underlying assets
     *   This function gets protocol fee parameters from GyroConfig
     */
    function _calcProtocolFees(
        uint256 previousInvariant,
        uint256 currentInvariant,
        uint256 currentBptSupply,
        uint256 protocolSwapFeePerc,
        uint256 protocolFeeGyroPortion
    ) internal pure returns (uint256, uint256) {
        /*********************************************************************************
        /*  Protocol fee collection should decrease the invariant L by
        *        Delta L = protocolSwapFeePerc * (currentInvariant - previousInvariant)
        *   To take these fees in BPT LP shares, the protocol mints Delta S new LP shares where
        *        Delta S = S * Delta L / ( currentInvariant - Delta L )
        *   where S = current BPT supply
        *   The protocol then splits the fees (in BPT) considering protocolFeeGyroPortion
        *   See also the write-up, Proposition 7.
        *********************************************************************************/

        if (currentInvariant <= previousInvariant) {
            // This shouldn't happen outside of rounding errors, but have this safeguard nonetheless to prevent the Pool
            // from entering a locked state in which joins and exits revert while computing accumulated swap fees.
            // NB: This condition is also used by the pools to indicate that _lastInvariant is invalid and should be ignored.
            return (0, 0);
        }

        // Calculate due protocol fees in BPT terms
        // We round down to prevent issues in the Pool's accounting, even if it means paying slightly less in protocol
        // fees to the Vault.
        // For the numerator, we need to round down delta L. Also for the denominator b/c subtracted
        // Ordering multiplications for best fixed point precision considering that S and currentInvariant-previousInvariant could be large
        uint256 numerator = (currentBptSupply.mulDown(currentInvariant.sub(previousInvariant))).mulDown(protocolSwapFeePerc);
        uint256 diffInvariant = protocolSwapFeePerc.mulDown(currentInvariant.sub(previousInvariant));
        uint256 denominator = currentInvariant.sub(diffInvariant);
        uint256 deltaS = numerator.divDown(denominator);

        // Split fees between Gyro and Balancer
        uint256 gyroFees = protocolFeeGyroPortion.mulDown(deltaS);
        uint256 balancerFees = deltaS.sub(gyroFees);

        return (gyroFees, balancerFees);
    }

    /** @dev Implements square root algorithm using Newton's method and a first-guess optimisation **/
    function _sqrt(uint256 input, uint256 tolerance) internal pure returns (uint256) {
        if (input == 0) {
            return 0;
        }

        uint256 guess = _makeInitialGuess(input);

        // 7 iterations
        guess = (guess + ((input * GyroFixedPoint.ONE) / guess)) / 2;
        guess = (guess + ((input * GyroFixedPoint.ONE) / guess)) / 2;
        guess = (guess + ((input * GyroFixedPoint.ONE) / guess)) / 2;
        guess = (guess + ((input * GyroFixedPoint.ONE) / guess)) / 2;
        guess = (guess + ((input * GyroFixedPoint.ONE) / guess)) / 2;
        guess = (guess + ((input * GyroFixedPoint.ONE) / guess)) / 2;
        guess = (guess + ((input * GyroFixedPoint.ONE) / guess)) / 2;

        // Check in some epsilon range
        // Check square is more or less correct
        uint256 guessSquared = guess.mulDown(guess);
        require(guessSquared <= input.add(guess.mulUp(tolerance)) && guessSquared >= input.sub(guess.mulUp(tolerance)), "_sqrt FAILED");

        return guess;
    }

    // function _makeInitialGuess10(uint256 input) internal pure returns (uint256) {
    //     uint256 orderUpperBound = 72;
    //     uint256 orderLowerBound = 0;
    //     uint256 orderMiddle;

    //     orderMiddle = (orderUpperBound + orderLowerBound) / 2;

    //     while (orderUpperBound - orderLowerBound != 1) {
    //         if (10**orderMiddle > input) {
    //             orderUpperBound = orderMiddle;
    //         } else {
    //             orderLowerBound = orderMiddle;
    //         }
    //     }

    //     return 10**(orderUpperBound / 2);
    // }

    function _makeInitialGuess(uint256 input) internal pure returns (uint256) {
        if (input >= GyroFixedPoint.ONE) {
            return (1 << (_intLog2Halved(input / GyroFixedPoint.ONE))) * GyroFixedPoint.ONE;
        } else {
            if (input <= 10) {
                return SQRT_1E_NEG_17;
            }
            if (input <= 1e2) {
                return 1e10;
            }
            if (input <= 1e3) {
                return SQRT_1E_NEG_15;
            }
            if (input <= 1e4) {
                return 1e11;
            }
            if (input <= 1e5) {
                return SQRT_1E_NEG_13;
            }
            if (input <= 1e6) {
                return 1e12;
            }
            if (input <= 1e7) {
                return SQRT_1E_NEG_11;
            }
            if (input <= 1e8) {
                return 1e13;
            }
            if (input <= 1e9) {
                return SQRT_1E_NEG_9;
            }
            if (input <= 1e10) {
                return 1e14;
            }
            if (input <= 1e11) {
                return SQRT_1E_NEG_7;
            }
            if (input <= 1e12) {
                return 1e15;
            }
            if (input <= 1e13) {
                return SQRT_1E_NEG_5;
            }
            if (input <= 1e14) {
                return 1e16;
            }
            if (input <= 1e15) {
                return SQRT_1E_NEG_3;
            }
            if (input <= 1e16) {
                return 1e17;
            }
            if (input <= 1e17) {
                return SQRT_1E_NEG_1;
            }
            return input;
        }
    }

    function _intLog2Halved(uint256 x) public pure returns (uint256 n) {
        if (x >= 1 << 128) {
            x >>= 128;
            n += 64;
        }
        if (x >= 1 << 64) {
            x >>= 64;
            n += 32;
        }
        if (x >= 1 << 32) {
            x >>= 32;
            n += 16;
        }
        if (x >= 1 << 16) {
            x >>= 16;
            n += 8;
        }
        if (x >= 1 << 8) {
            x >>= 8;
            n += 4;
        }
        if (x >= 1 << 4) {
            x >>= 4;
            n += 2;
        }
        if (x >= 1 << 2) {
            x >>= 2;
            n += 1;
        }
    }

    /** @dev If liquidity update is proportional so that price stays the same ("balanced liquidity update"), then this
     *  returns the invariant after that change. This is more efficient than calling `calculateInvariant()` on the updated balances.
     *  `isIncreaseLiq` denotes the sign of the update. See the writeup, Corollary 3 in Section 3.1.3. */
    function liquidityInvariantUpdate(
        uint256 uinvariant,
        uint256 changeBptSupply,
        uint256 currentBptSupply,
        bool isIncreaseLiq
    ) internal pure returns (uint256 unewInvariant) {
        //  change in invariant
        if (isIncreaseLiq) {
            // round new invariant up so that protocol fees not triggered
            uint256 dL = uinvariant.mulUp(changeBptSupply).divUp(currentBptSupply);
            unewInvariant = uinvariant.add(dL);
        } else {
            // round new invariant up (and so round dL down) so that protocol fees not triggered
            uint256 dL = uinvariant.mulDown(changeBptSupply).divDown(currentBptSupply);
            unewInvariant = uinvariant.sub(dL);
        }
    }

    /** @dev If `deltaBalances` are such that, when changing `balances` by it, the price stays the same ("balanced
     * liquidity update"), then this returns the invariant after that change. This is more efficient than calling
     * `calculateInvariant()` on the updated balances. `isIncreaseLiq` denotes the sign of the update.
     * See the writeup, Corollary 3 in Section 3.1.3.
     *
     * DEPRECATED and will go out of use and be removed once pending changes to the ECLP are merged. Use the other liquidityInvariantUpdate() function instead!
     */
    function liquidityInvariantUpdate(
        uint256[] memory balances,
        uint256 uinvariant,
        uint256[] memory deltaBalances,
        bool isIncreaseLiq
    ) internal pure returns (uint256 unewInvariant) {
        uint256 largestBalanceIndex;
        uint256 largestBalance;
        for (uint256 i = 0; i < balances.length; i++) {
            if (balances[i] > largestBalance) {
                largestBalance = balances[i];
                largestBalanceIndex = i;
            }
        }

        uint256 deltaInvariant = uinvariant.mulDown(deltaBalances[largestBalanceIndex]).divDown(balances[largestBalanceIndex]);
        unewInvariant = isIncreaseLiq ? uinvariant.add(deltaInvariant) : uinvariant.sub(deltaInvariant);
    }
}

// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

pragma solidity 0.7.6;

// import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "./GyroFixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/BalancerErrors.sol";

/* solhint-disable private-vars-leading-underscore */

/// @dev Signed fixed point operations based on Balancer's FixedPoint library.
/// Note: The `{mul,div}{UpMag,DownMag}()` functions do *not* round up or down, respectively,
/// in a signed fashion (like ceil and floor operations), but *in absolute value* (or *magnitude*), i.e.,
/// towards 0. This is useful in some applications.
library SignedFixedPoint {
    int256 internal constant ONE = 1e18; // 18 decimal places
    // setting extra precision at 38 decimals, which is the most we can get w/o overflowing on normal multiplication
    // this allows 20 extra digits to absorb error when multiplying by large numbers
    int256 internal constant ONE_XP = 1e38; // 38 decimal places

    function add(int256 a, int256 b) internal pure returns (int256) {
        // Fixed Point addition is the same as regular checked addition

        int256 c = a + b;
        if (!(b >= 0 ? c >= a : c < a)) _require(false, Errors.ADD_OVERFLOW);
        return c;
    }

    function addMag(int256 a, int256 b) internal pure returns (int256 c) {
        // add b in the same signed direction as a, i.e. increase the magnitude of a by b
        c = a > 0 ? add(a, b) : sub(a, b);
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        // Fixed Point subtraction is the same as regular checked subtraction

        int256 c = a - b;
        if (!(b <= 0 ? c >= a : c < a)) _require(false, Errors.SUB_OVERFLOW);
        return c;
    }

    /// @dev This rounds towards 0, i.e., down *in absolute value*!
    function mulDownMag(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;
        if (!(a == 0 || product / a == b)) _require(false, Errors.MUL_OVERFLOW);

        return product / ONE;
    }

    /// @dev this implements mulDownMag w/o checking for over/under-flows, which saves significantly on gas if these aren't needed
    function mulDownMagU(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / ONE;
    }

    /// @dev This rounds away from 0, i.e., up *in absolute value*!
    function mulUpMag(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;
        if (!(a == 0 || product / a == b)) _require(false, Errors.MUL_OVERFLOW);

        // If product > 0, the result should be ceil(p/ONE) = floor((p-1)/ONE) + 1, where floor() is implicit. If
        // product < 0, the result should be floor(p/ONE) = ceil((p+1)/ONE) - 1, where ceil() is implicit.
        // Addition for signed numbers: Case selection so we round away from 0, not always up.
        if (product > 0) return ((product - 1) / ONE) + 1;
        else if (product < 0) return ((product + 1) / ONE) - 1;
        // product == 0
        return 0;
    }

    /// @dev this implements mulUpMag w/o checking for over/under-flows, which saves significantly on gas if these aren't needed
    function mulUpMagU(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;

        // If product > 0, the result should be ceil(p/ONE) = floor((p-1)/ONE) + 1, where floor() is implicit. If
        // product < 0, the result should be floor(p/ONE) = ceil((p+1)/ONE) - 1, where ceil() is implicit.
        // Addition for signed numbers: Case selection so we round away from 0, not always up.
        if (product > 0) return ((product - 1) / ONE) + 1;
        else if (product < 0) return ((product + 1) / ONE) - 1;
        // product == 0
        return 0;
    }

    /// @dev Rounds towards 0, i.e., down in absolute value.
    function divDownMag(int256 a, int256 b) internal pure returns (int256) {
        if (b == 0) _require(false, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        }

        int256 aInflated = a * ONE;
        if (aInflated / a != ONE) _require(false, Errors.DIV_INTERNAL);

        return aInflated / b;
    }

    /// @dev this implements divDownMag w/o checking for over/under-flows, which saves significantly on gas if these aren't needed
    function divDownMagU(int256 a, int256 b) internal pure returns (int256) {
        if (b == 0) _require(false, Errors.ZERO_DIVISION);
        return (a * ONE) / b;
    }

    /// @dev Rounds away from 0, i.e., up in absolute value.
    function divUpMag(int256 a, int256 b) internal pure returns (int256) {
        if (b == 0) _require(false, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        }

        if (b < 0) {
            // Required so the below is correct.
            b = -b;
            a = -a;
        }

        int256 aInflated = a * ONE;
        if (aInflated / a != ONE) _require(false, Errors.DIV_INTERNAL);

        if (aInflated > 0) return ((aInflated - 1) / b) + 1;
        return ((aInflated + 1) / b) - 1;
    }

    /// @dev this implements divUpMag w/o checking for over/under-flows, which saves significantly on gas if these aren't needed
    function divUpMagU(int256 a, int256 b) internal pure returns (int256) {
        if (b == 0) _require(false, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        }

        // SOMEDAY check if we can shave off some gas by logically refactoring this vs the below case distinction into one (on a * b or so).
        if (b < 0) {
            // Ensure b > 0 so the below is correct.
            b = -b;
            a = -a;
        }

        if (a > 0) return ((a * ONE - 1) / b) + 1;
        return ((a * ONE + 1) / b) - 1;
    }

    /// @dev multiplies two extra precision numbers (with 38 decimals)
    /// rounds down in magnitude but this shouldn't matter
    /// multiplication can overflow if a,b are > 2 in magnitude
    function mulXp(int256 a, int256 b) internal pure returns (int256) {
        int256 product = a * b;
        if (!(a == 0 || product / a == b)) _require(false, Errors.MUL_OVERFLOW);

        return product / ONE_XP;
    }

    /// @dev multiplies two extra precision numbers (with 38 decimals)
    /// rounds down in magnitude but this shouldn't matter
    /// multiplication can overflow if a,b are > 2 in magnitude
    /// this implements mulXp w/o checking for over/under-flows, which saves significantly on gas if these aren't needed
    function mulXpU(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / ONE_XP;
    }

    /// @dev divides two extra precision numbers (with 38 decimals)
    /// rounds down in magnitude but this shouldn't matter
    /// can overflow if a > 2 or b << 1 in magnitude
    function divXp(int256 a, int256 b) internal pure returns (int256) {
        if (b == 0) _require(false, Errors.ZERO_DIVISION);

        if (a == 0) {
            return 0;
        }

        int256 aInflated = a * ONE_XP;
        if (aInflated / a != ONE_XP) _require(false, Errors.DIV_INTERNAL);

        return aInflated / b;
    }

    /// @dev divides two extra precision numbers (with 38 decimals)
    /// rounds down in magnitude but this shouldn't matter
    /// can overflow if a > 2 or b << 1 in magnitude
    /// this implements divXp w/o checking for over/under-flows, which saves significantly on gas if these aren't needed
    function divXpU(int256 a, int256 b) internal pure returns (int256) {
        if (b == 0) _require(false, Errors.ZERO_DIVISION);

        return (a * ONE_XP) / b;
    }

    /// @dev multiplies normal precision a with extra precision b (with 38 decimals)
    /// Rounds down in signed direction
    /// returns normal precision of the product
    function mulDownXpToNp(int256 a, int256 b) internal pure returns (int256) {
        int256 b1 = b / 1e19;
        int256 prod1 = a * b1;
        if (!(a == 0 || prod1 / a == b1)) _require(false, Errors.MUL_OVERFLOW);
        int256 b2 = b % 1e19;
        int256 prod2 = a * b2;
        if (!(a == 0 || prod2 / a == b2)) _require(false, Errors.MUL_OVERFLOW);
        return prod1 >= 0 && prod2 >= 0 ? (prod1 + prod2 / 1e19) / 1e19 : (prod1 + prod2 / 1e19 + 1) / 1e19 - 1;
    }

    /// @dev multiplies normal precision a with extra precision b (with 38 decimals)
    /// Rounds down in signed direction
    /// returns normal precision of the product
    /// this implements mulDownXpToNp w/o checking for over/under-flows, which saves significantly on gas if these aren't needed
    function mulDownXpToNpU(int256 a, int256 b) internal pure returns (int256) {
        int256 b1 = b / 1e19;
        int256 b2 = b % 1e19;
        // SOMEDAY check if we eliminate these vars and save some gas (by only checking the sign of prod1, say)
        int256 prod1 = a * b1;
        int256 prod2 = a * b2;
        return prod1 >= 0 && prod2 >= 0 ? (prod1 + prod2 / 1e19) / 1e19 : (prod1 + prod2 / 1e19 + 1) / 1e19 - 1;
    }

    /// @dev multiplies normal precision a with extra precision b (with 38 decimals)
    /// Rounds up in signed direction
    /// returns normal precision of the product
    function mulUpXpToNp(int256 a, int256 b) internal pure returns (int256) {
        int256 b1 = b / 1e19;
        int256 prod1 = a * b1;
        if (!(a == 0 || prod1 / a == b1)) _require(false, Errors.MUL_OVERFLOW);
        int256 b2 = b % 1e19;
        int256 prod2 = a * b2;
        if (!(a == 0 || prod2 / a == b2)) _require(false, Errors.MUL_OVERFLOW);
        return prod1 <= 0 && prod2 <= 0 ? (prod1 + prod2 / 1e19) / 1e19 : (prod1 + prod2 / 1e19 - 1) / 1e19 + 1;
    }

    /// @dev multiplies normal precision a with extra precision b (with 38 decimals)
    /// Rounds up in signed direction
    /// returns normal precision of the product
    /// this implements mulUpXpToNp w/o checking for over/under-flows, which saves significantly on gas if these aren't needed
    function mulUpXpToNpU(int256 a, int256 b) internal pure returns (int256) {
        int256 b1 = b / 1e19;
        int256 b2 = b % 1e19;
        // SOMEDAY check if we eliminate these vars and save some gas (by only checking the sign of prod1, say)
        int256 prod1 = a * b1;
        int256 prod2 = a * b2;
        return prod1 <= 0 && prod2 <= 0 ? (prod1 + prod2 / 1e19) / 1e19 : (prod1 + prod2 / 1e19 - 1) / 1e19 + 1;
    }

    // not implementing the pow functions right now b/c it's annoying and slightly ill-defined, and we don't use them.

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(int256 x) internal pure returns (int256) {
        if (x >= ONE || x <= 0) return 0;
        return ONE - x;
    }
}