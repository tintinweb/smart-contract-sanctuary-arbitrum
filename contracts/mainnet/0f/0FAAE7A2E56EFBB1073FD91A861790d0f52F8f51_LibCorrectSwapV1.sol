// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import {ISwapRouter} from "ISwapRouter.sol";
import {ISyncSwapRouter} from "ISyncSwapRouter.sol";
import {IMuteRouter} from "IMuteRouter.sol";
import {IStableSwap} from "IStableSwap.sol";

contract LibCorrectSwapV1 {
    // Exact search for supported function signatures
    bytes4 private constant _FUNC1 =
        bytes4(
            keccak256(
                "swapExactETHForTokens(uint256,address[],address,uint256)"
            )
        );
    bytes4 private constant _FUNC2 =
        bytes4(
            keccak256(
                "swapExactAVAXForTokens(uint256,address[],address,uint256)"
                "swapExactAVAXForTokens(uint256,address[],address,uint256)"
            )
        );
    bytes4 private constant _FUNC3 =
        bytes4(
            keccak256(
                "swapExactTokensForETH(uint256,uint256,address[],address,uint256)"
            )
        );
    bytes4 private constant _FUNC4 =
        bytes4(
            keccak256(
                "swapExactTokensForAVAX(uint256,uint256,address[],address,uint256)"
            )
        );
    bytes4 private constant _FUNC5 =
        bytes4(
            keccak256(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"
            )
        );
    bytes4 private constant _FUNC6 = ISwapRouter.exactInput.selector;

    bytes4 private constant _FUNC7 = ISyncSwapRouter.swap.selector;

    bytes4 private constant _FUNC8 = IMuteRouter.swapExactETHForTokens.selector;

    bytes4 private constant _FUNC9 = IMuteRouter.swapExactTokensForETH.selector;

    bytes4 private constant _FUNC10 =
        IMuteRouter.swapExactTokensForTokens.selector;

    bytes4 private constant _FUNC11 = IStableSwap.swapExact.selector;

    //---------------------------------------------------------------------------
    // External Method

    // @dev Correct input of destination chain swapData
    function correctSwap(bytes calldata _data, uint256 _amount)
        external
        view
        returns (bytes memory)
    {
        bytes4 sig = bytes4(_data[:4]);
        if (sig == _FUNC1) {
            return _data;
        } else if (sig == _FUNC2) {
            return _data;
        } else if (sig == _FUNC3) {
            return tryBasicCorrectSwap(_data, _amount);
        } else if (sig == _FUNC4) {
            return tryBasicCorrectSwap(_data, _amount);
        } else if (sig == _FUNC5) {
            return tryBasicCorrectSwap(_data, _amount);
        } else if (sig == _FUNC6) {
            return tryExactInput(_data, _amount);
        } else if (sig == _FUNC7) {
            return trySyncSwap(_data, _amount);
        } else if (sig == _FUNC8) {
            return _data;
        } else if (sig == _FUNC9) {
            return tryMuteSwap(_data, _amount);
        } else if (sig == _FUNC10) {
            return tryMuteSwap(_data, _amount);
        } else if (sig == _FUNC11) {
            return tryConnextSwap(_data, _amount);
        }

        // fuzzy matching
        return tryBasicCorrectSwap(_data, _amount);
    }

    function tryBasicCorrectSwap(bytes calldata _data, uint256 _amount)
        public
        view
        returns (bytes memory)
    {
        try this.basicCorrectSwap(_data, _amount) returns (
            bytes memory _result
        ) {
            return _result;
        } catch {
            revert("basicCorrectSwap fail!");
        }
    }

    function basicCorrectSwap(bytes calldata _data, uint256 _amount)
        external
        pure
        returns (bytes memory)
    {
        (
            ,
            uint256 _amountOutMin,
            address[] memory _path,
            address _to,
            uint256 _deadline
        ) = abi.decode(
                _data[4:],
                (uint256, uint256, address[], address, uint256)
            );

        return
            abi.encodeWithSelector(
                bytes4(_data[:4]),
                _amount,
                _amountOutMin,
                _path,
                _to,
                _deadline
            );
    }

    function tryExactInput(bytes calldata _data, uint256 _amount)
        public
        view
        returns (bytes memory)
    {
        try this.exactInput(_data, _amount) returns (bytes memory _result) {
            return _result;
        } catch {
            revert("exactInput fail!");
        }
    }

    function exactInput(bytes calldata _data, uint256 _amount)
        external
        pure
        returns (bytes memory)
    {
        ISwapRouter.ExactInputParams memory params = abi.decode(
            _data[4:],
            (ISwapRouter.ExactInputParams)
        );
        params.amountIn = _amount;

        return abi.encodeWithSelector(bytes4(_data[:4]), params);
    }

    function trySyncSwap(bytes calldata _data, uint256 _amount)
        public
        view
        returns (bytes memory)
    {
        try this.syncSwap(_data, _amount) returns (bytes memory _result) {
            return _result;
        } catch {
            revert("syncSwap fail!");
        }
    }

    function syncSwap(bytes calldata _data, uint256 _amount)
        external
        pure
        returns (bytes memory)
    {
        (
            ISyncSwapRouter.SwapPath[] memory paths,
            uint256 amountOutMin,
            uint256 deadline
        ) = abi.decode(
                _data[4:],
                (ISyncSwapRouter.SwapPath[], uint256, uint256)
            );

        uint256 fromAmountSum;
        for (uint256 i = 0; i < paths.length; i++) {
            fromAmountSum = fromAmountSum + paths[i].amountIn;
        }

        for (uint256 i = 0; i < paths.length; i++) {
            paths[i].amountIn = (_amount * paths[i].amountIn) / fromAmountSum;
        }

        return
            abi.encodeWithSelector(
                bytes4(_data[:4]),
                paths,
                amountOutMin,
                deadline
            );
    }

    function tryMuteSwap(bytes calldata _data, uint256 _amount)
        public
        view
        returns (bytes memory)
    {
        try this.muteSwap(_data, _amount) returns (bytes memory _result) {
            return _result;
        } catch {
            revert("muteSwap fail!");
        }
    }

    function muteSwap(bytes calldata _data, uint256 _amount)
        external
        pure
        returns (bytes memory)
    {
        (
            ,
            uint256 _amountOutMin,
            address[] memory _path,
            address _to,
            uint256 _deadline,
            bool[] memory _stable
        ) = abi.decode(
                _data[4:],
                (uint256, uint256, address[], address, uint256, bool[])
            );

        return
            abi.encodeWithSelector(
                bytes4(_data[:4]),
                _amount,
                _amountOutMin,
                _path,
                _to,
                _deadline,
                _stable
            );
    }

    function tryConnextSwap(bytes calldata _data, uint256 _amount)
        public
        view
        returns (bytes memory)
    {
        try this.connextSwap(_data, _amount) returns (bytes memory _result) {
            return _result;
        } catch {
            revert("connextSwap fail!");
        }
    }

    function connextSwap(bytes calldata _data, uint256 _amount)
        external
        pure
        returns (bytes memory)
    {
        (
            bytes32 _key,
            ,
            address _assetIn,
            address _assetOut,
            uint256 _minAmountOut,
            uint256 _deadline
        ) = abi.decode(
                _data[4:],
                (bytes32, uint256, address, address, uint256, uint256)
            );

        return
            abi.encodeWithSelector(
                bytes4(_data[:4]),
                _key,
                _amount,
                _assetIn,
                _assetOut,
                _minAmountOut,
                _deadline
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    function WETH9() external view returns (address);

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
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

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
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2;

interface ISyncSwapRouter {
    // The Router contract has Multicall and SelfPermit enabled.

    struct TokenInput {
        address token;
        uint256 amount;
    }

    struct SwapStep {
        address pool; // The pool of the step.
        bytes data; // The data to execute swap with the pool.
        address callback;
        bytes callbackData;
    }

    struct SwapPath {
        SwapStep[] steps; // Steps of the path.
        address tokenIn; // The input token of the path.
        uint256 amountIn; // The input token amount of the path.
    }

    struct SplitPermitParams {
        address token;
        uint256 approveAmount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ArrayPermitParams {
        uint256 approveAmount;
        uint256 deadline;
        bytes signature;
    }

    // Returns the vault address.
    function vault() external view returns (address);

    // Returns the wETH address.
    function wETH() external view returns (address);

    // Performs a swap.
    function swap(
        SwapPath[] memory paths,
        uint256 amountOutMin,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapWithPermit(
        SwapPath[] memory paths,
        uint256 amountOutMin,
        uint256 deadline,
        SplitPermitParams calldata permit
    ) external payable returns (uint256 amountOut);

    /// @notice Wrapper function to allow pool deployment to be batched.
    function createPool(address factory, bytes calldata data)
        external
        payable
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMuteRouter {
    function WETH() external view returns (address);

    function factory() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        uint256 feeType,
        bool stable
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        uint256 feeType,
        bool stable
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool stable
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool stable
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool stable
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool[] calldata stable
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool[] calldata stable
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool[] calldata stable
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool[] calldata stable
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool[] calldata stable
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        bool[] calldata stable
    ) external;

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    )
        external
        view
        returns (
            uint256 amountOut,
            bool stable,
            uint256 fee
        );

    function getAmountsOutExpanded(uint256 amountIn, address[] calldata path)
        external
        view
        returns (
            uint256[] memory amounts,
            bool[] memory stable,
            uint256[] memory fees
        );

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path,
        bool[] calldata stable
    )
        external
        view
        returns (
            uint256[] memory amounts,
            bool[] memory _stable,
            uint256[] memory fees
        );

    function getPairInfo(address[] calldata path, bool stable)
        external
        view
        returns (
            address tokenA,
            address tokenB,
            address pair,
            uint256 reserveA,
            uint256 reserveB,
            uint256 fee
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IERC20} from "IERC20.sol";

interface IStableSwap {
    /*** EVENTS ***/

    // events replicated from SwapUtils to make the ABI easier for dumb
    // clients
    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );
    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );
    event NewAdminFee(uint256 newAdminFee);
    event NewSwapFee(uint256 newSwapFee);
    event NewWithdrawFee(uint256 newWithdrawFee);
    event RampA(
        uint256 oldA,
        uint256 newA,
        uint256 initialTime,
        uint256 futureTime
    );
    event StopRampA(uint256 currentA, uint256 time);

    function swap(
        bytes32 key,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function swapExact(
        bytes32 key,
        uint256 amountIn,
        address assetIn,
        address assetOut,
        uint256 minAmountOut,
        uint256 deadline
    ) external payable returns (uint256);

    function swapExactOut(
        bytes32 key,
        uint256 amountOut,
        address assetIn,
        address assetOut,
        uint256 maxAmountIn,
        uint256 deadline
    ) external payable returns (uint256);

    function getA(bytes32 key) external view returns (uint256);

    function getToken(bytes32 key, uint8 index) external view returns (IERC20);

    function getTokenIndex(bytes32 key, address tokenAddress)
        external
        view
        returns (uint8);

    function getTokenBalance(bytes32 key, uint8 index)
        external
        view
        returns (uint256);

    function getVirtualPrice(bytes32 key) external view returns (uint256);

    // min return calculation functions
    function calculateSwap(
        bytes32 key,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateSwapOut(
        bytes32 key,
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dy
    ) external view returns (uint256);

    function calculateSwapFromAddress(
        bytes32 key,
        address assetIn,
        address assetOut,
        uint256 amountIn
    ) external view returns (uint256);

    function calculateSwapOutFromAddress(
        bytes32 key,
        address assetIn,
        address assetOut,
        uint256 amountOut
    ) external view returns (uint256);

    function calculateTokenAmount(
        bytes32 key,
        uint256[] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    function calculateRemoveLiquidity(bytes32 key, uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        bytes32 key,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    // state modifying functions
    function initialize(
        IERC20[] memory pooledTokens,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 a,
        uint256 fee,
        uint256 adminFee,
        address lpTokenTargetAddress
    ) external;

    function addLiquidity(
        bytes32 key,
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        bytes32 key,
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        bytes32 key,
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        bytes32 key,
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}