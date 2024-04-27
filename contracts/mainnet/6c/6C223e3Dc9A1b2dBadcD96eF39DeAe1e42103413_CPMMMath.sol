// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Math Library
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @dev Library for performing various math operations
library GSMath {
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    /// @dev Returns the square root of `a`.
    /// @param a number to square root
    /// @return z square root of a
    function sqrt(uint256 a) internal pure returns (uint256 z) {
        if (a == 0) return 0;

        assembly {
            z := 181 // Should be 1, but this saves a multiplication later.

            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, a))
            r := or(shl(6, lt(0xffffffffffffffffff, shr(r, a))), r)
            r := or(shl(5, lt(0xffffffffff, shr(r, a))), r)
            r := or(shl(4, lt(0xffffff, shr(r, a))), r)
            z := shl(shr(1, r), z)

            // Doesn't overflow since y < 2**136 after above.
            z := shr(18, mul(z, add(shr(r, a), 65536))) // A mul() saved from z = 181.

            // Given worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))

            // If x+1 is a perfect square, the Babylonian method cycles between floor(sqrt(x)) and ceil(sqrt(x)).
            // We always return floor. Source https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(a, z), z))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/// @title Interface for CPMM Math library
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Interface to call math functions to perform calculations used in CPMM strategies
interface ICPMMMath {

    /// @param delta - quantity of token0 bought from CFMM to achieve max collateral
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param fee1 - trading fee numerator
    /// @param fee2 - trading fee denominator
    /// @return collateral - max collateral liquidity value of tokensHeld after trade using deltas given reserves in CFMM
    function calcCollateralPostTrade(uint256 delta, uint256 tokensHeld0, uint256 tokensHeld1, uint256 reserve0,
        uint256 reserve1, uint256 fee1, uint256 fee2) external view returns(uint256 collateral);

    /// @dev Calculate quantities to trade to rebalance collateral (`tokensHeld`) to the desired `ratio`
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param fee1 - trading fee numerator
    /// @param fee2 - trading fee denominator
    /// @param decimals0 - decimals of token0
    /// @return deltas - quadratic roots (quantities to trade). The first quadratic root (index 0) is the only feasible trade
    function calcDeltasForMaxLP(uint256 tokensHeld0, uint256 tokensHeld1, uint256 reserve0, uint256 reserve1,
        uint256 fee1, uint256 fee2, uint8 decimals0) external view returns(int256[] memory deltas);

    /// @dev Calculate quantities to trade to rebalance collateral (`tokensHeld`) to the desired `ratio`
    /// @param liquidity - liquidity debt that needs to be repaid after rebalancing loan's collateral quantities
    /// @param ratio0 - numerator (token0) of desired ratio we wish collateral (`tokensHeld`) to have
    /// @param ratio1 - denominator (token1) of desired ratio we wish collateral (`tokensHeld`) to have
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param decimals0 - decimals of token0
    /// @return deltas - quadratic roots (quantities to trade). The first quadratic root (index 0) is the only feasible trade
    function calcDeltasToCloseSetRatio(uint256 liquidity, uint256 ratio0, uint256 ratio1, uint256 tokensHeld0, uint256 tokensHeld1,
        uint256 reserve0, uint256 reserve1, uint8 decimals0) external view returns(int256[] memory deltas);

    /// @dev how much collateral to trade to have enough to close a position
    /// @param liquidity - liquidity debt that needs to be repaid after rebalancing loan's collateral quantities
    /// @param lastCFMMInvariant - most up to date invariant in CFMM
    /// @param collateral - collateral invariant of loan to rebalance (not token quantities, but their geometric mean)
    /// @param reserve - reserve quantity of token to trade in CFMM
    /// @return delta - quantity of token to trade (> 0 means buy, < 0 means sell)
    function calcDeltasToClose(uint256 liquidity, uint256 lastCFMMInvariant, uint256 collateral, uint256 reserve)
        external pure returns(int256 delta);

    /// @dev Calculate quantities to trade to rebalance collateral (`tokensHeld`) to the desired `ratio`
    /// @param ratio0 - numerator (token0) of desired ratio we wish collateral (`tokensHeld`) to have
    /// @param ratio1 - denominator (token1) of desired ratio we wish collateral (`tokensHeld`) to have
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantity of token0 in CFMM
    /// @param reserve1 - reserve quantity of token1 in CFMM
    /// @param fee1 - trading fee numerator
    /// @param fee2 - trading fee denominator
    /// @return deltas - quadratic roots (quantities to trade). The first quadratic root (index 0) is the only feasible trade
    function calcDeltasForRatio(uint256 ratio0, uint256 ratio1, uint256 tokensHeld0, uint256 tokensHeld1,
        uint256 reserve0, uint256 reserve1, uint256 fee1, uint256 fee2) external view returns(int256[] memory deltas);

    /// @dev Calculate deltas to rebalance collateral for withdrawal while maintaining desired ratio
    /// @param amount - amount of token0 requesting to withdraw
    /// @param ratio0 - numerator of desired ratio to maintain after withdrawal (token0)
    /// @param ratio1 - denominator of desired ratio to maintain after withdrawal (token1)
    /// @param tokensHeld0 - quantities of token0 available in loan as collateral
    /// @param tokensHeld1 - quantities of token1 available in loan as collateral
    /// @param reserve0 - reserve quantities of token0 in CFMM
    /// @param reserve1 - reserve quantities of token1 in CFMM
    /// @param fee1 - trading fee numerator
    /// @param fee2 - trading fee denominator
    /// @return deltas - quantities of reserve tokens to rebalance after withdrawal. The second quadratic root (index 1) is the only feasible trade
    function calcDeltasForWithdrawal(uint256 amount, uint256 ratio0, uint256 ratio1, uint256 tokensHeld0, uint256 tokensHeld1,
        uint256 reserve0, uint256 reserve1, uint256 fee1, uint256 fee2) external view returns(int256[] memory deltas);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.21;

import "@gammaswap/v1-core/contracts/libraries/GSMath.sol";
import "../../interfaces/math/ICPMMMath.sol";
import "../FullMath.sol";

/// @title Math library for CPMM strategies
/// @author Daniel D. Alcarraz (https://github.com/0xDanr)
/// @notice Math library for complex computations for CPMM strategies
contract CPMMMath is ICPMMMath {

    error ZeroTokensHeld();
    error ZeroReserves();
    error ZeroFees();
    error ZeroRatio();
    error ZeroDecimals();
    error ComplexNumber();

    /// @dev See {ICPMMMath-calcCollateralPostTrade}
    function calcCollateralPostTrade(uint256 delta, uint256 tokensHeld0, uint256 tokensHeld1, uint256 reserve0, uint256 reserve1,
        uint256 fee1, uint256 fee2) external override virtual view returns(uint256 collateral) {
        if(tokensHeld0 == 0 || tokensHeld1 == 0) revert ZeroTokensHeld();
        if(reserve0 == 0 || reserve1 == 0) revert ZeroReserves();
        if(fee1 == 0 || fee2 == 0) revert ZeroFees();

        uint256 soldToken = reserve1 * delta * fee2 / ((reserve0 - delta) * fee1) + 1;
        require(soldToken <= tokensHeld1, "SOLD_TOKEN_GT_TOKENS_HELD1");

        tokensHeld1 -= soldToken;
        tokensHeld0 += delta;
        collateral = GSMath.sqrt(tokensHeld0 * tokensHeld1);
    }

    function calcDeterminant512(uint256 a, uint256 b, uint256 c0, uint256 c1, bool cIsNeg) internal virtual view returns(uint256 det) {
        // sqrt(b^2 - 4*a*c) because a is positive
        (uint256 leftVal0, uint256 leftVal1) = FullMath.mul256x256(b, b);
        (uint256 rightVal0, uint256 rightVal1) = FullMath.mul512x256(c0, c1, a);
        (rightVal0, rightVal1) = FullMath.mul512x256(rightVal0, rightVal1, 4);

        if(cIsNeg) {
            //sqrt(b^2 + 4*a*c)
            (leftVal0, leftVal1) = FullMath.add512x512(leftVal0, leftVal1, rightVal0, rightVal1);
            det = FullMath.sqrt512(leftVal0, leftVal1);// since both are expanded, will contract to correct value
        } else {
            //sqrt(b^2 - 4*a*c)
            if(FullMath.lt512(leftVal0, leftVal1, rightVal0, rightVal1)) revert ComplexNumber();// results in imaginary number
            (leftVal0, leftVal1) = FullMath.sub512x512(leftVal0, leftVal1, rightVal0, rightVal1);
            det = FullMath.sqrt512(leftVal0, leftVal1);
        }
    }

    function calcDeterminant(uint256 a, uint256 b, uint256 c, bool cIsNeg) internal virtual view returns(uint256 det) {
        // sqrt(b^2 - 4*a*c) because a is positive
        (uint256 leftVal0, uint256 leftVal1) = FullMath.mul256x256(b, b);
        (uint256 rightVal0, uint256 rightVal1) = FullMath.mul256x256(a, c);
        (rightVal0, rightVal1) = FullMath.mul512x256(rightVal0, rightVal1, 4);

        if(cIsNeg) {
            //sqrt(b^2 + 4*a*c)
            (leftVal0, leftVal1) = FullMath.add512x512(leftVal0, leftVal1, rightVal0, rightVal1);
            det = FullMath.sqrt512(leftVal0, leftVal1);// since both are expanded, will contract to correct value
        } else {
            //sqrt(b^2 - 4*a*c)
            if(FullMath.lt512(leftVal0, leftVal1, rightVal0, rightVal1)) revert ComplexNumber();// results in imaginary number
            (leftVal0, leftVal1) = FullMath.sub512x512(leftVal0, leftVal1, rightVal0, rightVal1);
            det = FullMath.sqrt512(leftVal0, leftVal1);
        }
    }

    function calcWithdrawalDeterminant(uint256 b, uint256 c, bool cIsNeg) internal virtual view returns(uint256 det) {
        // sqrt(b^2 - 4*c)
        (uint256 leftVal0, uint256 leftVal1) = FullMath.mul256x256(b, b); // expanded
        (uint256 rightVal0, uint256 rightVal1) = FullMath.mul256x256(c, 4); // previously expanded

        if(cIsNeg) {
            (leftVal0, leftVal1) = FullMath.add512x512(leftVal0, leftVal1, rightVal0, rightVal1);
            det = FullMath.sqrt512(leftVal0, leftVal1); // since both are expanded, will contract to correct value
        } else {
            if(FullMath.lt512(leftVal0, leftVal1, rightVal0, rightVal1)) revert ComplexNumber();// results in imaginary number
            (leftVal0, leftVal1) = FullMath.sub512x512(leftVal0, leftVal1, rightVal0, rightVal1);
            det = FullMath.sqrt512(leftVal0, leftVal1); // since both are expanded, will contract to correct value
        }
    }

    function calcForRatioDeterminant(uint256 b, uint256 c, uint256 ratio0, uint256 ratio1, bool cIsNeg) internal virtual view returns(uint256 det) {
        // sqrt(b^2 + 4*a*c) because a is negative
        (uint256 leftVal0, uint256 leftVal1) = FullMath.mul256x256(b, b);
        (uint256 rightVal0, uint256 rightVal1) = FullMath.mulDiv512(4*c, ratio1, ratio0);

        if(cIsNeg) {
            //sqrt(b^2 - 4*a*c)
            if(FullMath.lt512(leftVal0, leftVal1, rightVal0, rightVal1)) revert ComplexNumber();// results in imaginary number
            (leftVal0, leftVal1) = FullMath.sub512x512(leftVal0, leftVal1, rightVal0, rightVal1);
            det = FullMath.sqrt512(leftVal0, leftVal1);
        } else {
            //sqrt(b^2 + 4*a*c)
            (leftVal0, leftVal1) = FullMath.add512x512(leftVal0, leftVal1, rightVal0, rightVal1);
            det = FullMath.sqrt512(leftVal0, leftVal1);
        }
    }

    /// @dev See {ICPMMMath-calcDeltasForRatio}
    /// @notice The calculation takes into consideration the market impact the transaction would have
    /// @notice The equation is derived from solving the quadratic root formula taking into account trading fees
    /// @notice This equation should always result in a recommendation to purchase token0 (a positive number)
    /// @notice Since a negative quadratic root means selling, if the result is negative, then the result is wrong
    /// @notice We can flip the reserves, tokensHeld, and ratio to turn a purchase of token0 into a sale of token0
    function calcDeltasForMaxLP(uint256 tokensHeld0, uint256 tokensHeld1, uint256 reserve0, uint256 reserve1,
        uint256 fee1, uint256 fee2, uint8 decimals0) external virtual override view returns(int256[] memory deltas) {
        if(tokensHeld0 == 0 || tokensHeld1 == 0) revert ZeroTokensHeld();
        if(reserve0 == 0 || reserve1 == 0) revert ZeroReserves();
        if(fee1 == 0 || fee2 == 0) revert ZeroFees();
        if(decimals0 == 0) revert ZeroDecimals();
        // fee = fee1 / fee2 => fee2 > fee1 always
        // a = fee * (B_hat + B)
        uint256 a;
        {
            a = fee1 * (reserve1 + tokensHeld1) / fee2;
        }

        // b = -[2 * A_hat * B * fee + (L_hat ^ 2) * (1 + fee) + A * B_hat * (1 - fee)]
        //   = -[2 * A_hat * B * fee1 / fee2 + (L_hat ^ 2) * (fee2 + fee1) / fee2 + A * B_hat * (fee2 - fee1) / fee2];
        // b is always negative because fee2 > fee1 always
        uint256 b;
        {
            b = 2 * tokensHeld1 * (reserve0 * fee1 / fee2);
            b = b + reserve0 * (reserve1 * (fee2 + fee1) / fee2);
            b = b + tokensHeld0 * (reserve1 * (fee2 - fee1) / fee2);
            b = b / (10 ** decimals0);
        }

        // c = A_hat * fee * (B * A_hat - A * B_hat)
        //   = A_hat * (B * A_hat - A * B_hat) * fee1 / fee2
        bool cIsNeg;
        uint256 c;
        uint256 det;
        {
            c = tokensHeld1 * reserve0;
            uint256 rightVal = tokensHeld0 * reserve1;
            (cIsNeg,c) = c > rightVal ? (false,c - rightVal) : (true,rightVal - c);
            c = c / (10**decimals0);
            (c, det) = FullMath.mulDiv512(c, (reserve0 * fee1), (10**decimals0) * fee2);
        }

        if(det > 0) {
            det = calcDeterminant512(a, b, c, det, cIsNeg);
        } else {
            det = calcDeterminant(a, b, c, cIsNeg);
        }

        deltas = new int256[](2);
        // remember that a is always positive and b is always negative
        // root = (-b +/- det)/(2a)
        // plus version
        // (-b + det)/2a = (b + det)/2a
        // this is always positive
        deltas[0] = int256(FullMath.mulDiv256((b + det), (10 ** decimals0), (2 * a)));

        // minus version
        // (-b - det)/-2a = (b - det)/2a
        if(b > det) {
            // x2 is positive
            deltas[1] = int256(FullMath.mulDiv256((b - det), (10 ** decimals0), (2 * a)));
        } else {
            // x2 is negative
            deltas[1]= -int256(FullMath.mulDiv256((det - b), (10 ** decimals0), (2 * a)));
        }
    }

    /// @dev See {ICPMMMath-calcDeltasToCloseSetRatio}
    /// @notice The calculation takes into consideration the market impact the transaction would have
    /// @notice The equation is derived from solving the quadratic root formula taking into a   ccount trading fees
    /// @notice This equation should always result in a recommendation to purchase token0 (a positive number)
    /// @notice Since a negative quadratic root means selling, if the result is negative, then the result is wrong
    /// @notice We can flip the reserves, tokensHeld, and ratio to turn a purchase of token0 into a sale of token0
    function calcDeltasToCloseSetRatio(uint256 liquidity, uint256 ratio0, uint256 ratio1, uint256 tokensHeld0, uint256 tokensHeld1,
        uint256 reserve0, uint256 reserve1, uint8 decimals0) external virtual override view returns(int256[] memory deltas) {
        if(tokensHeld0 == 0 || tokensHeld1 == 0) revert ZeroTokensHeld();
        if(reserve0 == 0 || reserve1 == 0) revert ZeroReserves();
        if(ratio0 == 0 || ratio1 == 0) revert ZeroRatio();
        if(decimals0 == 0) revert ZeroDecimals();
        // phi = liquidity / lastCFMMInvariant
        //     = L / L_hat

        // a = P * (1 + phi)
        //   = ratio1 * (1 + phi) / ratio0
        //   = ratio1 * (phiDec + phi) / ratio0
        //   = ratio1 * (L_hat + L) / (L_hat * ratio0)
        //   = ratio1 * (1 + L/L_hat) / ratio0
        //   = [ratio1 + (ratio1 * L / L_hat)] * decimals0 / ratio0
        //   = (ratio1 / ratio0) + (ratio1 * liquidity) / (ratio0 * lastCFMMInvariant)
        //   = (ratio1 * lastCFMMInvariant + ratio1 * liquidity) / (ratio0 * lastCFMMInvariant)
        //   = ratio1 * (lastCFMMInvariant + liquidity) / (ratio0 * lastCFMMInvariant)
        //   = [ratio1 * (lastCFMMInvariant + liquidity) / ratio0 ] / lastCFMMInvariant
        //   = [ratio1 * (lastCFMMInvariant + liquidity) / ratio0 ] * invDecimals / lastCFMMInvariant
        uint256 a;
        bool bIsNeg;
        uint256 b;
        {
            uint256 lastCFMMInvariant = GSMath.sqrt(reserve0 * reserve1);
            a = FullMath.mulDiv256(liquidity + lastCFMMInvariant, ratio1 * (10**decimals0), lastCFMMInvariant * ratio0);

            // b = -(P * (A_hat * (2 * phi + 1) - A) + B + B_hat)
            //   = -(P * (A_hat * 2 * phi + A_hat - A) + B + B_hat)
            //   = -(P * A_hat * 2 * phi + P * A_hat - P * A + B + B_hat)
            //   = -(P * (A_hat * 2 * phi + A_hat - A) + B + B_hat)
            //   = -(P * (A_hat * 2 * liquidity / lastCFMMInvariant + A_hat - A) + B + B_hat)
            //   = -([ratio1 * (A_hat * 2 * liquidity / lastCFMMInvariant + A_hat - A) / ratio0] + B _ B_hat)
            {
                b = reserve0 * 2 * liquidity / lastCFMMInvariant + reserve0;
                (bIsNeg, b) = b > tokensHeld0 ? (false, (b - tokensHeld0)) : (true, (tokensHeld0 - b));
                b = FullMath.mulDiv256(b, ratio1, ratio0);
                uint256 rightVal = reserve1 + tokensHeld1;
                if(bIsNeg) { // the sign changes because b is ultimately negated
                    (bIsNeg, b) = b > rightVal ? (false,b - rightVal) : (true,rightVal - b);
                } else {
                    (bIsNeg, b) = (true,b + rightVal);
                }
            }
        }
        // c = A_hat * [B - P * (A - A_hat * phi)] - L * L_hat
        //   = A_hat * [B - P * A + P * A_hat * phi] - L * L_hat
        //   = A_hat * B - A_hat * P * A + (A_hat ^ 2) * P * phi - L * L_hat
        //   = A_hat * B - A_hat * P * A + (A_hat ^ 2) * P * L / L_hat - L * L_hat;
        //   = A_hat * B - A_hat * P * A + [(A_hat ^ 2) * P / L_hat - L_hat] * L;
        //   = A_hat * B - A_hat * P * A + [(A_hat ^ 2) * P - L_hat ^ 2] * L / L_hat;
        //   = A_hat * B - A_hat * P * A + [(A_hat ^ 2) * P - A_hat * B_hat] * L / L_hat;
        //   = A_hat * B - A_hat * P * A + A_hat * [A_hat * P - B_hat] * L / L_hat;
        //   = A_hat * [B - P * A + (A_hat * P - B_hat) * L / L_hat];
        //   = A_hat * [B - P * A - (B_hat - A_hat * P) * L / L_hat];
        //   = - A_hat * [P * A + (B_hat - A_hat * P) * L / L_hat - B];
        bool cIsNeg;
        uint256 c;
        {
            c = reserve0 * ratio1 / ratio0;
            (cIsNeg,c) = reserve1 > c ? (false,reserve1 - c) : (true, c - reserve1);
            c = FullMath.mulDiv256(c, liquidity, GSMath.sqrt(reserve0 * reserve1));
            if(cIsNeg) {
                c = c + tokensHeld1;
                uint256 leftVal = tokensHeld0 * ratio1 / ratio0;
                (cIsNeg,c) = leftVal > c ? (false, leftVal - c) : (true, c - leftVal);
            } else {
                c = c + tokensHeld0 * ratio1 / ratio0;
                (cIsNeg,c) = c > tokensHeld1 ? (false,c - tokensHeld1) : (true,tokensHeld1 - c);
            }

            (cIsNeg,c) = (!cIsNeg, FullMath.mulDiv256(reserve0, c, (10 ** decimals0)));
        }

        uint256 det = calcDeterminant(a, b, c, cIsNeg);

        deltas = new int256[](2);
        // remember that a is always positive
        // root = (-b +/- det)/(2a)
        if(bIsNeg) { // b < 0
            // plus version
            // (-b + det)/2a = (b + det)/2a
            // this is always positive
            deltas[0] = int256(FullMath.mulDiv256((b + det), (10**decimals0), (2 * a)));

            // minus version
            // (-b - det)/-2a = (b - det)/2a
            if(b > det) {
                // x2 is positive
                deltas[1] = int256(FullMath.mulDiv256((b - det), (10**decimals0), (2 * a)));
            } else {
                // x2 is negative
                deltas[1]= -int256(FullMath.mulDiv256((det - b), (10**decimals0), (2 * a)));
            }
        } else { // b > 0
            // plus version
            // (-b + det)/2a = (det - b)/2a
            if(det > b) {
                //  x1 is positive
                deltas[0] = int256(FullMath.mulDiv256((det - b), (10**decimals0), (2 * a)));
            } else {
                //  x1 is negative
                deltas[0] = -int256(FullMath.mulDiv256((b - det), (10**decimals0), (2 * a)));
            }

            // minus version
            // (-b - det)/-2a = -(b + det)/2a
            deltas[1] = -int256(FullMath.mulDiv256((b + det), (10**decimals0), (2 * a)));
        }
    }

    /// @dev See {ICPMMMath-calcDeltasToClose}
    /// @notice how much collateral to trade to have enough to close a position
    /// @notice reserve and collateral have to be of the same token
    /// @notice if > 0 => have to buy token to have exact amount of token to close position
    /// @notice if < 0 => have to sell token to have exact amount of token to close position
    function calcDeltasToClose(uint256 liquidity, uint256 lastCFMMInvariant, uint256 collateral, uint256 reserve)
        external virtual override pure returns(int256 delta) {
        require(lastCFMMInvariant > 0, "ZERO_CFMM_INVARIANT");
        require(collateral > 0, "ZERO_COLLATERAL");
        if(reserve == 0) revert ZeroReserves();

        uint256 left = reserve * liquidity;
        uint256 right = collateral * lastCFMMInvariant;
        bool isNeg = right > left;
        uint256 _delta = (isNeg ? right - left : left - right) / (lastCFMMInvariant + liquidity) + 1;
        delta = isNeg ? -int256(_delta) : int256(_delta);
    }

    /// @dev See {ICPMMMath-calcDeltasForRatio}
    /// @notice The calculation takes into consideration the market impact the transaction would have
    /// @notice The equation is derived from solving the quadratic root formula taking into account trading fees
    /// @notice This equation should always result in a recommendation to purchase token0 (a positive number)
    /// @notice Since a negative quadratic root means selling, if the result is negative, then the result is wrong
    /// @notice We can flip the reserves, tokensHeld, and ratio to turn a purchase of token0 into a sale of token0
    function calcDeltasForRatio(uint256 ratio0, uint256 ratio1, uint256 tokensHeld0, uint256 tokensHeld1,
        uint256 reserve0, uint256 reserve1, uint256 fee1, uint256 fee2) external virtual override view returns(int256[] memory deltas) {
        if(tokensHeld0 == 0 || tokensHeld1 == 0) revert ZeroTokensHeld();
        if(reserve0 == 0 || reserve1 == 0) revert ZeroReserves();
        if(ratio0 == 0 || ratio1 == 0) revert ZeroRatio();
        if(fee1 == 0 || fee2 == 0) revert ZeroFees();
        // a = -P*fee
        //   = -ratio1 * fee1 / (ratio0 * fee2)
        // must negate
        bool bIsNeg;
        uint256 b;
        {
            // b = (A_hat - A)*P*fee + (B*fee + B_hat)
            //   = (A_hat - A)*(ratio1/ratio0)*(fee1/fee2) + (B*fee1/fee2 + B_hat)
            //   = [(A_hat*ratio1*fee1 - A*ratio1*fee1) / ratio0 + B*fee1] / fee2 + B_hat
            uint256 leftVal;
            {
                uint256 A_hat_x_ratio1_x_fee1 = reserve0 * ratio1 * fee1;
                uint256 A_x_ratio1_x_fee1 = tokensHeld0 * ratio1 * fee1;
                bIsNeg = A_hat_x_ratio1_x_fee1 < A_x_ratio1_x_fee1;
                leftVal = (bIsNeg ? A_x_ratio1_x_fee1 - A_hat_x_ratio1_x_fee1 : A_hat_x_ratio1_x_fee1 - A_x_ratio1_x_fee1) / ratio0;
            }
            if(bIsNeg) {
                // [B*fee1 - leftVal] / fee2 + B_hat
                uint256 B_x_fee1 = tokensHeld1 * fee1;
                bIsNeg = B_x_fee1 < leftVal;
                if(!bIsNeg) {
                    b = (B_x_fee1 - leftVal) / fee2 + reserve1;
                } else {
                    leftVal = (leftVal - B_x_fee1) / fee2; // remains negative
                    // B_hat - leftVal1
                    bIsNeg = reserve1 < leftVal;
                    b = bIsNeg ? leftVal - reserve1 : reserve1 - leftVal;
                }
            } else {
                // [leftVal + B*fee1] / fee2 + B_hat
                b = (leftVal + tokensHeld1 * fee1) / fee2 + reserve1;
            }
        }

        bool cIsNeg;
        uint256 c;
        {
            // c = (A*P - B)*A_hat*fee
            //   = (A*ratio1/ratio0 - B)*A_hat*fee1/fee2
            //   = [(A*ratio1*fee1/ratio0)*A_hat - B*A_hat*fee1]/fee2
            c = tokensHeld0 * ratio1;
            reserve1 = fee1 * reserve0;
            reserve1 = FullMath.mulDiv256(c, reserve1, ratio0);
            uint256 leftVal = reserve1;
            uint256 rightVal = tokensHeld1 * reserve0 * fee1;
            cIsNeg = leftVal < rightVal;
            c = (cIsNeg ? rightVal - leftVal : leftVal - rightVal) / fee2;
        }

        reserve0 = fee2 * ratio0;
        reserve1 = fee1 * ratio1;
        uint256 det = calcForRatioDeterminant(b, c, reserve0, reserve1, cIsNeg);

        deltas = new int256[](2);
        // remember that a is always negative
        // root = (-b +/- det)/(2a)
        if(bIsNeg) { // b < 0
            // plus version
            // (b + det)/-2a = -(b + det)/2a
            // this is always negative
            deltas[0] = -int256(FullMath.mulDiv256((b + det), fee2 * ratio0, (2 * fee1 * ratio1)));

            // minus version
            // (b - det)/-2a = (det-b)/2a
            if(det > b) {
                // x2 is positive
                deltas[1] = int256(FullMath.mulDiv256((det - b), fee2 * ratio0, (2 * fee1 * ratio1)));
            } else {
                // x2 is negative
                deltas[1]= -int256(FullMath.mulDiv256((b - det), fee2 * ratio0, (2 * fee1 * ratio1)));
            }
        } else { // b > 0
            // plus version
            // (-b + det)/-2a = (b - det)/2a
            if(b > det) {
                //  x1 is positive
                deltas[0] = int256(FullMath.mulDiv256((b - det), fee2 * ratio0, (2 * fee1 * ratio1)));
            } else {
                //  x1 is negative
                deltas[0] = -int256(FullMath.mulDiv256((det - b), fee2 * ratio0, (2 * fee1 * ratio1)));
            }

            // minus version
            // (-b - det)/-2a = (b+det)/2a
            deltas[1] = int256(FullMath.mulDiv256((b + det), fee2 * ratio0, (2 * fee1 * ratio1)));
        }
    }

    /// @dev See {ICPMMMath-calcDeltasForWithdrawal}.
    /// @notice The calculation takes into consideration the market impact the transaction would have
    /// @notice The equation is derived from solving the quadratic root formula taking into account trading fees
    /// @notice This equation should always result in a recommendation to purchase token0 (a positive number)
    /// @notice Since a negative quadratic root means selling, if the result is negative, then the result is wrong
    /// @notice We can flip the reserves, tokensHeld, and ratio to turn a purchase of token0 into a sale of token0
    function calcDeltasForWithdrawal(uint256 amount, uint256 ratio0, uint256 ratio1, uint256 tokensHeld0, uint256 tokensHeld1,
        uint256 reserve0, uint256 reserve1, uint256 fee1, uint256 fee2) external virtual override view returns(int256[] memory deltas) {
        if(tokensHeld0 == 0 || tokensHeld1 == 0) revert ZeroTokensHeld();
        if(reserve0 == 0 || reserve1 == 0) revert ZeroReserves();
        if(ratio0 == 0 || ratio1 == 0) revert ZeroRatio();
        if(fee1 == 0 || fee2 == 0) revert ZeroFees();
        // a = 1
        bool bIsNeg;
        uint256 b;
        {
            // b = -[C + A_hat - A + (1/P)*(B + B_hat/fee)]
            //   = -C - A_hat + A - [(B/P) + B_hat/(fee*P)]
            //   = -[C + A_hat] + A - [(B/P) + B_hat/(fee*P)]
            //   = -[C + A_hat] + A - [(B + B_hat/fee)(1/P)]
            //   = -[C + A_hat] + A - [(B + B_hat*fee2/fee1)*ratio0/ratio1]
            //   = -[C + A_hat] + A - [(B*ratio0 + B_hat*fee2*ratio0/fee1)/ratio1]
            //   = A - [(B*ratio0 + B_hat*fee2*ratio0/fee1)/ratio1] - [C + A_hat]
            //   = A - ([(B*ratio0 + B_hat*fee2*ratio0/fee1)/ratio1] + [C + A_hat])
            uint256 rightVal = (tokensHeld1 * ratio0 * fee1 + reserve1 * fee2 * ratio0) / (fee1 * ratio1) + (amount + reserve0);
            bIsNeg = rightVal > tokensHeld0;
            b = bIsNeg ? rightVal - tokensHeld0 : tokensHeld0 - rightVal;
        }

        bool cIsNeg;
        uint256 c;
        {
            // c = -A_hat*(A - C - B/P)
            //   = -A_hat*A + A_hat*C + A_hat*B/P
            //   = -A_hat*A + A_hat*C + A_hat*B*ratio0/ratio1
            //   = A_hat*C + A_hat*B*ratio0/ratio1 - A_hat*A
            reserve1 = FullMath.mulDiv256(reserve0, tokensHeld1 * ratio0, ratio1);
            uint256 leftVal = reserve0 * amount + reserve1;
            uint256 rightVal = reserve0 * tokensHeld0;
            cIsNeg = rightVal > leftVal;
            c = cIsNeg ? rightVal - leftVal : leftVal - rightVal; // remains expanded
        }

        deltas = new int256[](2);
        uint256 det = calcWithdrawalDeterminant(b, c, cIsNeg);

        // a is not needed since it's just 1
        // root = [-b +/- det] / 2
        if(bIsNeg) {
            // [b +/- det] / 2
            // plus version: (b + det) / 2
            deltas[0] = int256((b + det) / 2);

            // minus version: (b - det) / 2
            if(b > det) {
                deltas[1] = int256((b - det) / 2);
            } else {
                deltas[1] = -int256((det - b) / 2);
            }
        } else {
            // [-b +/- det] / 2
            // plus version: (det - b) / 2
            if(det > b) {
                deltas[0] = int256((det - b) / 2);
            } else {
                deltas[0] = -int256((b - det) / 2);
            }

            // minus version: -(b + det) / 2
            deltas[1] = -int256((b + det) / 2);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷c) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param c The divisor
    /// @return r The 256-bit result
    function mulDiv256(uint256 a, uint256 b, uint256 c) internal pure returns(uint256) {
        (uint256 r0, uint256 r1) = mulDiv512(a, b, c);

        require(r1 == 0, "MULDIV_OVERFLOW");

        return r0;
    }

    /// @notice Calculates floor(a×b÷c) with full precision and returns a 512 bit number. Never overflows
    /// @notice Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param c The divisor
    /// @return r0 lower bits of result of division
    /// @return r1 lower bits of result of division
    function mulDiv512(uint256 a, uint256 b, uint256 c) internal pure returns(uint256 r0, uint256 r1) {
        require(c != 0, "MULDIV_ZERO_DIVISOR");

        // mul256x256
        uint256 a0;
        uint256 a1;
        assembly {
            let mm := mulmod(a, b, not(0))
            a0 := mul(a, b)
            a1 := sub(sub(mm, a0), lt(mm, a0))
        }

        // div512x256
        (r0, r1) = div512x256(a0, a1, c);
    }

    /// @notice Calculates the remainder of a division of a 512 bit unsigned integer by a 256 bit integer.
    /// @param a0 A uint256 representing the low bits of the numerator.
    /// @param a1 A uint256 representing the high bits of the numerator.
    /// @param b A uint256 representing the denominator.
    /// @return rem A uint256 representing the remainder of the division.
    function divRem512x256(uint256 a0, uint256 a1, uint256 b) internal pure returns(uint256 rem) {
        require(b != 0, "DIVISION_BY_ZERO");

        assembly {
            rem := mulmod(a1, not(0), b)
            rem := addmod(rem, a1, b)
            rem := addmod(rem, a0, b)
        }
    }

    /// @notice Calculates the division of a 512 bit unsigned integer by a 256 bit integer.
    /// @dev Source https://medium.com/wicketh/mathemagic-512-bit-division-in-solidity-afa55870a65
    /// @param a0 uint256 representing the lower bits of the numerator.
    /// @param a1 uint256 representing the higher bits of the numerator.
    /// @param b uint256 denominator.
    /// @return r0 lower bits of the uint512 quotient.
    /// @return r1 higher bits of the uint512 quotient.
    function div512x256(uint256 a0, uint256 a1, uint256 b) internal pure returns(uint256 r0, uint256 r1) {
        require(b != 0, "DIVISION_BY_ZERO");

        if(a1 == 0) {
            return (a0 / b, 0);
        }

        if(b == 1) {
            return (a0, a1);
        }

        uint256 q;
        uint256 r;

        assembly {
            q := add(div(sub(0, b), b), 1)
            r := mod(sub(0, b), b)
        }

        uint256 t0;
        uint256 t1;

        while(a1 != 0) {
            assembly {
                // (t0,t1) = a1 x q
                let mm := mulmod(a1, q, not(0))
                t0 := mul(a1, q)
                t1 := sub(sub(mm, t0), lt(mm, t0))

                // (r0,r1) = (r0,r1) + (t0,t1)
                let tmp := add(r0, t0)
                r1 := add(add(r1, t1), lt(tmp, r0))
                r0 := tmp

                // (t0,t1) = a1 x r
                mm := mulmod(a1, r, not(0))
                t0 := mul(a1, r)
                t1 := sub(sub(mm, t0), lt(mm, t0))

                // (a0,a1) = (t0,t1) + (a0,0)
                a0 := add(t0, a0)
                a1 := add(add(t1, 0), lt(a0, t0))
            }
        }

        assembly {
            let tmp := add(r0, div(a0,b))
            r1 := add(add(r1, 0), lt(tmp, r0))
            r0 := tmp
        }

        return (r0, r1);
    }

    /// @notice Calculate the product of two uint256 numbers. Never overflows
    /// @dev Source https://medium.com/wicketh/mathemagic-full-multiply-27650fec525d
    /// @param a first number (uint256).
    /// @param b second number (uint256).
    /// @return r0 The result as an uint512. (lower bits).
    /// @return r1 The result as an uint512. (higher bits).
    function mul256x256(uint256 a, uint256 b) internal pure returns (uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /// @notice Calculates the product of a uint512 and a uint256 number
    /// @dev Source https://medium.com/wicketh/mathemagic-512-bit-division-in-solidity-afa55870a65
    /// @param a0 lower bits of first number.
    /// @param a1 higher bits of first number.
    /// @param b second number (uint256).
    /// @return r0 The result as an uint512. (lower bits).
    /// @return r1 The result as an uint512. (higher bits).
    function mul512x256(uint256 a0, uint256 a1, uint256 b) internal pure returns (uint256 r0, uint256 r1) {
        uint256 ff;

        assembly {
            let mm := mulmod(a0, b, not(0))
            r0 := mul(a0, b)
            let cc := sub(sub(mm, r0), lt(mm, r0)) // carry from a0*b

            mm := mulmod(a1, b, not(0))
            let ab := mul(a1, b)
            ff := sub(sub(mm, ab), lt(mm, ab)) // carry from a1*b

            r1 := add(cc, ab)

            ff := or(ff, lt(r1,ab)) // overflow from (a0,a1)*b
        }

        require(ff < 1, "MULTIPLICATION_OVERFLOW");
    }

    /// @notice Calculates the sum of two uint512 numbers
    /// @dev Source https://medium.com/wicketh/mathemagic-512-bit-division-in-solidity-afa55870a65
    /// @param a0 lower bits of first number.
    /// @param a1 higher bits of first number.
    /// @param b0 lower bits of second number.
    /// @param b1 higher bits of second number.
    /// @return r0 The result as an uint512. (lower bits).
    /// @return r1 The result as an uint512. (higher bits).
    function add512x512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns (uint256 r0, uint256 r1) {
        uint256 ff;

        assembly {
            let rr := add(a1, b1)
            ff := lt(rr, a1)  // carry from a1+b1
            r0 := add(a0, b0)
            r1 := add(rr, lt(r0, a0)) // add carry from a0+b0
            ff := or(ff,lt(r1, rr))
        }

        require(ff < 1, "ADDITION_OVERFLOW");
    }

    /// @notice Calculates the difference of two uint512 numbers
    /// @dev Source https://medium.com/wicketh/mathemagic-512-bit-division-in-solidity-afa55870a65
    /// @param a0 lower bits of first number.
    /// @param a1 higher bits of first number.
    /// @param b0 lower bits of second number.
    /// @param b1 higher bits of second number.
    /// @return r0 The result as an uint512. (lower bits).
    /// @return r1 The result as an uint512. (higher bits).
    function sub512x512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns (uint256 r0, uint256 r1) {
        require(ge512(a0, a1, b0, b1), "SUBTRACTION_UNDERFLOW");

        assembly {
            r0 := sub(a0, b0)
            r1 := sub(sub(a1, b1), lt(a0, b0))
        }
    }

    /// @dev Returns the square root of `a`.
    /// @param a number to square root
    /// @return z square root of a
    function sqrt256(uint256 a) internal pure returns (uint256 z) {
        if (a == 0) return 0;

        assembly {
            z := 181 // Should be 1, but this saves a multiplication later.

            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, a))
            r := or(shl(6, lt(0xffffffffffffffffff, shr(r, a))), r)
            r := or(shl(5, lt(0xffffffffff, shr(r, a))), r)
            r := or(shl(4, lt(0xffffff, shr(r, a))), r)
            z := shl(shr(1, r), z)

            // Doesn't overflow since y < 2**136 after above.
            z := shr(18, mul(z, add(shr(r, a), 65536))) // A mul() saved from z = 181.

            // Given worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))
            z := shr(1, add(div(a, z), z))

            // If x+1 is a perfect square, the Babylonian method cycles between floor(sqrt(x)) and ceil(sqrt(x)).
            // We always return floor. Source https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            z := sub(z, lt(div(a, z), z))
        }
    }

    /// @notice Calculates the square root of a 512 bit unsigned integer, rounds down.
    /// @dev Uses Karatsuba Square Root method. Source https://hal.inria.fr/inria-00072854/document.
    /// @param a0 lower bits of 512 bit number.
    /// @param a1 higher bits of 512 bit number.
    /// @return z The square root as an uint256 of a 512 bit number.
    function sqrt512(uint256 a0, uint256 a1) internal pure returns (uint256 z) {
        if (a1 == 0) return sqrt256(a0);

        uint256 shift;

        assembly {
            let bits := mul(128, lt(a1, 0x100000000000000000000000000000000))
            shift := add(bits, shift)
            a1 := shl(bits, a1)

            bits := mul(64, lt(a1, 0x1000000000000000000000000000000000000000000000000))
            shift := add(bits, shift)
            a1 := shl(bits, a1)

            bits := mul(32, lt(a1, 0x100000000000000000000000000000000000000000000000000000000))
            shift := add(bits, shift)
            a1 := shl(bits, a1)

            bits := mul(16, lt(a1, 0x1000000000000000000000000000000000000000000000000000000000000))
            shift := add(bits, shift)
            a1 := shl(bits, a1)

            bits := mul(8, lt(a1, 0x100000000000000000000000000000000000000000000000000000000000000))
            shift := add(bits, shift)
            a1 := shl(bits, a1)

            bits := mul(4, lt(a1, 0x1000000000000000000000000000000000000000000000000000000000000000))
            shift := add(bits, shift)
            a1 := shl(bits, a1)

            bits := mul(2, lt(a1, 0x4000000000000000000000000000000000000000000000000000000000000000))
            shift := add(bits, shift)
            a1 := shl(bits, a1)

            a1 := or(shr(sub(256, shift), a0), a1)
            a0 := shl(shift, a0)
        }

        uint256 z1 = sqrt256(a1);

        assembly {
            let rz := sub(a1, mul(z1, z1))
            let numerator := or(shl(128, rz), shr(128, a0))
            let denominator := shl(1, z1)

            let q := div(numerator, denominator)
            let r := mod(numerator, denominator)

            let carry := shr(128, rz)
            let x := mul(carry, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)

            q := add(div(x, denominator), q)
            r := add(add(carry, mod(x, denominator)), r)
            q := add(div(r, denominator), q)
            r := mod(r, denominator)

            z := add(shl(128, z1), q)

            let rl := or(shl(128, r), and(a0, 0xffffffffffffffffffffffffffffffff))

            z := sub(z,gt(or(lt(shr(128, r),shr(128,q)),and(eq(shr(128, r), shr(128,q)),lt(rl,mul(q,q)))),0))
            z := shr(div(shift,2), z)
        }
    }

    function eq512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns (bool) {
        return a1 == b1 && a0 == b0;
    }

    function gt512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns (bool) {
        return a1 > b1 || (a1 == b1 && a0 > b0);
    }

    function lt512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns (bool) {
        return a1 < b1 || (a1 == b1 && a0 < b0);
    }

    function ge512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns (bool) {
        return a1 > b1 || (a1 == b1 && a0 >= b0);
    }

    function le512(uint256 a0, uint256 a1, uint256 b0, uint256 b1) internal pure returns (bool) {
        return a1 < b1 || (a1 == b1 && a0 <= b0);
    }
}