/**
 *Submitted for verification at Arbiscan.io on 2023-10-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 _amount) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}

/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
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
}

contract Splitter {
    address public gasTank;
    address public uniswapRouter; // Uniswap Router address
    address immutable public weth; // WETH address
    
    event EthSplit(address indexed sender, address indexed gasTank, address indexed smartWallet, uint256 amountETHForGasTank, uint256 amountETHToSmartWallet);
    event ERC20Split(address indexed sender, address indexed gasTank, address indexed smartWallet, uint256 amountETHForGasTank, address tokenAddress, uint256 amountERC20ToSmartWallet);
    
    constructor(address _gasTank, address _uniswapRouter, address _weth) {
        gasTank = _gasTank;
        uniswapRouter = _uniswapRouter;
        weth = _weth;
    }
    
    function splitETH(address smartWallet, uint256 amountForGasTank) external payable {
        require(amountForGasTank <= msg.value, "Amount for gasTank exceeds the received ETH");
        uint256 amountToSmartWallet = msg.value - amountForGasTank;
        
        (bool success1, ) = gasTank.call{value: amountForGasTank}("");
        require(success1, "Transfer to gasTank failed");
        
        (bool success2, ) = smartWallet.call{value: amountToSmartWallet}("");
        require(success2, "Transfer to smartWallet failed");

        emit EthSplit(msg.sender, gasTank, smartWallet, amountForGasTank, amountToSmartWallet);
    }

    function splitERC20(address smartWallet, address tokenAddress, uint256 depositAmount, uint24 poolFee, uint256 amountForGasTank, uint256 amountInMax) external {        
        
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), depositAmount);

        // Approve the Uniswap Router to spend the ERC20 tokens
        require(
            IERC20(tokenAddress).approve(uniswapRouter, amountInMax),
            "Token approval failed"
        );

        
        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: tokenAddress,
                tokenOut: weth,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 1 hours,
                amountOut: amountForGasTank,
                amountInMaximum: amountInMax,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        ISwapRouter(uniswapRouter).exactOutputSingle(params);

        IWETH9(weth).withdraw(amountForGasTank);

        // Send the swapped ETH to the gasTank
        (bool success, ) = gasTank.call{value: amountForGasTank}("");
        require(success, "Transfer to gasTank failed");
        
        // Send any remaining ERC20 tokens to the smartWallet
        uint256 remainingTokenBalance = IERC20(tokenAddress).balanceOf(address(this));
        require(
            IERC20(tokenAddress).transfer(smartWallet, remainingTokenBalance),
            "Token transfer to smartWallet failed"
        );
        
        emit ERC20Split(msg.sender, gasTank, smartWallet, amountForGasTank, tokenAddress, remainingTokenBalance);
    }

    // receive function
    receive() external payable {}
}