/**
 *Submitted for verification at Arbiscan.io on 2024-05-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

/**
 * @title Dex
 * @dev swap erc20 tokens contract
 * @custom:dev-run-script scripts/deploy_with_ethers.ts
 */

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function allowance(address owner, address spender) external view returns (uint256);

}

interface IERC20Metadata {
    function decimals() external view returns (uint8);
}

contract TokensSwap {
    error PairDoesntExist();
    error TransferFailed();
    error ApproveFailed();
    error AllowanceFailed();

    function getPrice(
        address factory,
        address token1,
        address token2,
        uint8 decimalsAfterPoint
    ) public view returns (uint256 price) {
        address pair = IUniswapV2Factory(factory).getPair(token1, token2);

        if (pair == address(0)) {
            revert PairDoesntExist();
        }

        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair)
            .getReserves();
        address token0 = IUniswapV2Pair(pair).token0();

        uint8 decimals0 = IERC20Metadata(token0).decimals();
        uint8 decimals1 = IERC20Metadata(token0 == token1 ? token2 : token1)
            .decimals();
        uint256 scaleFactor = 10**decimalsAfterPoint;

        if (token0 == token1) {
            price =
                (reserve1 * (10**decimals0) * scaleFactor) /
                reserve0 /
                (10**decimals1);
        } else {
            price =
                (reserve0 * (10**decimals1) * scaleFactor) /
                reserve1 /
                (10**decimals0);
        }
    }

    function getAmountsOut(
        address router,
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        amounts = IUniswapV2Router02(router).getAmountsOut(amountIn, path);
    }

    function swapTokens(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external {

        IERC20(tokenIn).approve(address(this), amountIn);

        uint256 allowance = IERC20(tokenIn).allowance(msg.sender, address(this));
        if (allowance < amountIn) {
            revert AllowanceFailed();
        }

        bool success = IERC20(tokenIn).transferFrom(
            msg.sender,
            address(this),
            amountIn
        );
        if (!success) {
            revert TransferFailed();
        }

        success = IERC20(tokenIn).approve(router, amountIn);
        if (!success) {
            revert ApproveFailed();
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }
}