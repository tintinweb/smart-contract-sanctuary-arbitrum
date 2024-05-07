// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

import { IPoolQuery, SpecifiedToken } from "../../interfaces/IPoolQuery.sol";
import "../PendleYTAdapter.sol";
import "../../interfaces/IQuoter.sol";

contract PendleYTQuery is IPoolQuery {
    PendleYTAdapter public immutable adapter;
    IPendleStaticRouter public immutable staticRouter;

    uint256 public immutable xToken;
    uint256 public immutable yToken;

    mapping(uint256 => uint8) public decimals;

    uint8 public constant NORMALIZED_DECIMALS = 18;

    constructor(address adapter_, IPendleStaticRouter staticRouter_) {
        adapter = PendleYTAdapter(adapter_);
        staticRouter = staticRouter_;

        xToken = adapter.xToken();
        yToken = adapter.yToken();

        decimals[xToken] = adapter.decimals(xToken);
        decimals[yToken] = adapter.decimals(yToken);
    }

    function swapGivenInputAmount(uint256 inputToken, uint256 inputAmount) public view returns (uint256 outputAmount) {
        uint256 rawInputAmount = _convertDecimals(NORMALIZED_DECIMALS, decimals[inputToken], inputAmount);

        bool isX = inputToken == xToken;
        uint256 outputToken = isX ? yToken : xToken;

        uint256 rawAmount;
        if (isX) {
            (rawAmount,,,,) = staticRouter.swapExactTokenForYtStatic(adapter.primitive(), adapter.underlying(xToken), rawInputAmount);
        } else {
            (rawAmount,,,,,,,) = staticRouter.swapExactYtForTokenStatic(adapter.primitive(), rawInputAmount, adapter.underlying(xToken));
        }

        outputAmount = _convertDecimals(decimals[outputToken], NORMALIZED_DECIMALS, rawAmount);
    }

    function swapGivenInputAmount(uint256 xBalance, uint256 yBalance, uint256 inputAmount, SpecifiedToken inputToken) public view returns (uint256 outputAmount) {
        bool isX = inputToken == SpecifiedToken.X;

        outputAmount = swapGivenInputAmount(isX ? xToken : yToken, inputAmount);
    }

    function depositGivenInputAmount(uint256 depositToken, uint256 depositAmount) external view override returns (uint256) { }

    function withdrawGivenInputAmount(uint256 withdrawnToken, uint256 burnAmount) external view override returns (uint256) { }

    /**
     * @dev convert a uint256 from one fixed point decimal basis to another,
     *   returning the truncated amount if a truncation occurs.
     * @dev fn(from, to, a) => b
     * @dev a = (x * 10**from) => b = (x * 10**to), where x is constant.
     * @param amountToConvert the amount being converted
     * @param decimalsFrom the fixed decimal basis of amountToConvert
     * @param decimalsTo the fixed decimal basis of the returned convertedAmount
     * @return convertedAmount the amount after conversion
     */
    function _convertDecimals(uint8 decimalsFrom, uint8 decimalsTo, uint256 amountToConvert) internal pure returns (uint256 convertedAmount) {
        if (decimalsFrom == decimalsTo) {
            // no shift
            convertedAmount = amountToConvert;
        } else if (decimalsFrom < decimalsTo) {
            // Decimal shift left (add precision)
            uint256 shift = 10 ** (uint256(decimalsTo - decimalsFrom));
            convertedAmount = amountToConvert * shift;
        } else {
            // Decimal shift right (remove precision) -> truncation
            uint256 shift = 10 ** (uint256(decimalsFrom - decimalsTo));
            convertedAmount = amountToConvert / shift;
        }
    }
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

enum SpecifiedToken {
    X,
    Y
}

interface IPoolQuery {
    function swapGivenInputAmount(uint256 inputToken, uint256 inputAmount) external view returns (uint256);
    function depositGivenInputAmount(uint256 depositToken, uint256 depositAmount) external view returns (uint256);
    function withdrawGivenInputAmount(uint256 withdrawnToken, uint256 burnAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IPendle.sol";
import "./OceanAdapter.sol";

enum ComputeType {
    Swap
}

/**
 * @notice
 *   curve2pool adapter contract enabling swapping, adding liquidity & removing liquidity for the curve usdc-usdt pool
 */
contract PendleYTAdapter is OceanAdapter {
    /////////////////////////////////////////////////////////////////////
    //                             Errors                              //
    /////////////////////////////////////////////////////////////////////
    error INVALID_COMPUTE_TYPE();
    error SLIPPAGE_LIMIT_EXCEEDED();

    /////////////////////////////////////////////////////////////////////
    //                             Events                              //
    /////////////////////////////////////////////////////////////////////
    event Swap(uint256 indexed inputToken, uint256 indexed inputAmount, uint256 indexed outputAmount, bytes32 slippageProtection, address user, bool computeOutput);
    event Deposit(uint256 indexed inputToken, uint256 indexed inputAmount, uint256 indexed outputAmount, bytes32 slippageProtection, address user, bool computeOutput);
    event Withdraw(uint256 indexed outputToken, uint256 indexed inputAmount, uint256 indexed outputAmount, bytes32 slippageProtection, address user, bool computeOutput);

    uint256 constant MAX_APPROVAL_AMOUNT = type(uint256).max;

    /// @notice x token Ocean ID.
    uint256 public immutable xToken;

    /// @notice y token Ocean ID.
    uint256 public immutable yToken;

    IPendleRouter public immutable router;

    //*********************************************************************//
    // ---------------------------- constructor -------------------------- //
    //*********************************************************************//

    /**
     * @notice only initializing the immutables, mappings & approves tokens
     */
    constructor(address ocean_, address primitive_, address baseToken_, IPendleRouter router_) OceanAdapter(ocean_, primitive_) {
        router = router_;

        xToken = _calculateOceanId(baseToken_, 0);
        underlying[xToken] = baseToken_;
        decimals[xToken] = IERC20Metadata(baseToken_).decimals();
        _approveToken(baseToken_);

        (,, IPYieldToken _YT) = IPendleMarket(primitive_).readTokens();
        yToken = _calculateOceanId(address(_YT), 0);
        underlying[yToken] = address(_YT);
        decimals[yToken] = IERC20Metadata(address(_YT)).decimals();
        _approveToken(address(_YT));
    }

    /**
     * @dev wraps the underlying token into the Ocean
     * @param tokenId Ocean ID of token to wrap
     * @param amount wrap amount
     */
    function wrapToken(uint256 tokenId, uint256 amount, bytes32 metadata) internal override {
        address tokenAddress = underlying[tokenId];

        Interaction memory interaction = Interaction({ interactionTypeAndAddress: _fetchInteractionId(tokenAddress, uint256(InteractionType.WrapErc20)), inputToken: 0, outputToken: 0, specifiedAmount: amount, metadata: bytes32(0) });

        IOceanInteractions(ocean).doInteraction(interaction);
    }

    /**
     * @dev unwraps the underlying token from the Ocean
     * @param tokenId Ocean ID of token to unwrap
     * @param amount unwrap amount
     */
    function unwrapToken(uint256 tokenId, uint256 amount, bytes32 metadata) internal override returns (uint256 unwrappedAmount) {
        address tokenAddress = underlying[tokenId];

        Interaction memory interaction = Interaction({ interactionTypeAndAddress: _fetchInteractionId(tokenAddress, uint256(InteractionType.UnwrapErc20)), inputToken: 0, outputToken: 0, specifiedAmount: amount, metadata: bytes32(0) });

        IOceanInteractions(ocean).doInteraction(interaction);

        // handle the unwrap fee scenario
        uint256 unwrapFee = amount / IOceanInteractions(ocean).unwrapFeeDivisor();
        (, uint256 truncated) = _convertDecimals(NORMALIZED_DECIMALS, decimals[tokenId], amount - unwrapFee);
        unwrapFee = unwrapFee + truncated;

        unwrappedAmount = amount - unwrapFee;
    }

    /**
     * @dev swaps/add liquidity/remove liquidity from Curve 2pool
     * @param inputToken The user is giving this token to the pool
     * @param outputToken The pool is giving this token to the user
     * @param inputAmount The amount of the inputToken the user is giving to the pool
     * @param minimumOutputAmount The minimum amount of tokens expected back after the exchange
     */
    function primitiveOutputAmount(uint256 inputToken, uint256 outputToken, uint256 inputAmount, bytes32 minimumOutputAmount) internal override returns (uint256 outputAmount) {
        (uint256 rawInputAmount,) = _convertDecimals(NORMALIZED_DECIMALS, decimals[inputToken], inputAmount);

        ComputeType action = _determineComputeType(inputToken, outputToken);

        uint256 rawOutputAmount;

        address underlyingInput = underlying[inputToken];
        address underlyingOutput = underlying[outputToken];

        if (inputToken == xToken) {
            IPendleRouter.TokenInput memory tokenInput;
            tokenInput.tokenIn = underlyingInput;
            tokenInput.netTokenIn = rawInputAmount;
            tokenInput.tokenMintSy = underlyingInput;

            IPendleRouter.ApproxParams memory approxParams;
            approxParams.guessMax = type(uint256).max;
            approxParams.maxIteration = 256;
            approxParams.eps = 1e14;

            IPendleRouter.LimitOrderData memory limitOrderData;

            (rawOutputAmount,,) = router.swapExactTokenForYt(address(this), primitive, 0, approxParams, tokenInput, limitOrderData);
        } else {
            IPendleRouter.TokenOutput memory tokenOutput;
            tokenOutput.tokenOut = underlyingOutput;
            tokenOutput.minTokenOut = 0;
            tokenOutput.tokenRedeemSy = underlyingOutput;

            IPendleRouter.LimitOrderData memory limitOrderData;

            (rawOutputAmount,,) = router.swapExactYtForToken(address(this), primitive, rawInputAmount, tokenOutput, limitOrderData);
        }

        (outputAmount,) = _convertDecimals(decimals[outputToken], NORMALIZED_DECIMALS, rawOutputAmount);

        if (uint256(minimumOutputAmount) > outputAmount) revert SLIPPAGE_LIMIT_EXCEEDED();

        emit Swap(inputToken, inputAmount, outputAmount, minimumOutputAmount, primitive, true);
    }

    /**
     * @dev Approves token to be spent by the Ocean and the Curve pool
     */
    function _approveToken(address tokenAddress) private {
        IERC20Metadata(tokenAddress).approve(ocean, MAX_APPROVAL_AMOUNT);
        IERC20Metadata(tokenAddress).approve(address(router), MAX_APPROVAL_AMOUNT);
    }

    /**
     * @dev Uses the inputToken and outputToken to determine the ComputeType
     *  (input: xToken, output: yToken) | (input: yToken, output: xToken) => SWAP
     *  base := xToken | yToken
     *  (input: base, output: lpToken) => DEPOSIT
     *  (input: lpToken, output: base) => WITHDRAW
     */
    function _determineComputeType(uint256 inputToken, uint256 outputToken) private view returns (ComputeType computeType) {
        if (((inputToken == xToken) && (outputToken == yToken)) || ((inputToken == yToken) && (outputToken == xToken))) {
            return ComputeType.Swap;
        } else {
            revert INVALID_COMPUTE_TYPE();
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of number of initialized ticks loaded
    function quoteExactInput(bytes memory path, uint256 amountIn) external view returns (uint256 amountOut, uint160[] memory sqrtPriceX96AfterList, uint32[] memory initializedTicksCrossedList, uint256 gasEstimate);

    struct QuoteExactInputSingleWithPoolParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        address pool;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `quoteExactInputSingleWithPool`
    /// tokenIn The token being swapped in
    /// amountIn The desired input amount
    /// tokenOut The token being swapped out
    /// fee The fee of the pool to consider for the pair
    /// pool The address of the pool to consider for the pair
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks loaded
    function quoteExactInputSingleWithPool(QuoteExactInputSingleWithPoolParams memory params) external view returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// amountIn The desired input amount
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks loaded
    function quoteExactInputSingle(QuoteExactInputSingleParams memory params) external view returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);

    struct QuoteExactOutputSingleWithPoolParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        address pool;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleWithPoolParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// amount The desired output amount
    /// fee The fee of the token pool to consider for the pair
    /// pool The address of the pool to consider for the pair
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks loaded
    function quoteExactOutputSingleWithPool(QuoteExactOutputSingleWithPoolParams memory params) external view returns (uint256 amountIn, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// amountOut The desired output amount
    /// fee The fee of the token pool to consider for the pair
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks loaded
    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params) external view returns (uint256 amountIn, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    function quoteExactOutput(bytes memory path, uint256 amountOut) external view returns (uint256 amountIn, uint160[] memory sqrtPriceX96AfterList, uint32[] memory initializedTicksCrossedList, uint256 gasEstimate);
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
// Cowri Labs Inc.

pragma solidity ^0.8.19;

interface IPendleRouter {
    struct ApproxParams {
        uint256 guessMin;
        uint256 guessMax;
        uint256 guessOffchain;
        uint256 maxIteration;
        uint256 eps;
    }

    struct SwapData {
        SwapType swapType;
        address extRouter;
        bytes extCalldata;
        bool needScale;
    }

    enum SwapType {
        NONE,
        KYBERSWAP,
        ONE_INCH,
        // ETH_WETH not used in Aggregator
        ETH_WETH
    }

    struct TokenInput {
        // TOKEN DATA
        address tokenIn;
        uint256 netTokenIn;
        address tokenMintSy;
        // AGGREGATOR DATA
        address pendleSwap;
        SwapData swapData;
    }

    struct TokenOutput {
        // TOKEN DATA
        address tokenOut;
        uint256 minTokenOut;
        address tokenRedeemSy;
        // AGGREGATOR DATA
        address pendleSwap;
        SwapData swapData;
    }

    enum OrderType {
        SY_FOR_PT,
        PT_FOR_SY,
        SY_FOR_YT,
        YT_FOR_SY
    }

    struct Order {
        uint256 salt;
        uint256 expiry;
        uint256 nonce;
        OrderType orderType;
        address token;
        address YT;
        address maker;
        address receiver;
        uint256 makingAmount;
        uint256 lnImpliedRate;
        uint256 failSafeRate;
        bytes permit;
    }

    struct FillOrderParams {
        Order order;
        bytes signature;
        uint256 makingAmount;
    }

    struct LimitOrderData {
        address limitRouter;
        uint256 epsSkipMarket;
        FillOrderParams[] normalFills;
        FillOrderParams[] flashFills;
        bytes optData;
    }

    function swapExactYtForToken(address receiver, address market, uint256 exactYtIn, TokenOutput calldata output, LimitOrderData calldata limit) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactTokenForYt(
        address receiver,
        address market,
        uint256 minYtOut,
        ApproxParams calldata guessYtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    )
        external
        payable
        returns (uint256 netYtOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactTokenForPt(
        address receiver,
        address market,
        uint256 minPtOut,
        ApproxParams calldata guessPtOut,
        TokenInput calldata input,
        LimitOrderData calldata limit
    )
        external
        payable
        returns (uint256 netPtOut, uint256 netSyFee, uint256 netSyInterm);

    function swapExactPtForToken(address receiver, address market, uint256 exactPtIn, TokenOutput calldata output, LimitOrderData calldata limit) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);
}

interface IStandardizedYield { }

interface IPPrincipalToken { }

interface IPYieldToken { }

interface IPendleMarket {
    function readTokens() external view returns (IStandardizedYield _SY, IPPrincipalToken _PT, IPYieldToken _YT);

    function getRewardTokens() external view returns (address[] memory);
}

interface IPendleStaticRouter {
    function addLiquidityDualSyAndPtStatic(address market, uint256 netSyDesired, uint256 netPtDesired) external view returns (uint256 netLpOut, uint256 netSyUsed, uint256 netPtUsed);

    function addLiquidityDualTokenAndPtStatic(
        address market,
        address tokenIn,
        uint256 netTokenDesired,
        uint256 netPtDesired
    )
        external
        view
        returns (uint256 netLpOut, uint256 netTokenUsed, uint256 netPtUsed, uint256 netSyUsed, uint256 netSyDesired);

    function addLiquiditySinglePtStatic(address market, uint256 netPtIn) external view returns (uint256 netLpOut, uint256 netPtToSwap, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter, uint256 netSyFromSwap);

    function addLiquiditySingleSyKeepYtStatic(address market, uint256 netSyIn) external view returns (uint256 netLpOut, uint256 netYtOut, uint256 netSyToPY);

    function addLiquiditySingleSyStatic(address market, uint256 netSyIn) external view returns (uint256 netLpOut, uint256 netPtFromSwap, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter, uint256 netSyToSwap);

    function addLiquiditySingleTokenKeepYtStatic(address market, address tokenIn, uint256 netTokenIn) external view returns (uint256 netLpOut, uint256 netYtOut, uint256 netSyMinted, uint256 netSyToPY);

    function addLiquiditySingleTokenStatic(
        address market,
        address tokenIn,
        uint256 netTokenIn
    )
        external
        view
        returns (uint256 netLpOut, uint256 netPtFromSwap, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter, uint256 netSyMinted, uint256 netSyToSwap);

    function removeLiquidityDualSyAndPtStatic(address market, uint256 netLpToRemove) external view returns (uint256 netSyOut, uint256 netPtOut);

    function removeLiquidityDualTokenAndPtStatic(address market, uint256 netLpToRemove, address tokenOut) external view returns (uint256 netTokenOut, uint256 netPtOut, uint256 netSyToRedeem);

    function removeLiquiditySinglePtStatic(
        address market,
        uint256 netLpToRemove
    )
        external
        view
        returns (uint256 netPtOut, uint256 netPtFromSwap, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter, uint256 netSyFromBurn, uint256 netPtFromBurn);

    function removeLiquiditySingleSyStatic(
        address market,
        uint256 netLpToRemove
    )
        external
        view
        returns (uint256 netSyOut, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter, uint256 netSyFromBurn, uint256 netPtFromBurn, uint256 netSyFromSwap);

    function removeLiquiditySingleTokenStatic(
        address market,
        uint256 netLpToRemove,
        address tokenOut
    )
        external
        view
        returns (uint256 netTokenOut, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter, uint256 netSyOut, uint256 netSyFromBurn, uint256 netPtFromBurn, uint256 netSyFromSwap);

    function swapExactPtForSyStatic(address market, uint256 exactPtIn) external view returns (uint256 netSyOut, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapExactPtForTokenStatic(address market, uint256 exactPtIn, address tokenOut) external view returns (uint256 netTokenOut, uint256 netSyToRedeem, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapExactPtForYtStatic(address market, uint256 exactPtIn) external view returns (uint256 netYtOut, uint256 totalPtToSwap, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapExactSyForPtStatic(address market, uint256 exactSyIn) external view returns (uint256 netPtOut, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapExactSyForYtStatic(address market, uint256 exactSyIn) external view returns (uint256 netYtOut, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapExactTokenForPtStatic(address market, address tokenIn, uint256 amountTokenIn) external view returns (uint256 netPtOut, uint256 netSyMinted, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapExactTokenForYtStatic(address market, address tokenIn, uint256 amountTokenIn) external view returns (uint256 netYtOut, uint256 netSyMinted, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapExactYtForPtStatic(address market, uint256 exactYtIn) external view returns (uint256 netPtOut, uint256 totalPtSwapped, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapExactYtForSyStatic(
        address market,
        uint256 exactYtIn
    )
        external
        view
        returns (uint256 netSyOut, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter, uint256 netSyOwedInt, uint256 netPYToRepaySyOwedInt, uint256 netPYToRedeemSyOutInt);

    function swapExactYtForTokenStatic(
        address market,
        uint256 exactYtIn,
        address tokenOut
    )
        external
        view
        returns (uint256 netTokenOut, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter, uint256 netSyOut, uint256 netSyOwedInt, uint256 netPYToRepaySyOwedInt, uint256 netPYToRedeemSyOutInt);

    function swapPtForExactSyStatic(address market, uint256 exactSyOut) external view returns (uint256 netPtIn, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapSyForExactPtStatic(address market, uint256 exactPtOut) external view returns (uint256 netSyIn, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);

    function swapSyForExactYtStatic(address market, uint256 exactYtOut) external view returns (uint256 netSyIn, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter, uint256 netSyReceivedInt, uint256 totalSyNeedInt);

    function swapYtForExactSyStatic(address market, uint256 exactSyOut) external view returns (uint256 netYtIn, uint256 netSyFee, uint256 priceImpact, uint256 exchangeRateAfter);
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOceanPrimitive.sol";
import "../interfaces/Interactions.sol";

/**
 * @notice
 *   Helper contract for shell adapters
 */
abstract contract OceanAdapter is IOceanPrimitive {
    /// @notice normalized decimals to be compatible with the Ocean.
    uint8 constant NORMALIZED_DECIMALS = 18;

    /// @notice Ocean address.
    address public immutable ocean;

    /// @notice external primitive address.
    address public immutable primitive;

    /// @notice The underlying token address corresponding to the Ocean ID.
    mapping(uint256 => address) public underlying;

    /// @notice The underlying token decimals wrt to the Ocean ID
    mapping(uint256 => uint8) public decimals;

    //*********************************************************************//
    // ---------------------------- constructor -------------------------- //
    //*********************************************************************//

    /// @notice only initializing the immutables
    constructor(address ocean_, address primitive_) {
        ocean = ocean_;
        primitive = primitive_;
    }

    /// @notice only allow the Ocean to call a method
    modifier onlyOcean() {
        require(msg.sender == ocean);
        _;
    }

    /**
     * @dev The Ocean must always know the input and output tokens in order to
     *  do the accounting.  One of the token amounts is chosen by the user, and
     *  the other amount is chosen by the primitive.  When computeOutputAmount is
     *  called, the user provides the inputAmount, and the primitive uses this to
     *  compute the outputAmount
     * @param inputToken The user is giving this token to the primitive
     * @param outputToken The primitive is giving this token to the user
     * @param inputAmount The amount of the inputToken the user is giving to the primitive
     * @param metadata a bytes32 value that the user provides the Ocean
     * @dev the unused param is an address field called userAddress
     */
    function computeOutputAmount(uint256 inputToken, uint256 outputToken, uint256 inputAmount, address, bytes32 metadata) external override onlyOcean returns (uint256 outputAmount) {
        uint256 unwrappedAmount = unwrapToken(inputToken, inputAmount, metadata);

        outputAmount = primitiveOutputAmount(inputToken, outputToken, unwrappedAmount, metadata);

        wrapToken(outputToken, outputAmount, metadata);
    }

    /**
     * @notice Not implemented for this primitive
     */
    function computeInputAmount(uint256 inputToken, uint256 outputToken, uint256 outputAmount, address userAddress, bytes32 maximumInputAmount) external override onlyOcean returns (uint256 inputAmount) {
        revert();
    }

    /**
     * @notice used to fetch the Ocean interaction ID
     */
    function _fetchInteractionId(address token, uint256 interactionType) internal pure returns (bytes32) {
        uint256 packedValue = uint256(uint160(token));
        packedValue |= interactionType << 248;
        return bytes32(abi.encode(packedValue));
    }

    /**
     * @notice calculates Ocean ID for a underlying token
     */
    function _calculateOceanId(address tokenAddress, uint256 tokenId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tokenAddress, tokenId)));
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @notice returning 0 here since this primitive should not have any tokens
     */
    function getTokenSupply(uint256 tokenId) external view virtual override returns (uint256) {
        return 0;
    }

    /**
     * @dev convert a uint256 from one fixed point decimal basis to another,
     *   returning the truncated amount if a truncation occurs.
     * @dev fn(from, to, a) => b
     * @dev a = (x * 10**from) => b = (x * 10**to), where x is constant.
     * @param amountToConvert the amount being converted
     * @param decimalsFrom the fixed decimal basis of amountToConvert
     * @param decimalsTo the fixed decimal basis of the returned convertedAmount
     * @return convertedAmount the amount after conversion
     * @return truncatedAmount if (from > to), there may be some truncation, it
     *  is up to the caller to decide what to do with the truncated amount.
     */
    function _convertDecimals(uint8 decimalsFrom, uint8 decimalsTo, uint256 amountToConvert) internal pure returns (uint256 convertedAmount, uint256 truncatedAmount) {
        if (decimalsFrom == decimalsTo) {
            // no shift
            convertedAmount = amountToConvert;
            truncatedAmount = 0;
        } else if (decimalsFrom < decimalsTo) {
            // Decimal shift left (add precision)
            uint256 shift = 10 ** (uint256(decimalsTo - decimalsFrom));
            convertedAmount = amountToConvert * shift;
            truncatedAmount = 0;
        } else {
            // Decimal shift right (remove precision) -> truncation
            uint256 shift = 10 ** (uint256(decimalsFrom - decimalsTo));
            convertedAmount = amountToConvert / shift;
            truncatedAmount = amountToConvert % shift;
        }
    }

    function primitiveOutputAmount(uint256 inputToken, uint256 outputToken, uint256 inputAmount, bytes32 metadata) internal virtual returns (uint256 outputAmount);

    function wrapToken(uint256 tokenId, uint256 amount, bytes32 metadata) internal virtual;

    function unwrapToken(uint256 tokenId, uint256 amount, bytes32 metadata) internal virtual returns (uint256 unwrappedAmount);
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

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity ^0.8.19;

/// @notice Implementing this allows a primitive to be called by the Ocean's
///  defi framework.
interface IOceanPrimitive {
    function computeOutputAmount(uint256 inputToken, uint256 outputToken, uint256 inputAmount, address userAddress, bytes32 metadata) external returns (uint256 outputAmount);

    function computeInputAmount(uint256 inputToken, uint256 outputToken, uint256 outputAmount, address userAddress, bytes32 metadata) external returns (uint256 inputAmount);

    function getTokenSupply(uint256 tokenId) external view returns (uint256 totalSupply);
}

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity ^0.8.19;

/**
 * @param interactionTypeAndAddress the type of interaction and the external
 *  contract called during this interaction.
 * @param inputToken this field is ignored except when the interaction type
 *  begins with "Compute".  During a "Compute" interaction, this token is given
 *  to the external contract.
 * @param outputToken this field is ignored except when the interaction type
 *  begins with "Compute".  During a "Compute" interaction, this token is
 *  received from the external contract.
 * @param specifiedAmount This value is the amount of the specified token.
 *  See the comment above the declaration for InteractionType for information
 *  on specified tokens.  When this value is equal to type(uint256).max, it is
 *  a request by the user to use the intra-transaction delta of the specified
 *  token as the specified amount.  See LibBalanceDelta for more information
 *  about this.  When the Ocean executes an interaction, it resolves the
 *  specifiedAmount before calling the external contract.  During a "721"
 *  interaction, the resolved specifiedAmount must be identically "1".
 * @param metadata This value is used in two ways.  During "Compute"
 *  interactions, it is forwarded to the external contract.  The external
 *  contract can define whatever expectations it wants for these 32 bytes.  The
 *  caller is expected to be aware of the expectations of the external contract
 *  invoked during the interaction.  During 721/1155 and wraps and unwraps,
 *  these bytes are cast to uint256 and used as the external ledger's token ID
 *  for the interaction.
 */
struct Interaction {
    bytes32 interactionTypeAndAddress;
    uint256 inputToken;
    uint256 outputToken;
    uint256 specifiedAmount;
    bytes32 metadata;
}

/**
 * InteractionType determines how the properties of Interaction are interpreted
 *
 * The interface implemented by the external contract, the specified token
 *  for the interaction, and what sign (+/-) of delta can be used are
 *  determined by the InteractionType.
 *
 * @param WrapErc20
 *      type(externalContract).interfaceId == IERC20
 *      specifiedToken == calculateOceanId(externalContract, 0)
 *      negative delta can be used as specifiedAmount
 *
 * @param UnwrapErc20
 *      type(externalContract).interfaceId == IERC20
 *      specifiedToken == calculateOceanId(externalContract, 0)
 *      positive delta can be used as specifiedAmount
 *
 * @param WrapErc721
 *      type(externalContract).interfaceId == IERC721
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      negative delta can be used as specifiedAmount
 *
 * @param UnwrapErc721
 *      type(externalContract).interfaceId == IERC721
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      positive delta can be used as specifiedAmount
 *
 * @param WrapErc1155
 *      type(externalContract).interfaceId == IERC1155
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      negative delta can be used as specifiedAmount
 *
 * @param WrapErc1155
 *      type(externalContract).interfaceId == IERC1155
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      positive delta can be used as specifiedAmount
 *
 * @param ComputeInputAmount
 *      type(externalContract).interfaceId == IOceanexternalContract
 *      specifiedToken == outputToken
 *      negative delta can be used as specifiedAmount
 *
 * @param ComputeOutputAmount
 *      type(externalContract).interfaceId == IOceanexternalContract
 *      specifiedToken == inputToken
 *      positive delta can be used as specifiedAmount
 */
enum InteractionType {
    WrapErc20,
    UnwrapErc20,
    WrapErc721,
    UnwrapErc721,
    WrapErc1155,
    UnwrapErc1155,
    ComputeInputAmount,
    ComputeOutputAmount,
    UnwrapEther
}

interface IOceanInteractions {
    function unwrapFeeDivisor() external view returns (uint256);

    function doMultipleInteractions(Interaction[] calldata interactions, uint256[] calldata ids) external payable returns (uint256[] memory burnIds, uint256[] memory burnAmounts, uint256[] memory mintIds, uint256[] memory mintAmounts);

    function forwardedDoMultipleInteractions(
        Interaction[] calldata interactions,
        uint256[] calldata ids,
        address userAddress
    )
        external
        payable
        returns (uint256[] memory burnIds, uint256[] memory burnAmounts, uint256[] memory mintIds, uint256[] memory mintAmounts);

    function doInteraction(Interaction calldata interaction) external payable returns (uint256 burnId, uint256 burnAmount, uint256 mintId, uint256 mintAmount);

    function forwardedDoInteraction(Interaction calldata interaction, address userAddress) external payable returns (uint256 burnId, uint256 burnAmount, uint256 mintId, uint256 mintAmount);
}