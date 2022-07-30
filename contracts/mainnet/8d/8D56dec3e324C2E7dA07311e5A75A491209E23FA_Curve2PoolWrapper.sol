// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   *********************  
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/

pragma solidity ^0.8.10;

// Interfaces
import {IStableSwap} from "../../interfaces/IStableSwap.sol";
import {IUniswapV2Router02} from "../../interfaces/IUniswapV2Router02.sol";

library Curve2PoolWrapper {
    address constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    IUniswapV2Router02 constant sushiRouter = IUniswapV2Router02(SUSHI_ROUTER);

    /**
     * @notice Swaps a token for 2CRV
     * @param _inputToken The token to swap
     * @param _amount The token amount to swap
     * @param _stableToken The address of the stable token to swap the `_inputToken`
     * @param _minStableAmount The minimum output amount of `_stableToken`
     * @param _min2CrvAmount The minimum output amount of 2CRV to receive
     * @param _recipient The address that's going to receive the 2CRV
     * @return The amount of 2CRV received
     */
    function swapTokenFor2Crv(
        IStableSwap self,
        address _inputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _min2CrvAmount,
        address _recipient
    ) public returns (uint256) {
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        address[] memory route = _swapTokenFor2CrvRoute(
            _inputToken,
            _stableToken
        );

        uint256[] memory swapOutputs = sushiRouter.swapExactTokensForTokens(
            _amount,
            _minStableAmount,
            route,
            _recipient,
            block.timestamp
        );

        uint256 stableOutput = swapOutputs[swapOutputs.length - 1];

        uint256 amountOut = swapStableFor2Crv(
            self,
            _stableToken,
            stableOutput,
            _min2CrvAmount
        );

        emit SwapTokenFor2Crv(_amount, amountOut, _inputToken);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for `_outputToken`
     * @param _outputToken The output token to receive
     * @param _amount The amount of 2CRV to swap
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minTokenAmount The minimum output amount of `_outputToken` to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swap2CrvForToken(
        IStableSwap self,
        address _outputToken,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minTokenAmount,
        address _recipient
    ) public returns (uint256) {
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        uint256 stableAmount = swap2CrvForStable(
            self,
            _stableToken,
            _amount,
            _minStableAmount
        );

        address[] memory route = _swap2CrvForTokenRoute(
            _outputToken,
            _stableToken
        );

        uint256[] memory swapOutputs = sushiRouter.swapExactTokensForTokens(
            stableAmount,
            _minTokenAmount,
            route,
            _recipient,
            block.timestamp
        );

        uint256 amountOut = swapOutputs[swapOutputs.length - 1];

        emit Swap2CrvForToken(_amount, amountOut, _outputToken);

        return amountOut;
    }

    /**
     * @notice Swaps the native asset for 2CRV
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _min2CrvAmount The minimum output amount of 2CRV to receive
     * @param _recipient The address that's going to receive the 2CRV
     * @return The amount of 2CRV received
     */
    function swapNativeFor2Crv(
        IStableSwap self,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _min2CrvAmount,
        address _recipient
    ) public returns (uint256) {
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        address[] memory route = new address[](2);

        route[0] = WETH;
        route[1] = _stableToken;

        uint256[] memory swapOutputs = sushiRouter.swapExactETHForTokens{
            value: _amount
        }(_minStableAmount, route, _recipient, block.timestamp);

        uint256 stableOutput = swapOutputs[swapOutputs.length - 1];

        uint256 amountOut = swapStableFor2Crv(
            self,
            _stableToken,
            stableOutput,
            _min2CrvAmount
        );

        emit SwapNativeFor2Crv(_amount, amountOut);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for native currency
     * @param _amount The amount of 2CRV to swap
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minNativeAmount The minimum output amount of native currency to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swap2CrvForNative(
        IStableSwap self,
        uint256 _amount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minNativeAmount,
        address _recipient
    ) public returns (uint256) {
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        uint256 stableAmount = swap2CrvForStable(
            self,
            _stableToken,
            _amount,
            _minStableAmount
        );

        address[] memory route = new address[](2);

        route[0] = _stableToken;
        route[1] = WETH;

        uint256[] memory swapOutputs = sushiRouter.swapExactTokensForETH(
            stableAmount,
            _minNativeAmount,
            route,
            _recipient,
            block.timestamp
        );

        uint256 amountOut = swapOutputs[swapOutputs.length - 1];

        emit Swap2CrvForNative(_amount, amountOut);

        return amountOut;
    }

    /**
     * @notice Swaps all 2CRV balance for `_outputToken`
     * @param _outputToken The output token to receive
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minTokenAmount The minimum output amount of `_outputToken` to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swapAll2CrvForToken(
        IStableSwap self,
        address _outputToken,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minTokenAmount,
        address _recipient
    ) public returns (uint256) {
        uint256 amount = self.balanceOf(_recipient);

        if (amount > 0) {
            return
                swap2CrvForToken(
                    self,
                    _outputToken,
                    amount,
                    _stableToken,
                    _minStableAmount,
                    _minTokenAmount,
                    _recipient
                );
        }

        return 0;
    }

    /**
     * @notice Swaps all 2CRV balance for native currency
     * @param _stableToken The address of the stable token to receive
     * @param _minStableAmount The minimum output amount of `_stableToken` to receive
     * @param _minNativeAmount The minimum output amount of native currency to receive
     * @param _recipient The address that's going to receive the `_outputToken`
     * @return The amount of `_outputToken` received
     */
    function swapAll2CrvForNative(
        IStableSwap self,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _minNativeAmount,
        address _recipient
    ) public returns (uint256) {
        uint256 amount = self.balanceOf(_recipient);

        if (amount > 0) {
            return
                swap2CrvForNative(
                    self,
                    amount,
                    _stableToken,
                    _minStableAmount,
                    _minNativeAmount,
                    _recipient
                );
        }

        return 0;
    }

    /**
     * @notice Swaps 2CRV for a stable token
     * @param _stableToken The stable token address
     * @param _amount The amount of 2CRV to sell
     * @param _minStableAmount The minimum amount stables to receive
     * @return The amount of stables received
     */
    function swap2CrvForStable(
        IStableSwap self,
        address _stableToken,
        uint256 _amount,
        uint256 _minStableAmount
    ) public returns (uint256) {
        int128 stableIndex;

        require(_stableToken == USDC || _stableToken == USDT, "P1");

        if (_stableToken == USDC) {
            stableIndex = 0;
        }
        if (_stableToken == USDT) {
            stableIndex = 1;
        }

        return
            self.remove_liquidity_one_coin(
                _amount,
                stableIndex,
                _minStableAmount
            );
    }

    /**
     * @notice Swaps a stable token for 2CRV
     * @param _stableToken The stable token address
     * @param _amount The amount of `_stableToken` to sell
     * @param _min2CrvAmount The minimum amount of 2CRV to receive
     * @return The amount of 2CRV received
     */
    function swapStableFor2Crv(
        IStableSwap self,
        address _stableToken,
        uint256 _amount,
        uint256 _min2CrvAmount
    ) public returns (uint256) {
        uint256[2] memory deposits;
        require(_stableToken == USDC || _stableToken == USDT, "P1");

        if (_stableToken == USDC) {
            deposits = [_amount, 0];
        }
        if (_stableToken == USDT) {
            deposits = [0, _amount];
        }

        return self.add_liquidity(deposits, _min2CrvAmount);
    }

    function _swap2CrvForTokenRoute(address _outputToken, address _stableToken)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory route;
        if (_outputToken == WETH) {
            // handle weth swaps
            route = new address[](2);
            route[0] = _stableToken;
            route[1] = _outputToken;
        } else {
            route = new address[](3);
            route[0] = _stableToken;
            route[1] = WETH;
            route[2] = _outputToken;
        }
        return route;
    }

    function _swapTokenFor2CrvRoute(address _inputToken, address _stableToken)
        internal
        pure
        returns (address[] memory)
    {
        address[] memory route;
        if (_inputToken == WETH) {
            // handle weth swaps
            route = new address[](2);
            route[0] = _inputToken;
            route[1] = _stableToken;
        } else {
            route = new address[](3);
            route[0] = _inputToken;
            route[1] = WETH;
            route[2] = _stableToken;
        }
        return route;
    }

    event Swap2CrvForToken(
        uint256 _amountIn,
        uint256 _amountOut,
        address _token
    );
    event SwapTokenFor2Crv(
        uint256 _amountIn,
        uint256 _amountOut,
        address _token
    );
    event Swap2CrvForNative(uint256 _amountIn, uint256 _amountOut);
    event SwapNativeFor2Crv(uint256 _amountIn, uint256 _amountOut);
    /**
     * ERROR MAPPING:
     * {
     *   "P1": "Invalid stable token",
     * }
     */
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStableSwap is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity(
        uint256 burn_amount,
        uint256[2] calldata min_amounts
    ) external returns (uint256[2] memory);

    function remove_liquidity_one_coin(
        uint256 burn_amount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
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
        uint256 deadline
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
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}