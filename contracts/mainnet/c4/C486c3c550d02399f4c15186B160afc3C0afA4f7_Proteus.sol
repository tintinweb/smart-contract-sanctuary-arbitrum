// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity =0.8.10;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {ILiquidityPoolImplementation, SpecifiedToken} from "./ILiquidityPoolImplementation.sol";
import {Slices} from "./Slices.sol";

contract Proteus is ILiquidityPoolImplementation, Slices {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for int256;

    uint256 private constant INT_MAX = uint256(type(int256).max);
    int128 private constant ABDK_ONE = int128(int256(1 << 64));
    int128 private constant ABDK_TWO = int128(int256(2 << 64));
    // When a token has 18 decimals, this is one microtoken
    int256 private constant MIN_BALANCE = 10**12;
    // The maximum slope (balance of y reserve) / (balance of x reserve)
    // This limits the pool to having at most 10**8 y for each x.
    int128 private constant MAX_M = 0x5f5e1000000000000000000;
    // The minimum slope (balance of y reserve) / (balance of x reserve)
    // This limits the pool to having at most 10**8 x for each y.
    int128 private constant MIN_M = 0x00000000000002af31dc461;
    // This limits the pool to inputting or outputting
    uint256 private constant MAX_BALANCE_AMOUNT_RATIO = 10**11;
    // Equivalent to roughly two and a half basis points since fee is applied twice.
    uint256 public constant BASE_FEE = 8000;
    // When a token has 18 decimals, this is 1 nanotoken
    uint256 private constant FIXED_FEE = 10**9;
    bool private constant FEE_UP = true;
    bool private constant FEE_DOWN = false;

    error BoundaryError();
    error AmountError();
    error CurveError();
    error BalanceError();

    constructor(
        int128[] memory ms,
        int128[] memory _as,
        int128[] memory bs,
        int128[] memory ks
    ) Slices(ms, _as, bs, ks) {
        // External calls with enums rely on both contracts using the same
        // mapping between enum fields and uint8 values.
        assert(uint8(SpecifiedToken.X) == 0);
        assert(uint8(SpecifiedToken.Y) == 1);
    }

    /**
     * @dev Given an input amount of a reserve token, we compute an output
     *  amount of the other reserve token, keeping utility invariant.
     * @dev We use FEE_DOWN because we want to decrease the perceived
     *  input amount and decrease the observed output amount.
     */
    function swapGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 inputAmount,
        SpecifiedToken inputToken
    ) external view returns (uint256 outputAmount) {
        require(
            inputAmount < INT_MAX && xBalance < INT_MAX && yBalance < INT_MAX
        );
        _checkAmountWithBalance(
            inputToken == SpecifiedToken.X ? xBalance : yBalance,
            inputAmount
        );
        int256 result = _swap(
            FEE_DOWN,
            int256(inputAmount),
            int256(xBalance),
            int256(yBalance),
            inputToken
        );
        require(result < 0);
        outputAmount = uint256(-result);
        _checkAmountWithBalance(
            inputToken == SpecifiedToken.X ? yBalance : xBalance,
            outputAmount
        );
    }

    /**
     * @dev Given an output amount of a reserve token, we compute an input
     *  amount of the other reserve token, keeping utility invariant.
     * @dev We use FEE_UP because we want to increase the perceived output
     *  amount and increase the observed input amount.
     */
    function swapGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 outputAmount,
        SpecifiedToken outputToken
    ) external view returns (uint256 inputAmount) {
        require(
            outputAmount < INT_MAX && xBalance < INT_MAX && yBalance < INT_MAX
        );
        _checkAmountWithBalance(
            outputToken == SpecifiedToken.X ? xBalance : yBalance,
            outputAmount
        );
        int256 result = _swap(
            FEE_UP,
            -int256(outputAmount),
            int256(xBalance),
            int256(yBalance),
            outputToken
        );
        require(result > 0);
        inputAmount = uint256(result);
        _checkAmountWithBalance(
            outputToken == SpecifiedToken.X ? yBalance : xBalance,
            inputAmount
        );
    }

    /**
     * @dev Given an input amount of a reserve token, we compute an output
     *  amount of LP tokens, scaling the total supply of the LP tokens with the
     *  utility of the pool.
     * @dev We use FEE_DOWN because we want to decrease the perceived amount
     *  deposited and decrease the amount of LP tokens minted.
     */
    function depositGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 depositedAmount,
        SpecifiedToken depositedToken
    ) external view returns (uint256 mintedAmount) {
        require(
            depositedAmount < INT_MAX &&
                xBalance < INT_MAX &&
                yBalance < INT_MAX &&
                totalSupply < INT_MAX
        );
        int256 result = _reserveTokenSpecified(
            depositedToken,
            int256(depositedAmount),
            FEE_DOWN,
            int256(totalSupply),
            int256(xBalance),
            int256(yBalance)
        );
        require(result > 0);
        mintedAmount = uint256(result);
    }

    /**
     * @dev Given an output amount of the LP token, we compute an amount of
     *  a reserve token that must be deposited to scale the utility of the pool
     *  in proportion to the change in total supply of the LP token.
     * @dev We use FEE_UP because we want to increase the perceived change in
     *  total supply and increase the observed amount deposited.
     */
    function depositGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 mintedAmount,
        SpecifiedToken depositedToken
    ) external view returns (uint256 depositedAmount) {
        require(
            mintedAmount < INT_MAX &&
                xBalance < INT_MAX &&
                yBalance < INT_MAX &&
                totalSupply < INT_MAX
        );
        int256 result = _lpTokenSpecified(
            depositedToken,
            int256(mintedAmount),
            FEE_UP,
            int256(totalSupply),
            int256(xBalance),
            int256(yBalance)
        );
        require(result > 0);
        depositedAmount = uint256(result);
    }

    /**
     * @dev Given an output amount of a reserve token, we compute an amount of
     *  LP tokens that must be burned in order to decrease the total supply in
     *  proportion to the decrease in utility.
     * @dev We use FEE_UP because we want to increase the perceived amount
     *  withdrawn from the pool and increase the observed decrease in total
     *  supply.
     */
    function withdrawGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 withdrawnAmount,
        SpecifiedToken withdrawnToken
    ) external view returns (uint256 burnedAmount) {
        require(
            withdrawnAmount < INT_MAX &&
                xBalance < INT_MAX &&
                yBalance < INT_MAX &&
                totalSupply < INT_MAX
        );
        int256 result = _reserveTokenSpecified(
            withdrawnToken,
            -int256(withdrawnAmount),
            FEE_UP,
            int256(totalSupply),
            int256(xBalance),
            int256(yBalance)
        );
        require(result < 0);
        burnedAmount = uint256(-result);
    }

    /**
     * @dev Given an input amount of the LP token, we compute an amount of
     *  a reserve token that must be output to decrease the pool's utility in
     *  proportion to the pool's decrease in total supply of the LP token.
     * @dev We use FEE_UP because we want to increase the perceived amount of
     *  reserve tokens leaving the pool and to increase the observed amount of
     *  LP tokens being burned.
     */
    function withdrawGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 burnedAmount,
        SpecifiedToken withdrawnToken
    ) external view returns (uint256 withdrawnAmount) {
        require(
            burnedAmount < INT_MAX &&
                xBalance < INT_MAX &&
                yBalance < INT_MAX &&
                totalSupply < INT_MAX
        );
        int256 result = _lpTokenSpecified(
            withdrawnToken,
            -int256(burnedAmount),
            FEE_DOWN,
            int256(totalSupply),
            int256(xBalance),
            int256(yBalance)
        );
        require(result < 0);
        withdrawnAmount = uint256(-result);
    }

    /**
     * @dev From a starting point (xi, yi), we can begin a swap in four ways:
     *  [+x, -x, +y, -y]. This function abstracts over those four ways using
     *  the specifiedToken parameter and the sign of the specifiedAmount
     *  integer.
     * @dev A starting coordinate can be combined with the specified amount
     *  to find a known final coordinate. A final coordinate and a final
     *  utility can be used to determine the final point.
     * @dev Using the final point and the initial point, we can find how much
     *  of the non-specified token must enter or leave the pool in order to
     *  keep utility invariant.
     * @dev see notes above _findFinalPoint for information on direction
     *  and other variables declared in this scope.
     */
    function _swap(
        bool feeDirection,
        int256 specifiedAmount,
        int256 xi,
        int256 yi,
        SpecifiedToken specifiedToken
    ) internal view returns (int256 computedAmount) {
        int256 roundedSpecifiedAmount;
        {
            roundedSpecifiedAmount = _applyFeeByRounding(
                specifiedAmount,
                feeDirection
            );
        }

        int256 xf;
        int256 yf;
        {
            int128[] memory slopes = getSlopes();
            uint256 i = _findSlice(slopes, xi, yi);

            int128[] memory _as = getAs();
            int128[] memory bs = getBs();
            int128[] memory ks = getKs();
            int256 utility = _getUtility(xi, yi, _as[i], bs[i], ks[i]);

            if (specifiedToken == SpecifiedToken.X) {
                int256 fixedPoint = xi + roundedSpecifiedAmount;
                int256 direction = (roundedSpecifiedAmount < 0)
                    ? int256(1)
                    : int256(-1);
                (xf, yf) = _findFinalPoint(
                    fixedPoint,
                    direction,
                    utility,
                    i,
                    _getPointGivenXandUtility,
                    slopes,
                    _as,
                    bs,
                    ks
                );
            } else {
                int256 fixedPoint = yi + roundedSpecifiedAmount;
                int256 direction = (roundedSpecifiedAmount < 0)
                    ? int256(-1)
                    : int256(1);
                (xf, yf) = _findFinalPoint(
                    fixedPoint,
                    direction,
                    utility,
                    i,
                    _getPointGivenYandUtility,
                    slopes,
                    _as,
                    bs,
                    ks
                );
            }
        }

        if (specifiedToken == SpecifiedToken.X) {
            computedAmount = _applyFeeByRounding(yf - yi, feeDirection);
            _checkBalances(xi + specifiedAmount, yi + computedAmount);
        } else {
            computedAmount = _applyFeeByRounding(xf - xi, feeDirection);
            _checkBalances(xi + computedAmount, yi + specifiedAmount);
        }
    }

    /**
     * @dev When performing a deposit given an input amount or a withdraw
     *  given an output amount, we know the initial point and final point,
     *  which allows us to find the initial utility and final utility.
     * @dev With the initial utility and final utility, we need to change
     *  the total supply in proportion to the change in utility.
     */
    function _reserveTokenSpecified(
        SpecifiedToken specifiedToken,
        int256 specifiedAmount,
        bool feeDirection,
        int256 si,
        int256 xi,
        int256 yi
    ) internal view returns (int256 computedAmount) {
        int256 xf;
        int256 yf;
        int256 ui;
        int256 uf;
        {
            if (specifiedToken == SpecifiedToken.X) {
                xf = xi + _applyFeeByRounding(specifiedAmount, feeDirection);
                yf = yi;
            } else {
                yf = yi + _applyFeeByRounding(specifiedAmount, feeDirection);
                xf = xi;
            }
        }
        {
            int128[] memory slopes = getSlopes();
            int128[] memory _as = getAs();
            int128[] memory bs = getBs();
            int128[] memory ks = getKs();
            {
                uint256 i = _findSlice(slopes, xi, yi);
                ui = _getUtility(xi, yi, _as[i], bs[i], ks[i]);
            }
            {
                uint256 j = _findSlice(slopes, xf, yf);
                uf = _getUtility(xf, yf, _as[j], bs[j], ks[j]);
            }
        }

        uint256 result = Math.mulDiv(uint256(uf), uint256(si), uint256(ui));
        require(result < INT_MAX);
        int256 sf = int256(result);
        computedAmount = _applyFeeByRounding(sf - si, feeDirection);
    }

    /**
     * @dev When performing a deposit given an output amount or a withdraw
     *  given an input amount, we know the initial total supply and the final
     *  total supply.
     * @dev Given the change in total supply, we need to find how much of a
     *  reserve token we need to take in or give out in order to change the
     *  pool's utility in proportion to the pool's change in total supply.
     * @dev see notes above _findFinalPoint for information on direction
     *  and other variables declared in this scope.
     */
    function _lpTokenSpecified(
        SpecifiedToken specifiedToken,
        int256 specifiedAmount,
        bool feeDirection,
        int256 si,
        int256 xi,
        int256 yi
    ) internal view returns (int256 computedAmount) {
        int128[] memory slopes = getSlopes();
        int128[] memory _as = getAs();
        int128[] memory bs = getBs();
        int128[] memory ks = getKs();

        (int256 uf, uint256 i) = _getUtilityFinalLp(
            si,
            si + _applyFeeByRounding(specifiedAmount, feeDirection),
            xi,
            yi,
            slopes,
            _as,
            bs,
            ks
        );

        int256 xf;
        int256 yf;
        if (specifiedToken == SpecifiedToken.X) {
            int256 direction = (specifiedAmount < 0) ? int256(1) : int256(-1);
            (xf, yf) = _findFinalPoint(
                yi,
                direction,
                uf,
                i,
                _getPointGivenYandUtility,
                slopes,
                _as,
                bs,
                ks
            );
        } else {
            int256 direction = (specifiedAmount < 0) ? int256(-1) : int256(1);
            (xf, yf) = _findFinalPoint(
                xi,
                direction,
                uf,
                i,
                _getPointGivenXandUtility,
                slopes,
                _as,
                bs,
                ks
            );
        }

        if (specifiedToken == SpecifiedToken.X) {
            computedAmount = _applyFeeByRounding(xf - xi, feeDirection);
            _checkBalances(xi + computedAmount, yf);
        } else {
            computedAmount = _applyFeeByRounding(yf - yi, feeDirection);
            _checkBalances(xf, yi + computedAmount);
        }
    }

    /// @dev extracted to avoid stack-too-deep errors
    function _getUtilityFinalLp(
        int256 si,
        int256 sf,
        int256 xi,
        int256 yi,
        int128[] memory slopes,
        int128[] memory _as,
        int128[] memory bs,
        int128[] memory ks
    ) internal pure returns (int256 uf, uint256 i) {
        require(sf >= MIN_BALANCE);
        i = _findSlice(slopes, xi, yi);
        int256 ui = _getUtility(xi, yi, _as[i], bs[i], ks[i]);
        uint256 result = Math.mulDiv(uint256(ui), uint256(sf), uint256(si));
        require(result < INT_MAX);
        uf = int256(result);
    }

    /**
     * @dev This function leverages several properties of proteus to find
     *  the final state of the balances after an action. These properties are:
     *   1. There is always a known coordinate. We always know at least one of
     *      xf or yf. In swaps we know the specified token (ti + amount == tf).
     *      In deposits or withdrawals, we know the non-specified token
     *      (ti == tf).
     *   2. There is always a known utility. During swaps utility is invariant
     *      (ui == uf).  During deposits or withdrawals, utility varies linearly
     *      with the known change in total supply of the LP token.
     *   3. There is only one slice (with parameters a, b, k and boundary
     *      slopes mLeft, mRight) of the piecewise curve where recovering the
     *      unknown coordinate from the known coordinate and know utility will
     *      result in a pair of coordinates that lie within the slice.
     *   4. Given initial slice i, the final slice
     *   5. We search to the left when the amount of y is increasing or the
     *      amount of x is decreasing.  We search to the right when the amount
     *      of x is increasing or the amount of y is decreasing. The slice
     *      parameters are stored starting with the slice along the x-axis
     *      and ending with the slice along the y-axis. To search to the left,
     *      we increment i.  To search to the right, we decrement i.
     * @param fixedCoordinate Known coordinate
     * @param direction Search direction. Either -1 (right) or +1 (left)
     * @param utility Known utility
     * @param i Initially the starting slice. Maintains search state.
     * @param getPoint Function that uses the known coordinate and the known
     *  utility to compute the unknown coordinate. Returns a point (x, y).
     * @param slopes y/x slopes that bound the slices of the piecewise curve
     * @param _as Horizontal shifts (x + a) of the piecewise curve
     * @param bs Vertical shifts (y + b) of the piecewise curve
     * @param ks Relative liquidity of the slice in comparison to the 0th slice
     */
    function _findFinalPoint(
        int256 fixedCoordinate,
        int256 direction,
        int256 utility,
        uint256 i,
        function(int256, int256, int128, int128, int128)
            pure
            returns (int256, int256) getPoint,
        int128[] memory slopes,
        int128[] memory _as,
        int128[] memory bs,
        int128[] memory ks
    ) internal pure returns (int256 xf, int256 yf) {
        (xf, yf) = getPoint(fixedCoordinate, utility, _as[i], bs[i], ks[i]);
        while (_pointIsNotInSlice(slopes, i, xf, yf)) {
            i = _next(i, direction);
            (xf, yf) = getPoint(fixedCoordinate, utility, _as[i], bs[i], ks[i]);
        }
    }

    /**
     * @dev Utility is the pool's internal measure of how much value it holds
     * @dev The pool values the x reserve and y reserve based on how much of
     *  one it holds compared to the other. The higher ratio of y to x, the
     *  less it values y compared to x.
     * @dev Proteus uses piecewise hyperbolas that are scaled by utility u, and
     *  relative liquidity k, and translated horizontally by a and vertically
     *  by b.
     * @dev the equation for a curve in a slice is:
     *  k(ab - 1)u**2 + (ay + bx)u + xy/k = 0
     *  where y/x determines what slice we are in, utility is comparable
     *  between slices, and the combination of a, b, and k determine the prices
     *  at both edges of the slice, which determines rate of change of price
     *  within the slice, which changes the magnitude of price impact for a
     *  trade of a given size within the slice.
     * @dev isolate u in the equation using the quadratic formula above gives us two solutions. 
     *  We always want the larger solution
     */
    function _getUtility(
        int256 x,
        int256 y,
        int128 a,
        int128 b,
        int128 k
    ) internal pure returns (int256 utility) {

        int256 aQuad = k.mul(a.mul(b).sub(ABDK_ONE)).muli(1e18);
        int256 bQuad = a.muli(y) + b.muli(x);
        int256 cQuad = (x * y) / k.muli(1e18);

        int256 disc = int256(Math.sqrt(uint256((bQuad**2) - (aQuad * cQuad * 4))));
        int256 r0 = ((-bQuad + disc) * 1e18) / (2 * aQuad);
        int256 r1 = ((-bQuad - disc) * 1e18) / (2 * aQuad);

        if(a < 0 && b < 0){
            utility = (r0 > r1) ? r1 : r0;
        } else {
            utility = (r0 > r1) ? r0 : r1;
        }
        
        if (utility < 0) {
            revert CurveError();
        }
    }

    /**
     * @dev Given a utility and a bonding curve (a, b, k) and one coordinate
     *  of a point on that curve, we can find the other coordinate of the
     *  point.
     * @dev the equation for a curve in a slice is:
     *  ((x / (ku)) + a) ((y / (ku)) + b) = 1 (see _getUtility notes)
     * @dev Isolating y in the equation above gives us the equation:
     *  y = (k^2 u^2)/(a k u + x) - b k u
     * @dev This function returns x as xf because we want to be able to call
     *  getPointGivenX and getPointGivenY and handle the returned values
     *  without caring about which particular function is was called.
     */
    function _getPointGivenXandUtility(
        int256 x,
        int256 utility,
        int128 a,
        int128 b,
        int128 k
    ) internal pure returns (int256 xf, int256 yf) {
        xf = x;
        int256 ku = k.muli(utility);
        // ((x / (ku)) + a) ((y / (ku)) + b) = 1
        //
        yf = ((ku**2) / (a.muli(ku) + xf)) - b.muli(ku);
        if (yf < 0) {
            revert CurveError();
        }
    }

    /**
     * @dev Given a utility and a bonding curve (a, b, k) and one coordinate
     *  of a point on that curve, we can find the other coordinate of the
     *  point.
     * @dev the equation for a curve in a slice is:
     *  ((x / (ku)) + a) ((y / (ku)) + b) = 1 (see _getUtility notes)
     * @dev Isolating y in the equation above gives us the equation:
     *  x = (k^2 u^2)/(b k u + y) - a k u
     * @dev This function returns y as yf because we want to be able to call
     *  getPointGivenX and getPointGivenY and handle the returned values
     *  without caring about which particular function is was called.
     */
    function _getPointGivenYandUtility(
        int256 y,
        int256 utility,
        int128 a,
        int128 b,
        int128 k
    ) internal pure returns (int256 xf, int256 yf) {
        yf = y;
        int256 ku = k.muli(utility);
        xf = ((ku**2) / (b.muli(ku) + yf)) - a.muli(ku);
        if (xf < 0) {
            revert CurveError();
        }
    }

    /**
     * @dev A point is in slice n if it is on or below the nth radial line that
     *  marks a slice boundary. If the slice is above the final radial line, it
     *  is in the final slice.
     * @dev the 0th slice is next to the x-axis, and the final slice is next to
     *  the y-axis.
     * @dev Points must be within a hexangle bounded by the lines:
     *   x = MIN_BALANCE
     *   y = MIN_BALANCE
     *   x = 2^255 - 1
     *   y = 2^255 - 1
     *   y = MAX_M * x
     *   y = MIN_M * x
     *  When balances are too close to the origin or the x and y axes, we
     *  can encounter problems with utility stability.
     */
    function _findSlice(
        int128[] memory slopes,
        int256 x,
        int256 y
    ) internal pure returns (uint256 index) {
        if (x < MIN_BALANCE || y < MIN_BALANCE) {
            revert BalanceError();
        }

        int128 m = y.divi(x);
        if (m <= MIN_M) {
            revert BoundaryError();
        }

        for (uint256 i = 0; i < slopes.length; ++i) {
            if (m <= slopes[i]) {
                return i;
            }
        }
        if (m <= MAX_M) {
            return NUMBER_OF_SLOPES;
        }
        // MAX_M < m
        revert BoundaryError();
    }

    /**
     * @dev A point is not in a slice if it is above the slice's lefthand
     *  radial line, or if it is on or below the slice's righthand radial
     *  line.
     *      in slice: (mRight, mLeft]
     *      not in slice: [0, mRight] U (mLeft, type(int128).max]
     */
    function _pointIsNotInSlice(
        int128[] memory slopes,
        uint256 currentSlice,
        int256 x,
        int256 y
    ) internal pure returns (bool inSlice) {
        (int128 mLeft, int128 mRight) = _getSliceBoundaries(
            slopes,
            currentSlice
        );
        int128 m = y.divi(x);
        inSlice = bool(m <= mRight || mLeft < m);
    }

    /**
     * @dev We number slices counterclockwise starting at the origin, so the
     *  lefthand slope is always greater than the righthand slope.
     * @dev The lefthand boundary is the n-th slope and the righthand boundary
     *  is the n-1-th slope.
     * @dev In the 0th slice, the righthand slope is MIN_M. This constant is
     *  slightly above the x-axis.
     * @dev In the final slice, the lefthand slope is MAX_M. This constant is
     *  slightly to the right of the y-axis.
     */
    function _getSliceBoundaries(int128[] memory slopes, uint256 index)
        internal
        pure
        returns (int128 mLeft, int128 mRight)
    {
        if (NUMBER_OF_SLOPES < index) {
            revert BoundaryError();
        }

        if (index == 0) {
            mLeft = slopes[0];
            mRight = MIN_M;
        } else if (index == NUMBER_OF_SLOPES) {
            mLeft = MAX_M;
            mRight = slopes[index - 1];
        } else {
            mLeft = slopes[index];
            mRight = slopes[index - 1];
        }
    }

    /**
     * @dev Next uses the parameter direction to abstract over traversing
     *  through the slices
     * @param currentSlice The slice we are leaving
     * @param direction This value is -1 when we are traversing to the right
     *  and +1 when we are traversing to the left.
     * @return nextSlice We add direction to the currentSlice to get the next
     *  slice. If the next slice is out of bounds, we throw an error.
     */
    function _next(uint256 currentSlice, int256 direction)
        internal
        pure
        returns (uint256 nextSlice)
    {
        assert(direction == -1 || direction == 1);
        int256 potentialSlice = int256(currentSlice) + direction;

        // Short circuit behavior means the unsigned cast is safe
        if (potentialSlice < 0 || NUMBER_OF_SLICES <= uint256(potentialSlice)) {
            revert BoundaryError();
        }
        // potentialSlice must be non-negative if we did not revert, so this
        // is a safe cast.
        nextSlice = uint256(potentialSlice);
        assert(nextSlice < NUMBER_OF_SLICES);
    }

    /**
     * @dev this limits the ratio between a starting balance and an input
     *  or output amount.
     * @dev when we swap very small amounts against a very large pool,
     *  precision errors can cause the pool to lose a small amount of value.
     */
    function _checkAmountWithBalance(uint256 balance, uint256 amount)
        private
        pure
    {
        if (balance / amount >= MAX_BALANCE_AMOUNT_RATIO) {
            revert AmountError();
        }
    }

    /**
     * @dev The pool's balances of the x reserve and y reserve tokens must be
     *  greater than the MIN_BALANCE
     * @dev The pool's ratio of y to x must be within the interval
     *  [MIN_M, MAX_M)
     */
    function _checkBalances(int256 x, int256 y) private pure {
        if (x < MIN_BALANCE || y < MIN_BALANCE) {
            revert BalanceError();
        }
        int128 finalBalanceRatio = y.divi(x);
        if (finalBalanceRatio < MIN_M) {
            revert BoundaryError();
        } else if (MAX_M <= finalBalanceRatio) {
            revert BoundaryError();
        }
    }

    /**
     * @dev Rounding and fees are equivalent concepts
     * @dev We charge fees by rounding values in directions that are beneficial
     *  to the pool.
     * @dev the BASE_FEE and FIXED_FEE values were chosen such that round
     *  enough to cover numerical stability issues that arise from using a
     *  fixed precision math library and piecewise bonding curves.
     */
    function _applyFeeByRounding(int256 amount, bool feeUp)
        private
        pure
        returns (int256 roundedAmount)
    {
        bool negative = amount < 0 ? true : false;
        uint256 absoluteValue = negative ? uint256(-amount) : uint256(amount);
        // FIXED_FEE * 2 because we will possibly deduct the FIXED_FEE from
        // this amount, and we don't want the final amount to be less than
        // the FIXED_FEE.
        if (absoluteValue < FIXED_FEE * 2) revert AmountError();

        uint256 roundedAbsoluteAmount;
        if (feeUp) {
            roundedAbsoluteAmount =
                absoluteValue +
                (absoluteValue / BASE_FEE) +
                FIXED_FEE;
            require(roundedAbsoluteAmount < INT_MAX);
        } else {
            roundedAbsoluteAmount =
                absoluteValue -
                (absoluteValue / BASE_FEE) -
                FIXED_FEE;
        }

        roundedAmount = negative
            ? -int256(roundedAbsoluteAmount)
            : int256(roundedAbsoluteAmount);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity =0.8.10;

enum SpecifiedToken {
    X,
    Y
}

interface ILiquidityPoolImplementation {
    function swapGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 inputAmount,
        SpecifiedToken inputToken
    ) external view returns (uint256 outputAmount);

    function depositGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 depositedAmount,
        SpecifiedToken depositedToken
    ) external view returns (uint256 mintedAmount);

    function withdrawGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 burnedAmount,
        SpecifiedToken withdrawnToken
    ) external view returns (uint256 withdrawnAmount);

    function swapGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 outputAmount,
        SpecifiedToken outputToken
    ) external view returns (uint256 inputAmount);

    function depositGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 mintedAmount,
        SpecifiedToken depositedToken
    ) external view returns (uint256 depositedAmount);

    function withdrawGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 withdrawnAmount,
        SpecifiedToken withdrawnToken
    ) external view returns (uint256 burnedAmount);
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity =0.8.10;

