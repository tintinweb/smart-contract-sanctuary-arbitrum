// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

pragma solidity =0.7.6;
pragma abicoder v2;

import './interfaces/IQuoter.sol';

contract UniswapV3SwapHelper {

    IQuoter public quoter;
    uint256 public output;

    constructor(address _quoter) {
        quoter = IQuoter(_quoter);
    }

    function getOutputAmount(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        (bool success, bytes memory result) = address(quoter).call(
            abi.encodeWithSelector(
                quoter.quoteExactInputSingle.selector,
                tokenIn,
                tokenOut,
                fee,
                amountIn,
                0
            )
        );

        if (success) {
            amountOut = abi.decode(result, (uint256));
        } else {
            amountOut = 0;
        }

        output = amountOut;
    }

    function getMultiOutputAmount(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        (bool success, bytes memory result) = address(quoter).call(
            abi.encodeWithSelector(
                quoter.quoteExactInput.selector,
                path,
                amountIn
            )
        );

        if (success) {
            amountOut = abi.decode(result, (uint256));
        } else {
            amountOut = 0;
        }

        output = amountOut;
    }

    function getMultiOutput(
        bytes memory path,
        uint256 amountIn
    ) private returns (uint256 amountOut) {
        (bool success, bytes memory result) = address(quoter).call(
            abi.encodeWithSelector(
                quoter.quoteExactInput.selector,
                path,
                amountIn
            )
        );

        if (success) {
            amountOut = abi.decode(result, (uint256));
        } else {
            amountOut = 0;
        }
    }

    function callPrivate(bytes memory path, uint256 amountIn) external returns (uint256 amountOut) {
        amountOut = getMultiOutput(path, amountIn);
    }

    function getOutput() external view returns (uint256 amountOut) {
        return output;
    }

}