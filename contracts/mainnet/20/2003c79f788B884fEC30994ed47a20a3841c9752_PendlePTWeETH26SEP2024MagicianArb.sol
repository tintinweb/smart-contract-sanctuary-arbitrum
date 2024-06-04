// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
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
pragma solidity >=0.7.6 <0.9.0;

/// @notice Extension for the Liquidation helper to support such operations as unwrapping
interface IMagician {
    /// @notice Operates to unwrap an `_asset`
    /// @param _asset Asset to be unwrapped
    /// @param _amount Amount of the `_asset`
    /// @return tokenOut A token that the `_asset` has been converted to
    /// @return amountOut Amount of the `tokenOut` that we received
    function towardsNative(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut);

    /// @notice Performs operation opposit to `towardsNative`
    /// @param _asset Asset to be wrapped
    /// @param _amount Amount of the `_asset`
    /// @return tokenOut A token that the `_asset` has been converted to
    /// @return amountOut Amount of the quote token that we spent to get `_amoun` of the `_asset`
    function towardsAsset(address _asset, uint256 _amount) external returns (address tokenOut, uint256 amountOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./IStandardizedYield.sol";
import "./IPPrincipalToken.sol";
import "./IPYieldToken.sol";

// solhint-disable var-name-mixedcase

interface IPMarket {
    function swapExactPtForSy(
        address receiver,
        uint256 exactPtIn,
        bytes calldata data
    ) external returns (uint256 netSyOut, uint256 netSyFee);

    function swapSyForExactPt(
        address receiver,
        uint256 exactPtOut,
        bytes calldata data
    ) external returns (uint256 netSyIn, uint256 netSyFee);

    function readTokens()
        external
        view
        returns (IStandardizedYield _SY, IPPrincipalToken _PT, IPYieldToken _YT);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IPPrincipalToken {
    function transfer(address user, uint256 amount) external;
    function isExpired() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IPYieldToken {
    function redeemPY(address receiver) external returns (uint256 amountSyOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

interface IStandardizedYield {
    function redeem(
        address receiver,
        uint256 amountSharesToRedeem,
        address tokenOut,
        uint256 minTokenOut,
        bool burnFromInternalBalance
    ) external returns (uint256 amountTokenOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IStandardizedYield.sol";
import "./interfaces/IPPrincipalToken.sol";
import "./interfaces/IPYieldToken.sol";
import "./interfaces/IPMarket.sol";

abstract contract PendleMagician {
    // solhint-disable
    address public immutable PENDLE_TOKEN;
    address public immutable PENDLE_MARKET;
    // solhint-enable

    bytes internal constant _EMPTY_BYTES = abi.encode();

    error InvalidAsset();
    error Unsupported();

    constructor(address _asset, address _market) {
        PENDLE_TOKEN = _asset;
        PENDLE_MARKET = _market;
    }

    function _sellPtForUnderlying(uint256 _netPtIn, address _tokenOut) internal returns (uint256 netTokenOut) {
        // solhint-disable-next-line var-name-mixedcase
        (IStandardizedYield SY, IPPrincipalToken PT, IPYieldToken YT) = IPMarket(PENDLE_MARKET)
            .readTokens();

        uint256 netSyOut;
        if (PT.isExpired()) {
            PT.transfer(address(YT), _netPtIn);
            netSyOut = YT.redeemPY(address(SY));
        } else {
            // safeTransfer not required
            PT.transfer(PENDLE_MARKET, _netPtIn);
            (netSyOut, ) = IPMarket(PENDLE_MARKET).swapExactPtForSy(
                address(SY), // better gas optimization to transfer SY directly to itself and burn
                _netPtIn,
                _EMPTY_BYTES
            );
        }

        // solhint-disable-next-line func-named-parameters
        netTokenOut = SY.redeem(address(this), netSyOut, _tokenOut, 0, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "../interfaces/IMagician.sol";
import "./PendleUniswapMagician.sol";

contract PendlePTWeETH26SEP2024MagicianArb is PendleUniswapMagician {
    address public constant WEETH = 0x35751007a407ca6FEFfE80b3cB397736D2cf4dbe;
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    constructor() PendleUniswapMagician(
        0xE592427A0AEce92De3Edee1F18E0157C05861564, // Uniswap router
        100, // fee
        0xb8b0a120F6A68Dd06209619F62429fB1a8e92feC, // PT Token
        0xf9F9779d8fF604732EBA9AD345E6A27EF5c2a9d6  // PT Market
    ) {}

    function _fromToken() internal pure override returns (address) {
        return WEETH;
    }

    function _toToken() internal pure override returns (address) {
        return WETH;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "../interfaces/IMagician.sol";
import "./PendleMagician.sol";

abstract contract PendleUniswapMagician is PendleMagician, IMagician {
    // solhint-disable var-name-mixedcase
    ISwapRouter public immutable UNISWAP_ROUTER;
    uint24 public immutable FEE;
    // solhint-enable var-name-mixedcase

    constructor(
        address _router,
        uint24 _fee,
        address _ptToken,
        address _ptMarket
    ) PendleMagician(_ptToken, _ptMarket) {
        UNISWAP_ROUTER = ISwapRouter(_router);
        FEE = _fee;
    }

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _amount) external returns (address asset, uint256 amount) {
        if (_asset != address(PENDLE_TOKEN)) revert InvalidAsset();

        asset = _toToken();
        uint256 amountWeeth = _sellPtForUnderlying(_amount, _fromToken());

        IERC20(_fromToken()).approve(address(UNISWAP_ROUTER), amountWeeth);

        amount = _swapWeeth(amountWeeth);
    }

    /// @inheritdoc IMagician
    function towardsAsset(address, uint256) external pure returns (address, uint256) {
        revert Unsupported();
    }

    function _swapWeeth(uint256 _amountIn) internal returns (uint256 amountOut) {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _fromToken(),
            tokenOut: _toToken(),
            fee: FEE,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: 1,
            sqrtPriceLimitX96: 0
        });

        return UNISWAP_ROUTER.exactInputSingle(params);
    }

    function _fromToken() internal pure virtual returns (address) {}
    
    function _toToken() internal pure virtual returns (address) {}
}