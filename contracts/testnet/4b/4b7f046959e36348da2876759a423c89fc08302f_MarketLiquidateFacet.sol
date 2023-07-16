// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

/**
 * @title NumberMath
 * @notice Library for additional math functions that are not included in the OpenZeppelin libraries.
 */
library NumberMath {
    error DivisionByZero();

    /**
     * @notice Divides `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Dividend
     * @param b Divisor
     * @return Resulting quotient
     */
    function divOut(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) revert DivisionByZero();
        return Math.ceilDiv(a, b);
    }

    /**
     * @notice Divides `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Dividend
     * @param b Divisor
     * @return Resulting quotient
     */
    function divOut(int256 a, int256 b) internal pure returns (int256) {
        return sign(a) * sign(b) * int256(divOut(SignedMath.abs(a), SignedMath.abs(b)));
    }

    /**
     * @notice Returns the sign of an int256
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a int256 to find the sign of
     * @return Sign of the int256
     */
    function sign(int256 a) internal pure returns (int256) {
        if (a > 0) return 1;
        if (a < 0) return -1;
        return 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../NumberMath.sol";
import "./Fixed6.sol";
import "./UFixed18.sol";
import "./PackedFixed18.sol";

/// @dev Fixed18 type
type Fixed18 is int256;
using Fixed18Lib for Fixed18 global;
type Fixed18Storage is bytes32;
using Fixed18StorageLib for Fixed18Storage global;

/**
 * @title Fixed18Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed18Lib {
    error Fixed18OverflowError(uint256 value);
    error Fixed18PackingOverflowError(int256 value);
    error Fixed18PackingUnderflowError(int256 value);

    int256 private constant BASE = 1e18;
    Fixed18 public constant ZERO = Fixed18.wrap(0);
    Fixed18 public constant ONE = Fixed18.wrap(BASE);
    Fixed18 public constant NEG_ONE = Fixed18.wrap(-1 * BASE);
    Fixed18 public constant MAX = Fixed18.wrap(type(int256).max);
    Fixed18 public constant MIN = Fixed18.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (Fixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed18OverflowError(value);
        return Fixed18.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed18 m) internal pure returns (Fixed18) {
        if (s > 0) return from(m);
        if (s < 0) {
            // Since from(m) multiplies m by BASE, from(m) cannot be type(int256).min
            // which is the only value that would overflow when negated. Therefore,
            // we can safely negate from(m) without checking for overflow.
            unchecked { return Fixed18.wrap(-1 * Fixed18.unwrap(from(m))); }
        }
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-6 signed fixed-decimal
     * @param a Base-6 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(Fixed6 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed6.unwrap(a) * 1e12);
    }

    /**
     * @notice Creates a packed signed fixed-decimal from an signed fixed-decimal
     * @param a signed fixed-decimal
     * @return New packed signed fixed-decimal
     */
    function pack(Fixed18 a) internal pure returns (PackedFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value > type(int128).max) revert Fixed18PackingOverflowError(value);
        if (value < type(int128).min) revert Fixed18PackingUnderflowError(value);
        return PackedFixed18.wrap(int128(value));
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed18 a) internal pure returns (bool) {
        return Fixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) + Fixed18.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) - Fixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together, rounding the result away from zero if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mulOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(NumberMath.divOut(Fixed18.unwrap(a) * Fixed18.unwrap(b), BASE));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * BASE / Fixed18.unwrap(b));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function divOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18Lib.from(sign(a) * sign(b), a.abs().divOut(b.abs()));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldiv(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldivOut(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / Fixed18.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(NumberMath.divOut(Fixed18.unwrap(a) * Fixed18.unwrap(b), Fixed18.unwrap(c)));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed18 a, Fixed18 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed18.unwrap(a), Fixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.min(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.max(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed18 a) internal pure returns (int256) {
        return Fixed18.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed18 a) internal pure returns (int256) {
        if (Fixed18.unwrap(a) > 0) return 1;
        if (Fixed18.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed18 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(SignedMath.abs(Fixed18.unwrap(a)));
    }
}

library Fixed18StorageLib {
    function read(Fixed18Storage self) internal view returns (Fixed18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Fixed18Storage self, Fixed18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../NumberMath.sol";
import "./Fixed18.sol";
import "./UFixed6.sol";

/// @dev Fixed6 type
type Fixed6 is int256;
using Fixed6Lib for Fixed6 global;
type Fixed6Storage is bytes32;
using Fixed6StorageLib for Fixed6Storage global;

/**
 * @title Fixed6Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed6Lib {
    error Fixed6OverflowError(uint256 value);
    error Fixed6PackingOverflowError(int256 value);
    error Fixed6PackingUnderflowError(int256 value);

    int256 private constant BASE = 1e6;
    Fixed6 public constant ZERO = Fixed6.wrap(0);
    Fixed6 public constant ONE = Fixed6.wrap(BASE);
    Fixed6 public constant NEG_ONE = Fixed6.wrap(-1 * BASE);
    Fixed6 public constant MAX = Fixed6.wrap(type(int256).max);
    Fixed6 public constant MIN = Fixed6.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed6 a) internal pure returns (Fixed6) {
        uint256 value = UFixed6.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed6OverflowError(value);
        return Fixed6.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed6 m) internal pure returns (Fixed6) {
        if (s > 0) return from(m);
        if (s < 0) {
            // Since from(m) multiplies m by BASE, from(m) cannot be type(int256).min
            // which is the only value that would overflow when negated. Therefore,
            // we can safely negate from(m) without checking for overflow.
            unchecked { return Fixed6.wrap(-1 * Fixed6.unwrap(from(m))); }
        }
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed6) {
        return Fixed6.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-18 signed fixed-decimal
     * @param a Base-18 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed18.unwrap(a) / 1e12);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-18 signed fixed-decimal
     * @param a Base-18 signed fixed-decimal
     * @param roundOut Whether to round the result away from zero if there is a remainder
     * @return New signed fixed-decimal
     */
    function from(Fixed18 a, bool roundOut) internal pure returns (Fixed6) {
        return roundOut ? Fixed6.wrap(NumberMath.divOut(Fixed18.unwrap(a), 1e12)): from(a);
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed6 a) internal pure returns (bool) {
        return Fixed6.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) + Fixed6.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) - Fixed6.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * Fixed6.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together, rounding the result away from zero if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mulOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(NumberMath.divOut(Fixed6.unwrap(a) * Fixed6.unwrap(b), BASE));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * BASE / Fixed6.unwrap(b));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function divOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6Lib.from(sign(a) * sign(b), a.abs().divOut(b.abs()));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed6 a, int256 b, int256 c) internal pure returns (Fixed6) {
        return muldiv(a, Fixed6.wrap(b), Fixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed6 a, int256 b, int256 c) internal pure returns (Fixed6) {
        return muldivOut(a, Fixed6.wrap(b), Fixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed6 a, Fixed6 b, Fixed6 c) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * Fixed6.unwrap(b) / Fixed6.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed6 a, Fixed6 b, Fixed6 c) internal pure returns (Fixed6) {
        return Fixed6.wrap(NumberMath.divOut(Fixed6.unwrap(a) * Fixed6.unwrap(b), Fixed6.unwrap(c)));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed6 a, Fixed6 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed6.unwrap(a), Fixed6.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(SignedMath.min(Fixed6.unwrap(a), Fixed6.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(SignedMath.max(Fixed6.unwrap(a), Fixed6.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed6 a) internal pure returns (int256) {
        return Fixed6.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed6 a) internal pure returns (int256) {
        if (Fixed6.unwrap(a) > 0) return 1;
        if (Fixed6.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed6 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(SignedMath.abs(Fixed6.unwrap(a)));
    }
}

library Fixed6StorageLib {
    function read(Fixed6Storage self) internal view returns (Fixed6 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Fixed6Storage self, Fixed6 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./Fixed18.sol";

/// @dev PackedFixed18 type
type PackedFixed18 is int128;
using PackedFixed18Lib for PackedFixed18 global;

/**
 * @title PackedFixed18Lib
 * @dev A packed version of the Fixed18 which takes up half the storage space (two PackedFixed18 can be packed
 *      into a single slot). Only valid within the range -1.7014118e+20 <= x <= 1.7014118e+20.
 * @notice Library for the packed signed fixed-decimal type.
 */
library PackedFixed18Lib {
    PackedFixed18 public constant MAX = PackedFixed18.wrap(type(int128).max);
    PackedFixed18 public constant MIN = PackedFixed18.wrap(type(int128).min);

    /**
     * @notice Creates an unpacked signed fixed-decimal from a packed signed fixed-decimal
     * @param self packed signed fixed-decimal
     * @return New unpacked signed fixed-decimal
     */
    function unpack(PackedFixed18 self) internal pure returns (Fixed18) {
        return Fixed18.wrap(int256(PackedFixed18.unwrap(self)));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./UFixed18.sol";

/// @dev PackedUFixed18 type
type PackedUFixed18 is uint128;
using PackedUFixed18Lib for PackedUFixed18 global;

/**
 * @title PackedUFixed18Lib
 * @dev A packed version of the UFixed18 which takes up half the storage space (two PackedUFixed18 can be packed
 *      into a single slot). Only valid within the range 0 <= x <= 3.4028237e+20.
 * @notice Library for the packed unsigned fixed-decimal type.
 */
library PackedUFixed18Lib {
    PackedUFixed18 public constant MAX = PackedUFixed18.wrap(type(uint128).max);

    /**
     * @notice Creates an unpacked unsigned fixed-decimal from a packed unsigned fixed-decimal
     * @param self packed unsigned fixed-decimal
     * @return New unpacked unsigned fixed-decimal
     */
    function unpack(PackedUFixed18 self) internal pure returns (UFixed18) {
        return UFixed18.wrap(uint256(PackedUFixed18.unwrap(self)));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../NumberMath.sol";
import "./Fixed18.sol";
import "./PackedUFixed18.sol";
import "./UFixed6.sol";

/// @dev UFixed18 type
type UFixed18 is uint256;
using UFixed18Lib for UFixed18 global;
type UFixed18Storage is bytes32;
using UFixed18StorageLib for UFixed18Storage global;

/**
 * @title UFixed18Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed18Lib {
    error UFixed18UnderflowError(int256 value);
    error UFixed18PackingOverflowError(uint256 value);

    uint256 private constant BASE = 1e18;
    UFixed18 public constant ZERO = UFixed18.wrap(0);
    UFixed18 public constant ONE = UFixed18.wrap(BASE);
    UFixed18 public constant MAX = UFixed18.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (UFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value < 0) revert UFixed18UnderflowError(value);
        return UFixed18.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-6 signed fixed-decimal
     * @param a Base-6 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed6 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed6.unwrap(a) * 1e12);
    }

    /**
     * @notice Creates a packed unsigned fixed-decimal from an unsigned fixed-decimal
     * @param a unsigned fixed-decimal
     * @return New packed unsigned fixed-decimal
     */
    function pack(UFixed18 a) internal pure returns (PackedUFixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > type(uint128).max) revert UFixed18PackingOverflowError(value);
        return PackedUFixed18.wrap(uint128(value));
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed18 a) internal pure returns (bool) {
        return UFixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) + UFixed18.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) - UFixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mulOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * UFixed18.unwrap(b), BASE));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * BASE / UFixed18.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function divOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * BASE, UFixed18.unwrap(b)));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldiv(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldivOut(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }


    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / UFixed18.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * UFixed18.unwrap(b), UFixed18.unwrap(c)));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed18 a, UFixed18 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed18.unwrap(a), UFixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.min(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.max(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed18 a) internal pure returns (uint256) {
        return UFixed18.unwrap(a) / BASE;
    }
}

library UFixed18StorageLib {
    function read(UFixed18Storage self) internal view returns (UFixed18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(UFixed18Storage self, UFixed18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../NumberMath.sol";
import "./Fixed6.sol";
import "./UFixed18.sol";

/// @dev UFixed6 type
type UFixed6 is uint256;
using UFixed6Lib for UFixed6 global;
type UFixed6Storage is bytes32;
using UFixed6StorageLib for UFixed6Storage global;

/**
 * @title UFixed6Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed6Lib {
    error UFixed6UnderflowError(int256 value);
    error UFixed6PackingOverflowError(uint256 value);

    uint256 private constant BASE = 1e6;
    UFixed6 public constant ZERO = UFixed6.wrap(0);
    UFixed6 public constant ONE = UFixed6.wrap(BASE);
    UFixed6 public constant MAX = UFixed6.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed6 a) internal pure returns (UFixed6) {
        int256 value = Fixed6.unwrap(a);
        if (value < 0) revert UFixed6UnderflowError(value);
        return UFixed6.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(a * BASE);
    }

    /**
     * @notice Creates an unsigned fixed-decimal from a base-18 unsigned fixed-decimal
     * @param a Base-18 unsigned fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed18.unwrap(a) / 1e12);
    }

    /**
     * @notice Creates an unsigned fixed-decimal from a base-18 unsigned fixed-decimal
     * @param a Base-18 unsigned fixed-decimal
     * @param roundOut Whether to round the result away from zero if there is a remainder
     * @return New unsigned fixed-decimal
     */
    function from(UFixed18 a, bool roundOut) internal pure returns (UFixed6) {
        return roundOut ? UFixed6.wrap(NumberMath.divOut(UFixed18.unwrap(a), 1e12)): from(a);
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed6 a) internal pure returns (bool) {
        return UFixed6.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) + UFixed6.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) - UFixed6.unwrap(b));
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * UFixed6.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mulOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * UFixed6.unwrap(b), BASE));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * BASE / UFixed6.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function divOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * BASE, UFixed6.unwrap(b)));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed6 a, uint256 b, uint256 c) internal pure returns (UFixed6) {
        return muldiv(a, UFixed6.wrap(b), UFixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed6 a, uint256 b, uint256 c) internal pure returns (UFixed6) {
        return muldivOut(a, UFixed6.wrap(b), UFixed6.wrap(c));
    }


    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed6 a, UFixed6 b, UFixed6 c) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * UFixed6.unwrap(b) / UFixed6.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed6 a, UFixed6 b, UFixed6 c) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * UFixed6.unwrap(b), UFixed6.unwrap(c)));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed6 a, UFixed6 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed6.unwrap(a), UFixed6.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(Math.min(UFixed6.unwrap(a), UFixed6.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(Math.max(UFixed6.unwrap(a), UFixed6.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed6 a) internal pure returns (uint256) {
        return UFixed6.unwrap(a) / BASE;
    }
}

library UFixed6StorageLib {
    function read(UFixed6Storage self) internal view returns (UFixed6 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(UFixed6Storage self, UFixed6 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURI.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
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
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "../math/SafeCast.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
 * used in storage, and not in memory.
 * ```solidity
 * DoubleEndedQueue.Bytes32Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library DoubleEndedQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Bytes32Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => bytes32) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Bytes32Deque storage deque, bytes32 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Bytes32Deque storage deque, bytes32 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Bytes32Deque storage deque, uint256 index) internal view returns (bytes32 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {IDiamondCut} from "@chromatic-protocol/contracts/core/interfaces/IDiamondCut.sol";
import {DiamondStorage, DiamondStorageLib} from "@chromatic-protocol/contracts/core/libraries/DiamondStorage.sol";

abstract contract Diamond {
    constructor(address _diamondCutFacet) payable {
        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        DiamondStorageLib.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        DiamondStorage storage ds;
        bytes32 position = DiamondStorageLib.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAutomate, IOpsProxyFactory, ITaskTreasuryUpgradable, ModuleData} from "@chromatic-protocol/contracts/core/base/gelato/Types.sol";

/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */
// solhint-disable private-vars-leading-underscore
abstract contract AutomateReady {
    IAutomate public immutable automate;
    address public immutable dedicatedMsgSender;
    address private immutable _gelato;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant OPS_PROXY_FACTORY = 0xC815dB16D4be6ddf2685C201937905aBf338F5D7;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _automate, address _taskCreator, address opsProxyFactory) {
        automate = IAutomate(_automate);
        _gelato = IAutomate(_automate).gelato();
        if (opsProxyFactory == address(0)) opsProxyFactory = OPS_PROXY_FACTORY;
        (dedicatedMsgSender, ) = IOpsProxyFactory(opsProxyFactory).getProxyOf(_taskCreator);
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IAutomate.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success, ) = _gelato.call{value: _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), _gelato, _fee);
        }
    }

    function _getFeeDetails() internal view returns (uint256 fee, address feeToken) {
        (fee, feeToken) = automate.getFeeDetails();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

enum Module {
    RESOLVER,
    TIME,
    PROXY,
    SINGLE_EXEC
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IAutomate {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(address receiver, address token, uint256 amount) external payable;

    function withdrawFunds(address payable receiver, address token, uint256 amount) external;
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IMarketLiquidate} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidate.sol";
import {IAutomate, Module, ModuleData} from "@chromatic-protocol/contracts/core/base/gelato/Types.sol";

/**
 * @title Liquidator
 * @dev An abstract contract for liquidation functionality in the Chromatic protocol.
 */
abstract contract Liquidator is IChromaticLiquidator {
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant DEFAULT_LIQUIDATION_INTERVAL = 1 minutes;
    uint256 private constant DEFAULT_CLAIM_INTERVAL = 1 days;

    IChromaticMarketFactory factory;
    uint256 public liquidationInterval;
    uint256 public claimInterval;

    mapping(address => mapping(uint256 => bytes32)) private _liquidationTaskIds;
    mapping(address => mapping(uint256 => bytes32)) private _claimPositionTaskIds;

    error OnlyAccessableByDao();
    error OnlyAccessableByMarket();

    /**
     * @dev Modifier to restrict access to only the DAO.
     */
    modifier onlyDao() {
        if (msg.sender != factory.dao()) revert OnlyAccessableByDao();
        _;
    }

    /**
     * @dev Modifier to check if the calling contract is a registered market.
     */
    modifier onlyMarket() {
        if (!factory.isRegisteredMarket(msg.sender)) revert OnlyAccessableByMarket();
        _;
    }

    /**
     * @dev Initializes the Liquidator contract.
     * @param _factory The address of the ChromaticMarketFactory contract.
     */
    constructor(IChromaticMarketFactory _factory) {
        factory = _factory;
        liquidationInterval = DEFAULT_LIQUIDATION_INTERVAL;
        claimInterval = DEFAULT_CLAIM_INTERVAL;
    }

    /**
     * @dev Retrieves the IAutomate contract instance.
     * @return IAutomate The IAutomate contract instance.
     */
    function getAutomate() internal view virtual returns (IAutomate);

    /**
     * @inheritdoc IChromaticLiquidator
     * @dev Can only be called by the DAO
     */
    function updateLiquidationInterval(uint256 interval) external override {
        liquidationInterval = interval;
        emit UpdateLiquidationInterval(interval);
    }

    /**
     * @inheritdoc IChromaticLiquidator
     * @dev Can only be called by the DAO
     */
    function updateClaimInterval(uint256 interval) external override {
        claimInterval = interval;
        emit UpdateClaimInterval(interval);
    }

    /**
     * @inheritdoc IChromaticLiquidator
     * @dev Can only be called by a registered market.
     */
    function createLiquidationTask(uint256 positionId) external override onlyMarket {
        _createTask(_liquidationTaskIds, positionId, this.resolveLiquidation, liquidationInterval);
    }

    /**
     * @inheritdoc IChromaticLiquidator
     * @dev Can only be called by a registered market.
     */
    function cancelLiquidationTask(uint256 positionId) external override onlyMarket {
        _cancelTask(_liquidationTaskIds, positionId);
    }

    /**
     * @inheritdoc IChromaticLiquidator
     */
    function resolveLiquidation(
        address _market,
        uint256 positionId
    ) external view override returns (bool canExec, bytes memory execPayload) {
        if (IMarketLiquidate(_market).checkLiquidation(positionId)) {
            return (true, abi.encodeCall(this.liquidate, (_market, positionId)));
        }

        return (false, bytes(""));
    }

    /**
     * @dev Internal function to perform the liquidation of a position.
     * @param _market The address of the market contract.
     * @param positionId The ID of the position to be liquidated.
     * @param fee The fee to be paid for the liquidation.
     */
    function _liquidate(address _market, uint256 positionId, uint256 fee) internal {
        IMarketLiquidate market = IMarketLiquidate(_market);
        market.liquidate(positionId, getAutomate().gelato(), fee);
    }

    /**
     * @inheritdoc IChromaticLiquidator
     * @dev Can only be called by a registered market.
     */
    function createClaimPositionTask(uint256 positionId) external override onlyMarket {
        _createTask(_claimPositionTaskIds, positionId, this.resolveClaimPosition, claimInterval);
    }

    /**
     * @inheritdoc IChromaticLiquidator
     * @dev Can only be called by a registered market.
     */
    function cancelClaimPositionTask(uint256 positionId) external override onlyMarket {
        _cancelTask(_claimPositionTaskIds, positionId);
    }

    /**
     * @inheritdoc IChromaticLiquidator
     */
    function resolveClaimPosition(
        address _market,
        uint256 positionId
    ) external view override returns (bool canExec, bytes memory execPayload) {
        if (IMarketLiquidate(_market).checkClaimPosition(positionId)) {
            return (true, abi.encodeCall(this.claimPosition, (_market, positionId)));
        }

        return (false, "");
    }

    /**
     * @dev Internal function to perform the claim of a position.
     * @param _market The address of the market contract.
     * @param positionId The ID of the position to be claimed.
     * @param fee The fee to be paid for the claim.
     */
    function _claimPosition(address _market, uint256 positionId, uint256 fee) internal {
        IMarketLiquidate market = IMarketLiquidate(_market);
        market.claimPosition(positionId, getAutomate().gelato(), fee);
    }

    /**
     * @dev Internal function to create a Gelato task for liquidation or claim position.
     * @param registry The mapping to store task IDs.
     * @param positionId The ID of the position.
     * @param resolve The resolve function to be called by the Gelato automation system.
     * @param interval The interval between task executions.
     */
    function _createTask(
        mapping(address => mapping(uint256 => bytes32)) storage registry,
        uint256 positionId,
        function(address, uint256) external view returns (bool, bytes memory) resolve,
        uint256 interval
    ) internal {
        address market = msg.sender;
        if (registry[market][positionId] != bytes32(0)) {
            return;
        }

        ModuleData memory moduleData = ModuleData({modules: new Module[](3), args: new bytes[](3)});

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.TIME;
        moduleData.modules[2] = Module.PROXY;
        moduleData.args[0] = abi.encode(
            address(this),
            abi.encodeCall(resolve, (market, positionId))
        );
        moduleData.args[1] = abi.encode(uint128(block.timestamp + interval), uint128(interval));
        moduleData.args[2] = bytes("");

        registry[market][positionId] = getAutomate().createTask(
            address(this),
            abi.encode(this.liquidate.selector),
            moduleData,
            ETH
        );
    }

    /**
     * @dev Internal function to cancel a Gelato task.
     * @param registry The mapping storing task IDs.
     * @param positionId The ID of the position.
     */
    function _cancelTask(
        mapping(address => mapping(uint256 => bytes32)) storage registry,
        uint256 positionId
    ) internal {
        address market = msg.sender;
        bytes32 taskId = registry[market][positionId];
        if (taskId != bytes32(0)) {
            getAutomate().cancelTask(taskId);
            delete registry[market][positionId];
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {Liquidator} from "@chromatic-protocol/contracts/core/base/Liquidator.sol";
import {AutomateReady} from "@chromatic-protocol/contracts/core/base/gelato/AutomateReady.sol";
import {IAutomate} from "@chromatic-protocol/contracts/core/base/gelato/Types.sol";

/**
 * @title ChromaticLiquidator
 * @dev A contract that handles the liquidation and claiming of positions in Chromatic markets.
 *      It extends the Liquidator and AutomateReady contracts and implements the IChromaticLiquidator interface.
 */
contract ChromaticLiquidator is Liquidator, AutomateReady {
    /**
     * @dev Constructor function.
     * @param _factory The address of the Chromatic Market Factory contract.
     * @param _automate The address of the Gelato Automate contract.
     * @param opsProxyFactory The address of the Ops Proxy Factory contract.
     */
    constructor(
        IChromaticMarketFactory _factory,
        address _automate,
        address opsProxyFactory
    ) Liquidator(_factory) AutomateReady(_automate, address(this), opsProxyFactory) {}

    /**
     * @inheritdoc Liquidator
     */
    function getAutomate() internal view override returns (IAutomate) {
        return automate;
    }

    /**
     * @inheritdoc IChromaticLiquidator
     */
    function liquidate(address market, uint256 positionId) external override {
        // feeToken is the native token because ETH is set as a fee token when creating task
        (uint256 fee, ) = _getFeeDetails();
        _liquidate(market, positionId, fee);
    }

    /**
     * @inheritdoc IChromaticLiquidator
     */
    function claimPosition(address market, uint256 positionId) external override {
        // feeToken is the native token because ETH is set as a fee token when creating task
        (uint256 fee, ) = _getFeeDetails();
        _claimPosition(market, positionId, fee);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {CLBTokenDeployerLib} from "@chromatic-protocol/contracts/core/libraries/deployer/CLBTokenDeployer.sol";
import {MarketStorage, MarketStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {Diamond} from "@chromatic-protocol/contracts/core/base/Diamond.sol";

/**
 * @title ChromaticMarket
 * @dev A contract that represents a Chromatic market, combining trade and liquidity functionalities.
 */
contract ChromaticMarket is Diamond {
    constructor(address diamondCutFacet) Diamond(diamondCutFacet) {
        IChromaticMarketFactory factory = IChromaticMarketFactory(msg.sender);

        (address _oracleProvider, address _settlementToken) = factory.parameters();
        MarketStorage storage ms = MarketStorageLib.marketStorage();

        ms.factory = factory;
        ms.oracleProvider = IOracleProvider(_oracleProvider);
        ms.settlementToken = IERC20Metadata(_settlementToken);
        ms.clbToken = ICLBToken(CLBTokenDeployerLib.deploy());
        ms.liquidator = IChromaticLiquidator(factory.liquidator());
        ms.vault = IChromaticVault(factory.vault());
        ms.keeperFeePayer = IKeeperFeePayer(factory.keeperFeePayer());

        ms.liquidityPool.initialize();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {IMarketDeployer} from "@chromatic-protocol/contracts/core/interfaces/factory/IMarketDeployer.sol";
import {IOracleProviderRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/IOracleProviderRegistry.sol";
import {ISettlementTokenRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/ISettlementTokenRegistry.sol";
import {IMarketState} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketState.sol";
import {OracleProviderRegistry, OracleProviderRegistryLib} from "@chromatic-protocol/contracts/core/libraries/registry/OracleProviderRegistry.sol";
import {SettlementTokenRegistry, SettlementTokenRegistryLib} from "@chromatic-protocol/contracts/core/libraries/registry/SettlementTokenRegistry.sol";
import {InterestRate} from "@chromatic-protocol/contracts/core/libraries/InterestRate.sol";
import {MarketDeployer, MarketDeployerLib, Parameters} from "@chromatic-protocol/contracts/core/libraries/deployer/MarketDeployer.sol";

/**
 * @title ChromaticMarketFactory
 * @dev Contract for managing the creation and registration of Chromatic markets.
 */
contract ChromaticMarketFactory is IChromaticMarketFactory {
    using OracleProviderRegistryLib for OracleProviderRegistry;
    using SettlementTokenRegistryLib for SettlementTokenRegistry;
    using MarketDeployerLib for MarketDeployer;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public override dao;

    address public override liquidator;
    address public override vault;
    address public override keeperFeePayer;
    address public override treasury;

    address private marketDiamondCutFacet;
    address private marketLoupeFacet;
    address private marketStateFacet;
    address private marketLiquidityFacet;
    address private marketTradeFacet;
    address private marketLiquidateFacet;
    address private marketSettleFacet;

    OracleProviderRegistry private _oracleProviderRegistry;
    SettlementTokenRegistry private _settlementTokenRegistry;

    MarketDeployer private _deployer;
    mapping(address => mapping(address => bool)) private _registered;
    mapping(address => address[]) private _marketsBySettlementToken;
    EnumerableSet.AddressSet private _markets;

    error OnlyAccessableByDao();
    error AlreadySetLiquidator();
    error AlreadySetVault();
    error AlreadySetKeeperFeePayer();
    error NotRegisteredOracleProvider();
    error NotRegisteredSettlementToken();
    error WrongTokenAddress();
    error ExistMarket();

    /**
     * @dev Modifier to restrict access to only the DAO address
     */
    modifier onlyDao() {
        if (msg.sender != dao) revert OnlyAccessableByDao();
        _;
    }

    /**
     * @dev Modifier to ensure that the caller is a registered oracle provider.
     *      Throws a 'NotRegisteredOracleProvider' error if the oracle provider is not registered.
     * @param oracleProvider The address of the oracle provider.
     */
    modifier onlyRegisteredOracleProvider(address oracleProvider) {
        if (!_oracleProviderRegistry.isRegistered(oracleProvider))
            revert NotRegisteredOracleProvider();
        _;
    }

    /**
     * @dev Initializes the ChromaticMarketFactory contract.
     * @param _marketDiamondCutFacet The market diamond cut facet address.
     * @param _marketLoupeFacet The market loupe facet address.
     * @param _marketStateFacet The market state facet address.
     * @param _marketLiquidityFacet The market liquidity facet address.
     * @param _marketTradeFacet The market trade facet address.
     * @param _marketLiquidateFacet The market liquidate facet address.
     * @param _marketSettleFacet The market settle facet address.
     */
    constructor(
        address _marketDiamondCutFacet,
        address _marketLoupeFacet,
        address _marketStateFacet,
        address _marketLiquidityFacet,
        address _marketTradeFacet,
        address _marketLiquidateFacet,
        address _marketSettleFacet
    ) {
        dao = msg.sender;
        treasury = dao;

        marketDiamondCutFacet = _marketDiamondCutFacet;
        marketLoupeFacet = _marketLoupeFacet;
        marketStateFacet = _marketStateFacet;
        marketLiquidityFacet = _marketLiquidityFacet;
        marketTradeFacet = _marketTradeFacet;
        marketLiquidateFacet = _marketLiquidateFacet;
        marketSettleFacet = _marketSettleFacet;
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     */
    function updateDao(address _dao) external override onlyDao {
        dao = _dao;
        emit UpdateDao(dao);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     */
    function updateTreasury(address _treasury) external override onlyDao {
        treasury = _treasury;
        emit UpdateTreasury(treasury);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     */
    function setLiquidator(address _liquidator) external override onlyDao {
        if (liquidator != address(0)) revert AlreadySetLiquidator();

        liquidator = _liquidator;
        emit SetLiquidator(liquidator);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     */
    function setVault(address _vault) external override onlyDao {
        if (vault != address(0)) revert AlreadySetVault();

        vault = _vault;
        emit SetVault(vault);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     * @dev This function can only be called by the DAO address.
     */
    function setKeeperFeePayer(address _keeperFeePayer) external override onlyDao {
        if (keeperFeePayer != address(0)) revert AlreadySetKeeperFeePayer();

        keeperFeePayer = _keeperFeePayer;
        emit SetKeeperFeePayer(keeperFeePayer);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     */
    function getMarkets() external view override returns (address[] memory) {
        return _markets.values();
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     */
    function getMarketsBySettlmentToken(
        address settlementToken
    ) external view override returns (address[] memory) {
        return _marketsBySettlementToken[settlementToken];
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     */
    function getMarket(
        address oracleProvider,
        address settlementToken
    ) external view override returns (address) {
        if (!_registered[oracleProvider][settlementToken]) return address(0);

        address[] memory markets = _marketsBySettlementToken[settlementToken];
        for (uint i; i < markets.length; ) {
            if (address(IMarketState(markets[i]).oracleProvider()) == oracleProvider) {
                return markets[i];
            }

            unchecked {
                i++;
            }
        }
        return address(0);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     */
    function isRegisteredMarket(address market) external view override returns (bool) {
        return _markets.contains(market);
    }

    /**
     * @inheritdoc IChromaticMarketFactory
     */
    function createMarket(
        address oracleProvider,
        address settlementToken
    ) external override onlyRegisteredOracleProvider(oracleProvider) {
        if (!_settlementTokenRegistry.isRegistered(settlementToken))
            revert NotRegisteredSettlementToken();

        if (_registered[oracleProvider][settlementToken]) revert ExistMarket();

        address market = _deployer.deploy(
            oracleProvider,
            settlementToken,
            marketDiamondCutFacet,
            marketLoupeFacet,
            marketStateFacet,
            marketLiquidityFacet,
            marketTradeFacet,
            marketLiquidateFacet,
            marketSettleFacet
        );

        _registered[oracleProvider][settlementToken] = true;
        _marketsBySettlementToken[settlementToken].push(market);
        _markets.add(market);

        IChromaticVault(vault).createMarketEarningDistributionTask(market);

        emit MarketCreated(oracleProvider, settlementToken, market);
    }

    /**
     * @inheritdoc IMarketDeployer
     */
    function parameters()
        external
        view
        override
        returns (address oracleProvider, address settlementToken)
    {
        Parameters memory params = _deployer.parameters;
        return (params.oracleProvider, params.settlementToken);
    }

    // implement IOracleProviderRegistry

    /**
     * @inheritdoc IOracleProviderRegistry
     * @dev This function can only be called by the DAO address.
     */
    function registerOracleProvider(
        address oracleProvider,
        OracleProviderProperties memory properties
    ) external override onlyDao {
        _oracleProviderRegistry.register(
            oracleProvider,
            properties.minTakeProfitBPS,
            properties.maxTakeProfitBPS,
            properties.leverageLevel
        );
        emit OracleProviderRegistered(oracleProvider, properties);
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     * @dev This function can only be called by the DAO address.
     */
    function unregisterOracleProvider(address oracleProvider) external override onlyDao {
        _oracleProviderRegistry.unregister(oracleProvider);
        emit OracleProviderUnregistered(oracleProvider);
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     */
    function registeredOracleProviders() external view override returns (address[] memory) {
        return _oracleProviderRegistry.oracleProviders();
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     */
    function isRegisteredOracleProvider(
        address oracleProvider
    ) external view override returns (bool) {
        return _oracleProviderRegistry.isRegistered(oracleProvider);
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     */
    function getOracleProviderProperties(
        address oracleProvider
    )
        external
        view
        override
        onlyRegisteredOracleProvider(oracleProvider)
        returns (OracleProviderProperties memory)
    {
        (
            uint32 minTakeProfitBPS,
            uint32 maxTakeProfitBPS,
            uint8 leverageLevel
        ) = _oracleProviderRegistry.getOracleProviderProperties(oracleProvider);

        return
            OracleProviderProperties({
                minTakeProfitBPS: minTakeProfitBPS,
                maxTakeProfitBPS: maxTakeProfitBPS,
                leverageLevel: leverageLevel
            });
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     * @dev This function can only be called by the DAO and registered oracle providers.
     */
    function updateTakeProfitBPSRange(
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS
    ) external override onlyDao onlyRegisteredOracleProvider(oracleProvider) {
        _oracleProviderRegistry.setTakeProfitBPSRange(
            oracleProvider,
            minTakeProfitBPS,
            maxTakeProfitBPS
        );
        emit UpdateTakeProfitBPSRange(oracleProvider, minTakeProfitBPS, maxTakeProfitBPS);
    }

    /**
     * @inheritdoc IOracleProviderRegistry
     * @dev This function can only be called by the DAO and registered oracle providers.
     */
    function updateLeverageLevel(
        address oracleProvider,
        uint8 level
    ) external override onlyDao onlyRegisteredOracleProvider(oracleProvider) {
        require(level <= 1);
        _oracleProviderRegistry.setLeverageLevel(oracleProvider, level);
        emit UpdateLeverageLevel(oracleProvider, level);
    }

    // implement ISettlementTokenRegistry

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function registerSettlementToken(
        address token,
        uint256 minimumMargin,
        uint256 interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    ) external override onlyDao {
        _settlementTokenRegistry.register(
            token,
            minimumMargin,
            interestRate,
            flashLoanFeeRate,
            earningDistributionThreshold,
            uniswapFeeTier
        );

        IKeeperFeePayer(keeperFeePayer).approveToRouter(token, true);
        IChromaticVault(vault).createMakerEarningDistributionTask(token);

        emit SettlementTokenRegistered(
            token,
            minimumMargin,
            interestRate,
            flashLoanFeeRate,
            earningDistributionThreshold,
            uniswapFeeTier
        );
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function registeredSettlementTokens() external view override returns (address[] memory) {
        return _settlementTokenRegistry.settlementTokens();
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function isRegisteredSettlementToken(address token) external view override returns (bool) {
        return _settlementTokenRegistry.isRegistered(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getMinimumMargin(address token) external view returns (uint256) {
        return _settlementTokenRegistry.getMinimumMargin(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function setMinimumMargin(address token, uint256 minimumMargin) external onlyDao {
        _settlementTokenRegistry.setMinimumMargin(token, minimumMargin);
        emit SetMinimumMargin(token, minimumMargin);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getFlashLoanFeeRate(address token) external view returns (uint256) {
        return _settlementTokenRegistry.getFlashLoanFeeRate(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function setFlashLoanFeeRate(address token, uint256 flashLoanFeeRate) external onlyDao {
        _settlementTokenRegistry.setFlashLoanFeeRate(token, flashLoanFeeRate);
        emit SetFlashLoanFeeRate(token, flashLoanFeeRate);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getEarningDistributionThreshold(address token) external view returns (uint256) {
        return _settlementTokenRegistry.getEarningDistributionThreshold(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function setEarningDistributionThreshold(
        address token,
        uint256 earningDistributionThreshold
    ) external onlyDao {
        _settlementTokenRegistry.setEarningDistributionThreshold(
            token,
            earningDistributionThreshold
        );
        emit SetEarningDistributionThreshold(token, earningDistributionThreshold);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getUniswapFeeTier(address token) external view returns (uint24) {
        return _settlementTokenRegistry.getUniswapFeeTier(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function setUniswapFeeTier(address token, uint24 uniswapFeeTier) external onlyDao {
        _settlementTokenRegistry.setUniswapFeeTier(token, uniswapFeeTier);
        emit SetUniswapFeeTier(token, uniswapFeeTier);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function appendInterestRateRecord(
        address token,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) external override onlyDao {
        _settlementTokenRegistry.appendInterestRateRecord(token, annualRateBPS, beginTimestamp);
        emit InterestRateRecordAppended(token, annualRateBPS, beginTimestamp);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     * @dev This function can only be called by the DAO address.
     */
    function removeLastInterestRateRecord(address token) external override onlyDao {
        (bool removed, InterestRate.Record memory record) = _settlementTokenRegistry
            .removeLastInterestRateRecord(token);

        if (removed) {
            emit LastInterestRateRecordRemoved(token, record.annualRateBPS, record.beginTimestamp);
        }
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function getInterestRateRecords(
        address token
    ) external view returns (InterestRate.Record[] memory) {
        return _settlementTokenRegistry.getInterestRateRecords(token);
    }

    /**
     * @inheritdoc ISettlementTokenRegistry
     */
    function currentInterestRate(
        address token
    ) external view override returns (uint256 annualRateBPS) {
        return _settlementTokenRegistry.currentInterestRate(token);
    }

    // implement IInterestCalculator

    /**
     * @inheritdoc IInterestCalculator
     */
    function calculateInterest(
        address token,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) external view override returns (uint256) {
        return _settlementTokenRegistry.calculateInterest(token, amount, from, to);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {ILendingPool} from "@chromatic-protocol/contracts/core/interfaces/vault/ILendingPool.sol";
import {IVault} from "@chromatic-protocol/contracts/core/interfaces/vault/IVault.sol";
import {IChromaticFlashLoanCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticFlashLoanCallback.sol";
import {AutomateReady} from "@chromatic-protocol/contracts/core/base/gelato/AutomateReady.sol";
import {IAutomate, Module, ModuleData} from "@chromatic-protocol/contracts/core/base/gelato/Types.sol";
import {BPS} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";

/**
 * @title ChromaticVault
 * @dev A contract that implements the ChromaticVault interface
 *      and provides functionality for managing positions, liquidity, and fees in Chromatic markets.
 */
contract ChromaticVault is IChromaticVault, ReentrancyGuard, AutomateReady {
    using Math for uint256;

    uint256 private constant DISTRIBUTION_INTERVAL = 1 hours;

    IChromaticMarketFactory factory;
    IKeeperFeePayer keeperFeePayer;

    mapping(address => uint256) public makerBalances; // settlement token => balance
    mapping(address => uint256) public takerBalances; // settlement token => balance
    mapping(address => uint256) public makerMarketBalances; // market => balance
    mapping(address => uint256) public takerMarketBalances; // market => balance
    mapping(address => uint256) public pendingMakerEarnings; // settlement token => earning
    mapping(address => uint256) public pendingMarketEarnings; // market => earning
    mapping(address => uint256) public pendingDeposits; // settlement token => deposit
    mapping(address => uint256) public pendingWithdrawals; // settlement token => deposit

    mapping(address => bytes32) public makerEarningDistributionTaskIds; // settlement token => task id
    mapping(address => bytes32) public marketEarningDistributionTaskIds; // market => task id

    error OnlyAccessableByFactoryOrDao();
    error OnlyAccessableByMarket();
    error NotEnoughBalance();
    error NotEnoughFeePaid();
    error ExistMarketEarningDistributionTask();

    /**
     * @dev Modifier to restrict access to only the factory or the DAO.
     */
    modifier onlyFactoryOrDao() {
        if (msg.sender != address(factory) && msg.sender != factory.dao())
            revert OnlyAccessableByFactoryOrDao();
        _;
    }

    /**
     * @dev Modifier to restrict access to only the Market contract.
     */
    modifier onlyMarket() {
        if (!factory.isRegisteredMarket(msg.sender)) revert OnlyAccessableByMarket();
        _;
    }

    /**
     * @dev Constructs a new ChromaticVault instance.
     * @param _factory The address of the Chromatic Market Factory contract.
     * @param _automate The address of the Gelato Automate contract.
     * @param opsProxyFactory The address of the OpsProxyFactory contract.
     */
    constructor(
        IChromaticMarketFactory _factory,
        address _automate,
        address opsProxyFactory
    ) AutomateReady(_automate, address(this), opsProxyFactory) {
        factory = _factory;
        keeperFeePayer = IKeeperFeePayer(factory.keeperFeePayer());
    }

    // implement IVault

    /**
     * @inheritdoc IVault
     * @dev This function can only be called by a market contract.
     */
    function onOpenPosition(
        address settlementToken,
        uint256 positionId,
        uint256 takerMargin,
        uint256 tradingFee,
        uint256 protocolFee
    ) external override onlyMarket {
        address market = msg.sender;

        takerBalances[settlementToken] += takerMargin;
        takerMarketBalances[market] += takerMargin;

        makerBalances[settlementToken] += tradingFee;
        makerMarketBalances[market] += tradingFee;

        transferProtocolFee(market, settlementToken, positionId, protocolFee);

        emit OnOpenPosition(market, positionId, takerMargin, tradingFee, protocolFee);
    }

    /**
     * @inheritdoc IVault
     * @dev This function can only be called by a market contract.
     */
    function onClaimPosition(
        address settlementToken,
        uint256 positionId,
        address recipient,
        uint256 takerMargin,
        uint256 settlementAmount
    ) external override onlyMarket {
        address market = msg.sender;

        SafeERC20.safeTransfer(IERC20(settlementToken), recipient, settlementAmount);

        takerBalances[settlementToken] -= takerMargin;
        takerMarketBalances[market] -= takerMargin;

        if (settlementAmount > takerMargin) {
            // maker loss
            uint256 makerLoss = settlementAmount - takerMargin;

            makerBalances[settlementToken] -= makerLoss;
            makerMarketBalances[market] -= makerLoss;
        } else {
            // maker profit
            uint256 makerProfit = takerMargin - settlementAmount;

            makerBalances[settlementToken] += makerProfit;
            makerMarketBalances[market] += makerProfit;
        }

        emit OnClaimPosition(market, positionId, recipient, takerMargin, settlementAmount);
    }

    /**
     * @inheritdoc IVault
     * @dev This function can only be called by a market contract.
     */
    function onAddLiquidity(address settlementToken, uint256 amount) external override onlyMarket {
        address market = msg.sender;

        pendingDeposits[settlementToken] += amount;

        emit OnAddLiquidity(market, amount);
    }

    /**
     * @inheritdoc IVault
     * @dev This function can only be called by a market contract.
     */
    function onSettlePendingLiquidity(
        address settlementToken,
        uint256 pendingDeposit,
        uint256 pendingWithdrawal
    ) external override onlyMarket {
        address market = msg.sender;

        pendingDeposits[settlementToken] -= pendingDeposit;
        pendingWithdrawals[settlementToken] += pendingWithdrawal;
        makerBalances[settlementToken] =
            makerBalances[settlementToken] +
            pendingDeposit -
            pendingWithdrawal;
        makerMarketBalances[market] =
            makerMarketBalances[market] +
            pendingDeposit -
            pendingWithdrawal;

        emit OnSettlePendingLiquidity(market, pendingDeposit, pendingWithdrawal);
    }

    /**
     * @inheritdoc IVault
     * @dev This function can only be called by a market contract.
     */
    function onWithdrawLiquidity(
        address settlementToken,
        address recipient,
        uint256 amount
    ) external override onlyMarket {
        address market = msg.sender;

        SafeERC20.safeTransfer(IERC20(settlementToken), recipient, amount);

        pendingWithdrawals[settlementToken] -= amount;

        emit OnWithdrawLiquidity(market, amount, recipient);
    }

    /**
     * @inheritdoc IVault
     * @dev This function can only be called by a market contract.
     */
    function transferKeeperFee(
        address settlementToken,
        address keeper,
        uint256 fee,
        uint256 margin
    ) external override onlyMarket returns (uint256 usedFee) {
        if (fee == 0) return 0;

        address market = msg.sender;

        usedFee = _transferKeeperFee(settlementToken, keeper, fee, margin);

        takerBalances[settlementToken] -= usedFee;
        takerMarketBalances[market] -= usedFee;

        emit TransferKeeperFee(market, fee, usedFee);
    }

    /**
     * @notice Internal function to transfer the keeper fee.
     * @param token The address of the settlement token.
     * @param keeper The address of the keeper to receive the fee.
     * @param fee The amount of the fee to transfer as native token.
     * @param margin The margin amount used for the fee payment.
     * @return usedFee The actual settlement token amount of fee used for the transfer.
     */
    function _transferKeeperFee(
        address token,
        address keeper,
        uint256 fee,
        uint256 margin
    ) internal returns (uint256 usedFee) {
        if (fee == 0) return 0;

        // swap to native token
        SafeERC20.safeTransfer(IERC20(token), address(keeperFeePayer), margin);

        return keeperFeePayer.payKeeperFee(token, fee, keeper);
    }

    /**
     * @notice Transfers the protocol fee to the DAO treasury address.
     * @param market The address of the market contract.
     * @param settlementToken The address of the settlement token.
     * @param positionId The ID of the position.
     * @param amount The amount of the protocol fee to transfer.
     */
    function transferProtocolFee(
        address market,
        address settlementToken,
        uint256 positionId,
        uint256 amount
    ) internal {
        if (amount != 0) {
            SafeERC20.safeTransfer(IERC20(settlementToken), factory.treasury(), amount);
            emit TransferProtocolFee(market, positionId, amount);
        }
    }

    // implement ILendingPool

    /**
     * @inheritdoc ILendingPool
     */
    function flashLoan(
        address token,
        uint256 amount,
        address recipient,
        bytes calldata data
    ) external nonReentrant {
        uint256 balance = IERC20(token).balanceOf(address(this));

        // Ensure that the loan amount does not exceed the available balance
        // after considering pending deposits and withdrawals
        if (amount > balance - pendingDeposits[token] - pendingWithdrawals[token])
            revert NotEnoughBalance();

        // Calculate the fee for the flash loan based on the loan amount and the flash loan fee rate of the token
        uint256 fee = amount.mulDiv(factory.getFlashLoanFeeRate(token), BPS, Math.Rounding.Up);

        SafeERC20.safeTransfer(IERC20(token), recipient, amount);

        // Invoke the flash loan callback function on the sender contract to process the loan
        IChromaticFlashLoanCallback(msg.sender).flashLoanCallback(fee, data);

        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        // Ensure that the fee has been paid by the recipient
        if (balanceAfter < balance + fee) revert NotEnoughFeePaid();

        uint256 paid = balanceAfter - balance;

        // Calculate the amounts to be distributed to the taker pool and maker pool
        uint256 takerBalance = takerBalances[token];
        uint256 makerBalance = makerBalances[token];
        uint256 paidToTakerPool = paid.mulDiv(takerBalance, takerBalance + makerBalance);
        uint256 paidToMakerPool = paid - paidToTakerPool;

        // Transfer the amount paid to the taker pool to the DAO treasury address
        if (paidToTakerPool != 0) {
            SafeERC20.safeTransfer(IERC20(token), factory.treasury(), paidToTakerPool);
        }
        // Add the amount paid to the maker pool to the pending maker earnings
        pendingMakerEarnings[token] += paidToMakerPool;

        emit FlashLoan(msg.sender, recipient, amount, paid, paidToTakerPool, paidToMakerPool);
    }

    /**
     * @inheritdoc ILendingPool
     * @dev The pending share of earnings is calculated based on the bin balance, maker balances, and market balances.
     */
    function getPendingBinShare(
        address market,
        address settlementToken,
        uint256 binBalance
    ) external view returns (uint256) {
        uint256 makerBalance = makerBalances[settlementToken];
        uint256 marketBalance = makerMarketBalances[market];

        return
            (
                // Calculate the pending share of earnings for the bin based on the maker balances and bin balance
                makerBalance == 0
                    ? 0
                    : pendingMakerEarnings[settlementToken].mulDiv(
                        binBalance,
                        makerBalance,
                        Math.Rounding.Up
                    )
            ) +
            (
                // Calculate the pending share of earnings for the bin based on the market balances and bin balance
                marketBalance == 0
                    ? 0
                    : pendingMarketEarnings[market].mulDiv(
                        binBalance,
                        marketBalance,
                        Math.Rounding.Up
                    )
            );
    }

    // gelato automate - distribute maker earning to each markets

    /**
     * @notice Resolves the maker earning distribution for a specific token.
     * @param token The address of the settlement token.
     * @return canExec True if the distribution can be executed, otherwise False.
     * @return execPayload The payload for executing the distribution.
     */
    function resolveMakerEarningDistribution(
        address token
    ) external view returns (bool canExec, bytes memory execPayload) {
        if (_makerEarningDistributable(token)) {
            return (true, abi.encodeCall(this.distributeMakerEarning, token));
        }

        return (false, "");
    }

    /**
     * @notice Distributes the maker earning for a token to the each markets.
     * @param token The address of the settlement token.
     */
    function distributeMakerEarning(address token) external {
        (uint256 fee, ) = _getFeeDetails();
        _distributeMakerEarning(token, fee);
    }

    /**
     * @inheritdoc IChromaticVault
     */
    function createMakerEarningDistributionTask(
        address token
    ) external virtual override onlyFactoryOrDao {
        if (makerEarningDistributionTaskIds[token] != bytes32(0))
            revert ExistMarketEarningDistributionTask();

        ModuleData memory moduleData = ModuleData({modules: new Module[](3), args: new bytes[](3)});

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.TIME;
        moduleData.modules[2] = Module.PROXY;
        moduleData.args[0] = _resolverModuleArg(
            abi.encodeCall(this.resolveMakerEarningDistribution, token)
        );
        moduleData.args[1] = _timeModuleArg(block.timestamp, DISTRIBUTION_INTERVAL);
        moduleData.args[2] = _proxyModuleArg();

        makerEarningDistributionTaskIds[token] = automate.createTask(
            address(this),
            abi.encode(this.distributeMakerEarning.selector),
            moduleData,
            ETH
        );
    }

    /**
     * @inheritdoc IChromaticVault
     */
    function cancelMakerEarningDistributionTask(
        address token
    ) external virtual override onlyFactoryOrDao {
        bytes32 taskId = makerEarningDistributionTaskIds[token];
        if (taskId != bytes32(0)) {
            automate.cancelTask(taskId);
            delete makerEarningDistributionTaskIds[token];
        }
    }

    /**
     * @dev Internal function to distribute the maker earning for a token to the each markets.
     * @param token The address of the settlement token.
     * @param fee The keeper fee amount.
     */
    function _distributeMakerEarning(address token, uint256 fee) internal {
        if (!_makerEarningDistributable(token)) return;

        address[] memory markets = factory.getMarketsBySettlmentToken(token);

        uint256 earning = pendingMakerEarnings[token];
        delete pendingMakerEarnings[token];

        uint256 usedFee = fee != 0 ? _transferKeeperFee(token, automate.gelato(), fee, earning) : 0;
        emit TransferKeeperFee(fee, usedFee);

        uint256 remainBalance = makerBalances[token];
        uint256 remainEarning = earning - usedFee;
        for (uint256 i; i < markets.length; ) {
            address market = markets[i];
            uint256 marketBalance = makerMarketBalances[market];
            uint256 marketEarning = remainEarning.mulDiv(marketBalance, remainBalance);

            pendingMarketEarnings[market] += marketEarning;

            remainBalance -= marketBalance;
            remainEarning -= marketEarning;

            emit MarketEarningAccumulated(market, marketEarning);

            unchecked {
                i++;
            }
        }

        emit MakerEarningDistributed(token, earning, usedFee);
    }

    /**
     * @dev Private function to check if the maker earning is distributable for a token.
     * @param token The address of the settlement token.
     * @return True if the maker earning is distributable, False otherwise.
     */
    function _makerEarningDistributable(address token) private view returns (bool) {
        return pendingMakerEarnings[token] >= factory.getEarningDistributionThreshold(token);
    }

    // gelato automate - distribute market earning to each bins

    /**
     * @notice Resolves the market earning distribution for a market.
     * @param market The address of the market.
     * @return canExec True if the distribution can be executed.
     * @return execPayload The payload for executing the distribution.
     */
    function resolveMarketEarningDistribution(
        address market
    ) external view returns (bool canExec, bytes memory execPayload) {
        address token = address(IChromaticMarket(market).settlementToken());
        if (_marketEarningDistributable(market, token)) {
            return (true, abi.encodeCall(this.distributeMarketEarning, market));
        }

        return (false, "");
    }

    /**
     * @notice Distributes the market earning for a market to the each bins.
     * @param market The address of the market.
     */
    function distributeMarketEarning(address market) external {
        (uint256 fee, ) = _getFeeDetails();
        _distributeMarketEarning(market, fee);
    }

    /**
     * @inheritdoc IChromaticVault
     */
    function createMarketEarningDistributionTask(
        address market
    ) external virtual override onlyFactoryOrDao {
        if (marketEarningDistributionTaskIds[market] != bytes32(0))
            revert ExistMarketEarningDistributionTask();

        ModuleData memory moduleData = ModuleData({modules: new Module[](3), args: new bytes[](3)});

        moduleData.modules[0] = Module.RESOLVER;
        moduleData.modules[1] = Module.TIME;
        moduleData.modules[2] = Module.PROXY;
        moduleData.args[0] = _resolverModuleArg(
            abi.encodeCall(this.resolveMarketEarningDistribution, market)
        );
        moduleData.args[1] = _timeModuleArg(block.timestamp, DISTRIBUTION_INTERVAL);
        moduleData.args[2] = _proxyModuleArg();

        marketEarningDistributionTaskIds[market] = automate.createTask(
            address(this),
            abi.encode(this.distributeMarketEarning.selector),
            moduleData,
            ETH
        );
    }

    /**
     * @inheritdoc IChromaticVault
     */
    function cancelMarketEarningDistributionTask(
        address market
    ) external virtual override onlyFactoryOrDao {
        bytes32 taskId = marketEarningDistributionTaskIds[market];
        if (taskId != bytes32(0)) {
            automate.cancelTask(taskId);
            delete marketEarningDistributionTaskIds[market];
        }
    }

    /**
     * @dev Internal function to distribute the market earning for a market to the each bins.
     * @param market The address of the market.
     * @param fee The fee amount.
     */
    function _distributeMarketEarning(address market, uint256 fee) internal {
        address token = address(IChromaticMarket(market).settlementToken());
        if (!_marketEarningDistributable(market, token)) return;

        uint256 earning = pendingMarketEarnings[market];
        delete pendingMarketEarnings[market];

        uint256 usedFee = fee != 0 ? _transferKeeperFee(token, automate.gelato(), fee, earning) : 0;
        emit TransferKeeperFee(market, fee, usedFee);

        uint256 remainEarning = earning - usedFee;

        uint256 balance = makerMarketBalances[market];
        makerMarketBalances[market] += remainEarning;
        makerBalances[token] += remainEarning;

        IChromaticMarket(market).distributeEarningToBins(remainEarning, balance);

        emit MarketEarningDistributed(market, earning, usedFee, balance);
    }

    /**
     * @dev Private function to check if the market earning is distributable for a market.
     * @param market The address of the market.
     * @param token The address of the settlement token.
     * @return True if the market earning is distributable, False otherwise.
     */
    function _marketEarningDistributable(
        address market,
        address token
    ) private view returns (bool) {
        return pendingMarketEarnings[market] >= factory.getEarningDistributionThreshold(token);
    }

    function _resolverModuleArg(bytes memory _resolverData) internal view returns (bytes memory) {
        return abi.encode(address(this), _resolverData);
    }

    function _timeModuleArg(
        uint256 _startTime,
        uint256 _interval
    ) internal pure returns (bytes memory) {
        return abi.encode(uint128(_startTime), uint128(_interval));
    }

    function _proxyModuleArg() internal pure returns (bytes memory) {
        return bytes("");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";
import {ERC1155Supply, ERC1155} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {BPS} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";

/**
 * @title CLBToken
 * @dev CLBToken is an ERC1155 token contract that represents Liquidity Bin tokens.
 *      CLBToken allows minting and burning of tokens by the Chromatic Market contract.
 */
contract CLBToken is ERC1155Supply, ICLBToken {
    using Strings for uint256;
    using Strings for uint128;
    using SafeCast for uint256;
    using SignedMath for int256;

    IChromaticMarket public immutable market;

    error OnlyAccessableByMarket();

    /**
     * @dev Modifier to restrict access to the Chromatic Market contract.
     *      Only the market contract is allowed to call functions with this modifier.
     *      Reverts with an error if the caller is not the market contract.
     */
    modifier onlyMarket() {
        if (address(market) != (msg.sender)) revert OnlyAccessableByMarket();
        _;
    }

    /**
     * @dev Initializes the CLBToken contract.
     *      The constructor sets the market contract address as the caller.
     */
    constructor() ERC1155("") {
        market = IChromaticMarket(msg.sender);
    }

    /**
     * @inheritdoc ICLBToken
     */
    function decimals() public view override returns (uint8) {
        return market.settlementToken().decimals();
    }

    /**
     * @inheritdoc ICLBToken
     */
    function totalSupply(
        uint256 id
    ) public view virtual override(ERC1155Supply, ICLBToken) returns (uint256) {
        return super.totalSupply(id);
    }

    /**
     * @inheritdoc ICLBToken
     */
    function totalSupplyBatch(
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        uint256[] memory supplies = new uint256[](ids.length);
        for (uint256 i; i < ids.length; ) {
            supplies[i] = super.totalSupply(ids[i]);

            unchecked {
                i++;
            }
        }
        return supplies;
    }

    /**
     * @inheritdoc ICLBToken
     * @dev This function can only be called by the Chromatic Market contract.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external override onlyMarket {
        _mint(to, id, amount, data);
    }

    /**
     * @inheritdoc ICLBToken
     * @dev This function can only be called by the Chromatic Market contract.
     */
    function burn(address from, uint256 id, uint256 amount) external override onlyMarket {
        _burn(from, id, amount);
    }

    /**
     * @inheritdoc ICLBToken
     */
    function name(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked("CLB - ", description(id)));
    }

    /**
     * @inheritdoc ICLBToken
     */
    function description(uint256 id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _tokenSymbol(),
                    " - ",
                    _indexName(),
                    " ",
                    _formattedFeeRate(decodeId(id))
                )
            );
    }

    /**
     * @inheritdoc ICLBToken
     */
    function image(uint256 id) public view override returns (string memory) {
        int16 tradingFeeRate = decodeId(id);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(_svg(tradingFeeRate, _tokenSymbol(), _indexName()))
                )
            );
    }

    /**
     * @inheritdoc IERC1155MetadataURI
     */
    function uri(
        uint256 id
    ) public view override(ERC1155, IERC1155MetadataURI) returns (string memory) {
        bytes memory metadata = abi.encodePacked(
            '{"name": "',
            name(id),
            '", "description": "',
            description(id),
            '", "decimals": "',
            uint256(decimals()).toString(),
            '", "image":"',
            image(id),
            '"',
            "}"
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    /**
     * @dev Encodes a trading fee rate into a token ID.
     * @param tradingFeeRate The trading fee rate to encode.
     * @return id The encoded token ID.
     */
    function encodeId(int16 tradingFeeRate) internal pure returns (uint256 id) {
        id = CLBTokenLib.encodeId(tradingFeeRate);
    }

    /**
     * @dev Decodes a token ID into a trading fee rate.
     * @param id The token ID to decode.
     * @return tradingFeeRate The decoded trading fee rate.
     */
    function decodeId(uint256 id) internal pure returns (int16 tradingFeeRate) {
        tradingFeeRate = CLBTokenLib.decodeId(id);
    }

    /**
     * @dev Retrieves the symbol of the settlement token.
     * @return The symbol of the settlement token.
     */
    function _tokenSymbol() private view returns (string memory) {
        return market.settlementToken().symbol();
    }

    /**
     * @dev Retrieves the name of the index.
     * @return The name of the index.
     */
    function _indexName() private view returns (string memory) {
        return market.oracleProvider().description();
    }

    /**
     * @dev Formats a fee rate into a human-readable string.
     * @param feeRate The fee rate to format.
     * @return The formatted fee rate as a bytes array.
     */
    function _formattedFeeRate(int16 feeRate) private pure returns (bytes memory) {
        uint256 absFeeRate = uint16(feeRate < 0 ? -(feeRate) : feeRate);

        uint256 pct = BPS / 100;
        uint256 integerPart = absFeeRate / pct;
        uint256 fractionalPart = absFeeRate % pct;

        bytes memory fraction;
        if (fractionalPart != 0) {
            uint256 fractionalPart1 = fractionalPart / (pct / 10);
            uint256 fractionalPart2 = fractionalPart % (pct / 10);

            fraction = bytes(".");
            if (fractionalPart2 == 0) {
                fraction = abi.encodePacked(fraction, fractionalPart1.toString());
            } else {
                fraction = abi.encodePacked(
                    fraction,
                    fractionalPart1.toString(),
                    fractionalPart2.toString()
                );
            }
        }

        return abi.encodePacked(feeRate < 0 ? "-" : "+", integerPart.toString(), fraction, "%");
    }

    uint256 private constant _W = 480;
    uint256 private constant _H = 480;
    string private constant _WS = "480";
    string private constant _HS = "480";
    uint256 private constant _BARS = 9;

    function _svg(
        int16 feeRate,
        string memory symbol,
        string memory index
    ) private pure returns (bytes memory) {
        bytes memory formattedFeeRate = _formattedFeeRate(feeRate);
        string memory color = _color(feeRate);
        bool long = feeRate > 0;

        bytes memory text = abi.encodePacked(
            '<text class="st13 st14" font-size="64" transform="translate(440 216.852)" text-anchor="end">',
            formattedFeeRate,
            "</text>"
            '<text class="st13 st16" font-size="28" transform="translate(440 64.036)" text-anchor="end">',
            symbol,
            "</text>"
            '<path d="M104.38 40 80.74 51.59V40L63.91 52.17v47.66L80.74 112v-11.59L104.38 112zm-43.34 0L50.87 52.17v47.66L61.04 112zm-16.42 0L40 52.17v47.66L44.62 112z" class="st13" />'
            '<text class="st13 st14 st18" transform="translate(440 109.356)" text-anchor="end">',
            index,
            " Market</text>"
            '<path fill="none" stroke="#fff" stroke-miterlimit="10" d="M440 140H40" opacity=".5" />'
            '<text class="st13 st14 st18" transform="translate(40 438.578)">CLB</text>'
            '<text class="st13 st16" font-size="22" transform="translate(107.664 438.578)">Chromatic Liquidity Bin Token</text>'
            '<text class="st13 st16" font-size="16" transform="translate(54.907 390.284)">ERC-1155</text>'
            '<path fill="none" stroke="#fff" stroke-miterlimit="10" d="M132.27 399.77h-84c-4.42 0-8-3.58-8-8v-14c0-4.42 3.58-8 8-8h84c4.42 0 8 3.58 8 8v14c0 4.42-3.58 8-8 8z" />'
        );

        return
            abi.encodePacked(
                '<?xml version="1.0" encoding="utf-8"?>'
                '<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" x="0" y="0" version="1.1" viewBox="0 0 ',
                _WS,
                " ",
                _HS,
                '">'
                "<style>"
                "  .st13 {"
                "    fill: #fff"
                "  }"
                "  .st14 {"
                '    font-family: "NotoSans-Bold";'
                "  }"
                "  .st16 {"
                '    font-family: "NotoSans-Regular";'
                "  }"
                "  .st18 {"
                "    font-size: 32px"
                "  }"
                "</style>",
                _background(long),
                _bars(long, color, _activeBar(feeRate)),
                text,
                "</svg>"
            );
    }

    function _background(bool long) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<linearGradient id="bg" x1="',
                long ? "0" : _WS,
                '" x2="',
                long ? _WS : "0",
                '" y1="',
                _HS,
                '" y2="0" gradientUnits="userSpaceOnUse">',
                long
                    ? '<stop offset="0" />'
                    '<stop offset=".3" stop-color="#010302" />'
                    '<stop offset=".5" stop-color="#040b07" />'
                    '<stop offset=".6" stop-color="#0a1910" />'
                    '<stop offset=".7" stop-color="#132e1d" />'
                    '<stop offset=".8" stop-color="#1d482e" />'
                    '<stop offset=".9" stop-color="#2b6843" />'
                    '<stop offset="1" stop-color="#358153" />'
                    : '<stop offset="0" style="stop-color:#000" />'
                    '<stop offset=".3" style="stop-color:#030101" />'
                    '<stop offset=".4" style="stop-color:#0b0605" />'
                    '<stop offset=".6" style="stop-color:#190f0b" />'
                    '<stop offset=".7" style="stop-color:#2e1a13" />'
                    '<stop offset=".8" style="stop-color:#482a1f" />'
                    '<stop offset=".9" style="stop-color:#683c2c" />'
                    '<stop offset="1" style="stop-color:#8e523c" />',
                "</linearGradient>"
                '<path fill="url(#bg)" d="M0 0h',
                _WS,
                "v",
                _HS,
                'H0z" />'
            );
    }

    function _activeBar(int16 feeRate) private pure returns (uint256) {
        uint256 absFeeRate = uint16(feeRate < 0 ? -(feeRate) : feeRate);

        if (absFeeRate >= BPS / 10) {
            return (absFeeRate / (BPS / 10 / 2)) - 2;
        } else if (absFeeRate >= BPS / 100) {
            return (absFeeRate / (BPS / 100)) - 1;
        } else if (absFeeRate >= BPS / 1000) {
            return (absFeeRate / (BPS / 1000)) - 1;
        } else if (absFeeRate >= BPS / 10000) {
            return (absFeeRate / (BPS / 10000)) - 1;
        }
        return 0;
    }

    function _bars(
        bool long,
        string memory color,
        uint256 activeBar
    ) private pure returns (bytes memory bars) {
        for (uint256 i; i < _BARS; ) {
            bars = abi.encodePacked(bars, _bar(i, long, color, i == activeBar));

            unchecked {
                i++;
            }
        }
    }

    function _bar(
        uint256 barIndex,
        bool long,
        string memory color,
        bool active
    ) private pure returns (bytes memory) {
        (uint256 pos, uint256 width, uint256 height, uint256 hDelta) = _barAttributes(
            barIndex,
            long
        );

        string memory gX = _gradientX(barIndex, long);
        string memory gY = (_H - height).toString();

        bytes memory stop = abi.encodePacked(
            '<stop offset="0" stop-color="',
            color,
            '" stop-opacity="0"/>'
            '<stop offset="1" stop-color="',
            color,
            '"/>'
        );
        bytes memory path = _path(barIndex, long, pos, width, height, hDelta);
        bytes memory bar = abi.encodePacked(
            '<linearGradient id="bar',
            barIndex.toString(),
            '" x1="',
            gX,
            '" x2="',
            gX,
            '" y1="',
            gY,
            '" y2="',
            _HS,
            '" gradientUnits="userSpaceOnUse">',
            stop,
            "</linearGradient>",
            path
        );

        if (active) {
            bytes memory edge = _edge(long, pos, width, height);
            return abi.encodePacked(bar, bar, bar, edge);
        }
        return bar;
    }

    function _edge(
        bool long,
        uint256 pos,
        uint256 width,
        uint256 height
    ) private pure returns (bytes memory) {
        string memory _epos = (long ? pos + width : pos - width).toString();

        bytes memory path = abi.encodePacked(
            '<path fill="url(#edge)" d="M',
            _epos,
            " ",
            _HS,
            "h",
            long ? "-" : "",
            "2v-",
            height.toString(),
            "H",
            _epos,
            'z"/>'
        );
        return
            abi.encodePacked(
                '<linearGradient id="edge" x1="',
                _epos,
                '" x2="',
                _epos,
                '" y1="',
                _HS,
                '" y2="',
                (_H - height).toString(),
                '" gradientUnits="userSpaceOnUse">'
                '<stop offset="0" stop-color="#fff" stop-opacity="0"/>'
                '<stop offset=".5" stop-color="#fff" stop-opacity=".5"/>'
                '<stop offset="1" stop-color="#fff" stop-opacity="0"/>'
                "</linearGradient>",
                path
            );
    }

    function _path(
        uint256 barIndex,
        bool long,
        uint256 pos,
        uint256 width,
        uint256 height,
        uint256 hDelta
    ) private pure returns (bytes memory) {
        string memory _w = width.toString();
        bytes memory _h = abi.encodePacked("h", long ? "" : "-", _w);
        bytes memory _l = abi.encodePacked("l", long ? "-" : "", _w, " ", hDelta.toString());
        return
            abi.encodePacked(
                '<path fill="url(#bar',
                barIndex.toString(),
                ')" d="M',
                pos.toString(),
                " ",
                _HS,
                _h,
                "v-",
                height.toString(),
                _l,
                'z"/>'
            );
    }

    function _barAttributes(
        uint256 barIndex,
        bool long
    ) private pure returns (uint256 pos, uint256 width, uint256 height, uint256 hDelta) {
        uint256[_BARS] memory widths = [uint256(44), 45, 48, 51, 53, 55, 58, 62, 64];
        uint256[_BARS] memory heights = [uint256(480), 415, 309, 240, 185, 144, 111, 86, 67];
        uint256[_BARS] memory hDeltas = [uint256(33), 27, 19, 14, 10, 8, 5, 4, 3];

        width = widths[barIndex];
        height = heights[barIndex];
        hDelta = hDeltas[barIndex];
        pos = long ? 0 : _W;
        for (uint256 i; i < barIndex; ) {
            pos = long ? pos + widths[i] : pos - widths[i];

            unchecked {
                i++;
            }
        }
    }

    function _gradientX(uint256 barIndex, bool long) private pure returns (string memory) {
        string[_BARS] memory longXs = [
            "-1778",
            "-1733.4",
            "-1686.6",
            "-1637.4",
            "-1585.7",
            "-1531.5",
            "-1474.6",
            "-1414.8",
            "-1352"
        ];
        string[_BARS] memory shortXs = [
            "-12373.4",
            "-12328.8",
            "-12281.9",
            "-12232.8",
            "-12181.1",
            "-12126.9",
            "-12069.9",
            "-12010.1",
            "-11947.3"
        ];

        return long ? longXs[barIndex] : shortXs[barIndex];
    }

    function _color(int16 feeRate) private pure returns (string memory) {
        bool long = feeRate > 0;
        uint256 absFeeRate = uint16(feeRate < 0 ? -(feeRate) : feeRate);

        if (absFeeRate >= BPS / 10) {
            // feeRate >= 10%  or feeRate <= -10%
            return long ? "#FFCE94" : "#A0DC50";
        } else if (absFeeRate >= BPS / 100) {
            // 10% > feeRate >= 1% or -1% >= feeRate > -10%
            return long ? "#FFAB5E" : "#82E664";
        } else if (absFeeRate >= BPS / 1000) {
            // 1% > feeRate >= 0.1% or -0.1% >= feeRate > -1%
            return long ? "#FF966E" : "#5ADC8C";
        } else if (absFeeRate >= BPS / 10000) {
            // 0.1% > feeRate >= 0.01% or -0.01% >= feeRate > -0.1%
            return long ? "#FE8264" : "#3CD2AA";
        }
        // feeRate == 0%
        return "#000000";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "@chromatic-protocol/contracts/core/interfaces/IDiamondCut.sol";
import {DiamondStorage, DiamondStorageLib} from "@chromatic-protocol/contracts/core/libraries/DiamondStorage.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

abstract contract DiamondCutFacetBase is IDiamondCut {
    function _diamondCut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _calldata
    ) internal {
        DiamondStorage storage ds = DiamondStorageLib.diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _cut.length; ) {
            (selectorCount, selectorSlot) = DiamondStorageLib.addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _cut[facetIndex].facetAddress,
                _cut[facetIndex].action,
                _cut[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_cut, _init, _calldata);
        DiamondStorageLib.initializeDiamondCut(_init, _calldata);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {DiamondCutFacetBase} from "@chromatic-protocol/contracts/core/facets/DiamondCutFacetBase.sol";
import {MarketStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";

contract MarketDiamondCutFacet is DiamondCutFacetBase {
    error OnlyAccessableByFactoryOrDao();

    /**
     * @dev Modifier to restrict access to only the factory or the DAO.
     */
    modifier onlyFactoryOrDao() {
        IChromaticMarketFactory factory = MarketStorageLib.marketStorage().factory;
        if (msg.sender != address(factory) && msg.sender != factory.dao())
            revert OnlyAccessableByFactoryOrDao();
        _;
    }

    /**
     * @notice Add/replace/remove any number of functions and optionally execute
     *         a function with delegatecall
     * @param _cut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     *                  _calldata is executed with delegatecall on _init
     */
    function diamondCut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _calldata
    ) external override onlyFactoryOrDao {
        _diamondCut(_cut, _init, _calldata);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {MarketStorage, MarketStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";

abstract contract MarketFacetBase {
    error OnlyAccessableByDao();
    error OnlyAccessableByLiquidator();
    error OnlyAccessableByVault();

    /**
     * @dev Modifier to restrict access to only the DAO.
     */
    modifier onlyDao() {
        if (msg.sender != MarketStorageLib.marketStorage().factory.dao())
            revert OnlyAccessableByDao();
        _;
    }

    /**
     * @dev Modifier to restrict access to only the liquidator contract.
     */
    modifier onlyLiquidator() {
        if (msg.sender != address(MarketStorageLib.marketStorage().liquidator))
            revert OnlyAccessableByLiquidator();
        _;
    }

    /**
     * @dev Modifier to restrict a function to be called only by the vault contract.
     */
    modifier onlyVault() {
        if (msg.sender != address(MarketStorageLib.marketStorage().vault))
            revert OnlyAccessableByVault();
        _;
    }

    /**
     * @dev Creates a new LP context.
     * @return The LP context.
     */
    function newLpContext(MarketStorage storage ms) internal view returns (LpContext memory) {
        IOracleProvider.OracleVersion memory _currentVersionCache;
        return
            LpContext({
                oracleProvider: ms.oracleProvider,
                interestCalculator: ms.factory,
                vault: ms.vault,
                clbToken: ms.clbToken,
                market: address(this),
                settlementToken: address(ms.settlementToken),
                tokenPrecision: 10 ** ms.settlementToken.decimals(),
                _currentVersionCache: _currentVersionCache
            });
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IMarketLiquidate} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidate.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {MarketStorage, MarketStorageLib, PositionStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {MarketTradeFacetBase} from "@chromatic-protocol/contracts/core/facets/market/MarketTradeFacetBase.sol";

/**
 * @title MarketLiquidateFacet
 * @dev A contract that manages liquidations.
 */
contract MarketLiquidateFacet is MarketTradeFacetBase, IMarketLiquidate, ReentrancyGuard {
    using SafeCast for uint256;
    using SignedMath for int256;

    error AlreadyClosedPosition();
    error NotClaimablePosition();

    /**
     * @inheritdoc IMarketLiquidate
     */
    function claimPosition(
        uint256 positionId,
        address keeper,
        uint256 keeperFee // native token amount
    ) external override nonReentrant onlyLiquidator {
        Position memory position = _getPosition(PositionStorageLib.positionStorage(), positionId);

        MarketStorage storage ms = MarketStorageLib.marketStorage();

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        if (!ctx.isPastVersion(position.closeVersion)) revert NotClaimablePosition();

        uint256 usedKeeperFee = keeperFee != 0
            ? ctx.vault.transferKeeperFee(
                ctx.settlementToken,
                keeper,
                keeperFee,
                position.takerMargin
            )
            : 0;
        int256 pnl = position.pnl(ctx);
        uint256 interest = _claimPosition(
            ctx,
            position,
            pnl,
            usedKeeperFee,
            position.owner,
            bytes("")
        );
        emit ClaimPositionByKeeper(position.owner, pnl, interest, usedKeeperFee, position);

        ms.liquidator.cancelClaimPositionTask(position.id);
    }

    /**
     * @inheritdoc IMarketLiquidate
     */
    function liquidate(
        uint256 positionId,
        address keeper,
        uint256 keeperFee // native token amount
    ) external override nonReentrant onlyLiquidator {
        Position memory position = _getPosition(PositionStorageLib.positionStorage(), positionId);
        if (position.closeVersion != 0) revert AlreadyClosedPosition();

        MarketStorage storage ms = MarketStorageLib.marketStorage();

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        (bool _liquidate, int256 _pnl) = _checkLiquidation(ctx, position);
        if (!_liquidate) return;

        uint256 usedKeeperFee = keeperFee != 0
            ? ctx.vault.transferKeeperFee(
                ctx.settlementToken,
                keeper,
                keeperFee,
                position.takerMargin
            )
            : 0;
        uint256 interest = _claimPosition(
            ctx,
            position,
            _pnl,
            usedKeeperFee,
            position.owner,
            bytes("")
        );

        ms.liquidator.cancelLiquidationTask(positionId);

        emit Liquidate(position.owner, _pnl, interest, usedKeeperFee, position);
    }

    /**
     * @inheritdoc IMarketLiquidate
     */
    function checkLiquidation(uint256 positionId) external view override returns (bool _liquidate) {
        Position memory position = PositionStorageLib.positionStorage().getPosition(positionId);
        if (position.id == 0) return false;

        (_liquidate, ) = _checkLiquidation(
            newLpContext(MarketStorageLib.marketStorage()),
            position
        );
    }

    /**
     * @dev Internal function for checking if a position should be liquidated.
     * @param ctx The LpContext containing the current oracle version and synchronization information.
     * @param position The Position object representing the position to be checked.
     * @return _liquidate A boolean indicating whether the position should be liquidated.
     * @return _pnl The profit or loss amount of the position.
     */
    function _checkLiquidation(
        LpContext memory ctx,
        Position memory position
    ) internal view returns (bool _liquidate, int256 _pnl) {
        uint256 interest = ctx.calculateInterest(
            position.makerMargin(),
            position.openTimestamp,
            block.timestamp
        );

        _pnl =
            PositionUtil.pnl(
                position.leveragedQty(ctx),
                position.entryPrice(ctx),
                PositionUtil.oraclePrice(ctx.currentOracleVersion())
            ) -
            interest.toInt256();

        uint256 absPnl = _pnl.abs();
        if (_pnl > 0) {
            // whether profit stop (taker side)
            _liquidate = absPnl >= position.makerMargin();
        } else {
            // whether loss cut (taker side)
            _liquidate = absPnl >= position.takerMargin;
        }
    }

    /**
     * @inheritdoc IMarketLiquidate
     */
    function checkClaimPosition(uint256 positionId) external view override returns (bool) {
        Position memory position = PositionStorageLib.positionStorage().getPosition(positionId);
        if (position.id == 0) return false;

        return newLpContext(MarketStorageLib.marketStorage()).isPastVersion(position.closeVersion);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IVault} from "@chromatic-protocol/contracts/core/interfaces/vault/IVault.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {IChromaticLiquidityCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticLiquidityCallback.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {LpReceipt, LpAction} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {LiquidityPool} from "@chromatic-protocol/contracts/core/libraries/liquidity/LiquidityPool.sol";
import {MarketStorage, MarketStorageLib, LpReceiptStorage, LpReceiptStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {MarketFacetBase} from "@chromatic-protocol/contracts/core/facets/market/MarketFacetBase.sol";

/**
 * @title MarketLiquidityFacet
 * @dev Contract for managing liquidity in a market.
 */
contract MarketLiquidityFacet is
    MarketFacetBase,
    IMarketLiquidity,
    IERC1155Receiver,
    ReentrancyGuard
{
    using Math for uint256;

    error TooSmallAmount();
    error NotExistLpReceipt();
    error NotClaimableLpReceipt();
    error NotWithdrawableLpReceipt();
    error InvalidLpReceiptAction();
    error InvalidTransferedTokenAmount();

    /**
     * @inheritdoc IMarketLiquidity
     */
    function addLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external override nonReentrant returns (LpReceipt memory receipt) {
        MarketStorage storage ms = MarketStorageLib.marketStorage();

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        IERC20Metadata settlementToken = IERC20Metadata(ctx.settlementToken);
        IVault vault = ctx.vault;

        uint256 balanceBefore = settlementToken.balanceOf(address(vault));
        IChromaticLiquidityCallback(msg.sender).addLiquidityCallback(
            address(settlementToken),
            address(vault),
            data
        );

        uint256 amount = settlementToken.balanceOf(address(vault)) - balanceBefore;

        vault.onAddLiquidity(ctx.settlementToken, amount);

        receipt = _addLiquidity(ctx, ms.liquidityPool, recipient, tradingFeeRate, amount);

        emit AddLiquidity(receipt);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function addLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata amounts,
        bytes calldata data
    ) external override nonReentrant returns (LpReceipt[] memory receipts) {
        require(tradingFeeRates.length == amounts.length);

        MarketStorage storage ms = MarketStorageLib.marketStorage();
        LiquidityPool storage liquidityPool = ms.liquidityPool;

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        uint256 totalAmount = _checkTransferedAmount(ctx, amounts, data);

        ctx.vault.onAddLiquidity(ctx.settlementToken, totalAmount);

        receipts = new LpReceipt[](tradingFeeRates.length);
        for (uint256 i; i < tradingFeeRates.length; ) {
            receipts[i] = _addLiquidity(
                ctx,
                liquidityPool,
                recipient,
                tradingFeeRates[i],
                amounts[i]
            );

            unchecked {
                i++;
            }
        }

        emit AddLiquidityBatch(receipts);
    }

    function _checkTransferedAmount(
        LpContext memory ctx,
        uint256[] calldata amounts,
        bytes calldata data
    ) private returns (uint256 totalAmount) {
        for (uint256 i; i < amounts.length; ) {
            totalAmount += amounts[i];

            unchecked {
                i++;
            }
        }

        IERC20Metadata settlementToken = IERC20Metadata(ctx.settlementToken);
        address vault = address(ctx.vault);

        uint256 balanceBefore = settlementToken.balanceOf(vault);
        IChromaticLiquidityCallback(msg.sender).addLiquidityBatchCallback(
            address(settlementToken),
            vault,
            data
        );

        uint256 transferedAmount = settlementToken.balanceOf(vault) - balanceBefore;
        if (transferedAmount != totalAmount) revert InvalidTransferedTokenAmount();
    }

    function _addLiquidity(
        LpContext memory ctx,
        LiquidityPool storage liquidityPool,
        address recipient,
        int16 tradingFeeRate,
        uint256 amount
    ) private returns (LpReceipt memory receipt) {
        liquidityPool.acceptAddLiquidity(ctx, tradingFeeRate, amount);

        receipt = _newLpReceipt(ctx, LpAction.ADD_LIQUIDITY, amount, recipient, tradingFeeRate);
        LpReceiptStorageLib.lpReceiptStorage().setReceipt(receipt);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function claimLiquidity(uint256 receiptId, bytes calldata data) external override nonReentrant {
        LpReceiptStorage storage ls = LpReceiptStorageLib.lpReceiptStorage();
        MarketStorage storage ms = MarketStorageLib.marketStorage();

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        (LpReceipt memory receipt, uint256 clbTokenAmount) = _claimLiquidity(
            ctx,
            ls,
            ms.liquidityPool,
            receiptId
        );

        IChromaticLiquidityCallback(msg.sender).claimLiquidityCallback(receiptId, data);
        ls.deleteReceipt(receiptId);

        emit ClaimLiquidity(receipt, clbTokenAmount);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function claimLiquidityBatch(
        uint256[] calldata receiptIds,
        bytes calldata data
    ) external override nonReentrant {
        LpReceiptStorage storage ls = LpReceiptStorageLib.lpReceiptStorage();
        MarketStorage storage ms = MarketStorageLib.marketStorage();
        LiquidityPool storage liquidityPool = ms.liquidityPool;

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        LpReceipt[] memory _receipts = new LpReceipt[](receiptIds.length);
        uint256[] memory _clbTokenAmounts = new uint256[](receiptIds.length);

        for (uint256 i; i < receiptIds.length; ) {
            (_receipts[i], _clbTokenAmounts[i]) = _claimLiquidity(
                ctx,
                ls,
                liquidityPool,
                receiptIds[i]
            );

            unchecked {
                i++;
            }
        }

        IChromaticLiquidityCallback(msg.sender).claimLiquidityBatchCallback(receiptIds, data);
        ls.deleteReceipts(receiptIds);

        emit ClaimLiquidityBatch(_receipts, _clbTokenAmounts);
    }

    function _claimLiquidity(
        LpContext memory ctx,
        LpReceiptStorage storage ls,
        LiquidityPool storage liquidityPool,
        uint256 receiptId
    ) private returns (LpReceipt memory receipt, uint256 clbTokenAmount) {
        receipt = _getLpReceipt(ls, receiptId);
        if (receipt.action != LpAction.ADD_LIQUIDITY) revert InvalidLpReceiptAction();
        if (!ctx.isPastVersion(receipt.oracleVersion)) revert NotClaimableLpReceipt();

        clbTokenAmount = liquidityPool.acceptClaimLiquidity(
            ctx,
            receipt.tradingFeeRate,
            receipt.amount,
            receipt.oracleVersion
        );
        ctx.clbToken.safeTransferFrom(
            address(this),
            receipt.recipient,
            receipt.clbTokenId(),
            clbTokenAmount,
            bytes("")
        );
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function removeLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external override nonReentrant returns (LpReceipt memory receipt) {
        MarketStorage storage ms = MarketStorageLib.marketStorage();

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        uint256 clbTokenId = CLBTokenLib.encodeId(tradingFeeRate);
        uint256 balanceBefore = ctx.clbToken.balanceOf(address(this), clbTokenId);
        IChromaticLiquidityCallback(msg.sender).removeLiquidityCallback(
            address(ctx.clbToken),
            clbTokenId,
            data
        );

        uint256 clbTokenAmount = ctx.clbToken.balanceOf(address(this), clbTokenId) - balanceBefore;
        if (clbTokenAmount == 0) revert TooSmallAmount();

        receipt = _removeLiquidity(
            ctx,
            ms.liquidityPool,
            recipient,
            tradingFeeRate,
            clbTokenAmount
        );

        emit RemoveLiquidity(receipt);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function removeLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata clbTokenAmounts,
        bytes calldata data
    ) external override nonReentrant returns (LpReceipt[] memory receipts) {
        require(tradingFeeRates.length == clbTokenAmounts.length);

        MarketStorage storage ms = MarketStorageLib.marketStorage();
        LiquidityPool storage liquidityPool = ms.liquidityPool;

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        _checkTransferedCLBTokenAmount(ctx, tradingFeeRates, clbTokenAmounts, data);

        receipts = new LpReceipt[](tradingFeeRates.length);
        for (uint256 i; i < tradingFeeRates.length; ) {
            receipts[i] = _removeLiquidity(
                ctx,
                liquidityPool,
                recipient,
                tradingFeeRates[i],
                clbTokenAmounts[i]
            );

            unchecked {
                i++;
            }
        }

        emit RemoveLiquidityBatch(receipts);
    }

    function _checkTransferedCLBTokenAmount(
        LpContext memory ctx,
        int16[] calldata tradingFeeRates,
        uint256[] calldata clbTokenAmounts,
        bytes calldata data
    ) private {
        address[] memory _accounts = new address[](tradingFeeRates.length);
        uint256[] memory _clbTokenIds = new uint256[](tradingFeeRates.length);
        for (uint256 i; i < tradingFeeRates.length; ) {
            _accounts[i] = address(this);
            _clbTokenIds[i] = CLBTokenLib.encodeId(tradingFeeRates[i]);

            unchecked {
                i++;
            }
        }

        uint256[] memory balancesBefore = ctx.clbToken.balanceOfBatch(_accounts, _clbTokenIds);
        IChromaticLiquidityCallback(msg.sender).removeLiquidityBatchCallback(
            address(ctx.clbToken),
            _clbTokenIds,
            data
        );

        uint256[] memory balancesAfter = ctx.clbToken.balanceOfBatch(_accounts, _clbTokenIds);
        for (uint256 i; i < tradingFeeRates.length; ) {
            if (clbTokenAmounts[i] != balancesAfter[i] - balancesBefore[i])
                revert InvalidTransferedTokenAmount();

            unchecked {
                i++;
            }
        }
    }

    function _removeLiquidity(
        LpContext memory ctx,
        LiquidityPool storage liquidityPool,
        address recipient,
        int16 tradingFeeRate,
        uint256 clbTokenAmount
    ) private returns (LpReceipt memory receipt) {
        liquidityPool.acceptRemoveLiquidity(ctx, tradingFeeRate, clbTokenAmount);

        receipt = _newLpReceipt(
            ctx,
            LpAction.REMOVE_LIQUIDITY,
            clbTokenAmount,
            recipient,
            tradingFeeRate
        );
        LpReceiptStorageLib.lpReceiptStorage().setReceipt(receipt);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function withdrawLiquidity(
        uint256 receiptId,
        bytes calldata data
    ) external override nonReentrant {
        LpReceiptStorage storage ls = LpReceiptStorageLib.lpReceiptStorage();
        MarketStorage storage ms = MarketStorageLib.marketStorage();

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        (
            LpReceipt memory receipt,
            uint256 amount,
            uint256 burnedCLBTokenAmount
        ) = _withdrawLiquidity(ctx, ls, ms.liquidityPool, receiptId);

        IChromaticLiquidityCallback(msg.sender).withdrawLiquidityCallback(receiptId, data);
        ls.deleteReceipt(receiptId);

        emit WithdrawLiquidity(receipt, amount, burnedCLBTokenAmount);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function withdrawLiquidityBatch(
        uint256[] calldata receiptIds,
        bytes calldata data
    ) external override nonReentrant {
        LpReceiptStorage storage ls = LpReceiptStorageLib.lpReceiptStorage();
        MarketStorage storage ms = MarketStorageLib.marketStorage();
        LiquidityPool storage liquidityPool = ms.liquidityPool;

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        LpReceipt[] memory _receipts = new LpReceipt[](receiptIds.length);
        uint256[] memory _amounts = new uint256[](receiptIds.length);
        uint256[] memory _burnedCLBTokenAmounts = new uint256[](receiptIds.length);

        for (uint256 i; i < receiptIds.length; ) {
            (_receipts[i], _amounts[i], _burnedCLBTokenAmounts[i]) = _withdrawLiquidity(
                ctx,
                ls,
                liquidityPool,
                receiptIds[i]
            );

            unchecked {
                i++;
            }
        }

        IChromaticLiquidityCallback(msg.sender).withdrawLiquidityBatchCallback(receiptIds, data);
        ls.deleteReceipts(receiptIds);

        emit WithdrawLiquidityBatch(_receipts, _amounts, _burnedCLBTokenAmounts);
    }

    function _withdrawLiquidity(
        LpContext memory ctx,
        LpReceiptStorage storage ls,
        LiquidityPool storage liquidityPool,
        uint256 receiptId
    ) private returns (LpReceipt memory receipt, uint256 amount, uint256 burnedCLBTokenAmount) {
        receipt = _getLpReceipt(ls, receiptId);
        if (receipt.action != LpAction.REMOVE_LIQUIDITY) revert InvalidLpReceiptAction();
        if (!ctx.isPastVersion(receipt.oracleVersion)) revert NotWithdrawableLpReceipt();

        address recipient = receipt.recipient;
        uint256 clbTokenAmount = receipt.amount;

        (amount, burnedCLBTokenAmount) = liquidityPool.acceptWithdrawLiquidity(
            ctx,
            receipt.tradingFeeRate,
            clbTokenAmount,
            receipt.oracleVersion
        );

        ctx.clbToken.safeTransferFrom(
            address(this),
            recipient,
            receipt.clbTokenId(),
            clbTokenAmount - burnedCLBTokenAmount,
            bytes("")
        );
        ctx.vault.onWithdrawLiquidity(ctx.settlementToken, recipient, amount);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function getBinLiquidity(int16 tradingFeeRate) external view override returns (uint256 amount) {
        amount = MarketStorageLib.marketStorage().liquidityPool.getBinLiquidity(tradingFeeRate);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function getBinFreeLiquidity(
        int16 tradingFeeRate
    ) external view override returns (uint256 amount) {
        amount = MarketStorageLib.marketStorage().liquidityPool.getBinFreeLiquidity(tradingFeeRate);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function distributeEarningToBins(uint256 earning, uint256 marketBalance) external onlyVault {
        MarketStorageLib.marketStorage().liquidityPool.distributeEarning(earning, marketBalance);
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function getBinValues(
        int16[] memory tradingFeeRates
    ) external view override returns (uint256[] memory) {
        MarketStorage storage ms = MarketStorageLib.marketStorage();
        LiquidityPool storage liquidityPool = ms.liquidityPool;

        LpContext memory ctx = newLpContext(ms);
        uint256[] memory values = new uint256[](tradingFeeRates.length);
        for (uint256 i; i < tradingFeeRates.length; ) {
            values[i] = liquidityPool.binValue(tradingFeeRates[i], ctx);

            unchecked {
                i++;
            }
        }
        return values;
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function getLpReceipt(uint256 receiptId) external view returns (LpReceipt memory receipt) {
        receipt = _getLpReceipt(LpReceiptStorageLib.lpReceiptStorage(), receiptId);
    }

    function _getLpReceipt(
        LpReceiptStorage storage ls,
        uint256 receiptId
    ) private view returns (LpReceipt memory receipt) {
        receipt = ls.getReceipt(receiptId);
        if (receipt.id == 0) revert NotExistLpReceipt();
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function claimableLiquidity(
        int16 tradingFeeRate,
        uint256 oracleVersion
    ) external view returns (ClaimableLiquidity memory) {
        return
            MarketStorageLib.marketStorage().liquidityPool.claimableLiquidity(
                tradingFeeRate,
                oracleVersion
            );
    }

    /**
     * @inheritdoc IMarketLiquidity
     */
    function liquidityBinStatuses() external view returns (LiquidityBinStatus[] memory) {
        MarketStorage storage ms = MarketStorageLib.marketStorage();
        return ms.liquidityPool.liquidityBinStatuses(newLpContext(ms));
    }

    /**
     * @dev Creates a new liquidity receipt.
     * @param ctx The liquidity context.
     * @param action The liquidity action.
     * @param amount The amount of liquidity.
     * @param recipient The address to receive the liquidity.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @return The new liquidity receipt.
     */
    function _newLpReceipt(
        LpContext memory ctx,
        LpAction action,
        uint256 amount,
        address recipient,
        int16 tradingFeeRate
    ) private returns (LpReceipt memory) {
        return
            LpReceipt({
                id: LpReceiptStorageLib.lpReceiptStorage().nextId(),
                oracleVersion: ctx.currentOracleVersion().version,
                action: action,
                amount: amount,
                recipient: recipient,
                tradingFeeRate: tradingFeeRate
            });
    }

    // implement IERC1155Receiver

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155Received(
        address /* operator */,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @inheritdoc IERC1155Receiver
     */
    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // ERC165
            interfaceID == this.onERC1155Received.selector ^ this.onERC1155BatchReceived.selector; // IERC1155Receiver
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IMarketSettle} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketSettle.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {MarketStorage, MarketStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {MarketFacetBase} from "@chromatic-protocol/contracts/core/facets/market/MarketFacetBase.sol";

/**
 * @title MarketSettleFacet
 */
contract MarketSettleFacet is MarketFacetBase, IMarketSettle {
    /**
     * @inheritdoc IMarketSettle
     * @dev This function settles the market by synchronizing the oracle version
     *      and calling the settle function of the liquidity pool.
     */
    function settle() external override {
        MarketStorage storage ms = MarketStorageLib.marketStorage();

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        ms.liquidityPool.settle(ctx);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {IMarketState} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketState.sol";
import {MarketStorage, MarketStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {MarketFacetBase} from "@chromatic-protocol/contracts/core/facets/market/MarketFacetBase.sol";

/**
 * @title MarketStateFacet
 */
contract MarketStateFacet is MarketFacetBase, IMarketState {
    /**
     * @inheritdoc IMarketState
     */
    function factory() external view returns (IChromaticMarketFactory _factory) {
        _factory = MarketStorageLib.marketStorage().factory;
    }

    /**
     * @inheritdoc IMarketState
     */
    function settlementToken() external view returns (IERC20Metadata _token) {
        _token = MarketStorageLib.marketStorage().settlementToken;
    }

    /**
     * @inheritdoc IMarketState
     */
    function oracleProvider() external view returns (IOracleProvider _provider) {
        _provider = MarketStorageLib.marketStorage().oracleProvider;
    }

    /**
     * @inheritdoc IMarketState
     */
    function clbToken() external view returns (ICLBToken _token) {
        _token = MarketStorageLib.marketStorage().clbToken;
    }

    /**
     * @inheritdoc IMarketState
     */
    function liquidator() external view returns (IChromaticLiquidator _liquidator) {
        _liquidator = MarketStorageLib.marketStorage().liquidator;
    }

    /**
     * @inheritdoc IMarketState
     */
    function vault() external view returns (IChromaticVault _vault) {
        _vault = MarketStorageLib.marketStorage().vault;
    }

    /**
     * @inheritdoc IMarketState
     */
    function keeperFeePayer() external view returns (IKeeperFeePayer _keeperFeePayer) {
        _keeperFeePayer = MarketStorageLib.marketStorage().keeperFeePayer;
    }

    /**
     * @inheritdoc IMarketState
     */
    function feeProtocol() external view returns (uint8 _feeProtocol) {
        _feeProtocol = MarketStorageLib.marketStorage().feeProtocol;
    }

    /**
     * @inheritdoc IMarketState
     */
    function setFeeProtocol(uint8 _feeProtocol) external override onlyDao {
        require(_feeProtocol == 0 || (_feeProtocol >= 4 && _feeProtocol <= 10));

        MarketStorage storage ps = MarketStorageLib.marketStorage();

        uint8 feeProtocolOld = ps.feeProtocol;
        ps.feeProtocol = _feeProtocol;

        emit SetFeeProtocol(feeProtocolOld, _feeProtocol);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IOracleProviderRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/IOracleProviderRegistry.sol";
import {IChromaticTradeCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticTradeCallback.sol";
import {IMarketTrade} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketTrade.sol";
import {IVault} from "@chromatic-protocol/contracts/core/interfaces/vault/IVault.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";
import {QTY_PRECISION, QTY_LEVERAGE_PRECISION} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {MarketStorage, MarketStorageLib, PositionStorage, PositionStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {BPS} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {LiquidityPool} from "@chromatic-protocol/contracts/core/libraries/liquidity/LiquidityPool.sol";
import {MarketTradeFacetBase} from "@chromatic-protocol/contracts/core/facets/market/MarketTradeFacetBase.sol";

/**
 * @title MarketTradeFacet
 * @dev A contract that manages trading positions.
 */
contract MarketTradeFacet is MarketTradeFacetBase, IMarketTrade, ReentrancyGuard {
    using Math for uint256;
    using SignedMath for int256;

    error ZeroTargetAmount();
    error TooSmallTakerMargin();
    error NotEnoughMarginTransfered();
    error NotPermitted();
    error AlreadyClosedPosition();
    error NotClaimablePosition();
    error ExceedMaxAllowableTradingFee();
    error ExceedMaxAllowableLeverage();
    error NotAllowableTakerMargin();
    error NotAllowableMakerMargin();

    /**
     * @inheritdoc IMarketTrade
     */
    function openPosition(
        int224 qty,
        uint32 leverage,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 maxAllowableTradingFee,
        bytes calldata data
    ) external override nonReentrant returns (Position memory position) {
        if (qty == 0) revert ZeroTargetAmount();

        MarketStorage storage ms = MarketStorageLib.marketStorage();
        IChromaticMarketFactory factory = ms.factory;
        LiquidityPool storage liquidityPool = ms.liquidityPool;

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        uint256 minMargin = factory.getMinimumMargin(ctx.settlementToken);
        if (takerMargin < minMargin) revert TooSmallTakerMargin();

        _checkPositionParam(
            ctx,
            qty,
            leverage,
            takerMargin,
            makerMargin,
            factory.getOracleProviderProperties(address(ctx.oracleProvider))
        );

        position = _newPosition(ctx, qty, leverage, takerMargin, ms.feeProtocol);
        position.setBinMargins(
            liquidityPool.prepareBinMargins(position.qty, makerMargin, minMargin)
        );

        _openPosition(ctx, liquidityPool, position, maxAllowableTradingFee, data);

        // write position
        PositionStorageLib.positionStorage().setPosition(position);
        // create keeper task
        ms.liquidator.createLiquidationTask(position.id);

        emit OpenPosition(position.owner, position);
    }

    function _checkPositionParam(
        LpContext memory ctx,
        int256 qty,
        uint32 leverage,
        uint256 takerMargin,
        uint256 makerMargin,
        IOracleProviderRegistry.OracleProviderProperties memory properties
    ) private pure {
        uint256 maxAllowableLeverage = (properties.leverageLevel + 1) * 10;
        if (leverage > maxAllowableLeverage * QTY_LEVERAGE_PRECISION)
            revert ExceedMaxAllowableLeverage();

        uint256 absQty = qty.abs().mulDiv(ctx.tokenPrecision, QTY_PRECISION);
        if (
            takerMargin < absQty / maxAllowableLeverage || // reciprocal of max allowable leverage
            takerMargin > absQty // max 100%
        ) revert NotAllowableTakerMargin();
        if (
            makerMargin < absQty.mulDiv(properties.minTakeProfitBPS, BPS) ||
            makerMargin > absQty.mulDiv(properties.maxTakeProfitBPS, BPS)
        ) revert NotAllowableMakerMargin();
    }

    function _openPosition(
        LpContext memory ctx,
        LiquidityPool storage liquidityPool,
        Position memory position,
        uint256 maxAllowableTradingFee,
        bytes calldata data
    ) private {
        // check trading fee
        uint256 tradingFee = position.tradingFee();
        uint256 protocolFee = position.protocolFee();
        if (tradingFee + protocolFee > maxAllowableTradingFee) {
            revert ExceedMaxAllowableTradingFee();
        }

        IERC20Metadata settlementToken = IERC20Metadata(ctx.settlementToken);
        IVault vault = ctx.vault;

        // call callback
        uint256 balanceBefore = settlementToken.balanceOf(address(vault));

        uint256 requiredMargin = position.takerMargin + protocolFee + tradingFee;
        IChromaticTradeCallback(msg.sender).openPositionCallback(
            address(settlementToken),
            address(vault),
            requiredMargin,
            data
        );
        // check margin settlementToken increased
        if (balanceBefore + requiredMargin < settlementToken.balanceOf(address(vault)))
            revert NotEnoughMarginTransfered();

        liquidityPool.acceptOpenPosition(ctx, position); // settle()

        vault.onOpenPosition(
            address(settlementToken),
            position.id,
            position.takerMargin,
            tradingFee,
            protocolFee
        );
    }

    /**
     * @inheritdoc IMarketTrade
     */
    function closePosition(uint256 positionId) external override {
        Position storage position = PositionStorageLib.positionStorage().getStoragePosition(
            positionId
        );
        if (position.id == 0) revert NotExistPosition();
        if (position.owner != msg.sender) revert NotPermitted();
        if (position.closeVersion != 0) revert AlreadyClosedPosition();

        MarketStorage storage ms = MarketStorageLib.marketStorage();
        LiquidityPool storage liquidityPool = ms.liquidityPool;
        IChromaticLiquidator liquidator = ms.liquidator;

        LpContext memory ctx = newLpContext(ms);

        position.closeVersion = ctx.currentOracleVersion().version;
        position.closeTimestamp = block.timestamp;

        liquidityPool.acceptClosePosition(ctx, position);
        liquidator.cancelLiquidationTask(position.id);

        emit ClosePosition(position.owner, position);

        if (position.closeVersion > position.openVersion) {
            liquidator.createClaimPositionTask(position.id);
        } else {
            // process claim if the position is closed in the same oracle version as the open version
            uint256 interest = _claimPosition(ctx, position, 0, 0, position.owner, bytes(""));
            emit ClaimPosition(position.owner, 0, interest, position);
        }
    }

    /**
     * @inheritdoc IMarketTrade
     */
    function claimPosition(
        uint256 positionId,
        address recipient, // EOA or account contract
        bytes calldata data
    ) external override nonReentrant {
        Position memory position = _getPosition(PositionStorageLib.positionStorage(), positionId);
        if (position.owner != msg.sender) revert NotPermitted();

        MarketStorage storage ms = MarketStorageLib.marketStorage();

        LpContext memory ctx = newLpContext(ms);
        ctx.syncOracleVersion();

        if (!ctx.isPastVersion(position.closeVersion)) revert NotClaimablePosition();

        int256 pnl = position.pnl(ctx);
        uint256 interest = _claimPosition(ctx, position, pnl, 0, recipient, data);
        emit ClaimPosition(position.owner, pnl, interest, position);

        ms.liquidator.cancelClaimPositionTask(position.id);
    }

    /**
     * @inheritdoc IMarketTrade
     */
    function getPositions(
        uint256[] calldata positionIds
    ) external view returns (Position[] memory _positions) {
        PositionStorage storage ps = PositionStorageLib.positionStorage();

        _positions = new Position[](positionIds.length);
        for (uint i; i < positionIds.length; ) {
            _positions[i] = ps.getPosition(positionIds[i]);

            unchecked {
                i++;
            }
        }
    }

    function _newPosition(
        LpContext memory ctx,
        int224 qty,
        uint32 leverage,
        uint256 takerMargin,
        uint8 feeProtocol
    ) private returns (Position memory) {
        PositionStorage storage ps = PositionStorageLib.positionStorage();

        return
            Position({
                id: ps.nextId(),
                openVersion: ctx.currentOracleVersion().version,
                closeVersion: 0,
                qty: qty, //
                leverage: leverage,
                openTimestamp: block.timestamp,
                closeTimestamp: 0,
                takerMargin: takerMargin,
                owner: msg.sender,
                _binMargins: new BinMargin[](0),
                _feeProtocol: feeProtocol
            });
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IChromaticTradeCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticTradeCallback.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {MarketStorage, MarketStorageLib, PositionStorage, PositionStorageLib} from "@chromatic-protocol/contracts/core/libraries/MarketStorage.sol";
import {MarketFacetBase} from "@chromatic-protocol/contracts/core/facets/market/MarketFacetBase.sol";

abstract contract MarketTradeFacetBase is MarketFacetBase {
    using SafeCast for uint256;
    using SignedMath for int256;

    error NotExistPosition();
    error ClaimPositionCallbackError();

    /**
     * @dev Internal function for claiming a position.
     * @param ctx The LpContext containing the current oracle version and synchronization information.
     * @param position The Position object representing the position to be claimed.
     * @param pnl The profit or loss amount of the position.
     * @param usedKeeperFee The amount of the keeper fee used.
     * @param recipient The address of the recipient (EOA or account contract) receiving the settlement.
     * @param data Additional data for the claim position callback.
     */
    function _claimPosition(
        LpContext memory ctx,
        Position memory position,
        int256 pnl,
        uint256 usedKeeperFee,
        address recipient,
        bytes memory data
    ) internal returns (uint256 interest) {
        uint256 makerMargin = position.makerMargin();
        uint256 takerMargin = position.takerMargin - usedKeeperFee;
        uint256 settlementAmount = takerMargin;

        // Calculate the interest based on the maker margin and the time difference
        // between the open timestamp and the current block timestamp
        interest = ctx.calculateInterest(makerMargin, position.openTimestamp, block.timestamp);

        // Calculate the realized profit or loss by subtracting the interest from the total pnl
        int256 realizedPnl = pnl - interest.toInt256();
        uint256 absRealizedPnl = realizedPnl.abs();
        if (realizedPnl > 0) {
            if (absRealizedPnl > makerMargin) {
                // If the absolute value of the realized pnl is greater than the maker margin,
                // set the realized pnl to the maker margin and add the maker margin to the settlement
                realizedPnl = makerMargin.toInt256();
                settlementAmount += makerMargin;
            } else {
                settlementAmount += absRealizedPnl;
            }
        } else {
            if (absRealizedPnl > takerMargin) {
                // If the absolute value of the realized pnl is greater than the taker margin,
                // set the realized pnl to the negative taker margin and set the settlement amount to 0
                realizedPnl = -(takerMargin.toInt256());
                settlementAmount = 0;
            } else {
                settlementAmount -= absRealizedPnl;
            }
        }

        MarketStorage storage ms = MarketStorageLib.marketStorage();

        // Accept the claim position in the liquidity pool
        ms.liquidityPool.acceptClaimPosition(ctx, position, realizedPnl);

        // Call the onClaimPosition function in the vault to handle the settlement
        ctx.vault.onClaimPosition(
            ctx.settlementToken,
            position.id,
            recipient,
            takerMargin,
            settlementAmount
        );

        // Call the claim position callback function on the position owner's contract
        // If an exception occurs during the callback, revert the transaction unless the caller is the liquidator
        try
            IChromaticTradeCallback(position.owner).claimPositionCallback(position.id, data)
        {} catch (bytes memory /* e */ /*lowLevelData*/) {
            if (msg.sender != address(ms.liquidator)) {
                revert ClaimPositionCallbackError();
            }
        }
        // Delete the claimed position from the positions mapping
        PositionStorageLib.positionStorage().deletePosition(position.id);
    }

    function _getPosition(
        PositionStorage storage ps,
        uint256 positionId
    ) internal view returns (Position memory position) {
        position = ps.getPosition(positionId);
        if (position.id == 0) revert NotExistPosition();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IChromaticFlashLoanCallback
 * @dev Interface for a contract that handles flash loan callbacks in the Chromatic protocol.
 *      Flash loans are loans that are borrowed and repaid within a single transaction.
 *      This interface defines the function signature for the flash loan callback.
 */
interface IChromaticFlashLoanCallback {
    /**
     * @notice Handles the flash loan callback after a flash loan has been executed.
     * @param fee The fee amount charged for the flash loan.
     * @param data Additional data associated with the flash loan.
     */
    function flashLoanCallback(uint256 fee, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IChromaticLiquidityCallback
 * @dev Interface for a contract that handles liquidity callbacks in the Chromatic protocol.
 *      Liquidity callbacks are used to handle various operations related to liquidity management.
 *      This interface defines the function signatures for different types of liquidity callbacks.
 */
interface IChromaticLiquidityCallback {
    /**
     * @notice Handles the callback after adding liquidity to the Chromatic protocol.
     * @param settlementToken The address of the settlement token used for adding liquidity.
     * @param vault The address of the vault where the liquidity is added.
     * @param data Additional data associated with the liquidity addition.
     */
    function addLiquidityCallback(
        address settlementToken,
        address vault,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after adding liquidity to the Chromatic protocol.
     * @param settlementToken The address of the settlement token used for adding liquidity.
     * @param vault The address of the vault where the liquidity is added.
     * @param data Additional data associated with the liquidity addition.
     */
    function addLiquidityBatchCallback(
        address settlementToken,
        address vault,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after claiming liquidity from the Chromatic protocol.
     * @param receiptId The ID of the liquidity claim receipt.
     * @param data Additional data associated with the liquidity claim.
     */
    function claimLiquidityCallback(uint256 receiptId, bytes calldata data) external;

    /**
     * @notice Handles the callback after claiming liquidity from the Chromatic protocol.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data associated with the liquidity claim.
     */
    function claimLiquidityBatchCallback(
        uint256[] calldata receiptIds,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after removing liquidity from the Chromatic protocol.
     * @param clbToken The address of the Chromatic liquidity token.
     * @param clbTokenId The ID of the Chromatic liquidity token to be removed.
     * @param data Additional data associated with the liquidity removal.
     */
    function removeLiquidityCallback(
        address clbToken,
        uint256 clbTokenId,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after removing liquidity from the Chromatic protocol.
     * @param clbToken The address of the Chromatic liquidity token.
     * @param clbTokenIds The array of the Chromatic liquidity token IDs to be removed.
     * @param data Additional data associated with the liquidity removal.
     */
    function removeLiquidityBatchCallback(
        address clbToken,
        uint256[] calldata clbTokenIds,
        bytes calldata data
    ) external;

    /**
     * @notice Handles the callback after withdrawing liquidity from the Chromatic protocol.
     * @param receiptId The ID of the liquidity withdrawal receipt.
     * @param data Additional data associated with the liquidity withdrawal.
     */
    function withdrawLiquidityCallback(uint256 receiptId, bytes calldata data) external;

    /**
     * @notice Handles the callback after withdrawing liquidity from the Chromatic protocol.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data associated with the liquidity withdrawal.
     */
    function withdrawLiquidityBatchCallback(
        uint256[] calldata receiptIds,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IChromaticTradeCallback
 * @dev The interface for handling callbacks related to Chromatic trading operations.
 */
interface IChromaticTradeCallback {
    /**
     * @notice Callback function called after opening a position.
     * @param settlementToken The address of the settlement token used in the position.
     * @param vault The address of the vault contract.
     * @param marginRequired The amount of margin required for the position.
     * @param data Additional data related to the callback.
     */
    function openPositionCallback(
        address settlementToken,
        address vault,
        uint256 marginRequired,
        bytes calldata data
    ) external;

    /**
     * @notice Callback function called after claiming a position.
     * @param positionId The ID of the claimed position.
     * @param data Additional data related to the callback.
     */
    function claimPositionCallback(uint256 positionId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title An interface for a contract that is capable of deploying Chromatic markets
 * @notice A contract that constructs a market must implement this to pass arguments to the market
 * @dev This is used to avoid having constructor arguments in the market contract, which results in the init code hash
 * of the market being constant allowing the CREATE2 address of the market to be cheaply computed on-chain
 */
interface IMarketDeployer {
    /**
     * @notice Get the parameters to be used in constructing the market, set transiently during market creation.
     * @dev Called by the market constructor to fetch the parameters of the market
     * Returns underlyingAsset The underlying asset of the market
     * Returns settlementToken The settlement token of the market
     * Returns vPoolCapacity Capacity of virtual future pool
     * Returns vPoolA Amplification coefficient of virtual future pool, precise value
     */
    function parameters() external view returns (address oracleProvider, address settlementToken);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IOracleProviderRegistry
 * @dev Interface for the Oracle Provider Registry contract.
 */
interface IOracleProviderRegistry {
    struct OracleProviderProperties {
        uint32 minTakeProfitBPS;
        uint32 maxTakeProfitBPS;
        uint8 leverageLevel;
    }

    /**
     * @dev Emitted when a new oracle provider is registered.
     * @param oracleProvider The address of the registered oracle provider.
     * @param properties The properties of the registered oracle provider.
     */
    event OracleProviderRegistered(
        address indexed oracleProvider,
        OracleProviderProperties properties
    );

    /**
     * @dev Emitted when an oracle provider is unregistered.
     * @param oracleProvider The address of the unregistered oracle provider.
     */
    event OracleProviderUnregistered(address indexed oracleProvider);

    /**
     * @dev Emitted when the take-profit basis points range of an oracle provider is updated.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The new minimum take-profit basis points.
     * @param maxTakeProfitBPS The new maximum take-profit basis points.
     */
    event UpdateTakeProfitBPSRange(
        address indexed oracleProvider,
        uint32 indexed minTakeProfitBPS,
        uint32 indexed maxTakeProfitBPS
    );

    /**
     * @dev Emitted when the level of an oracle provider is set.
     * @param oracleProvider The address of the oracle provider.
     * @param level The new level set for the oracle provider.
     */
    event UpdateLeverageLevel(address indexed oracleProvider, uint8 indexed level);

    /**
     * @notice Registers an oracle provider.
     * @param oracleProvider The address of the oracle provider to register.
     * @param properties The properties of the oracle provider.
     */
    function registerOracleProvider(
        address oracleProvider,
        OracleProviderProperties memory properties
    ) external;

    /**
     * @notice Unregisters an oracle provider.
     * @param oracleProvider The address of the oracle provider to unregister.
     */
    function unregisterOracleProvider(address oracleProvider) external;

    /**
     * @notice Gets the registered oracle providers.
     * @return An array of registered oracle provider addresses.
     */
    function registeredOracleProviders() external view returns (address[] memory);

    /**
     * @notice Checks if an oracle provider is registered.
     * @param oracleProvider The address of the oracle provider to check.
     * @return A boolean indicating if the oracle provider is registered.
     */
    function isRegisteredOracleProvider(address oracleProvider) external view returns (bool);

    /**
     * @notice Retrieves the properties of an oracle provider.
     * @param oracleProvider The address of the oracle provider.
     * @return The properties of the oracle provider.
     */
    function getOracleProviderProperties(
        address oracleProvider
    ) external view returns (OracleProviderProperties memory);

    /**
     * @notice Updates the take-profit basis points range of an oracle provider.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The new minimum take-profit basis points.
     * @param maxTakeProfitBPS The new maximum take-profit basis points.
     */
    function updateTakeProfitBPSRange(
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS
    ) external;

    /**
     * @notice Updates the leverage level of an oracle provider in the registry.
     * @dev The level must be either 0 or 1, and the max leverage must be x10 for level 0 or x20 for level 1.
     * @param oracleProvider The address of the oracle provider.
     * @param level The new leverage level to be set for the oracle provider.
     */
    function updateLeverageLevel(address oracleProvider, uint8 level) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {InterestRate} from "@chromatic-protocol/contracts/core/libraries/InterestRate.sol";

/**
 * @title ISettlementTokenRegistry
 * @dev Interface for the Settlement Token Registry contract.
 */
interface ISettlementTokenRegistry {
    /**
     * @dev Emitted when a new settlement token is registered.
     * @param token The address of the registered settlement token.
     * @param minimumMargin The minimum margin for the markets using this settlement token.
     * @param interestRate The interest rate for the settlement token.
     * @param flashLoanFeeRate The flash loan fee rate for the settlement token.
     * @param earningDistributionThreshold The earning distribution threshold for the settlement token.
     * @param uniswapFeeTier The Uniswap fee tier for the settlement token.
     */
    event SettlementTokenRegistered(
        address indexed token,
        uint256 indexed minimumMargin,
        uint256 indexed interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    );

    /**
     * @dev Emitted when the minimum margin for a settlement token is set.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    event SetMinimumMargin(address indexed token, uint256 indexed minimumMargin);

    /**
     * @dev Emitted when the flash loan fee rate for a settlement token is set.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    event SetFlashLoanFeeRate(address indexed token, uint256 indexed flashLoanFeeRate);

    /**
     * @dev Emitted when the earning distribution threshold for a settlement token is set.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    event SetEarningDistributionThreshold(
        address indexed token,
        uint256 indexed earningDistributionThreshold
    );

    /**
     * @dev Emitted when the Uniswap fee tier for a settlement token is set.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    event SetUniswapFeeTier(address indexed token, uint24 indexed uniswapFeeTier);

    /**
     * @dev Emitted when an interest rate record is appended for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    event InterestRateRecordAppended(
        address indexed token,
        uint256 indexed annualRateBPS,
        uint256 indexed beginTimestamp
    );

    /**
     * @dev Emitted when the last interest rate record is removed for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    event LastInterestRateRecordRemoved(
        address indexed token,
        uint256 indexed annualRateBPS,
        uint256 indexed beginTimestamp
    );

    /**
     * @notice Registers a new settlement token.
     * @param token The address of the settlement token to register.
     * @param minimumMargin The minimum margin for the settlement token.
     * @param interestRate The interest rate for the settlement token.
     * @param flashLoanFeeRate The flash loan fee rate for the settlement token.
     * @param earningDistributionThreshold The earning distribution threshold for the settlement token.
     * @param uniswapFeeTier The Uniswap fee tier for the settlement token.
     */
    function registerSettlementToken(
        address token,
        uint256 minimumMargin,
        uint256 interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    ) external;

    /**
     * @notice Gets the list of registered settlement tokens.
     * @return An array of addresses representing the registered settlement tokens.
     */
    function registeredSettlementTokens() external view returns (address[] memory);

    /**
     * @notice Checks if a settlement token is registered.
     * @param token The address of the settlement token to check.
     * @return True if the settlement token is registered, false otherwise.
     */
    function isRegisteredSettlementToken(address token) external view returns (bool);

    /**
     * @notice Gets the minimum margin for a settlement token.
     * @dev The minimumMargin is used as the minimum value for the taker margin of a position
     *      or as the minimum value for the maker margin of each bin.
     * @param token The address of the settlement token.
     * @return The minimum margin for the settlement token.
     */
    function getMinimumMargin(address token) external view returns (uint256);

    /**
     * @notice Sets the minimum margin for a settlement token.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    function setMinimumMargin(address token, uint256 minimumMargin) external;

    /**
     * @notice Gets the flash loan fee rate for a settlement token.
     * @param token The address of the settlement token.
     * @return The flash loan fee rate for the settlement token.
     */
    function getFlashLoanFeeRate(address token) external view returns (uint256);

    /**
     * @notice Sets the flash loan fee rate for a settlement token.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    function setFlashLoanFeeRate(address token, uint256 flashLoanFeeRate) external;

    /**
     * @notice Gets the earning distribution threshold for a settlement token.
     * @param token The address of the settlement token.
     * @return The earning distribution threshold for the settlement token.
     */
    function getEarningDistributionThreshold(address token) external view returns (uint256);

    /**
     * @notice Sets the earning distribution threshold for a settlement token.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    function setEarningDistributionThreshold(
        address token,
        uint256 earningDistributionThreshold
    ) external;

    /**
     * @notice Gets the Uniswap fee tier for a settlement token.
     * @param token The address of the settlement token.
     * @return The Uniswap fee tier for the settlement token.
     */
    function getUniswapFeeTier(address token) external view returns (uint24);

    /**
     * @notice Sets the Uniswap fee tier for a settlement token.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    function setUniswapFeeTier(address token, uint24 uniswapFeeTier) external;

    /**
     * @notice Appends an interest rate record for a settlement token.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points (BPS).
     * @param beginTimestamp The timestamp when the interest rate record begins.
     */
    function appendInterestRateRecord(
        address token,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) external;

    /**
     * @notice Removes the last interest rate record for a settlement token.
     * @param token The address of the settlement token.
     */
    function removeLastInterestRateRecord(address token) external;

    /**
     * @notice Gets the current interest rate for a settlement token.
     * @param token The address of the settlement token.
     * @return The current interest rate for the settlement token.
     */
    function currentInterestRate(address token) external view returns (uint256);

    /**
     * @notice Gets all the interest rate records for a settlement token.
     * @param token The address of the settlement token.
     * @return An array of interest rate records for the settlement token.
     */
    function getInterestRateRecords(
        address token
    ) external view returns (InterestRate.Record[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IChromaticLiquidator
 * @dev Interface for the Chromatic Liquidator contract.
 */
interface IChromaticLiquidator {
    /**
     * @notice Emitted when the liquidation task interval is updated.
     * @param interval The new liquidation task interval.
     */
    event UpdateLiquidationInterval(uint256 indexed interval);

    /**
     * @notice Emitted when the claim task interval is updated.
     * @param interval The new claim task interval.
     */
    event UpdateClaimInterval(uint256 indexed interval);

    /**
     * @notice Updates the liquidation task interval.
     * @param interval The new liquidation task interval.
     */
    function updateLiquidationInterval(uint256 interval) external;

    /**
     * @notice Updates the claim task interval.
     * @param interval The new claim task interval.
     */
    function updateClaimInterval(uint256 interval) external;

    /**
     * @notice Creates a liquidation task for a given position.
     * @param positionId The ID of the position to be liquidated.
     */
    function createLiquidationTask(uint256 positionId) external;

    /**
     * @notice Cancels a liquidation task for a given position.
     * @param positionId The ID of the position for which to cancel the liquidation task.
     */
    function cancelLiquidationTask(uint256 positionId) external;

    /**
     * @notice Resolves the liquidation of a position.
     * @dev This function is called by the Gelato automation system.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be liquidated.
     * @return canExec Whether the liquidation can be executed.
     * @return execPayload The encoded function call to execute the liquidation.
     */
    function resolveLiquidation(
        address market,
        uint256 positionId
    ) external view returns (bool canExec, bytes memory execPayload);

    /**
     * @notice Liquidates a position in a market.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be liquidated.
     */
    function liquidate(address market, uint256 positionId) external;

    /**
     * @notice Creates a claim position task for a given position.
     * @param positionId The ID of the position to be claimed.
     */
    function createClaimPositionTask(uint256 positionId) external;

    /**
     * @notice Cancels a claim position task for a given position.
     * @param positionId The ID of the position for which to cancel the claim position task.
     */
    function cancelClaimPositionTask(uint256 positionId) external;

    /**
     * @notice Resolves the claim of a position.
     * @dev This function is called by the Gelato automation system.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be claimed.
     * @return canExec Whether the claim can be executed.
     * @return execPayload The encoded function call to execute the claim.
     */
    function resolveClaimPosition(
        address market,
        uint256 positionId
    ) external view returns (bool canExec, bytes memory execPayload);

    /**
     * @notice Claims a position in a market.
     * @param market The address of the market contract.
     * @param positionId The ID of the position to be claimed.
     */
    function claimPosition(address market, uint256 positionId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IMarketTrade} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketTrade.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {IMarketState} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketState.sol";
import {IMarketLiquidate} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidate.sol";
import {IMarketSettle} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketSettle.sol";

/**
 * @title IChromaticMarket
 * @dev Interface for the Chromatic Market contract, which combines trade and liquidity functionalities.
 */
interface IChromaticMarket is
    IMarketTrade,
    IMarketLiquidity,
    IMarketState,
    IMarketLiquidate,
    IMarketSettle
{

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IMarketDeployer} from "@chromatic-protocol/contracts/core/interfaces/factory/IMarketDeployer.sol";
import {ISettlementTokenRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/ISettlementTokenRegistry.sol";
import {IOracleProviderRegistry} from "@chromatic-protocol/contracts/core/interfaces/factory/IOracleProviderRegistry.sol";

/**
 * @title IChromaticMarketFactory
 * @dev Interface for the Chromatic Market Factory contract.
 */
interface IChromaticMarketFactory is
    IMarketDeployer,
    IOracleProviderRegistry,
    ISettlementTokenRegistry,
    IInterestCalculator
{
    /**
     * @notice Emitted when the DAO address is updated.
     * @param dao The new DAO address.
     */
    event UpdateDao(address indexed dao);

    /**
     * @notice Emitted when the DAO treasury address is updated.
     * @param treasury The new DAO treasury address.
     */
    event UpdateTreasury(address indexed treasury);

    /**
     * @notice Emitted when the liquidator address is set.
     * @param liquidator The liquidator address.
     */
    event SetLiquidator(address indexed liquidator);

    /**
     * @notice Emitted when the vault address is set.
     * @param vault The vault address.
     */
    event SetVault(address indexed vault);

    /**
     * @notice Emitted when the keeper fee payer address is set.
     * @param keeperFeePayer The keeper fee payer address.
     */
    event SetKeeperFeePayer(address indexed keeperFeePayer);

    /**
     * @notice Emitted when a market is created.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     * @param market The address of the created market.
     */
    event MarketCreated(
        address indexed oracleProvider,
        address indexed settlementToken,
        address indexed market
    );

    /**
     * @notice Returns the address of the DAO.
     * @return The address of the DAO.
     */
    function dao() external view returns (address);

    /**
     * @notice Returns the address of the DAO treasury.
     * @return The address of the DAO treasury.
     */
    function treasury() external view returns (address);

    /**
     * @notice Returns the address of the liquidator.
     * @return The address of the liquidator.
     */
    function liquidator() external view returns (address);

    /**
     * @notice Returns the address of the vault.
     * @return The address of the vault.
     */
    function vault() external view returns (address);

    /**
     * @notice Returns the address of the keeper fee payer.
     * @return The address of the keeper fee payer.
     */
    function keeperFeePayer() external view returns (address);

    /**
     * @notice Updates the DAO address.
     * @param dao The new DAO address.
     */
    function updateDao(address dao) external;

    /**
     * @notice Updates the DAO treasury address.
     * @param treasury The new DAO treasury address.
     */
    function updateTreasury(address treasury) external;

    /**
     * @notice Sets the liquidator address.
     * @param liquidator The liquidator address.
     */
    function setLiquidator(address liquidator) external;

    /**
     * @notice Sets the vault address.
     * @param vault The vault address.
     */
    function setVault(address vault) external;

    /**
     * @notice Sets the keeper fee payer address.
     * @param keeperFeePayer The keeper fee payer address.
     */
    function setKeeperFeePayer(address keeperFeePayer) external;

    /**
     * @notice Returns an array of all market addresses.
     * @return markets An array of all market addresses.
     */
    function getMarkets() external view returns (address[] memory markets);

    /**
     * @notice Returns an array of market addresses associated with a settlement token.
     * @param settlementToken The address of the settlement token.
     * @return An array of market addresses.
     */
    function getMarketsBySettlmentToken(
        address settlementToken
    ) external view returns (address[] memory);

    /**
     * @notice Returns the address of a market associated with an oracle provider and settlement token.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     * @return The address of the market.
     */
    function getMarket(
        address oracleProvider,
        address settlementToken
    ) external view returns (address);

    /**
     * @notice Creates a new market associated with an oracle provider and settlement token.
     * @param oracleProvider The address of the oracle provider.
     * @param settlementToken The address of the settlement token.
     */
    function createMarket(address oracleProvider, address settlementToken) external;

    /**
     * @notice Checks if a market is registered.
     * @param market The address of the market.
     * @return True if the market is registered, false otherwise.
     */
    function isRegisteredMarket(address market) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ILendingPool} from "@chromatic-protocol/contracts/core/interfaces/vault/ILendingPool.sol";
import {IVault} from "@chromatic-protocol/contracts/core/interfaces/vault/IVault.sol";

/**
 * @title IChromaticVault
 * @notice Interface for the Chromatic Vault contract.
 */
interface IChromaticVault is IVault, ILendingPool {
    /**
     * @dev Emitted when market earning is accumulated.
     * @param market The address of the market.
     * @param earning The amount of earning accumulated.
     */
    event MarketEarningAccumulated(address indexed market, uint256 earning);

    /**
     * @dev Emitted when maker earning is distributed.
     * @param token The address of the settlement token.
     * @param earning The amount of earning distributed.
     * @param usedKeeperFee The amount of keeper fee used.
     */
    event MakerEarningDistributed(
        address indexed token,
        uint256 indexed earning,
        uint256 indexed usedKeeperFee
    );

    /**
     * @dev Emitted when market earning is distributed.
     * @param market The address of the market.
     * @param earning The amount of earning distributed.
     * @param usedKeeperFee The amount of keeper fee used.
     * @param marketBalance The balance of the market.
     */
    event MarketEarningDistributed(
        address indexed market,
        uint256 indexed earning,
        uint256 indexed usedKeeperFee,
        uint256 marketBalance
    );

    /**
     * @notice Creates a maker earning distribution task for a token.
     * @param token The address of the settlement token.
     */
    function createMakerEarningDistributionTask(address token) external;

    /**
     * @notice Cancels a maker earning distribution task for a token.
     * @param token The address of the settlement token.
     */
    function cancelMakerEarningDistributionTask(address token) external;

    /**
     * @notice Creates a market earning distribution task for a market.
     * @param market The address of the market.
     */
    function createMarketEarningDistributionTask(address market) external;

    /**
     * @notice Cancels a market earning distribution task for a market.
     * @param market The address of the market.
     */
    function cancelMarketEarningDistributionTask(address market) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";

/**
 * @title ICLBToken
 * @dev Interface for CLBToken contract, which represents Liquidity Bin tokens.
 */
interface ICLBToken is IERC1155, IERC1155MetadataURI {
    /**
     * @dev Total amount of tokens in with a given id.
     * @param id The token ID for which to retrieve the total supply.
     * @return The total supply of tokens for the given token ID.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Total amounts of tokens in with the given ids.
     * @param ids The token IDs for which to retrieve the total supply.
     * @return The total supples of tokens for the given token IDs.
     */
    function totalSupplyBatch(uint256[] memory ids) external view returns (uint256[] memory);

    /**
     * @dev Mints new tokens and assigns them to the specified address.
     * @param to The address to which the minted tokens will be assigned.
     * @param id The token ID to mint.
     * @param amount The amount of tokens to mint.
     * @param data Additional data to pass during the minting process.
     */
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev Burns tokens from a specified address.
     * @param from The address from which to burn tokens.
     * @param id The token ID to burn.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 id, uint256 amount) external;

    /**
     * @dev Retrieves the number of decimals used for token amounts.
     * @return The number of decimals used for token amounts.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Retrieves the name of a token.
     * @param id The token ID for which to retrieve the name.
     * @return The name of the token.
     */
    function name(uint256 id) external view returns (string memory);

    /**
     * @dev Retrieves the description of a token.
     * @param id The token ID for which to retrieve the description.
     * @return The description of the token.
     */
    function description(uint256 id) external view returns (string memory);

    /**
     * @dev Retrieves the image URI of a token.
     * @param id The token ID for which to retrieve the image URI.
     * @return The image URI of the token.
     */
    function image(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IInterestCalculator
 * @dev Interface for an interest calculator contract.
 */
interface IInterestCalculator {
    /**
     * @notice Calculates the interest accrued for a given token and amount within a specified time range.
     * @param token The address of the token.
     * @param amount The amount of the token.
     * @param from The starting timestamp (inclusive) of the time range.
     * @param to The ending timestamp (exclusive) of the time range.
     * @return The accrued interest for the specified token and amount within the given time range.
     */
    function calculateInterest(
        address token,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IKeeperFeePayer
 * @dev Interface for a contract that pays keeper fees.
 */
interface IKeeperFeePayer {
    event SetRouter(address indexed);

    /**
     * @notice Approves or revokes approval to the Uniswap router for a given token.
     * @param token The address of the token.
     * @param approve A boolean indicating whether to approve or revoke approval.
     */
    function approveToRouter(address token, bool approve) external;

    /**
     * @notice Pays the keeper fee using Uniswap swaps.
     * @param tokenIn The address of the token being swapped.
     * @param amountOut The desired amount of output tokens.
     * @param keeperAddress The address of the keeper to receive the fee.
     * @return amountIn The actual amount of input tokens used for the swap.
     */
    function payKeeperFee(
        address tokenIn,
        uint256 amountOut,
        address keeperAddress
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";

/**
 * @title IMarketLiquidate
 * @dev Interface for liquidating and claiming positions in a market.
 */
interface IMarketLiquidate {
    /**
     * @dev Emitted when a position is claimed by keeper.
     * @param account The address of the account claiming the position.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param usedKeeperFee The amount of keeper fee used for the liquidation.
     * @param position The claimed position.
     */
    event ClaimPositionByKeeper(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        uint256 usedKeeperFee,
        Position position
    );

    /**
     * @dev Emitted when a position is liquidated.
     * @param account The address of the account being liquidated.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param usedKeeperFee The amount of keeper fee used for the liquidation.
     * @param position The liquidated position.
     */
    event Liquidate(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        uint256 usedKeeperFee,
        Position position
    );

    /**
     * @dev Checks if a position is eligible for liquidation.
     * @param positionId The ID of the position to check.
     * @return A boolean indicating if the position is eligible for liquidation.
     */
    function checkLiquidation(uint256 positionId) external view returns (bool);

    /**
     * @dev Liquidates a position.
     * @param positionId The ID of the position to liquidate.
     * @param keeper The address of the keeper performing the liquidation.
     * @param keeperFee The native token amount of the keeper's fee.
     */
    function liquidate(uint256 positionId, address keeper, uint256 keeperFee) external;

    /**
     * @dev Checks if a position is eligible for claim.
     * @param positionId The ID of the position to check.
     * @return A boolean indicating if the position is eligible for claim.
     */
    function checkClaimPosition(uint256 positionId) external view returns (bool);

    /**
     * @dev Claims a closed position on behalf of a keeper.
     * @param positionId The ID of the position to claim.
     * @param keeper The address of the keeper claiming the position.
     * @param keeperFee The native token amount of the keeper's fee.
     */
    function claimPosition(uint256 positionId, address keeper, uint256 keeperFee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

/**
 * @title IMarketLiquidity
 * @dev The interface for liquidity operations in a market.
 */
interface IMarketLiquidity {
    /**
     * @dev A struct representing claimable liquidity information.
     */
    struct ClaimableLiquidity {
        /// @dev The amount of settlement tokens requested for minting.
        uint256 mintingTokenAmountRequested;
        /// @dev The actual amount of CLB tokens minted.
        uint256 mintingCLBTokenAmount;
        /// @dev The amount of CLB tokens requested for burning.
        uint256 burningCLBTokenAmountRequested;
        /// @dev The actual amount of CLB tokens burned.
        uint256 burningCLBTokenAmount;
        /// @dev The amount of settlement tokens equal in value to the burned CLB tokens.
        uint256 burningTokenAmount;
    }

    struct LiquidityBinStatus {
        uint256 liquidity;
        uint256 freeLiquidity;
        uint256 binValue;
        int16 tradingFeeRate;
    }

    /**
     * @dev Emitted when liquidity is added to the market.
     * @param receipt The liquidity receipt.
     */
    event AddLiquidity(LpReceipt receipt);

    /**
     * @dev Emitted when liquidity is added to the market.
     * @param receipts An array of LP receipts.
     */
    event AddLiquidityBatch(LpReceipt[] receipts);

    /**
     * @dev Emitted when liquidity is claimed from the market.
     * @param clbTokenAmount The amount of CLB tokens claimed.
     * @param receipt The liquidity receipt.
     */
    event ClaimLiquidity(LpReceipt receipt, uint256 indexed clbTokenAmount);

    /**
     * @dev Emitted when liquidity is claimed from the market.
     * @param receipts An array of LP receipts.
     * @param clbTokenAmounts The amount list of CLB tokens claimed.
     */
    event ClaimLiquidityBatch(LpReceipt[] receipts, uint256[] clbTokenAmounts);

    /**
     * @dev Emitted when liquidity is removed from the market.
     * @param receipt The liquidity receipt.
     */
    event RemoveLiquidity(LpReceipt receipt);

    /**
     * @dev Emitted when liquidity is removed from the market.
     * @param receipts An array of LP receipts.
     */
    event RemoveLiquidityBatch(LpReceipt[] receipts);

    /**
     * @dev Emitted when liquidity is withdrawn from the market.
     * @param receipt The liquidity receipt.
     * @param amount The amount of liquidity withdrawn.
     * @param burnedCLBTokenAmount The amount of burned CLB tokens.
     */
    event WithdrawLiquidity(
        LpReceipt receipt,
        uint256 indexed amount,
        uint256 indexed burnedCLBTokenAmount
    );

    /**
     * @dev Emitted when liquidity is withdrawn from the market.
     * @param receipts An array of LP receipts.
     * @param amounts The amount list of liquidity withdrawn.
     * @param burnedCLBTokenAmounts The amount list of burned CLB tokens.
     */
    event WithdrawLiquidityBatch(
        LpReceipt[] receipts,
        uint256[] amounts,
        uint256[] burnedCLBTokenAmounts
    );

    /**
     * @dev Adds liquidity to the market.
     * @param recipient The address to receive the liquidity tokens.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function addLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external returns (LpReceipt memory);

    /**
     * @notice Adds liquidity to multiple liquidity bins of the market in a batch.
     * @param recipient The address of the recipient for each liquidity bin.
     * @param tradingFeeRates An array of fee rates for each liquidity bin.
     * @param amounts An array of amounts to add as liquidity for each bin.
     * @param data Additional data for the liquidity callback.
     * @return An array of LP receipts.
     */
    function addLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (LpReceipt[] memory);

    /**
     * @dev Claims liquidity from a liquidity receipt.
     * @param receiptId The ID of the liquidity receipt.
     * @param data Additional data for the liquidity callback.
     */
    function claimLiquidity(uint256 receiptId, bytes calldata data) external;

    /**
     * @dev Claims liquidity from a liquidity receipt.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data for the liquidity callback.
     */
    function claimLiquidityBatch(uint256[] calldata receiptIds, bytes calldata data) external;

    /**
     * @dev Removes liquidity from the market.
     * @param recipient The address to receive the removed liquidity.
     * @param tradingFeeRate The trading fee rate for the liquidity.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function removeLiquidity(
        address recipient,
        int16 tradingFeeRate,
        bytes calldata data
    ) external returns (LpReceipt memory);

    /**
     * @dev Removes liquidity from the market.
     * @param recipient The address to receive the removed liquidity.
     * @param tradingFeeRates An array of fee rates for each liquidity bin.
     * @param clbTokenAmounts An array of clb token amounts to remove as liquidity for each bin.
     * @param data Additional data for the liquidity callback.
     * @return The liquidity receipt.
     */
    function removeLiquidityBatch(
        address recipient,
        int16[] calldata tradingFeeRates,
        uint256[] calldata clbTokenAmounts,
        bytes calldata data
    ) external returns (LpReceipt[] memory);

    /**
     * @dev Withdraws liquidity from a liquidity receipt.
     * @param receiptId The ID of the liquidity receipt.
     * @param data Additional data for the liquidity callback.
     */
    function withdrawLiquidity(uint256 receiptId, bytes calldata data) external;

    /**
     * @dev Withdraws liquidity from a liquidity receipt.
     * @param receiptIds The array of the liquidity receipt IDs.
     * @param data Additional data for the liquidity callback.
     */
    function withdrawLiquidityBatch(uint256[] calldata receiptIds, bytes calldata data) external;

    /**
     * @dev Retrieves the total liquidity amount for a specific trading fee rate in the liquidity pool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the liquidity amount.
     * @return amount The total liquidity amount for the specified trading fee rate.
     */
    function getBinLiquidity(int16 tradingFeeRate) external view returns (uint256 amount);

    /**
     * @dev Retrieves the available (free) liquidity amount for a specific trading fee rate in the liquidity pool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the available liquidity amount.
     * @return amount The available (free) liquidity amount for the specified trading fee rate.
     */
    function getBinFreeLiquidity(int16 tradingFeeRate) external view returns (uint256 amount);

    /**
     * @dev Retrieves the values of a specific trading fee rate's bins in the liquidity pool.
     *      The value of a bin represents the total valuation of the liquidity in the bin.
     * @param tradingFeeRates The list of trading fee rate for which to retrieve the bin value.
     * @return values The value list of the bins for the specified trading fee rates.
     */
    function getBinValues(
        int16[] memory tradingFeeRates
    ) external view returns (uint256[] memory values);

    /**
     * @dev Distributes earning to the liquidity bins.
     * @param earning The amount of earning to distribute.
     * @param marketBalance The balance of the market.
     */
    function distributeEarningToBins(uint256 earning, uint256 marketBalance) external;

    /**
     * @dev Retrieves the liquidity receipt with the given receipt ID.
     *      It throws NotExistLpReceipt if the specified receipt ID does not exist.
     * @param receiptId The ID of the liquidity receipt to retrieve.
     * @return receipt The liquidity receipt with the specified ID.
     */
    function getLpReceipt(uint256 receiptId) external view returns (LpReceipt memory);

    /**
     * @dev Retrieves the claimable liquidity information for a specific trading fee rate and oracle version from the associated LiquidityPool.
     * @param tradingFeeRate The trading fee rate for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        int16 tradingFeeRate,
        uint256 oracleVersion
    ) external view returns (ClaimableLiquidity memory);

    /**
     * @dev Retrieves the liquidity bin statuses for the caller's liquidity pool.
     * @return statuses An array of LiquidityBinStatus representing the liquidity bin statuses.
     */
    function liquidityBinStatuses() external view returns (LiquidityBinStatus[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IMarketSettle
 * @dev Interface for market settlement.
 */
interface IMarketSettle {
    /**
     * @notice Executes the settlement process for the Chromatic market.
     * @dev This function is called to settle the market.
     */
    function settle() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";

/**
 * @title IMarketState
 * @dev Interface for accessing the state of a market contract.
 */
interface IMarketState {
    /**
     * @notice Emitted when the protocol fee is changed by the market
     * @param feeProtocolOld The previous value of the protocol fee
     * @param feeProtocolNew The updated value of the protocol fee
     */
    event SetFeeProtocol(uint8 feeProtocolOld, uint8 feeProtocolNew);

    /**
     * @dev Returns the factory contract for the market.
     * @return The factory contract.
     */
    function factory() external view returns (IChromaticMarketFactory);

    /**
     * @dev Returns the settlement token of the market.
     * @return The settlement token.
     */
    function settlementToken() external view returns (IERC20Metadata);

    /**
     * @dev Returns the oracle provider contract for the market.
     * @return The oracle provider contract.
     */
    function oracleProvider() external view returns (IOracleProvider);

    /**
     * @dev Returns the CLB token contract for the market.
     * @return The CLB token contract.
     */
    function clbToken() external view returns (ICLBToken);

    /**
     * @dev Returns the liquidator contract for the market.
     * @return The liquidator contract.
     */
    function liquidator() external view returns (IChromaticLiquidator);

    /**
     * @dev Returns the vault contract for the market.
     * @return The vault contract.
     */
    function vault() external view returns (IChromaticVault);

    /**
     * @dev Returns the keeper fee payer contract for the market.
     * @return The keeper fee payer contract.
     */
    function keeperFeePayer() external view returns (IKeeperFeePayer);

    /**
     * @notice Returns the denominator of the protocol's % share of the fees
     * @return The protocol fee for the market
     */
    function feeProtocol() external view returns (uint8);

    /**
     * @notice Set the denominator of the protocol's % share of the fees
     * @param feeProtocol new protocol fee for the market
     */
    function setFeeProtocol(uint8 feeProtocol) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";

/**
 * @title IMarketTrade
 * @dev Interface for trading positions in a market.
 */
interface IMarketTrade {
    /**
     * @dev Emitted when a position is opened.
     * @param account The address of the account opening the position.
     * @param position The opened position.
     */
    event OpenPosition(address indexed account, Position position);

    /**
     * @dev Emitted when a position is closed.
     * @param account The address of the account closing the position.
     * @param position The closed position.
     */
    event ClosePosition(address indexed account, Position position);

    /**
     * @dev Emitted when a position is claimed.
     * @param account The address of the account claiming the position.
     * @param pnl The profit or loss of the claimed position.
     * @param interest The interest paid for the claimed position.
     * @param position The claimed position.
     */
    event ClaimPosition(
        address indexed account,
        int256 indexed pnl,
        uint256 indexed interest,
        Position position
    );

    /**
     * @dev Emitted when protocol fees are transferred.
     * @param positionId The ID of the position for which the fees are transferred.
     * @param amount The amount of fees transferred.
     */
    event TransferProtocolFee(uint256 indexed positionId, uint256 indexed amount);

    /**
     * @dev Opens a new position in the market.
     * @param qty The quantity of the position.
     * @param leverage The leverage of the position in basis points.
     * @param takerMargin The margin amount provided by the taker.
     * @param makerMargin The margin amount provided by the maker.
     * @param maxAllowableTradingFee The maximum allowable trading fee for the position.
     * @param data Additional data for the position callback.
     * @return The opened position.
     */
    function openPosition(
        int224 qty,
        uint32 leverage, // BPS
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 maxAllowableTradingFee,
        bytes calldata data
    ) external returns (Position memory);

    /**
     * @dev Closes a position in the market.
     * @param positionId The ID of the position to close.
     */
    function closePosition(uint256 positionId) external;

    /**
     * @dev Claims a closed position in the market.
     * @param positionId The ID of the position to claim.
     * @param recipient The address of the recipient of the claimed position.
     * @param data Additional data for the claim callback.
     */
    function claimPosition(
        uint256 positionId,
        address recipient, // EOA or account contract
        bytes calldata data
    ) external;

    /**
     * @dev Retrieves multiple positions by their IDs.
     * @param positionIds The IDs of the positions to retrieve.
     * @return positions An array of retrieved positions.
     */
    function getPositions(
        uint256[] calldata positionIds
    ) external view returns (Position[] memory positions);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ILendingPool
 * @dev Interface for a lending pool contract.
 */
interface ILendingPool {
    /**
     * @dev Emitted when a flash loan is executed.
     * @param sender The address initiating the flash loan.
     * @param recipient The address receiving the flash loan.
     * @param amount The amount of the flash loan.
     * @param paid The amount paid back after the flash loan.
     * @param paidToTakerPool The amount paid to the taker pool after the flash loan.
     * @param paidToMakerPool The amount paid to the maker pool after the flash loan.
     */
    event FlashLoan(
        address indexed sender,
        address indexed recipient,
        uint256 indexed amount,
        uint256 paid,
        uint256 paidToTakerPool,
        uint256 paidToMakerPool
    );

    /**
     * @dev Executes a flash loan.
     * @param token The address of the token for the flash loan.
     * @param amount The amount of the flash loan.
     * @param recipient The address to receive the flash loan.
     * @param data Additional data for the flash loan.
     */
    function flashLoan(
        address token,
        uint256 amount,
        address recipient,
        bytes calldata data
    ) external;

    /**
     * @notice Retrieves the pending share of earnings for a specific bin (subset) of funds in a market.
     * @param market The address of the market.
     * @param settlementToken The settlement token address.
     * @param binBalance The balance of funds in the bin.
     * @return The pending share of earnings for the specified bin.
     */
    function getPendingBinShare(
        address market,
        address settlementToken,
        uint256 binBalance
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title IVault
 * @dev Interface for the Vault contract, responsible for managing positions and liquidity.
 */
interface IVault {
    /**
     * @notice Emitted when a position is opened.
     * @param market The address of the market.
     * @param positionId The ID of the opened position.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param tradingFee The trading fee associated with the position.
     * @param protocolFee The protocol fee associated with the position.
     */
    event OnOpenPosition(
        address indexed market,
        uint256 indexed positionId,
        uint256 indexed takerMargin,
        uint256 tradingFee,
        uint256 protocolFee
    );

    /**
     * @notice Emitted when a position is claimed.
     * @param market The address of the market.
     * @param positionId The ID of the claimed position.
     * @param recipient The address of the recipient of the settlement amount.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param settlementAmount The settlement amount received by the recipient.
     */
    event OnClaimPosition(
        address indexed market,
        uint256 indexed positionId,
        address indexed recipient,
        uint256 takerMargin,
        uint256 settlementAmount
    );

    /**
     * @notice Emitted when liquidity is added to the vault.
     * @param market The address of the market.
     * @param amount The amount of liquidity added.
     */
    event OnAddLiquidity(address indexed market, uint256 indexed amount);

    /**
     * @notice Emitted when pending liquidity is settled.
     * @param market The address of the market.
     * @param pendingDeposit The amount of pending deposit being settled.
     * @param pendingWithdrawal The amount of pending withdrawal being settled.
     */
    event OnSettlePendingLiquidity(
        address indexed market,
        uint256 indexed pendingDeposit,
        uint256 indexed pendingWithdrawal
    );

    /**
     * @notice Emitted when liquidity is withdrawn from the vault.
     * @param market The address of the market.
     * @param amount The amount of liquidity withdrawn.
     * @param recipient The address of the recipient of the withdrawn liquidity.
     */
    event OnWithdrawLiquidity(
        address indexed market,
        uint256 indexed amount,
        address indexed recipient
    );

    /**
     * @notice Emitted when the keeper fee is transferred.
     * @param fee The amount of the transferred keeper fee as native token.
     * @param amount The amount of settlement token to be used for paying keeper fee.
     */
    event TransferKeeperFee(uint256 indexed fee, uint256 indexed amount);

    /**
     * @notice Emitted when the keeper fee is transferred for a specific market.
     * @param market The address of the market.
     * @param fee The amount of the transferred keeper fee as native token.
     * @param amount The amount of settlement token to be used for paying keeper fee.
     */
    event TransferKeeperFee(address indexed market, uint256 indexed fee, uint256 indexed amount);

    /**
     * @notice Emitted when the protocol fee is transferred for a specific position.
     * @param market The address of the market.
     * @param positionId The ID of the position.
     * @param amount The amount of the transferred fee.
     */
    event TransferProtocolFee(
        address indexed market,
        uint256 indexed positionId,
        uint256 indexed amount
    );

    /**
     * @notice Called when a position is opened by a market contract.
     * @param settlementToken The settlement token address.
     * @param positionId The ID of the opened position.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param tradingFee The trading fee associated with the position.
     * @param protocolFee The protocol fee associated with the position.
     */
    function onOpenPosition(
        address settlementToken,
        uint256 positionId,
        uint256 takerMargin,
        uint256 tradingFee,
        uint256 protocolFee
    ) external;

    /**
     * @notice Called when a position is claimed by a market contract.
     * @param settlementToken The settlement token address.
     * @param positionId The ID of the claimed position.
     * @param recipient The address that will receive the settlement amount.
     * @param takerMargin The margin amount provided by the taker for the position.
     * @param settlementAmount The amount to be settled for the position.
     */
    function onClaimPosition(
        address settlementToken,
        uint256 positionId,
        address recipient,
        uint256 takerMargin,
        uint256 settlementAmount
    ) external;

    /**
     * @notice Called when liquidity is added to the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param amount The amount of liquidity being added.
     */
    function onAddLiquidity(address settlementToken, uint256 amount) external;

    /**
     * @notice Called when pending liquidity is settled in the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param pendingDeposit The amount of pending deposits being settled.
     * @param pendingWithdrawal The amount of pending withdrawals being settled.
     */
    function onSettlePendingLiquidity(
        address settlementToken,
        uint256 pendingDeposit,
        uint256 pendingWithdrawal
    ) external;

    /**
     * @notice Called when liquidity is withdrawn from the vault by a market contract.
     * @param settlementToken The settlement token address.
     * @param recipient The address that will receive the withdrawn liquidity.
     * @param amount The amount of liquidity to be withdrawn.
     */
    function onWithdrawLiquidity(
        address settlementToken,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Transfers the keeper fee from the market to the specified keeper.
     * @param settlementToken The settlement token address.
     * @param keeper The address of the keeper to receive the fee.
     * @param fee The amount of the fee to transfer as native token.
     * @param margin The margin amount used for the fee payment.
     * @return usedFee The actual settlement token amount of fee used for the transfer.
     */
    function transferKeeperFee(
        address settlementToken,
        address keeper,
        uint256 fee,
        uint256 margin
    ) external returns (uint256 usedFee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IWETH9} from "@chromatic-protocol/contracts/core/interfaces/IWETH9.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";

/**
 * @title KeeperFeePayer
 * @dev A contract that pays keeper fees using a Uniswap router.
 */
contract KeeperFeePayer is IKeeperFeePayer {
    IChromaticMarketFactory factory;
    ISwapRouter uniswapRouter;
    IWETH9 public WETH9;

    error OnlyAccessableByDao();
    error OnlyAccessableByFactoryOrDao();
    error KeeperFeeTransferFailure();
    error InvalidSwapValue();

    /**
     * @dev Modifier to restrict access to only the DAO.
     */
    modifier onlyDao() {
        if (msg.sender != factory.dao()) revert OnlyAccessableByDao();
        _;
    }

    /**
     * @dev Modifier to restrict access to only the factory or the DAO.
     */
    modifier onlyFactoryOrDao() {
        if (msg.sender != address(factory) && msg.sender != factory.dao())
            revert OnlyAccessableByFactoryOrDao();
        _;
    }

    /**
     * @dev Constructor function.
     * @param _factory The address of the ChromaticMarketFactory contract.
     * @param _uniswapRouter The address of the Uniswap router contract.
     * @param _weth The address of the WETH9 contract.
     */
    constructor(IChromaticMarketFactory _factory, ISwapRouter _uniswapRouter, IWETH9 _weth) {
        factory = _factory;
        uniswapRouter = _uniswapRouter;
        WETH9 = _weth;
    }

    /**
     * @dev Sets the Uniswap router address.
     * @param _uniswapRouter The address of the Uniswap router contract.
     * @notice Only the DAO can call this function.
     */
    function setRouter(ISwapRouter _uniswapRouter) public onlyDao {
        uniswapRouter = _uniswapRouter;
        emit SetRouter(address(uniswapRouter));
    }

    /**
     * @inheritdoc IKeeperFeePayer
     * @dev Only the factory or the DAO can call this function.
     */
    function approveToRouter(address token, bool approve) external onlyFactoryOrDao {
        IERC20(token).approve(address(uniswapRouter), approve ? type(uint256).max : 0);
    }

    /**
     * @inheritdoc IKeeperFeePayer
     * @dev Only the Vault can call this function.
     */
    function payKeeperFee(
        address tokenIn,
        uint256 amountOut,
        address keeperAddress
    ) external returns (uint256 amountIn) {
        uint256 balance = IERC20(tokenIn).balanceOf(address(this));

        amountIn = swapExactOutput(tokenIn, address(this), amountOut, balance);

        // unwrap
        WETH9.withdraw(amountOut);

        // send eth to keeper
        (bool success, ) = keeperAddress.call{value: amountOut}("");
        if (!success) revert KeeperFeeTransferFailure();

        uint256 remainedBalance = IERC20(tokenIn).balanceOf(address(this));
        if (remainedBalance + amountIn < balance) revert InvalidSwapValue();

        SafeERC20.safeTransfer(IERC20(tokenIn), msg.sender, remainedBalance);
    }

    /**
     * @dev Executes a Uniswap swap with exact output amount.
     * @param tokenIn The address of the input token.
     * @param recipient The address that will receive the output tokens.
     * @param amountOut The desired amount of output tokens.
     * @param amountInMaximum The maximum amount of input tokens allowed for the swap.
     * @return amountIn The actual amount of input tokens used for the swap.
     */
    function swapExactOutput(
        address tokenIn,
        address recipient,
        uint256 amountOut,
        uint256 amountInMaximum
    ) internal returns (uint256 amountIn) {
        if (tokenIn == address(WETH9)) return amountOut;

        ISwapRouter.ExactOutputSingleParams memory swapParam = ISwapRouter.ExactOutputSingleParams(
            tokenIn,
            address(WETH9),
            factory.getUniswapFeeTier(tokenIn),
            recipient,
            block.timestamp,
            amountOut,
            amountInMaximum,
            0
        );
        return uniswapRouter.exactOutputSingle(swapParam);
    }

    /**
     * @dev Fallback function to receive ETH payments.
     */
    receive() external payable {}

    /**
     * @dev Fallback function to receive ETH payments.
     */
    fallback() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title BinMargin
 * @dev The BinMargin struct represents the margin information for an LP bin.
 */
struct BinMargin {
    /// @dev The trading fee rate associated with the LP bin
    uint16 tradingFeeRate;
    /// @dev The maker margin amount specified for the LP bin
    uint256 amount;
}

using BinMarginLib for BinMargin global;

/**
 * @title BinMarginLib
 * @dev The BinMarginLib library provides functions to operate on BinMargin structs.
 */
library BinMarginLib {
    using Math for uint256;

    uint256 constant TRADING_FEE_RATE_PRECISION = 10000;

    /**
     * @notice Calculates the trading fee based on the margin amount and the trading fee rate.
     * @param self The BinMargin struct
     * @param _feeProtocol The protocol fee for the market
     * @return The trading fee amount
     */
    function tradingFee(BinMargin memory self, uint8 _feeProtocol) internal pure returns (uint256) {
        uint256 _tradingFee = self.amount.mulDiv(self.tradingFeeRate, TRADING_FEE_RATE_PRECISION);
        return _tradingFee - _protocolFee(_tradingFee, _feeProtocol);
    }

    /**
     * @notice Calculates the protocol fee based on the margin amount and the trading fee rate.
     * @param self The BinMargin struct
     * @param _feeProtocol The protocol fee for the market
     * @return The protocol fee amount
     */
    function protocolFee(
        BinMargin memory self,
        uint8 _feeProtocol
    ) internal pure returns (uint256) {
        return
            _protocolFee(
                self.amount.mulDiv(self.tradingFeeRate, TRADING_FEE_RATE_PRECISION),
                _feeProtocol
            );
    }

    function _protocolFee(uint256 _tradingFee, uint8 _feeProtocol) private pure returns (uint256) {
        return _feeProtocol != 0 ? _tradingFee / _feeProtocol : 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {FEE_RATES_LENGTH} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";

/**
 * @title CLBTokenLib
 * @notice Provides utility functions for working with CLB tokens.
 */
library CLBTokenLib {
    using SignedMath for int256;
    using SafeCast for uint256;

    uint256 private constant DIRECTION_PRECISION = 10 ** 10;
    uint16 private constant MIN_FEE_RATE = 1;

    /**
     * @notice Encode the CLB token ID of ERC1155 token type
     * @dev If `tradingFeeRate` is negative, it adds `DIRECTION_PRECISION` to the absolute fee rate.
     *      Otherwise it returns the fee rate directly.
     * @return id The ID of ERC1155 token
     */
    function encodeId(int16 tradingFeeRate) internal pure returns (uint256) {
        bool long = tradingFeeRate > 0;
        return _encodeId(uint16(long ? tradingFeeRate : -tradingFeeRate), long);
    }

    /**
     * @notice Decode the trading fee rate from the CLB token ID of ERC1155 token type
     * @dev If `id` is greater than or equal to `DIRECTION_PRECISION`,
     *      then it substracts `DIRECTION_PRECISION` from `id`
     *      and returns the negation of the substracted value.
     *      Otherwise it returns `id` directly.
     * @return tradingFeeRate The trading fee rate
     */
    function decodeId(uint256 id) internal pure returns (int16 tradingFeeRate) {
        if (id >= DIRECTION_PRECISION) {
            tradingFeeRate = -int16((id - DIRECTION_PRECISION).toUint16());
        } else {
            tradingFeeRate = int16(id.toUint16());
        }
    }

    /**
     * @notice Retrieves the array of supported trading fee rates.
     * @dev This function returns the array of supported trading fee rates,
     *      ranging from the minimum fee rate to the maximum fee rate with step increments.
     * @return tradingFeeRates The array of supported trading fee rates.
     */
    function tradingFeeRates() internal pure returns (uint16[FEE_RATES_LENGTH] memory) {
        // prettier-ignore
        return [
            MIN_FEE_RATE, 2, 3, 4, 5, 6, 7, 8, 9, // 0.01% ~ 0.09%, step 0.01%
            10, 20, 30, 40, 50, 60, 70, 80, 90, // 0.1% ~ 0.9%, step 0.1%
            100, 200, 300, 400, 500, 600, 700, 800, 900, // 1% ~ 9%, step 1%
            1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000 // 10% ~ 50%, step 5%
        ];
    }

    function tokenIds() internal pure returns (uint256[] memory) {
        uint16[FEE_RATES_LENGTH] memory feeRates = tradingFeeRates();

        uint256[] memory ids = new uint256[](FEE_RATES_LENGTH * 2);
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            ids[i] = _encodeId(feeRates[i], true);
            ids[i + FEE_RATES_LENGTH] = _encodeId(feeRates[i], false);

            unchecked {
                i++;
            }
        }

        return ids;
    }

    function _encodeId(uint16 tradingFeeRate, bool long) private pure returns (uint256 id) {
        id = long ? tradingFeeRate : tradingFeeRate + DIRECTION_PRECISION;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

uint256 constant BPS = 10000;
uint256 constant FEE_RATES_LENGTH = 36;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {CLBToken} from "@chromatic-protocol/contracts/core/CLBToken.sol";

/**
 * @title CLBTokenDeployerLib
 * @notice Library for deploying CLB tokens
 */
library CLBTokenDeployerLib {
    /**
     * @notice Deploys a new CLB token
     * @return clbToken The address of the deployed CLB token
     */
    function deploy() external returns (address clbToken) {
        clbToken = address(new CLBToken());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import {IDiamondCut} from "@chromatic-protocol/contracts/core/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "@chromatic-protocol/contracts/core/interfaces/IDiamondLoupe.sol";
import {IMarketState} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketState.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {IMarketTrade} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketTrade.sol";
import {IMarketLiquidate} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidate.sol";
import {IMarketSettle} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketSettle.sol";
import {ChromaticMarket} from "@chromatic-protocol/contracts/core/ChromaticMarket.sol";

/**
 * @title MarketDeployer
 * @notice Storage struct for deploying a ChromaticMarket contract
 */
struct MarketDeployer {
    Parameters parameters;
}

/**
 * @title Parameters
 * @notice Struct for storing deployment parameters
 */
struct Parameters {
    address oracleProvider;
    address settlementToken;
}

/**
 * @title MarketDeployerLib
 * @notice Library for deploying a ChromaticMarket contract
 */
library MarketDeployerLib {
    /**
     * @notice Deploys a ChromaticMarket contract
     * @param self The MarketDeployer storage
     * @param oracleProvider The address of the oracle provider
     * @param settlementToken The address of the settlement token
     * @param marketDiamondCutFacet The market diamond cut facet address.
     * @param marketLoupeFacet The market loupe facet address.
     * @param marketStateFacet The market state facet address.
     * @param marketLiquidityFacet The market liquidity facet address.
     * @param marketTradeFacet The market trade facet address.
     * @param marketLiquidateFacet The market liquidate facet address.
     * @param marketSettleFacet The market settle facet address.
     * @return market The address of the deployed ChromaticMarket contract
     */
    function deploy(
        MarketDeployer storage self,
        address oracleProvider,
        address settlementToken,
        address marketDiamondCutFacet,
        address marketLoupeFacet,
        address marketStateFacet,
        address marketLiquidityFacet,
        address marketTradeFacet,
        address marketLiquidateFacet,
        address marketSettleFacet
    ) external returns (address market) {
        self.parameters = Parameters({
            oracleProvider: oracleProvider,
            settlementToken: settlementToken
        });
        market = address(
            new ChromaticMarket{salt: keccak256(abi.encode(oracleProvider, settlementToken))}(
                marketDiamondCutFacet
            )
        );
        delete self.parameters;

        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](6);
        cut[0] = _marketLoupeFacetCut(marketLoupeFacet);
        cut[1] = _marketStateFacetCut(marketStateFacet);
        cut[2] = _marketLiquidityFacetCut(marketLiquidityFacet);
        cut[3] = _marketTradeFacetCut(marketTradeFacet);
        cut[4] = _marketLiquidateFacetCut(marketLiquidateFacet);
        cut[5] = _marketSettleFacetCut(marketSettleFacet);
        IDiamondCut(market).diamondCut(cut, address(0), "");
    }

    function _marketLoupeFacetCut(
        address marketLoupeFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](4);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketStateFacetCut(
        address marketStateFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](9);
        functionSelectors[0] = IMarketState.factory.selector;
        functionSelectors[1] = IMarketState.settlementToken.selector;
        functionSelectors[2] = IMarketState.oracleProvider.selector;
        functionSelectors[3] = IMarketState.clbToken.selector;
        functionSelectors[4] = IMarketState.liquidator.selector;
        functionSelectors[5] = IMarketState.vault.selector;
        functionSelectors[6] = IMarketState.keeperFeePayer.selector;
        functionSelectors[7] = IMarketState.feeProtocol.selector;
        functionSelectors[8] = IMarketState.setFeeProtocol.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketStateFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketLiquidityFacetCut(
        address marketLiquidityFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](18);
        functionSelectors[0] = IMarketLiquidity.addLiquidity.selector;
        functionSelectors[1] = IMarketLiquidity.addLiquidityBatch.selector;
        functionSelectors[2] = IMarketLiquidity.claimLiquidity.selector;
        functionSelectors[3] = IMarketLiquidity.claimLiquidityBatch.selector;
        functionSelectors[4] = IMarketLiquidity.removeLiquidity.selector;
        functionSelectors[5] = IMarketLiquidity.removeLiquidityBatch.selector;
        functionSelectors[6] = IMarketLiquidity.withdrawLiquidity.selector;
        functionSelectors[7] = IMarketLiquidity.withdrawLiquidityBatch.selector;
        functionSelectors[8] = IMarketLiquidity.getBinLiquidity.selector;
        functionSelectors[9] = IMarketLiquidity.getBinFreeLiquidity.selector;
        functionSelectors[10] = IMarketLiquidity.getBinValues.selector;
        functionSelectors[11] = IMarketLiquidity.distributeEarningToBins.selector;
        functionSelectors[12] = IMarketLiquidity.getLpReceipt.selector;
        functionSelectors[13] = IMarketLiquidity.claimableLiquidity.selector;
        functionSelectors[14] = IMarketLiquidity.liquidityBinStatuses.selector;
        functionSelectors[15] = IERC1155Receiver.onERC1155Received.selector;
        functionSelectors[16] = IERC1155Receiver.onERC1155BatchReceived.selector;
        functionSelectors[17] = IERC165.supportsInterface.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketLiquidityFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketTradeFacetCut(
        address marketTradeFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](4);
        functionSelectors[0] = IMarketTrade.openPosition.selector;
        functionSelectors[1] = IMarketTrade.closePosition.selector;
        functionSelectors[2] = IMarketTrade.claimPosition.selector;
        functionSelectors[3] = IMarketTrade.getPositions.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketTradeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketLiquidateFacetCut(
        address marketLiquidateFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](4);
        functionSelectors[0] = IMarketLiquidate.checkLiquidation.selector;
        functionSelectors[1] = IMarketLiquidate.liquidate.selector;
        functionSelectors[2] = IMarketLiquidate.checkClaimPosition.selector;
        functionSelectors[3] = IMarketLiquidate.claimPosition.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketLiquidateFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }

    function _marketSettleFacetCut(
        address marketSettleFacet
    ) private pure returns (IDiamondCut.FacetCut memory cut) {
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IMarketSettle.settle.selector;

        cut = IDiamondCut.FacetCut({
            facetAddress: marketSettleFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/******************************************************************************\
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "@chromatic-protocol/contracts/core/interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

struct DiamondStorage {
    // maps function selectors to the facets that execute the functions.
    // and maps the selectors to their position in the selectorSlots array.
    // func selector => address facet, selector position
    mapping(bytes4 => bytes32) facets;
    // array of slots of function selectors.
    // each slot holds 8 function selectors.
    mapping(uint256 => bytes32) selectorSlots;
    // The number of function selectors in selectorSlots
    uint16 selectorCount;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) supportedInterfaces;
}

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library DiamondStorageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("protocol.chromatic.diamond.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "DiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "DiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "DiamondCut: Can't add function that already exists"
                );
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "DiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "DiamondCut: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "DiamondCut: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "DiamondCut: Can't replace function that doesn't exist"
                );
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "DiamondCut: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "DiamondCut: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "DiamondCut: Can't remove immutable function"
                    );
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("DiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "DiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

library Errors {
    string constant NOT_ENOUGH_FREE_LIQUIDITY = "NEFL";
    string constant TOO_SMALL_AMOUNT = "TSA";
    string constant INVALID_ORACLE_VERSION = "IOV";
    string constant EXCEED_MARGIN_RANGE = "IOV";
    string constant UNSUPPORTED_TRADING_FEE_RATE = "UTFR";
    string constant ALREADY_REGISTERED_ORACLE_PROVIDER = "ARO";
    string constant ALREADY_REGISTERED_TOKEN = "ART";
    string constant UNREGISTERED_TOKEN = "URT";
    string constant INTEREST_RATE_NOT_INITIALIZED = "IRNI";
    string constant INTEREST_RATE_OVERFLOW = "IROF";
    string constant INTEREST_RATE_PAST_TIMESTAMP = "IRPT";
    string constant INTEREST_RATE_NOT_APPENDABLE = "IRNA";
    string constant INTEREST_RATE_ALREADY_APPLIED = "IRAA";
    string constant UNSETTLED_POSITION = "USP";
    string constant INVALID_POSITION_QTY = "IPQ";
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BPS} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title InterestRate
 * @notice Provides functions for managing interest rates.
 * @dev The library allows for the initialization, appending, and removal of interest rate records,
 *      as well as calculating interest based on these records.
 */
library InterestRate {
    using Math for uint256;

    /// @dev Record type
    struct Record {
        /// @dev Annual interest rate in BPS
        uint256 annualRateBPS;
        /// @dev Timestamp when the interest rate becomes effective
        uint256 beginTimestamp;
    }

    uint256 private constant MAX_RATE_BPS = BPS; // max interest rate is 100%
    uint256 private constant YEAR = 365 * 24 * 3600;

    /**
     * @dev Ensure that the interest rate records have been initialized before certain functions can be called.
     *      It checks whether the length of the Record array is greater than 0.
     */
    modifier initialized(Record[] storage self) {
        require(self.length != 0, Errors.INTEREST_RATE_NOT_INITIALIZED);
        _;
    }

    /**
     * @notice Initialize the interest rate records.
     * @param self The stored record array
     * @param initialInterestRate The initial interest rate
     */
    function initialize(Record[] storage self, uint256 initialInterestRate) internal {
        self.push(Record({annualRateBPS: initialInterestRate, beginTimestamp: 0}));
    }

    /**
     * @notice Add a new interest rate record to the array.
     * @dev Annual rate is not greater than the maximum rate and that the begin timestamp is in the future,
     *      and the new record's begin timestamp is greater than the previous record's timestamp.
     * @param self The stored record array
     * @param annualRateBPS The annual interest rate in BPS
     * @param beginTimestamp Begin timestamp of this record
     */
    function appendRecord(
        Record[] storage self,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) internal initialized(self) {
        require(annualRateBPS <= MAX_RATE_BPS, Errors.INTEREST_RATE_OVERFLOW);
        require(beginTimestamp > block.timestamp, Errors.INTEREST_RATE_PAST_TIMESTAMP);

        Record memory lastRecord = self[self.length - 1];
        require(beginTimestamp > lastRecord.beginTimestamp, Errors.INTEREST_RATE_NOT_APPENDABLE);

        self.push(Record({annualRateBPS: annualRateBPS, beginTimestamp: beginTimestamp}));
    }

    /**
     * @notice Remove the last interest rate record from the array.
     * @dev The current time must be less than the begin timestamp of the last record.
     *      If the array has only one record, it returns false along with an empty record.
     *      Otherwise, it removes the last record from the array and returns true along with the removed record.
     * @param self The stored record array
     * @return removed Whether the last record is removed
     * @return record The removed record
     */
    function removeLastRecord(
        Record[] storage self
    ) internal initialized(self) returns (bool removed, Record memory record) {
        if (self.length <= 1) {
            // empty
            return (false, Record(0, 0));
        }

        Record memory lastRecord = self[self.length - 1];
        require(block.timestamp < lastRecord.beginTimestamp, Errors.INTEREST_RATE_ALREADY_APPLIED);

        self.pop();

        return (true, lastRecord);
    }

    /**
     * @notice Find the interest rate record that applies to a given timestamp.
     * @dev It iterates through the array from the end to the beginning
     *      and returns the first record with a begin timestamp less than or equal to the provided timestamp.
     * @param self The stored record array
     * @param timestamp Given timestamp
     * @return interestRate The record which is found
     * @return index The index of record
     */
    function findRecordAt(
        Record[] storage self,
        uint256 timestamp
    ) internal view initialized(self) returns (Record memory interestRate, uint256 index) {
        for (uint256 i = self.length; i != 0; ) {
            unchecked {
                index = i - 1;
            }
            interestRate = self[index];

            if (interestRate.beginTimestamp <= timestamp) {
                return (interestRate, index);
            }

            unchecked {
                i--;
            }
        }

        return (self[0], 0); // empty result (this line is not reachable)
    }

    /**
     * @notice Calculate the interest
     * @param self The stored record array
     * @param amount Token amount
     * @param from Begin timestamp (inclusive)
     * @param to End timestamp (exclusive)
     */
    function calculateInterest(
        Record[] storage self,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) internal view initialized(self) returns (uint256) {
        if (from >= to) {
            return 0;
        }

        uint256 interest = 0;

        uint256 endTimestamp = type(uint256).max;
        for (uint256 idx = self.length; idx != 0; ) {
            Record memory record = self[idx - 1];
            if (endTimestamp <= from) {
                break;
            }

            interest += _interest(
                amount,
                record.annualRateBPS,
                Math.min(to, endTimestamp) - Math.max(from, record.beginTimestamp)
            );
            endTimestamp = record.beginTimestamp;

            unchecked {
                idx--;
            }
        }
        return interest;
    }

    function _interest(
        uint256 amount,
        uint256 rateBPS, // annual rate
        uint256 period // in seconds
    ) private pure returns (uint256) {
        return amount.mulDiv(rateBPS * period, BPS * YEAR, Math.Rounding.Up);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";

/**
 * @title AccruedInterest
 * @notice Structure for tracking accumulated interest
 */
struct AccruedInterest {
    /// @dev The timestamp at which the interest was last accumulated.
    uint256 accumulatedAt;
    /// @dev The total amount of interest accumulated.
    uint256 accumulatedAmount;
}

/**
 * @title AccruedInterestLib
 * @notice Tracks the accumulated interest for a given token amount and period of time
 */
library AccruedInterestLib {
    /**
     * @notice Accumulates interest for a given token amount and period of time
     * @param self The AccruedInterest storage
     * @param ctx The LpContext instance for interest calculation
     * @param tokenAmount The amount of tokens to calculate interest for
     * @param until The timestamp until which interest should be accumulated
     */
    function accumulate(
        AccruedInterest storage self,
        LpContext memory ctx,
        uint256 tokenAmount,
        uint256 until
    ) internal {
        uint256 accumulatedAt = self.accumulatedAt;
        // check if the interest is already accumulated for the given period of time.
        if (until <= accumulatedAt) return;

        if (tokenAmount != 0) {
            // calculate the interest for the given period of time and accumulate it
            self.accumulatedAmount += ctx.calculateInterest(tokenAmount, accumulatedAt, until);
        }
        // update the timestamp at which the interest was last accumulated.
        self.accumulatedAt = until;
    }

    /**
     * @notice Deducts interest from the accumulated interest.
     * @param self The AccruedInterest storage.
     * @param amount The amount of interest to deduct.
     */
    function deduct(AccruedInterest storage self, uint256 amount) internal {
        uint256 accumulatedAmount = self.accumulatedAmount;
        // check if the amount is greater than the accumulated interest.
        if (amount >= accumulatedAmount) {
            self.accumulatedAmount = 0;
        } else {
            self.accumulatedAmount = accumulatedAmount - amount;
        }
    }

    /**
     * @notice Calculates the accumulated interest for a given token amount and period of time
     * @param self The AccruedInterest storage
     * @param ctx The LpContext instance for interest calculation
     * @param tokenAmount The amount of tokens to calculate interest for
     * @param until The timestamp until which interest should be accumulated
     * @return The accumulated interest amount
     */
    function calculateInterest(
        AccruedInterest storage self,
        LpContext memory ctx,
        uint256 tokenAmount,
        uint256 until
    ) internal view returns (uint256) {
        if (tokenAmount == 0) return 0;

        uint256 accumulatedAt = self.accumulatedAt;
        uint256 accumulatedAmount = self.accumulatedAmount;
        if (until <= accumulatedAt) return accumulatedAmount;

        return accumulatedAmount + ctx.calculateInterest(tokenAmount, accumulatedAt, until);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {BinClosingPosition, BinClosingPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinClosingPosition.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";

/**
 * @title BinClosedPosition
 * @notice Represents a closed position within an LiquidityBin.
 */
struct BinClosedPosition {
    uint256 _totalMakerMargin;
    BinClosingPosition _closing;
    EnumerableSet.UintSet _waitingVersions;
    mapping(uint256 => _ClaimWaitingPosition) _waitingPositions;
    AccruedInterest _accruedInterest;
}

/**
 * @title _ClaimWaitingPosition
 * @notice Represents the accumulated values of the waiting positions to be claimed
 *      for a specific version within BinClosedPosition.
 */
struct _ClaimWaitingPosition {
    int256 totalLeveragedQty;
    uint256 totalEntryAmount;
    uint256 totalMakerMargin;
    uint256 totalTakerMargin;
}

/**
 * @title BinClosedPositionLib
 * @notice A library that provides functions to manage the closed position within an LiquidityBin.
 */
library BinClosedPositionLib {
    using EnumerableSet for EnumerableSet.UintSet;
    using AccruedInterestLib for AccruedInterest;
    using BinClosingPositionLib for BinClosingPosition;

    /**
     * @notice Settles the closing position within the BinClosedPosition.
     * @dev If the closeVersion is not set or is equal to the current oracle version, no action is taken.
     *      Otherwise, the waiting position is stored and the accrued interest is accumulated.
     * @param self The BinClosedPosition storage.
     * @param ctx The LpContext memory.
     */
    function settleClosingPosition(BinClosedPosition storage self, LpContext memory ctx) internal {
        uint256 closeVersion = self._closing.closeVersion;
        if (!ctx.isPastVersion(closeVersion)) return;

        _ClaimWaitingPosition memory waitingPosition = _ClaimWaitingPosition({
            totalLeveragedQty: self._closing.totalLeveragedQty,
            totalEntryAmount: self._closing.totalEntryAmount,
            totalMakerMargin: self._closing.totalMakerMargin,
            totalTakerMargin: self._closing.totalTakerMargin
        });

        // accumulate interest before update `_totalMakerMargin`
        self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

        self._totalMakerMargin += waitingPosition.totalMakerMargin;
        self._waitingVersions.add(closeVersion);
        self._waitingPositions[closeVersion] = waitingPosition;

        self._closing.settleAccruedInterest(ctx);
        self._accruedInterest.accumulatedAmount += self._closing.accruedInterest.accumulatedAmount;

        delete self._closing;
    }

    /**
     * @notice Closes the position within the BinClosedPosition.
     * @dev Delegates the onClosePosition function call to the underlying BinClosingPosition.
     * @param self The BinClosedPosition storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     */
    function onClosePosition(
        BinClosedPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        self._closing.onClosePosition(ctx, param);
    }

    /**
     * @notice Claims the position within the BinClosedPosition.
     * @dev If the closeVersion is equal to the BinClosingPosition's closeVersion, the claim is made directly.
     *      Otherwise, the claim is made from the waiting position, and if exhausted, the waiting position is removed.
     *      The accrued interest is accumulated and deducted accordingly.
     * @param self The BinClosedPosition storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     */
    function onClaimPosition(
        BinClosedPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        uint256 closeVersion = param.closeVersion;

        if (closeVersion == self._closing.closeVersion) {
            self._closing.onClaimPosition(ctx, param);
        } else {
            bool exhausted = _onClaimPosition(self._waitingPositions[closeVersion], ctx, param);

            // accumulate interest before update `_totalMakerMargin`
            self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

            self._totalMakerMargin -= param.makerMargin;
            self._accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));

            if (exhausted) {
                self._waitingVersions.remove(closeVersion);
                delete self._waitingPositions[closeVersion];
            }
        }
    }

    /**
     * @dev Claims the position from the waiting position within the BinClosedPosition.
     *      Updates the waiting position and returns whether the waiting position is exhausted.
     * @param waitingPosition The waiting position storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     * @return exhausted Whether the waiting position is exhausted.
     */
    function _onClaimPosition(
        _ClaimWaitingPosition storage waitingPosition,
        LpContext memory ctx,
        PositionParam memory param
    ) private returns (bool exhausted) {
        int256 totalLeveragedQty = waitingPosition.totalLeveragedQty;
        int256 leveragedQty = param.leveragedQty;
        PositionUtil.checkRemovePositionQty(totalLeveragedQty, leveragedQty);
        if (totalLeveragedQty == leveragedQty) return true;

        waitingPosition.totalLeveragedQty = totalLeveragedQty - leveragedQty;
        waitingPosition.totalEntryAmount -= param.entryAmount(ctx);
        waitingPosition.totalMakerMargin -= param.makerMargin;
        waitingPosition.totalTakerMargin -= param.takerMargin;

        return false;
    }

    /**
     * @dev Calculates the current interest for a liquidity bin closed position.
     * @param self The BinClosedPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function currentInterest(
        BinClosedPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return _currentInterest(self, ctx) + self._closing.currentInterest(ctx);
    }

    /**
     * @dev Calculates the current interest for a liquidity bin closed position without closing position.
     * @param self The BinClosedPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function _currentInterest(
        BinClosedPosition storage self,
        LpContext memory ctx
    ) private view returns (uint256) {
        return
            self._accruedInterest.calculateInterest(ctx, self._totalMakerMargin, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title BinClosingPosition
 * @dev Represents the closing position within an LiquidityBin.
 */
struct BinClosingPosition {
    /// @dev The oracle version when the position was closed.
    uint256 closeVersion;
    /// @dev The total leveraged quantity of the closing position.
    int256 totalLeveragedQty;
    /// @dev The total entry amount of the closing position.
    uint256 totalEntryAmount;
    /// @dev The total maker margin of the closing position.
    uint256 totalMakerMargin;
    /// @dev The total taker margin of the closing position.
    uint256 totalTakerMargin;
    /// @dev The accumulated interest of the closing position.
    AccruedInterest accruedInterest;
}

/**
 * @title BinClosingPositionLib
 * @notice A library that provides functions to manage the closing position within an LiquidityBin.
 */
library BinClosingPositionLib {
    using AccruedInterestLib for AccruedInterest;

    /**
     * @notice Settles the accumulated interest of the closing position.
     * @param self The BinClosingPosition storage.
     * @param ctx The LpContext.
     */
    function settleAccruedInterest(BinClosingPosition storage self, LpContext memory ctx) internal {
        self.accruedInterest.accumulate(ctx, self.totalMakerMargin, block.timestamp);
    }

    /**
     * @notice Handles the closing of a position.
     * @param self The BinClosingPosition storage.
     * @param ctx The LpContext.
     * @param param The position parameters.
     */
    function onClosePosition(
        BinClosingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        uint256 closeVersion = self.closeVersion;
        require(
            closeVersion == 0 || closeVersion == param.closeVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        int256 totalLeveragedQty = self.totalLeveragedQty;
        int256 leveragedQty = param.leveragedQty;
        PositionUtil.checkAddPositionQty(totalLeveragedQty, leveragedQty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.closeVersion = param.closeVersion;
        self.totalLeveragedQty = totalLeveragedQty + leveragedQty;
        self.totalEntryAmount += param.entryAmount(ctx);
        self.totalMakerMargin += param.makerMargin;
        self.totalTakerMargin += param.takerMargin;
        self.accruedInterest.accumulatedAmount += param.calculateInterest(ctx, block.timestamp);
    }

    /**
     * @notice Handles the claiming of a position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @param param The position parameters.
     */
    function onClaimPosition(
        BinClosingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        require(self.closeVersion == param.closeVersion, Errors.INVALID_ORACLE_VERSION);

        int256 totalLeveragedQty = self.totalLeveragedQty;
        int256 leveragedQty = param.leveragedQty;
        PositionUtil.checkRemovePositionQty(totalLeveragedQty, leveragedQty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.totalLeveragedQty = totalLeveragedQty - leveragedQty;
        self.totalEntryAmount -= param.entryAmount(ctx);
        self.totalMakerMargin -= param.makerMargin;
        self.totalTakerMargin -= param.takerMargin;
        self.accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));
    }

    /**
     * @notice Calculates the current accrued interest of the closing position.
     * @param self The BinClosingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The current accrued interest.
     */
    function currentInterest(
        BinClosingPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return self.accruedInterest.calculateInterest(ctx, self.totalMakerMargin, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title BinLiquidity
 * @notice Represents the liquidity information within an LiquidityBin.
 */
struct BinLiquidity {
    uint256 total;
    _PendingLiquidity _pending;
    mapping(uint256 => _ClaimMinting) _claimMintings;
    mapping(uint256 => _ClaimBurning) _claimBurnings;
    DoubleEndedQueue.Bytes32Deque _burningVersions;
}

/**
 * @title _PendingLiquidity
 * @notice Represents the pending liquidity details within BinLiquidity.
 */
struct _PendingLiquidity {
    uint256 oracleVersion;
    uint256 tokenAmount;
    uint256 clbTokenAmount;
}

/**
 * @title _ClaimMinting
 * @notice Represents the accumulated values of minting claims
 *         for a specific oracle version within BinLiquidity.
 */
struct _ClaimMinting {
    uint256 tokenAmountRequested;
    uint256 clbTokenAmount;
}

/**
 * @title _ClaimBurning
 * @notice Represents the accumulated values of burning claims
 *         for a specific oracle version within BinLiquidity.
 */
struct _ClaimBurning {
    uint256 clbTokenAmountRequested;
    uint256 clbTokenAmount;
    uint256 tokenAmount;
}

/**
 * @title BinLiquidityLib
 * @notice A library that provides functions to manage the liquidity within an LiquidityBin.
 */
library BinLiquidityLib {
    using Math for uint256;
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    /// @dev Minimum amount constant to prevent division by zero.
    uint256 private constant MIN_AMOUNT = 1000;

    /**
     * @notice Settles the pending liquidity within the BinLiquidity.
     * @dev This function settles pending liquidity in the BinLiquidity storage by performing the following steps:
     *      1. Settles pending liquidity
     *          - If the pending oracle version is not set or is greater than or equal to the current oracle version,
     *            no action is taken.
     *          - Otherwise, the pending liquidity and burning CLB tokens are settled by following steps:
     *              a. If there is a pending deposit,
     *                 it calculates the minting amount of CLB tokens
     *                 based on the pending deposit, bin value, and CLB token total supply.
     *                 It updates the total liquidity and adds the pending deposit to the claim mintings.
     *              b. If there is a pending CLB token burning,
     *                 it adds the oracle version to the burning versions list
     *                 and initializes the claim burning details.
     *      2. Settles bunding CLB tokens
     *          a. It trims all completed burning versions from the burning versions list.
     *          b. For each burning version in the list,
     *             it calculates the pending CLB token amount and the pending withdrawal amount
     *             based on the bin value and CLB token total supply.
     *             - If there is sufficient free liquidity, it calculates the burning amount of CLB tokens.
     *             - If there is insufficient free liquidity, it calculates the burning amount
     *               based on the available free liquidity and updates the pending withdrawal accordingly.
     *          c. It updates the burning amount and pending withdrawal,
     *             and reduces the free liquidity accordingly.
     *          d. Finally, it updates the total liquidity by subtracting the pending withdrawal.
     *      And the CLB tokens are minted or burned accordingly.
     *      The pending deposit and withdrawal amounts are passed to the vault for further processing.
     * @param self The BinLiquidity storage.
     * @param ctx The LpContext memory.
     * @param binValue The current value of the bin.
     * @param freeLiquidity The amount of free liquidity available in the bin.
     * @param clbTokenId The ID of the CLB token.
     */
    function settlePendingLiquidity(
        BinLiquidity storage self,
        LpContext memory ctx,
        uint256 binValue,
        uint256 freeLiquidity,
        uint256 clbTokenId
    ) internal {
        ICLBToken clbToken = ctx.clbToken;
        uint256 totalSupply = clbToken.totalSupply(clbTokenId);

        (uint256 pendingDeposit, uint256 mintingAmount) = _settlePending(
            self,
            ctx,
            binValue,
            totalSupply
        );
        (uint256 burningAmount, uint256 pendingWithdrawal) = _settleBurning(
            self,
            freeLiquidity + pendingDeposit,
            binValue,
            totalSupply
        );

        if (mintingAmount > burningAmount) {
            clbToken.mint(ctx.market, clbTokenId, mintingAmount - burningAmount, bytes(""));
        } else if (mintingAmount < burningAmount) {
            clbToken.burn(ctx.market, clbTokenId, burningAmount - mintingAmount);
        }

        if (pendingDeposit != 0 || pendingWithdrawal != 0) {
            ctx.vault.onSettlePendingLiquidity(
                ctx.settlementToken,
                pendingDeposit,
                pendingWithdrawal
            );
        }
    }

    /**
     * @notice Adds liquidity to the BinLiquidity.
     * @dev Sets the pending liquidity with the specified amount and oracle version.
     *      If the amount is less than the minimum amount, it reverts with an error.
     *      If there is already pending liquidity with a different oracle version, it reverts with an error.
     * @param self The BinLiquidity storage.
     * @param amount The amount of tokens to add for liquidity.
     * @param oracleVersion The oracle version associated with the liquidity.
     */
    function onAddLiquidity(
        BinLiquidity storage self,
        uint256 amount,
        uint256 oracleVersion
    ) internal {
        require(amount > MIN_AMOUNT, Errors.TOO_SMALL_AMOUNT);

        uint256 pendingOracleVersion = self._pending.oracleVersion;
        require(
            pendingOracleVersion == 0 || pendingOracleVersion == oracleVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        self._pending.oracleVersion = oracleVersion;
        self._pending.tokenAmount += amount;
    }

    /**
     * @notice Claims liquidity from the BinLiquidity by minting CLB tokens.
     * @dev Retrieves the minting details for the specified oracle version
     *      and calculates the CLB token amount to be claimed.
     *      Updates the claim minting details and returns the CLB token amount to be claimed.
     *      If there are no more tokens remaining for the claim, it is removed from the mapping.
     * @param self The BinLiquidity storage.
     * @param amount The amount of tokens to claim.
     * @param oracleVersion The oracle version associated with the claim.
     * @return clbTokenAmount The amount of CLB tokens to be claimed.
     */
    function onClaimLiquidity(
        BinLiquidity storage self,
        uint256 amount,
        uint256 oracleVersion
    ) internal returns (uint256 clbTokenAmount) {
        _ClaimMinting memory _cm = self._claimMintings[oracleVersion];
        clbTokenAmount = amount.mulDiv(_cm.clbTokenAmount, _cm.tokenAmountRequested);

        _cm.clbTokenAmount -= clbTokenAmount;
        _cm.tokenAmountRequested -= amount;
        if (_cm.tokenAmountRequested == 0) {
            delete self._claimMintings[oracleVersion];
        } else {
            self._claimMintings[oracleVersion] = _cm;
        }
    }

    /**
     * @notice Removes liquidity from the BinLiquidity by setting pending CLB token amount.
     * @dev Sets the pending liquidity with the specified CLB token amount and oracle version.
     *      If there is already pending liquidity with a different oracle version, it reverts with an error.
     * @param self The BinLiquidity storage.
     * @param clbTokenAmount The amount of CLB tokens to remove liquidity.
     * @param oracleVersion The oracle version associated with the liquidity.
     */
    function onRemoveLiquidity(
        BinLiquidity storage self,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    ) internal {
        uint256 pendingOracleVersion = self._pending.oracleVersion;
        require(
            pendingOracleVersion == 0 || pendingOracleVersion == oracleVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        self._pending.oracleVersion = oracleVersion;
        self._pending.clbTokenAmount += clbTokenAmount;
    }

    /**
     * @notice Withdraws liquidity from the BinLiquidity by burning CLB tokens and withdrawing tokens.
     * @dev Retrieves the burning details for the specified oracle version
     *      and calculates the CLB token amount and token amount to burn and withdraw, respectively.
     *      Updates the claim burning details and returns the token amount to withdraw and the burned CLB token amount.
     *      If there are no more CLB tokens remaining for the claim, it is removed from the mapping.
     * @param self The BinLiquidity storage.
     * @param clbTokenAmount The amount of CLB tokens to withdraw.
     * @param oracleVersion The oracle version associated with the claim.
     * @return amount The amount of tokens to be withdrawn for the claim.
     * @return burnedCLBTokenAmount The amount of CLB tokens to be burned for the claim.
     */
    function onWithdrawLiquidity(
        BinLiquidity storage self,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    ) internal returns (uint256 amount, uint256 burnedCLBTokenAmount) {
        _ClaimBurning memory _cb = self._claimBurnings[oracleVersion];
        amount = clbTokenAmount.mulDiv(_cb.tokenAmount, _cb.clbTokenAmountRequested);
        burnedCLBTokenAmount = clbTokenAmount.mulDiv(
            _cb.clbTokenAmount,
            _cb.clbTokenAmountRequested
        );

        _cb.clbTokenAmount -= burnedCLBTokenAmount;
        _cb.tokenAmount -= amount;
        _cb.clbTokenAmountRequested -= clbTokenAmount;
        if (_cb.clbTokenAmountRequested == 0) {
            delete self._claimBurnings[oracleVersion];
        } else {
            self._claimBurnings[oracleVersion] = _cb;
        }
    }

    /**
     * @notice Calculates the amount of CLB tokens to be minted
     *         for a given token amount, bin value, and CLB token total supply.
     * @dev If the CLB token total supply is zero, returns the token amount as is.
     *      Otherwise, calculates the minting amount
     *      based on the token amount, bin value, and CLB token total supply.
     * @param amount The amount of tokens to be minted.
     * @param binValue The current bin value.
     * @param clbTokenTotalSupply The total supply of CLB tokens.
     * @return The amount of CLB tokens to be minted.
     */
    function calculateCLBTokenMinting(
        uint256 amount,
        uint256 binValue,
        uint256 clbTokenTotalSupply
    ) internal pure returns (uint256) {
        return
            clbTokenTotalSupply == 0
                ? amount
                : amount.mulDiv(clbTokenTotalSupply, binValue < MIN_AMOUNT ? MIN_AMOUNT : binValue);
    }

    /**
     * @notice Calculates the value of CLB tokens
     *         for a given CLB token amount, bin value, and CLB token total supply.
     * @dev If the CLB token total supply is zero, returns zero.
     *      Otherwise, calculates the value based on the CLB token amount, bin value, and CLB token total supply.
     * @param clbTokenAmount The amount of CLB tokens.
     * @param binValue The current bin value.
     * @param clbTokenTotalSupply The total supply of CLB tokens.
     * @return The value of the CLB tokens.
     */
    function calculateCLBTokenValue(
        uint256 clbTokenAmount,
        uint256 binValue,
        uint256 clbTokenTotalSupply
    ) internal pure returns (uint256) {
        return clbTokenTotalSupply == 0 ? 0 : clbTokenAmount.mulDiv(binValue, clbTokenTotalSupply);
    }

    /**
     * @dev Settles the pending deposit and pending CLB token burning.
     * @param self The BinLiquidity storage.
     * @param ctx The LpContext.
     * @param binValue The current value of the bin.
     * @param totalSupply The total supply of CLB tokens.
     * @return pendingDeposit The amount of pending deposit to be settled.
     * @return mintingAmount The calculated minting amount of CLB tokens for the pending deposit.
     */
    function _settlePending(
        BinLiquidity storage self,
        LpContext memory ctx,
        uint256 binValue,
        uint256 totalSupply
    ) private returns (uint256 pendingDeposit, uint256 mintingAmount) {
        uint256 oracleVersion = self._pending.oracleVersion;
        if (!ctx.isPastVersion(oracleVersion)) return (0, 0);

        pendingDeposit = self._pending.tokenAmount;
        uint256 pendingCLBTokenAmount = self._pending.clbTokenAmount;

        if (pendingDeposit != 0) {
            mintingAmount = calculateCLBTokenMinting(pendingDeposit, binValue, totalSupply);

            self.total += pendingDeposit;
            self._claimMintings[oracleVersion] = _ClaimMinting({
                tokenAmountRequested: pendingDeposit,
                clbTokenAmount: mintingAmount
            });
        }

        if (pendingCLBTokenAmount != 0) {
            self._burningVersions.pushBack(bytes32(oracleVersion));
            self._claimBurnings[oracleVersion] = _ClaimBurning({
                clbTokenAmountRequested: pendingCLBTokenAmount,
                clbTokenAmount: 0,
                tokenAmount: 0
            });
        }

        delete self._pending;
    }

    /**
     * @dev Settles the pending CLB token burning and calculates the burning amount and pending withdrawal.
     * @param self The BinLiquidity storage.
     * @param freeLiquidity The amount of free liquidity available for burning.
     * @param binValue The current value of the bin.
     * @param totalSupply The total supply of CLB tokens.
     * @return burningAmount The calculated burning amount of CLB tokens.
     * @return pendingWithdrawal The calculated pending withdrawal amount.
     */
    function _settleBurning(
        BinLiquidity storage self,
        uint256 freeLiquidity,
        uint256 binValue,
        uint256 totalSupply
    ) private returns (uint256 burningAmount, uint256 pendingWithdrawal) {
        // trim all claim completed burning versions
        while (!self._burningVersions.empty()) {
            uint256 _ov = uint256(self._burningVersions.front());
            _ClaimBurning memory _cb = self._claimBurnings[_ov];
            if (_cb.clbTokenAmount >= _cb.clbTokenAmountRequested) {
                self._burningVersions.popFront();
                if (_cb.clbTokenAmountRequested == 0) {
                    delete self._claimBurnings[_ov];
                }
            } else {
                break;
            }
        }

        uint256 length = self._burningVersions.length();
        for (uint256 i; i < length && freeLiquidity != 0; ) {
            uint256 _ov = uint256(self._burningVersions.at(i));
            _ClaimBurning storage _cb = self._claimBurnings[_ov];

            uint256 _pendingCLBTokenAmount = _cb.clbTokenAmountRequested - _cb.clbTokenAmount;
            if (_pendingCLBTokenAmount != 0) {
                uint256 _burningAmount;
                uint256 _pendingWithdrawal = calculateCLBTokenValue(
                    _pendingCLBTokenAmount,
                    binValue,
                    totalSupply
                );

                if (freeLiquidity >= _pendingWithdrawal) {
                    _burningAmount = _pendingCLBTokenAmount;
                } else {
                    _burningAmount = calculateCLBTokenMinting(freeLiquidity, binValue, totalSupply);
                    require(_burningAmount < _pendingCLBTokenAmount);
                    _pendingWithdrawal = freeLiquidity;
                }

                _cb.clbTokenAmount += _burningAmount;
                _cb.tokenAmount += _pendingWithdrawal;
                burningAmount += _burningAmount;
                pendingWithdrawal += _pendingWithdrawal;
                freeLiquidity -= _pendingWithdrawal;
            }

            unchecked {
                i++;
            }
        }

        self.total -= pendingWithdrawal;
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific oracle version.
     * @param self The reference to the BinLiquidity struct.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IMarketLiquidity.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        BinLiquidity storage self,
        uint256 oracleVersion
    ) internal view returns (IMarketLiquidity.ClaimableLiquidity memory) {
        _ClaimMinting memory _cm = self._claimMintings[oracleVersion];
        _ClaimBurning memory _cb = self._claimBurnings[oracleVersion];

        return
            IMarketLiquidity.ClaimableLiquidity({
                mintingTokenAmountRequested: _cm.tokenAmountRequested,
                mintingCLBTokenAmount: _cm.clbTokenAmount,
                burningCLBTokenAmountRequested: _cb.clbTokenAmountRequested,
                burningCLBTokenAmount: _cb.clbTokenAmount,
                burningTokenAmount: _cb.tokenAmount
            });
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {UFixed18} from "@equilibria/root/number/types/UFixed18.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title BinPendingPosition
 * @notice Represents a pending position within the LiquidityBin
 */
struct BinPendingPosition {
    /// @dev The oracle version when the position was opened.
    uint256 openVersion;
    /// @dev The total leveraged quantity of the pending position.
    int256 totalLeveragedQty;
    /// @dev The total maker margin of the pending position.
    uint256 totalMakerMargin;
    /// @dev The total taker margin of the pending position.
    uint256 totalTakerMargin;
    /// @dev The accumulated interest of the pending position.
    AccruedInterest accruedInterest;
}

/**
 * @title BinPendingPositionLib
 * @notice Library for managing pending positions in the `LiquidityBin`
 */
library BinPendingPositionLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using AccruedInterestLib for AccruedInterest;

    /**
     * @notice Settles the accumulated interest of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     */
    function settleAccruedInterest(BinPendingPosition storage self, LpContext memory ctx) internal {
        self.accruedInterest.accumulate(ctx, self.totalMakerMargin, block.timestamp);
    }

    /**
     * @notice Handles the opening of a position.
     * @param self The BinPendingPosition storage.
     * @param param The position parameters.
     */
    function onOpenPosition(
        BinPendingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        uint256 openVersion = self.openVersion;
        require(
            openVersion == 0 || openVersion == param.openVersion,
            Errors.INVALID_ORACLE_VERSION
        );

        int256 totalLeveragedQty = self.totalLeveragedQty;
        int256 leveragedQty = param.leveragedQty;
        PositionUtil.checkAddPositionQty(totalLeveragedQty, leveragedQty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.openVersion = param.openVersion;
        self.totalLeveragedQty = totalLeveragedQty + leveragedQty;
        self.totalMakerMargin += param.makerMargin;
        self.totalTakerMargin += param.takerMargin;
    }

    /**
     * @notice Handles the closing of a position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @param param The position parameters.
     */
    function onClosePosition(
        BinPendingPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        require(self.openVersion == param.openVersion, Errors.INVALID_ORACLE_VERSION);

        int256 totalLeveragedQty = self.totalLeveragedQty;
        int256 leveragedQty = param.leveragedQty;
        PositionUtil.checkRemovePositionQty(totalLeveragedQty, leveragedQty);

        // accumulate interest before update `totalMakerMargin`
        settleAccruedInterest(self, ctx);

        self.totalLeveragedQty = totalLeveragedQty - leveragedQty;
        self.totalMakerMargin -= param.makerMargin;
        self.totalTakerMargin -= param.takerMargin;
        self.accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));
    }

    /**
     * @notice Calculates the unrealized profit or loss (PnL) of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The unrealized PnL.
     */
    function unrealizedPnl(
        BinPendingPosition storage self,
        LpContext memory ctx
    ) internal view returns (int256) {
        uint256 openVersion = self.openVersion;
        if (!ctx.isPastVersion(openVersion)) return 0;

        IOracleProvider.OracleVersion memory currentVersion = ctx.currentOracleVersion();
        UFixed18 _entryPrice = PositionUtil.settlePrice(
            ctx.oracleProvider,
            openVersion,
            ctx.currentOracleVersion()
        );
        UFixed18 _exitPrice = PositionUtil.oraclePrice(currentVersion);

        int256 pnl = PositionUtil.pnl(self.totalLeveragedQty, _entryPrice, _exitPrice) +
            currentInterest(self, ctx).toInt256();
        uint256 absPnl = pnl.abs();

        if (pnl >= 0) {
            return Math.min(absPnl, self.totalTakerMargin).toInt256();
        } else {
            return -(Math.min(absPnl, self.totalMakerMargin).toInt256());
        }
    }

    /**
     * @notice Calculates the current accrued interest of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @return uint256 The current accrued interest.
     */
    function currentInterest(
        BinPendingPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return self.accruedInterest.calculateInterest(ctx, self.totalMakerMargin, block.timestamp);
    }

    /**
     * @notice Calculates the entry price of the pending position.
     * @param self The BinPendingPosition storage.
     * @param ctx The LpContext.
     * @return UFixed18 The entry price.
     */
    function entryPrice(
        BinPendingPosition storage self,
        LpContext memory ctx
    ) internal view returns (UFixed18) {
        return
            PositionUtil.settlePrice(
                ctx.oracleProvider,
                self.openVersion,
                ctx.currentOracleVersion()
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {UFixed18} from "@equilibria/root/number/types/UFixed18.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {AccruedInterest, AccruedInterestLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/AccruedInterest.sol";
import {BinPendingPosition, BinPendingPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinPendingPosition.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";

/**
 * @title BinPosition
 * @notice Represents a position in the LiquidityBin
 */
struct BinPosition {
    /// @dev The total leveraged quantity of the `LiquidityBin`
    int256 totalLeveragedQty;
    /// @dev The total entry amount of the `LiquidityBin`
    uint256 totalEntryAmount;
    /// @dev The total maker margin of the `LiquidityBin`
    uint256 _totalMakerMargin;
    /// @dev The total taker margin of the `LiquidityBin`
    uint256 _totalTakerMargin;
    /// @dev The pending position of the `LiquidityBin`
    BinPendingPosition _pending;
    /// @dev The accumulated interest of the `LiquidityBin`
    AccruedInterest _accruedInterest;
}

/**
 * @title BinPositionLib
 * @notice Library for managing positions in the `LiquidityBin`
 */
library BinPositionLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using AccruedInterestLib for AccruedInterest;
    using BinPendingPositionLib for BinPendingPosition;

    /**
     * @notice Settles pending positions for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     */
    function settlePendingPosition(BinPosition storage self, LpContext memory ctx) internal {
        uint256 openVersion = self._pending.openVersion;
        if (!ctx.isPastVersion(openVersion)) return;

        // accumulate interest before update `_totalMakerMargin`
        self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

        int256 pendingQty = self._pending.totalLeveragedQty;
        self.totalLeveragedQty += pendingQty;
        self.totalEntryAmount += PositionUtil.transactionAmount(
            pendingQty,
            self._pending.entryPrice(ctx)
        );
        self._totalMakerMargin += self._pending.totalMakerMargin;
        self._totalTakerMargin += self._pending.totalTakerMargin;

        self._pending.settleAccruedInterest(ctx);
        self._accruedInterest.accumulatedAmount += self._pending.accruedInterest.accumulatedAmount;

        delete self._pending;
    }

    /**
     * @notice Handles the opening of a position for a liquidity bin.
     * @param self The BinPosition storage.
     * @param ctx The LpContext data struct.
     * @param param The PositionParam containing the position parameters.
     */
    function onOpenPosition(
        BinPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        self._pending.onOpenPosition(ctx, param);
    }

    /**
     * @notice Handles the closing of a position for a liquidity bin.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @param param The PositionParam data struct containing the position parameters.
     */
    function onClosePosition(
        BinPosition storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal {
        if (param.openVersion == self._pending.openVersion) {
            self._pending.onClosePosition(ctx, param);
        } else {
            int256 totalLeveragedQty = self.totalLeveragedQty;
            int256 leveragedQty = param.leveragedQty;
            PositionUtil.checkRemovePositionQty(totalLeveragedQty, leveragedQty);

            // accumulate interest before update `_totalMakerMargin`
            self._accruedInterest.accumulate(ctx, self._totalMakerMargin, block.timestamp);

            self.totalLeveragedQty = totalLeveragedQty - leveragedQty;
            self.totalEntryAmount -= param.entryAmount(ctx);
            self._totalMakerMargin -= param.makerMargin;
            self._totalTakerMargin -= param.takerMargin;
            self._accruedInterest.deduct(param.calculateInterest(ctx, block.timestamp));
        }
    }

    /**
     * @notice Returns the total maker margin for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @return uint256 The total maker margin.
     */
    function totalMakerMargin(BinPosition storage self) internal view returns (uint256) {
        return self._totalMakerMargin + self._pending.totalMakerMargin;
    }

    /**
     * @notice Returns the total taker margin for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @return uint256 The total taker margin.
     */
    function totalTakerMargin(BinPosition storage self) internal view returns (uint256) {
        return self._totalTakerMargin + self._pending.totalTakerMargin;
    }

    /**
     * @notice Calculates the unrealized profit or loss for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return int256 The unrealized profit or loss.
     */
    function unrealizedPnl(
        BinPosition storage self,
        LpContext memory ctx
    ) internal view returns (int256) {
        IOracleProvider.OracleVersion memory currentVersion = ctx.currentOracleVersion();

        int256 leveragedQty = self.totalLeveragedQty;
        int256 sign = leveragedQty < 0 ? int256(-1) : int256(1);
        UFixed18 exitPrice = PositionUtil.oraclePrice(currentVersion);

        int256 entryAmount = self.totalEntryAmount.toInt256() * sign;
        int256 exitAmount = PositionUtil.transactionAmount(leveragedQty, exitPrice).toInt256() *
            sign;

        int256 rawPnl = exitAmount - entryAmount;
        int256 pnl = rawPnl +
            self._pending.unrealizedPnl(ctx) +
            _currentInterest(self, ctx).toInt256();
        uint256 absPnl = pnl.abs();

        if (pnl >= 0) {
            return Math.min(absPnl, totalTakerMargin(self)).toInt256();
        } else {
            return -(Math.min(absPnl, totalMakerMargin(self)).toInt256());
        }
    }

    /**
     * @dev Calculates the current interest for a liquidity bin position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function currentInterest(
        BinPosition storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return _currentInterest(self, ctx) + self._pending.currentInterest(ctx);
    }

    /**
     * @dev Calculates the current interest for a liquidity bin position without pending position.
     * @param self The BinPosition storage struct.
     * @param ctx The LpContext data struct.
     * @return uint256 The current interest.
     */
    function _currentInterest(
        BinPosition storage self,
        LpContext memory ctx
    ) private view returns (uint256) {
        return
            self._accruedInterest.calculateInterest(ctx, self._totalMakerMargin, block.timestamp);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {BinLiquidity, BinLiquidityLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinLiquidity.sol";
import {BinPosition, BinPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinPosition.sol";
import {BinClosedPosition, BinClosedPositionLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/BinClosedPosition.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";
/**
 * @title LiquidityBin
 * @notice Structure representing a liquidity bin
 */
struct LiquidityBin {
    /// @dev The ID of the CLB token
    uint256 clbTokenId;
    /// @dev The liquidity data for the bin
    BinLiquidity _liquidity;
    /// @dev The position data for the bin
    BinPosition _position;
    /// @dev The closed position data for the bin
    BinClosedPosition _closedPosition;
}

/**
 * @title LiquidityBinLib
 * @notice Library for managing liquidity bin
 */
library LiquidityBinLib {
    using Math for uint256;
    using SignedMath for int256;
    using LiquidityBinLib for LiquidityBin;
    using BinLiquidityLib for BinLiquidity;
    using BinPositionLib for BinPosition;
    using BinClosedPositionLib for BinClosedPosition;

    /**
     * @notice Modifier to settle the pending positions, closing positions,
     *         and pending liquidity of the bin before executing a function.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext data struct.
     */
    modifier _settle(LiquidityBin storage self, LpContext memory ctx) {
        self.settle(ctx);
        _;
    }

    /**
     * @notice Settles the pending positions, closing positions, and pending liquidity of the bin.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext data struct.
     */
    function settle(LiquidityBin storage self, LpContext memory ctx) internal {
        self._closedPosition.settleClosingPosition(ctx);
        self._position.settlePendingPosition(ctx);
        self._liquidity.settlePendingLiquidity(
            ctx,
            self.value(ctx),
            self.freeLiquidity(),
            self.clbTokenId
        );
    }

    /**
     * @notice Initializes the liquidity bin with the given trading fee rate
     * @param self The LiquidityBin storage
     * @param tradingFeeRate The trading fee rate to set
     */
    function initialize(LiquidityBin storage self, int16 tradingFeeRate) internal {
        self.clbTokenId = CLBTokenLib.encodeId(tradingFeeRate);
    }

    /**
     * @notice Opens a new position in the liquidity bin
     * @param self The LiquidityBin storage
     * @param ctx The LpContext data struct
     * @param param The position parameters
     * @param tradingFee The trading fee amount
     */
    function openPosition(
        LiquidityBin storage self,
        LpContext memory ctx,
        PositionParam memory param,
        uint256 tradingFee
    ) internal _settle(self, ctx) {
        require(param.makerMargin <= self.freeLiquidity(), Errors.NOT_ENOUGH_FREE_LIQUIDITY);

        self._position.onOpenPosition(ctx, param);
        self._liquidity.total += tradingFee;
    }

    /**
     * @notice Closes a position in the liquidity bin
     * @param self The LiquidityBin storage
     * @param ctx The LpContext data struct
     * @param param The position parameters
     */
    function closePosition(
        LiquidityBin storage self,
        LpContext memory ctx,
        PositionParam memory param
    ) internal _settle(self, ctx) {
        self._position.onClosePosition(ctx, param);
        if (param.closeVersion > param.openVersion) {
            self._closedPosition.onClosePosition(ctx, param);
        }
    }

    /**
     * @notice Claims an existing liquidity position in the bin.
     * @dev This function claims the position using the specified parameters
     *      and updates the total by subtracting the absolute value
     *      of the taker's profit or loss (takerPnl) from it.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param param The PositionParam memory.
     * @param takerPnl The taker's profit/loss.
     */
    function claimPosition(
        LiquidityBin storage self,
        LpContext memory ctx,
        PositionParam memory param,
        int256 takerPnl
    ) internal _settle(self, ctx) {
        if (param.closeVersion == 0) {
            // called when liquidate
            self._position.onClosePosition(ctx, param);
        } else if (param.closeVersion > param.openVersion) {
            self._closedPosition.onClaimPosition(ctx, param);
        }

        uint256 absTakerPnl = takerPnl.abs();
        if (takerPnl < 0) {
            self._liquidity.total += absTakerPnl;
        } else {
            self._liquidity.total -= absTakerPnl;
        }
    }

    /**
     * @notice Retrieves the total liquidity in the bin
     * @param self The LiquidityBin storage
     * @return uint256 The total liquidity in the bin
     */
    function liquidity(LiquidityBin storage self) internal view returns (uint256) {
        return self._liquidity.total;
    }

    /**
     * @notice Retrieves the free liquidity in the bin (liquidity minus total maker margin)
     * @param self The LiquidityBin storage
     * @return uint256 The free liquidity in the bin
     */
    function freeLiquidity(LiquidityBin storage self) internal view returns (uint256) {
        return self._liquidity.total - self._position.totalMakerMargin();
    }

    /**
     * @notice Applies earnings to the liquidity bin
     * @param self The LiquidityBin storage
     * @param earning The earning amount to apply
     */
    function applyEarning(LiquidityBin storage self, uint256 earning) internal {
        self._liquidity.total += earning;
    }

    /**
     * @notice Calculates the value of the bin.
     * @dev This function considers the unrealized profit or loss of the position
     *      and adds it to the total value.
     *      Additionally, it includes the pending bin share from the market's vault.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @return uint256 The value of the bin.
     */
    function value(
        LiquidityBin storage self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        int256 unrealizedPnl = self._position.unrealizedPnl(ctx);

        uint256 absPnl = unrealizedPnl.abs();

        uint256 _liquidity = self.liquidity();
        uint256 _value = unrealizedPnl < 0 ? _liquidity - absPnl : _liquidity + absPnl;
        return
            _value +
            self._closedPosition.currentInterest(ctx) +
            ctx.vault.getPendingBinShare(ctx.market, ctx.settlementToken, _liquidity);
    }

    /**
     * @notice Accepts an add liquidity request.
     * @dev This function adds liquidity to the bin by calling the `onAddLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param amount The amount of liquidity to add.
     */
    function acceptAddLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 amount
    ) internal _settle(self, ctx) {
        self._liquidity.onAddLiquidity(amount, ctx.currentOracleVersion().version);
    }

    /**
     * @notice Accepts a claim liquidity request.
     * @dev This function claims liquidity from the bin by calling the `onClaimLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param amount The amount of liquidity to claim.
     *        (should be the same as the one used in acceptAddLiquidity)
     * @param oracleVersion The oracle version used for the claim.
     *        (should be the oracle version when call acceptAddLiquidity)
     * @return The amount of liquidity (CLB tokens) received as a result of the liquidity claim.
     */
    function acceptClaimLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 amount,
        uint256 oracleVersion
    ) internal _settle(self, ctx) returns (uint256) {
        return self._liquidity.onClaimLiquidity(amount, oracleVersion);
    }

    /**
     * @notice Accepts a remove liquidity request.
     * @dev This function removes liquidity from the bin by calling the `onRemoveLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param clbTokenAmount The amount of CLB tokens to remove.
     */
    function acceptRemoveLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 clbTokenAmount
    ) internal _settle(self, ctx) {
        self._liquidity.onRemoveLiquidity(clbTokenAmount, ctx.currentOracleVersion().version);
    }

    /**
     * @notice Accepts a withdraw liquidity request.
     * @dev This function withdraws liquidity from the bin by calling the `onWithdrawLiquidity` function
     *      of the liquidity component.
     * @param self The LiquidityBin storage.
     * @param ctx The LpContext memory.
     * @param clbTokenAmount The amount of CLB tokens to withdraw.
     *        (should be the same as the one used in acceptRemoveLiquidity)
     * @param oracleVersion The oracle version used for the withdrawal.
     *        (should be the oracle version when call acceptRemoveLiquidity)
     * @return amount The amount of liquidity withdrawn
     * @return burnedCLBTokenAmount The amount of CLB tokens burned during the withdrawal.
     */
    function acceptWithdrawLiquidity(
        LiquidityBin storage self,
        LpContext memory ctx,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    ) internal _settle(self, ctx) returns (uint256 amount, uint256 burnedCLBTokenAmount) {
        return self._liquidity.onWithdrawLiquidity(clbTokenAmount, oracleVersion);
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific oracle version from a LiquidityBin.
     * @param self The reference to the LiquidityBin struct.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IMarketLiquidity.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        LiquidityBin storage self,
        uint256 oracleVersion
    ) internal view returns (IMarketLiquidity.ClaimableLiquidity memory) {
        return self._liquidity.claimableLiquidity(oracleVersion);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IMarketLiquidity} from "@chromatic-protocol/contracts/core/interfaces/market/IMarketLiquidity.sol";
import {LiquidityBin, LiquidityBinLib} from "@chromatic-protocol/contracts/core/libraries/liquidity/LiquidityBin.sol";
import {PositionParam} from "@chromatic-protocol/contracts/core/libraries/liquidity/PositionParam.sol";
import {FEE_RATES_LENGTH} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title LiquidityPool
 * @notice Represents a collection of long and short liquidity bins
 */
struct LiquidityPool {
    mapping(uint16 => LiquidityBin) _longBins;
    mapping(uint16 => LiquidityBin) _shortBins;
}

using LiquidityPoolLib for LiquidityPool global;

/**
 * @title LiquidityPoolLib
 * @notice Library for managing liquidity bins in an LiquidityPool
 */
library LiquidityPoolLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;
    using LiquidityBinLib for LiquidityBin;

    /**
     * @notice Emitted when earning is accumulated for a liquidity bin.
     * @param feeRate The fee rate of the bin.
     * @param binType The type of the bin ("L" for long, "S" for short).
     * @param earning The accumulated earning.
     */
    event LiquidityBinEarningAccumulated(
        uint16 indexed feeRate,
        bytes1 indexed binType,
        uint256 indexed earning
    );

    struct _proportionalPositionParamValue {
        int256 leveragedQty;
        uint256 takerMargin;
    }

    /**
     * @notice Modifier to validate the trading fee rate.
     * @param tradingFeeRate The trading fee rate to validate.
     */
    modifier _validTradingFeeRate(int16 tradingFeeRate) {
        validateTradingFeeRate(tradingFeeRate);

        _;
    }

    /**
     * @notice Initializes the LiquidityPool.
     * @param self The reference to the LiquidityPool.
     */
    function initialize(LiquidityPool storage self) internal {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 feeRate = _tradingFeeRates[i];
            self._longBins[feeRate].initialize(int16(feeRate));
            self._shortBins[feeRate].initialize(-int16(feeRate));

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Settles the liquidity bins in the LiquidityPool.
     * @param self The reference to the LiquidityPool.
     * @param ctx The LpContext object.
     */
    function settle(LiquidityPool storage self, LpContext memory ctx) internal {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 feeRate = _tradingFeeRates[i];
            self._longBins[feeRate].settle(ctx);
            self._shortBins[feeRate].settle(ctx);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Prepares bin margins based on the given quantity and maker margin.
     * @dev This function prepares bin margins by performing the following steps:
     *      1. Calculates the appropriate bin margins
     *         for each trading fee rate based on the provided quantity and maker margin.
     *      2. Iterates through the target bins based on the quantity,
     *         finds the minimum available fee rate,
     *         and determines the upper bound for calculating bin margins.
     *      3. Iterates from the minimum fee rate until the upper bound,
     *         assigning the remaining maker margin to the bins until it is exhausted.
     *      4. Creates an array of BinMargin structs
     *         containing the trading fee rate and corresponding margin amount for each bin.
     * @param self The reference to the LiquidityPool.
     * @param qty The quantity of the position.
     * @param makerMargin The maker margin of the position.
     * @return binMargins An array of BinMargin representing the calculated bin margins.
     */
    function prepareBinMargins(
        LiquidityPool storage self,
        int224 qty,
        uint256 makerMargin,
        uint256 minimumBinMargin
    ) internal view returns (BinMargin[] memory) {
        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, qty);

        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();
        uint256[FEE_RATES_LENGTH] memory _binMargins;

        uint256 to;
        uint256 cnt;
        uint256 remain = makerMargin;
        for (; to < FEE_RATES_LENGTH; to++) {
            if (remain == 0) break;

            uint256 freeLiquidity = _bins[_tradingFeeRates[to]].freeLiquidity();
            if (freeLiquidity >= minimumBinMargin) {
                if (remain <= freeLiquidity) {
                    _binMargins[to] = remain;
                    remain = 0;
                } else {
                    _binMargins[to] = freeLiquidity;
                    remain -= freeLiquidity;
                }
                cnt++;
            }
        }

        require(remain == 0, Errors.NOT_ENOUGH_FREE_LIQUIDITY);

        BinMargin[] memory binMargins = new BinMargin[](cnt);
        for ((uint256 i, uint256 idx) = (0, 0); i < to; i++) {
            if (_binMargins[i] != 0) {
                binMargins[idx] = BinMargin({
                    tradingFeeRate: _tradingFeeRates[i],
                    amount: _binMargins[i]
                });

                unchecked {
                    idx++;
                }
            }
        }

        return binMargins;
    }

    /**
     * @notice Accepts an open position and opens corresponding liquidity bins.
     * @dev This function calculates the target liquidity bins based on the position quantity.
     *      It prepares the bin margins and divides the position parameters accordingly.
     *      Then, it opens the liquidity bins with the corresponding parameters and trading fees.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param position The Position object representing the open position.
     */
    function acceptOpenPosition(
        LiquidityPool storage self,
        LpContext memory ctx,
        Position memory position
    ) internal {
        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, position.qty);

        uint256 makerMargin = position.makerMargin();
        BinMargin[] memory binMargins = position.binMargins();

        // Divide the position parameters to match the bin margins
        _proportionalPositionParamValue[] memory paramValues = divideToPositionParamValue(
            position.leveragedQty(ctx),
            makerMargin,
            position.takerMargin,
            binMargins
        );

        PositionParam memory param = newPositionParam(position.openVersion, position.openTimestamp);
        for (uint256 i; i < binMargins.length; ) {
            BinMargin memory binMargin = binMargins[i];

            if (binMargin.amount != 0) {
                param.leveragedQty = paramValues[i].leveragedQty;
                param.takerMargin = paramValues[i].takerMargin;
                param.makerMargin = binMargin.amount;

                _bins[binMargins[i].tradingFeeRate].openPosition(
                    ctx,
                    param,
                    binMargin.tradingFee(position._feeProtocol)
                );
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Accepts a close position request and closes the corresponding liquidity bins.
     * @dev This function calculates the target liquidity bins based on the position quantity.
     *      It retrieves the maker margin and bin margins from the position.
     *      Then, it divides the position parameters to match the bin margins.
     *      Finally, it closes the liquidity bins with the provided parameters.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param position The Position object representing the close position request.
     */
    function acceptClosePosition(
        LiquidityPool storage self,
        LpContext memory ctx,
        Position memory position
    ) internal {
        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, position.qty);

        uint256 makerMargin = position.makerMargin();
        BinMargin[] memory binMargins = position.binMargins();

        // Divide the position parameters to match the bin margins
        _proportionalPositionParamValue[] memory paramValues = divideToPositionParamValue(
            position.leveragedQty(ctx),
            makerMargin,
            position.takerMargin,
            binMargins
        );

        PositionParam memory param = newPositionParam(
            position.openVersion,
            position.closeVersion,
            position.openTimestamp,
            position.closeTimestamp
        );

        for (uint256 i; i < binMargins.length; ) {
            if (binMargins[i].amount != 0) {
                LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                param.leveragedQty = paramValues[i].leveragedQty;
                param.takerMargin = paramValues[i].takerMargin;
                param.makerMargin = binMargins[i].amount;

                _bin.closePosition(ctx, param);
            }

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Accepts a claim position request and processes the corresponding liquidity bins
     *         based on the realized position pnl.
     * @dev This function verifies if the absolute value of the realized position pnl is within the acceptable margin range.
     *      It retrieves the target liquidity bins based on the position quantity and the bin margins from the position.
     *      Then, it divides the position parameters to match the bin margins.
     *      Depending on the value of the realized position pnl, it either claims the position fully or partially.
     *      The claimed pnl is distributed among the liquidity bins according to their respective margins.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param position The Position object representing the position to claim.
     * @param realizedPnl The realized position pnl (taker side).
     */
    function acceptClaimPosition(
        LiquidityPool storage self,
        LpContext memory ctx,
        Position memory position,
        int256 realizedPnl // realized position pnl (taker side)
    ) internal {
        uint256 absRealizedPnl = realizedPnl.abs();
        uint256 makerMargin = position.makerMargin();
        // Ensure that the realized position pnl is within the acceptable margin range
        require(
            !((realizedPnl > 0 && absRealizedPnl > makerMargin) ||
                (realizedPnl < 0 && absRealizedPnl > position.takerMargin)),
            Errors.EXCEED_MARGIN_RANGE
        );

        // Retrieve the target liquidity bins based on the position quantity
        mapping(uint16 => LiquidityBin) storage _bins = targetBins(self, position.qty);
        BinMargin[] memory binMargins = position.binMargins();

        // Divide the position parameters to match the bin margins
        _proportionalPositionParamValue[] memory paramValues = divideToPositionParamValue(
            position.leveragedQty(ctx),
            makerMargin,
            position.takerMargin,
            binMargins
        );

        PositionParam memory param = newPositionParam(
            position.openVersion,
            position.closeVersion,
            position.openTimestamp,
            position.closeTimestamp
        );

        if (realizedPnl == 0) {
            for (uint256 i; i < binMargins.length; ) {
                if (binMargins[i].amount != 0) {
                    LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                    param.leveragedQty = paramValues[i].leveragedQty;
                    param.takerMargin = paramValues[i].takerMargin;
                    param.makerMargin = binMargins[i].amount;

                    _bin.claimPosition(ctx, param, 0);
                }

                unchecked {
                    i++;
                }
            }
        } else if (realizedPnl > 0 && absRealizedPnl == makerMargin) {
            for (uint256 i; i < binMargins.length; ) {
                if (binMargins[i].amount != 0) {
                    LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                    param.leveragedQty = paramValues[i].leveragedQty;
                    param.takerMargin = paramValues[i].takerMargin;
                    param.makerMargin = binMargins[i].amount;

                    _bin.claimPosition(ctx, param, param.makerMargin.toInt256());
                }

                unchecked {
                    i++;
                }
            }
        } else {
            uint256 remainMakerMargin = makerMargin;
            uint256 remainRealizedPnl = absRealizedPnl;

            for (uint256 i; i < binMargins.length; ) {
                if (binMargins[i].amount != 0) {
                    LiquidityBin storage _bin = _bins[binMargins[i].tradingFeeRate];

                    param.leveragedQty = paramValues[i].leveragedQty;
                    param.takerMargin = paramValues[i].takerMargin;
                    param.makerMargin = binMargins[i].amount;

                    uint256 absTakerPnl = remainRealizedPnl.mulDiv(
                        param.makerMargin,
                        remainMakerMargin
                    );
                    if (realizedPnl < 0) {
                        // maker profit
                        absTakerPnl = Math.min(absTakerPnl, param.takerMargin);
                    } else {
                        // taker profit
                        absTakerPnl = Math.min(absTakerPnl, param.makerMargin);
                    }

                    int256 takerPnl = realizedPnl < 0
                        ? -(absTakerPnl.toInt256())
                        : absTakerPnl.toInt256();

                    _bin.claimPosition(ctx, param, takerPnl);

                    remainMakerMargin -= param.makerMargin;
                    remainRealizedPnl -= absTakerPnl;
                }

                unchecked {
                    i++;
                }
            }

            require(remainRealizedPnl == 0, Errors.EXCEED_MARGIN_RANGE);
        }
    }

    /**
     * @notice Accepts an add liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptAddLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param amount The amount of liquidity to add.
     */
    function acceptAddLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 amount
    ) internal _validTradingFeeRate(tradingFeeRate) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the add liquidity request on the liquidity bin
        bin.acceptAddLiquidity(ctx, amount);
    }

    /**
     * @notice Accepts a claim liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptClaimLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param amount The amount of liquidity to claim.
     *        (should be the same as the one used in acceptAddLiquidity)
     * @param oracleVersion The oracle version used for the claim.
     *        (should be the oracle version when call acceptAddLiquidity)
     * @return The amount of liquidity (CLB tokens) received as a result of the liquidity claim.
     */
    function acceptClaimLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 amount,
        uint256 oracleVersion
    ) internal _validTradingFeeRate(tradingFeeRate) returns (uint256) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the claim liquidity request on the liquidity bin and return the actual claimed amount
        return bin.acceptClaimLiquidity(ctx, amount, oracleVersion);
    }

    /**
     * @notice Accepts a remove liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptRemoveLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param clbTokenAmount The amount of CLB tokens to remove.
     */
    function acceptRemoveLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 clbTokenAmount
    ) internal _validTradingFeeRate(tradingFeeRate) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the remove liquidity request on the liquidity bin
        bin.acceptRemoveLiquidity(ctx, clbTokenAmount);
    }

    /**
     * @notice Accepts a withdraw liquidity request
     *         and processes the liquidity bin corresponding to the given trading fee rate.
     * @dev This function validates the trading fee rate
     *      and calls the acceptWithdrawLiquidity function on the target liquidity bin.
     * @param self The reference to the LiquidityPool storage.
     * @param ctx The LpContext object.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @param clbTokenAmount The amount of CLB tokens to withdraw.
     *        (should be the same as the one used in acceptRemoveLiquidity)
     * @param oracleVersion The oracle version used for the withdrawal.
     *        (should be the oracle version when call acceptRemoveLiquidity)
     * @return amount The amount of base tokens withdrawn
     * @return burnedCLBTokenAmount the amount of CLB tokens burned.
     */
    function acceptWithdrawLiquidity(
        LiquidityPool storage self,
        LpContext memory ctx,
        int16 tradingFeeRate,
        uint256 clbTokenAmount,
        uint256 oracleVersion
    )
        internal
        _validTradingFeeRate(tradingFeeRate)
        returns (uint256 amount, uint256 burnedCLBTokenAmount)
    {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Process the withdraw liquidity request on the liquidity bin
        // and get the amount of base tokens withdrawn and CLB tokens burned
        return bin.acceptWithdrawLiquidity(ctx, clbTokenAmount, oracleVersion);
    }

    /**
     * @notice Retrieves the total liquidity amount in base tokens for the specified trading fee rate.
     * @dev This function retrieves the liquidity bin based on the trading fee rate
     *      and calls the liquidity function on it.
     * @param self The reference to the LiquidityPool storage.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @return amount The total liquidity amount in base tokens.
     */
    function getBinLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate
    ) internal view returns (uint256 amount) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Get the total liquidity amount in base tokens from the liquidity bin
        return bin.liquidity();
    }

    /**
     * @notice Retrieves the free liquidity amount in base tokens for the specified trading fee rate.
     * @dev This function retrieves the liquidity bin based on the trading fee rate
     *      and calls the freeLiquidity function on it.
     * @param self The reference to the LiquidityPool storage.
     * @param tradingFeeRate The trading fee rate associated with the liquidity bin.
     * @return amount The free liquidity amount in base tokens.
     */
    function getBinFreeLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate
    ) internal view returns (uint256 amount) {
        // Retrieve the liquidity bin based on the trading fee rate
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        // Get the free liquidity amount in base tokens from the liquidity bin
        return bin.freeLiquidity();
    }

    /**
     * @notice Retrieves the target bins based on the sign of the given value.
     * @dev This function retrieves the target bins mapping (short or long) based on the sign of the given value.
     * @param self The storage reference to the LiquidityPool.
     * @param sign The sign of the value (-1 for negative, 1 for positive).
     * @return _bins The target bins mapping associated with the sign of the value.
     */
    function targetBins(
        LiquidityPool storage self,
        int256 sign
    ) private view returns (mapping(uint16 => LiquidityBin) storage) {
        return sign < 0 ? self._shortBins : self._longBins;
    }

    /**
     * @notice Retrieves the target bin based on the trading fee rate.
     * @dev This function retrieves the target bin based on the sign of the trading fee rate and returns it.
     * @param self The storage reference to the LiquidityPool.
     * @param tradingFeeRate The trading fee rate associated with the bin.
     * @return bin The target bin associated with the trading fee rate.
     */
    function targetBin(
        LiquidityPool storage self,
        int16 tradingFeeRate
    ) private view returns (LiquidityBin storage) {
        return
            tradingFeeRate < 0
                ? self._shortBins[abs(tradingFeeRate)]
                : self._longBins[abs(tradingFeeRate)];
    }

    /**
     * @notice Divides the leveraged quantity, maker margin, and taker margin
     *         into proportional position parameter values.
     * @dev This function divides the leveraged quantity, maker margin, and taker margin
     *      into proportional position parameter values based on the bin margins.
     *      It calculates the proportional values for each bin margin and returns them in an array.
     * @param leveragedQty The leveraged quantity.
     * @param makerMargin The maker margin amount.
     * @param takerMargin The taker margin amount.
     * @param binMargins The array of bin margins.
     * @return values The array of proportional position parameter values.
     */
    function divideToPositionParamValue(
        int256 leveragedQty,
        uint256 makerMargin,
        uint256 takerMargin,
        BinMargin[] memory binMargins
    ) private pure returns (_proportionalPositionParamValue[] memory) {
        uint256 remainLeveragedQty = leveragedQty.abs();
        uint256 remainTakerMargin = takerMargin;

        _proportionalPositionParamValue[] memory values = new _proportionalPositionParamValue[](
            binMargins.length
        );

        for (uint256 i; i < binMargins.length - 1; ) {
            uint256 _qty = remainLeveragedQty.mulDiv(binMargins[i].amount, makerMargin);
            uint256 _takerMargin = remainTakerMargin.mulDiv(binMargins[i].amount, makerMargin);

            values[i] = _proportionalPositionParamValue({
                leveragedQty: leveragedQty < 0 ? _qty.toInt256() : -(_qty.toInt256()), // opposit side
                takerMargin: _takerMargin
            });

            remainLeveragedQty -= _qty;
            remainTakerMargin -= _takerMargin;

            unchecked {
                i++;
            }
        }

        values[binMargins.length - 1] = _proportionalPositionParamValue({
            leveragedQty: leveragedQty < 0
                ? remainLeveragedQty.toInt256()
                : -(remainLeveragedQty.toInt256()), // opposit side
            takerMargin: remainTakerMargin
        });

        return values;
    }

    /**
     * @notice Creates a new PositionParam struct with the given oracle version and timestamp.
     * @param openVersion The version of the oracle when the position was opened
     * @param openTimestamp The timestamp when the position was opened
     * @return param The new PositionParam struct.
     */
    function newPositionParam(
        uint256 openVersion,
        uint256 openTimestamp
    ) private pure returns (PositionParam memory param) {
        param.openVersion = openVersion;
        param.openTimestamp = openTimestamp;
    }

    /**
     * @notice Creates a new PositionParam struct with the given oracle version and timestamp.
     * @param openVersion The version of the oracle when the position was opened
     * @param closeVersion The version of the oracle when the position was closed
     * @param openTimestamp The timestamp when the position was opened
     * @param closeTimestamp The timestamp when the position was closed
     * @return param The new PositionParam struct.
     */
    function newPositionParam(
        uint256 openVersion,
        uint256 closeVersion,
        uint256 openTimestamp,
        uint256 closeTimestamp
    ) private pure returns (PositionParam memory param) {
        param.openVersion = openVersion;
        param.closeVersion = closeVersion;
        param.openTimestamp = openTimestamp;
        param.closeTimestamp = closeTimestamp;
    }

    /**
     * @notice Validates the trading fee rate.
     * @dev This function validates the trading fee rate by checking if it is supported.
     *      It compares the absolute value of the fee rate with the predefined trading fee rates
     *      to determine if it is a valid rate.
     * @param tradingFeeRate The trading fee rate to be validated.
     */
    function validateTradingFeeRate(int16 tradingFeeRate) private pure {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();

        uint16 absFeeRate = abs(tradingFeeRate);

        uint256 idx = findUpperBound(_tradingFeeRates, absFeeRate);
        require(
            idx < _tradingFeeRates.length && absFeeRate == _tradingFeeRates[idx],
            Errors.UNSUPPORTED_TRADING_FEE_RATE
        );
    }

    /**
     * @notice Calculates the absolute value of an int16 number.
     * @param i The int16 number.
     * @return absValue The absolute value of the input number.
     */
    function abs(int16 i) private pure returns (uint16) {
        return i < 0 ? uint16(-i) : uint16(i);
    }

    /**
     * @notice Finds the upper bound index of an element in a sorted array.
     * @dev This function performs a binary search on the sorted array
     *      to find * the index of the upper bound of the given element.
     *      It returns the index as the exclusive upper bound,
     *      or the inclusive upper bound if the element is found at the end of the array.
     * @param array The sorted array.
     * @param element The element to find the upper bound for.
     * @return uint256 The index of the upper bound of the element in the array.
     */
    function findUpperBound(
        uint16[FEE_RATES_LENGTH] memory array,
        uint16 element
    ) private pure returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low != 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    /**
     * @notice Distributes earnings among the liquidity bins.
     * @dev This function distributes the earnings among the liquidity bins,
     *      proportional to their total balances.
     *      It iterates through the trading fee rates
     *      and distributes the proportional amount of earnings to each bin
     *      based on its total balance relative to the market balance.
     * @param self The LiquidityPool storage.
     * @param earning The total earnings to be distributed.
     * @param marketBalance The market balance.
     */
    function distributeEarning(
        LiquidityPool storage self,
        uint256 earning,
        uint256 marketBalance
    ) internal {
        uint256 remainEarning = earning;
        uint256 remainBalance = marketBalance;
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();

        (remainEarning, remainBalance) = distributeEarning(
            self._longBins,
            remainEarning,
            remainBalance,
            _tradingFeeRates,
            "L"
        );
        (remainEarning, remainBalance) = distributeEarning(
            self._shortBins,
            remainEarning,
            remainBalance,
            _tradingFeeRates,
            "S"
        );
    }

    /**
     * @notice Distributes earnings among the liquidity bins of a specific type.
     * @dev This function distributes the earnings among the liquidity bins of
     *      the specified type, proportional to their total balances.
     *      It iterates through the trading fee rates
     *      and distributes the proportional amount of earnings to each bin
     *      based on its total balance relative to the market balance.
     * @param bins The liquidity bins mapping.
     * @param earning The total earnings to be distributed.
     * @param marketBalance The market balance.
     * @param _tradingFeeRates The array of supported trading fee rates.
     * @param binType The type of liquidity bin ("L" for long, "S" for short).
     * @return remainEarning The remaining earnings after distribution.
     * @return remainBalance The remaining market balance after distribution.
     */
    function distributeEarning(
        mapping(uint16 => LiquidityBin) storage bins,
        uint256 earning,
        uint256 marketBalance,
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates,
        bytes1 binType
    ) private returns (uint256 remainEarning, uint256 remainBalance) {
        remainBalance = marketBalance;
        remainEarning = earning;

        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 feeRate = _tradingFeeRates[i];
            LiquidityBin storage bin = bins[feeRate];
            uint256 binLiquidity = bin.liquidity();

            if (binLiquidity == 0) {
                unchecked {
                    i++;
                }
                continue;
            }

            uint256 binEarning = remainEarning.mulDiv(binLiquidity, remainBalance);

            bin.applyEarning(binEarning);

            remainBalance -= binLiquidity;
            remainEarning -= binEarning;

            emit LiquidityBinEarningAccumulated(feeRate, binType, binEarning);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Retrieves the value of a specific bin in the LiquidityPool storage for the provided trading fee rate.
     * @param self The reference to the LiquidityPool storage.
     * @param _tradingFeeRate The trading fee rate for which to calculate the bin value.
     * @param ctx The LP context containing relevant information for the calculation.
     * @return value The value of the specified bin.
     */
    function binValue(
        LiquidityPool storage self,
        int16 _tradingFeeRate,
        LpContext memory ctx
    ) internal view returns (uint256 value) {
        value = targetBin(self, _tradingFeeRate).value(ctx);
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific trading fee rate and oracle version from a LiquidityPool.
     * @param self The reference to the LiquidityPool struct.
     * @param tradingFeeRate The trading fee rate for which to retrieve the claimable liquidity.
     * @param oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IMarketLiquidity.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        LiquidityPool storage self,
        int16 tradingFeeRate,
        uint256 oracleVersion
    )
        internal
        view
        _validTradingFeeRate(tradingFeeRate)
        returns (IMarketLiquidity.ClaimableLiquidity memory)
    {
        LiquidityBin storage bin = targetBin(self, tradingFeeRate);
        return bin.claimableLiquidity(oracleVersion);
    }

    /**
     * @dev Retrieves the liquidity bin statuses for the LiquidityPool using the provided context.
     * @param self The LiquidityPool storage instance.
     * @param ctx The LpContext containing the necessary context for calculating the bin statuses.
     * @return stats An array of IMarketLiquidity.LiquidityBinStatus representing the liquidity bin statuses.
     */
    function liquidityBinStatuses(
        LiquidityPool storage self,
        LpContext memory ctx
    ) internal view returns (IMarketLiquidity.LiquidityBinStatus[] memory) {
        uint16[FEE_RATES_LENGTH] memory _tradingFeeRates = CLBTokenLib.tradingFeeRates();

        IMarketLiquidity.LiquidityBinStatus[]
            memory stats = new IMarketLiquidity.LiquidityBinStatus[](FEE_RATES_LENGTH * 2);
        for (uint256 i; i < FEE_RATES_LENGTH; ) {
            uint16 _feeRate = _tradingFeeRates[i];
            LiquidityBin storage longBin = targetBin(self, int16(_feeRate));
            LiquidityBin storage shortBin = targetBin(self, -int16(_feeRate));

            stats[i] = IMarketLiquidity.LiquidityBinStatus({
                tradingFeeRate: int16(_feeRate),
                liquidity: longBin.liquidity(),
                freeLiquidity: longBin.freeLiquidity(),
                binValue: longBin.value(ctx)
            });
            stats[i + FEE_RATES_LENGTH] = IMarketLiquidity.LiquidityBinStatus({
                tradingFeeRate: -int16(_feeRate),
                liquidity: shortBin.liquidity(),
                freeLiquidity: shortBin.freeLiquidity(),
                binValue: shortBin.value(ctx)
            });

            unchecked {
                i++;
            }
        }

        return stats;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {UFixed18} from "@equilibria/root/number/types/UFixed18.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";

/**
 * @title PositionParam
 * @dev A struct representing the parameters of a position.
 */
struct PositionParam {
    /// @dev The version of the position's open transaction
    uint256 openVersion;
    /// @dev The version of the position's close transaction
    uint256 closeVersion;
    /// @dev The leveraged quantity of the position
    int256 leveragedQty;
    /// @dev The margin amount provided by the taker
    uint256 takerMargin;
    /// @dev The margin amount provided by the maker
    uint256 makerMargin;
    /// @dev The timestamp of the position's open transaction
    uint256 openTimestamp;
    /// @dev The timestamp of the position's close transaction
    uint256 closeTimestamp;
    /// @dev Caches the settle oracle version for the position's entry
    IOracleProvider.OracleVersion _entryVersionCache;
    /// @dev Caches the settle oracle version for the position's exit
    IOracleProvider.OracleVersion _exitVersionCache;
}

using PositionParamLib for PositionParam global;

/**
 * @title PositionParamLib
 * @notice Library for manipulating PositionParam struct.
 */
library PositionParamLib {
    using Math for uint256;
    using SignedMath for int256;

    /**
     * @notice Returns the settle version for the position's entry.
     * @param self The PositionParam struct.
     * @return uint256 The settle version for the position's entry.
     */
    function entryVersion(PositionParam memory self) internal pure returns (uint256) {
        return PositionUtil.settleVersion(self.openVersion);
    }

    /**
     * @notice Calculates the entry price for a PositionParam.
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @return UFixed18 The entry price.
     */
    function entryPrice(
        PositionParam memory self,
        LpContext memory ctx
    ) internal view returns (UFixed18) {
        return
            PositionUtil.settlePrice(
                ctx.oracleProvider,
                self.openVersion,
                self.entryOracleVersion(ctx)
            );
    }

    /**
     * @notice Calculates the entry amount for a PositionParam.
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @return uint256 The entry amount.
     */
    function entryAmount(
        PositionParam memory self,
        LpContext memory ctx
    ) internal view returns (uint256) {
        return PositionUtil.transactionAmount(self.leveragedQty, self.entryPrice(ctx));
    }

    /**
     * @notice Retrieves the settle oracle version for the position's entry.
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @return OracleVersion The settle oracle version for the position's entry.
     */
    function entryOracleVersion(
        PositionParam memory self,
        LpContext memory ctx
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._entryVersionCache.version == 0) {
            self._entryVersionCache = ctx.oracleVersionAt(self.entryVersion());
        }
        return self._entryVersionCache;
    }

    /**
     * @dev Calculates the interest for a PositionParam until a specified timestamp.
     * @dev It is used only to deduct accumulated accrued interest when close position
     * @param self The PositionParam struct.
     * @param ctx The LpContext struct.
     * @param until The timestamp until which to calculate the interest.
     * @return uint256 The calculated interest.
     */
    function calculateInterest(
        PositionParam memory self,
        LpContext memory ctx,
        uint256 until
    ) internal view returns (uint256) {
        return ctx.calculateInterest(self.makerMargin, self.openTimestamp, until);
    }

    /**
     * @notice Creates a clone of a PositionParam.
     * @param self The PositionParam data struct.
     * @return PositionParam The cloned PositionParam.
     */
    function clone(PositionParam memory self) internal pure returns (PositionParam memory) {
        return
            PositionParam({
                openVersion: self.openVersion,
                closeVersion: self.closeVersion,
                leveragedQty: self.leveragedQty,
                takerMargin: self.takerMargin,
                makerMargin: self.makerMargin,
                openTimestamp: self.openTimestamp,
                closeTimestamp: self.closeTimestamp,
                _entryVersionCache: self._entryVersionCache,
                _exitVersionCache: self._exitVersionCache
            });
    }

    /**
     * @notice Creates the inverse of a PositionParam by negating the leveragedQty.
     * @param self The PositionParam data struct.
     * @return PositionParam The inverted PositionParam.
     */
    function inverse(PositionParam memory self) internal pure returns (PositionParam memory) {
        PositionParam memory param = self.clone();
        param.leveragedQty *= -1;
        return param;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IInterestCalculator} from "@chromatic-protocol/contracts/core/interfaces/IInterestCalculator.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";

/**
 * @title LpContext
 * @notice Represents the context information required for LP bin operations.
 */
struct LpContext {
    /// @dev The Oracle Provider contract used for price feed
    IOracleProvider oracleProvider;
    /// @dev The Interest Calculator contract used for interest calculations
    IInterestCalculator interestCalculator;
    /// @dev The Chromatic Vault contract responsible for managing liquidity and margin
    IChromaticVault vault;
    /// @dev The CLB token contract that represents LP ownership in the pool
    ICLBToken clbToken;
    /// @dev The address of market contract
    address market;
    /// @dev The address of the settlement token used in the market
    address settlementToken;
    /// @dev The precision of the settlement token used in the market
    uint256 tokenPrecision;
    /// @dev Cached instance of the current oracle version
    IOracleProvider.OracleVersion _currentVersionCache;
}

using LpContextLib for LpContext global;

/**
 * @title LpContextLib
 * @notice Provides functions that operate on the `LpContext` struct
 */
library LpContextLib {
    /**
     * @notice Syncs the oracle version used by the market.
     * @param self The memory instance of `LpContext` struct
     */
    function syncOracleVersion(LpContext memory self) internal {
        self._currentVersionCache = self.oracleProvider.sync();
    }

    /**
     * @notice Retrieves the current oracle version used by the market
     * @dev If the `_currentVersionCache` has been initialized, then returns it.
     *      If not, it calls the `currentVersion` function on the `oracleProvider of the market
     *      to fetch the current version and stores it in the cache,
     *      and then returns the current version.
     * @param self The memory instance of `LpContext` struct
     * @return OracleVersion The current oracle version
     */
    function currentOracleVersion(
        LpContext memory self
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._currentVersionCache.version == 0) {
            self._currentVersionCache = self.oracleProvider.currentVersion();
        }

        return self._currentVersionCache;
    }

    /**
     * @notice Retrieves the oracle version at a specific version number
     * @dev If the `_currentVersionCache` matches the requested version, then returns it.
     *      Otherwise, it calls the `atVersion` function on the `oracleProvider` of the market
     *      to fetch the desired version.
     * @param self The memory instance of `LpContext` struct
     * @param version The requested version number
     * @return OracleVersion The oracle version at the requested version number
     */
    function oracleVersionAt(
        LpContext memory self,
        uint256 version
    ) internal view returns (IOracleProvider.OracleVersion memory) {
        if (self._currentVersionCache.version == version) {
            return self._currentVersionCache;
        }
        return self.oracleProvider.atVersion(version);
    }

    /**
     * @notice Calculates the interest accrued for a given amount of settlement tokens
               within a specified time range.
     * @dev This function internally calls the `calculateInterest` function on the `interestCalculator` contract.
     * @param self The memory instance of the `LpContext` struct.
     * @param amount The amount of settlement tokens for which the interest needs to be calculated.
     * @param from The starting timestamp of the time range (inclusive).
     * @param to The ending timestamp of the time range (exclusive).
     * @return The accrued interest as a `uint256` value.
     */
    function calculateInterest(
        LpContext memory self,
        uint256 amount,
        uint256 from,
        uint256 to
    ) internal view returns (uint256) {
        return
            amount == 0 || from >= to
                ? 0
                : self.interestCalculator.calculateInterest(self.settlementToken, amount, from, to);
    }

    /**
     * @notice Checks if an oracle version is in the past.
     * @param self The memory instance of the `LpContext` struct.
     * @param oracleVersion The oracle version to check.
     * @return A boolean value indicating whether the oracle version is in the past.
     */
    function isPastVersion(
        LpContext memory self,
        uint256 oracleVersion
    ) internal view returns (bool) {
        return oracleVersion != 0 && oracleVersion < self.currentOracleVersion().version;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";

/**
 * @dev The LpAction enum represents the types of LP actions that can be performed.
 */
enum LpAction {
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY
}

/**
 * @title LpReceipt
 * @notice The LpReceipt struct represents a receipt of an LP action performed.
 */
struct LpReceipt {
    /// @dev An identifier for the receipt
    uint256 id;
    /// @dev The oracle version associated with the action
    uint256 oracleVersion;
    /// @dev The amount involved in the action,
    ///      when the action is `ADD_LIQUIDITY`, this value represents the amount of settlement tokens
    ///      when the action is `REMOVE_LIQUIDITY`, this value represents the amount of CLB tokens
    uint256 amount;
    /// @dev The address of the recipient of the action
    address recipient;
    /// @dev An enumeration representing the type of LP action performed (ADD_LIQUIDITY or REMOVE_LIQUIDITY)
    LpAction action;
    /// @dev The trading fee rate associated with the LP action
    int16 tradingFeeRate;
}

using LpReceiptLib for LpReceipt global;

/**
 * @title LpReceiptLib
 * @notice Provides functions that operate on the `LpReceipt` struct
 */
library LpReceiptLib {
    /**
     * @notice Computes the ID of the CLBToken contract based on the trading fee rate.
     * @param self The LpReceipt struct.
     * @return The ID of the CLBToken contract.
     */
    function clbTokenId(LpReceipt memory self) internal pure returns (uint256) {
        return CLBTokenLib.encodeId(self.tradingFeeRate);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IChromaticLiquidator} from "@chromatic-protocol/contracts/core/interfaces/IChromaticLiquidator.sol";
import {IChromaticVault} from "@chromatic-protocol/contracts/core/interfaces/IChromaticVault.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {LiquidityPool} from "@chromatic-protocol/contracts/core/libraries/liquidity/LiquidityPool.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";

struct MarketStorage {
    IChromaticMarketFactory factory;
    IOracleProvider oracleProvider;
    IERC20Metadata settlementToken;
    ICLBToken clbToken;
    IChromaticLiquidator liquidator;
    IChromaticVault vault;
    IKeeperFeePayer keeperFeePayer;
    LiquidityPool liquidityPool;
    uint8 feeProtocol;
}

struct LpReceiptStorage {
    uint256 lpReceiptId;
    mapping(uint256 => LpReceipt) lpReceipts;
}

struct PositionStorage {
    uint256 positionId;
    mapping(uint256 => Position) positions;
}

library MarketStorageLib {
    bytes32 constant MARKET_STORAGE_POSITION = keccak256("protocol.chromatic.market.storage");

    function marketStorage() internal pure returns (MarketStorage storage ms) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }
}

using LpReceiptStorageLib for LpReceiptStorage global;

library LpReceiptStorageLib {
    bytes32 constant LP_RECEIPT_STORAGE_POSITION =
        keccak256("protocol.chromatic.lpreceipt.storage");

    function lpReceiptStorage() internal pure returns (LpReceiptStorage storage ls) {
        bytes32 position = LP_RECEIPT_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }

    function nextId(LpReceiptStorage storage self) internal returns (uint256 id) {
        id = ++self.lpReceiptId;
    }

    function setReceipt(LpReceiptStorage storage self, LpReceipt memory receipt) internal {
        self.lpReceipts[receipt.id] = receipt;
    }

    function getReceipt(
        LpReceiptStorage storage self,
        uint256 receiptId
    ) internal view returns (LpReceipt memory receipt) {
        receipt = self.lpReceipts[receiptId];
    }

    function deleteReceipt(LpReceiptStorage storage self, uint256 receiptId) internal {
        delete self.lpReceipts[receiptId];
    }

    function deleteReceipts(LpReceiptStorage storage self, uint256[] memory receiptIds) internal {
        for (uint256 i; i < receiptIds.length; ) {
            delete self.lpReceipts[receiptIds[i]];

            unchecked {
                i++;
            }
        }
    }
}

using PositionStorageLib for PositionStorage global;

library PositionStorageLib {
    bytes32 constant POSITION_STORAGE_POSITION = keccak256("protocol.chromatic.position.storage");

    function positionStorage() internal pure returns (PositionStorage storage ls) {
        bytes32 position = POSITION_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }

    function nextId(PositionStorage storage self) internal returns (uint256 id) {
        id = ++self.positionId;
    }

    function setPosition(PositionStorage storage self, Position memory position) internal {
        Position storage _p = self.positions[position.id];

        _p.id = position.id;
        _p.openVersion = position.openVersion;
        _p.closeVersion = position.closeVersion;
        _p.qty = position.qty;
        _p.openTimestamp = position.openTimestamp;
        _p.closeTimestamp = position.closeTimestamp;
        _p.leverage = position.leverage;
        _p.takerMargin = position.takerMargin;
        _p.owner = position.owner;
        _p._feeProtocol = position._feeProtocol;
        // can not convert memory array to storage array
        delete _p._binMargins;
        for (uint i; i < position._binMargins.length; ) {
            BinMargin memory binMargin = position._binMargins[i];
            if (binMargin.amount != 0) {
                _p._binMargins.push(position._binMargins[i]);
            }

            unchecked {
                i++;
            }
        }
    }

    function getPosition(
        PositionStorage storage self,
        uint256 positionId
    ) internal view returns (Position memory position) {
        position = self.positions[positionId];
    }

    function getStoragePosition(
        PositionStorage storage self,
        uint256 positionId
    ) internal view returns (Position storage position) {
        position = self.positions[positionId];
    }

    function deletePosition(PositionStorage storage self, uint256 positionId) internal {
        delete self.positions[positionId];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {UFixed18} from "@equilibria/root/number/types/UFixed18.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {PositionUtil, QTY_LEVERAGE_PRECISION} from "@chromatic-protocol/contracts/core/libraries/PositionUtil.sol";
import {LpContext} from "@chromatic-protocol/contracts/core/libraries/LpContext.sol";
import {BinMargin} from "@chromatic-protocol/contracts/core/libraries/BinMargin.sol";

/**
 * @title Position
 * @dev The Position struct represents a trading position.
 */
struct Position {
    /// @dev The position identifier
    uint256 id;
    /// @dev The version of the oracle when the position was opened
    uint256 openVersion;
    /// @dev The version of the oracle when the position was closed
    uint256 closeVersion;
    /// @dev The quantity of the position
    int224 qty;
    /// @dev The leverage applied to the position
    uint32 leverage;
    /// @dev The timestamp when the position was opened
    uint256 openTimestamp;
    /// @dev The timestamp when the position was closed
    uint256 closeTimestamp;
    /// @dev The amount of collateral that a trader must provide
    uint256 takerMargin;
    /// @dev The owner of the position, usually it is the account address of trader
    address owner;
    /// @dev The bin margins for the position, it represents the amount of collateral for each bin
    BinMargin[] _binMargins;
    /// @dev The protocol fee for the market
    uint8 _feeProtocol;
}

using PositionLib for Position global;

/**
 * @title PositionLib
 * @notice Provides functions that operate on the `Position` struct
 */
library PositionLib {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;

    /**
     * @notice Calculates the settle version for the position's entry
     * @param self The memory instance of the `Position` struct
     * @return utin256 The settle version for the position's entry
     */
    function entryVersion(Position memory self) internal pure returns (uint256) {
        return PositionUtil.settleVersion(self.openVersion);
    }

    /**
     * @notice Calculates the settle version for the position's exit
     * @param self The memory instance of the `Position` struct
     * @return utin256 The settle version for the position's exit
     */
    function exitVersion(Position memory self) internal pure returns (uint256) {
        return PositionUtil.settleVersion(self.closeVersion);
    }

    /**
     * @notice Calculates the leveraged quantity of the position
     *         based on the position's quantity and leverage
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return uint256 The leveraged quantity
     */
    function leveragedQty(
        Position memory self,
        LpContext memory ctx
    ) internal pure returns (int256) {
        int256 qty = self.qty;
        int256 leveraged = qty
            .abs()
            .mulDiv(self.leverage * ctx.tokenPrecision, QTY_LEVERAGE_PRECISION)
            .toInt256();
        return qty < 0 ? -leveraged : leveraged;
    }

    /**
     * @notice Calculates the entry price of the position based on the position's open oracle version
     * @dev It fetches oracle price from `IOracleProvider`
     *      at the settle version calculated based on the position's open oracle version
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return UFixed18 The entry price
     */
    function entryPrice(
        Position memory self,
        LpContext memory ctx
    ) internal view returns (UFixed18) {
        return PositionUtil.settlePrice(ctx.oracleProvider, self.openVersion);
    }

    /**
     * @notice Calculates the exit price of the position based on the position's close oracle version
     * @dev It fetches oracle price from `IOracleProvider`
     *      at the settle version calculated based on the position's close oracle version
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return UFixed18 The exit price
     */
    function exitPrice(
        Position memory self,
        LpContext memory ctx
    ) internal view returns (UFixed18) {
        return PositionUtil.settlePrice(ctx.oracleProvider, self.closeVersion);
    }

    /**
     * @notice Calculates the profit or loss of the position
     *         based on the close oracle version and the leveraged quantity
     * @param self The memory instance of the `Position` struct
     * @param ctx The context object for this transaction
     * @return int256 The profit or loss
     */
    function pnl(Position memory self, LpContext memory ctx) internal view returns (int256) {
        return
            self.closeVersion > self.openVersion
                ? PositionUtil.pnl(
                    self.leveragedQty(ctx),
                    self.entryPrice(ctx),
                    self.exitPrice(ctx)
                )
                : int256(0);
    }

    /**
     * @notice Calculates the total margin required for the makers of the position
     * @dev The maker margin is calculated by summing up the amounts of all bin margins
     *      in the `_binMargins` array
     * @param self The memory instance of the `Position` struct
     * @return margin The maker margin
     */
    function makerMargin(Position memory self) internal pure returns (uint256 margin) {
        for (uint256 i; i < self._binMargins.length; ) {
            margin += self._binMargins[i].amount;

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates the total trading fee for the position
     * @dev The trading fee is calculated by summing up the trading fees of all bin margins
     *      in the `_binMargins` array
     * @param self The memory instance of the `Position` struct
     * @return fee The trading fee
     */
    function tradingFee(Position memory self) internal pure returns (uint256 fee) {
        for (uint256 i; i < self._binMargins.length; ) {
            fee += self._binMargins[i].tradingFee(self._feeProtocol);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Calculates the total protocol fee for a position.
     * @param self The Position struct representing the position.
     * @return fee The total protocol fee amount.
     */
    function protocolFee(Position memory self) internal pure returns (uint256 fee) {
        for (uint256 i; i < self._binMargins.length; ) {
            fee += self._binMargins[i].protocolFee(self._feeProtocol);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Returns an array of BinMargin instances
     *         representing the bin margins for the position
     * @param self The memory instance of the `Position` struct
     * @return margins The bin margins for the position
     */
    function binMargins(Position memory self) internal pure returns (BinMargin[] memory margins) {
        margins = self._binMargins;
    }

    /**
     * @notice Sets the `_binMargins` array for the position
     * @param self The memory instance of the `Position` struct
     * @param margins The bin margins for the position
     */
    function setBinMargins(Position memory self, BinMargin[] memory margins) internal pure {
        self._binMargins = margins;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {Fixed18} from "@equilibria/root/number/types/Fixed18.sol";
import {UFixed18, UFixed18Lib} from "@equilibria/root/number/types/UFixed18.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

uint256 constant QTY_DECIMALS = 4;
uint256 constant LEVERAGE_DECIMALS = 2;
uint256 constant QTY_PRECISION = 10 ** QTY_DECIMALS;
uint256 constant LEVERAGE_PRECISION = 10 ** LEVERAGE_DECIMALS;
uint256 constant QTY_LEVERAGE_PRECISION = QTY_PRECISION * LEVERAGE_PRECISION;

/**
 * @title PositionUtil
 * @notice Provides utility functions for managing positions
 */
library PositionUtil {
    using Math for uint256;
    using SafeCast for uint256;
    using SignedMath for int256;

    /**
     * @notice Returns next oracle version to settle
     * @dev It adds 1 to the `oracleVersion`
     *      and ensures that the `oracleVersion` is greater than 0 using a require statement.
     *      If the `oracleVersion` is not valid,
     *      it will trigger an error with the message `INVALID_ORACLE_VERSION`.
     * @param oracleVersion Input oracle version
     * @return uint256 Next oracle version to settle
     */
    function settleVersion(uint256 oracleVersion) internal pure returns (uint256) {
        require(oracleVersion != 0, Errors.INVALID_ORACLE_VERSION);
        return oracleVersion + 1;
    }

    /**
     * @notice Calculates the price of the position based on the `oracleVersion` to settle
     * @dev It calls another overloaded `settlePrice` function
     *      with an additional `OracleVersion` parameter,
     *      passing the `currentVersion` obtained from the `provider`
     * @param provider The oracle provider
     * @param oracleVersion The oracle version of position
     * @return UFixed18 The calculated price to settle
     */
    function settlePrice(
        IOracleProvider provider,
        uint256 oracleVersion
    ) internal view returns (UFixed18) {
        return settlePrice(provider, oracleVersion, provider.currentVersion());
    }

    /**
     * @notice Calculates the price of the position based on the `oracleVersion` to settle
     * @dev It calculates the price by considering the `settleVersion`
     *      and the `currentVersion` obtained from the `IOracleProvider`.
     *      It ensures that the settle version is not greater than the current version;
     *      otherwise, it triggers an error with the message `UNSETTLED_POSITION`.
     *      It retrieves the corresponding `OracleVersion` using `atVersion` from the `IOracleProvider`,
     *      and then calls `oraclePrice` to obtain the price.
     * @param provider The oracle provider
     * @param oracleVersion The oracle version of position
     * @param currentVersion The current oracle version
     * @return UFixed18 The calculated entry price to settle
     */
    function settlePrice(
        IOracleProvider provider,
        uint256 oracleVersion,
        IOracleProvider.OracleVersion memory currentVersion
    ) internal view returns (UFixed18) {
        uint256 _settleVersion = settleVersion(oracleVersion);
        require(_settleVersion <= currentVersion.version, Errors.UNSETTLED_POSITION);

        IOracleProvider.OracleVersion memory _oracleVersion = _settleVersion ==
            currentVersion.version
            ? currentVersion
            : provider.atVersion(_settleVersion);
        return oraclePrice(_oracleVersion);
    }

    /**
     * @notice Extracts the price value from an `OracleVersion` struct
     * @dev If the price is less than 0, it returns 0
     * @param oracleVersion The memory instance of `OracleVersion` struct
     * @return UFixed18 The price value of `oracleVersion`
     */
    function oraclePrice(
        IOracleProvider.OracleVersion memory oracleVersion
    ) internal pure returns (UFixed18) {
        return
            oracleVersion.price.sign() < 0
                ? UFixed18Lib.ZERO
                : UFixed18Lib.from(oracleVersion.price);
    }

    /**
     * @notice Calculates the profit or loss (PnL) for a position
     *         based on the leveraged quantity, entry price, and exit price
     * @dev It first calculates the price difference (`delta`) between the exit price and the entry price.
     *      If the leveraged quantity is negative, indicating short position,
     *      it adjusts the `delta` to reflect a negative change.
     *      The function then calculates the absolute PnL
     *      by multiplying the absolute value of the leveraged quantity
     *      with the absolute value of the `delta`, divided by the entry price.
     *      Finally, if `delta` is negative, indicating a loss,
     *      the absolute PnL is negated to represent a negative value.
     * @param leveragedQty The leveraged quantity of the position
     * @param _entryPrice The entry price of the position
     * @param _exitPrice The exit price of the position
     * @return int256 The profit or loss
     */
    function pnl(
        int256 leveragedQty, // as token precision
        UFixed18 _entryPrice,
        UFixed18 _exitPrice
    ) internal pure returns (int256) {
        int256 delta = _exitPrice.gt(_entryPrice)
            ? UFixed18.unwrap(_exitPrice.sub(_entryPrice)).toInt256()
            : -UFixed18.unwrap(_entryPrice.sub(_exitPrice)).toInt256();
        if (leveragedQty < 0) delta *= -1;

        int256 absPnl = leveragedQty
            .abs()
            .mulDiv(delta.abs(), UFixed18.unwrap(_entryPrice))
            .toInt256();

        return delta < 0 ? -absPnl : absPnl;
    }

    /**
     * @notice Verifies the validity of a position quantity added to the bin
     * @dev It ensures that the sign of the current quantity of the bin's position
     *      and the added quantity are same or zero.
     *      If the condition is not met, it triggers an error with the message `INVALID_POSITION_QTY`.
     * @param currentQty The current quantity of the bin's pending position
     * @param addedQty The position quantity added
     */
    function checkAddPositionQty(int256 currentQty, int256 addedQty) internal pure {
        require(
            !((currentQty > 0 && addedQty <= 0) || (currentQty < 0 && addedQty >= 0)),
            Errors.INVALID_POSITION_QTY
        );
    }

    /**
     * @notice Verifies the validity of a position quantity removed from the bin
     * @dev It ensures that the sign of the current quantity of the bin's position
     *      and the removed quantity are same or zero,
     *      and the absolute removed quantity is not greater than the absolute current quantity.
     *      If the condition is not met, it triggers an error with the message `INVALID_POSITION_QTY`.
     * @param currentQty The current quantity of the bin's position
     * @param removeQty The position quantity removed
     */
    function checkRemovePositionQty(int256 currentQty, int256 removeQty) internal pure {
        require(
            !((currentQty == 0) ||
                (removeQty == 0) ||
                (currentQty > 0 && removeQty > currentQty) ||
                (currentQty < 0 && removeQty < currentQty)),
            Errors.INVALID_POSITION_QTY
        );
    }

    /**
     * @notice Calculates the transaction amount based on the leveraged quantity and price
     * @param leveragedQty The leveraged quantity of the position
     * @param price The price of the position
     * @return uint256 The transaction amount
     */
    function transactionAmount(
        int256 leveragedQty,
        UFixed18 price
    ) internal pure returns (uint256) {
        return leveragedQty.abs().mulDiv(UFixed18.unwrap(price), UFixed18.unwrap(UFixed18Lib.ONE));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title OracleProviderRegistry
 * @dev A registry for managing oracle providers.
 */
struct OracleProviderRegistry {
    /// @dev Set of registered oracle providers
    EnumerableSet.AddressSet _oracleProviders;
    mapping(address => uint32) _minTakeProfitBPSs;
    mapping(address => uint32) _maxTakeProfitBPSs;
    mapping(address => uint8) _leverageLevels;
}

/**
 * @title OracleProviderRegistryLib
 * @notice Library for managing a registry of oracle providers.
 */
library OracleProviderRegistryLib {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Registers an oracle provider in the registry.
     * @dev Throws an error if the oracle provider is already registered.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider to register.
     * @param minTakeProfitBPS The minimum take-profit basis points.
     * @param maxTakeProfitBPS The maximum take-profit basis points.
     * @param leverageLevel The leverage level of the oracle provider.
     */
    function register(
        OracleProviderRegistry storage self,
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS,
        uint8 leverageLevel
    ) internal {
        require(
            !self._oracleProviders.contains(oracleProvider),
            Errors.ALREADY_REGISTERED_ORACLE_PROVIDER
        );

        self._oracleProviders.add(oracleProvider);
        self._minTakeProfitBPSs[oracleProvider] = minTakeProfitBPS;
        self._maxTakeProfitBPSs[oracleProvider] = maxTakeProfitBPS;
        self._leverageLevels[oracleProvider] = leverageLevel;
    }

    /**
     * @notice Unregisters an oracle provider from the registry.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider to unregister.
     */
    function unregister(OracleProviderRegistry storage self, address oracleProvider) internal {
        self._oracleProviders.remove(oracleProvider);
    }

    /**
     * @notice Returns an array of all registered oracle providers.
     * @param self The OracleProviderRegistry storage.
     * @return oracleProviders An array of addresses representing the registered oracle providers.
     */
    function oracleProviders(
        OracleProviderRegistry storage self
    ) internal view returns (address[] memory) {
        return self._oracleProviders.values();
    }

    /**
     * @notice Checks if an oracle provider is registered in the registry.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider to check.
     * @return bool Whether the oracle provider is registered.
     */
    function isRegistered(
        OracleProviderRegistry storage self,
        address oracleProvider
    ) internal view returns (bool) {
        return self._oracleProviders.contains(oracleProvider);
    }

    /**
     * @notice Retrieves the properties of an oracle provider.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider.
     * @return minTakeProfitBPS The minimum take-profit basis points.
     * @return maxTakeProfitBPS The maximum take-profit basis points.
     * @return leverageLevel The leverage level of the oracle provider.
     */
    function getOracleProviderProperties(
        OracleProviderRegistry storage self,
        address oracleProvider
    )
        internal
        view
        returns (uint32 minTakeProfitBPS, uint32 maxTakeProfitBPS, uint8 leverageLevel)
    {
        minTakeProfitBPS = self._minTakeProfitBPSs[oracleProvider];
        maxTakeProfitBPS = self._maxTakeProfitBPSs[oracleProvider];
        leverageLevel = self._leverageLevels[oracleProvider];
    }

    /**
     * @notice Sets the range for take-profit basis points for an oracle provider.
     * @param self The OracleProviderRegistry storage.
     * @param oracleProvider The address of the oracle provider.
     * @param minTakeProfitBPS The minimum take-profit basis points.
     * @param maxTakeProfitBPS The maximum take-profit basis points.
     */
    function setTakeProfitBPSRange(
        OracleProviderRegistry storage self,
        address oracleProvider,
        uint32 minTakeProfitBPS,
        uint32 maxTakeProfitBPS
    ) internal {
        self._minTakeProfitBPSs[oracleProvider] = minTakeProfitBPS;
        self._maxTakeProfitBPSs[oracleProvider] = maxTakeProfitBPS;
    }

    /**
     * @notice Sets the leverage level of an oracle provider in the registry.
     * @dev The leverage level must be either 0 or 1, and the max leverage must be x10 for level 0 or x20 for level 1.
     * @param self The storage reference to the OracleProviderRegistry.
     * @param oracleProvider The address of the oracle provider.
     * @param leverageLevel The new leverage level to be set for the oracle provider.
     */
    function setLeverageLevel(
        OracleProviderRegistry storage self,
        address oracleProvider,
        uint8 leverageLevel
    ) internal {
        self._leverageLevels[oracleProvider] = leverageLevel;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {InterestRate} from "@chromatic-protocol/contracts/core/libraries/InterestRate.sol";
import {Errors} from "@chromatic-protocol/contracts/core/libraries/Errors.sol";

/**
 * @title SettlementTokenRegistry
 * @dev A registry for managing settlement tokens and their associated parameters.
 */
struct SettlementTokenRegistry {
    /// @dev Set of registered settlement tokens
    EnumerableSet.AddressSet _tokens;
    /// @dev Mapping of settlement tokens to their interest rate records
    mapping(address => InterestRate.Record[]) _interestRateRecords;
    /// @dev Mapping of settlement tokens to their minimum margins
    mapping(address => uint256) _minimumMargins;
    /// @dev Mapping of settlement tokens to their flash loan fee rates
    mapping(address => uint256) _flashLoanFeeRates;
    /// @dev Mapping of settlement tokens to their earning distribution thresholds
    mapping(address => uint256) _earningDistributionThresholds;
    /// @dev Mapping of settlement tokens to their Uniswap fee tiers
    mapping(address => uint24) _uniswapFeeTiers;
}

/**
 * @title SettlementTokenRegistryLib
 * @notice Library for managing the settlement token registry.
 */
library SettlementTokenRegistryLib {
    using EnumerableSet for EnumerableSet.AddressSet;
    using InterestRate for InterestRate.Record[];

    /**
     * @notice Modifier to check if a token is registered in the settlement token registry.
     * @dev Throws an error if the token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the token to check.
     */
    modifier registeredOnly(SettlementTokenRegistry storage self, address token) {
        require(self._tokens.contains(token), Errors.UNREGISTERED_TOKEN);
        _;
    }

    /**
     * @notice Registers a token in the settlement token registry.
     * @dev Throws an error if the token is already registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the token to register.
     * @param minimumMargin The minimum margin for the token.
     * @param interestRate The initial interest rate for the token.
     * @param flashLoanFeeRate The flash loan fee rate for the token.
     * @param earningDistributionThreshold The earning distribution threshold for the token.
     * @param uniswapFeeTier The Uniswap fee tier for the token.
     */
    function register(
        SettlementTokenRegistry storage self,
        address token,
        uint256 minimumMargin,
        uint256 interestRate,
        uint256 flashLoanFeeRate,
        uint256 earningDistributionThreshold,
        uint24 uniswapFeeTier
    ) internal {
        require(self._tokens.add(token), Errors.ALREADY_REGISTERED_TOKEN);

        self._interestRateRecords[token].initialize(interestRate);
        self._minimumMargins[token] = minimumMargin;
        self._flashLoanFeeRates[token] = flashLoanFeeRate;
        self._earningDistributionThresholds[token] = earningDistributionThreshold;
        self._uniswapFeeTiers[token] = uniswapFeeTier;
    }

    /**
     * @notice Returns an array of all registered settlement tokens.
     * @param self The SettlementTokenRegistry storage.
     * @return An array of addresses representing the registered settlement tokens.
     */
    function settlementTokens(
        SettlementTokenRegistry storage self
    ) internal view returns (address[] memory) {
        return self._tokens.values();
    }

    /**
     * @notice Checks if a token is registered in the settlement token registry.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the token to check.
     * @return bool Whether the token is registered.
     */
    function isRegistered(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (bool) {
        return self._tokens.contains(token);
    }

    /**
     * @notice Retrieves the minimum margin for a asettlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the asettlement token.
     * @return uint256 The minimum margin for the asettlement token.
     */
    function getMinimumMargin(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (uint256) {
        return self._minimumMargins[token];
    }

    /**
     * @notice Sets the minimum margin for asettlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param minimumMargin The new minimum margin for the settlement token.
     */
    function setMinimumMargin(
        SettlementTokenRegistry storage self,
        address token,
        uint256 minimumMargin
    ) internal {
        self._minimumMargins[token] = minimumMargin;
    }

    /**
     * @notice Retrieves the flash loan fee rate for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return uint256 The flash loan fee rate for the settlement token.
     */
    function getFlashLoanFeeRate(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (uint256) {
        return self._flashLoanFeeRates[token];
    }

    /**
     * @notice Sets the flash loan fee rate for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param flashLoanFeeRate The new flash loan fee rate for the settlement token.
     */
    function setFlashLoanFeeRate(
        SettlementTokenRegistry storage self,
        address token,
        uint256 flashLoanFeeRate
    ) internal {
        self._flashLoanFeeRates[token] = flashLoanFeeRate;
    }

    /**
     * @notice Retrieves the earning distribution threshold for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return uint256 The earning distribution threshold for the token.
     */
    function getEarningDistributionThreshold(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (uint256) {
        return self._earningDistributionThresholds[token];
    }

    /**
     * @notice Sets the earning distribution threshold for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param earningDistributionThreshold The new earning distribution threshold for the settlement token.
     */
    function setEarningDistributionThreshold(
        SettlementTokenRegistry storage self,
        address token,
        uint256 earningDistributionThreshold
    ) internal {
        self._earningDistributionThresholds[token] = earningDistributionThreshold;
    }

    /**
     * @notice Retrieves the Uniswap fee tier for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return uint24 The Uniswap fee tier for the settlement token.
     */
    function getUniswapFeeTier(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (uint24) {
        return self._uniswapFeeTiers[token];
    }

    /**
     * @notice Sets the Uniswap fee tier for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param uniswapFeeTier The new Uniswap fee tier for the settlement token.
     */
    function setUniswapFeeTier(
        SettlementTokenRegistry storage self,
        address token,
        uint24 uniswapFeeTier
    ) internal {
        self._uniswapFeeTiers[token] = uniswapFeeTier;
    }

    /**
     * @notice Appends an interest rate record for a settlement token.
     * @dev Throws an error if the settlement token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param annualRateBPS The annual interest rate in basis points.
     * @param beginTimestamp The timestamp when the interest rate begins.
     */
    function appendInterestRateRecord(
        SettlementTokenRegistry storage self,
        address token,
        uint256 annualRateBPS,
        uint256 beginTimestamp
    ) internal registeredOnly(self, token) {
        getInterestRateRecords(self, token).appendRecord(annualRateBPS, beginTimestamp);
    }

    /**
     * @notice Removes the last interest rate record for a settlement token.
     * @dev The current time must be less than the begin timestamp of the last record.
     *      Otherwise throws an error with the message `INTEREST_RATE_ALREADY_APPLIED`.
     * @dev Throws an error if the settlement token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return removed Whether the removal was successful
     * @return record The removed interest rate record.
     */
    function removeLastInterestRateRecord(
        SettlementTokenRegistry storage self,
        address token
    )
        internal
        registeredOnly(self, token)
        returns (bool removed, InterestRate.Record memory record)
    {
        (removed, record) = getInterestRateRecords(self, token).removeLastRecord();
    }

    /**
     * @notice Retrieves the current interest rate for a settlement token.
     * @dev Throws an error if the settlement token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return annualRateBPS The current annual interest rate in basis points.
     */
    function currentInterestRate(
        SettlementTokenRegistry storage self,
        address token
    ) internal view registeredOnly(self, token) returns (uint256 annualRateBPS) {
        (InterestRate.Record memory record, ) = getInterestRateRecords(self, token).findRecordAt(
            block.timestamp
        );
        return record.annualRateBPS;
    }

    /**
     * @notice Calculates the interest accrued for a settlement token within a specified time range.
     * @dev Throws an error if the token is not registered.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @param amount The amount of settlement tokens to calculate interest for.
     * @param from The starting timestamp of the interest calculation (inclusive).
     * @param to The ending timestamp of the interest calculation (exclusive).
     * @return uint256 The calculated interest amount.
     */
    function calculateInterest(
        SettlementTokenRegistry storage self,
        address token,
        uint256 amount,
        uint256 from, // timestamp (inclusive)
        uint256 to // timestamp (exclusive)
    ) internal view registeredOnly(self, token) returns (uint256) {
        return getInterestRateRecords(self, token).calculateInterest(amount, from, to);
    }

    /**
     * @notice Retrieves the array of interest rate records for a settlement token.
     * @param self The SettlementTokenRegistry storage.
     * @param token The address of the settlement token.
     * @return The array of interest rate records.
     */
    function getInterestRateRecords(
        SettlementTokenRegistry storage self,
        address token
    ) internal view returns (InterestRate.Record[] storage) {
        return self._interestRateRecords[token];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {ChromaticLiquidator} from "@chromatic-protocol/contracts/core/ChromaticLiquidator.sol";
import {IAutomate, Module, ModuleData} from "@chromatic-protocol/contracts/core/base/gelato/Types.sol";

contract ChromaticLiquidatorMock is ChromaticLiquidator {
    constructor(
        IChromaticMarketFactory _factory,
        address _automate,
        address opsProxyFactory
    ) ChromaticLiquidator(_factory, _automate, opsProxyFactory) {}

    function liquidate(address market, uint256 positionId, uint256 fee) external {
        _liquidate(market, positionId, fee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {ChromaticVault} from "@chromatic-protocol/contracts/core/ChromaticVault.sol";
import {IAutomate, Module, ModuleData} from "@chromatic-protocol/contracts/core/base/gelato/Types.sol";

contract ChromaticVaultMock is ChromaticVault {
    constructor(
        IChromaticMarketFactory _factory,
        address _automate,
        address opsProxyFactory
    ) ChromaticVault(_factory, _automate, opsProxyFactory) {}

    function distributeMakerEarning(address token, uint256 keeperFee) external {
        _distributeMakerEarning(token, keeperFee);
    }

    function distributeMarketEarning(address market, uint256 keeperFee) external {
        _distributeMarketEarning(market, keeperFee);
    }

    function setPendingMarketEarnings(address market, uint256 earning) external {
        pendingMarketEarnings[market] = earning;
    }

    function createMakerEarningDistributionTask(address token) external override {
        // dummy
    }

    function createMarketEarningDistributionTask(address market) external override {
        // dummy
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IKeeperFeePayer} from "@chromatic-protocol/contracts/core/interfaces/IKeeperFeePayer.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";

contract KeeperFeePayerMock is IKeeperFeePayer {
    IChromaticMarketFactory factory;

    modifier onlyFactoryOrDao() {
        require(
            msg.sender == address(factory) || msg.sender == factory.dao(),
            "only factory or DAO can access"
        );
        _;
    }

    modifier onlyVault() {
        require(msg.sender == factory.vault(), "only Vault can access");
        _;
    }

    constructor(IChromaticMarketFactory _factory) {
        factory = _factory;
    }

    // this contrct doesn't have balance
    function approveToRouter(address token, bool approve) external onlyFactoryOrDao {
        IERC20(token).approve(address(this), approve ? type(uint256).max : 0);
    }

    // 1:1 swap
    function payKeeperFee(
        address tokenIn,
        uint256 amountOut,
        address keeperAddress
    ) external onlyVault returns (uint256 amountIn) {
        uint256 tokenBalance = IERC20(tokenIn).balanceOf(address(this));

        amountIn = amountOut;
        require(tokenBalance >= amountIn, "balance of token is not enough");
        require(address(this).balance >= amountOut, "balance of payer contract is not enough");

        // send eth to keeper
        (bool success, ) = keeperAddress.call{value: amountOut}("");
        require(success, "_transfer: ETH transfer failed");

        SafeERC20.safeTransfer(IERC20(tokenIn), msg.sender, tokenBalance - amountIn);
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

import "@equilibria/root/number/types/Fixed18.sol";

interface IOracleProvider {
    /// @dev Error for invalid oracle round
    error InvalidOracleRound();

    /// @dev A singular oracle version with its corresponding data
    struct OracleVersion {
        /// @dev The iterative version
        uint256 version;
        /// @dev the timestamp of the oracle update
        uint256 timestamp;
        /// @dev The oracle price of the corresponding version
        Fixed18 price;
    }

    /**
     * @notice Checks for a new price and updates the internal phase annotation state accordingly
     * @dev `sync` is expected to be called soon after a phase update occurs in the underlying proxy.
     *      Phase updates should be detected using off-chain mechanism and should trigger a `sync` call
     *      This is feasible in the short term due to how infrequent phase updates are, but phase update
     *      and roundCount detection should eventually be implemented at the contract level.
     *      Reverts if there is more than 1 phase to update in a single sync because we currently cannot
     *      determine the startingRoundId for the intermediary phase.
     * @return The current oracle version after sync
     */
    function sync() external returns (OracleVersion memory);

    /**
     * @notice Returns the current oracle version
     * @return oracleVersion Current oracle version
     */
    function currentVersion() external view returns (OracleVersion memory);

    /**
     * @notice Returns the current oracle version
     * @param version The version of which to lookup
     * @return oracleVersion Oracle version at version `version`
     */
    function atVersion(uint256 version) external view returns (OracleVersion memory);

    /**
     * @notice Retrieves the description of the Oracle Provider.
     * @return A string representing the description of the Oracle Provider.
     */
    function description() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IChromaticRouter} from "@chromatic-protocol/contracts/periphery/interfaces/IChromaticRouter.sol";
import {ChromaticAccount} from "@chromatic-protocol/contracts/periphery/ChromaticAccount.sol";

/**
 * @title AccountFactory
 * @dev Abstract contract for creating and managing user accounts.
 */
abstract contract AccountFactory is IChromaticRouter {
    ChromaticAccount private cloneBase;
    address private marketFactory;
    mapping(address => address) private accounts;

    /**
     * @dev Initializes the AccountFactory contract with the provided router and market factory addresses.
     * @param _marketFactory The address of the market factory contract.
     */
    constructor(address _marketFactory) {
        cloneBase = new ChromaticAccount();
        marketFactory = _marketFactory;
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function createAccount() external {
        address owner = msg.sender;
        require(accounts[owner] == address(0));

        ChromaticAccount newAccount = ChromaticAccount(Clones.clone(address(cloneBase)));
        newAccount.initialize(owner, address(this), marketFactory);
        accounts[owner] = address(newAccount);

        emit AccountCreated(address(newAccount), owner);
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function getAccount() external view returns (address) {
        return accounts[msg.sender];
    }

    /**
     * @notice Retrieves the address of a user's account.
     * @param accountAddress The address of the user's account.
     * @return The address of the user's account.
     */
    function getAccount(address accountAddress) internal view returns (address) {
        return accounts[accountAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";

/**
 * @title VerifyCallback
 * @dev Abstract contract for verifying callback functions from registered markets.
 */
abstract contract VerifyCallback {
    address marketFactory;

    /**
     * @dev Throws an error indicating that the caller is not a registered market.
     */
    error NotMarket();

    /**
     * @dev Modifier to verify the callback function is called by a registered market.
     *      Throws an error if the caller is not a registered market.
     */
    modifier verifyCallback() {
        if (!IChromaticMarketFactory(marketFactory).isRegisteredMarket(msg.sender))
            revert NotMarket();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {IChromaticTradeCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticTradeCallback.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {IChromaticAccount} from "@chromatic-protocol/contracts/periphery/interfaces/IChromaticAccount.sol";
import {VerifyCallback} from "@chromatic-protocol/contracts/periphery/base/VerifyCallback.sol";

/**
 * @title ChromaticAccount
 * @dev This contract manages user accounts and positions.
 */
contract ChromaticAccount is IChromaticAccount, VerifyCallback {
    using EnumerableSet for EnumerableSet.UintSet;

    address owner;
    address private router;
    bool isInitialized;

    mapping(address => EnumerableSet.UintSet) private positionIds;

    error NotRouter();
    error NotOwner();
    error AlreadyInitialized();
    error NotEnoughBalance();
    error NotExistPosition();

    /**
     * @dev Modifier that allows only the router to call a function.
     */
    modifier onlyRouter() {
        if (msg.sender != router) revert NotRouter();
        _;
    }

    /**
     * @dev Modifier that allows only the owner to call a function.
     */
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /**
     * @notice Initializes the account with the specified owner, router, and market factory addresses.
     * @param _owner The address of the account owner.
     * @param _router The address of the router contract.
     * @param _marketFactory The address of the market factory contract.
     */
    function initialize(address _owner, address _router, address _marketFactory) external {
        if (isInitialized) revert AlreadyInitialized();
        owner = _owner;
        router = _router;
        isInitialized = true;
        marketFactory = _marketFactory;
    }

    /**
     * @inheritdoc IChromaticAccount
     */
    function balance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @inheritdoc IChromaticAccount
     */
    function withdraw(address token, uint256 amount) external onlyOwner {
        if (balance(token) < amount) revert NotEnoughBalance();
        SafeERC20.safeTransfer(IERC20(token), owner, amount);
    }

    function addPositionId(address market, uint256 positionId) internal {
        positionIds[market].add(positionId);
    }

    function removePositionId(address market, uint256 positionId) internal {
        positionIds[market].remove(positionId);
    }

    /**
     * @inheritdoc IChromaticAccount
     */
    function hasPositionId(address market, uint256 id) public view returns (bool) {
        return positionIds[market].contains(id);
    }

    /**
     * @inheritdoc IChromaticAccount
     */
    function getPositionIds(address market) external view returns (uint256[] memory) {
        return positionIds[market].values();
    }

    /**
     * @inheritdoc IChromaticAccount
     */
    function openPosition(
        address marketAddress,
        int224 qty,
        uint32 leverage,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 maxAllowableTradingFee
    ) external onlyRouter returns (Position memory position) {
        position = IChromaticMarket(marketAddress).openPosition(
            qty,
            leverage,
            takerMargin,
            makerMargin,
            maxAllowableTradingFee,
            bytes("")
        );
        addPositionId(marketAddress, position.id);
    }

    /**
     * @inheritdoc IChromaticAccount
     */
    function closePosition(address marketAddress, uint256 positionId) external override onlyRouter {
        if (!hasPositionId(marketAddress, positionId)) revert NotExistPosition();

        IChromaticMarket(marketAddress).closePosition(positionId);
    }

    /**
     * @inheritdoc IChromaticAccount
     */
    function claimPosition(address marketAddress, uint256 positionId) external override onlyRouter {
        if (!hasPositionId(marketAddress, positionId)) revert NotExistPosition();

        IChromaticMarket(marketAddress).claimPosition(positionId, address(this), bytes(""));
    }

    /**
     * @inheritdoc IChromaticTradeCallback
     */
    function openPositionCallback(
        address settlementToken,
        address vault,
        uint256 marginRequired,
        bytes calldata /* data */
    ) external override verifyCallback {
        if (balance(settlementToken) < marginRequired) revert NotEnoughBalance();

        SafeERC20.safeTransfer(IERC20(settlementToken), vault, marginRequired);
    }

    /**
     * @inheritdoc IChromaticTradeCallback
     */
    function claimPositionCallback(
        uint256 positionId,
        bytes calldata /* data */
    ) external override verifyCallback {
        removePositionId(msg.sender, positionId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
// import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Fixed18, UFixed18, Fixed18Lib} from "@equilibria/root/number/types/Fixed18.sol";
import {IOracleProvider} from "@chromatic-protocol/contracts/oracle/interfaces/IOracleProvider.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";
import {BPS, FEE_RATES_LENGTH} from "@chromatic-protocol/contracts/core/libraries/Constants.sol";
import {IChromaticRouter} from "@chromatic-protocol/contracts/periphery/interfaces/IChromaticRouter.sol";

/**
 * @title ChromaticLens
 * @dev A contract that provides utility functions for interacting with Chromatic markets.
 */
contract ChromaticLens {
    using Math for uint256;

    struct CLBBalance {
        uint256 tokenId;
        uint256 balance;
        uint256 totalSupply;
        uint256 binValue;
    }

    IChromaticRouter router;

    constructor(IChromaticRouter _router) {
        router = _router;
    }

    function multicall(bytes[] calldata data) external view returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i; i < data.length; ) {
            results[i] = Address.functionStaticCall(address(this), data[i]);

            unchecked {
                i++;
            }
        }
        return results;
    }

    /**
     * @dev Retrieves the OracleVersion for the specified oracle version in the given Chromatic market.
     * @param market The address of the Chromatic market contract.
     * @param version An oracle versions.
     * @return oracleVersion The OracleVersion for the specified oracle version.
     */
    function oracleVersion(
        IChromaticMarket market,
        uint256 version
    ) external view returns (IOracleProvider.OracleVersion memory) {
        return market.oracleProvider().atVersion(version);
    }

    /**
     * @dev Retrieves the LP receipts for the specified owner in the given Chromatic market.
     * @param market The address of the Chromatic market contract.
     * @param owner The address of the LP token owner.
     * @return result An array of LpReceipt containing the LP receipts for the owner.
     */
    function lpReceipts(
        IChromaticMarket market,
        address owner
    ) public view returns (LpReceipt[] memory result) {
        uint256[] memory receiptIds = router.getLpReceiptIds(address(market), owner);

        result = new LpReceipt[](receiptIds.length);
        for (uint i; i < receiptIds.length; ) {
            result[i] = market.getLpReceipt(receiptIds[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Retrieves the CLB token balances for the specified owner in the given Chromatic market.
     * @param market The address of the Chromatic market contract.
     * @param owner The address of the CLB token owner.
     * @return An array of CLBBalance containing the CLB token balance information for the owner.
     */
    function clbBalanceOf(
        IChromaticMarket market,
        address owner
    ) external view returns (CLBBalance[] memory) {
        uint256[] memory tokenIds = CLBTokenLib.tokenIds();
        address[] memory accounts = new address[](tokenIds.length);
        // Set all accounts to the owner's address
        for (uint256 i; i < accounts.length; ) {
            accounts[i] = owner;

            unchecked {
                i++;
            }
        }

        // Get balances of CLB tokens for the owner
        uint256[] memory balances = market.clbToken().balanceOfBatch(accounts, tokenIds);

        // Count the number of CLB tokens with non-zero balance
        uint256 effectiveCnt;
        for (uint256 i; i < balances.length; ) {
            if (balances[i] != 0) {
                unchecked {
                    effectiveCnt++;
                }
            }

            unchecked {
                i++;
            }
        }

        uint256[] memory effectiveBalances = new uint256[](effectiveCnt);
        uint256[] memory effectiveTokenIds = new uint256[](effectiveCnt);
        int16[] memory effectiveFeeRates = new int16[](effectiveCnt);

        uint256 idx;
        for (uint256 i; i < balances.length; ) {
            if (balances[i] != 0) {
                effectiveBalances[idx] = balances[i];
                effectiveTokenIds[idx] = tokenIds[i];
                effectiveFeeRates[idx] = CLBTokenLib.decodeId(tokenIds[i]);
                unchecked {
                    idx++;
                }
            }

            unchecked {
                i++;
            }
        }

        uint256[] memory totalSupplies = market.clbToken().totalSupplyBatch(effectiveTokenIds);
        uint256[] memory binValues = market.getBinValues(effectiveFeeRates);

        // Populate the result array with CLB token balance information
        CLBBalance[] memory result = new CLBBalance[](effectiveCnt);
        for (uint256 i; i < effectiveCnt; ) {
            result[i] = CLBBalance({
                tokenId: effectiveTokenIds[i],
                balance: effectiveBalances[i],
                totalSupply: totalSupplies[i],
                binValue: binValues[i]
            });

            unchecked {
                i++;
            }
        }

        return result;
    }

    /**
     * @dev Retrieves the claimable liquidity information for a specific trading fee rate and oracle version from the given Chromatic Market.
     * @param market The Chromatic Market from which to retrieve the claimable liquidity information.
     * @param tradingFeeRate The trading fee rate for which to retrieve the claimable liquidity.
     * @param _oracleVersion The oracle version for which to retrieve the claimable liquidity.
     * @return claimableLiquidity An instance of IChromaticMarket.ClaimableLiquidity representing the claimable liquidity information.
     */
    function claimableLiquidity(
        IChromaticMarket market,
        int16 tradingFeeRate,
        uint256 _oracleVersion
    ) external view returns (IChromaticMarket.ClaimableLiquidity memory) {
        return market.claimableLiquidity(tradingFeeRate, _oracleVersion);
    }

    /**
     * @dev Retrieves the liquidity bin statuses for the specified Chromatic Market.
     * @param market The Chromatic Market contract for which liquidity bin statuses are retrieved.
     * @return statuses An array of LiquidityBinStatus representing the liquidity bin statuses.
     */
    function liquidityBinStatuses(
        IChromaticMarket market
    ) external view returns (IChromaticMarket.LiquidityBinStatus[] memory) {
        return market.liquidityBinStatuses();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SignedMath} from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import {IChromaticMarketFactory} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarketFactory.sol";
import {IChromaticMarket} from "@chromatic-protocol/contracts/core/interfaces/IChromaticMarket.sol";
import {ICLBToken} from "@chromatic-protocol/contracts/core/interfaces/ICLBToken.sol";
import {IChromaticLiquidityCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticLiquidityCallback.sol";
import {CLBTokenLib} from "@chromatic-protocol/contracts/core/libraries/CLBTokenLib.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

import {IChromaticRouter} from "@chromatic-protocol/contracts/periphery/interfaces/IChromaticRouter.sol";
import {AccountFactory} from "@chromatic-protocol/contracts/periphery/base/AccountFactory.sol";
import {VerifyCallback} from "@chromatic-protocol/contracts/periphery/base/VerifyCallback.sol";
import {ChromaticAccount} from "@chromatic-protocol/contracts/periphery/ChromaticAccount.sol";

/**
 * @title ChromaticRouter
 * @dev A router contract that facilitates liquidity provision and trading on Chromatic.
 */
contract ChromaticRouter is AccountFactory, VerifyCallback, Ownable {
    using SignedMath for int256;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @dev Struct representing the data for an addLiquidity callback.
     * @param provider The address of the liquidity provider.
     * @param amount The amount of tokens being added as liquidity.
     */
    struct AddLiquidityCallbackData {
        address provider;
        uint256 amount;
    }

    /**
     * @dev Struct representing the data for an addLiquidityBatch callback.
     * @param provider The address of the liquidity provider.
     * @param amount The amount of tokens being added as liquidity.
     */
    struct AddLiquidityBatchCallbackData {
        address provider;
        uint256 amount;
    }

    /**
     * @dev Struct representing the data for a claimLiquidity callback.
     * @param provider The address of the liquidity provider.
     */
    struct ClaimLiquidityCallbackData {
        address provider;
    }

    /**
     * @dev Struct representing the data for a claimLiquidityBatch callback.
     * @param provider The address of the liquidity provider.
     */
    struct ClaimLiquidityBatchCallbackData {
        address provider;
    }

    /**
     * @dev Struct representing the data for a removeLiquidity callback.
     * @param provider The address of the liquidity provider.
     * @param clbTokenAmount The amount of CLB tokens being removed.
     */
    struct RemoveLiquidityCallbackData {
        address provider;
        uint256 clbTokenAmount;
    }

    /**
     * @dev Struct representing the data for a removeLiquidityBatch callback.
     * @param provider The address of the liquidity provider.
     * @param clbTokenAmounts An array of CLB token amounts being removed.
     */
    struct RemoveLiquidityBatchCallbackData {
        address provider;
        uint256[] clbTokenAmounts;
    }

    /**
     * @dev Struct representing the data for a withdrawLiquidity callback.
     * @param provider The address of the liquidity provider.
     */
    struct WithdrawLiquidityCallbackData {
        address provider;
    }

    /**
     * @dev Struct representing the data for a withdrawLiquidityBatch callback.
     * @param provider The address of the liquidity provider.
     */
    struct WithdrawLiquidityBatchCallbackData {
        address provider;
    }

    mapping(address => mapping(address => EnumerableSet.UintSet)) receiptIds; // market => provider => receiptIds

    error NotExistLpReceipt();

    /**
     * @dev Initializes the ChromaticRouter contract.
     * @param _marketFactory The address of the ChromaticMarketFactory contract.
     */
    constructor(address _marketFactory) onlyOwner AccountFactory(_marketFactory) {
        marketFactory = _marketFactory;
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     */
    function addLiquidityCallback(
        address settlementToken,
        address vault,
        bytes calldata data
    ) external override verifyCallback {
        AddLiquidityCallbackData memory callbackData = abi.decode(data, (AddLiquidityCallbackData));
        SafeERC20.safeTransferFrom(
            IERC20(settlementToken),
            callbackData.provider,
            vault,
            callbackData.amount
        );
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     */
    function addLiquidityBatchCallback(
        address settlementToken,
        address vault,
        bytes calldata data
    ) external override verifyCallback {
        AddLiquidityBatchCallbackData memory callbackData = abi.decode(
            data,
            (AddLiquidityBatchCallbackData)
        );
        SafeERC20.safeTransferFrom(
            IERC20(settlementToken),
            callbackData.provider,
            vault,
            callbackData.amount
        );
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     */
    function claimLiquidityCallback(
        uint256 receiptId,
        bytes calldata data
    ) external override verifyCallback {
        ClaimLiquidityCallbackData memory callbackData = abi.decode(
            data,
            (ClaimLiquidityCallbackData)
        );
        receiptIds[msg.sender][callbackData.provider].remove(receiptId);
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     */
    function claimLiquidityBatchCallback(
        uint256[] calldata _receiptIds,
        bytes calldata data
    ) external override verifyCallback {
        ClaimLiquidityBatchCallbackData memory callbackData = abi.decode(
            data,
            (ClaimLiquidityBatchCallbackData)
        );
        for (uint256 i; i < _receiptIds.length; ) {
            receiptIds[msg.sender][callbackData.provider].remove(_receiptIds[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     */
    function removeLiquidityCallback(
        address clbToken,
        uint256 clbTokenId,
        bytes calldata data
    ) external override verifyCallback {
        RemoveLiquidityCallbackData memory callbackData = abi.decode(
            data,
            (RemoveLiquidityCallbackData)
        );
        IERC1155(clbToken).safeTransferFrom(
            callbackData.provider,
            msg.sender, // market
            clbTokenId,
            callbackData.clbTokenAmount,
            bytes("")
        );
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     */
    function removeLiquidityBatchCallback(
        address clbToken,
        uint256[] calldata clbTokenIds,
        bytes calldata data
    ) external override verifyCallback {
        RemoveLiquidityBatchCallbackData memory callbackData = abi.decode(
            data,
            (RemoveLiquidityBatchCallbackData)
        );

        IERC1155(clbToken).safeBatchTransferFrom(
            callbackData.provider,
            msg.sender, // market
            clbTokenIds,
            callbackData.clbTokenAmounts,
            bytes("")
        );
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     */
    function withdrawLiquidityCallback(
        uint256 receiptId,
        bytes calldata data
    ) external override verifyCallback {
        WithdrawLiquidityCallbackData memory callbackData = abi.decode(
            data,
            (WithdrawLiquidityCallbackData)
        );
        receiptIds[msg.sender][callbackData.provider].remove(receiptId);
    }

    /**
     * @inheritdoc IChromaticLiquidityCallback
     */
    function withdrawLiquidityBatchCallback(
        uint256[] calldata _receiptIds,
        bytes calldata data
    ) external override verifyCallback {
        WithdrawLiquidityBatchCallbackData memory callbackData = abi.decode(
            data,
            (WithdrawLiquidityBatchCallbackData)
        );

        for (uint256 i; i < _receiptIds.length; ) {
            receiptIds[msg.sender][callbackData.provider].remove(_receiptIds[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function openPosition(
        address market,
        int224 qty,
        uint32 leverage,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 maxAllowableTradingFee
    ) external override returns (Position memory) {
        return
            _getAccount(msg.sender).openPosition(
                market,
                qty,
                leverage,
                takerMargin,
                makerMargin,
                maxAllowableTradingFee
            );
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function closePosition(address market, uint256 positionId) external override {
        _getAccount(msg.sender).closePosition(market, positionId);
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function claimPosition(address market, uint256 positionId) external override {
        _getAccount(msg.sender).claimPosition(market, positionId);
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function addLiquidity(
        address market,
        int16 feeRate,
        uint256 amount,
        address recipient
    ) public override returns (LpReceipt memory receipt) {
        bytes memory result = _call(
            market,
            abi.encodeWithSelector(
                IChromaticMarket(market).addLiquidity.selector,
                recipient,
                feeRate,
                abi.encode(AddLiquidityCallbackData({provider: msg.sender, amount: amount}))
            )
        );

        receipt = abi.decode(result, (LpReceipt));
        receiptIds[market][msg.sender].add(receipt.id);
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function claimLiquidity(address market, uint256 receiptId) public override {
        address provider = msg.sender;
        if (!receiptIds[market][provider].contains(receiptId)) revert NotExistLpReceipt();

        _call(
            market,
            abi.encodeWithSelector(
                IChromaticMarket(market).claimLiquidity.selector,
                receiptId,
                abi.encode(ClaimLiquidityCallbackData({provider: provider}))
            )
        );
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function removeLiquidity(
        address market,
        int16 feeRate,
        uint256 clbTokenAmount,
        address recipient
    ) public override returns (LpReceipt memory receipt) {
        bytes memory result = _call(
            market,
            abi.encodeWithSelector(
                IChromaticMarket(market).removeLiquidity.selector,
                recipient,
                feeRate,
                abi.encode(
                    RemoveLiquidityCallbackData({
                        provider: msg.sender,
                        clbTokenAmount: clbTokenAmount
                    })
                )
            )
        );

        receipt = abi.decode(result, (LpReceipt));
        receiptIds[market][msg.sender].add(receipt.id);
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function withdrawLiquidity(address market, uint256 receiptId) public override {
        address provider = msg.sender;
        if (!receiptIds[market][provider].contains(receiptId)) revert NotExistLpReceipt();

        _call(
            market,
            abi.encodeWithSelector(
                IChromaticMarket(market).withdrawLiquidity.selector,
                receiptId,
                abi.encode(WithdrawLiquidityCallbackData({provider: provider}))
            )
        );
    }

    /**
     * @dev Retrieves the account of the specified owner.
     * @param owner The owner of the account.
     * @return The account address.
     */
    function _getAccount(address owner) internal view returns (ChromaticAccount) {
        return ChromaticAccount(getAccount(owner));
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function getLpReceiptIds(address market) external view override returns (uint256[] memory) {
        return getLpReceiptIds(market, msg.sender);
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function getLpReceiptIds(
        address market,
        address owner
    ) public view override returns (uint256[] memory) {
        return receiptIds[market][owner].values();
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function addLiquidityBatch(
        address market,
        address recipient,
        int16[] calldata feeRates,
        uint256[] calldata amounts
    ) external override returns (LpReceipt[] memory lpReceipts) {
        require(feeRates.length == amounts.length, "TradeRouter: invalid arguments");

        uint256 totalAmount;
        for (uint256 i; i < amounts.length; ) {
            totalAmount += amounts[i];

            unchecked {
                i++;
            }
        }

        lpReceipts = IChromaticMarket(market).addLiquidityBatch(
            recipient,
            feeRates,
            amounts,
            abi.encode(AddLiquidityCallbackData({provider: msg.sender, amount: totalAmount}))
        );

        for (uint i; i < feeRates.length; ) {
            receiptIds[market][msg.sender].add(lpReceipts[i].id);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function claimLiquidityBatch(address market, uint256[] calldata _receiptIds) external override {
        IChromaticMarket(market).claimLiquidityBatch(
            _receiptIds,
            abi.encode(ClaimLiquidityBatchCallbackData({provider: msg.sender}))
        );
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function removeLiquidityBatch(
        address market,
        address recipient,
        int16[] calldata feeRates,
        uint256[] calldata clbTokenAmounts
    ) external override returns (LpReceipt[] memory lpReceipts) {
        lpReceipts = IChromaticMarket(market).removeLiquidityBatch(
            recipient,
            feeRates,
            clbTokenAmounts,
            abi.encode(
                RemoveLiquidityBatchCallbackData({
                    provider: msg.sender,
                    clbTokenAmounts: clbTokenAmounts
                })
            )
        );

        for (uint i; i < feeRates.length; ) {
            receiptIds[market][msg.sender].add(lpReceipts[i].id);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @inheritdoc IChromaticRouter
     */
    function withdrawLiquidityBatch(
        address market,
        uint256[] calldata _receiptIds
    ) external override {
        IChromaticMarket(market).withdrawLiquidityBatch(
            _receiptIds,
            abi.encode(WithdrawLiquidityBatchCallbackData({provider: msg.sender}))
        );
    }

    function _call(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory result) = target.call(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IChromaticTradeCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticTradeCallback.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";

/**
 * @title IChromaticAccount
 * @dev Interface for the ChromaticAccount contract, which manages user accounts and positions.
 */
interface IChromaticAccount is IChromaticTradeCallback {
    /**
     * @notice Returns the balance of the specified token for the account.
     * @param token The address of the token.
     * @return The balance of the token.
     */
    function balance(address token) external view returns (uint256);

    /**
     * @notice Withdraws the specified amount of tokens from the account.
     * @param token The address of the token to withdraw.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(address token, uint256 amount) external;

    /**
     * @notice Checks if the specified market has the specified position ID.
     * @param marketAddress The address of the market.
     * @param positionId The ID of the position.
     * @return A boolean indicating whether the market has the position ID.
     */
    function hasPositionId(address marketAddress, uint256 positionId) external view returns (bool);

    /**
     * @notice Retrieves an array of position IDs owned by this account for the specified market.
     * @param marketAddress The address of the market.
     * @return An array of position IDs.
     */
    function getPositionIds(address marketAddress) external view returns (uint256[] memory);

    /**
     * @notice Opens a new position in the specified market.
     * @param marketAddress The address of the market.
     * @param qty The quantity of the position.
     * @param leverage The leverage of the position.
     * @param takerMargin The margin required for the taker.
     * @param makerMargin The margin required for the maker.
     * @param maxAllowableTradingFee The maximum allowable trading fee.
     * @return position The opened position.
     */
    function openPosition(
        address marketAddress,
        int224 qty,
        uint32 leverage,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 maxAllowableTradingFee
    ) external returns (Position memory);

    /**
     * @notice Closes the specified position in the specified market.
     * @param marketAddress The address of the market.
     * @param positionId The ID of the position to close.
     */
    function closePosition(address marketAddress, uint256 positionId) external;

    /**
     * @notice Claims the specified position in the specified market.
     * @param marketAddress The address of the market.
     * @param positionId The ID of the position to claim.
     */
    function claimPosition(address marketAddress, uint256 positionId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IChromaticLiquidityCallback} from "@chromatic-protocol/contracts/core/interfaces/callback/IChromaticLiquidityCallback.sol";
import {Position} from "@chromatic-protocol/contracts/core/libraries/Position.sol";
import {LpReceipt} from "@chromatic-protocol/contracts/core/libraries/LpReceipt.sol";

/**
 * @title IChromaticRouter
 * @dev Interface for the ChromaticRouter contract.
 */
interface IChromaticRouter is IChromaticLiquidityCallback {
    /**
     * @dev Emitted when a new account is created.
     * @param account The address of the created account.
     * @param owner The address of the owner of the created account.
     */
    event AccountCreated(address indexed account, address indexed owner);

    /**
     * @dev Opens a new position in a ChromaticMarket contract.
     * @param market The address of the ChromaticMarket contract.
     * @param qty The quantity of the position.
     * @param leverage The leverage of the position.
     * @param takerMargin The margin amount for the taker.
     * @param makerMargin The margin amount for the maker.
     * @param maxAllowableTradingFee The maximum allowable trading fee.
     * @return position The new position.
     */
    function openPosition(
        address market,
        int224 qty,
        uint32 leverage,
        uint256 takerMargin,
        uint256 makerMargin,
        uint256 maxAllowableTradingFee
    ) external returns (Position memory);

    /**
     * @notice Closes a position in a ChromaticMarket contract.
     * @param market The address of the ChromaticMarket contract.
     * @param positionId The ID of the position to close.
     */
    function closePosition(address market, uint256 positionId) external;

    /**
     * @notice Claims a position from a ChromaticMarket contract.
     * @param market The address of the ChromaticMarket contract.
     * @param positionId The ID of the position to claim.
     */
    function claimPosition(address market, uint256 positionId) external;

    /**
     * @notice Adds liquidity to a ChromaticMarket contract.
     * @param market The address of the ChromaticMarket contract.
     * @param feeRate The fee rate of the liquidity bin.
     * @param amount The amount to add as liquidity.
     * @param recipient The recipient address.
     * @return receipt The LP receipt.
     */
    function addLiquidity(
        address market,
        int16 feeRate,
        uint256 amount,
        address recipient
    ) external returns (LpReceipt memory);

    /**
     * @notice Claims liquidity from a ChromaticMarket contract.
     * @param market The address of the ChromaticMarket contract.
     * @param receiptId The ID of the LP receipt.
     */
    function claimLiquidity(address market, uint256 receiptId) external;

    /**
     * @notice Removes liquidity from a ChromaticMarket contract.
     * @param market The address of the ChromaticMarket contract.
     * @param feeRate The fee rate of the liquidity bin.
     * @param clbTokenAmount The amount of CLB tokens to remove as liquidity.
     * @param recipient The recipient address.
     * @return receipt The LP receipt.
     */
    function removeLiquidity(
        address market,
        int16 feeRate,
        uint256 clbTokenAmount,
        address recipient
    ) external returns (LpReceipt memory);

    /**
     * @notice Withdraws liquidity from a ChromaticMarket contract.
     * @param market The address of the ChromaticMarket contract.
     * @param receiptId The ID of the LP receipt.
     */
    function withdrawLiquidity(address market, uint256 receiptId) external;

    /**
     * @notice Creates a new user account.
     * @dev Only one account can be created per user.
     *      Emits an `AccountCreated` event upon successful creation.
     */
    function createAccount() external;

    /**
     * @notice Retrieves the account of the caller.
     * @return The account address.
     */
    function getAccount() external view returns (address);

    /**
     * @notice Retrieves the LP receipt IDs of the caller for the specified market.
     * @param market The address of the ChromaticMarket contract.
     * @return An array of LP receipt IDs.
     */
    function getLpReceiptIds(address market) external view returns (uint256[] memory);

    /**
     * @notice Get the LP receipt IDs associated with a specific market and owner.
     * @param market The address of the ChromaticMarket contract.
     * @param owner The address of the owner.
     * @return An array of LP receipt IDs.
     */
    function getLpReceiptIds(
        address market,
        address owner
    ) external view returns (uint256[] memory);

    /**
     * @notice Adds liquidity to multiple liquidity bins of ChromaticMarket contract in a batch.
     * @param market The address of the ChromaticMarket contract.
     * @param recipient The address of the recipient for each liquidity bin.
     * @param feeRates An array of fee rates for each liquidity bin.
     * @param amounts An array of amounts to add as liquidity for each bin.
     * @return lpReceipts An array of LP receipts.
     */
    function addLiquidityBatch(
        address market,
        address recipient,
        int16[] calldata feeRates,
        uint256[] calldata amounts
    ) external returns (LpReceipt[] memory lpReceipts);

    /**
     * @notice Claims liquidity from multiple ChromaticMarket contracts in a batch.
     * @param market The address of the ChromaticMarket contract.
     * @param receiptIds An array of LP receipt IDs to claim liquidity from.
     */
    function claimLiquidityBatch(address market, uint256[] calldata receiptIds) external;

    /**
     * @notice Removes liquidity from multiple ChromaticMarket contracts in a batch.
     * @param market The address of the ChromaticMarket contract.
     * @param recipient The address of the recipient for each liquidity bin.
     * @param feeRates An array of fee rates for each liquidity bin.
     * @param clbTokenAmounts An array of CLB token amounts to remove as liquidity for each bin.
     * @return lpReceipts An array of LP receipts.
     */
    function removeLiquidityBatch(
        address market,
        address recipient,
        int16[] calldata feeRates,
        uint256[] calldata clbTokenAmounts
    ) external returns (LpReceipt[] memory lpReceipts);

    /**
     * @notice Withdraws liquidity from multiple ChromaticMarket contracts in a batch.
     * @param market The address of the ChromaticMarket contract.
     * @param receiptIds An array of LP receipt IDs to withdraw liquidity from.
     */
    function withdrawLiquidityBatch(address market, uint256[] calldata receiptIds) external;
}