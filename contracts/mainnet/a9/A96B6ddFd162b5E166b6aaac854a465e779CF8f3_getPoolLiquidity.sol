/**
 *Submitted for verification at Arbiscan on 2023-07-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IUniswapV3Pool {
    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);
}

interface IERC20 {
    function symbol() external view returns (string memory);
}

contract getPoolLiquidity {
    address constant uniswapV3Factory = 
        address(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    uint24[] fee = [uint24(100), uint24(500), uint24(3000), uint24(10000)];

    function getPoolLiquidityByInputToken(
        address inputToken,
        address outputToken
    ) external view returns (
        string memory inputTokenSymbol,
        string memory outputTokenSymbol,
        address[] memory poolAddress,
        uint128[] memory poolLiquidity
    ) {
        inputTokenSymbol = IERC20(inputToken).symbol();
        outputTokenSymbol = IERC20(outputToken).symbol();

        address[] memory _poolAddress = new address[](4);
        uint128[] memory _poolLiquidity = new uint128[](4);

        for (uint i ; i < 4; i++) {
            address _pool = 
                IUniswapV3Factory(uniswapV3Factory).getPool(
                    inputToken, 
                    outputToken, 
                    fee[i]
                );
            _poolAddress[i] = _pool;
            if (_pool != address(0)) {
                _poolLiquidity[i] = IUniswapV3Pool(_pool).liquidity();
            } else {
                _poolLiquidity[i] = 0;
            }
        }

        poolAddress = _poolAddress;
        poolLiquidity = _poolLiquidity;
    }
}