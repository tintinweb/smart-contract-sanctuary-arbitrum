// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "./IUniversalV3Pool.sol";
import "./IUniversalV3Factory.sol";


/// @title Provides quotes for swaps on V3 Pools
/// @notice Allows getting the expected amount out or amount in for a given swap without executing the swap
/// @dev These functions are not gas efficient and should _not_ be called on chain. Instead, optimistically execute
/// the swap and check the amounts in the callback.
/// @dev UniversalQuoter can be used on UniswapV3, CamelotV3, SushiSwapV3, ArbDexV3, RamsesV2, ZyberSwapV3, MMFinanceV3, CrescentSwapV3 and KyberSwapV2
contract UniversalQuoter {
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick.
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @dev Transient storage variable used to check a safety condition in exact output swaps.
    uint256 private amountOutCached;

    constructor() {}

    /// @dev Decode data encoded in function @quoteExactInputSingle and in @quoteExactOutputSingle
    function decodeFirstPool(bytes memory path) internal pure returns (
        address tokenA, address tokenB){
        require(path.length >= 40, "Decode Path fails");
        (bytes20 _tokenA, bytes20 _tokenB) = _decodeFirstPool(path);
        return (address(_tokenA), address(_tokenB));
    }

    function _decodeFirstPool(bytes memory path) internal pure returns (
        bytes20 tokenA, bytes20 tokenB){
        assembly{
            /// @dev Load the input data pointer
            let inputPtr := add(path, 32)
            /// @dev Load each x-byte segment of the input into the result variables
            tokenA := mload(inputPtr)
            tokenB := mload(add(inputPtr, 20))
        }
    }

    /// @dev Get pool fee from UniswapV3Pool
    function getPoolFeeUniswap(address pool) external view returns (uint24 fee){
        return IUniversalV3Pool(pool).fee();
    }

    /// @dev Get pool fee from KyberSwapV2Pool
    function getPoolFeeKyber(address pool) external view returns (uint24 fee){
        return IUniversalV3Pool(pool).swapFeeUnits();
    }

    /// @dev Get pool fee from AlgebraPool
    function getPoolFeeAlgebra(address pool) external view returns (uint16 fee){
        (, , fee, , , , ) = IUniversalV3Pool(pool).globalState();
    }

    /// @notice Use at UniswapV3, SushiSwapV3, ArbDexV3, RamsesV2, MMFinanceV3, CrescentSwapV3 and KyberSwapV2
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @return pool The pool address
    function getPoolFromUniswapFactory(
        address _factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool) {
        return IUniversalV3Factory(_factory).getPool(tokenA, tokenB, fee);
    }

    /// @notice Use at CamelotV3 and ZyberSwapV3
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @return pool The pool address
    function getPoolFromAlgebraFactory(
        address _factory,
        address tokenA,
        address tokenB
    ) external view returns (address pool) {
        return IUniversalV3Factory(_factory).poolByPair(tokenA, tokenB);
    }

    function _uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory path
    ) internal view {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut) = decodeFirstPool(path);

        (bool isExactInput, uint256 amountToPay, uint256 amountReceived) =
            amount0Delta > 0
                ? (tokenIn < tokenOut, uint256(amount0Delta), uint256(-amount1Delta))
                : (tokenOut < tokenIn, uint256(amount1Delta), uint256(-amount0Delta));
        if (isExactInput) {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, amountReceived)
                revert(ptr, 32)
            }
        } else {
            // if the cache has been populated, ensure that the full output amount has been received
            if (amountOutCached != 0) require(amountReceived == amountOutCached);
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, amountToPay)
                revert(ptr, 32)
            }
        }
    }

    /// @notice This function is for MMFinance V3 callback
    function pancakeV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external view {
        _uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    /// @notice This function is for Uniswap V3, SushiSwap V3, ArbDex V3, CrescentSwap V3 callback
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external view {
        _uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    /// @notice This function is for Ramses V2 callback
    function ramsesV2SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external view {
        _uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    /// @notice This function is for Camelot V3 and ZyberSwap V3 callback
    function algebraSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external view {
        _uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    /// @notice This function is for KyberSwap V2 callback
    function swapCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata data) external view {
        _uniswapV3SwapCallback(deltaQty0, deltaQty1, data);
    }

    /// @dev Parses a revert reason that should contain the numeric quote
    function parseRevertReason(bytes memory reason) private pure returns (uint256) {
        if (reason.length != 32) {
            if (reason.length < 68) revert('Unexpected error');
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (uint256));
    }

    /// @notice To get correct output need to add V3 Pool address
    /// @dev Function return amountOut
    function quoteExactInputSingle(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) public returns (uint256 amountOut) {
        bool zeroForOne = tokenIn < tokenOut;

        try
            IUniversalV3Pool(pool).swap(
                address(this), // address(0) might cause issues with some tokens
                zeroForOne,
                int256(amountIn),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encodePacked(tokenIn, tokenOut)
            )
        {} catch (bytes memory reason) {
            return parseRevertReason(reason);
        }
    }

    /// @notice To get correct output need to add V3 Pool address
    /// @dev Function return amountIn
    function quoteExactOutputSingle(
        address pool,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) public  returns (uint256 amountIn) {
        bool zeroForOne = tokenIn < tokenOut;

        // if no price limit has been specified, cache the output amount for comparison in the swap callback
        if (sqrtPriceLimitX96 == 0) amountOutCached = amountOut;
        try
            IUniversalV3Pool(pool).swap(
                address(this), // address(0) might cause issues with some tokens
                zeroForOne,
                -int256(amountOut),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encodePacked(tokenOut, tokenIn)
            )
        {} catch (bytes memory reason) {
            if (sqrtPriceLimitX96 == 0) delete amountOutCached; // clear cache
            return parseRevertReason(reason);
        }
    }
}