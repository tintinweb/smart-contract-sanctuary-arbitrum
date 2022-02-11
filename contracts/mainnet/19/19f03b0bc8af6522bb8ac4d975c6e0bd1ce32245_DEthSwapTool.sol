/**
 *Submitted for verification at arbiscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IUniswapRouter is ISwapRouter 
{
    function refundETH() 
        external 
        payable;
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported v       alues.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract DaiSwapTool 
{
    IUniswapRouter public constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    AggregatorV3Interface public constant ethUsdPriceFeed = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    address private constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    address private constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    function convertExactEthToDai() 
        public 
        payable 
    {
        require(msg.value > 0, "Must pass non 0 ETH amount");

        uint256 deadline = block.timestamp + 15;
        address tokenIn = WETH9;
        address tokenOut = DAI;
        uint24 fee = 3000;
        address recipient = msg.sender;
        uint256 amountIn = msg.value;
        uint256 amountOutMinimum = (uint256(getEthUsd()) * amountIn / 10**8) * 95 / 100;
        uint160 sqrtPriceLimitX96 = 0;  

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            fee,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum,
            sqrtPriceLimitX96
        );

        uniswapRouter.exactInputSingle{ value: msg.value }(params);
        uniswapRouter.refundETH();

        // refund leftover ETH to user
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed");
    }   

    function getEthUsd() 
        public 
        view 
        returns (int _price) 
    {
        (,_price,,,) = ethUsdPriceFeed.latestRoundData();
    }
  
    // important to receive ETH
    receive() 
        payable 
        external 
    {
        convertExactEthToDai();
    }
}

contract FrySwapTool
{
    IUniswapRouter public constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    AggregatorV3Interface public constant ethUsdPriceFeed = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    address private constant FRY = 0x633A3d2091dc7982597A0f635d23Ba5EB1223f48;
    address private constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    function convertExactEthToFry() 
        public 
        payable 
    {
        require(msg.value > 0, "Must pass non 0 ETH amount");

        uint256 deadline = block.timestamp + 15;
        address tokenIn = WETH9;
        address tokenOut = FRY;
        uint24 fee = 10000;
        address recipient = msg.sender;
        uint256 amountIn = msg.value;
        uint256 amountOutMinimum = 10**18; // won't work for less than 1 FRY
        uint160 sqrtPriceLimitX96 = 0;  

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            fee,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum,
            sqrtPriceLimitX96
        );

        uniswapRouter.exactInputSingle{ value: msg.value }(params);
        uniswapRouter.refundETH();

        // refund leftover ETH to user
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed");
    }

    receive() 
        payable 
        external 
    {
        convertExactEthToFry();
    }
}

contract DEthSwapTool
{
    IUniswapRouter public constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    AggregatorV3Interface public constant ethUsdPriceFeed = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);
    address private constant DETH = 0xBA98da6EF5EeB1a66B91B6608E0e2Bb6E9020607;
    address private constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    function convertExactEthToDEth() 
        public 
        payable 
    {
        require(msg.value > 0, "Must pass non 0 ETH amount");

        uint256 deadline = block.timestamp + 15;
        address tokenIn = WETH9;
        address tokenOut = DETH;
        uint24 fee = 10000;
        address recipient = msg.sender;
        uint256 amountIn = msg.value;
        uint256 amountOutMinimum = 1; 
        uint160 sqrtPriceLimitX96 = 0;  

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            fee,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum,
            sqrtPriceLimitX96
        );

        uniswapRouter.exactInputSingle{ value: msg.value }(params);
        uniswapRouter.refundETH();

        // refund leftover ETH to user
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed");
    }

    receive() 
        payable 
        external 
    {
        convertExactEthToDEth();
    }
}