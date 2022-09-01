// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity =0.8.10;

import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILiquidityPoolImplementation.sol";

contract Proteus is ILiquidityPoolImplementation, Ownable {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    struct Slice {
        int128 mLeft;
        int128 mRight;
        int128 a;
        int128 b;
        int128 xMax;
        int128 yMax;
    }

    uint256 internal constant SCALE = 1e18;
    uint256 internal constant INT64_MAX = uint256(uint64(type(int64).max));
    uint256 internal constant MAXIMUM_BALANCE = ((INT64_MAX + 1) * SCALE) - 1;
    uint256 internal constant MINIMUM_BALANCE = 1e15;
    uint256 internal constant MINIMUM_OPERATING_AMOUNT = 1e8;
    int128 internal constant ONE = 2**64;
    int128 internal constant TWO = 2 * ONE;
    int128 internal constant FOUR = 4 * ONE;
    int128 internal constant minPriceDelta = 0x86;
    uint8 internal constant FEE_PRECISION = 11;
    // 10^-11 in ABDK.
    // If you were swapping a billion dollars, this would be a fee of one cent
    int128 internal constant MIN_FEE = ONE / int128(uint128(10**FEE_PRECISION));

    // ABDK.sqrt(type(int128).max);
    int128 public constant MAXIMUM_M = 0x5f5e1000000000000000000;
    // ABDK.sqrt(int128(1));
    int128 public constant MINIMUM_M = 0x00000000000002af31dc461;
    // The MIN_FEE is used to help with numerical stability
    // If this value is modified, it must be higher than MIN_FEE
    int128 public constant xFee = MIN_FEE;
    int128 public constant yFee = MIN_FEE;

    // stores the current weighting parameters
    Slice[] slices;

    // *Output
    error RequestedInputTooLarge();
    error ComputedOutputTooLarge();
    error RequestedInputTooSmall();
    error ComputedOutputTooSmall();

    // *Input
    error RequestedOutputTooLarge();
    error ComputedInputTooLarge();
    error RequestedOutputTooSmall();
    error ComputedInputTooSmall();

    // bounding M
    error InvalidXYRatio();

    // updating weights
    error UnequalArrayLengths();
    error TooFewParameters();

    // casting to ABDK
    error BalanceTooLarge();

    event SlicesUpdated(
        address indexed operator,
        int128[] slopes,
        int128[] rootPrices
    );

    constructor(int128[] memory slopes, int128[] memory rootPrices) {
        _updateSlices(slopes, rootPrices);
    }

    /**
     * Based on whether we are swapping in X or Y, we compute the new balance
     * for that token (_New). We can also find the corresponding token maximum
     * balance (_Max) for the slice that we are currently in If the new token
     * balance is less than the maximum token balance of the slice, we can
     * compute the new balance for the other token (_New and return the
     * difference between the old and new balances of the other token. If not,
     * we move into the next slice, updating our utility and max token balance
     * values and repeat the process.
     */
    function swapGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 inputToken,
        uint256 inputAmount
    ) external view override returns (uint256 outputAmount) {
        int128 m = yBalance.divu(xBalance);
        uint256 i = _findSlice(m);
        Slice memory slice = slices[i];
        int128 util;

        if (inputToken == 0) {
            _checkswapGivenInputAmountParameters(xBalance, inputAmount);

            util = _getXUtil(_balToABDK(xBalance), m, slice);
            int128 xNew = _balToABDK(xBalance + inputAmount);
            int128 xMax;
            if (i == slices.length - 1) {
                // In the final slice xMax * util can overflow.
                xMax = _getXMax(util);
            } else {
                xMax = util.mul(slice.xMax);
            }

            if (i == slices.length - 1 && xNew > xMax) {
                revert RequestedInputTooLarge();
            }

            while (xNew > xMax && i < slices.length - 1) {
                slice = slices[++i];
                util = xMax.mul(slice.mLeft).div(slice.yMax);
                if (i == slices.length - 1) {
                    xMax = _getXMax(util);
                    if (xNew > xMax) {
                        revert RequestedInputTooLarge();
                    }
                    break;
                }
                xMax = util.mul(slice.xMax);
            }

            uint256 yNew = _getY(xNew, util, slice);
            outputAmount = (ONE.sub(yFee)).mulu(yBalance - yNew);

            _checkswapGivenInputAmountReturn(yBalance, outputAmount);
            _checkBalanceXYRatio(
                xBalance + inputAmount,
                yBalance - outputAmount
            );
        } else {
            _checkswapGivenInputAmountParameters(yBalance, inputAmount);

            util = _getYUtil(_balToABDK(yBalance), m, slice);
            int128 yNew = _balToABDK(yBalance + inputAmount);

            int128 yMax;
            if (i == 0) {
                // In the final slice yMax * util can overflow.
                yMax = _getYMax(util);
            } else {
                // Scaled out max y value of current slice
                yMax = util.mul(slice.yMax);
            }

            if (i == 0 && yNew > yMax) {
                revert RequestedInputTooLarge();
            }

            while (yNew > yMax && i > 0) {
                slice = slices[--i];
                util = yMax.div(slice.xMax.mul(slice.mRight));
                if (i == 0) {
                    yMax = _getYMax(util);
                    if (yNew > yMax) {
                        revert RequestedInputTooLarge();
                    }
                    break;
                }
                yMax = util.mul(slice.yMax);
            }

            uint256 xNew = _getX(yNew, util, slice);
            outputAmount = (ONE.sub(xFee)).mulu(xBalance - xNew);

            _checkswapGivenInputAmountReturn(xBalance, outputAmount);
            _checkBalanceXYRatio(
                xBalance - outputAmount,
                yBalance + inputAmount
            );
        }
    }

    /**
     * Based on whether we are depositing in X or Y, we compute a new balance
     * for that token (_New).  We can also find the corresponding token maximum
     * balance (_Max) for the slice that we are currently in. If the new token
     * balance is less than the maximum token balance of the slice, we can
     * compute the new utility value (utilNew),  increase LP token supply by
     * the percentage increase in utility and return the total increase in
     * supply. If not, we move into the next slice, updating our utility,
     * LP token supply, and max token balance values and repeat the process.
     */
    function depositGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 depositToken,
        uint256 depositAmount
    ) external view override returns (uint256 mintAmount) {
        uint256 originalSupply = totalSupply;
        int128 m = yBalance.divu(xBalance);
        uint256 i = _findSlice(m);
        Slice memory slice = slices[i];
        int128 util;
        int128 utilNew;

        if (depositToken == 0) {
            _checkDepositRequest(xBalance, depositAmount);
            _checkBalanceXYRatio(xBalance + depositAmount, yBalance);

            int128 _y = _balToABDK(yBalance);
            util = _getYUtil(_y, m, slice);

            int128 xNew = _balToABDK(xBalance + depositAmount);
            _checkScaledXYRatio(xNew, _y);
            m = _y.div(xNew);

            if (i != slices.length - 1) {
                // Scaled out max x value of current slice
                int128 xMax = _y.div(slice.mRight);

                while (xNew > xMax) {
                    utilNew = xMax.div(slice.xMax);
                    totalSupply = utilNew.div(util).mulu(totalSupply);

                    if (totalSupply > MAXIMUM_BALANCE) {
                        revert ComputedOutputTooLarge();
                    }

                    slice = slices[++i];
                    util = _y.div(slice.yMax);
                    if (i == slices.length - 1) break;

                    xMax = _y.div(slice.mRight);
                }
            }

            utilNew = _getXUtil(xNew, m, slice);
        } else {
            _checkDepositRequest(yBalance, depositAmount);
            _checkBalanceXYRatio(xBalance, yBalance + depositAmount);

            int128 _x = _balToABDK(xBalance);
            util = _getXUtil(_x, m, slice);

            int128 yNew = _balToABDK(yBalance + depositAmount);
            _checkScaledXYRatio(_x, yNew);
            m = yNew.div(_x);

            if (i != 0) {
                // Scaled out max y value of current slice
                int128 yMax = _x.mul(slice.mLeft);

                while (yNew > yMax) {
                    utilNew = yMax.div(slice.yMax);
                    totalSupply = utilNew.div(util).mulu(totalSupply);

                    if (totalSupply > MAXIMUM_BALANCE) {
                        revert ComputedOutputTooLarge();
                    }

                    slice = slices[--i];
                    util = _x.div(slice.xMax);
                    if (i == 0) break;

                    yMax = _x.mul(slice.mLeft);
                }
            }

            utilNew = _getYUtil(yNew, m, slice);
        }
        int128 utilityChange = utilNew.div(util);

        if (
            totalSupply > 1e18 &&
            MAXIMUM_BALANCE.divu(totalSupply) <= utilityChange
        ) {
            revert ComputedOutputTooLarge();
        }

        totalSupply = utilityChange.mulu(totalSupply);

        mintAmount = totalSupply - originalSupply;
        mintAmount -= MIN_FEE.mulu(mintAmount);
        _checkDepositReturn(originalSupply, mintAmount);
    }

    /**
     * Based on whether we are withdrawing out X or Y, we compute the utility
     * at the left or right edge of the slice (utilNew).  We use the utility
     * value at the edge to find the maximum number of LP tokens that can be
     * burned to get to the edge of the slice (burnMax). If the remaining
     * number of LP tokens to burn is less than the max burn amount, we can
     * compute the new token balance (_New) and  return the difference between
     * the old and new token balance.  If not, we move into the previous slice,
     * updating our utility, LP token supply, and max burn amount and repeat
     * the process.
     */
    function withdrawGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 withdrawnToken,
        uint256 burnAmount
    ) external view override returns (uint256 withdrawnAmount) {
        _checkWithdrawRequest(totalSupply, burnAmount);

        int128 m = yBalance.divu(xBalance);
        uint256 i = _findSlice(m);
        Slice memory slice = slices[i];
        int128 util;
        int128 utilNew;
        uint256 burnMax;

        if (withdrawnToken == 0) {
            int128 _y = _balToABDK(yBalance);
            util = _getYUtil(_y, m, slice);

            if (i != 0) {
                utilNew = _y.div(slice.yMax);
                burnMax = ONE.sub(utilNew.div(util)).mulu(totalSupply);

                while (burnAmount > burnMax) {
                    totalSupply -= burnMax;
                    burnAmount -= burnMax;

                    slice = slices[--i];
                    util = _y.div(slice.xMax.mul(slice.mRight));
                    if (i == 0) break;

                    utilNew = _y.div(slice.yMax);
                    burnMax = ONE.sub(utilNew.div(util)).mulu(totalSupply);
                }
            }
            utilNew = ONE.sub(burnAmount.divu(totalSupply)).mul(util);
            uint256 xNew = _getX(_y, utilNew, slice);

            withdrawnAmount = (ONE.sub(xFee)).mulu(xBalance - xNew);
            _checkWithdrawReturn(xBalance, withdrawnAmount);
            _checkBalanceXYRatio(xBalance - withdrawnAmount, yBalance);
        } else {
            int128 _x = _balToABDK(xBalance);
            util = _getXUtil(_x, m, slice);

            if (i != slices.length - 1) {
                utilNew = _x.div(slice.xMax);
                burnMax = ONE.sub(utilNew.div(util)).mulu(totalSupply);

                while (burnAmount > burnMax) {
                    totalSupply -= burnMax;
                    burnAmount -= burnMax;

                    slice = slices[++i];
                    util = _x.mul(slice.mLeft).div(slice.yMax);
                    if (i == slices.length - 1) break;

                    utilNew = _x.div(slice.xMax);
                    burnMax = ONE.sub(utilNew.div(util)).mulu(totalSupply);
                }
            }
            utilNew = ONE.sub(burnAmount.divu(totalSupply)).mul(util);
            uint256 yNew = _getY(_x, utilNew, slice);
            withdrawnAmount = (ONE.sub(yFee)).mulu(yBalance - yNew);
            _checkWithdrawReturn(yBalance, withdrawnAmount);
            _checkBalanceXYRatio(xBalance, yBalance - withdrawnAmount);
        }
    }

    /**
     * Based on whether we are swapping out X or Y, we compute the new balance
     * for that token (_New).  We can also find the corresponding token minimum
     * balance (_Min) for the slice that we are currently in. If the new token
     * balance is greater than the minimum token balance of the slice, we can
     * compute the new balance for the other token (_New) and return the
     * difference between the new and old balances of the other token.  If not,
     * we move into the previous slice, updating our utility and min token
     * balance values and repeat the process.
     */
    function swapGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 outputToken,
        uint256 outputAmount
    ) external view override returns (uint256 inputAmount) {
        int128 m = yBalance.divu(xBalance);
        uint256 i = _findSlice(m);
        Slice memory slice = slices[i];
        int128 util;

        if (outputToken == 0) {
            _checkswapGivenOutputAmountParameters(xBalance, outputAmount);

            outputAmount = ONE.sub(xFee).inv().mulu(outputAmount);
            int128 xNew = _balToABDK(xBalance - outputAmount);

            util = _getXUtil(_balToABDK(xBalance), m, slice);
            int128 xMin = util.mul(slice.yMax.div(slice.mLeft));

            if (i != 0) {
                while (xNew < xMin) {
                    slice = slices[--i];
                    util = xMin.div(slice.xMax);
                    if (i == 0) {
                        break;
                    }
                    xMin = util.mul(slice.yMax.div(slice.mLeft));
                }
            } else if (xNew < xMin) {
                revert RequestedOutputTooLarge();
            }

            uint256 yNew = _getY(xNew, util, slice);
            inputAmount = yNew - yBalance;

            _checkswapGivenOutputAmountReturn(yNew);
            _checkBalanceXYRatio(
                xBalance - outputAmount,
                yBalance + inputAmount
            );
        } else {
            _checkswapGivenOutputAmountParameters(yBalance, outputAmount);

            outputAmount = ONE.sub(yFee).inv().mulu(outputAmount);
            int128 yNew = _balToABDK(yBalance - outputAmount);

            util = _getYUtil(_balToABDK(yBalance), m, slice);
            int128 yMin = util.mul(slice.xMax.mul(slice.mRight));

            if (i != slices.length - 1) {
                while (yNew < yMin) {
                    slice = slices[++i];
                    util = yMin.div(slice.yMax);
                    if (i == slices.length - 1) {
                        break;
                    }
                    yMin = util.mul(slice.xMax.mul(slice.mRight));
                }
            } else if (yNew < yMin) {
                revert RequestedOutputTooLarge();
            }

            uint256 xNew = _getX(yNew, util, slice);
            inputAmount = xNew - xBalance;

            _checkswapGivenOutputAmountReturn(xNew);
            _checkBalanceXYRatio(
                xBalance + inputAmount,
                yBalance - outputAmount
            );
        }
    }

    /**
     * Based on whether we are depositing in X or Y, we compute the utility
     * at the left or right edge of the slice (utilNew).  We use the utility
     * value at the edge to find the maximum number of LP tokens that can be
     * minted to get to the edge of the slice (mintMax). If the remaining
     * number of LP tokens to mint is less than the max mint amount, we can
     * compute the new token balance (_New) and  return the difference between
     * the new and old token balance.  If not, we move into the next slice,
     * updating our utility, LP token supply, and max mint amount and repeat
     * the process.
     */
    function depositGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 depositToken,
        uint256 mintAmount
    ) external view override returns (uint256 depositAmount) {
        _checkDepositRequest(totalSupply, mintAmount);
        int128 m = yBalance.divu(xBalance);
        uint256 i = _findSlice(m);
        Slice memory slice = slices[i];
        int128 util;
        int128 utilNew;
        uint256 mintMax;

        if (depositToken == 0) {
            util = _getXUtil(_balToABDK(xBalance), m, slice);
            int128 _y = _balToABDK(yBalance);

            if (i != slices.length - 1) {
                utilNew = _y.div(slice.xMax.mul(slice.mRight));
                mintMax = utilNew.div(util).mulu(totalSupply) - totalSupply;

                while (mintAmount > mintMax) {
                    mintAmount -= mintMax;
                    totalSupply += mintMax;
                    if (totalSupply > MAXIMUM_BALANCE) {
                        revert ComputedInputTooLarge();
                    }

                    slice = slices[++i];
                    util = _y.div(slice.yMax);
                    if (i == slices.length - 1) break;

                    utilNew = _y.div(slice.xMax.mul(slice.mRight));
                    mintMax = utilNew.div(util).mulu(totalSupply) - totalSupply;
                }
            }

            utilNew = util.mulu(mintAmount + totalSupply).divu(totalSupply);

            uint256 xNew = _getX(_y, utilNew, slice);

            depositAmount = ONE.add(xFee).mulu(xNew - xBalance);
            _checkDepositReturn(xBalance, depositAmount);
            _checkBalanceXYRatio(xBalance + depositAmount, yBalance);
        } else {
            util = _getYUtil(_balToABDK(yBalance), m, slice);
            int128 _x = _balToABDK(xBalance);

            if (i != 0) {
                utilNew = _x.mul(slice.mLeft).div(slice.yMax);
                mintMax = utilNew.div(util).mulu(totalSupply) - totalSupply;

                while (mintAmount > mintMax) {
                    mintAmount -= mintMax;
                    totalSupply += mintMax;
                    if (totalSupply > MAXIMUM_BALANCE) {
                        revert ComputedInputTooLarge();
                    }

                    slice = slices[--i];
                    util = _x.div(slice.xMax);
                    if (i == 0) break;

                    utilNew = _x.mul(slice.mLeft).div(slice.yMax);
                    mintMax = utilNew.div(util).mulu(totalSupply) - totalSupply;
                }
            }

            utilNew = util.mulu(mintAmount + totalSupply).divu(totalSupply);

            uint256 yNew = _getY(_x, utilNew, slice);

            depositAmount = ONE.add(yFee).mulu(yNew - yBalance);
            _checkDepositReturn(xBalance, depositAmount);
            _checkBalanceXYRatio(xBalance, yBalance + depositAmount);
        }
    }

    /*
     * Based on whether we are withdrawing out X or Y, we compute a new balance
     * for that token (_New).  We can also find the corresponding token minimum
     * (_Min) balance for the slice that we are currently in. If the new token
     * balance is greater than the minimum balance of the slice, we can compute
     * the new utility value (utilNew),  decrease LP token supply by the
     * percentage decrease in utility and return the total decrease in supply.
     * If not, we move into the previous slice, updating our utility, LP token
     * supply, and min token balance values and repeat the process.
     */
    function withdrawGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 withdrawnToken,
        uint256 withdrawnAmount
    ) external view override returns (uint256 burnAmount) {
        uint256 originalSupply = totalSupply;
        int128 m = yBalance.divu(xBalance);
        uint256 i = _findSlice(m);
        Slice memory slice = slices[i];
        int128 util;
        int128 utilNew;

        if (withdrawnToken == 0) {
            _checkWithdrawRequest(xBalance, withdrawnAmount);
            _checkBalanceXYRatio(xBalance - withdrawnAmount, yBalance);

            withdrawnAmount = ONE.sub(xFee).inv().mulu(withdrawnAmount);
            util = _getXUtil(_balToABDK(xBalance), m, slice);
            int128 xNew = _balToABDK(xBalance - withdrawnAmount);

            int128 _y = _balToABDK(yBalance);

            if (i != 0) {
                int128 xMin = _y.div(slice.mLeft); // Scaled out min x value of current slice

                while (xNew < xMin) {
                    utilNew = _y.div(slice.yMax);
                    totalSupply = utilNew.div(util).mulu(totalSupply);

                    slice = slices[--i];
                    util = xMin.div(slice.xMax);
                    if (i == 0) break;

                    xMin = _y.div(slice.mLeft);
                }
            }

            m = _y.div(xNew);
            utilNew = _getXUtil(xNew, m, slice);
        } else {
            _checkWithdrawRequest(yBalance, withdrawnAmount);
            _checkBalanceXYRatio(xBalance, yBalance - withdrawnAmount);

            withdrawnAmount = ONE.sub(yFee).inv().mulu(withdrawnAmount);

            util = _getYUtil(_balToABDK(yBalance), m, slice);
            int128 yNew = _balToABDK(yBalance - withdrawnAmount);
            int128 _x = _balToABDK(xBalance);

            if (i != slices.length - 1) {
                int128 yMin = _x.mul(slice.mRight); // Scaled out min y value of current slice

                while (yNew < yMin) {
                    utilNew = _x.div(slice.xMax);
                    totalSupply = utilNew.div(util).mulu(totalSupply);

                    slice = slices[++i];
                    util = yMin.div(slice.yMax);
                    if (i == slices.length - 1) break;

                    yMin = _x.mul(slice.mRight);
                }
            }

            m = yNew.div(_x);
            utilNew = _getYUtil(yNew, m, slice);
        }

        totalSupply = utilNew.div(util).mulu(totalSupply);
        burnAmount = originalSupply - totalSupply;
        _checkWithdrawReturn(originalSupply, burnAmount);
    }

    function updateSlices(int128[] memory slopes, int128[] memory rootPrices)
        external
        onlyOwner
    {
        _updateSlices(slopes, rootPrices);
    }

    function _checkswapGivenInputAmountParameters(
        uint256 balance,
        uint256 amount
    ) internal pure {
        if ((MAXIMUM_BALANCE - balance) < amount) {
            revert RequestedInputTooLarge();
        }
        if (
            amount < MINIMUM_OPERATING_AMOUNT ||
            (balance / amount) > (10**FEE_PRECISION)
        ) {
            revert RequestedInputTooSmall();
        }
    }

    function _checkswapGivenInputAmountReturn(uint256 balance, uint256 amount)
        internal
        pure
    {
        if ((balance - amount < MINIMUM_BALANCE)) {
            revert ComputedOutputTooLarge();
        }
    }

    function _checkWithdrawRequest(uint256 balance, uint256 amount)
        internal
        pure
    {
        if (
            (balance - (balance / (10**FEE_PRECISION)) <= amount) ||
            (balance - amount < MINIMUM_BALANCE)
        ) {
            revert RequestedInputTooLarge();
        }
        if (
            amount < MINIMUM_OPERATING_AMOUNT ||
            (balance / amount) > (10**FEE_PRECISION)
        ) {
            revert RequestedInputTooSmall();
        }
    }

    function _checkWithdrawReturn(uint256 balance, uint256 amount)
        internal
        pure
    {
        if (
            (balance - (balance / (10**FEE_PRECISION)) <= amount) ||
            (balance - amount < MINIMUM_BALANCE)
        ) {
            revert ComputedOutputTooLarge();
        }
    }

    function _checkDepositRequest(uint256 balance, uint256 amount)
        internal
        pure
    {
        if (
            MAXIMUM_BALANCE - balance < amount ||
            (amount / balance) > (10**FEE_PRECISION)
        ) {
            revert RequestedInputTooLarge();
        }
        if (
            amount < MINIMUM_OPERATING_AMOUNT ||
            (balance / amount) > (10**FEE_PRECISION)
        ) {
            revert RequestedInputTooSmall();
        }
    }

    function _checkDepositReturn(uint256 balance, uint256 amount)
        internal
        pure
    {
        if (MAXIMUM_BALANCE - balance < amount) {
            revert ComputedOutputTooLarge();
        }
    }

    function _checkswapGivenOutputAmountParameters(
        uint256 balance,
        uint256 amount
    ) internal pure {
        if (
            (balance - (balance / (10**FEE_PRECISION)) <= amount) ||
            (balance - amount < MINIMUM_BALANCE)
        ) {
            revert RequestedOutputTooLarge();
        }
        if (
            amount < MINIMUM_OPERATING_AMOUNT ||
            (balance / amount) > (10**FEE_PRECISION)
        ) {
            revert RequestedOutputTooSmall();
        }
    }

    function _checkswapGivenOutputAmountReturn(uint256 newBalance)
        internal
        pure
    {
        if (newBalance > MAXIMUM_BALANCE) {
            revert ComputedInputTooLarge();
        }
    }

    /**
     * @dev Checks scaled x vs scaled y, avoiding under/overflows.
     *
     * DEFINITION: ulp: unit of least precision: 2^-64.
     * DEFINITION: MINIMUM_M = smallest m where m^2 does not underflow:
     *   sqrt(ulp)
     * DEFINITION: MAX_VAL: largest representable unit.
     * DEFINITION: MAXIMUM_M = largest m where m^2 does not overflow:
     *   sqrt(MAX_VAL)
     *
     *  Conjecture 1: If x <= MINIMUM_M and y <= MINIMUM_M:
     *   x in range [ulp, sqrt(ulp)], y in range [ulp, sqrt(ulp)]
     *   m is maximized when x is largest and y is smallest
     *   m is minimized when x is smallest and y is largest
     *   (ulp / sqrt(ulp)) <= m <= (sqrt(ulp) / ulp)
     *  Conjecture 2: these bounds are equal to (MINIMUM_M, MAXIMUM_M)
     *  When using fixed point that goes from [radix^(-fixed), radix^(fixed)]
     *    sqrt(ulp) == (ulp / sqrt(ulp)) < (sqrt(ulp) / ulp) == sqrt(MAX_VAL)
     *  Example with ulp = 0.01, MAX_VAL = 100: [10^-2, 10^2]
     *   0.1 == (0.01 / 0.1) < (0.1 / 0.01) == 10
     * Conjecture 3: * When x and y are both less than MINIMUM_M, we're safe.
     *
     * When x is less than MINIMUM_M but y is greater than MINIMUM_M, we
     * need to check if y is greater than MAXIMUM_M * x. We don't need to
     * check x / y against MINIMUM_M because:
     *  x <= MINIMUM_M, MINIMUM_M < y, x < y, so y / x > 1, 1 < MINIMUM_M
     *
     * When x is greater than MINIMUM_M, we can multiply it by MINIMUM_M
     * to check against y without fear of under/overflow.  If is greater
     * than or equal to x * MINIMUM_M, our final check is whether or not
     * x / y is greater than MAXIMUM_M.  This is safer to check by doing:
     *   y > x * MAXIMUM_M, where the result of the multiplication is
     *  saved in a variable twice the size of x and MAXIMUM_M.
     */
    function _checkScaledXYRatio(int128 x, int128 y) internal pure {
        if (
            (x == 0 || y == 0) ||
            ((x <= MINIMUM_M) && (y > MINIMUM_M) && y > (MAXIMUM_M.mul(x))) ||
            ((x > MINIMUM_M) && (MINIMUM_M.mul(x) > y)) ||
            (y > ((int256(x) * int256(MAXIMUM_M)) >> 64))
        ) {
            revert InvalidXYRatio();
        }
    }

    /// @dev this function must be called AFTER checking that xBalance and
    ///  yBalance are in the valid range.
    /// @dev valid x and y balances are less than 2^123, so multiplying
    ///  MAXIMUM_M by x cannot overflow, as the result is stored in a uint256.
    function _checkBalanceXYRatio(uint256 xBalance, uint256 yBalance)
        internal
        pure
    {
        if (
            MINIMUM_M.mulu(xBalance) > yBalance ||
            yBalance > MAXIMUM_M.mulu(xBalance)
        ) {
            revert InvalidXYRatio();
        }
    }

    function _updateSlices(int128[] memory slopes, int128[] memory rootPrices)
        internal
    {
        if (slopes.length != rootPrices.length) {
            revert UnequalArrayLengths();
        }
        if (slopes.length < 2) {
            revert TooFewParameters();
        }

        while (slices.length > 0) {
            slices.pop();
        }

        {
            // First slice contains the y-asymptote of the hyperbola
            // At y-axis asymptote,
            // (y + b) / x = m
            // b = (m * x) - y
            // y = mx
            // (y - b) (x) = 1
            // (mx - b) (x) = 1
            // mx^2 - bx - 1 = 0
            // the "first" slope is the largest representable number
            // It is essentially our y-asymptote.
            int128 m_i = MAXIMUM_M;
            int128 m_j = slopes[0];
            // rp_i is unusued in first slice calculations.  In theory it is
            // infinity, since the prices in the edge slices are asymptotic.
            // In pratice, we don't need to compute anything with rp_i in the
            // first slice.
            int128 rp_j = rootPrices[0];
            // x_a and y_a are unused in first slice calculations.  In theory
            // they don't exist since x_a and y_a would be the intersection of
            // the hyperbola and the y-axis, and the hyperbola only approaches
            // the y-axis.  Luckily we don't need them.
            int128 x_b = rp_j.inv();
            int128 y_b = rp_j;
            // This slice is asymptotic with the y-axis.  Therefore, we can't
            // shift the hyperbola along the x-axis, so a must be zero.
            int128 a = 0;
            int128 b = m_j.mul(x_b).sub(y_b);
            // xMax is the boundary of this slice and slice[1]
            int128 xMax = _quadratic(m_j, b.neg(), ONE.neg());
            // yMax is the point where this curve gets close enough to the
            // y-axis for all practical purposes.
            int128 yMax = _quadratic(ONE, b.neg(), m_i.neg());

            slices.push(Slice(m_i, m_j, a, b, xMax, yMax));
        }

        // Inner slices do not contain an asymptote
        for (uint256 i = 1; i < slopes.length; ++i) {
            // m_i is closer to the y-axis
            int128 m_i = slopes[i - 1];
            // m_j is closer to the x-axis
            int128 m_j = slopes[i];

            // x = 1 / sqrt(p)
            // y = sqrt(p)

            // When rp[i - 1] and rp[i] are far enough apart, we translate a
            // constant sum curve to derive a, b, xMax, and yMax

            require(rootPrices[i - 1].sub(rootPrices[i]) >= minPriceDelta);
            // Point A (x_a, y_a) is the intersection of m_i with the point
            // on the hyperbola x * y = 1 where the derivative is the root
            // price.
            // -dy/dx = y / x = sqrt(price)
            int128 x_a = rootPrices[i - 1].inv();
            int128 y_a = rootPrices[i - 1];
            // Point B (x_b, y_b) is the intersection of the
            int128 x_b = rootPrices[i].inv();
            int128 y_b = rootPrices[i];

            // y_a + b / x_a + a = m_i
            // y_b + b / x_b + a = m_j
            // a is how much we shift the hyperbola by along the x axis
            int128 a = m_j.mul(x_b).add(y_a).sub(m_i.mul(x_a)).sub(y_b).div(
                m_i.sub(m_j)
            );
            // b is how much we shift the hyperbola by along the y-axis
            int128 b = m_i.mul(x_a.add(a)).sub(y_a);

            // xMax is where the parabola shifted by a and b intersects m_j
            // y = mx
            // (y - b) (x - a) = 1
            // (mx - b) (x - a) = 1
            // mx^2 - (am + b)x + (ab - 1) = 0
            int128 xMax = _quadratic(
                m_j,
                b.add(a.mul(m_j)).neg(),
                b.mul(a).sub(ONE)
            );
            // yMax is where the parabola shifted by a and b intersects m_i
            // x = y / m
            // (y - b) (x - a) = 1
            // (y - b) (y/m - a) = 1
            // (1/m)y^2 - (a + b/m)y + (ab - 1) = 0
            int128 yMax = _quadratic(
                m_i.inv(),
                a.add(b.div(m_i)).neg(),
                b.mul(a).sub(ONE)
            );

            slices.push(Slice(m_i, m_j, a, b, xMax, yMax));
        }

        {
            // First slice contains the x-asymptote of the hyperbola
            // (y) / (x + a) = m
            // a = y/m - x
            // x = y / m
            // (y) (x - a) = 1
            // (y) (y/m - a) = 1
            // (1/m)y^2 - ay - 1 = 0

            // At x-axis asymptote, b equals 0
            int128 m_i = slopes[slopes.length - 1];
            // the "last" slope is the smallest representable number
            // It is our x-asymptote
            int128 m_j = MINIMUM_M;
            int128 rp_i = rootPrices[slopes.length - 1];
            // rp_j is unusued here, it's value is zero.
            int128 x_a = rp_i.inv();
            int128 y_a = rp_i;
            // x_b and y_b are unused in final slice calculations.  In theory
            // they don't exist since x_b and y_b would be the intersection of
            // the hyperbola and the x-axis, and the hyperbola only approaches
            // the x-axis.  Luckily we don't need them.
            int128 a = y_a.div(m_i).sub(x_a);
            // This slice is asymptotic with the x-axis.  Therefore, we can't
            // shift the hyperbola along the y-axis, so b must be zero.
            int128 b = 0;
            // xMax is the point where this curve gets close enough to the
            // x-axis for all practical purposes.
            int128 xMax = _quadratic(m_j, m_j.mul(a).neg(), ONE.neg());
            // yMax is the boundary of this slice and slices[slices.length - 2]
            int128 yMax = _quadratic(m_i.inv(), a.neg(), ONE.neg());

            slices.push(Slice(m_i, m_j, a, b, xMax, yMax));
        }

        emit SlicesUpdated(msg.sender, slopes, rootPrices);
    }

    /// @dev Util is defined as the scale factor between the balance and the
    ///  corresponding value on the slice
    function _getXUtil(
        int128 x,
        int128 m,
        Slice memory slice
    ) internal pure returns (int128 xUtil) {
        /**
         * Equations for our reference hyperbola:
         *  y = mx
         *  (y - b) (x - a) = 1
         * Rewrite y in terms of x:
         *  (mx - b) (x - a) = 1
         * Reorder operations to find coefficients of polynomial:
         *  mx^2 - (am + b)x + (ab - 1) = 0
         */
        int128 xPrime = _quadratic(
            m,
            slice.b.add(slice.a.mul(m)).neg(),
            slice.b.mul(slice.a).sub(ONE)
        );
        xUtil = x.div(xPrime);
    }

    /// @dev Util is defined as the scale factor between the balance and the
    ///  corresponding value on the slice
    function _getYUtil(
        int128 y,
        int128 m,
        Slice memory slice
    ) internal pure returns (int128 yUtil) {
        /**
         * Equations for our hyperbola:
         *  x = y / m
         *  (y - b) (x - a) = 1
         * Rewrite x in terms of y:
         *  (y - b) (y/m - a) = 1
         * Reorder operations to find coefficients of polynomial:
         *  (1/m)y^2 - (a + b/m)y + (ab - 1) = 0
         */
        int128 yPrime = _quadratic(
            m.inv(),
            slice.a.add(slice.b.div(m)).neg(),
            slice.b.mul(slice.a).sub(ONE)
        );
        yUtil = y.div(yPrime);
    }

    function _getX(
        int128 y,
        int128 util,
        Slice memory slice
    ) internal pure returns (uint256 x) {
        int128 yPrime = y.div(util);
        /**
         * Equation for our reference hyperbola:
         *  (y - b) (x - a) = 1
         * Isolate x:
         *  x = 1 / (y - b) + a
         */
        int128 xPrime = yPrime.sub(slice.b).inv().add(slice.a);
        _checkScaledXYRatio(xPrime, yPrime);
        x = xPrime.mul(util).mulu(SCALE);
    }

    function _getY(
        int128 x,
        int128 util,
        Slice memory slice
    ) internal pure returns (uint256 y) {
        int128 xPrime = x.div(util);
        /**
         * Equation for our reference hyperbola:
         *  (y - b) (x - a) = 1
         * Isolate y:
         *  y = 1 / (x - a) + b
         */
        int128 yPrime = xPrime.sub(slice.a).inv().add(slice.b);
        _checkScaledXYRatio(xPrime, yPrime);

        y = yPrime.mul(util).mulu(SCALE);
    }

    /**
     * @dev This returns the maximum X balance for a given utility
     * If xMaxScaled * utility doesn't overflow, the maximum X
     * is the result.  xMaxScaled * utility does overflow, the
     * maxium X balance is MAXIMUM_BALANCE.
     * The maximum X balance is found in the final slice.
     */
    function _getXMax(int128 util) internal view returns (int128 xMax) {
        int128 xMaxScaled = slices[slices.length - 1].xMax;

        if (util <= ONE) {
            xMax = xMaxScaled.mul(util);
        } else if (type(int128).max.div(util) > xMaxScaled) {
            xMax = xMaxScaled.mul(util);
        } else {
            xMax = _balToABDK(MAXIMUM_BALANCE);
        }
    }

    /**
     * @dev This works just like getXMax, but using the yBalance and the first
     * slice.
     */
    function _getYMax(int128 util) internal view returns (int128 yMax) {
        int128 yMaxScaled = slices[0].yMax;

        if (util <= ONE) {
            yMax = yMaxScaled.mul(util);
        } else if (type(int128).max.div(util) > yMaxScaled) {
            yMax = yMaxScaled.mul(util);
        } else {
            yMax = _balToABDK(MAXIMUM_BALANCE);
        }
    }

    /**
     *  @dev This function is specifically for finding the greater root of a
     *  quadratic equation.  Because we're using this to find the x
     *  intercept between a straight line originating from the origin
     *  and a hyperbola in the first quadrant, we know we want the greater
     *  root.  The lesser root is always the intercept in the third quadrant.
     */
    function _quadratic(
        int128 a,
        int128 b,
        int128 c
    ) internal pure returns (int128 greaterRoot) {
        int128 discriminant = ABDKMath64x64.sqrt(
            b.pow(2).sub(a.mul(c).mul(FOUR))
        );
        int128 denominator = TWO.mul(a);
        greaterRoot = b.neg().add(discriminant).div(denominator);
    }

    function _findSlice(int128 m) internal view returns (uint256 i) {
        i = 0;
        while (i < slices.length) {
            if (m <= slices[i].mLeft && m > slices[i].mRight) return i;
            unchecked {
                ++i;
            }
        }
        // while loop terminates at i == slices.length
        // if we just return i here we'll get an index out of bounds.
        return i - 1;
    }

    /// @dev Converts a fixed 18 decimal point uint256 value into a
    ///  fixed 64 binary point number (Standard Ether to ABDK 64x64).
    /// @dev the constant MAXIMUM_BALANCE is the largest number that can
    ///  be handled by this function
    function _balToABDK(uint256 bal) internal pure returns (int128 abdk) {
        if (bal > MAXIMUM_BALANCE) {
            revert BalanceTooLarge();
        }

        abdk = ABDKMath64x64.fromUInt(bal / SCALE).add(
            (bal % SCALE).divu(SCALE)
        );
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

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity =0.8.10;

interface ILiquidityPoolImplementation {
    function swapGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 inputToken,
        uint256 inputAmount
    ) external view returns (uint256 outputAmount);

    function depositGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 depositToken,
        uint256 depositAmount
    ) external view returns (uint256 mintAmount);

    function withdrawGivenInputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 withdrawnToken,
        uint256 burnAmount
    ) external view returns (uint256 withdrawnAmount);

    function swapGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 outputToken,
        uint256 outputAmount
    ) external view returns (uint256 inputAmount);

    function depositGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 depositToken,
        uint256 mintAmount
    ) external view returns (uint256 depositAmount);

    function withdrawGivenOutputAmount(
        uint256 xBalance,
        uint256 yBalance,
        uint256 totalSupply,
        uint256 withdrawnToken,
        uint256 withdrawnAmount
    ) external view returns (uint256 burnAmount);
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