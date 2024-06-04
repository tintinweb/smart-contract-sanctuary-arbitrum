// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IButtonswapFactory} from
    "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapFactory/IButtonswapFactory.sol";
import {IButtonswapPair} from "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {IGenericButtonswapRouter} from "./interfaces/IButtonswapRouter/IGenericButtonswapRouter.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IButtonToken} from "./interfaces/IButtonToken.sol";
import {ButtonswapLibrary} from "./libraries/ButtonswapLibrary.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {ButtonswapOperations} from "./libraries/ButtonswapOperations.sol";
import {Math} from "./libraries/Math.sol";
import {IUSDM} from "./interfaces/IUSDM.sol";

contract GenericButtonswapRouter is IGenericButtonswapRouter {
    uint256 private constant BPS = 10_000;

    /**
     * @inheritdoc IGenericButtonswapRouter
     */
    address public immutable override factory;
    /**
     * @inheritdoc IGenericButtonswapRouter
     */
    address public immutable override WETH;

    modifier ensure(uint256 deadline) {
        if (block.timestamp > deadline) {
            revert Expired(deadline, block.timestamp);
        }
        _;
    }

    /**
     * @dev Only accepts ETH via fallback from the WETH contract
     */
    receive() external payable {
        if (msg.sender != WETH) {
            revert NonWETHSender(msg.sender);
        }
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    // **** TransformOperations **** //

    // Swap
    function _swap(address tokenIn, address tokenOut) internal returns (uint256 amountOut) {
        IButtonswapPair pair = IButtonswapPair(ButtonswapLibrary.pairFor(factory, tokenIn, tokenOut));
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));

        (uint256 poolIn, uint256 poolOut) = ButtonswapLibrary.getPools(factory, tokenIn, tokenOut);
        amountOut = ButtonswapLibrary.getAmountOut(amountIn, poolIn, poolOut);

        TransferHelper.safeApprove(tokenIn, address(pair), amountIn);
        if (tokenIn < tokenOut) {
            pair.swap(amountIn, 0, 0, amountOut, address(this));
        } else {
            pair.swap(0, amountIn, amountOut, 0, address(this));
        }
    }

    // Wrap-Button
    function _wrapButton(address tokenIn, address tokenOut) internal returns (uint256 amountOut) {
        if (IButtonToken(tokenOut).underlying() != tokenIn) {
            revert IncorrectButtonPairing(tokenIn, tokenOut);
        }
        // Approving/depositing the entire balance of the router
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        TransferHelper.safeApprove(tokenIn, tokenOut, amountIn);
        amountOut = IButtonToken(tokenOut).deposit(amountIn);
    }

    // Unwrap-Button
    function _unwrapButton(address tokenIn, address tokenOut) internal returns (uint256 amountOut) {
        if (IButtonToken(tokenIn).underlying() != tokenOut) {
            revert IncorrectButtonPairing(tokenOut, tokenIn);
        }
        // Burning the entire balance of the router
        amountOut = IButtonToken(tokenIn).burnAll();
    }

    // Wrap-WETH
    function _wrapWETH(address tokenIn, address tokenOut) internal returns (uint256 amountOut) {
        if (tokenIn != address(0)) {
            revert NonEthToken(tokenIn);
        }
        if (tokenOut != address(WETH)) {
            revert NonWethToken(WETH, tokenOut);
        }
        // Depositing the entire balance of the router
        uint256 amountIn = address(this).balance;
        IWETH(WETH).deposit{value: amountIn}();
        amountOut = amountIn;
    }

    // Unwrap-WETH
    function _unwrapWETH(address tokenIn, address tokenOut) internal returns (uint256 amountOut) {
        if (tokenIn != address(WETH)) {
            revert NonWethToken(WETH, tokenIn);
        }
        if (tokenOut != address(0)) {
            revert NonEthToken(tokenOut);
        }
        uint256 amountIn = IWETH(WETH).balanceOf(address(this));
        IWETH(WETH).withdraw(amountIn);
        amountOut = address(this).balance;
    }

    // USDM-swap
    function _usdmSwap(address tokenIn, address tokenOut) internal returns (uint256 amountOut) {
        IButtonswapPair pair = IButtonswapPair(ButtonswapLibrary.pairFor(factory, tokenIn, tokenOut));
        uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 receivedAmount = IUSDM(tokenIn).convertToTokens(
            IUSDM(tokenIn).convertToShares(
                IERC20(tokenIn).balanceOf(address(this))
            )
        );

        (uint256 poolIn, uint256 poolOut) = ButtonswapLibrary.getPools(factory, tokenIn, tokenOut);
        amountOut = ButtonswapLibrary.getAmountOut(receivedAmount, poolIn, poolOut);

        TransferHelper.safeApprove(tokenIn, address(pair), amountIn);
        if (tokenIn < tokenOut) {
            pair.swap(amountIn, 0, 0, amountOut, address(this));
        } else {
            pair.swap(0, amountIn, amountOut, 0, address(this));
        }
    }

    function _swapStep(address tokenIn, SwapStep calldata swapStep)
        internal
        virtual
        returns (address tokenOut, uint256 amountOut)
    {
        tokenOut = swapStep.tokenOut;
        if (swapStep.operation == ButtonswapOperations.Swap.SWAP) {
            amountOut = _swap(tokenIn, tokenOut);
        } else if (swapStep.operation == ButtonswapOperations.Swap.WRAP_BUTTON) {
            amountOut = _wrapButton(tokenIn, tokenOut);
        } else if (swapStep.operation == ButtonswapOperations.Swap.UNWRAP_BUTTON) {
            amountOut = _unwrapButton(tokenIn, tokenOut);
        } else if (swapStep.operation == ButtonswapOperations.Swap.WRAP_WETH) {
            amountOut = _wrapWETH(tokenIn, tokenOut);
        } else if (swapStep.operation == ButtonswapOperations.Swap.UNWRAP_WETH) {
            amountOut = _unwrapWETH(tokenIn, tokenOut);
        } else if (swapStep.operation == ButtonswapOperations.Swap.USDM_SWAP) {
            amountOut = _usdmSwap(tokenIn, tokenOut);
        }
    }

    function _swapExactTokensForTokens(address tokenIn, uint256 amountIn, SwapStep[] calldata swapSteps)
        internal
        returns (uint256[] memory amounts, address tokenOut, uint256 amountOut)
    {
        tokenOut = tokenIn;
        amountOut = amountIn;
        amounts = new uint256[](swapSteps.length + 1);
        amounts[0] = amountIn;

        for (uint256 i = 0; i < swapSteps.length; i++) {
            (tokenOut, amountOut) = _swapStep(tokenOut, swapSteps[i]);
            amounts[i + 1] = amountOut;
        }
    }

    function _transferTokensOut(address tokenOut, SwapStep[] calldata swapSteps, address to) internal {
        // If swapSteps is empty or the last swapStep isn't unwrap-weth, then transfer out the entire balance of tokenOut
        if (swapSteps.length == 0 || swapSteps[swapSteps.length - 1].operation != ButtonswapOperations.Swap.UNWRAP_WETH)
        {
            TransferHelper.safeTransfer(tokenOut, to, IERC20(tokenOut).balanceOf(address(this)));
        } else {
            // Otherwise, transfer out the entire balance
            payable(to).transfer(address(this).balance);
        }
    }

    function swapExactTokensForTokens(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        SwapStep[] calldata swapSteps,
        address to,
        uint256 deadline
    ) external payable override ensure(deadline) returns (uint256[] memory amounts) {
        // Transferring in the initial amount if the first swapStep is not wrap-weth
        if (swapSteps[0].operation != ButtonswapOperations.Swap.WRAP_WETH) {
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        }

        // Doing the swaps one-by-one
        // Repurposing tokenIn/amountIn variables to represent finalTokenOut/finalAmountOut to save gas
        (amounts, tokenIn, amountIn) = _swapExactTokensForTokens(tokenIn, amountIn, swapSteps);

        // Confirm that the final amountOut is greater than or equal to the amountOutMin
        if (amountIn < amountOutMin) {
            revert InsufficientOutputAmount(amountOutMin, amountIn);
        }

        // Transferring output balance to to-address
        _transferTokensOut(tokenIn, swapSteps, to);
    }

    function _getAmountIn(address tokenIn, uint256 amountOut, SwapStep calldata swapStep)
        internal
        virtual
        returns (uint256 amountIn)
    {
        if (swapStep.operation == ButtonswapOperations.Swap.SWAP) {
            (uint256 poolIn, uint256 poolOut) = ButtonswapLibrary.getPools(factory, tokenIn, swapStep.tokenOut);
            amountIn = ButtonswapLibrary.getAmountIn(amountOut, poolIn, poolOut);
        } else if (swapStep.operation == ButtonswapOperations.Swap.WRAP_BUTTON) {
            amountIn = IButtonToken(swapStep.tokenOut).wrapperToUnderlying(amountOut);
        } else if (swapStep.operation == ButtonswapOperations.Swap.UNWRAP_BUTTON) {
            amountIn = IButtonToken(tokenIn).underlyingToWrapper(amountOut);
        } else if (swapStep.operation == ButtonswapOperations.Swap.WRAP_WETH) {
            amountIn = amountOut;
        } else if (swapStep.operation == ButtonswapOperations.Swap.UNWRAP_WETH) {
            amountIn = amountOut;
        } else if (swapStep.operation == ButtonswapOperations.Swap.USDM_SWAP) {
            (uint256 poolIn, uint256 poolOut) = ButtonswapLibrary.getPools(factory, tokenIn, swapStep.tokenOut);
            amountIn = ButtonswapLibrary.getAmountIn(amountOut, poolIn, poolOut) + 4;
        }
    }

    function _getAmountIn(address tokenIn, uint256 amountOut, SwapStep[] calldata swapSteps)
        internal
        returns (uint256 amountIn)
    {
        amountIn = amountOut;
        if (swapSteps.length > 0) {
            for (uint256 i = swapSteps.length - 1; i > 0; i--) {
                amountIn = _getAmountIn(swapSteps[i - 1].tokenOut, amountIn, swapSteps[i]);
            }
            // Do the last iteration outside of the loop since we need to use tokenIn
            amountIn = _getAmountIn(tokenIn, amountIn, swapSteps[0]);
        }
    }

    function _getAmountOut(address tokenIn, uint256 amountIn, SwapStep calldata swapStep)
        internal
        virtual
        returns (uint256 amountOut)
    {
        if (swapStep.operation == ButtonswapOperations.Swap.SWAP) {
            (uint256 poolIn, uint256 poolOut) = ButtonswapLibrary.getPools(factory, tokenIn, swapStep.tokenOut);
            amountOut = ButtonswapLibrary.getAmountOut(amountIn, poolIn, poolOut);
        } else if (swapStep.operation == ButtonswapOperations.Swap.WRAP_BUTTON) {
            amountOut = IButtonToken(swapStep.tokenOut).underlyingToWrapper(amountIn);
        } else if (swapStep.operation == ButtonswapOperations.Swap.UNWRAP_BUTTON) {
            amountOut = IButtonToken(tokenIn).wrapperToUnderlying(amountIn);
        } else if (swapStep.operation == ButtonswapOperations.Swap.WRAP_WETH) {
            amountOut = amountIn;
        } else if (swapStep.operation == ButtonswapOperations.Swap.UNWRAP_WETH) {
            amountOut = amountIn;
        } else if (swapStep.operation == ButtonswapOperations.Swap.USDM_SWAP) {
            (uint256 poolIn, uint256 poolOut) = ButtonswapLibrary.getPools(factory, tokenIn, swapStep.tokenOut);
            amountOut = ButtonswapLibrary.getAmountOut(IUSDM(tokenIn).convertToTokens(IUSDM(tokenIn).convertToShares(amountIn)), poolIn, poolOut);
        }
    }

    function _getAmountOut(address tokenIn, uint256 amountIn, SwapStep[] calldata swapSteps)
        internal
        returns (uint256 amountOut)
    {
        amountOut = amountIn;
        if (swapSteps.length > 0) {
            // Do the first iteration outside of the loop since we need to use tokenIn
            amountOut = _getAmountOut(tokenIn, amountOut, swapSteps[0]);

            for (uint256 i = 1; i < swapSteps.length; i++) {
                amountOut = _getAmountOut(swapSteps[i - 1].tokenOut, amountOut, swapSteps[i]);
            }
        }
    }

    function swapTokensForExactTokens(
        address tokenIn,
        uint256 amountOut,
        uint256 amountInMax,
        SwapStep[] calldata swapSteps,
        address to,
        uint256 deadline
    ) external payable override ensure(deadline) returns (uint256[] memory amounts) {
        //        amounts = _getAmountsIn(tokenIn, amountOut, swapSteps);
        uint256 amountIn = _getAmountIn(tokenIn, amountOut, swapSteps);

        if (amountIn > amountInMax) {
            revert ExcessiveInputAmount(amountInMax, amountIn);
        }

        // Transferring in the initial amount if the first swapStep is not wrap-weth
        if (swapSteps[0].operation != ButtonswapOperations.Swap.WRAP_WETH) {
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        } else if (amountIn < amountInMax) {
            // Refund the surplus input ETH to the user if the first swapStep is wrap-weth
            payable(msg.sender).transfer(amountInMax - amountIn);
        }

        // Reusing tokenIn/amountIn as finalTokenIn/finalAmountIn
        (amounts, tokenIn, amountIn) = _swapExactTokensForTokens(tokenIn, amountIn, swapSteps);

        // Validate that sufficient output was returned
        if (amountIn < amountOut) {
            revert InsufficientOutputAmount(amountOut, amountIn);
        }

        // Transferring output balance to to-address
        _transferTokensOut(tokenIn, swapSteps, to);
    }

    function _transferSwapStepsIn(address pair, address tokenIn, uint256 amountIn, SwapStep[] calldata swapSteps)
        internal
        returns (uint256[] memory amounts, uint256 finalAmountIn)
    {
        // Transferring in tokenA from user if first swapStepsA is not wrap-weth
        if (swapSteps.length == 0 || swapSteps[0].operation != ButtonswapOperations.Swap.WRAP_WETH) {
            TransferHelper.safeTransferFrom(tokenIn, msg.sender, address(this), amountIn);
        }

        // Repurposing tokenIn/amountIn variables as finalTokenIn/finalAmountIn to save gas
        (amounts, tokenIn, amountIn) = _swapExactTokensForTokens(tokenIn, amountIn, swapSteps);

        // Approving final tokenA for transfer to pair
        TransferHelper.safeApprove(tokenIn, pair, amountIn);
        finalAmountIn = amountIn;
    }

    function _validateMovingAveragePrice0Threshold(
        uint256 movingAveragePrice0ThresholdBps,
        uint256 pool0,
        uint256 pool1,
        IButtonswapPair pair
    ) internal view {
        // Validate that the moving average price is within the threshold for pairs that exist
        // Skip if pair doesn't exist yet (empty pools) or if movingAveragePrice0ThresholdBps is maximum
        if (pool0 > 0 && pool1 > 0 && movingAveragePrice0ThresholdBps < type(uint256).max) {
            uint256 movingAveragePrice0 = pair.movingAveragePrice0();
            uint256 cachedTerm = Math.mulDiv(movingAveragePrice0, pool0 * BPS, 2 ** 112);
            // Check above lowerbound
            if ((movingAveragePrice0ThresholdBps < BPS) && pool1 * (BPS - movingAveragePrice0ThresholdBps) > cachedTerm) {
                revert MovingAveragePriceOutOfBounds(pool0, pool1, movingAveragePrice0, movingAveragePrice0ThresholdBps);
            }
            // Check below upperbound
            if (pool1 * (BPS + movingAveragePrice0ThresholdBps) < cachedTerm
            ) {
                revert MovingAveragePriceOutOfBounds(pool0, pool1, movingAveragePrice0, movingAveragePrice0ThresholdBps);
            }
        }
    }

    function _calculateDualSidedAddAmounts(
        AddLiquidityParams calldata addLiquidityParams,
        IButtonswapPair pair,
        bool aToken0
    ) internal returns (uint256 amountA, uint256 amountB) {
        // Fetch pair liquidity
        uint256 poolA;
        uint256 poolB;
        uint256 reservoirA;
        uint256 reservoirB;
        if (aToken0) {
            (poolA, poolB, reservoirA, reservoirB,) = pair.getLiquidityBalances();
        } else {
            (poolB, poolA, reservoirB, reservoirA,) = pair.getLiquidityBalances();
        }

        // If pair has no liquidity, then deposit addLiquidityParams.amountADesired and addLiquidityParams.amountBDesired
        if ((poolA + reservoirA) == 0 && (poolB + reservoirB) == 0) {
            (amountA, amountB) = (addLiquidityParams.amountADesired, addLiquidityParams.amountBDesired);
        } else {
            // Calculate optimal amountB and check if it fits
            uint256 amountOptimal = _getAmountIn(
                addLiquidityParams.tokenB,
                ButtonswapLibrary.quote(
                    _getAmountOut(
                        addLiquidityParams.tokenA, addLiquidityParams.amountADesired, addLiquidityParams.swapStepsA
                    ),
                    poolA + reservoirA,
                    poolB + reservoirB
                ),
                addLiquidityParams.swapStepsB
            );
            if (amountOptimal <= addLiquidityParams.amountBDesired) {
                if (amountOptimal < addLiquidityParams.amountBMin) {
                    revert InsufficientTokenAmount(
                        addLiquidityParams.tokenB, amountOptimal, addLiquidityParams.amountBMin
                    );
                }
                (amountA, amountB) = (addLiquidityParams.amountADesired, amountOptimal);
            } else {
                // Calculate optimal amountA (repurposing variable to save gas) and check if it fits
                amountOptimal = _getAmountIn(
                    addLiquidityParams.tokenA,
                    ButtonswapLibrary.quote(
                        _getAmountOut(
                            addLiquidityParams.tokenB, addLiquidityParams.amountBDesired, addLiquidityParams.swapStepsB
                        ),
                        poolB + reservoirB,
                        poolA + reservoirA
                    ),
                    addLiquidityParams.swapStepsA
                );
                assert(amountOptimal <= addLiquidityParams.amountADesired); // This case should never happen
                if (amountOptimal < addLiquidityParams.amountAMin) {
                    revert InsufficientTokenAmount(
                        addLiquidityParams.tokenA, amountOptimal, addLiquidityParams.amountAMin
                    );
                }
                (amountA, amountB) = (amountOptimal, addLiquidityParams.amountBDesired);
            }
        }

        // Validate that the moving average price is within the threshold for pairs that already existed
        _validateMovingAveragePrice0Threshold(
            addLiquidityParams.movingAveragePrice0ThresholdBps, aToken0 ? poolA : poolB, aToken0 ? poolB : poolA, pair
        );
    }

    function _addLiquidityDual(
        IButtonswapPair pair,
        bool aToken0,
        AddLiquidityParams calldata addLiquidityParams,
        address to
    ) internal returns (uint256[] memory amountsA, uint256[] memory amountsB, uint256 liquidity) {
        // Calculating how much of tokenA and tokenB to take from user
        (uint256 amountA, uint256 amountB) = _calculateDualSidedAddAmounts(addLiquidityParams, pair, aToken0);

        (amountsA, amountA) =
            _transferSwapStepsIn(address(pair), addLiquidityParams.tokenA, amountA, addLiquidityParams.swapStepsA);
        (amountsB, amountB) =
            _transferSwapStepsIn(address(pair), addLiquidityParams.tokenB, amountB, addLiquidityParams.swapStepsB);

        if (aToken0) {
            liquidity = pair.mint(amountA, amountB, to);
        } else {
            liquidity = pair.mint(amountB, amountA, to);
        }
    }

    function _addLiquidityGetMintSwappedAmounts(
        AddLiquidityParams calldata addLiquidityParams,
        address pairTokenA,
        address pairTokenB,
        bool isReservoirA
    ) internal returns (uint256 amountA, uint256 amountB) {
        // ReservoirA is non-empty
        if (isReservoirA) {
            // we take from reservoirA and the user-provided amountBDesired
            // But modify so that you don't do liquidityOut logic since you don't need it
            (, uint256 amountAOptimal) = ButtonswapLibrary.getMintSwappedAmounts(
                factory,
                pairTokenB,
                pairTokenA,
                _getAmountOut(
                    addLiquidityParams.tokenB, addLiquidityParams.amountBDesired, addLiquidityParams.swapStepsB
                )
            );
            amountAOptimal = _getAmountIn(addLiquidityParams.tokenA, amountAOptimal, addLiquidityParams.swapStepsA);
            // Slippage-check: User wants to drain from the res by amountAMin or more
            if (amountAOptimal < addLiquidityParams.amountAMin) {
                revert InsufficientTokenAmount(addLiquidityParams.tokenA, amountAOptimal, addLiquidityParams.amountAMin);
            }
            (amountA, amountB) = (0, addLiquidityParams.amountBDesired);
        } else {
            // ReservoirB is non-empty
            // we take from reservoirB and the user-provided amountADesired
            (, uint256 amountBOptimal) = ButtonswapLibrary.getMintSwappedAmounts(
                factory,
                pairTokenA,
                pairTokenB,
                _getAmountOut(
                    addLiquidityParams.tokenA, addLiquidityParams.amountADesired, addLiquidityParams.swapStepsA
                )
            );
            amountBOptimal = _getAmountIn(addLiquidityParams.tokenB, amountBOptimal, addLiquidityParams.swapStepsB);
            // Slippage-check: User wants to drain from the res by amountBMin or more
            if (amountBOptimal < addLiquidityParams.amountBMin) {
                revert InsufficientTokenAmount(addLiquidityParams.tokenB, amountBOptimal, addLiquidityParams.amountBMin);
            }
            (amountA, amountB) = (addLiquidityParams.amountADesired, 0);
        }
    }

    function _calculateSingleSidedAddAmounts(
        AddLiquidityParams calldata addLiquidityParams,
        IButtonswapPair pair,
        address pairTokenA,
        address pairTokenB
    ) internal returns (uint256 amountA, uint256 amountB) {
        // Fetch pair liquidity
        uint256 poolA;
        uint256 poolB;
        uint256 reservoirA;
        uint256 reservoirB;
        if (pairTokenA < pairTokenB) {
            (poolA, poolB, reservoirA, reservoirB,) = pair.getLiquidityBalances();
        } else {
            (poolB, poolA, reservoirB, reservoirA,) = pair.getLiquidityBalances();
        }

        // If poolA and poolB are both 0, then the pair hasn't been initialized yet
        if (poolA == 0 || poolB == 0) {
            revert NotInitialized(address(pair));
        }
        // If reservoirA and reservoirB are both 0, then the pair doesn't have a non-empty reservoir
        if (reservoirA == 0 && reservoirB == 0) {
            revert NoReservoir(address(pair));
        }

        (amountA, amountB) =
            _addLiquidityGetMintSwappedAmounts(addLiquidityParams, pairTokenA, pairTokenB, reservoirA > 0);
    }

    function _addLiquiditySingle(
        IButtonswapPair pair,
        address pairTokenA,
        address pairTokenB,
        AddLiquidityParams calldata addLiquidityParams,
        address to
    ) internal returns (uint256[] memory amountsA, uint256[] memory amountsB, uint256 liquidity) {
        // Calculating how much of tokenA and tokenB to take from user
        (uint256 amountA, uint256 amountB) =
            _calculateSingleSidedAddAmounts(addLiquidityParams, pair, pairTokenA, pairTokenB);

        if (amountA > 0) {
            (amountsA, amountA) =
                _transferSwapStepsIn(address(pair), addLiquidityParams.tokenA, amountA, addLiquidityParams.swapStepsA);
            liquidity = pair.mintWithReservoir(amountA, to);
        } else if (amountB > 0) {
            (amountsB, amountB) =
                _transferSwapStepsIn(address(pair), addLiquidityParams.tokenB, amountB, addLiquidityParams.swapStepsB);
            liquidity = pair.mintWithReservoir(amountB, to);
        }
    }

    function _addLiquidityGetOrCreatePair(AddLiquidityParams calldata addLiquidityParams)
        internal
        returns (address pairAddress, address pairTokenA, address pairTokenB)
    {
        // No need to validate if finalTokenA or finalTokenB are address(0) since getPair and createPair will handle it
        pairTokenA = addLiquidityParams.swapStepsA.length > 0
            ? addLiquidityParams.swapStepsA[addLiquidityParams.swapStepsA.length - 1].tokenOut
            : addLiquidityParams.tokenA;
        pairTokenB = addLiquidityParams.swapStepsB.length > 0
            ? addLiquidityParams.swapStepsB[addLiquidityParams.swapStepsB.length - 1].tokenOut
            : addLiquidityParams.tokenB;

        // Fetch the pair
        pairAddress = IButtonswapFactory(factory).getPair(pairTokenA, pairTokenB);

        // Pair doesn't exist
        if (pairAddress == address(0)) {
            // If the operation is dual-sided and createPair is true, then create the pair. Otherwise throw an error
            if (addLiquidityParams.operation == ButtonswapOperations.Liquidity.DUAL && addLiquidityParams.createPair) {
                pairAddress = IButtonswapFactory(factory).createPair(pairTokenA, pairTokenB);
            } else {
                revert PairDoesNotExist(pairTokenA, pairTokenB);
            }
        } else if (addLiquidityParams.createPair) {
            // The pair already exists but createPair is true
            revert PairAlreadyExists(pairTokenA, pairTokenB, pairAddress);
        }
    }

    function addLiquidity(AddLiquidityParams calldata addLiquidityParams, address to, uint256 deadline)
        external
        payable
        ensure(deadline)
        returns (uint256[] memory amountsA, uint256[] memory amountsB, uint256 liquidity)
    {
        (address pairAddress, address pairTokenA, address pairTokenB) = _addLiquidityGetOrCreatePair(addLiquidityParams);

        if (addLiquidityParams.operation == ButtonswapOperations.Liquidity.DUAL) {
            (amountsA, amountsB, liquidity) =
                _addLiquidityDual(IButtonswapPair(pairAddress), pairTokenA < pairTokenB, addLiquidityParams, to);
        } else if (addLiquidityParams.operation == ButtonswapOperations.Liquidity.SINGLE) {
            (amountsA, amountsB, liquidity) =
                _addLiquiditySingle(IButtonswapPair(pairAddress), pairTokenA, pairTokenB, addLiquidityParams, to);
        }

        if (liquidity < addLiquidityParams.liquidityMin) {
            revert InsufficientOutputLiquidity(liquidity, addLiquidityParams.liquidityMin);
        }
    }

    function _removeLiquidityDual(
        IButtonswapPair pair,
        RemoveLiquidityParams calldata removeLiquidityParams,
        address to
    ) internal returns (uint256[] memory amountsA, uint256[] memory amountsB) {
        // Burn the pair-tokens for amountA of tokenA and amountB of tokenB
        (address token0,) = ButtonswapLibrary.sortTokens(removeLiquidityParams.tokenA, removeLiquidityParams.tokenB);
        uint256 amountA;
        uint256 amountB;
        if (removeLiquidityParams.tokenA == token0) {
            (amountA, amountB) = pair.burn(removeLiquidityParams.liquidity, address(this));
        } else {
            (amountB, amountA) = pair.burn(removeLiquidityParams.liquidity, address(this));
        }

        // Repurposing amountA/amountB variables to represent finalOutputAmountA/finalOutputAmountB (after all the swaps) to save gas
        address finalTokenA;
        address finalTokenB;
        (amountsA, finalTokenA, amountA) =
            _swapExactTokensForTokens(removeLiquidityParams.tokenA, amountA, removeLiquidityParams.swapStepsA);
        (amountsB, finalTokenB, amountB) =
            _swapExactTokensForTokens(removeLiquidityParams.tokenB, amountB, removeLiquidityParams.swapStepsB);

        // Validate that enough of tokenA/B (after all the swaps) was received
        if (amountA < removeLiquidityParams.amountAMin) {
            revert InsufficientTokenAmount(finalTokenA, amountA, removeLiquidityParams.amountAMin);
        }
        if (amountB < removeLiquidityParams.amountBMin) {
            revert InsufficientTokenAmount(finalTokenB, amountB, removeLiquidityParams.amountBMin);
        }

        // Transfer finalTokenA/finalTokenB to the user
        _transferTokensOut(finalTokenA, removeLiquidityParams.swapStepsA, to);
        _transferTokensOut(finalTokenB, removeLiquidityParams.swapStepsB, to);
    }

    function _removeLiquiditySingle(
        IButtonswapPair pair,
        RemoveLiquidityParams calldata removeLiquidityParams,
        address to
    ) internal returns (uint256[] memory amountsA, uint256[] memory amountsB) {
        // Burn the pair-tokens for amountA of tokenA and amountB of tokenB
        (address token0,) = ButtonswapLibrary.sortTokens(removeLiquidityParams.tokenA, removeLiquidityParams.tokenB);
        uint256 amountA;
        uint256 amountB;
        if (removeLiquidityParams.tokenA == token0) {
            (amountA, amountB) = pair.burnFromReservoir(removeLiquidityParams.liquidity, address(this));
        } else {
            (amountB, amountA) = pair.burnFromReservoir(removeLiquidityParams.liquidity, address(this));
        }

        // Repurposing amountA/amountB variables to represent finalOutputAmountA/finalOutputAmountB (after all the swaps) to save gas
        address finalTokenA;
        address finalTokenB;
        if (amountA > 0) {
            (amountsA, finalTokenA, amountA) =
                _swapExactTokensForTokens(removeLiquidityParams.tokenA, amountA, removeLiquidityParams.swapStepsA);
            finalTokenB = removeLiquidityParams.tokenB;
        } else {
            (amountsB, finalTokenB, amountB) =
                _swapExactTokensForTokens(removeLiquidityParams.tokenB, amountB, removeLiquidityParams.swapStepsB);
            finalTokenA = removeLiquidityParams.tokenA;
        }

        // Validate that enough of tokenA/B (after all the swaps) was received
        if (amountA < removeLiquidityParams.amountAMin) {
            revert InsufficientTokenAmount(finalTokenA, amountA, removeLiquidityParams.amountAMin);
        }
        if (amountB < removeLiquidityParams.amountBMin) {
            revert InsufficientTokenAmount(finalTokenB, amountB, removeLiquidityParams.amountBMin);
        }

        // Transfer finalTokenA/finalTokenB to the user
        _transferTokensOut(finalTokenA, removeLiquidityParams.swapStepsA, to);
        _transferTokensOut(finalTokenB, removeLiquidityParams.swapStepsB, to);
    }

    function _removeLiquidity(IButtonswapPair pair, RemoveLiquidityParams calldata removeLiquidityParams, address to)
        internal
        returns (uint256[] memory amountsA, uint256[] memory amountsB)
    {
        // Transfer pair-tokens to the router from msg.sender
        pair.transferFrom(msg.sender, address(this), removeLiquidityParams.liquidity);

        // Route to the appropriate internal removeLiquidity function based on the operation
        if (removeLiquidityParams.operation == ButtonswapOperations.Liquidity.DUAL) {
            return _removeLiquidityDual(pair, removeLiquidityParams, to);
        } else if (removeLiquidityParams.operation == ButtonswapOperations.Liquidity.SINGLE) {
            return _removeLiquiditySingle(pair, removeLiquidityParams, to);
        }
    }

    function _removeLiquidityGetPair(RemoveLiquidityParams calldata removeLiquidityParams)
        internal
        view
        returns (address pairAddress)
    {
        pairAddress = IButtonswapFactory(factory).getPair(removeLiquidityParams.tokenA, removeLiquidityParams.tokenB);
        // If pair doesn't exist, throw error
        if (pairAddress == address(0)) {
            revert PairDoesNotExist(removeLiquidityParams.tokenA, removeLiquidityParams.tokenB);
        }
    }

    function removeLiquidity(RemoveLiquidityParams calldata removeLiquidityParams, address to, uint256 deadline)
        external
        ensure(deadline)
        returns (uint256[] memory amountsA, uint256[] memory amountsB)
    {
        // Fetch the pair
        IButtonswapPair pair = IButtonswapPair(_removeLiquidityGetPair(removeLiquidityParams));
        // Remove liquidity
        return _removeLiquidity(pair, removeLiquidityParams, to);
    }

    function removeLiquidityWithPermit(
        RemoveLiquidityParams calldata removeLiquidityParams,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external ensure(deadline) returns (uint256[] memory amountsA, uint256[] memory amountsB) {
        // Fetch the pair
        IButtonswapPair pair = IButtonswapPair(_removeLiquidityGetPair(removeLiquidityParams));
        // Call permit on the pair
        uint256 value = approveMax ? type(uint256).max : removeLiquidityParams.liquidity;
        pair.permit(msg.sender, address(this), value, deadline, v, r, s);
        // Remove liquidity
        return _removeLiquidity(pair, removeLiquidityParams, to);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapFactoryErrors} from "./IButtonswapFactoryErrors.sol";
import {IButtonswapFactoryEvents} from "./IButtonswapFactoryEvents.sol";

interface IButtonswapFactory is IButtonswapFactoryErrors, IButtonswapFactoryEvents {
    /**
     * @notice Returns the current address for `feeTo`.
     * The owner of this address receives the protocol fee as it is collected over time.
     * @return _feeTo The `feeTo` address
     */
    function feeTo() external view returns (address _feeTo);

    /**
     * @notice Returns the current address for `feeToSetter`.
     * The owner of this address has the power to update both `feeToSetter` and `feeTo`.
     * @return _feeToSetter The `feeToSetter` address
     */
    function feeToSetter() external view returns (address _feeToSetter);

    /**
     * @notice The name of the ERC20 liquidity token.
     * @return _tokenName The `tokenName`
     */
    function tokenName() external view returns (string memory _tokenName);

    /**
     * @notice The symbol of the ERC20 liquidity token.
     * @return _tokenSymbol The `tokenSymbol`
     */
    function tokenSymbol() external view returns (string memory _tokenSymbol);

    /**
     * @notice Returns the current state of restricted creation.
     * If true, then no new pairs, only feeToSetter can create new pairs
     * @return _isCreationRestricted The `isCreationRestricted` state
     */
    function isCreationRestricted() external view returns (bool _isCreationRestricted);

    /**
     * @notice Returns the current address for `isCreationRestrictedSetter`.
     * The owner of this address has the power to update both `isCreationRestrictedSetter` and `isCreationRestricted`.
     * @return _isCreationRestrictedSetter The `isCreationRestrictedSetter` address
     */
    function isCreationRestrictedSetter() external view returns (address _isCreationRestrictedSetter);

    /**
     * @notice Get the (unique) Pair address created for the given combination of `tokenA` and `tokenB`.
     * If the Pair does not exist then zero address is returned.
     * @param tokenA The first unsorted token
     * @param tokenB The second unsorted token
     * @return pair The address of the Pair instance
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Get the Pair address at the given `index`, ordered chronologically.
     * @param index The index to query
     * @return pair The address of the Pair created at the given `index`
     */
    function allPairs(uint256 index) external view returns (address pair);

    /**
     * @notice Get the current total number of Pairs created
     * @return count The total number of Pairs created
     */
    function allPairsLength() external view returns (uint256 count);

    /**
     * @notice Creates a new {ButtonswapPair} instance for the given unsorted tokens `tokenA` and `tokenB`.
     * @dev The tokens are sorted later, but can be provided to this method in either order.
     * @param tokenA The first unsorted token address
     * @param tokenB The second unsorted token address
     * @return pair The address of the new {ButtonswapPair} instance
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Updates the address that receives the protocol fee.
     * This can only be called by the `feeToSetter` address.
     * @param _feeTo The new address
     */
    function setFeeTo(address _feeTo) external;

    /**
     * @notice Updates the address that has the power to set the `feeToSetter` and `feeTo` addresses.
     * This can only be called by the `feeToSetter` address.
     * @param _feeToSetter The new address
     */
    function setFeeToSetter(address _feeToSetter) external;

    /**
     * @notice Updates the state of restricted creation.
     * This can only be called by the `feeToSetter` address.
     * @param _isCreationRestricted The new state
     */
    function setIsCreationRestricted(bool _isCreationRestricted) external;

    /**
     * @notice Updates the address that has the power to set the `isCreationRestrictedSetter` and `isCreationRestricted`.
     * This can only be called by the `isCreationRestrictedSetter` address.
     * @param _isCreationRestrictedSetter The new address
     */
    function setIsCreationRestrictedSetter(address _isCreationRestrictedSetter) external;

    /**
     * @notice Returns the current address for `isPausedSetter`.
     * The owner of this address has the power to update both `isPausedSetter` and call `setIsPaused`.
     * @return _isPausedSetter The `isPausedSetter` address
     */
    function isPausedSetter() external view returns (address _isPausedSetter);

    /**
     * @notice Updates the address that has the power to set the `isPausedSetter` and call `setIsPaused`.
     * This can only be called by the `isPausedSetter` address.
     * @param _isPausedSetter The new address
     */
    function setIsPausedSetter(address _isPausedSetter) external;

    /**
     * @notice Updates the pause state of given Pairs.
     * This can only be called by the `feeToSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param isPausedNew The new pause state
     */
    function setIsPaused(address[] calldata pairs, bool isPausedNew) external;

    /**
     * @notice Returns the current address for `paramSetter`.
     * The owner of this address has the power to update `paramSetter`, default parameters, and current parameters on existing pairs
     * @return _paramSetter The `paramSetter` address
     */
    function paramSetter() external view returns (address _paramSetter);

    /**
     * @notice Updates the address that has the power to set the `paramSetter` and update the default params.
     * This can only be called by the `paramSetter` address.
     * @param _paramSetter The new address
     */
    function setParamSetter(address _paramSetter) external;

    /**
     * @notice Returns the default value of `movingAverageWindow` used for new pairs.
     * @return _defaultMovingAverageWindow The `defaultMovingAverageWindow` value
     */
    function defaultMovingAverageWindow() external view returns (uint32 _defaultMovingAverageWindow);

    /**
     * @notice Returns the default value of `maxVolatilityBps` used for new pairs.
     * @return _defaultMaxVolatilityBps The `defaultMaxVolatilityBps` value
     */
    function defaultMaxVolatilityBps() external view returns (uint16 _defaultMaxVolatilityBps);

    /**
     * @notice Returns the default value of `minTimelockDuration` used for new pairs.
     * @return _defaultMinTimelockDuration The `defaultMinTimelockDuration` value
     */
    function defaultMinTimelockDuration() external view returns (uint32 _defaultMinTimelockDuration);

    /**
     * @notice Returns the default value of `maxTimelockDuration` used for new pairs.
     * @return _defaultMaxTimelockDuration The `defaultMaxTimelockDuration` value
     */
    function defaultMaxTimelockDuration() external view returns (uint32 _defaultMaxTimelockDuration);

    /**
     * @notice Returns the default value of `maxSwappableReservoirLimitBps` used for new pairs.
     * @return _defaultMaxSwappableReservoirLimitBps The `defaultMaxSwappableReservoirLimitBps` value
     */
    function defaultMaxSwappableReservoirLimitBps()
        external
        view
        returns (uint16 _defaultMaxSwappableReservoirLimitBps);

    /**
     * @notice Returns the default value of `swappableReservoirGrowthWindow` used for new pairs.
     * @return _defaultSwappableReservoirGrowthWindow The `defaultSwappableReservoirGrowthWindow` value
     */
    function defaultSwappableReservoirGrowthWindow()
        external
        view
        returns (uint32 _defaultSwappableReservoirGrowthWindow);

    /**
     * @notice Updates the default parameters used for new pairs.
     * This can only be called by the `paramSetter` address.
     * @param newDefaultMovingAverageWindow The new defaultMovingAverageWindow
     * @param newDefaultMaxVolatilityBps The new defaultMaxVolatilityBps
     * @param newDefaultMinTimelockDuration The new defaultMinTimelockDuration
     * @param newDefaultMaxTimelockDuration The new defaultMaxTimelockDuration
     * @param newDefaultMaxSwappableReservoirLimitBps The new defaultMaxSwappableReservoirLimitBps
     * @param newDefaultSwappableReservoirGrowthWindow The new defaultSwappableReservoirGrowthWindow
     */
    function setDefaultParameters(
        uint32 newDefaultMovingAverageWindow,
        uint16 newDefaultMaxVolatilityBps,
        uint32 newDefaultMinTimelockDuration,
        uint32 newDefaultMaxTimelockDuration,
        uint16 newDefaultMaxSwappableReservoirLimitBps,
        uint32 newDefaultSwappableReservoirGrowthWindow
    ) external;

    /**
     * @notice Updates the `movingAverageWindow` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMovingAverageWindow The new `movingAverageWindow` value
     */
    function setMovingAverageWindow(address[] calldata pairs, uint32 newMovingAverageWindow) external;

    /**
     * @notice Updates the `maxVolatilityBps` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMaxVolatilityBps The new `maxVolatilityBps` value
     */
    function setMaxVolatilityBps(address[] calldata pairs, uint16 newMaxVolatilityBps) external;

    /**
     * @notice Updates the `minTimelockDuration` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMinTimelockDuration The new `minTimelockDuration` value
     */
    function setMinTimelockDuration(address[] calldata pairs, uint32 newMinTimelockDuration) external;

    /**
     * @notice Updates the `maxTimelockDuration` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMaxTimelockDuration The new `maxTimelockDuration` value
     */
    function setMaxTimelockDuration(address[] calldata pairs, uint32 newMaxTimelockDuration) external;

    /**
     * @notice Updates the `maxSwappableReservoirLimitBps` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newMaxSwappableReservoirLimitBps The new `maxSwappableReservoirLimitBps` value
     */
    function setMaxSwappableReservoirLimitBps(address[] calldata pairs, uint16 newMaxSwappableReservoirLimitBps)
        external;

    /**
     * @notice Updates the `swappableReservoirGrowthWindow` value of given Pairs.
     * This can only be called by the `paramSetter` address.
     * @param pairs A list of addresses for the pairs that should be updated
     * @param newSwappableReservoirGrowthWindow The new `swappableReservoirGrowthWindow` value
     */
    function setSwappableReservoirGrowthWindow(address[] calldata pairs, uint32 newSwappableReservoirGrowthWindow)
        external;

    /**
     * @notice Returns the last token pair created and the parameters used.
     * @return token0 The first token address
     * @return token1 The second token address
     * @return movingAverageWindow The moving average window
     * @return maxVolatilityBps The max volatility bps
     * @return minTimelockDuration The minimum time lock duration
     * @return maxTimelockDuration The maximum time lock duration
     * @return maxSwappableReservoirLimitBps The max swappable reservoir limit bps
     * @return swappableReservoirGrowthWindow The swappable reservoir growth window
     */
    function lastCreatedTokensAndParameters()
        external
        returns (
            address token0,
            address token1,
            uint32 movingAverageWindow,
            uint16 maxVolatilityBps,
            uint32 minTimelockDuration,
            uint32 maxTimelockDuration,
            uint16 maxSwappableReservoirLimitBps,
            uint32 swappableReservoirGrowthWindow
        );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapPairErrors} from "./IButtonswapPairErrors.sol";
import {IButtonswapPairEvents} from "./IButtonswapPairEvents.sol";
import {IButtonswapERC20} from "../IButtonswapERC20/IButtonswapERC20.sol";

interface IButtonswapPair is IButtonswapPairErrors, IButtonswapPairEvents, IButtonswapERC20 {
    /**
     * @notice The smallest value that {IButtonswapERC20-totalSupply} can be.
     * @dev After the first mint the total liquidity (represented by the liquidity token total supply) can never drop below this value.
     *
     * This is to protect against an attack where the attacker mints a very small amount of liquidity, and then donates pool tokens to skew the ratio.
     * This results in future minters receiving no liquidity tokens when they deposit.
     * By enforcing a minimum liquidity value this attack becomes prohibitively expensive to execute.
     * @return MINIMUM_LIQUIDITY The MINIMUM_LIQUIDITY value
     */
    function MINIMUM_LIQUIDITY() external pure returns (uint256 MINIMUM_LIQUIDITY);

    /**
     * @notice The duration for which the moving average is calculated for.
     * @return _movingAverageWindow The value of movingAverageWindow
     */
    function movingAverageWindow() external view returns (uint32 _movingAverageWindow);

    /**
     * @notice Updates the movingAverageWindow parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#movingaveragewindow) for more detail.
     * @param newMovingAverageWindow The new value for movingAverageWindow
     */
    function setMovingAverageWindow(uint32 newMovingAverageWindow) external;

    /**
     * @notice Numerator (over 10_000) of the threshold when price volatility triggers maximum single-sided timelock duration.
     * @return _maxVolatilityBps The value of maxVolatilityBps
     */
    function maxVolatilityBps() external view returns (uint16 _maxVolatilityBps);

    /**
     * @notice Updates the maxVolatilityBps parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#maxvolatilitybps) for more detail.
     * @param newMaxVolatilityBps The new value for maxVolatilityBps
     */
    function setMaxVolatilityBps(uint16 newMaxVolatilityBps) external;

    /**
     * @notice How long the minimum singled-sided timelock lasts for.
     * @return _minTimelockDuration The value of minTimelockDuration
     */
    function minTimelockDuration() external view returns (uint32 _minTimelockDuration);

    /**
     * @notice Updates the minTimelockDuration parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#mintimelockduration) for more detail.
     * @param newMinTimelockDuration The new value for minTimelockDuration
     */
    function setMinTimelockDuration(uint32 newMinTimelockDuration) external;

    /**
     * @notice How long the maximum singled-sided timelock lasts for.
     * @return _maxTimelockDuration The value of maxTimelockDuration
     */
    function maxTimelockDuration() external view returns (uint32 _maxTimelockDuration);

    /**
     * @notice Updates the maxTimelockDuration parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#maxtimelockduration) for more detail.
     * @param newMaxTimelockDuration The new value for maxTimelockDuration
     */
    function setMaxTimelockDuration(uint32 newMaxTimelockDuration) external;

    /**
     * @notice Numerator (over 10_000) of the fraction of the pool balance that acts as the maximum limit on how much of the reservoir
     * can be swapped in a given timeframe.
     * @return _maxSwappableReservoirLimitBps The value of maxSwappableReservoirLimitBps
     */
    function maxSwappableReservoirLimitBps() external view returns (uint16 _maxSwappableReservoirLimitBps);

    /**
     * @notice Updates the maxSwappableReservoirLimitBps parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#maxswappablereservoirlimitbps) for more detail.
     * @param newMaxSwappableReservoirLimitBps The new value for maxSwappableReservoirLimitBps
     */
    function setMaxSwappableReservoirLimitBps(uint16 newMaxSwappableReservoirLimitBps) external;

    /**
     * @notice How much time it takes for the swappable reservoir value to grow from nothing to its maximum value.
     * @return _swappableReservoirGrowthWindow The value of swappableReservoirGrowthWindow
     */
    function swappableReservoirGrowthWindow() external view returns (uint32 _swappableReservoirGrowthWindow);

    /**
     * @notice Updates the swappableReservoirGrowthWindow parameter of the pair.
     * This can only be called by the Factory address.
     * Refer to [parameters.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/parameters.md#swappablereservoirgrowthwindow) for more detail.
     * @param newSwappableReservoirGrowthWindow The new value for swappableReservoirGrowthWindow
     */
    function setSwappableReservoirGrowthWindow(uint32 newSwappableReservoirGrowthWindow) external;

    /**
     * @notice The address of the {ButtonswapFactory} instance used to create this Pair.
     * @dev Set to `msg.sender` in the Pair constructor.
     * @return factory The factory address
     */
    function factory() external view returns (address factory);

    /**
     * @notice The address of the first sorted token.
     * @return token0 The token address
     */
    function token0() external view returns (address token0);

    /**
     * @notice The address of the second sorted token.
     * @return token1 The token address
     */
    function token1() external view returns (address token1);

    /**
     * @notice The time-weighted average price of the Pair.
     * The price is of `token0` in terms of `token1`.
     * @dev The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * Consequently this value must be divided by `2^112` to get the actual price.
     *
     * Because of the time weighting, `price0CumulativeLast` must also be divided by the total Pair lifetime to get the average price over that time period.
     * @return price0CumulativeLast The current cumulative `token0` price
     */
    function price0CumulativeLast() external view returns (uint256 price0CumulativeLast);

    /**
     * @notice The time-weighted average price of the Pair.
     * The price is of `token1` in terms of `token0`.
     * @dev The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * Consequently this value must be divided by `2^112` to get the actual price.
     *
     * Because of the time weighting, `price1CumulativeLast` must also be divided by the total Pair lifetime to get the average price over that time period.
     * @return price1CumulativeLast The current cumulative `token1` price
     */
    function price1CumulativeLast() external view returns (uint256 price1CumulativeLast);

    /**
     * @notice The timestamp for when the single-sided timelock concludes.
     * The timelock is initiated based on price volatility of swaps over the last `movingAverageWindow`, and can be
     *   extended by new swaps if they are sufficiently volatile.
     * The timelock protects against attempts to manipulate the price that is used to valuate the reservoir tokens during
     *   single-sided operations.
     * It also guards against general legitimate volatility, as it is preferable to defer single-sided operations until
     *   it is clearer what the market considers the price to be.
     * @return singleSidedTimelockDeadline The current deadline timestamp
     */
    function singleSidedTimelockDeadline() external view returns (uint120 singleSidedTimelockDeadline);

    /**
     * @notice The timestamp by which the amount of reservoir tokens that can be exchanged during a single-sided operation
     *   reaches its maximum value.
     * This maximum value is not necessarily the entirety of the reservoir, instead being calculated as a fraction of the
     *   corresponding token's active liquidity.
     * @return swappableReservoirLimitReachesMaxDeadline The current deadline timestamp
     */
    function swappableReservoirLimitReachesMaxDeadline()
        external
        view
        returns (uint120 swappableReservoirLimitReachesMaxDeadline);

    /**
     * @notice Returns the current limit on the number of reservoir tokens that can be exchanged during a single-sided mint/burn operation.
     * @return swappableReservoirLimit The amount of reservoir token that can be exchanged
     */
    function getSwappableReservoirLimit() external view returns (uint256 swappableReservoirLimit);

    /**
     * @notice Whether the Pair is currently paused
     * @return _isPaused The paused state
     */
    function getIsPaused() external view returns (bool _isPaused);

    /**
     * @notice Updates the pause state.
     * This can only be called by the Factory address.
     * @param isPausedNew The new value for isPaused
     */
    function setIsPaused(bool isPausedNew) external;

    /**
     * @notice Get the current liquidity values.
     * @return _pool0 The active `token0` liquidity
     * @return _pool1 The active `token1` liquidity
     * @return _reservoir0 The inactive `token0` liquidity
     * @return _reservoir1 The inactive `token1` liquidity
     * @return _blockTimestampLast The timestamp of when the price was last updated
     */
    function getLiquidityBalances()
        external
        view
        returns (uint112 _pool0, uint112 _pool1, uint112 _reservoir0, uint112 _reservoir1, uint32 _blockTimestampLast);

    /**
     * @notice The current `movingAveragePrice0` value, based on the current block timestamp.
     * @dev This is the `token0` price, time weighted to prevent manipulation.
     * Refer to [reservoir-valuation.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/reservoir-valuation.md#price-stability) for more detail.
     *
     * The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * It is used to valuate the reservoir tokens that are exchanged during single-sided operations.
     * @return _movingAveragePrice0 The current `movingAveragePrice0` value
     */
    function movingAveragePrice0() external view returns (uint256 _movingAveragePrice0);

    /**
     * @notice Mints new liquidity tokens to `to` based on `amountIn0` of `token0` and `amountIn1  of`token1` deposited.
     * Expects both tokens to be deposited in a ratio that matches the current Pair price.
     * @dev The token deposits are deduced to be the delta between token balance before and after the transfers in order to account for unusual tokens.
     * Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#dual-sided-mint) for more detail.
     * @param amountIn0 The amount of `token0` that should be transferred in from the user
     * @param amountIn1 The amount of `token1` that should be transferred in from the user
     * @param to The account that receives the newly minted liquidity tokens
     * @return liquidityOut THe amount of liquidity tokens minted
     */
    function mint(uint256 amountIn0, uint256 amountIn1, address to) external returns (uint256 liquidityOut);

    /**
     * @notice Mints new liquidity tokens to `to` based on how much `token0` or `token1` has been deposited.
     * The token transferred is the one that the Pair does not have a non-zero inactive liquidity balance for.
     * Expects only one token to be deposited, so that it can be paired with the other token's inactive liquidity.
     * @dev The token deposits are deduced to be the delta between token balance before and after the transfers in order to account for unusual tokens.
     * Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#single-sided-mint) for more detail.
     * @param amountIn The amount of tokens that should be transferred in from the user
     * @param to The account that receives the newly minted liquidity tokens
     * @return liquidityOut THe amount of liquidity tokens minted
     */
    function mintWithReservoir(uint256 amountIn, address to) external returns (uint256 liquidityOut);

    /**
     * @notice Burns `liquidityIn` liquidity tokens to redeem to `to` the corresponding `amountOut0` of `token0` and `amountOut1` of `token1`.
     * @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#dual-sided-burn) for more detail.
     * @param liquidityIn The amount of liquidity tokens to burn
     * @param to The account that receives the redeemed tokens
     * @return amountOut0 The amount of `token0` that the liquidity tokens are redeemed for
     * @return amountOut1 The amount of `token1` that the liquidity tokens are redeemed for
     */
    function burn(uint256 liquidityIn, address to) external returns (uint256 amountOut0, uint256 amountOut1);

    /**
     * @notice Burns `liquidityIn` liquidity tokens to redeem to `to` the corresponding `amountOut0` of `token0` and `amountOut1` of `token1`.
     * Only returns tokens from the non-zero inactive liquidity balance, meaning one of `amountOut0` and `amountOut1` will be zero.
     * @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#single-sided-burn) for more detail.
     * @param liquidityIn The amount of liquidity tokens to burn
     * @param to The account that receives the redeemed tokens
     * @return amountOut0 The amount of `token0` that the liquidity tokens are redeemed for
     * @return amountOut1 The amount of `token1` that the liquidity tokens are redeemed for
     */
    function burnFromReservoir(uint256 liquidityIn, address to)
        external
        returns (uint256 amountOut0, uint256 amountOut1);

    /**
     * @notice Swaps one token for the other, taking `amountIn0` of `token0` and `amountIn1` of `token1` from the sender and sending `amountOut0` of `token0` and `amountOut1` of `token1` to `to`.
     * The price of the swap is determined by maintaining the "K Invariant".
     * A 0.3% fee is collected to distribute between liquidity providers and the protocol.
     * @dev The token deposits are deduced to be the delta between the current Pair contract token balances and the last stored balances.
     * Optional calldata can be passed to `data`, which will be used to confirm the output token transfer with `to` if `to` is a contract that implements the {IButtonswapCallee} interface.
     * Refer to [swap-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/swap-math.md) for more detail.
     * @param amountIn0 The amount of `token0` that the sender sends
     * @param amountIn1 The amount of `token1` that the sender sends
     * @param amountOut0 The amount of `token0` that the recipient receives
     * @param amountOut1 The amount of `token1` that the recipient receives
     * @param to The account that receives the swap output
     */
    function swap(uint256 amountIn0, uint256 amountIn1, uint256 amountOut0, uint256 amountOut1, address to) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {ButtonswapOperations} from "../../libraries/ButtonswapOperations.sol";
import {IGenericButtonswapRouterErrors} from "./IGenericButtonswapRouterErrors.sol";

interface IGenericButtonswapRouter is IGenericButtonswapRouterErrors {
    /**
     * @notice Struct for swapping tokens
     * @param operation The operation to perform: (SWAP, WRAP_BUTTON, UNWRAP_BUTTON, WRAP_WETH, UNWRAP_WETH)
     * @param tokenOut The address of the output token to swap to. If ETH (or network currency), address(0) is used.
     */
    struct SwapStep {
        ButtonswapOperations.Swap operation;
        address tokenOut;
    }

    /**
     * @notice Struct for adding liquidity
     * @dev The last `SwapStep.tokenOut` of `swapStepsA` and `swapStepsB` determine the pair to add liquidity to.
     * If they do not exist, then `tokenA` and `tokenB` are used.
     * @param operation Whether to perform dual- or single- sided liquidity provision
     * @param tokenA The address of the first token provided
     * @param tokenB The address of the second token provided
     * @param swapStepsA The swap steps to transform tokenA before adding liquidity
     * @param swapStepsB The swap steps to transform tokenB before adding liquidity
     * @param amountADesired The maximum amount of tokenA to provide
     * @param amountBDesired The maximum amount of tokenB to provide
     * @param amountAMin The minimum amount of the first token to provide
     * @param amountBMin The minimum amount of the second token to provide
     * @param movingAveragePrice0ThresholdBps The percentage threshold that movingAveragePrice0 can deviate from the current price.
     * @param createPair Whether to create the pair. Will trigger revert if false and the pair does not exist, or if true and the pair already exists.
     */
    struct AddLiquidityParams {
        ButtonswapOperations.Liquidity operation; // Potentially just separate out the function
        address tokenA;
        address tokenB;
        SwapStep[] swapStepsA;
        SwapStep[] swapStepsB;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        uint256 liquidityMin;
        uint256 movingAveragePrice0ThresholdBps;
        bool createPair;
    }

    /**
     * @notice Struct for removing liquidity
     * @dev `tokenA` and `tokenB` determine the pair to remove liquidity from. The output the tokens the user receives
     * are determined by `swapStepsA` and `swapStepsB`. If they do not exist, then `tokenA` and `tokenB` are used.
     * @param operation Whether to perform dual- or single- sided liquidity withdrawal
     * @param tokenA The address of the first token in the pair
     * @param tokenB The address of the second token in the pair
     * @param swapStepsA The swap steps to transform tokenA after removing it from the pair
     * @param swapStepsB The swap steps to transform tokenB after removing it from the pair
     * @param liquidity The amount of liquidity tokens to burn
     * @param amountAMin The minimum amount of the first token to receive
     * @param amountBMin The minimum amount of the second token to receive
     */
    struct RemoveLiquidityParams {
        ButtonswapOperations.Liquidity operation;
        address tokenA;
        address tokenB;
        SwapStep[] swapStepsA;
        SwapStep[] swapStepsB;
        uint256 liquidity;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    /**
     * @notice Returns the address of the Buttonswap Factory
     * @return factory The address of the Buttonswap Factory
     */
    function factory() external view returns (address factory);
    /**
     * @notice Returns the address of the WETH token
     * @return WETH The address of the WETH token
     */
    function WETH() external view returns (address WETH);

    /**
     * @notice Given an ordered array of tokens, performs consecutive swaps/transformation operations from a specific amount of the first token to the last token in the swapSteps array.
     * @dev Example:
     * ```solidity
     * // Example: exact ETH -> WETH -> stETH
     * swapExactTokensForTokens(
     *     address(0),
     *     5*10**18,
     *     4*10**18,
     *     [
     *         IGenericButtonswapRouter.SwapStep(ButtonswapOperations.Swap.WRAP_ETH, address(weth)),
     *         IGenericButtonswapRouter.SwapStep(ButtonSwapOperation.Swap.SWAP, address(stETH))
     *     ],
     *     toAddress,
     *     deadline
     * );
     * ```
     * @param tokenIn The address of the input token
     * @param amountIn The amount of the first token to swap
     * @param amountOutMin The minimum amount of the last token to receive from the swap
     * @param swapSteps An array of SwapStep structs representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amounts The amounts of each token received during the execution of swapSteps
     */
    function swapExactTokensForTokens(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        SwapStep[] calldata swapSteps,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    //

    /**
     * @notice Given an ordered array of tokens, performs consecutive swaps/transformation operations from the first token to a specific amount of the last token in the swapSteps array.
     * @dev Note: If there is excess balance stored in the contract, it will be transferred out. Thus the actual amount received may be more than the `amountOut` specified.
     *
     * Example: stETH -> rrETH -> rETH
     * ```solidity
     * // Example: stETH -> rrETH -> rETH
     * swapTokensForExactTokens(
     *     address(stETH)
     *     4*10**18,
     *     5*10**18,
     *     [
     *         IGenericButtonswapRouter.SwapStep(ButtonSwapOperation.Swap.SWAP, address(rebasingRocketEth))
     *         IGenericButtonswapRouter.SwapStep(ButtonswapOperations.Swap.UNWRAP_BUTTON, address(rocketETH)),
     *     ],
     *     toAddress,
     *     deadline
     * );
     * ```
     * @param tokenIn The address of the input token
     * @param amountOut The amount of the last token to receive from the swap.
     * @param amountInMax The maximum amount of the first token to swap.
     * @param swapSteps An array of SwapStep structs representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amounts The amounts of each token received during the execution of swapSteps
     */
    function swapTokensForExactTokens(
        address tokenIn,
        uint256 amountOut,
        uint256 amountInMax,
        SwapStep[] calldata swapSteps,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    /**
     * @notice Adds liquidity to a pair and transfers the liquidity tokens to the recipient.
     * @dev If `addLiquidityParams.liquidity` is `ButtonswapOperations.Liquidity.DUAL`, then first the pair is created if it doesn't exist yet.
     * If the pair is empty, `addLiquidityParams.amountAMin` and `addLiquidityParams.amountBMin` are ignored.
     * If the pair is nonempty, it deposits as much of `addLiquidityParams.tokenA` and `addLiquidityParams.tokenB` as possible
     * (after applying `addLiquidityParams.swapStepsA` and `addLiquidityParams.swapStepsB`) while maintaining 3 conditions:
     * 1. The ratio of final tokenA to final tokenB in the pair remains approximately the same
     * 2. The amount of `addLiquidityParams.tokenA` provided from the sender is at least `addLiquidityParams.amountAMin` but less than or equal to `addLiquidityParams.amountADesired`
     * 3. The amount of `addLiquidityParams.tokenB` provided from the sender is at least `addLiquidityParams.amountBMin` but less than or equal to `addLiquidityParams.amountBDesired`
     * ---
     * If `addLiquidityParams.liquidity` is `ButtonswapOperations.Liquidity.SINGLE`, it only adds liquidity opposite to the pair's existing reservoir.this
     * Since there at most one reservoir at a given time, some conditions are checked:
     * 1. If there is no reservoir, it rejects
     * 2. The token corresponding to the existing reservoir has its corresponding amountDesired parameter ignored
     * 3. The reservoir is deducted from and transformed into the corresponding output token (after applying swapSteps), and then checked against corresponding amountMin parameter.
     * ---
     * *Example: (ETH -> WETH) + (rETH -> rrETH)
     * ```
     * // Example: (ETH -> WETH) + (rETH -> rrETH)
     * addLiquidity(
     *     IGenericButtonswapRouter.AddLiquidityParams(
     *         ButtonswapOperations.Liquidity.DUAL,
     *         address(0),
     *         address(rETH),
     *         [
     *             IGenericButtonswapRouter.SwapStep(ButtonSwapOperation.Swap.WRAP_WETH, address(weth))
     *         ],
     *         [
     *             IGenericButtonswapRouter.SwapStep(ButtonSwapOperation.Swap.WRAP_BUTTON, address(rrETH))
     *         ],
     *         4000 * 10**18,
     *         4000 * 10**18,
     *         3000 * 10**18,
     *         3000 * 10**18,
     *         1,
     *     ),
     *     toAddress,
     *     deadline
     * );
     * ```
     * @param addLiquidityParams The AddLiquidityParams struct containing all the parameters necessary to add liquidity
     * @param to The address to send the liquidity tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountsA The amounts of each tokenA received during the execution of swapStepsA before adding liquidity
     * @return amountsB The amounts of each tokenB received during the execution of swapStepsB before adding liquidity
     * @return liquidity The amount of liquidity tokens minted
     */
    function addLiquidity(AddLiquidityParams calldata addLiquidityParams, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amountsA, uint256[] memory amountsB, uint256 liquidity);

    /**
     * @notice Removes liquidity from a pair, and transfers the tokens to the recipient.
     * @dev `removeLiquidityParams.liquidity` determines whether to perform dual- or single- sided liquidity withdrawal.
     *
     * Example: (WETH -> ETH) - (rrETH -> stETH)*
     * ```
     * // Example: (WETH -> ETH) - (rrETH -> stETH)
     * removeLiquidity(
     *     IGenericButtonswapRouter.RemoveLiquidityParams(
     *         ButtonswapOperations.Liquidity.DUAL,
     *         address(WETH),
     *         address(rrETH),
     *         [
     *             IGenericButtonswapRouter.SwapStep(ButtonSwapOperation.Swap.UNWRAP_WETH, address(0))
     *         ],
     *         [
     *             IGenericButtonswapRouter.SwapStep(ButtonSwapOperation.Swap.SWAP, address(stETH))
     *         ],
     *         2000 * 10**18,
     *         2000 * 10**18,
     *         2000 * 10**18,
     *         1,
     *     ),
     *     toAddress,
     *     deadline
     * );
     * ```
     * @param removeLiquidityParams The RemoveLiquidityParams struct containing all the parameters necessary to remove liquidity
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountsA The amounts of each tokenA received during the execution of swapStepsA after removing liquidity
     * @return amountsB The amounts of each tokenB received during the execution of swapStepsB after removing liquidity
     */
    function removeLiquidity(RemoveLiquidityParams calldata removeLiquidityParams, address to, uint256 deadline)
        external
        returns (uint256[] memory amountsA, uint256[] memory amountsB);

    /**
     * @notice Similar to `removeLiquidity()` but utilizes the Permit signatures to reduce gas consumption.
     * Removes liquidity from a pair, and transfers the tokens to the recipient.
     * @param removeLiquidityParams The RemoveLiquidityParams struct containing all the parameters necessary to remove liquidity
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @param approveMax Whether the signature is for the max uint256 or liquidity value
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     * @return amountsA The amounts of each tokenA received during the execution of swapStepsA after removing liquidity
     * @return amountsB The amounts of each tokenB received during the execution of swapStepsB after removing liquidity
     */
    function removeLiquidityWithPermit(
        RemoveLiquidityParams calldata removeLiquidityParams,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256[] memory amountsA, uint256[] memory amountsB);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);
}

pragma solidity >=0.5.0;

interface IButtonToken {
    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens.
    /// @param amount The amount of wrapper tokens to mint.
    /// @return The amount of underlying tokens deposited.
    function mint(uint256 amount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of underlying tokens withdrawn.
    function burnAll() external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function deposit(uint256 uAmount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of wrapper tokens burnt.
    function withdrawAll() external returns (uint256);

    //--------------------------------------------------------------------------
    // ButtonWrapper view methods

    /// @return The address of the underlying token.
    function underlying() external view returns (address);

    /// @return The total underlying tokens held by the wrapper contract.
    function totalUnderlying() external view returns (uint256);

    /// @param who The account address.
    /// @return The underlying token balance of the account.
    function balanceOfUnderlying(address who) external view returns (uint256);

    /// @param uAmount The amount of underlying tokens.
    /// @return The amount of wrapper tokens exchangeable.
    function underlyingToWrapper(uint256 uAmount) external view returns (uint256);

    /// @param amount The amount of wrapper tokens.
    /// @return The amount of underlying tokens exchangeable.
    function wrapperToUnderlying(uint256 amount) external view returns (uint256);
}

pragma solidity ^0.8.13;

import {IButtonswapPair} from "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {Math} from "buttonswap-periphery_buttonswap-core/libraries/Math.sol";
import {IERC20} from "../interfaces/IERC20.sol";

library ButtonswapLibrary {
    /// @notice Identical addresses provided
    error IdenticalAddresses();
    /// @notice Zero address provided
    error ZeroAddress();
    /// @notice Insufficient amount provided
    error InsufficientAmount();
    /// @notice Insufficient liquidity provided
    error InsufficientLiquidity();
    /// @notice Insufficient input amount provided
    error InsufficientInputAmount();
    /// @notice Insufficient output amount provided
    error InsufficientOutputAmount();
    /// @notice Invalid path provided
    error InvalidPath();

    /**
     * @dev Returns sorted token addresses, used to handle return values from pairs sorted in this order
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return token0 First sorted token address
     * @return token1 Second sorted token address
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) {
            revert IdenticalAddresses();
        }
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // If the tokens are different and sorted, only token0 can be the zero address
        if (token0 == address(0)) {
            revert ZeroAddress();
        }
    }

    /**
     * @dev Predicts the address that the Pair contract for given tokens would have been deployed to
     * @dev Specifically, this calculates the CREATE2 address for a Pair contract.
     * @dev It's done this way to avoid making any external calls, and thus saving on gas versus other approaches.
     * @param factory The address of the ButtonswapFactory used to create the pair
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return pair The pair address
     */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // Init Hash Code is generated by the following command:
        //        bytes32 initHashCode = keccak256(abi.encodePacked(type(ButtonswapPair).creationCode));
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"912fa011211d18178fef8f22392edc90ca8f101645ab8347e1359b5ce2f890df" // init code hash
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Fetches and sorts the pools for a pair. Pools are the current token balances in the pair contract serving as liquidity.
     * @param factory The address of the ButtonswapFactory
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return poolA Pool corresponding to tokenA
     * @return poolB Pool corresponding to tokenB
     */
    function getPools(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 poolA, uint256 poolB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 pool0, uint256 pool1,,,) = IButtonswapPair(pairFor(factory, tokenA, tokenB)).getLiquidityBalances();
        (poolA, poolB) = tokenA == token0 ? (pool0, pool1) : (pool1, pool0);
    }

    /**
     * @dev Fetches and sorts the reservoirs for a pair. Reservoirs are the current token balances in the pair contract not actively serving as liquidity.
     * @param factory The address of the ButtonswapFactory
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return reservoirA Reservoir corresponding to tokenA
     * @return reservoirB Reservoir corresponding to tokenB
     */
    function getReservoirs(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reservoirA, uint256 reservoirB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (,, uint256 reservoir0, uint256 reservoir1,) =
            IButtonswapPair(pairFor(factory, tokenA, tokenB)).getLiquidityBalances();
        (reservoirA, reservoirB) = tokenA == token0 ? (reservoir0, reservoir1) : (reservoir1, reservoir0);
    }

    /**
     * @dev Fetches and sorts the pools and reservoirs for a pair.
     *   - Pools are the current token balances in the pair contract serving as liquidity.
     *   - Reservoirs are the current token balances in the pair contract not actively serving as liquidity.
     * @param factory The address of the ButtonswapFactory
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return poolA Pool corresponding to tokenA
     * @return poolB Pool corresponding to tokenB
     * @return reservoirA Reservoir corresponding to tokenA
     * @return reservoirB Reservoir corresponding to tokenB
     */
    function getLiquidityBalances(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 poolA, uint256 poolB, uint256 reservoirA, uint256 reservoirB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 pool0, uint256 pool1, uint256 reservoir0, uint256 reservoir1,) =
            IButtonswapPair(pairFor(factory, tokenA, tokenB)).getLiquidityBalances();
        (poolA, poolB, reservoirA, reservoirB) =
            tokenA == token0 ? (pool0, pool1, reservoir0, reservoir1) : (pool1, pool0, reservoir1, reservoir0);
    }

    /**
     * @dev Given some amount of an asset and pair pools, returns an equivalent amount of the other asset
     * @param amountA The amount of token A
     * @param poolA The balance of token A in the pool
     * @param poolB The balance of token B in the pool
     * @return amountB The amount of token B
     */
    function quote(uint256 amountA, uint256 poolA, uint256 poolB) internal pure returns (uint256 amountB) {
        if (amountA == 0) {
            revert InsufficientAmount();
        }
        if (poolA == 0 || poolB == 0) {
            revert InsufficientLiquidity();
        }
        amountB = (amountA * poolB) / poolA;
    }

    /**
     * @dev Given a factory, two tokens, and a mintAmount of the first, returns how much of the much of the mintAmount will be swapped for the other token and for how much during a mintWithReservoir operation.
     * @dev The logic is a condensed version of PairMath.getSingleSidedMintLiquidityOutAmountA and PairMath.getSingleSidedMintLiquidityOutAmountB
     * @param factory The address of the ButtonswapFactory that created the pairs
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param mintAmountA The amount of tokenA to be minted
     * @return tokenAToSwap The amount of tokenA to be exchanged for tokenB from the reservoir
     * @return swappedReservoirAmountB The amount of tokenB returned from the reservoir
     */
    function getMintSwappedAmounts(address factory, address tokenA, address tokenB, uint256 mintAmountA)
        internal
        view
        returns (uint256 tokenAToSwap, uint256 swappedReservoirAmountB)
    {
        IButtonswapPair pair = IButtonswapPair(pairFor(factory, tokenA, tokenB));
        uint256 totalA = IERC20(tokenA).balanceOf(address(pair));
        uint256 totalB = IERC20(tokenB).balanceOf(address(pair));
        uint256 movingAveragePrice0 = pair.movingAveragePrice0();

        // tokenA == token0
        if (tokenA < tokenB) {
            tokenAToSwap =
                (mintAmountA * totalB) / (Math.mulDiv(movingAveragePrice0, (totalA + mintAmountA), 2 ** 112) + totalB);
            swappedReservoirAmountB = (tokenAToSwap * movingAveragePrice0) / 2 ** 112;
        } else {
            tokenAToSwap =
                (mintAmountA * totalB) / (((2 ** 112 * (totalA + mintAmountA)) / movingAveragePrice0) + totalB);
            // Inverse price so again we can use it without overflow risk
            swappedReservoirAmountB = (tokenAToSwap * (2 ** 112)) / movingAveragePrice0;
        }
    }

    /**
     * @dev Given a factory, two tokens, and a liquidity amount, returns how much of the first token will be withdrawn from the pair and how much of it came from the reservoir during a burnFromReservoir operation.
     * @dev The logic is a condensed version of PairMath.getSingleSidedBurnOutputAmountA and PairMath.getSingleSidedBurnOutputAmountB
     * @param factory The address of the ButtonswapFactory that created the pairs
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param liquidity The amount of liquidity to be burned
     * @return tokenOutA The amount of tokenA to be withdrawn from the pair
     * @return swappedReservoirAmountA The amount of tokenA returned from the reservoir
     */
    function getBurnSwappedAmounts(address factory, address tokenA, address tokenB, uint256 liquidity)
        internal
        view
        returns (uint256 tokenOutA, uint256 swappedReservoirAmountA)
    {
        IButtonswapPair pair = IButtonswapPair(pairFor(factory, tokenA, tokenB));
        uint256 totalLiquidity = pair.totalSupply();
        uint256 totalA = IERC20(tokenA).balanceOf(address(pair));
        uint256 totalB = IERC20(tokenB).balanceOf(address(pair));
        uint256 movingAveragePrice0 = pair.movingAveragePrice0();
        uint256 tokenBToSwap = (totalB * liquidity) / totalLiquidity;
        tokenOutA = (totalA * liquidity) / totalLiquidity;

        // tokenA == token0
        if (tokenA < tokenB) {
            swappedReservoirAmountA = (tokenBToSwap * (2 ** 112)) / movingAveragePrice0;
        } else {
            swappedReservoirAmountA = (tokenBToSwap * movingAveragePrice0) / 2 ** 112;
        }
        tokenOutA += swappedReservoirAmountA;
    }

    /**
     * @dev Given an input amount of an asset and pair pools, returns the maximum output amount of the other asset
     * Factors in the fee on the input amount.
     * @param amountIn The input amount of the asset
     * @param poolIn The balance of the input asset in the pool
     * @param poolOut The balance of the output asset in the pool
     * @return amountOut The output amount of the other asset
     */
    function getAmountOut(uint256 amountIn, uint256 poolIn, uint256 poolOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        if (amountIn == 0) {
            revert InsufficientInputAmount();
        }
        if (poolIn == 0 || poolOut == 0) {
            revert InsufficientLiquidity();
        }
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * poolOut;
        uint256 denominator = (poolIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @dev Given an output amount of an asset and pair pools, returns a required input amount of the other asset
     * @param amountOut The output amount of the asset
     * @param poolIn The balance of the input asset in the pool
     * @param poolOut The balance of the output asset in the pool
     * @return amountIn The required input amount of the other asset
     */
    function getAmountIn(uint256 amountOut, uint256 poolIn, uint256 poolOut) internal pure returns (uint256 amountIn) {
        if (amountOut == 0) {
            revert InsufficientOutputAmount();
        }
        if (poolIn == 0 || poolOut == 0) {
            revert InsufficientLiquidity();
        }
        uint256 numerator = poolIn * amountOut * 1000;
        uint256 denominator = (poolOut - amountOut) * 997;
        amountIn = ((numerator + denominator - 1) / denominator);
    }

    /**
     * @dev Given an ordered array of tokens and an input amount of the first asset, performs chained getAmountOut calculations to calculate the output amount of the final asset
     * @param factory The address of the ButtonswapFactory that created the pairs
     * @param amountIn The input amount of the first asset
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @return amounts The output amounts of each asset in the path
     */
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        if (path.length < 2) {
            revert InvalidPath();
        }
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 poolIn, uint256 poolOut,,) = getLiquidityBalances(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], poolIn, poolOut);
        }
    }

    /**
     * @dev Given an ordered array of tokens and an output amount of the final asset, performs chained getAmountIn calculations to calculate the input amount of the first asset
     * @param factory The address of the ButtonswapFactory that created the pairs
     * @param amountOut The output amount of the final asset
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @return amounts The input amounts of each asset in the path
     */
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        if (path.length < 2) {
            revert InvalidPath();
        }
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 poolIn, uint256 poolOut,,) = getLiquidityBalances(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], poolIn, poolOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// ToDo: Replace with solmate/SafeTransferLib
pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

library ButtonswapOperations {
    enum Swap {
        SWAP,
        WRAP_BUTTON,
        UNWRAP_BUTTON,
        WRAP_WETH,
        UNWRAP_WETH,
        USDM_SWAP
    }

    enum Liquidity {
        DUAL,
        SINGLE
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// a library for performing various math operations

library Math {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUSDM {
    function convertToShares(uint256 amount) external view returns (uint256);

    function convertToTokens(uint256 shares) external view returns (uint256);

    function sharesOf(address account) external view returns (uint256);

    function mint(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapFactoryErrors {
    /**
     * @notice The given token addresses are the same
     */
    error TokenIdenticalAddress();

    /**
     * @notice The given token address is the zero address
     */
    error TokenZeroAddress();

    /**
     * @notice The given tokens already have a {ButtonswapPair} instance
     */
    error PairExists();

    /**
     * @notice User does not have permission for the attempted operation
     */
    error Forbidden();

    /**
     * @notice There was an attempt to update a parameter to an invalid value
     */
    error InvalidParameter();
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapFactoryEvents {
    /**
     * @notice Emitted when a new Pair is created.
     * @param token0 The first sorted token
     * @param token1 The second sorted token
     * @param pair The address of the new {ButtonswapPair} contract
     * @param count The new total number of Pairs created
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 count);

    /**
     * @notice Emitted when the default parameters for a new pair have been updated.
     * @param paramSetter The address that changed the parameters
     * @param newDefaultMovingAverageWindow The new movingAverageWindow default value
     * @param newDefaultMaxVolatilityBps The new maxVolatilityBps default value
     * @param newDefaultMinTimelockDuration The new minTimelockDuration default value
     * @param newDefaultMaxTimelockDuration The new maxTimelockDuration default value
     * @param newDefaultMaxSwappableReservoirLimitBps The new maxSwappableReservoirLimitBps default value
     * @param newDefaultSwappableReservoirGrowthWindow The new swappableReservoirGrowthWindow default value
     */
    event DefaultParametersUpdated(
        address indexed paramSetter,
        uint32 newDefaultMovingAverageWindow,
        uint16 newDefaultMaxVolatilityBps,
        uint32 newDefaultMinTimelockDuration,
        uint32 newDefaultMaxTimelockDuration,
        uint16 newDefaultMaxSwappableReservoirLimitBps,
        uint32 newDefaultSwappableReservoirGrowthWindow
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapERC20Errors} from "../IButtonswapERC20/IButtonswapERC20Errors.sol";

interface IButtonswapPairErrors is IButtonswapERC20Errors {
    /**
     * @notice Re-entrancy guard prevented method call
     */
    error Locked();

    /**
     * @notice User does not have permission for the attempted operation
     */
    error Forbidden();

    /**
     * @notice Integer maximums exceeded
     */
    error Overflow();

    /**
     * @notice Initial deposit not yet made
     */
    error Uninitialized();

    /**
     * @notice There was not enough liquidity in the reservoir
     */
    error InsufficientReservoir();

    /**
     * @notice Not enough liquidity was created during mint
     */
    error InsufficientLiquidityMinted();

    /**
     * @notice Not enough funds added to mint new liquidity
     */
    error InsufficientLiquidityAdded();

    /**
     * @notice More liquidity must be burned to be redeemed for non-zero amounts
     */
    error InsufficientLiquidityBurned();

    /**
     * @notice Swap was attempted with zero input
     */
    error InsufficientInputAmount();

    /**
     * @notice Swap was attempted with zero output
     */
    error InsufficientOutputAmount();

    /**
     * @notice Pool doesn't have the liquidity to service the swap
     */
    error InsufficientLiquidity();

    /**
     * @notice The specified "to" address is invalid
     */
    error InvalidRecipient();

    /**
     * @notice The product of pool balances must not change during a swap (save for accounting for fees)
     */
    error KInvariant();

    /**
     * @notice The new price ratio after a swap is invalid (one or more of the price terms are zero)
     */
    error InvalidFinalPrice();

    /**
     * @notice Single sided operations are not executable at this point in time
     */
    error SingleSidedTimelock();

    /**
     * @notice The attempted operation would have swapped reservoir tokens above the current limit
     */
    error SwappableReservoirExceeded();

    /**
     * @notice All operations on the pair other than dual-sided burning are currently paused
     */
    error Paused();
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapERC20Events} from "../IButtonswapERC20/IButtonswapERC20Events.sol";

interface IButtonswapPairEvents is IButtonswapERC20Events {
    /**
     * @notice Emitted when a {IButtonswapPair-mint} is performed.
     * Some `token0` and `token1` are deposited in exchange for liquidity tokens representing a claim on them.
     * @param from The account that supplied the tokens for the mint
     * @param amount0 The amount of `token0` that was deposited
     * @param amount1 The amount of `token1` that was deposited
     * @param amountOut The amount of liquidity tokens that were minted
     * @param to The account that received the tokens from the mint
     */
    event Mint(address indexed from, uint256 amount0, uint256 amount1, uint256 amountOut, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-burn} is performed.
     * Liquidity tokens are redeemed for underlying `token0` and `token1`.
     * @param from The account that supplied the tokens for the burn
     * @param amountIn The amount of liquidity tokens that were burned
     * @param amount0 The amount of `token0` that was received
     * @param amount1 The amount of `token1` that was received
     * @param to The account that received the tokens from the burn
     */
    event Burn(address indexed from, uint256 amountIn, uint256 amount0, uint256 amount1, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-swap} is performed.
     * @param from The account that supplied the tokens for the swap
     * @param amount0In The amount of `token0` that went into the swap
     * @param amount1In The amount of `token1` that went into the swap
     * @param amount0Out The amount of `token0` that came out of the swap
     * @param amount1Out The amount of `token1` that came out of the swap
     * @param to The account that received the tokens from the swap
     */
    event Swap(
        address indexed from,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /**
     * @notice Emitted when the movingAverageWindow parameter for the pair has been updated.
     * @param newMovingAverageWindow The new movingAverageWindow value
     */
    event MovingAverageWindowUpdated(uint32 newMovingAverageWindow);

    /**
     * @notice Emitted when the maxVolatilityBps parameter for the pair has been updated.
     * @param newMaxVolatilityBps The new maxVolatilityBps value
     */
    event MaxVolatilityBpsUpdated(uint16 newMaxVolatilityBps);

    /**
     * @notice Emitted when the minTimelockDuration parameter for the pair has been updated.
     * @param newMinTimelockDuration The new minTimelockDuration value
     */
    event MinTimelockDurationUpdated(uint32 newMinTimelockDuration);

    /**
     * @notice Emitted when the maxTimelockDuration parameter for the pair has been updated.
     * @param newMaxTimelockDuration The new maxTimelockDuration value
     */
    event MaxTimelockDurationUpdated(uint32 newMaxTimelockDuration);

    /**
     * @notice Emitted when the maxSwappableReservoirLimitBps parameter for the pair has been updated.
     * @param newMaxSwappableReservoirLimitBps The new maxSwappableReservoirLimitBps value
     */
    event MaxSwappableReservoirLimitBpsUpdated(uint16 newMaxSwappableReservoirLimitBps);

    /**
     * @notice Emitted when the swappableReservoirGrowthWindow parameter for the pair has been updated.
     * @param newSwappableReservoirGrowthWindow The new swappableReservoirGrowthWindow value
     */
    event SwappableReservoirGrowthWindowUpdated(uint32 newSwappableReservoirGrowthWindow);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

import {IButtonswapERC20Errors} from "./IButtonswapERC20Errors.sol";
import {IButtonswapERC20Events} from "./IButtonswapERC20Events.sol";

interface IButtonswapERC20 is IButtonswapERC20Errors, IButtonswapERC20Events {
    /**
     * @notice Returns the name of the token.
     * @return _name The token name
     */
    function name() external view returns (string memory _name);

    /**
     * @notice Returns the symbol of the token, usually a shorter version of the name.
     * @return _symbol The token symbol
     */
    function symbol() external view returns (string memory _symbol);

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * @dev This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the contract.
     * @return decimals The number of decimals
     */
    function decimals() external pure returns (uint8 decimals);

    /**
     * @notice Returns the amount of tokens in existence.
     * @return totalSupply The amount of tokens in existence
     */
    function totalSupply() external view returns (uint256 totalSupply);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param owner The account the balance is being checked for
     * @return balance The amount of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}.
     * This is zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @return allowance The amount of tokens owned by `owner` that the `spender` can transfer
     */
    function allowance(address owner, address spender) external view returns (uint256 allowance);

    /**
     * @notice Sets `value` as the allowance of `spender` over the caller's tokens.
     * @dev IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     * @param spender The account that is granted permission to spend the tokens
     * @param value The amount of tokens that can be spent
     * @return success Whether the operation succeeded
     */
    function approve(address spender, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from the caller's account to `to`.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transfer(address to, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from `from` to `to` using the allowance mechanism.
     * `value` is then deducted from the caller's allowance.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param from The account that is sending the tokens
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return DOMAIN_SEPARATOR The `DOMAIN_SEPARATOR` value
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 DOMAIN_SEPARATOR);

    /**
     * @notice Returns the typehash used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return PERMIT_TYPEHASH The `PERMIT_TYPEHASH` value
     */
    function PERMIT_TYPEHASH() external pure returns (bytes32 PERMIT_TYPEHASH);

    /**
     * @notice Returns the current nonce for `owner`.
     * This value must be included whenever a signature is generated for {permit}.
     * @dev Every successful call to {permit} increases `owner`'s nonce by one.
     * This prevents a signature from being used multiple times.
     * @param owner The account to get the nonce for
     * @return nonce The current nonce for the given `owner`
     */
    function nonces(address owner) external view returns (uint256 nonce);

    /**
     * @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s signed approval.
     * @dev IMPORTANT: The same issues {approve} has related to transaction ordering also apply here.
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the [relevant EIP section](https://eips.ethereum.org/EIPS/eip-2612#specification).
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @param value The amount of `owner`'s tokens that `spender` can transfer
     * @param deadline The future time after which the permit is no longer valid
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IGenericButtonswapRouterErrors {
    // **** WETH Errors **** //
    /**
     * @dev Thrown when ETH is sent by address other than WETH contract
     * @param sender The sender of the ETH
     */
    error NonWETHSender(address sender);
    /// @notice WETH transfer failed
    //    error FailedWETHTransfer();
    /**
     * @notice Thrown when a different token address is provided where WETH address is expected
     * @param weth The address of WETH
     * @param token The address of the token
     */
    error NonWethToken(address weth, address token);
    /**
     * @notice Thrown when input is a token instead of should be ETH (0x address)
     * @param token The address of the token
     */
    error NonEthToken(address token);

    // **** Button Errors **** //
    /**
     * @notice Thrown when the underlying token doesn't match that of the buttonToken
     * @param underlyingToken The address of the underlying token
     * @param buttonToken The address of the buttonToken
     */
    error IncorrectButtonPairing(address underlyingToken, address buttonToken);

    // **** IERC20 Errors **** //
    /**
     * @notice Thrown when the amountIn doesn't match the router's current balance of IERC20 token
     * @param token The address of the token
     * @param balance The balance of the token
     */
    error IncorrectBalance(address token, uint256 balance, uint256 amountIn);

    // **** Swap Errors **** //
    /**
     * @notice Thrown when the calculated input amount exceeds the specified maximum
     * @param amountInMax The maximum amount of input token
     * @param amount The amount of input token
     */
    error ExcessiveInputAmount(uint256 amountInMax, uint256 amount);
    /**
     * @notice Thrown when insufficient tokens are returned in an operation
     * @param amountOutMin The minimum amount of output token
     * @param amount The amount of output token
     */
    error InsufficientOutputAmount(uint256 amountOutMin, uint256 amount);
    /**
     * @notice Thrown when the deadline is exceeded
     * @param deadline The deadline
     * @param timestamp The current timestamp
     */
    error Expired(uint256 deadline, uint256 timestamp);

    // **** AddLiquidity Errors **** //
    /**
     * @notice movingAveragePrice0 is out of specified bounds
     * @param pool0 The amount in pool0
     * @param pool1 The amount in pool1
     * @param movingAveragePrice0 The current movingAveragePrice0 of the pair
     * @param movingAveragePrice0ThresholdBps The threshold of deviation of movingAveragePrice0 from the pool price
     */
    error MovingAveragePriceOutOfBounds(
        uint256 pool0, uint256 pool1, uint256 movingAveragePrice0, uint256 movingAveragePrice0ThresholdBps
    );

    // **** AddLiquidity/RemoveLiquidity Errors **** //
    /**
     * @notice Insufficient amount of token available
     * @param token The address of token
     * @param amount The amount of token available
     * @param requiredAmount The amount of token required
     */
    error InsufficientTokenAmount(address token, uint256 amount, uint256 requiredAmount);

    /**
     * @notice Pair does not exist
     * @param tokenA The address of tokenA
     * @param tokenB The address of tokenB
     */
    error PairDoesNotExist(address tokenA, address tokenB);

    /**
     * @notice Pair already exists
     * @param tokenA The address of tokenA
     * @param tokenB The address of tokenB
     * @param pair The address of the pair
     */
    error PairAlreadyExists(address tokenA, address tokenB, address pair);

    /**
     * @notice Pair has not yet been initialized
     */
    error NotInitialized(address pair);

    /**
     * @notice Neither token in the pair has a non-empty reservoir
     */
    error NoReservoir(address pair);

    /**
     * @notice Insufficient liquidity output from mint
     * @param liquidity The amount of liquidity
     * @param minLiquidity The minimum amount of liquidity
     */
    error InsufficientOutputLiquidity(uint256 liquidity, uint256 minLiquidity);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // Borrowed implementation from solmate
    // https://github.com/transmissions11/solmate/blob/2001af43aedb46fdc2335d2a7714fb2dae7cfcd1/src/utils/FixedPointMathLib.sol#L164
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
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

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
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
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapERC20Errors {
    /**
     * @notice Permit deadline was exceeded
     */
    error PermitExpired();

    /**
     * @notice Permit signature invalid
     */
    error PermitInvalidSignature();
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

interface IButtonswapERC20Events {
    /**
     * @notice Emitted when the allowance of a `spender` for an `owner` is set by a call to {IButtonswapERC20-approve}.
     * `value` is the new allowance.
     * @param owner The account that has granted approval
     * @param spender The account that has been given approval
     * @param value The amount the spender can transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     * @param from The account that sent the tokens
     * @param to The account that received the tokens
     * @param value The amount of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
}