// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IImmutableState {
    /// @return Returns the address of the Uniswap V2 factory
    function factoryV2() external view returns (address);

    /// @return Returns the address of Uniswap V3 NFT position manager
    function positionManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol';

/// @title Periphery Payments Extended
/// @notice Functions to ease deposits and withdrawals of ETH and tokens
interface IPeripheryPaymentsExtended is IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to msg.sender as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    function unwrapWETH9(uint256 amountMinimum) external payable;

    /// @notice Wraps the contract's ETH balance into WETH9
    /// @dev The resulting WETH9 is custodied by the router, thus will require further distribution
    /// @param value The amount of ETH to wrap
    function wrapETH(uint256 value) external payable;

    /// @notice Transfers the full amount of a token held by this contract to msg.sender
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to msg.sender
    /// @param amountMinimum The minimum amount of token required for a transfer
    function sweepToken(address token, uint256 amountMinimum) external payable;

    /// @notice Transfers the specified amount of a token from the msg.sender to address(this)
    /// @param token The token to pull
    /// @param value The amount to pay
    function pull(address token, uint256 value) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@uniswap/v3-periphery/contracts/interfaces/IPeripheryPaymentsWithFee.sol';

import './IPeripheryPaymentsExtended.sol';

/// @title Periphery Payments With Fee Extended
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPaymentsWithFeeExtended is IPeripheryPaymentsExtended, IPeripheryPaymentsWithFee {
    /// @notice Unwraps the contract's WETH9 balance and sends it to msg.sender as ETH, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    /// @notice Transfers the full amount of a token held by this contract to msg.sender, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import './IPeripheryPayments.sol';

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPaymentsWithFee is IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;
}

