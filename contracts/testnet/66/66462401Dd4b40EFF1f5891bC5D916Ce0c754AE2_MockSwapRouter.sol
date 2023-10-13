// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ISwapRouter {
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

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "contracts/interfaces/ISwapRouter.sol";

contract MockSwapRouter is ISwapRouter {
    address private tokenIn;
    address private tokenOut;
    uint24 private fee;
    address private recipient;
    uint256 private deadline;
    uint256 private amountIn;
    uint256 private amountOutMinimum;
    uint160 private sqrtPriceLimitX96;
    uint256 private txValue;

    struct MockSwapData {
        address tokenIn; address tokenOut; uint24 fee; address recipient; uint256 deadline;
        uint256 amountIn; uint256 amountOutMinimum; uint160 sqrtPriceLimitX96; uint256 txValue;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut) {
        tokenIn = params.tokenIn;
        tokenOut = params.tokenOut;
        fee = params.fee;
        recipient = params.recipient;
        deadline = params.deadline;
        amountIn = params.amountIn;
        amountOutMinimum = params.amountOutMinimum;
        sqrtPriceLimitX96 = params.sqrtPriceLimitX96;
        txValue = msg.value;
    }

    function receivedSwap() external view returns (MockSwapData memory) {
        return MockSwapData(
            tokenIn, tokenOut, fee, recipient, deadline, amountIn, amountOutMinimum,
            sqrtPriceLimitX96, txValue
        );
    }
}