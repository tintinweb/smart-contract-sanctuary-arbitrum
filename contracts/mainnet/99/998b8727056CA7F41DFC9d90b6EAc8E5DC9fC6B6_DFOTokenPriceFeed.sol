pragma solidity ^0.8.0;

// import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

contract DFOTokenPriceFeed{

    constructor() {
    }

    function estimateAmountOut(address tokenIn, uint128 amountIn, uint32 secondsAgo) external pure returns(uint){
        return 20000000000000000;
    }
}