// SPDX-License-Identifier: Apache-2.0-or-later
/*

 Copyright 2021-2023 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

// solhint-disable-next-line
pragma solidity 0.8.17;

import "./AUniswapV3NPM.sol";
import "./interfaces/IAUniswap.sol";
import "./interfaces/IEWhitelist.sol";
import "../../interfaces/IWETH9.sol";
import "../../IRigoblockV3Pool.sol";
import "../../../utils/exchanges/uniswap/v3-periphery/contracts/libraries/Path.sol";
import "../../../utils/exchanges/uniswap/ISwapRouter02/ISwapRouter02.sol";

/// @title AUniswap - Allows interactions with the Uniswap contracts.
/// @author Gabriele Rigo - <[email protected]>
// @notice We implement sweep token methods routed to uniswap router even though could be defined as virtual and not implemented,
//  because we always wrap/unwrap ETH within the pool and never accidentally send tokens to uniswap router or npm contracts.
//  This allows to avoid clasing signatures and correctly reach target address for payment methods.
contract AUniswap is IAUniswap, AUniswapV3NPM {
    using Path for bytes;

    // storage must be immutable as needs to be rutime consistent
    // 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 on public networks
    /// @inheritdoc IAUniswap
    address public immutable override uniswapRouter02;

    // 0xC36442b4a4522E871399CD717aBDD847Ab11FE88 on public networks
    /// @inheritdoc IAUniswap
    address public immutable override uniswapv3Npm;

    /// @inheritdoc IAUniswap
    address public immutable override weth;

    constructor(address newUniswapRouter02) {
        uniswapRouter02 = newUniswapRouter02;
        uniswapv3Npm = payable(ISwapRouter02(uniswapRouter02).positionManager());
        weth = payable(INonfungiblePositionManager(uniswapv3Npm).WETH9());
    }

    /*
     * UNISWAP V2 METHODS
     */
    /// @inheritdoc IAUniswap
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external override returns (uint256 amountOut) {
        address uniswapRouter = _preSwap(path[0], path[path.length - 1]);

        amountOut = ISwapRouter02(uniswapRouter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to != address(this) ? address(this) : to
        );

        // we make sure we do not clear storage
        _safeApprove(path[0], uniswapRouter, uint256(1));
    }

    /// @inheritdoc IAUniswap
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external override returns (uint256 amountIn) {
        address uniswapRouter = _preSwap(path[0], path[path.length - 1]);

        amountIn = ISwapRouter02(uniswapRouter).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to != address(this) ? address(this) : to
        );

        // we make sure we do not clear storage
        _safeApprove(path[0], uniswapRouter, uint256(1));
    }

    /*
     * UNISWAP V3 SWAP METHODS
     */
    /// @inheritdoc IAUniswap
    function exactInputSingle(ISwapRouter02.ExactInputSingleParams calldata params)
        external
        override
        returns (uint256 amountOut)
    {
        address uniswapRouter = _preSwap(params.tokenIn, params.tokenOut);

        // we swap the tokens
        amountOut = ISwapRouter02(uniswapRouter).exactInputSingle(
            IV3SwapRouter.ExactInputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: address(this), // this pool is always the recipient
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            })
        );

        // we make sure we do not clear storage
        _safeApprove(params.tokenIn, uniswapRouter, uint256(1));
    }

    /// @inheritdoc IAUniswap
    function exactInput(ISwapRouter02.ExactInputParams calldata params) external override returns (uint256 amountOut) {
        (address tokenIn, address tokenOut) = _decodePathTokens(params.path);
        address uniswapRouter = _preSwap(tokenIn, tokenOut);

        // we swap the tokens
        amountOut = ISwapRouter02(uniswapRouter).exactInput(
            IV3SwapRouter.ExactInputParams({
                path: params.path,
                recipient: address(this), // this pool is always the recipient
                amountIn: params.amountIn,
                amountOutMinimum: params.amountOutMinimum
            })
        );

        // we make sure we do not clear storage
        _safeApprove(tokenIn, uniswapRouter, uint256(1));
    }

    /// @inheritdoc IAUniswap
    function exactOutputSingle(ISwapRouter02.ExactOutputSingleParams calldata params)
        external
        override
        returns (uint256 amountIn)
    {
        address uniswapRouter = _preSwap(params.tokenIn, params.tokenOut);

        // we swap the tokens
        amountIn = ISwapRouter02(uniswapRouter).exactOutputSingle(
            IV3SwapRouter.ExactOutputSingleParams({
                tokenIn: params.tokenIn,
                tokenOut: params.tokenOut,
                fee: params.fee,
                recipient: address(this), // this pool is always the recipient
                amountOut: params.amountOut,
                amountInMaximum: params.amountInMaximum,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            })
        );

        // we make sure we do not clear storage
        _safeApprove(params.tokenIn, uniswapRouter, uint256(1));
    }

    /// @inheritdoc IAUniswap
    function exactOutput(ISwapRouter02.ExactOutputParams calldata params) external override returns (uint256 amountIn) {
        (address tokenOut, address tokenIn) = _decodePathTokens(params.path);
        address uniswapRouter = _preSwap(tokenIn, tokenOut);

        // we swap the tokens
        amountIn = ISwapRouter02(uniswapRouter).exactOutput(
            IV3SwapRouter.ExactOutputParams({
                path: params.path,
                recipient: address(this), // this pool is always the recipient
                amountOut: params.amountOut,
                amountInMaximum: params.amountInMaximum
            })
        );

        // we make sure we do not clear storage
        _safeApprove(tokenIn, uniswapRouter, uint256(1));
    }

    /*
     * UNISWAP V3 PAYMENT METHODS
     */
    /// @inheritdoc IAUniswap
    function sweepToken(address token, uint256 amountMinimum) external virtual override {}

    /// @inheritdoc IAUniswap
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external virtual override {}

    /// @inheritdoc IAUniswap
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external virtual override {}

    /// @inheritdoc IAUniswap
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external virtual override {}

    /// @inheritdoc IAUniswap
    function unwrapWETH9(uint256 amountMinimum) external override {
        IWETH9(_getWeth()).withdraw(amountMinimum);
    }

    /// @inheritdoc IAUniswap
    function unwrapWETH9(uint256 amountMinimum, address recipient) external override {
        if (recipient != address(this)) {
            recipient = address(this);
        }
        IWETH9(_getWeth()).withdraw(amountMinimum);
    }

    /// @inheritdoc IAUniswap
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external virtual override {}

    /// @inheritdoc IAUniswap
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external virtual override {}

    /// @inheritdoc IAUniswap
    function wrapETH(uint256 value) external override {
        if (value > uint256(0)) {
            IWETH9(_getWeth()).deposit{value: value}();
        }
    }

    /// @inheritdoc IAUniswap
    function refundETH() external virtual override {}

    function _safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal override {
        // 0x095ea7b3 = bytes4(keccak256(bytes("approve(address,uint256)")))
        // solhint-disable-next-line avoid-low-level-calls
        (, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, spender, value));
        // approval never fails unless rogue token
        assert(data.length == 0 || abi.decode(data, (bool)));
    }

    function _preSwap(address tokenIn, address tokenOut) private returns (address uniswapRouter) {
        _assertTokenWhitelisted(tokenOut);

        // we require target to being contract to prevent call being executed to EOA
        require(_isContract(tokenIn), "AUNISWAP_APPROVE_TARGET_NOT_CONTRACT_ERROR");
        uniswapRouter = _getUniswapRouter2();

        // we set the allowance to the uniswap router
        _safeApprove(tokenIn, uniswapRouter, type(uint256).max);
    }

    function _assertTokenWhitelisted(address token) internal view override {
        // we allow swapping to base token even if not whitelisted token
        if (token != IRigoblockV3Pool(payable(address(this))).getPool().baseToken) {
            require(IEWhitelist(address(this)).isWhitelistedToken(token), "AUNISWAP_TOKEN_NOT_WHITELISTED_ERROR");
        }
    }

    function _getUniswapNpm() internal view override returns (address) {
        return uniswapv3Npm;
    }

    function _decodePathTokens(bytes memory path) private pure returns (address tokenA, address tokenB) {
        (tokenA, tokenB, ) = path.decodeFirstPool();

        if (path.hasMultiplePools()) {
            // we skip all routes but last POP_OFFSET
            for (uint256 i = 0; i < path.numPools() - 1; i++) {
                path = path.skipToken();
            }
            (, tokenB, ) = path.decodeFirstPool();
        }
    }

    function _getUniswapRouter2() private view returns (address) {
        return uniswapRouter02;
    }

    function _getWeth() private view returns (address) {
        return weth;
    }

    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }
}