contract Slices {
    uint256 constant NUMBER_OF_SLICES = 13;
    uint256 constant NUMBER_OF_SLOPES = NUMBER_OF_SLICES - 1;

    int128 immutable m0;
    int128 immutable m1;
    int128 immutable m2;
    int128 immutable m3;
    int128 immutable m4;
    int128 immutable m5;
    int128 immutable m6;
    int128 immutable m7;
    int128 immutable m8;
    int128 immutable m9;
    int128 immutable m10;
    int128 immutable m11;

    int128 immutable k0;
    int128 immutable k1;
    int128 immutable k2;
    int128 immutable k3;
    int128 immutable k4;
    int128 immutable k5;
    int128 immutable k6;
    int128 immutable k7;
    int128 immutable k8;
    int128 immutable k9;
    int128 immutable k10;
    int128 immutable k11;
    int128 immutable k12;

    int128 immutable a0;
    int128 immutable a1;
    int128 immutable a2;
    int128 immutable a3;
    int128 immutable a4;
    int128 immutable a5;
    int128 immutable a6;
    int128 immutable a7;
    int128 immutable a8;
    int128 immutable a9;
    int128 immutable a10;
    int128 immutable a11;
    int128 immutable a12;

    int128 immutable b0;
    int128 immutable b1;
    int128 immutable b2;
    int128 immutable b3;
    int128 immutable b4;
    int128 immutable b5;
    int128 immutable b6;
    int128 immutable b7;
    int128 immutable b8;
    int128 immutable b9;
    int128 immutable b10;
    int128 immutable b11;
    int128 immutable b12;

    constructor(
        int128[] memory ms,
        int128[] memory _as,
        int128[] memory bs,
        int128[] memory ks
    ) {

        require(ms.length == NUMBER_OF_SLOPES);
        require(_as.length == NUMBER_OF_SLICES);
        require(bs.length == NUMBER_OF_SLICES);
        require(ks.length == NUMBER_OF_SLICES);

        m0 = ms[0];
        m1 = ms[1];
        m2 = ms[2];
        m3 = ms[3];
        m4 = ms[4];
        m5 = ms[5];
        m6 = ms[6];
        m7 = ms[7];
        m8 = ms[8];
        m9 = ms[9];
        m10 = ms[10];
        m11 = ms[11];

        k0 = ks[0];
        k1 = ks[1];
        k2 = ks[2];
        k3 = ks[3];
        k4 = ks[4];
        k5 = ks[5];
        k6 = ks[6];
        k7 = ks[7];
        k8 = ks[8];
        k9 = ks[9];
        k10 = ks[10];
        k11 = ks[11];
        k12 = ks[12];

        a0 = _as[0];
        a1 = _as[1];
        a2 = _as[2];
        a3 = _as[3];
        a4 = _as[4];
        a5 = _as[5];
        a6 = _as[6];
        a7 = _as[7];
        a8 = _as[8];
        a9 = _as[9];
        a10 = _as[10];
        a11 = _as[11];
        a12 = _as[12];

        b0 = bs[0];
        b1 = bs[1];
        b2 = bs[2];
        b3 = bs[3];
        b4 = bs[4];
        b5 = bs[5];
        b6 = bs[6];
        b7 = bs[7];
        b8 = bs[8];
        b9 = bs[9];
        b10 = bs[10];
        b11 = bs[11];
        b12 = bs[12];
    }

    function getSlopes() public view returns (int128[] memory slopes) {
        slopes = new int128[](NUMBER_OF_SLOPES);
        slopes[0] = m0;
        slopes[1] = m1;
        slopes[2] = m2;
        slopes[3] = m3;
        slopes[4] = m4;
        slopes[5] = m5;
        slopes[6] = m6;
        slopes[7] = m7;
        slopes[8] = m8;
        slopes[9] = m9;
        slopes[10] = m10; 
        slopes[11] = m11; 
        
    }

    function getAs() public view returns (int128[] memory _as) {
        _as = new int128[](NUMBER_OF_SLICES);
        _as[0] = a0;
        _as[1] = a1;
        _as[2] = a2;
        _as[3] = a3;
        _as[4] = a4;
        _as[5] = a5;
        _as[6] = a6;
        _as[7] = a7;
        _as[8] = a8;
        _as[9] = a9;
        _as[10] = a10; 
        _as[11] = a11; 
        _as[12] = a12; 
    }

    function getBs() public view returns (int128[] memory bs) {
        bs = new int128[](NUMBER_OF_SLICES);
        bs[0] = b0;
        bs[1] = b1;
        bs[2] = b2;
        bs[3] = b3;
        bs[4] = b4;
        bs[5] = b5;
        bs[6] = b6;
        bs[7] = b7;
        bs[8] = b8;
        bs[9] = b9;
        bs[10] = b10; 
        bs[11] = b11; 
        bs[12] = b12; 
    }

    function getKs() public view returns (int128[] memory ks) {
        ks = new int128[](NUMBER_OF_SLICES);
        ks[0] = k0;
        ks[1] = k1;
        ks[2] = k2;
        ks[3] = k3;
        ks[4] = k4;
        ks[5] = k5;
        ks[6] = k6;
        ks[7] = k7;
        ks[8] = k8;
        ks[9] = k9;
        ks[10] = k10; 
        ks[11] = k11; 
        ks[12] = k12; 
    }
}