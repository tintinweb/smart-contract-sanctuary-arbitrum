// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 limitSqrtPrice;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Unlike standard swaps, handles transferring from user before the actual swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingleSupportingFeeOnTransferTokens(
        ExactInputSingleParams calldata params
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

import "./IAsset.sol";

interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICryptoFactory {
    function get_coins(address _pool) external view returns (address[2] memory);

    function get_coin_indices(address _pool, address _from, address _to) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICryptoPool {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable;

    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable;

    function get_dy(uint256 i, uint256 j, uint256 amount) external view returns (uint256);

    function get_dy_underlying(uint256 i, uint256 j, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICryptoRegistry {
    function get_coin_indices(address _pool, address _from, address _to) external view returns (uint256, uint256);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_n_coins(address _pool) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurvePool {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;

    function get_dy(int128 i, int128 j, uint256 amount) external view returns (uint256);

    function get_dy_underlying(int128 i, int128 j, uint256 amount) external view returns (uint256);

    function coins(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRegistry {
    function get_coin_indices(address _pool, address _from, address _to) external view returns (int128, int128, bool);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_n_coins(address _pool) external view returns (uint256[2] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDodoV2Pool {
    function sellBase(address to) external payable returns (uint256);

    function sellQuote(address to) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGmxVault {
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IQuote {
    struct RFQTQuote {
        address pool;
        address externalAccount;
        address trader;
        address effectiveTrader;
        address baseToken;
        address quoteToken;
        uint256 effectiveBaseTokenAmount;
        uint256 baseTokenAmount;
        uint256 quoteTokenAmount;
        uint256 quoteExpiry;
        uint256 nonce;
        bytes32 txid;
        bytes signature;
    }

    function tradeRFQT(RFQTQuote memory quote) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITWAPRelayer {
    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint32 submitDeadline;
    }

    function sell(SellParams memory sellParams) external payable returns (uint256 orderId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ISwapPool.sol";

interface IBasePool is ISwapPool {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ISwapPool.sol";

interface ICryptoPool is ISwapPool {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ISwapPool.sol";

interface IMetaPool is ISwapPool {
    function exchangeUnderlying(uint256 i, uint256 j, uint256 dx, uint256 minDy) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRegistry {
    function getCoinIndices(address _pool, address _from, address _to) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISwapPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 minDy,
        bytes calldata data
    ) external payable returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IDMMExchangeRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata poolsPath,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ISwapCallBack.sol";

/// @notice Functions for swapping tokens via KyberSwap v2
/// - Support swap with exact input or exact output
/// - Support swap with a price limit
/// - Support swap within a single pool and between multiple pools
interface IElasticRouter is ISwapCallback {
    /// @dev Params for swapping exact input amount
    /// @param tokenIn the token to swap
    /// @param tokenOut the token to receive
    /// @param fee the pool's fee
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountIn the tokenIn amount to swap
    /// @param amountOutMinimum the minimum receive amount
    /// @param limitSqrtP the price limit, if reached, stop swapping
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
        uint160 limitSqrtP;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function swapExactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    /// @dev Params for swapping exact input using multiple pools
    /// @param path the encoded path to swap from tokenIn to tokenOut
    ///   If the swap is from token0 -> token1 -> token2, then path is encoded as [token0, fee01, token1, fee12, token2]
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountIn the tokenIn amount to swap
    /// @param amountOutMinimum the minimum receive amount
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function swapExactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    /// @dev Params for swapping exact output amount
    /// @param tokenIn the token to swap
    /// @param tokenOut the token to receive
    /// @param fee the pool's fee
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountOut the tokenOut amount of tokenOut
    /// @param amountInMaximum the minimum input amount
    /// @param limitSqrtP the price limit, if reached, stop swapping
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 maxAmountIn;
        uint160 limitSqrtP;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function swapExactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    /// @dev Params for swapping exact output using multiple pools
    /// @param path the encoded path to swap from tokenIn to tokenOut
    ///   If the swap is from token0 -> token1 -> token2, then path is encoded as [token2, fee12, token1, fee01, token0]
    /// @param recipient address to receive tokenOut
    /// @param deadline time that the transaction will be expired
    /// @param amountOut the tokenOut amount of tokenOut
    /// @param amountInMaximum the minimum input amount
    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 maxAmountIn;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function swapExactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Callback for IPool#swap
/// @notice Any contract that calls IPool#swap must implement this interface
interface ISwapCallback {
    /// @notice Called to `msg.sender` after swap execution of IPool#swap.
    /// @dev This function's implementation must pay tokens owed to the pool for the swap.
    /// The caller of this method must be checked to be a Pool deployed by the canonical Factory.
    /// deltaQty0 and deltaQty1 can both be 0 if no tokens were swapped.
    /// @param deltaQty0 The token0 quantity that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send deltaQty0 of token0 to the pool.
    /// @param deltaQty1 The token1 quantity that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send deltaQty1 of token1 to the pool.
    /// @param data Data passed through by the caller via the IPool#swap call
    function swapCallback(int256 deltaQty0, int256 deltaQty1, bytes calldata data) external;
}

// SPDX-License-Identifier:  MIT
pragma solidity 0.8.17;

interface IPool {
    function swap(
        address from,
        address to,
        address recipient,
        uint256 amount,
        uint256 minAmount,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPlatypusRouter01 {
    function swapTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut, uint256 haircut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISwap {
    /**
     * @notice Return the index of the given token address. Reverts if no matching
     * token is found.
     * @param tokenAddress address of the token
     * @return the index of the given token address
     */
    function getTokenIndex(address tokenAddress) external view returns (uint8);

    /**
     * @notice Swap two tokens using this pool
     * @param tokenIndexFrom the token the user wants to swap from
     * @param tokenIndexTo the token the user wants to swap to
     * @param dx the amount of tokens the user wants to swap from
     * @param minDy the min amount the user would like to receive, or revert.
     * @param deadline latest timestamp to accept this transaction
     */
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRouter {
    struct Route {
        address from;
        address to;
        bool stable;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRouterV2 {
    struct Route {
        address from;
        address to;
        bool stable;
        address factory;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface ILBRouter {
    /**
     * @dev This enum represents the version of the pair requested
     * - V1: Joe V1 pair
     * - V2: LB pair V2. Also called legacyPair
     * - V2_1: LB pair V2.1 (current version)
     */
    enum Version {
        V1,
        V2,
        V2_1
    }

    /**
     * @dev The path parameters, such as:
     * - pairBinSteps: The list of bin steps of the pairs to go through
     * - versions: The list of versions of the pairs to go through
     * - tokenPath: The list of tokens in the path to go through
     */
    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITridentBentoBoxV1 {
    function deposit(
        address token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITridentPool {
    function swap(bytes calldata data) external returns (uint256 finalAmountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV3RouterV1 {
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

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

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

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3RouterV2 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWombatRouter {
    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWooPPV2 {
    /// @notice Swap `fromToken` to `toToken`.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @param minToAmount the minimum amount of `toToken` to receive
    /// @param to the destination address
    /// @param rebateTo the rebate address (optional, can be address ZERO)
    /// @return realToAmount the amount of toToken to receive
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external returns (uint256 realToAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "../interfaces/IWETH.sol";

error AssetNotReceived();

library LibAsset {
    using LibAsset for address;

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalance(address self) internal view returns (uint256) {
        return self.isNative() ? address(this).balance : IERC20(self).balanceOf(address(this));
    }

    function transferFrom(address self, address from, address to, uint256 amount) internal {
        SafeERC20.safeTransferFrom(IERC20(self), from, to, amount);
    }

    function transfer(address self, address recipient, uint256 amount) internal {
        if (self.isNative()) {
            Address.sendValue(payable(recipient), amount);
        } else {
            SafeERC20.safeTransfer(IERC20(self), recipient, amount);
        }
    }

    function approve(address self, address spender, uint256 amount) internal {
        SafeERC20.forceApprove(IERC20(self), spender, amount);
    }

    function deposit(address self, address weth, uint256 amount) internal {
        if (self.isNative()) {
            if (msg.value < amount) {
                revert AssetNotReceived();
            }
            IWETH(weth).deposit{value: amount}();
        } else {
            self.transferFrom(msg.sender, address(this), amount);
        }
    }

    function withdraw(address self, address weth, address to, uint256 amount) internal {
        if (self.isNative()) {
            IWETH(weth).withdraw(amount);
        }
        self.transfer(payable(to), amount);
    }

    function getDecimals(address self) internal view returns (uint8 tokenDecimals) {
        tokenDecimals = 18;

        if (!self.isNative()) {
            (, bytes memory queriedDecimals) = self.staticcall(abi.encodeWithSignature("decimals()"));
            tokenDecimals = abi.decode(queriedDecimals, (uint8));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error AddressOutOfBounds();

library LibBytes {
    using LibBytes for bytes;

    function toAddress(bytes memory self, uint256 start) internal pure returns (address) {
        if (self.length < start + 20) {
            revert AddressOutOfBounds();
        }
        address tempAddress;

        assembly {
            tempAddress := mload(add(add(self, 20), start))
        }

        return tempAddress;
    }

    function slice(
        bytes memory self,
        uint256 start,
        uint256 length
    ) internal pure returns (bytes memory) {
        require(length + 31 >= length, "slice_overflow");
        require(self.length >= start + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(length, 31)
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, length)

                for {
                    let cc := add(add(add(self, lengthmod), mul(0x20, iszero(lengthmod))), start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function concat(bytes memory self, bytes memory postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            tempBytes := mload(0x40)

            let length := mload(self)
            mstore(tempBytes, length)

            let mc := add(tempBytes, 0x20)
            let end := add(mc, length)

            for {
                let cc := add(self, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            length := mload(postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            mc := end
            end := add(mc, length)

            for {
                let cc := add(postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(0x40, and(add(add(end, iszero(add(length, mload(self)))), 31), not(31)))
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct CurveSettings {
    address mainRegistry;
    address cryptoRegistry;
    address cryptoFactory;
}

struct Amm {
    uint8 protocolId;
    bytes4 selector;
    address addr;
}

struct AppStorage {
    address weth;
    address magpieAggregatorAddress;
    mapping(uint16 => Amm) amms;
    CurveSettings curveSettings;
}

library LibMagpieRouter {
    function getStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ILendingPool} from "../interfaces/aave-v2/ILendingPool.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibAaveV2 {
    using LibAsset for address;

    function swapAaveV2(Hop memory h) internal returns (uint256 amountOut) {
        uint256 pl = h.path.length;
        for (uint256 i = 0; i < pl - 1; ) {
            bytes memory poolData = h.poolDataList[i];
            uint8 operation;
            assembly {
                operation := shr(248, mload(add(poolData, 32)))
            }
            bool isDeposit = operation == 1;
            uint256 amountIn = i == 0 ? h.amountIn : amountOut;
            if (isDeposit) {
                h.path[i].approve(h.addr, amountIn);
                ILendingPool(h.addr).deposit(h.path[i], amountIn, address(this), 0);
                amountOut = h.amountIn;
            } else {
                amountOut = ILendingPool(h.addr).withdraw(h.path[i + 1], amountIn, address(this));
            }

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISwapRouter} from "../interfaces/algebra/ISwapRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibAlgebra {
    using LibAsset for address;

    function getAlgebraPath(address[] memory path) private pure returns (bytes memory) {
        uint256 pl = path.length;
        bytes memory payload = new bytes(pl * 20);

        assembly {
            let i := 0
            let payloadPosition := add(payload, 32)
            let pathPosition := add(path, 32)

            for {

            } lt(i, pl) {
                i := add(i, 1)
                pathPosition := add(pathPosition, 32)
                payloadPosition := add(payloadPosition, 20)
            } {
                mstore(payloadPosition, shl(96, mload(pathPosition)))
            }
        }

        return payload;
    }

    function swapAlgebra(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);
        if (h.path.length == 2) {
            amountOut = ISwapRouter(h.addr).exactInputSingle(
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: h.path[0],
                    tokenOut: h.path[1],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: h.amountIn,
                    amountOutMinimum: 0,
                    limitSqrtPrice: 0
                })
            );
        } else {
            amountOut = ISwapRouter(h.addr).exactInput(
                ISwapRouter.ExactInputParams({
                    path: getAlgebraPath(h.path),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: h.amountIn,
                    amountOutMinimum: 0
                })
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAsset} from "../interfaces/balancer-v2/IAsset.sol";
import {IVault} from "../interfaces/balancer-v2/IVault.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibBalancerV2 {
    using LibAsset for address;

    function getPoolId(bytes memory poolData) private pure returns (bytes32 poolId) {
        assembly {
            poolId := mload(add(poolData, 32))
        }
    }

    function swapBalancerV2(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);
        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        if (h.path.length == 2) {
            amountOut = IVault(h.addr).swap(
                IVault.SingleSwap({
                    poolId: getPoolId(h.poolDataList[0]),
                    kind: IVault.SwapKind.GIVEN_IN,
                    assetIn: IAsset(h.path[0]),
                    assetOut: IAsset(h.path[1]),
                    amount: h.amountIn,
                    userData: "0x"
                }),
                funds,
                0,
                block.timestamp
            );
        } else {
            uint256 i;
            uint256 l = h.path.length;
            IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](h.path.length - 1);
            IAsset[] memory balancerAssets = new IAsset[](h.path.length);
            int256[] memory limits = new int256[](h.path.length);

            for (i = 0; i < l - 1; ) {
                swaps[i] = IVault.BatchSwapStep({
                    poolId: getPoolId(h.poolDataList[i]),
                    assetInIndex: i,
                    assetOutIndex: i + 1,
                    amount: i == 0 ? h.amountIn : 0,
                    userData: "0x"
                });
                balancerAssets[i] = IAsset(h.path[i]);
                limits[i] = i == 0 ? int256(h.amountIn) : int256(0);

                if (i == h.path.length - 2) {
                    balancerAssets[i + 1] = IAsset(h.path[i + 1]);
                    limits[i + 1] = 0;
                }

                unchecked {
                    i++;
                }
            }

            int256[] memory deltas = IVault(h.addr).batchSwap(
                IVault.SwapKind.GIVEN_IN,
                swaps,
                balancerAssets,
                funds,
                limits,
                block.timestamp
            );

            int256 delta = deltas[l - 1];
            amountOut = uint256(delta < 0 ? -delta : delta);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ICamelotRouter} from "../interfaces/camelot/ICamelotRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibCamelot {
    using LibAsset for address;

    function swapCamelot(Hop memory h) internal returns (uint256 amountOut) {
        uint256 l = h.path.length;
        h.path[0].approve(h.addr, h.amountIn);
        ICamelotRouter(h.addr).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            h.amountIn,
            0,
            h.path,
            address(this),
            address(0),
            block.timestamp
        );

        amountOut = h.path[l - 1].getBalance();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AppStorage, LibMagpieRouter} from "../libraries/LibMagpieRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {ICryptoFactory} from "../interfaces/curve/ICryptoFactory.sol";
import {ICryptoPool} from "../interfaces/curve/ICryptoPool.sol";
import {ICryptoRegistry} from "../interfaces/curve/ICryptoRegistry.sol";
import {ICurvePool} from "../interfaces/curve/ICurvePool.sol";
import {IRegistry} from "../interfaces/curve/IRegistry.sol";
import {Hop} from "./LibHop.sol";

struct ExchangeArgs {
    address pool;
    address from;
    address to;
    uint256 amount;
}

library LibCurve {
    using LibAsset for address;

    function getPoolAddress(bytes memory poolData) private pure returns (address poolAddress) {
        assembly {
            poolAddress := shr(96, mload(add(poolData, 32)))
        }
    }

    function mainExchange(ExchangeArgs memory exchangeArgs, address registry) private {
        int128 i = 0;
        int128 j = 0;
        bool isUnderlying = false;
        (i, j, isUnderlying) = IRegistry(registry).get_coin_indices(
            exchangeArgs.pool,
            exchangeArgs.from,
            exchangeArgs.to
        );

        if (isUnderlying) {
            ICurvePool(exchangeArgs.pool).exchange_underlying(i, j, exchangeArgs.amount, 0);
        } else {
            ICurvePool(exchangeArgs.pool).exchange(i, j, exchangeArgs.amount, 0);
        }
    }

    function cryptoExchange(ExchangeArgs memory exchangeArgs, address registry) private {
        uint256 i = 0;
        uint256 j = 0;
        address initial = exchangeArgs.from;
        address target = exchangeArgs.to;

        (i, j) = ICryptoRegistry(registry).get_coin_indices(exchangeArgs.pool, initial, target);

        ICryptoPool(exchangeArgs.pool).exchange(i, j, exchangeArgs.amount, 0);
    }

    function swapCurve(Hop memory h) internal returns (uint256 amountOut) {
        AppStorage storage s = LibMagpieRouter.getStorage();

        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            address pool = getPoolAddress(h.poolDataList[i]);

            ExchangeArgs memory exchangeArgs = ExchangeArgs({
                pool: pool,
                from: h.path[i],
                to: h.path[i + 1],
                amount: i == 0 ? h.amountIn : amountOut
            });

            h.path[i].approve(exchangeArgs.pool, h.amountIn);

            if (
                s.curveSettings.cryptoRegistry != address(0) &&
                ICryptoRegistry(s.curveSettings.cryptoRegistry).get_n_coins(exchangeArgs.pool) > 0
            ) {
                cryptoExchange(exchangeArgs, s.curveSettings.cryptoRegistry);
            } else if (
                s.curveSettings.mainRegistry != address(0) &&
                IRegistry(s.curveSettings.mainRegistry).get_n_coins(exchangeArgs.pool)[0] > 0
            ) {
                mainExchange(exchangeArgs, s.curveSettings.mainRegistry);
            } else if (s.curveSettings.cryptoFactory != address(0)) {
                cryptoExchange(exchangeArgs, s.curveSettings.cryptoFactory);
            }

            amountOut = h.path[i + 1].getBalance();

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IDodoV2Pool} from "../interfaces/dodo-v2/IDodoV2Pool.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibDodoV2 {
    using LibAsset for address;

    function getPoolData(bytes memory poolData) private pure returns (bytes32 poolDataBytes32) {
        assembly {
            poolDataBytes32 := mload(add(poolData, 32))
        }
    }

    function convertPoolDataList(
        bytes[] memory poolDataList
    ) private pure returns (bytes32[] memory poolDataListBytes32) {
        uint256 l = poolDataList.length;
        poolDataListBytes32 = new bytes32[](l);
        for (uint256 i = 0; i < l; ) {
            poolDataListBytes32[i] = getPoolData(poolDataList[i]);
            unchecked {
                i++;
            }
        }
    }

    function getDodoV2Data(
        bytes32[] memory poolData
    ) private pure returns (address[] memory poolAddresses, uint256[] memory directions) {
        uint256 l = poolData.length;
        poolAddresses = new address[](l);
        directions = new uint256[](l);

        assembly {
            let i := 0
            let poolAddressesPosition := add(poolAddresses, 32)
            let directionsPosition := add(directions, 32)

            for {

            } lt(i, l) {
                i := add(i, 1)
                poolAddressesPosition := add(poolAddressesPosition, 32)
                directionsPosition := add(directionsPosition, 32)
            } {
                let poolDataPosition := add(add(poolData, 32), mul(i, 32))

                mstore(poolAddressesPosition, shr(96, mload(poolDataPosition)))
                mstore(directionsPosition, shr(248, shl(160, mload(poolDataPosition))))
            }
        }
    }

    function swapDodoV2(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.poolDataList.length;
        (address[] memory poolAddresses, uint256[] memory directions) = getDodoV2Data(
            convertPoolDataList(h.poolDataList)
        );

        h.path[0].transfer(payable(poolAddresses[0]), h.amountIn);

        for (i = 0; i < l; ) {
            if (directions[i] == 1) {
                amountOut = IDodoV2Pool(poolAddresses[i]).sellBase((i == l - 1) ? address(this) : poolAddresses[i + 1]);
            } else {
                amountOut = IDodoV2Pool(poolAddresses[i]).sellQuote(
                    (i == l - 1) ? address(this) : poolAddresses[i + 1]
                );
            }

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IGmxVault} from "../interfaces/gmx/IGmxVault.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibGmx {
    using LibAsset for address;

    function swapGmx(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            h.path[i].transfer(h.addr, i == 0 ? h.amountIn : amountOut);
            amountOut = IGmxVault(h.addr).swap(h.path[i], h.path[i + 1], address(this));

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IQuote} from "../interfaces/hashflow/IQuote.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {Hop} from "./LibHop.sol";

library LibHashflow {
    using LibAsset for address;
    using LibBytes for bytes;

    function swapHashflow(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            bytes memory poolData = h.poolDataList[i];
            IQuote.RFQTQuote memory quote;

            assembly {
                mstore(quote, shr(96, mload(add(poolData, 32)))) // pool
                mstore(add(quote, 32), shr(96, mload(add(poolData, 180)))) // externalAccount
                mstore(add(quote, 96), shr(96, mload(add(poolData, 200)))) // effectiveTrader
                mstore(add(quote, 224), mload(add(poolData, 52))) // baseTokenAmount
                mstore(add(quote, 256), mload(add(poolData, 84))) // quoteTokenAmount
                mstore(add(quote, 288), mload(add(poolData, 116))) // quoteExpiry
                mstore(add(quote, 320), mload(add(poolData, 148))) // nonce
                mstore(add(quote, 352), mload(add(poolData, 220))) // txid
            }

            quote.effectiveBaseTokenAmount = i == 0 ? h.amountIn : amountOut;
            quote.trader = address(this);
            quote.baseToken = h.path[i];
            quote.quoteToken = h.path[i + 1];
            quote.signature = poolData.slice(220, poolData.length - 220);

            h.path[i].approve(h.addr, quote.effectiveBaseTokenAmount);

            IQuote(h.addr).tradeRFQT(quote);

            amountOut = h.path[i + 1].getBalance();

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AppStorage, LibMagpieRouter} from "../libraries/LibMagpieRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";

struct Hop {
    address addr;
    uint256 amountIn;
    address recipient;
    bytes[] poolDataList;
    address[] path;
}

struct HopParams {
    uint16 ammId;
    uint256 amountIn;
    bytes[] poolDataList;
    address[] path;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ITWAPRelayer} from "../interfaces/integral-size/ITWAPRelayer.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibIntegralSize {
    using LibAsset for address;

    function swapIntegralSize(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            h.path[i].approve(h.addr, h.amountIn);

            ITWAPRelayer(h.addr).sell(
                ITWAPRelayer.SellParams({
                    tokenIn: h.path[i],
                    tokenOut: h.path[i + 1],
                    amountIn: i == 0 ? h.amountIn : amountOut,
                    amountOutMin: 0,
                    wrapUnwrap: false,
                    to: address(this),
                    submitDeadline: uint32(block.timestamp)
                })
            );

            amountOut = h.path[i + 1].getBalance();

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IMetaPool} from "../interfaces/kokonut-swap/IMetaPool.sol";
import {ICryptoPool} from "../interfaces/kokonut-swap/ICryptoPool.sol";
import {IBasePool} from "../interfaces/kokonut-swap/IBasePool.sol";
import {IRegistry} from "../interfaces/kokonut-swap/IRegistry.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibKokonutSwap {
    using LibAsset for address;

    function getPoolAddress(bytes memory poolData) private pure returns (address poolAddress) {
        assembly {
            poolAddress := shr(96, mload(add(poolData, 32)))
        }
    }

    function swapKokonutBase(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            uint256 amountIn = i == 0 ? h.amountIn : amountOut;
            address poolAddress = getPoolAddress(h.poolDataList[i]);
            h.path[i].approve(poolAddress, amountIn);
            (uint256 tokenIndexFrom, uint256 tokenIndexTo) = IRegistry(h.addr).getCoinIndices(
                poolAddress,
                h.path[i],
                h.path[i + 1]
            );
            (amountOut, ) = IBasePool(poolAddress).exchange(tokenIndexFrom, tokenIndexTo, amountIn, 0, new bytes(0));

            unchecked {
                i++;
            }
        }
    }

    function swapKokonutCrypto(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            uint256 amountIn = i == 0 ? h.amountIn : amountOut;
            address poolAddress = getPoolAddress(h.poolDataList[i]);
            h.path[i].approve(poolAddress, amountIn);
            (uint256 tokenIndexFrom, uint256 tokenIndexTo) = IRegistry(h.addr).getCoinIndices(
                poolAddress,
                h.path[i],
                h.path[i + 1]
            );
            (amountOut, ) = ICryptoPool(poolAddress).exchange(tokenIndexFrom, tokenIndexTo, amountIn, 0, new bytes(0));

            unchecked {
                i++;
            }
        }
    }

    function swapKokonutMeta(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            uint256 amountIn = i == 0 ? h.amountIn : amountOut;
            address poolAddress = getPoolAddress(h.poolDataList[i]);
            h.path[i].approve(poolAddress, amountIn);
            (uint256 tokenIndexFrom, uint256 tokenIndexTo) = IRegistry(h.addr).getCoinIndices(
                poolAddress,
                h.path[i],
                h.path[i + 1]
            );
            (amountOut, ) = IMetaPool(poolAddress).exchangeUnderlying(tokenIndexFrom, tokenIndexTo, amountIn, 0);

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import {IDMMExchangeRouter} from "../interfaces/kyber-swap/IDMMExchangeRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibKyberSwapClassic {
    using LibAsset for address;

    function getPoolAddress(bytes memory poolData) private pure returns (address poolAddress) {
        assembly {
            poolAddress := shr(96, mload(add(poolData, 32)))
        }
    }

    function swapKyberClassic(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);

        uint256 l = h.path.length;
        address[] memory poolsPath = new address[](l - 1);
        IERC20[] memory path = new IERC20[](l);

        for (uint256 i = 0; i < l; ) {
            path[i] = IERC20(h.path[i]);

            if (i < l - 1) {
                poolsPath[i] = getPoolAddress(h.poolDataList[i]);
            }

            unchecked {
                i++;
            }
        }

        uint256[] memory amountOuts = IDMMExchangeRouter(h.addr).swapExactTokensForTokens(
            h.amountIn,
            0,
            poolsPath,
            path,
            address(this),
            block.timestamp
        );

        amountOut = amountOuts[amountOuts.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IElasticRouter} from "../interfaces/kyber-swap/IElasticRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

error KyberInvalidLengthsOfArrays();

library LibKyberSwapElastic {
    using LibAsset for address;

    function getPoolData(bytes memory poolData) private pure returns (bytes32 poolDataBytes32) {
        assembly {
            poolDataBytes32 := mload(add(poolData, 32))
        }
    }

    function convertPoolDataList(
        bytes[] memory poolDataList
    ) private pure returns (bytes32[] memory poolDataListBytes32) {
        uint256 l = poolDataList.length;
        poolDataListBytes32 = new bytes32[](l);
        for (uint256 i = 0; i < l; ) {
            poolDataListBytes32[i] = getPoolData(poolDataList[i]);
            unchecked {
                i++;
            }
        }
    }

    function getKyberPath(address[] memory path, bytes32[] memory poolDataList) private pure returns (bytes memory) {
        bytes memory payload;
        uint256 pl = path.length;
        uint256 pdl = poolDataList.length;

        if (pl - 1 != pdl) {
            revert KyberInvalidLengthsOfArrays();
        }

        assembly {
            payload := mload(0x40)
            let i := 0
            let payloadPosition := add(payload, 32)
            let pathPosition := add(path, 32)
            let poolDataPosition := add(poolDataList, 32)

            for {

            } lt(i, pl) {
                i := add(i, 1)
                pathPosition := add(pathPosition, 32)
            } {
                mstore(payloadPosition, shl(96, mload(pathPosition)))
                payloadPosition := add(payloadPosition, 20)

                if lt(i, pdl) {
                    mstore(payloadPosition, mload(poolDataPosition))
                    payloadPosition := add(payloadPosition, 3)
                    poolDataPosition := add(poolDataPosition, 32)
                }
            }

            mstore(payload, sub(sub(payloadPosition, payload), 32))
            mstore(0x40, and(add(payloadPosition, 31), not(31)))
        }

        return payload;
    }

    function swapKyberElastic(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);
        if (h.path.length == 2) {
            bytes memory poolData = h.poolDataList[0];
            uint24 fee;

            assembly {
                fee := shr(232, mload(add(poolData, 32)))
            }

            amountOut = IElasticRouter(h.addr).swapExactInputSingle(
                IElasticRouter.ExactInputSingleParams({
                    tokenIn: h.path[0],
                    tokenOut: h.path[1],
                    fee: fee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: h.amountIn,
                    minAmountOut: 0,
                    limitSqrtP: 0
                })
            );
        } else {
            amountOut = IElasticRouter(h.addr).swapExactInput(
                IElasticRouter.ExactInputParams({
                    path: getKyberPath(h.path, convertPoolDataList(h.poolDataList)),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: h.amountIn,
                    minAmountOut: 0
                })
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IPool} from "../interfaces/mantis-swap/IPool.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibMantisSwap {
    using LibAsset for address;

    function swapMantis(Hop memory h) internal returns (uint256 amountOut) {
        uint256 l = h.path.length;
        for (uint256 i = 0; i < l - 1; ) {
            uint256 amountIn = i == 0 ? h.amountIn : amountOut;
            h.path[i].approve(h.addr, amountIn);
            IPool(h.addr).swap(h.path[i], h.path[i + 1], address(this), amountIn, 0, block.timestamp);
            amountOut = h.path[i + 1].getBalance();

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IPlatypusRouter01} from "../interfaces/platypus/IPlatypusRouter01.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibPlatypus {
    using LibAsset for address;

    function getPoolAddress(bytes memory poolData) private pure returns (address poolAddress) {
        assembly {
            poolAddress := shr(96, mload(add(poolData, 32)))
        }
    }

    function getPoolAddresses(bytes[] memory poolDataList) private pure returns (address[] memory poolAddresses) {
        uint256 pdl = poolDataList.length;
        poolAddresses = new address[](pdl);

        for (uint256 i = 0; i < pdl; ) {
            poolAddresses[i] = getPoolAddress(poolDataList[i]);
            unchecked {
                i++;
            }
        }
    }

    function swapPlatypus(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);
        (amountOut, ) = IPlatypusRouter01(h.addr).swapTokensForTokens(
            h.path,
            getPoolAddresses(h.poolDataList),
            h.amountIn,
            0,
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISwap} from "../interfaces/saddle/ISwap.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibSaddle {
    using LibAsset for address;

    function getPoolAddress(bytes memory poolData) private pure returns (address poolAddress) {
        assembly {
            poolAddress := shr(96, mload(add(poolData, 32)))
        }
    }

    function swapSaddle(Hop memory h) internal returns (uint256 amountOut) {
        uint256 i;
        uint256 l = h.path.length;

        for (i = 0; i < l - 1; ) {
            address poolAddress = getPoolAddress(h.poolDataList[i]);
            h.path[i].approve(poolAddress, i == 0 ? h.amountIn : amountOut);
            uint8 tokenIndexFrom = ISwap(poolAddress).getTokenIndex(h.path[i]);
            uint8 tokenIndexTo = ISwap(poolAddress).getTokenIndex(h.path[i + 1]);
            amountOut = ISwap(poolAddress).swap(
                tokenIndexFrom,
                tokenIndexTo,
                i == 0 ? h.amountIn : amountOut,
                0,
                block.timestamp
            );

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IRouter} from "../interfaces/solidly/IRouter.sol";
import {IRouterV2} from "../interfaces/solidly/IRouterV2.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibSolidly {
    using LibAsset for address;

    function getRoute(address[] memory path, bool stable) private pure returns (IRouter.Route[] memory routes) {
        uint256 pl = path.length;
        routes = new IRouter.Route[](pl - 1);
        for (uint256 i = 0; i < pl - 1; ) {
            routes[i] = IRouter.Route({from: path[i], to: path[i + 1], stable: stable});

            unchecked {
                i++;
            }
        }
    }

    function getRouteV2(
        address[] memory path,
        bool stable,
        bytes[] memory poolDataList
    ) private pure returns (IRouterV2.Route[] memory routes) {
        uint256 pl = path.length;
        routes = new IRouterV2.Route[](pl - 1);
        for (uint256 i = 0; i < pl - 1; ) {
            bytes memory poolData = poolDataList[i];
            address factoryAddress;

            assembly {
                factoryAddress := shr(96, mload(add(poolData, 32)))
            }

            routes[i] = IRouterV2.Route({from: path[i], to: path[i + 1], stable: stable, factory: factoryAddress});

            unchecked {
                i++;
            }
        }
    }

    function swapSolidlyStable(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);

        uint256[] memory amountOuts = h.poolDataList.length == 0
            ? IRouter(h.addr).swapExactTokensForTokens(
                h.amountIn,
                0,
                getRoute(h.path, true),
                address(this),
                block.timestamp
            )
            : IRouterV2(h.addr).swapExactTokensForTokens(
                h.amountIn,
                0,
                getRouteV2(h.path, true, h.poolDataList),
                address(this),
                block.timestamp
            );

        amountOut = amountOuts[amountOuts.length - 1];
    }

    function swapSolidlyVolatile(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);

        uint256[] memory amountOuts = h.poolDataList.length == 0
            ? IRouter(h.addr).swapExactTokensForTokens(
                h.amountIn,
                0,
                getRoute(h.path, false),
                address(this),
                block.timestamp
            )
            : IRouterV2(h.addr).swapExactTokensForTokens(
                h.amountIn,
                0,
                getRouteV2(h.path, false, h.poolDataList),
                address(this),
                block.timestamp
            );

        amountOut = amountOuts[amountOuts.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import {ILBRouter} from "../interfaces/traderJoe-v2-1/ILBRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibTraderJoeV2_1 {
    using LibAsset for address;

    function getPairBinStep(bytes memory poolData) private pure returns (uint256 pairBinStep) {
        assembly {
            pairBinStep := mload(add(poolData, 32))
        }
    }

    function getPairBinSteps(bytes[] memory poolDataList) private pure returns (uint256[] memory pairBinSteps) {
        uint256 pdl = poolDataList.length;
        pairBinSteps = new uint256[](pdl);

        for (uint256 i = 0; i < pdl; ) {
            pairBinSteps[i] = getPairBinStep(poolDataList[i]);
            unchecked {
                i++;
            }
        }
    }

    function getTokens(address[] memory path) private pure returns (IERC20[] memory tokens) {
        uint256 l = path.length;
        tokens = new IERC20[](l);
        for (uint256 i = 0; i < l; ) {
            tokens[i] = IERC20(path[i]);
            unchecked {
                i++;
            }
        }
    }

    function getVersions(address[] memory path) private pure returns (ILBRouter.Version[] memory versions) {
        uint256 l = path.length - 1;
        versions = new ILBRouter.Version[](l);
        for (uint256 i = 0; i < l; ) {
            versions[i] = ILBRouter.Version.V2_1;
            unchecked {
                i++;
            }
        }
    }

    function swapTraderJoeV2_1(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);
        amountOut = ILBRouter(h.addr).swapExactTokensForTokens(
            h.amountIn,
            0,
            ILBRouter.Path({
                pairBinSteps: getPairBinSteps(h.poolDataList),
                versions: getVersions(h.path),
                tokenPath: getTokens(h.path)
            }),
            h.recipient,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ITridentPool} from "../interfaces/trident/ITridentPool.sol";
import {ITridentBentoBoxV1} from "../interfaces/trident/ITridentBentoBoxV1.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

error TridentInvalidLengthsOfArrays();

library LibTrident {
    using LibAsset for address;

    function getPoolAddress(bytes memory poolData) private pure returns (address poolAddress) {
        assembly {
            poolAddress := shr(96, mload(add(poolData, 32)))
        }
    }

    function swapTrident(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].transfer(h.addr, h.amountIn);

        uint256 pl = h.path.length;
        for (uint256 i = 0; i < pl - 1; ) {
            address poolAddress = getPoolAddress(h.poolDataList[i]);
            bool isLast = i == pl - 2;

            if (i == 0) {
                ITridentBentoBoxV1(h.addr).deposit(h.path[i], h.addr, poolAddress, h.amountIn, 0);
            }

            amountOut = ITridentPool(poolAddress).swap(
                abi.encode(h.path[i], isLast ? address(this) : getPoolAddress(h.poolDataList[i + 1]), isLast)
            );

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IUniswapV2Router} from "../interfaces/uniswap-v2/IUniswapV2Router.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibUniswapV2 {
    using LibAsset for address;

    function swapUniswapV2(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);

        uint256[] memory amountOuts = IUniswapV2Router(h.addr).swapExactTokensForTokens(
            h.amountIn,
            0,
            h.path,
            address(this),
            block.timestamp + 1
        );

        amountOut = amountOuts[amountOuts.length - 1];
    }

    function swapUniswapV2Withfee(Hop memory h) internal returns (uint256 amountOut) {
        uint256 l = h.path.length;
        h.path[0].approve(h.addr, h.amountIn);

        IUniswapV2Router(h.addr).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            h.amountIn,
            0,
            h.path,
            address(this),
            block.timestamp + 1
        );

        amountOut = h.path[l - 1].getBalance();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IUniswapV3RouterV1} from "../interfaces/uniswap-v3/IUniswapV3RouterV1.sol";
import {IUniswapV3RouterV2} from "../interfaces/uniswap-v3/IUniswapV3RouterV2.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

error UniswapV3InvalidLengthsOfArrays();

library LibUniswapV3 {
    using LibAsset for address;

    function getPoolData(bytes memory poolData) private pure returns (bytes32 poolDataBytes32) {
        assembly {
            poolDataBytes32 := mload(add(poolData, 32))
        }
    }

    function convertPoolDataList(
        bytes[] memory poolDataList
    ) private pure returns (bytes32[] memory poolDataListBytes32) {
        uint256 l = poolDataList.length;
        poolDataListBytes32 = new bytes32[](l);
        for (uint256 i = 0; i < l; ) {
            poolDataListBytes32[i] = getPoolData(poolDataList[i]);
            unchecked {
                i++;
            }
        }
    }

    function getUniswapV3Path(
        address[] memory path,
        bytes32[] memory poolDataList
    ) private pure returns (bytes memory) {
        bytes memory payload;
        uint256 pl = path.length;
        uint256 pdl = poolDataList.length;

        if (pl - 1 != pdl) {
            revert UniswapV3InvalidLengthsOfArrays();
        }

        assembly {
            payload := mload(0x40)
            let i := 0
            let payloadPosition := add(payload, 32)
            let pathPosition := add(path, 32)
            let poolDataPosition := add(poolDataList, 32)

            for {

            } lt(i, pl) {
                i := add(i, 1)
                pathPosition := add(pathPosition, 32)
            } {
                mstore(payloadPosition, shl(96, mload(pathPosition)))
                payloadPosition := add(payloadPosition, 20)

                if lt(i, pdl) {
                    mstore(payloadPosition, mload(poolDataPosition))
                    payloadPosition := add(payloadPosition, 3)
                    poolDataPosition := add(poolDataPosition, 32)
                }
            }

            mstore(payload, sub(sub(payloadPosition, payload), 32))
            mstore(0x40, and(add(payloadPosition, 31), not(31)))
        }

        return payload;
    }

    function swapUniswapV3V1(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);
        if (h.path.length == 2) {
            bytes memory poolData = h.poolDataList[0];
            uint24 fee;

            assembly {
                fee := shr(232, mload(add(poolData, 32)))
            }

            amountOut = IUniswapV3RouterV1(h.addr).exactInputSingle(
                IUniswapV3RouterV1.ExactInputSingleParams({
                    tokenIn: h.path[0],
                    tokenOut: h.path[1],
                    fee: fee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: h.amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        } else {
            amountOut = IUniswapV3RouterV1(h.addr).exactInput(
                IUniswapV3RouterV1.ExactInputParams({
                    path: getUniswapV3Path(h.path, convertPoolDataList(h.poolDataList)),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: h.amountIn,
                    amountOutMinimum: 0
                })
            );
        }
    }

    function swapUniswapV3V2(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);
        if (h.path.length == 2) {
            bytes memory poolData = h.poolDataList[0];
            uint24 fee;

            assembly {
                fee := shr(232, mload(add(poolData, 32)))
            }

            amountOut = IUniswapV3RouterV2(h.addr).exactInputSingle(
                IUniswapV3RouterV2.ExactInputSingleParams({
                    tokenIn: h.path[0],
                    tokenOut: h.path[1],
                    fee: fee,
                    recipient: address(this),
                    amountIn: h.amountIn,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        } else {
            amountOut = IUniswapV3RouterV2(h.addr).exactInput(
                IUniswapV3RouterV2.ExactInputParams({
                    path: getUniswapV3Path(h.path, convertPoolDataList(h.poolDataList)),
                    recipient: address(this),
                    amountIn: h.amountIn,
                    amountOutMinimum: 0
                })
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IWombatRouter} from "../interfaces/wombat/IWombatRouter.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibWombat {
    using LibAsset for address;

    function getPoolAddress(bytes memory poolData) private pure returns (address poolAddress) {
        assembly {
            poolAddress := shr(96, mload(add(poolData, 32)))
        }
    }

    function getPoolAddresses(bytes[] memory poolDataList) private pure returns (address[] memory poolAddresses) {
        uint256 pdl = poolDataList.length;
        poolAddresses = new address[](pdl);

        for (uint256 i = 0; i < pdl; ) {
            poolAddresses[i] = getPoolAddress(poolDataList[i]);
            unchecked {
                i++;
            }
        }
    }

    function swapWombat(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].approve(h.addr, h.amountIn);
        amountOut = IWombatRouter(h.addr).swapExactTokensForTokens(
            h.path,
            getPoolAddresses(h.poolDataList),
            h.amountIn,
            0,
            address(this),
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IWooPPV2} from "../interfaces/woofi/IWooPPV2.sol";
import {LibAsset} from "../libraries/LibAsset.sol";
import {Hop} from "./LibHop.sol";

library LibWooFi {
    using LibAsset for address;

    function swapWooFi(Hop memory h) internal returns (uint256 amountOut) {
        h.path[0].transfer(h.addr, h.amountIn);

        uint256 pl = h.path.length;
        for (uint256 i = 0; i < pl - 1; ) {
            amountOut = IWooPPV2(h.addr).swap(
                h.path[i],
                h.path[i + 1],
                i == 0 ? h.amountIn : amountOut,
                0,
                i == pl - 2 ? address(this) : h.addr,
                msg.sender
            );

            unchecked {
                i++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AppStorage} from "../../libraries/LibMagpieRouter.sol";
import {IRouter1} from "../interfaces/IRouter1.sol";
import {LibBalancerV2} from "../LibBalancerV2.sol";
import {Hop} from "../LibHop.sol";
import {LibAlgebra} from "../LibAlgebra.sol";
import {LibCurve} from "../LibCurve.sol";
import {LibDodoV2} from "../LibDodoV2.sol";
import {LibGmx} from "../LibGmx.sol";
import {LibHashflow} from "../LibHashflow.sol";
import {LibIntegralSize} from "../LibIntegralSize.sol";
import {LibKyberSwapClassic} from "../LibKyberSwapClassic.sol";
import {LibKyberSwapElastic} from "../LibKyberSwapElastic.sol";
import {LibTrident} from "../LibTrident.sol";
import {LibUniswapV2} from "../LibUniswapV2.sol";
import {LibUniswapV3} from "../LibUniswapV3.sol";
import {LibWooFi} from "../LibWooFi.sol";
import {LibSaddle} from "../LibSaddle.sol";
import {LibWombat} from "../LibWombat.sol";
import {LibSolidly} from "../LibSolidly.sol";
import {LibPlatypus} from "../LibPlatypus.sol";
import {LibKokonutSwap} from "../LibKokonutSwap.sol";
import {LibCamelot} from "../LibCamelot.sol";
import {LibMantisSwap} from "../LibMantisSwap.sol";
import {LibTraderJoeV2_1} from "../LibTraderJoeV2_1.sol";
import {LibAaveV2} from "../LibAaveV2.sol";

contract Router1Facet is IRouter1 {
    AppStorage internal s;

    function swapBalancerV2(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibBalancerV2.swapBalancerV2(h);
    }

    function swapCurve(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibCurve.swapCurve(h);
    }

    function swapDodoV2(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibDodoV2.swapDodoV2(h);
    }

    function swapGmx(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibGmx.swapGmx(h);
    }

    function swapHashflow(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibHashflow.swapHashflow(h);
    }

    function swapIntegralSize(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibIntegralSize.swapIntegralSize(h);
    }

    function swapKyberClassic(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibKyberSwapClassic.swapKyberClassic(h);
    }

    function swapKyberElastic(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibKyberSwapElastic.swapKyberElastic(h);
    }

    function swapTrident(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibTrident.swapTrident(h);
    }

    function swapUniswapV2(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibUniswapV2.swapUniswapV2(h);
    }

    function swapUniswapV3V1(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibUniswapV3.swapUniswapV3V1(h);
    }

    function swapUniswapV3V2(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibUniswapV3.swapUniswapV3V2(h);
    }

    function swapWooFi(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibWooFi.swapWooFi(h);
    }

    function swapAlgebra(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibAlgebra.swapAlgebra(h);
    }

    function swapSaddle(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibSaddle.swapSaddle(h);
    }

    function swapWombat(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibWombat.swapWombat(h);
    }

    function swapSolidlyStable(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibSolidly.swapSolidlyStable(h);
    }

    function swapSolidlyVolatile(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibSolidly.swapSolidlyVolatile(h);
    }

    function swapPlatypus(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibPlatypus.swapPlatypus(h);
    }

    function swapKokonutBase(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibKokonutSwap.swapKokonutBase(h);
    }

    function swapKokonutCrypto(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibKokonutSwap.swapKokonutCrypto(h);
    }

    function swapKokonutMeta(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibKokonutSwap.swapKokonutMeta(h);
    }

    function swapCamelot(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibCamelot.swapCamelot(h);
    }

    function swapMantis(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibMantisSwap.swapMantis(h);
    }

    function swapTraderJoeV2_1(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibTraderJoeV2_1.swapTraderJoeV2_1(h);
    }

    function swapAaveV2(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibAaveV2.swapAaveV2(h);
    }

    function swapUniswapV2Withfee(Hop calldata h) external payable returns (uint256 amountOut) {
        return LibUniswapV2.swapUniswapV2Withfee(h);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Hop} from "../LibHop.sol";

interface IRouter1 {
    function swapBalancerV2(Hop calldata h) external payable returns (uint256 amountOut);

    function swapCurve(Hop calldata h) external payable returns (uint256 amountOut);

    function swapDodoV2(Hop calldata h) external payable returns (uint256 amountOut);

    function swapGmx(Hop calldata h) external payable returns (uint256 amountOut);

    function swapHashflow(Hop calldata h) external payable returns (uint256 amountOut);

    function swapIntegralSize(Hop calldata h) external payable returns (uint256 amountOut);

    function swapKyberClassic(Hop calldata h) external payable returns (uint256 amountOut);

    function swapKyberElastic(Hop memory h) external payable returns (uint256 amountOut);

    function swapTrident(Hop calldata h) external payable returns (uint256 amountOut);

    function swapUniswapV2(Hop calldata h) external payable returns (uint256 amountOut);

    function swapUniswapV3V1(Hop calldata h) external payable returns (uint256 amountOut);

    function swapUniswapV3V2(Hop calldata h) external payable returns (uint256 amountOut);

    function swapWooFi(Hop calldata h) external payable returns (uint256 amountOut);

    function swapAlgebra(Hop calldata h) external payable returns (uint256 amountOut);

    function swapSaddle(Hop calldata h) external payable returns (uint256 amountOut);

    function swapWombat(Hop calldata h) external payable returns (uint256 amountOut);

    function swapSolidlyStable(Hop calldata h) external payable returns (uint256 amountOut);

    function swapSolidlyVolatile(Hop calldata h) external payable returns (uint256 amountOut);

    function swapPlatypus(Hop calldata h) external payable returns (uint256 amountOut);

    function swapKokonutBase(Hop calldata h) external payable returns (uint256 amountOut);

    function swapKokonutCrypto(Hop calldata h) external payable returns (uint256 amountOut);

    function swapKokonutMeta(Hop calldata h) external payable returns (uint256 amountOut);

    function swapCamelot(Hop calldata h) external payable returns (uint256 amountOut);

    function swapMantis(Hop calldata h) external payable returns (uint256 amountOut);

    function swapTraderJoeV2_1(Hop calldata h) external payable returns (uint256 amountOut);

    function swapAaveV2(Hop calldata h) external payable returns (uint256 amountOut);

    function swapUniswapV2Withfee(Hop calldata h) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}