// SPDX-License-Identifier: Apache-2.0-or-later
/*

 Copyright 2021-2023 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

// solhint-disable-next-line
pragma solidity 0.8.17;

import "./interfaces/IAUniswapV3NPM.sol";
import "../../interfaces/IWETH9.sol";
import "../../../utils/exchanges/uniswap/INonfungiblePositionManager/INonfungiblePositionManager.sol";

/// @title AUniswapV3NPM - Allows interactions with the Uniswap NPM contract.
/// @author Gabriele Rigo - <[email protected]>
abstract contract AUniswapV3NPM is IAUniswapV3NPM {
    /// @inheritdoc IAUniswapV3NPM
    function mint(INonfungiblePositionManager.MintParams calldata params)
        external
        override
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        // we require both token being whitelisted
        _assertTokenWhitelisted(params.token0);
        _assertTokenWhitelisted(params.token1);
        address uniswapNpm = _getUniswapNpm();

        // we set the allowance to the uniswap position manager
        if (params.amount0Desired > 0) _safeApprove(params.token0, uniswapNpm, type(uint256).max);
        if (params.amount1Desired > 0) _safeApprove(params.token1, uniswapNpm, type(uint256).max);

        // only then do we mint the liquidity token
        (tokenId, liquidity, amount0, amount1) = INonfungiblePositionManager(uniswapNpm).mint(
            INonfungiblePositionManager.MintParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.fee,
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min,
                recipient: address(this), // this pool is always the recipient
                deadline: params.deadline
            })
        );

        // we make sure we do not clear storage
        if (params.amount0Desired > 0) _safeApprove(params.token0, uniswapNpm, uint256(1));
        if (params.amount1Desired > 0) _safeApprove(params.token1, uniswapNpm, uint256(1));
    }

    /// @inheritdoc IAUniswapV3NPM
    function increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams calldata params)
        external
        override
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        address uniswapNpm = _getUniswapNpm();
        assert(INonfungiblePositionManager(uniswapNpm).ownerOf(params.tokenId) == address(this));
        (, , address token0, address token1, , , , , , , , ) = INonfungiblePositionManager(uniswapNpm).positions(
            params.tokenId
        );

        // we require both tokens being whitelisted
        _assertTokenWhitelisted(token0);
        _assertTokenWhitelisted(token1);

        // we first set the allowance to the uniswap position manager
        if (params.amount0Desired > 0) _safeApprove(token0, uniswapNpm, type(uint256).max);
        if (params.amount1Desired > 0) _safeApprove(token1, uniswapNpm, type(uint256).max);

        // finally, we add to the liquidity token
        (liquidity, amount0, amount1) = INonfungiblePositionManager(uniswapNpm).increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: params.tokenId,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min,
                deadline: params.deadline
            })
        );

        // we make sure we do not clear storage
        if (params.amount0Desired > 0) _safeApprove(token0, uniswapNpm, uint256(1));
        if (params.amount1Desired > 0) _safeApprove(token1, uniswapNpm, uint256(1));
    }

    /// @inheritdoc IAUniswapV3NPM
    function decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params)
        external
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = INonfungiblePositionManager(_getUniswapNpm()).decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: params.tokenId,
                liquidity: params.liquidity,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min,
                deadline: params.deadline
            })
        );
    }

    /// @inheritdoc IAUniswapV3NPM
    function collect(INonfungiblePositionManager.CollectParams calldata params)
        external
        override
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = INonfungiblePositionManager(_getUniswapNpm()).collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: params.tokenId,
                recipient: address(this), // this pool is always the recipient
                amount0Max: params.amount0Max,
                amount1Max: params.amount1Max
            })
        );
    }

    /// @inheritdoc IAUniswapV3NPM
    function burn(uint256 tokenId) external override {
        INonfungiblePositionManager(_getUniswapNpm()).burn(tokenId);
    }

    /// @inheritdoc IAUniswapV3NPM
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external override returns (address pool) {
        pool = INonfungiblePositionManager(_getUniswapNpm()).createAndInitializePoolIfNecessary(
            token0,
            token1,
            fee,
            sqrtPriceX96
        );
    }

    function _assertTokenWhitelisted(address token) internal view virtual {}

    function _safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal virtual {}

    function _getUniswapNpm() internal view virtual returns (address) {}
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "../../../../utils/exchanges/uniswap/ISwapRouter02/ISwapRouter02.sol";

interface IAUniswap {
    /// @notice Returns the address of the Uniswap swap router contract.
    /// @return Address of the uniswap router.
    function uniswapRouter02() external view returns (address);

    /// @notice Returns the address of the Uniswap NPM contract.
    /// @return Address of the Uniswap NPM contract.
    function uniswapv3Npm() external view returns (address);

    /// @notice Returns the address of the Weth contract.
    /// @return Address of the Weth contract.
    function weth() external view returns (address);

    /*
     * UNISWAP V2 METHODS
     */
    /// @notice Swaps `amountIn` of one token for as much as possible of another token.
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap.
    /// @param amountOutMin The minimum amount of output that must be received.
    /// @param path The ordered list of tokens to swap through.
    /// @param to The recipient address.
    /// @return amountOut The amount of the received token.
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token.
    /// @param amountOut The amount of token to swap for.
    /// @param amountInMax The maximum amount of input that the caller will pay.
    /// @param path The ordered list of tokens to swap through.
    /// @param to The recipient address.
    /// @return amountIn The amount of token to pay.
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external returns (uint256 amountIn);

    /*
     * UNISWAP V3 SWAP METHODS
     */
    /// @notice Swaps `amountIn` of one token for as much as possible of another token.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata.
    /// @return amountOut The amount of the received token.
    function exactInputSingle(ISwapRouter02.ExactInputSingleParams calldata params)
        external
        returns (uint256 amountOut);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata.
    /// @return amountOut The amount of the received token.
    function exactInput(ISwapRouter02.ExactInputParams calldata params) external returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for `amountOut` of another token.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata.
    /// @return amountIn The amount of the input token.
    function exactOutputSingle(ISwapRouter02.ExactOutputSingleParams calldata params)
        external
        returns (uint256 amountIn);

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed).
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata.
    /// @return amountIn The amount of the input token.
    function exactOutput(ISwapRouter02.ExactOutputParams calldata params) external returns (uint256 amountIn);

    /*
     * UNISWAP V3 PAYMENT METHODS
     */
    /// @notice Transfers the full amount of a token held by this contract to recipient.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users.
    /// @param token The contract address of the token which will be transferred to `recipient`.
    /// @param amountMinimum The minimum amount of token required for a transfer.
    function sweepToken(address token, uint256 amountMinimum) external;

    /// @notice Transfers the full amount of a token held by this contract to recipient.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users.
    /// @param token The contract address of the token which will be transferred to `recipient`.
    /// @param amountMinimum The minimum amount of token required for a transfer.
    /// @param recipient The destination address of the token.
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external;

    /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users.
    /// @param token The contract address of the token which will be transferred to `recipient`.
    /// @param amountMinimum The minimum amount of token required for a transfer.
    /// @param feeBips The amount of fee in basis points.
    /// @param feeRecipient The destination address of the token.
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external;

    /// @notice Transfers the full amount of a token held by this contract to recipient, with a percentage between
    /// 0 (exclusive) and 1 (inclusive) going to feeRecipient.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users.
    /// @param token The contract address of the token which will be transferred to `recipient`.
    /// @param amountMinimum The minimum amount of token required for a transfer.
    /// @param recipient The destination address of the token.
    /// @param feeBips The amount of fee in basis points.
    /// @param feeRecipient The destination address of the token.
    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external;

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap.
    function unwrapWETH9(uint256 amountMinimum) external;

    /// @notice Unwraps ETH from WETH9.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap.
    /// @param recipient The address to keep same uniswap npm selector.
    function unwrapWETH9(uint256 amountMinimum, address recipient) external;

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of token required for a transfer.
    /// @param feeBips The amount of fee in basis points.
    /// @param feeRecipient The destination address of the token.
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external;

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH, with a percentage between
    /// 0 (exclusive), and 1 (inclusive) going to feeRecipient.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of token required for a transfer.
    /// @param recipient The destination address of the token.
    /// @param feeBips The amount of fee in basis points.
    /// @param feeRecipient The destination address of the token.
    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external;

    /// @notice Wraps ETH.
    /// @dev Client must wrap if input is native currency.
    /// @param value The ETH amount to be wrapped.
    function wrapETH(uint256 value) external;

    /// @notice Allows sending pool transactions exactly as Uniswap original transactions.
    /// @dev Declared virtual as we never send ETH to Uniswap router contract.
    function refundETH() external;
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "../../../../utils/exchanges/uniswap/INonfungiblePositionManager/INonfungiblePositionManager.sol";

interface IAUniswapV3NPM {
    /*
     * UNISWAP V3 LIQUIDITY METHODS
     */
    /// @notice Creates a new position wrapped in a NFT.
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata.
    /// @return tokenId The ID of the token that represents the minted position.
    /// @return liquidity The amount of liquidity for this position.
    /// @return amount0 The amount of token0.
    /// @return amount1 The amount of token1.
    function mint(INonfungiblePositionManager.MintParams calldata params)
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`.
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change.
    /// @return liquidity The new liquidity amount as a result of the increase.
    /// @return amount0 The amount of token0 to acheive resulting liquidity.
    /// @return amount1 The amount of token1 to acheive resulting liquidity.
    function increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams calldata params)
        external
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position.
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change.
    /// @return amount0 The amount of token0 accounted to the position's tokens owed.
    /// @return amount1 The amount of token1 accounted to the position's tokens owed.
    function decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams calldata params)
        external
        returns (uint256 amount0, uint256 amount1);

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient.
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect.
    /// @return amount0 The amount of fees collected in token0.
    /// @return amount1 The amount of fees collected in token1.
    function collect(INonfungiblePositionManager.CollectParams calldata params)
        external
        returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens.
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned.
    function burn(uint256 tokenId) external;

    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool.
    /// @param token0 The contract address of token0 of the pool.
    /// @param token1 The contract address of token1 of the pool.
    /// @param fee The fee amount of the v3 pool for the specified token pair.
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value.
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary.
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external returns (address pool);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title EWhitelist Interface - Allows interaction with the whitelist extension contract.
/// @author Gabriele Rigo - <[email protected]>
interface IEWhitelist {
    /// @notice Emitted when a token is whitelisted or removed.
    /// @param token Address pf the target token.
    /// @param isWhitelisted Boolean the token is added or removed.
    event Whitelisted(address indexed token, bool isWhitelisted);

    /// @notice Allows a whitelister to whitelist a token.
    /// @param token Address of the target token.
    function whitelistToken(address token) external;

    /// @notice Allows a whitelister to remove a token.
    /// @param token Address of the target token.
    function removeToken(address token) external;

    /// @notice Allows a whitelister to whitelist/remove a list of tokens.
    /// @param tokens Address array to tokens.
    /// @param whitelisted Bollean array the token is to be whitelisted or removed.
    function batchUpdateTokens(address[] calldata tokens, bool[] memory whitelisted) external;

    /// @notice Returns whether a token has been whitelisted.
    /// @param token Address of the target token.
    /// @return Boolean the token is whitelisted.
    function isWhitelistedToken(address token) external view returns (bool);

    /// @notice Returns the address of the authority contract.
    /// @return Address of the authority contract.
    function getAuthority() external view returns (address);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2018 RigoBlock, Rigo Investment Sagl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    /// @notice Emitted when a token is transferred.
    /// @param from Address transferring the tokens.
    /// @param to Address receiving the tokens.
    /// @param value Number of token units.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Emitted when a token holder sets and approval.
    /// @param owner Address of the account setting the approval.
    /// @param spender Address of the allowed account.
    /// @param value Number of approved units.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Transfers token from holder to another address.
    /// @param to Address to send tokens to.
    /// @param value Number of token units to send.
    /// @return success Bool the transaction was successful.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice Allows spender to transfer tokens from the holder.
    /// @param from Address of the token holder.
    /// @param to Address to send tokens to.
    /// @param value Number of units to transfer.
    /// @return success Bool the transaction was successful.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice Allows a holder to approve a spender.
    /// @param spender Address of the token spender.
    /// @param value Number of units to be approved.
    /// @return success Bool the transaction was successful.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice Returns token balance for an address.
    /// @param who Address to query balance for.
    /// @return Number of units held.
    function balanceOf(address who) external view returns (uint256);

    /// @notice Returns token allowance of an address to another address.
    /// @param owner Address of token hodler.
    /// @param spender Address of the token spender.
    /// @return Number of allowed units.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Returns token decimals.
    /// @return Uint8 number of decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "./IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Actions Interface - Allows interaction with the pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3PoolActions {
    /// @notice Allows a user to mint pool tokens on behalf of an address.
    /// @param recipient Address receiving the tokens.
    /// @param amountIn Amount of base tokens.
    /// @param amountOutMin Minimum amount to be received, prevents pool operator frontrunning.
    /// @return recipientAmount Number of tokens minted to recipient.
    function mint(
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) external payable returns (uint256 recipientAmount);

    /// @notice Allows a pool holder to burn pool tokens.
    /// @param amountIn Number of tokens to burn.
    /// @param amountOutMin Minimum amount to be received, prevents pool operator frontrunning.
    /// @return netRevenue Net amount of burnt pool tokens.
    function burn(uint256 amountIn, uint256 amountOutMin) external returns (uint256 netRevenue);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Events - Declares events of the pool contract.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolEvents {
    /// @notice Emitted when a new pool is initialized.
    /// @dev Pool is initialized at new pool creation.
    /// @param group Address of the factory.
    /// @param owner Address of the owner.
    /// @param baseToken Address of the base token.
    /// @param name String name of the pool.
    /// @param symbol String symbol of the pool.
    event PoolInitialized(
        address indexed group,
        address indexed owner,
        address indexed baseToken,
        string name,
        bytes8 symbol
    );

    /// @notice Emitted when new owner is set.
    /// @param old Address of the previous owner.
    /// @param current Address of the new owner.
    event NewOwner(address indexed old, address indexed current);

    /// @notice Emitted when pool operator updates NAV.
    /// @param poolOperator Address of the pool owner.
    /// @param pool Address of the pool.
    /// @param unitaryValue Value of 1 token in wei units.
    event NewNav(address indexed poolOperator, address indexed pool, uint256 unitaryValue);

    /// @notice Emitted when pool operator sets new mint fee.
    /// @param pool Address of the pool.
    /// @param who Address that is sending the transaction.
    /// @param transactionFee Number of the new fee in wei.
    event NewFee(address indexed pool, address indexed who, uint16 transactionFee);

    /// @notice Emitted when pool operator updates fee collector address.
    /// @param pool Address of the pool.
    /// @param who Address that is sending the transaction.
    /// @param feeCollector Address of the new fee collector.
    event NewCollector(address indexed pool, address indexed who, address feeCollector);

    /// @notice Emitted when pool operator updates minimum holding period.
    /// @param pool Address of the pool.
    /// @param minimumPeriod Number of seconds.
    event MinimumPeriodChanged(address indexed pool, uint48 minimumPeriod);

    /// @notice Emitted when pool operator updates the mint/burn spread.
    /// @param pool Address of the pool.
    /// @param spread Number of the spread in basis points.
    event SpreadChanged(address indexed pool, uint16 spread);

    /// @notice Emitted when pool operator sets a kyc provider.
    /// @param pool Address of the pool.
    /// @param kycProvider Address of the kyc provider.
    event KycProviderSet(address indexed pool, address indexed kycProvider);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Fallback Interface - Interface of the fallback method.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolFallback {
    /// @notice Delegate calls to pool extension.
    /// @dev Delegatecall restricted to owner, staticcall accessible by everyone.
    /// @dev Restricting delegatecall to owner effectively locks direct calls.
    fallback() external payable;

    /// @notice Allows transfers to pool.
    /// @dev Prevents accidental transfer to implementation contract.
    receive() external payable;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Immutable - Interface of the pool storage.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolImmutable {
    /// @notice Returns a string of the pool version.
    /// @return String of the pool implementation version.
    function VERSION() external view returns (string memory);

    /// @notice Returns the address of the authority contract.
    /// @return Address of the authority contract.
    function authority() external view returns (address);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Initializer Interface - Allows initializing a pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3PoolInitializer {
    /// @notice Initializes to pool storage.
    /// @dev Pool can only be initialized at creation, meaning this method cannot be called directly to implementation.
    function initializePool() external;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool Owner Actions Interface - Interface of the owner methods.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolOwnerActions {
    /// @notice Allows owner to decide where to receive the fee.
    /// @param feeCollector Address of the fee receiver.
    function changeFeeCollector(address feeCollector) external;

    /// @notice Allows pool owner to change the minimum holding period.
    /// @param minPeriod Time in seconds.
    function changeMinPeriod(uint48 minPeriod) external;

    /// @notice Allows pool owner to change the mint/burn spread.
    /// @param newSpread Number between 0 and 1000, in basis points.
    function changeSpread(uint16 newSpread) external;

    /// @notice Allows pool owner to set/update the user whitelist contract.
    /// @dev Kyc provider can be set to null, removing user whitelist requirement.
    /// @param kycProvider Address if the kyc provider.
    function setKycProvider(address kycProvider) external;

    /// @notice Allows pool owner to set a new owner address.
    /// @dev Method restricted to owner.
    /// @param newOwner Address of the new owner.
    function setOwner(address newOwner) external;

    /// @notice Allows pool owner to set the transaction fee.
    /// @param transactionFee Value of the transaction fee in basis points.
    function setTransactionFee(uint16 transactionFee) external;

    /// @notice Allows pool owner to set the pool price.
    /// @param unitaryValue Value of 1 token in wei units.
    function setUnitaryValue(uint256 unitaryValue) external;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

/// @title Rigoblock V3 Pool State - Returns the pool view methods.
/// @author Gabriele Rigo - <[email protected]>
interface IRigoblockV3PoolState {
    /// @notice Returned pool initialization parameters.
    /// @dev Symbol is stored as bytes8 but returned as string to facilitating client view.
    /// @param name String of the pool name (max 32 characters).
    /// @param symbol String of the pool symbol (from 3 to 5 characters).
    /// @param decimals Uint8 decimals.
    /// @param owner Address of the pool operator.
    /// @param baseToken Address of the base token of the pool (0 for base currency).
    struct ReturnedPool {
        string name;
        string symbol;
        uint8 decimals;
        address owner;
        address baseToken;
    }

    /// @notice Returns the struct containing pool initialization parameters.
    /// @dev Symbol is stored as bytes8 but returned as string in the returned struct, unlocked is omitted as alwasy true.
    /// @return ReturnedPool struct.
    function getPool() external view returns (ReturnedPool memory);

    /// @notice Pool variables.
    /// @param minPeriod Minimum holding period in seconds.
    /// @param spread Value of spread in basis points (from 0 to +-10%).
    /// @param transactionFee Value of transaction fee in basis points (from 0 to 1%).
    /// @param feeCollector Address of the fee receiver.
    /// @param kycProvider Address of the kyc provider.
    struct PoolParams {
        uint48 minPeriod;
        uint16 spread;
        uint16 transactionFee;
        address feeCollector;
        address kycProvider;
    }

    /// @notice Returns the struct compaining pool parameters.
    /// @return PoolParams struct.
    function getPoolParams() external view returns (PoolParams memory);

    /// @notice Pool tokens.
    /// @param unitaryValue A token's unitary value in base token.
    /// @param totalSupply Number of total issued pool tokens.
    struct PoolTokens {
        uint256 unitaryValue;
        uint256 totalSupply;
    }

    /// @notice Returns the struct containing pool tokens info.
    /// @return PoolTokens struct.
    function getPoolTokens() external view returns (PoolTokens memory);

    /// @notice Returns the aggregate pool generic storage.
    /// @return poolInitParams The pool's initialization parameters.
    /// @return poolVariables The pool's variables.
    /// @return poolTokensInfo The pool's tokens info.
    function getPoolStorage()
        external
        view
        returns (
            ReturnedPool memory poolInitParams,
            PoolParams memory poolVariables,
            PoolTokens memory poolTokensInfo
        );

    /// @notice Pool holder account.
    /// @param userBalance Number of tokens held by user.
    /// @param activation Time when tokens become active.
    struct UserAccount {
        uint208 userBalance;
        uint48 activation;
    }

    /// @notice Returns a pool holder's account struct.
    /// @return UserAccount struct.
    function getUserAccount(address _who) external view returns (UserAccount memory);

    /// @notice Returns a string of the pool name.
    /// @dev Name maximum length 31 bytes.
    /// @return String of the name.
    function name() external view returns (string memory);

    /// @notice Returns the address of the owner.
    /// @return Address of the owner.
    function owner() external view returns (address);

    /// @notice Returns a string of the pool symbol.
    /// @return String of the symbol.
    function symbol() external view returns (string memory);

    /// @notice Returns the total amount of issued tokens for this pool.
    /// @return Number of total issued tokens.
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.7.0 <0.9.0;

/// @title IStorageAccessible - generic base interface that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
interface IStorageAccessible {
    /// @notice Reads `length` bytes of storage in the currents contract.
    /// @param offset - the offset in the current contract's storage in words to start reading from.
    /// @param length - the number of words (32 bytes) of data to read.
    /// @return Bytes string of the bytes that were read.
    function getStorageAt(uint256 offset, uint256 length) external view returns (bytes memory);

    /// @notice Reads bytes of storage at different storage locations.
    /// @dev Returns a string with values regarless of where they are stored, i.e. variable, mapping or struct.
    /// @param slots The array of storage slots to query into.
    /// @return Bytes string composite of different storage locations' value.
    function getStorageSlotsAt(uint256[] memory slots) external view returns (bytes memory);
}

// SPDX-License-Identifier: Apache 2.0
/*

 Copyright 2022 Rigo Intl.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IERC20.sol";
import "./interfaces/pool/IRigoblockV3PoolActions.sol";
import "./interfaces/pool/IRigoblockV3PoolEvents.sol";
import "./interfaces/pool/IRigoblockV3PoolFallback.sol";
import "./interfaces/pool/IRigoblockV3PoolImmutable.sol";
import "./interfaces/pool/IRigoblockV3PoolInitializer.sol";
import "./interfaces/pool/IRigoblockV3PoolOwnerActions.sol";
import "./interfaces/pool/IRigoblockV3PoolState.sol";
import "./interfaces/pool/IStorageAccessible.sol";

/// @title Rigoblock V3 Pool Interface - Allows interaction with the pool contract.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
interface IRigoblockV3Pool is
    IERC20,
    IRigoblockV3PoolImmutable,
    IRigoblockV3PoolEvents,
    IRigoblockV3PoolFallback,
    IRigoblockV3PoolInitializer,
    IRigoblockV3PoolActions,
    IRigoblockV3PoolOwnerActions,
    IRigoblockV3PoolState,
    IStorageAccessible
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "../v3-periphery/contracts/interfaces/external/IERC721.sol";
import "../v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "../v3-periphery/contracts/interfaces/IPoolInitializer.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is IERC721, IPeripheryImmutableState, IPoolInitializer {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@uniswap/swap-router-contracts/contracts/interfaces/IImmutableState.sol";
import "@uniswap/swap-router-contracts/contracts/interfaces/IPeripheryPaymentsWithFeeExtended.sol";

import "./IV2SwapRouter.sol";
import "./IV3SwapRouter.sol";

/// @title Router token swapping functionality
interface ISwapRouter02 is IV2SwapRouter, IV3SwapRouter, IImmutableState, IPeripheryPaymentsWithFeeExtended {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token
    /// @param amountOut The amount of token to swap for
    /// @param amountInMax The maximum amount of input that the caller will pay
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountIn The amount of token to pay
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0 <0.9.0;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter {
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

// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.0 <0.9.0;

interface IERC721 {
    /// @notice Returns the owner of a given id.
    /// @param tokenId Number of the token id.
    /// @return owner Address of the token owner.
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.9.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5 <0.9.0;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.9.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}