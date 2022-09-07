// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {JonesSSOVPutV3Strategy} from "../JonesSSOVPutV3Strategy.sol";

contract JonesDpxPutStrategy is JonesSSOVPutV3Strategy {
    constructor()
        JonesSSOVPutV3Strategy(
            "JonesDpxPutStrategy",
            0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55, // DPX
            0xf71b2B6fE3c1d94863e751d6B455f750E714163C, // DPX Weekly SSOV-P
            0xDD0556DDCFE7CdaB3540E7F09cB366f498d90774 // Multisig address
        )
    {}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

/**
 * Libraries
 */
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Curve2PoolAdapter} from "../adapters/Curve2PoolAdapter.sol";
import {SushiAdapter} from "../adapters/SushiAdapter.sol";

/**
 * Interfaces
 */
import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {IwETH} from "../interfaces/IwETH.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import {JonesSSOVV3StrategyBase} from "./JonesSSOVV3StrategyBase.sol";
import {ISsovV3} from "../interfaces/ISsovV3.sol";

contract JonesSSOVPutV3Strategy is JonesSSOVV3StrategyBase {
    using SafeERC20 for IERC20;
    using SushiAdapter for IUniswapV2Router02;
    using Curve2PoolAdapter for IStableSwap;

    /// Curve stable swap
    IStableSwap private constant stableSwap = IStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    /// Selling route for swapping base token with USDC;
    address[] private route;

    /**
     * @dev Sets the values for {name}, {asset}, {SSOVP}, and {governor}
     */
    constructor(bytes32 _name, address _asset, address _SSOV, address _governor)
        JonesSSOVV3StrategyBase(_name, _asset, _SSOV, _governor)
    {
        if (_asset == wETH) {
            route = [USDC, wETH];
        } else {
            route = [USDC, wETH, _asset];
        }
        // Token spending approval for Curve 2pool
        IERC20(USDC).safeApprove(address(stableSwap), type(uint256).max);

        // Token spending approvals for SushiSwap
        IERC20(USDC).safeApprove(address(sushiRouter), type(uint256).max);
        IERC20(_asset).safeApprove(address(sushiRouter), type(uint256).max);

        // Token spending approval for SSOV-P
        IERC20(stableSwap).safeApprove(address(SSOV), type(uint256).max);
    }

    /**
     * @notice Sells the base asset for 2CRV
     * @param _baseAmount The amount of base asset to sell
     * @param _stableToken The address of the stable token that will be used as intermediary to get 2CRV
     * @param _minStableAmount The minimum amount of `_stableToken` to get when swapping base
     * @param _min2CrvAmount The minimum amount of 2CRV to receive
     * Returns the amount of 2CRV tokens
     */
    function sellBaseFor2Crv(
        uint256 _baseAmount,
        address _stableToken,
        uint256 _minStableAmount,
        uint256 _min2CrvAmount
    )
        public
        onlyRole(KEEPER)
        returns (uint256)
    {
        return stableSwap.swapTokenFor2Crv(
            asset, _baseAmount, _stableToken, _minStableAmount, _min2CrvAmount, address(this)
        );
    }

    /**
     * @notice Sells 2CRV for the base asset
     * @param _amount The amount of 2CRV to sell
     * @param _stableToken The address of the stable token to receive when removing 2CRV lp
     * @param _minStableAmount The minimum amount of `_stableToken` to get when swapping 2CRV
     * @param _minAssetAmount The minimum amount of base asset to receive
     * Returns the amount of base asset
     */
    function sell2CrvForBase(uint256 _amount, address _stableToken, uint256 _minStableAmount, uint256 _minAssetAmount)
        public
        onlyRole(KEEPER)
        returns (uint256)
    {
        return stableSwap.swap2CrvForToken(asset, _amount, _stableToken, _minStableAmount, _minAssetAmount, address(this));
    }

    /**
     * Sells USDC balance for the asset token
     * @param _minAssetOutputFromUSDCSwap Minimum asset output from swapping USDC.
     */
    function sellUSDCForAsset(uint256 _minAssetOutputFromUSDCSwap) public onlyRole(KEEPER) {
        sushiRouter.sellTokensForExactTokens(route, _minAssetOutputFromUSDCSwap, address(this), USDC);
    }

    /**
     * Sells 2CRV balance for USDC
     * @param _minUSDCOutput Minimum USDC output from selling 2crv.
     */
    function swap2CRVBalanceForUSDC(uint256 _minUSDCOutput) public onlyRole(KEEPER) {
        uint256 _2crvBalance = stableSwap.balanceOf(address(this));
        if (_2crvBalance > 0) {
            stableSwap.swap2CrvForStable(USDC, _2crvBalance, _minUSDCOutput);
        }
    }

    function updateSSOVAddress(ISsovV3 _newSSOV) public onlyRole(GOVERNOR) {
        // revoke old
        IERC20(stableSwap).safeApprove(address(SSOV), 0);

        // set new ssov
        SSOV = _newSSOV;

        // approve new
        IERC20(stableSwap).safeApprove(address(SSOV), type(uint256).max);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
import {IStableSwap} from "../interfaces/IStableSwap.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

library Curve2PoolAdapter {
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
    )
        public
        returns (uint256)
    {
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        address[] memory route = _swapTokenFor2CrvRoute(_inputToken, _stableToken);

        uint256[] memory swapOutputs =
            sushiRouter.swapExactTokensForTokens(_amount, _minStableAmount, route, _recipient, block.timestamp);

        uint256 stableOutput = swapOutputs[swapOutputs.length - 1];

        uint256 amountOut = swapStableFor2Crv(self, _stableToken, stableOutput, _min2CrvAmount);

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
    )
        public
        returns (uint256)
    {
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        uint256 stableAmount = swap2CrvForStable(self, _stableToken, _amount, _minStableAmount);

        address[] memory route = _swapStableForTokenRoute(_outputToken, _stableToken);

        uint256[] memory swapOutputs =
            sushiRouter.swapExactTokensForTokens(stableAmount, _minTokenAmount, route, _recipient, block.timestamp);

        uint256 amountOut = swapOutputs[swapOutputs.length - 1];

        emit Swap2CrvForToken(_amount, amountOut, _outputToken);

        return amountOut;
    }

    /**
     * @notice Swaps 2CRV for a stable token
     * @param _stableToken The stable token address
     * @param _amount The amount of 2CRV to sell
     * @param _minStableAmount The minimum amount stables to receive
     * @return The amount of stables received
     */
    function swap2CrvForStable(IStableSwap self, address _stableToken, uint256 _amount, uint256 _minStableAmount)
        public
        returns (uint256)
    {
        int128 stableIndex;

        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        if (_stableToken == USDC) {
            stableIndex = 0;
        }
        if (_stableToken == USDT) {
            stableIndex = 1;
        }

        return self.remove_liquidity_one_coin(_amount, stableIndex, _minStableAmount);
    }

    /**
     * @notice Swaps a stable token for 2CRV
     * @param _stableToken The stable token address
     * @param _amount The amount of `_stableToken` to sell
     * @param _min2CrvAmount The minimum amount of 2CRV to receive
     * @return The amount of 2CRV received
     */
    function swapStableFor2Crv(IStableSwap self, address _stableToken, uint256 _amount, uint256 _min2CrvAmount)
        public
        returns (uint256)
    {
        uint256[2] memory deposits;
        if (_stableToken != USDC && _stableToken != USDT) {
            revert INVALID_STABLE_TOKEN();
        }

        if (_stableToken == USDC) {
            deposits = [_amount, 0];
        }
        if (_stableToken == USDT) {
            deposits = [0, _amount];
        }

        return self.add_liquidity(deposits, _min2CrvAmount);
    }

    function _swapStableForTokenRoute(address _outputToken, address _stableToken)
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

    event Swap2CrvForToken(uint256 _amountIn, uint256 _amountOut, address _token);
    event SwapTokenFor2Crv(uint256 _amountIn, uint256 _amountOut, address _token);

    error INVALID_STABLE_TOKEN();
}

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

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

library SushiAdapter {
    using SafeERC20 for IERC20;

    /**
     * Sells the received tokens for the provided amounts for the last token in the route
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token
     */
    function sellTokens(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    )
        public
    {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokens(self, IERC20(_tokens[i]), _assetAmounts[i], _recepient, deadline, _routes[i]);
        }
    }

    /**
     * Sells the received tokens for the provided amounts for ETH
     * Temporary solution until we implement accumulation policy.
     * @param self the sushi router used to perform the sale.
     * @param _assetAmounts output amount from selling the tokens.
     * @param _tokens tokens to sell.
     * @param _recepient recepient address.
     * @param _routes routes to sell each token.
     */
    function sellTokensForEth(
        IUniswapV2Router02 self,
        uint256[] memory _assetAmounts,
        address[] memory _tokens,
        address _recepient,
        address[][] memory _routes
    )
        public
    {
        uint256 amountsLength = _assetAmounts.length;
        uint256 tokensLength = _tokens.length;
        uint256 routesLength = _routes.length;

        require(amountsLength == tokensLength, "SRE1");
        require(routesLength == tokensLength, "SRE1");

        uint256 deadline = block.timestamp + 120;
        for (uint256 i = 0; i < tokensLength; i++) {
            _sellTokensForEth(self, IERC20(_tokens[i]), _assetAmounts[i], _recepient, deadline, _routes[i]);
        }
    }

    /**
     * Sells one token for a given amount of another.
     * @param self the Sushi router used to perform the sale.
     * @param _route route to swap the token.
     * @param _assetAmount output amount of the last token in the route from selling the first.
     * @param _recepient recepient address.
     */
    function sellTokensForExactTokens(
        IUniswapV2Router02 self,
        address[] memory _route,
        uint256 _assetAmount,
        address _recepient,
        address _token
    )
        public
    {
        require(_route.length >= 2, "SRE2");
        uint256 balance = IERC20(_route[0]).balanceOf(_recepient);
        if (balance > 0) {
            uint256 deadline = block.timestamp + 120; // Two minutes
            _sellTokens(self, IERC20(_token), _assetAmount, _recepient, deadline, _route);
        }
    }

    function _sellTokensForEth(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    )
        private
    {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForETH(balance, _assetAmount, _route, _recepient, _deadline);
        }
    }

    function swapTokens(
        IUniswapV2Router02 self,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path,
        address _recepient
    )
        external
    {
        self.swapExactTokensForTokens(_amountIn, _amountOutMin, _path, _recepient, block.timestamp);
    }

    function _sellTokens(
        IUniswapV2Router02 _sushiRouter,
        IERC20 _token,
        uint256 _assetAmount,
        address _recepient,
        uint256 _deadline,
        address[] memory _route
    )
        private
    {
        uint256 balance = _token.balanceOf(_recepient);
        if (balance > 0) {
            _sushiRouter.swapExactTokensForTokens(balance, _assetAmount, _route, _recepient, _deadline);
        }
    }

    // ERROR MAPPING:
    // {
    //   "SRE1": "Rewards: token, amount and routes lenght must match",
    //   "SRE2": "Length of route must be at least 2",
    // }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IStableSwap is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);

    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts)
        external
        returns (uint256[2] memory);

    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount) external returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i) external view returns (uint256);

    function coins(uint256 i) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IwETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountETH);

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
    )
        external
        returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

/**
 * Libraries
 */
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SsovAdapter} from "../adapters/SsovAdapter.sol";

/**
 * Interfaces
 */
import {ISsovV3} from "../interfaces/ISsovV3.sol";
import {ISsovV3Viewer} from "../interfaces/ISsovV3Viewer.sol";
import {IwETH} from "../interfaces/IwETH.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";

import {JonesStrategyV3Base} from "./JonesStrategyV3Base.sol";

contract JonesSSOVV3StrategyBase is JonesStrategyV3Base {
    using SafeERC20 for IERC20;
    using SsovAdapter for ISsovV3;

    ISsovV3Viewer constant viewer = ISsovV3Viewer(0x9abE93F7A70998f1836C2Ee0E21988Ca87072001);

    /// SSOV contract
    ISsovV3 public SSOV;

    constructor(bytes32 _name, address _asset, address _SSOV, address _governor)
        JonesStrategyV3Base(_name, _asset, _governor)
    {
        if (_SSOV == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }
        SSOV = ISsovV3(_SSOV);
    }

    // ============================= Mutative functions ================================

    /**
     * Deposits funds to SSOV at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of collateral to deposit.
     * @return tokenId Token id of the deposit.
     */
    function depositSSOV(uint256 _strikeIndex, uint256 _amount) public onlyRole(KEEPER) returns (uint256 tokenId) {
        return SSOV.depositSSOV(_strikeIndex, _amount, address(this));
    }

    /**
     * Buys options from Dopex SSOV.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of puts/calls to purchase.
     * Returns bool to indicate if put/call purchase went through sucessfully.
     */
    function purchaseOption(uint256 _strikeIndex, uint256 _amount) public onlyRole(KEEPER) returns (bool) {
        return SSOV.purchaseOption(_strikeIndex, _amount, address(this));
    }

    /**
     * @notice Settles the SSOV epoch.
     * @param _ssovEpoch The SSOV epoch to settle.
     * @param _ssovStrikes The SSOV strike indexes to settle.
     */
    function settleEpoch(uint256 _ssovEpoch, uint256[] memory _ssovStrikes) public onlyRole(KEEPER) returns (bool) {
        SSOV.settleEpoch(address(this), _ssovEpoch, _ssovStrikes);
        return true;
    }

    function withdrawTokenId(uint256 _tokenId) public onlyRole(KEEPER) returns (bool) {
        SSOV.withdraw(_tokenId, address(this));
        return true;
    }

    /**
     * @notice Withdraws from SSOV for the given `_epoch` and `_strikes`.
     * @param _epoch The SSOV epoch to withdraw from.
     * @param _strikes The SSOV strikes.
     */
    function withdrawEpoch(uint256 _epoch, uint256[] memory _strikes) public onlyRole(KEEPER) returns (bool) {
        SSOV.withdrawEpoch(_epoch, _strikes, address(this));
        return true;
    }

    // ============================= Management Functions ================================

    /**
     * @inheritdoc IStrategy
     */
    function migrateFunds(address _to, address[] memory _tokens, bool _shouldTransferEth, bool _shouldTransferERC721)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        _transferTokens(_to, _tokens, _shouldTransferEth);
        // withdraw erc721 tokens
        if (_shouldTransferERC721) {
            uint256[] memory depositTokens = viewer.walletOfOwner(address(this), SSOV);
            for (uint256 i = 0; i < depositTokens.length; i++) {
                uint256 tokenId = depositTokens[i];
                SSOV.safeTransferFrom(address(this), _to, tokenId);
            }
        }

        emit FundsMigrated(_to);
    }

    // ============================= ERC721 ================================
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface ISsovV3 is IERC721 {
    struct Addresses {
        address feeStrategy;
        address stakingStrategy;
        address optionPricing;
        address priceOracle;
        address volatilityOracle;
        address feeDistributor;
        address optionsTokenImplementation;
    }

    struct EpochData {
        bool expired;
        uint256 startTime;
        uint256 expiry;
        uint256 settlementPrice;
        uint256 totalCollateralBalance; // Premium + Deposits from all strikes
        uint256 collateralExchangeRate; // Exchange rate for collateral to underlying (Only applicable to CALL options)
        uint256 settlementCollateralExchangeRate; // Exchange rate for collateral to underlying on settlement (Only applicable to CALL options)
        uint256[] strikes;
        uint256[] totalRewardsCollected;
        uint256[] rewardDistributionRatios;
        address[] rewardTokensToDistribute;
    }

    struct EpochStrikeData {
        address strikeToken;
        uint256 totalCollateral;
        uint256 activeCollateral;
        uint256 totalPremiums;
        uint256 checkpointPointer;
        uint256[] rewardStoredForPremiums;
        uint256[] rewardDistributionRatiosForPremiums;
    }

    struct VaultCheckpoint {
        uint256 activeCollateral;
        uint256 totalCollateral;
        uint256 accruedPremium;
    }

    struct WritePosition {
        uint256 epoch;
        uint256 strike;
        uint256 collateralAmount;
        uint256 checkpointIndex;
        uint256[] rewardDistributionRatios;
    }

    function expire() external;

    function deposit(uint256 strikeIndex, uint256 amount, address user) external returns (uint256 tokenId);

    function purchase(uint256 strikeIndex, uint256 amount, address user)
        external
        returns (uint256 premium, uint256 totalFee);

    function settle(uint256 strikeIndex, uint256 amount, uint256 epoch, address to) external returns (uint256 pnl);

    function withdraw(uint256 tokenId, address to)
        external
        returns (uint256 collateralTokenWithdrawAmount, uint256[] memory rewardTokenWithdrawAmounts);

    function getUnderlyingPrice() external returns (uint256);

    function getCollateralPrice() external returns (uint256);

    function getVolatility(uint256 _strike) external view returns (uint256);

    function calculatePremium(uint256 _strike, uint256 _amount, uint256 _expiry)
        external
        view
        returns (uint256 premium);

    function calculatePnl(uint256 price, uint256 strike, uint256 amount, uint256 collateralExchangeRate)
        external
        pure
        returns (uint256);

    function calculatePurchaseFees(uint256 strike, uint256 amount) external returns (uint256);

    function calculateSettlementFees(uint256 settlementPrice, uint256 pnl, uint256 amount)
        external
        view
        returns (uint256);

    function getEpochTimes(uint256 epoch) external view returns (uint256 start, uint256 end);

    function writePosition(uint256 tokenId)
        external
        view
        returns (
            uint256 epoch,
            uint256 strike,
            uint256 collateralAmount,
            uint256 checkpointIndex,
            uint256[] memory rewardDistributionRatios
        );

    function getEpochStrikeTokens(uint256 epoch) external view returns (address[] memory);

    function getEpochStrikeData(uint256 epoch, uint256 strike) external view returns (EpochStrikeData memory);

    function getLastVaultCheckpoint(uint256 epoch, uint256 strike) external view returns (VaultCheckpoint memory);

    function underlyingSymbol() external returns (string memory);

    function isPut() external view returns (bool);

    function addresses() external view returns (Addresses memory);

    function collateralToken() external view returns (IERC20);

    function currentEpoch() external view returns (uint256);

    function expireDelayTolerance() external returns (uint256);

    function collateralPrecision() external returns (uint256);

    function getEpochData(uint256 epoch) external view returns (EpochData memory);

    function epochStrikeData(uint256 epoch, uint256 strike) external view returns (EpochStrikeData memory);

    // Dopex management only
    function expire(uint256 _settlementPrice, uint256 _settlementCollateralExchangeRate) external;

    function bootstrap(uint256[] memory strikes, uint256 expiry, string memory expirySymbol) external;

    function addToContractWhitelist(address _contract) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

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
        returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountToken, uint256 amountETH);

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
    )
        external
        returns (uint256 amountA, uint256 amountB);

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
    )
        external
        returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256 amountB);

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ISsovV3} from "../interfaces/ISsovV3.sol";
import {ISsovV3Viewer} from "../interfaces/ISsovV3Viewer.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

library SsovAdapter {
    using SafeERC20 for IERC20;

    ISsovV3Viewer constant viewer = ISsovV3Viewer(0x9abE93F7A70998f1836C2Ee0E21988Ca87072001);

    /**
     * Deposits funds to SSOV at desired strike price.
     * @param _strikeIndex Strike price index.
     * @param _amount Amount of Collateral to deposit.
     * @param _depositor The depositor contract
     * @return tokenId tokenId of the deposit.
     */
    function depositSSOV(ISsovV3 self, uint256 _strikeIndex, uint256 _amount, address _depositor)
        public
        returns (uint256 tokenId)
    {
        tokenId = self.deposit(_strikeIndex, _amount, _depositor);
        uint256 epoch = self.currentEpoch();
        emit SSOVDeposit(epoch, _strikeIndex, _amount, tokenId);
    }

    /**
     * Purchase Dopex option.
     * @param self Dopex SSOV contract.
     * @param _strikeIndex Strike index for current epoch.
     * @param _amount Amount of options to purchase.
     * @param _buyer Jones strategy contract.
     * @return Whether deposit was successful.
     */
    function purchaseOption(ISsovV3 self, uint256 _strikeIndex, uint256 _amount, address _buyer)
        public
        returns (bool)
    {
        (uint256 premium, uint256 totalFee) = self.purchase(_strikeIndex, _amount, _buyer);

        emit SSOVPurchase(
            self.currentEpoch(), _strikeIndex, _amount, premium, totalFee, address(self.collateralToken())
            );

        return true;
    }

    function _settleEpoch(
        ISsovV3 self,
        uint256 _epoch,
        IERC20 _strikeToken,
        address _caller,
        uint256 _strikePrice,
        uint256 _settlementPrice,
        uint256 _strikeIndex,
        uint256 _settlementCollateralExchangeRate
    )
        private
    {
        uint256 strikeTokenBalance = _strikeToken.balanceOf(_caller);
        uint256 pnl =
            self.calculatePnl(_settlementPrice, _strikePrice, strikeTokenBalance, _settlementCollateralExchangeRate);
        if (strikeTokenBalance > 0 && pnl > 0) {
            _strikeToken.safeApprove(address(self), strikeTokenBalance);
            self.settle(_strikeIndex, strikeTokenBalance, _epoch, _caller);
        }
    }

    /**
     * Settles options from Dopex SSOV at the end of an epoch.
     * @param _caller the address settling the epoch
     * @param _epoch the epoch to settle
     * @param _strikes the strikes to settle
     * Returns bool to indicate if epoch settlement was successful.
     */
    function settleEpoch(ISsovV3 self, address _caller, uint256 _epoch, uint256[] memory _strikes)
        public
        returns (bool)
    {
        if (_strikes.length == 0) {
            return false;
        }

        ISsovV3.EpochData memory epochData = self.getEpochData(_epoch);
        uint256[] memory epochStrikes = epochData.strikes;
        uint256 price = epochData.settlementPrice;

        address[] memory strikeTokens = viewer.getEpochStrikeTokens(_epoch, self);
        for (uint256 i = 0; i < _strikes.length; i++) {
            uint256 index = _strikes[i];
            IERC20 strikeToken = IERC20(strikeTokens[index]);
            uint256 strikePrice = epochStrikes[index];
            _settleEpoch(
                self, _epoch, strikeToken, _caller, strikePrice, price, index, epochData.settlementCollateralExchangeRate
            );
        }
        return true;
    }

    /**
     * Allows withdraw of all erc721 tokens ssov deposit for the given epoch and strikes.
     */
    function withdrawEpoch(ISsovV3 self, uint256 _epoch, uint256[] memory _strikes, address _caller) public {
        uint256[] memory tokenIds = viewer.walletOfOwner(_caller, self);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (uint256 epoch, uint256 strike,,,) = self.writePosition(tokenIds[i]);
            if (epoch == _epoch) {
                for (uint256 j = 0; j < _strikes.length; j++) {
                    if (strike == _strikes[j]) {
                        self.withdraw(tokenIds[i], _caller);
                    }
                }
            }
        }
    }

    /**
     * Emitted when new Deposit to SSOV is made
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount deposited Collateral Token amount
     * @param _tokenId token ID of the deposit
     */
    event SSOVDeposit(uint256 indexed _epoch, uint256 _strikeIndex, uint256 _amount, uint256 _tokenId);

    /**
     * emitted when new put/call from SSOV is purchased
     * @param _epoch SSOV epoch (indexed)
     * @param _strikeIndex SSOV strike index
     * @param _amount put amount
     * @param _premium put/call premium
     * @param _totalFee put/call total fee
     */
    event SSOVPurchase(
        uint256 indexed _epoch,
        uint256 _strikeIndex,
        uint256 _amount,
        uint256 _premium,
        uint256 _totalFee,
        address _token
    );
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ISsovV3} from "./ISsovV3.sol";

interface ISsovV3Viewer {
    function getEpochStrikeTokens(uint256 epoch, ISsovV3 ssov) external view returns (address[] memory strikeTokens);

    function walletOfOwner(address owner, ISsovV3 ssov) external view returns (uint256[] memory tokenIds);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IStrategy {
    // ============================= View functions ================================

    /**
     * @return strategy name
     */
    function name() external view returns (bytes32);

    /**
     * Returns the base erc20 asset for the strategy.
     * Assumption: For now, strategies only accept one base asset at the time (i.e the same strat cannot invest ETH and DPX ony one or the other).
     * @return the address for the asset
     */
    function asset() external view returns (address);

    /**
     * Returns the current unused assets in the strategy.
     * @return unused amount of assets
     */
    function getUnused() external view returns (uint256);

    /**
     * Returns the vault attached to strategy.
     * Should revert with error if vault is not attached.
     */
    function getVault() external view returns (address);

    // ============================= Mutative functions ================================

    /**
     * Borrow base assets from the vault.
     * This will borrow the required `_amount` in base assets from the vault.
     * @dev SHOULD only be called by the strategists
     * @dev SHOULD call a very specific method on the vault and not do "transferTo"
     * @dev SHOULD emit event Borrow(vault, asset, amount)
     * @param _amount the amount of assets to borrow
     */
    function borrow(uint256 _amount) external;

    /**
     * Returns all funds to the vault.
     * @dev SHOULD only be called by the strategists
     * @dev SHOULD call a very specific method on the vault "depositProfits"
     * @dev SHOULD emit event Repay(vault, asset, amount)
     */
    function repay() external;

    /**
     * Returns specified `_amount` of funds to the vault.
     * @dev SHOULD only be called by the strategists
     * @dev SHOULD call a very specific method on the vault "depositStrategyFunds"
     * @dev SHOULD emit event Repay(vault, asset, amount)
     */
    function repayFunds(uint256 _amount) external;

    /**
     * Migrates funds to specified address `_to`.
     * @dev SHOULD only be called by the GOVERNOR.
     *
     * Emits {FundsMigrated}
     */
    function migrateFunds(address _to, address[] memory _tokens, bool _shouldTransferEth, bool _shouldTransferERC721)
        external;

    /**
     * Detaches the strategy.
     * For some reason we might want to detach the strat from the vault,
     * this function should close all open positions, repay the vault and remove itself from the vault whitelist.
     *
     * Reverts if pending settlements or unable to withdraw every deposit after calling `repay`.
     * This is to ensure that the Strategy only detaches if everything is settled and
     * deposited assets are repaid to vault.
     *
     * Make sure to invoke `removeStrategyFromWhitelist` on previously detached vault after detaching.
     *
     * @dev SHOULD only be called by the `GOVERNOR`. Governor should also have `KEEPER` role in order to detach successfully.
     * @dev This function should raise an error in the case it can't withdrawal all the funds invested from the used contracts
     */
    function detach() external;

    /**
     * @dev Attaches `_vault` to this strategy.
     *
     * Only a strategist can attach vault and can only happen once.
     * This method is used over the constructor to prevent circular dependency.
     * Should revert with error if vault is already attached.
     *
     * Invoke `whitelistStrategy` on vault after calling this to whitelist this
     * strategy for the vault to be able to pull assets and perform other restricted actions.
     *
     * Emits {VaultSet}.
     */
    function setVault(address _vault) external;

    // ============================= Events ================================
    /**
     * Emitted when borrowing assets from the underlying vault.
     */
    event Borrow(address indexed strategist, uint256 amount, address indexed vault, address indexed asset);

    /**
     * Emitted when closing the strategy.
     */
    event Repay(address indexed strategist, uint256 amount, address indexed vault, address indexed asset);

    /**
     * Emitted when attaching the vault.
     */
    event VaultSet(address indexed governor, address indexed vault);

    /**
     * Emitted when migrating funds (ex in case of an emergency).
     */
    event FundsMigrated(address indexed governor);

    /**
     * Emitted when detaching the vault.
     */
    event VaultDetached(address indexed governor, address indexed vault);

    // ============================= Errors ================================
    error ADDRESS_CANNOT_BE_ZERO_ADDRESS();
    error VAULT_NOT_ATTACHED();
    error VAULT_ALREADY_ATTACHED();
    error MANAGEMENT_WINDOW_NOT_OPEN();
    error NOT_ENOUGH_AVAILABLE_ASSETS();
    error STRATEGY_STILL_HAS_ASSET_BALANCE();
    error BORROW_AMOUNT_ZERO();
    error MSG_SENDER_DOES_NOT_HAVE_PERMISSION_TO_EMERGENCY_WITHDRAW();
    error INVALID_AMOUNT();
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IwETH} from "../interfaces/IwETH.sol";
import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";

abstract contract JonesStrategyV3Base is IStrategy, AccessControl {
    using SafeERC20 for IERC20;

    address internal _vault;
    bytes32 public constant KEEPER = keccak256("KEEPER");
    bytes32 public constant GOVERNOR = keccak256("GOVERNOR");
    address public constant wETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    IUniswapV2Router02 public constant sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address public immutable asset;
    bytes32 public immutable name;
    bool public isVaultSet;

    /**
     * @dev Sets the values for {name} and {asset}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(bytes32 _name, address _asset, address _governor) {
        if (_asset == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }

        if (_governor == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }

        name = _name;
        asset = _asset;

        _grantRole(GOVERNOR, _governor);
        _grantRole(KEEPER, _governor);
    }

    // ============================= View functions ================================

    /**
     * @inheritdoc IStrategy
     */
    function getVault() public view virtual returns (address) {
        if (!isVaultSet) {
            revert VAULT_NOT_ATTACHED();
        }
        return address(_vault);
    }

    /**
     * @inheritdoc IStrategy
     */
    function getUnused() public view virtual override returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    // ============================= Mutative functions ================================

    function grantKeeperRole(address _to) public onlyRole(GOVERNOR) {
        if (_to == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }
        _grantRole(KEEPER, _to);
    }

    function revokeKeeperRole(address _from) public onlyRole(GOVERNOR) {
        _revokeRole(KEEPER, _from);
    }

    /**
     * @inheritdoc IStrategy
     */
    function setVault(address _newVault) public virtual onlyRole(GOVERNOR) {
        if (isVaultSet) {
            revert VAULT_ALREADY_ATTACHED();
        }

        if (_newVault == address(0)) {
            revert ADDRESS_CANNOT_BE_ZERO_ADDRESS();
        }

        _vault = _newVault;
        IERC20(asset).safeApprove(_vault, type(uint256).max);
        isVaultSet = true;
        emit VaultSet(_msgSender(), _vault);
    }

    /**
     * @inheritdoc IStrategy
     */
    function detach() public virtual override onlyRole(GOVERNOR) {
        if (!isVaultSet) {
            revert VAULT_NOT_ATTACHED();
        }
        _repay();
        if (getUnused() > 0) {
            revert STRATEGY_STILL_HAS_ASSET_BALANCE();
        }
        address prevVault = _vault;
        IERC20(asset).safeApprove(_vault, 0);
        _vault = address(0);
        isVaultSet = false;
        emit VaultDetached(msg.sender, prevVault);
    }

    /**
     * @inheritdoc IStrategy
     */
    function borrow(uint256 _amount) public virtual override onlyRole(KEEPER) {
        if (!isVaultSet) {
            revert VAULT_NOT_ATTACHED();
        }
        if (_amount == 0) {
            revert BORROW_AMOUNT_ZERO();
        }
        IVault(_vault).pull(_amount);
        emit Borrow(_msgSender(), _amount, _vault, asset);
    }

    /**
     * @inheritdoc IStrategy
     */
    function repay() public virtual override onlyRole(KEEPER) {
        _repay();
    }

    /**
     * @inheritdoc IStrategy
     */
    function repayFunds(uint256 _amount) public virtual override onlyRole(KEEPER) {
        _repayFunds(_amount);
    }

    function _repay() internal virtual {
        _repayFunds(getUnused());
    }

    function _repayFunds(uint256 _amount) internal virtual {
        if (!isVaultSet) {
            revert VAULT_NOT_ATTACHED();
        }
        if (_amount == 0 || _amount > getUnused()) {
            revert INVALID_AMOUNT();
        }
        IVault(_vault).depositStrategyFunds(_amount);
        emit Repay(_msgSender(), _amount, _vault, asset);
    }

    function migrateFunds(address _to, address[] memory _tokens, bool _shouldTransferEth, bool)
        public
        virtual
        override
        onlyRole(GOVERNOR)
    {
        _transferTokens(_to, _tokens, _shouldTransferEth);
        emit FundsMigrated(_to);
    }

    function _transferTokens(address _to, address[] memory _tokens, bool _shouldTransferEth) internal virtual {
        // transfer tokens
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token = IERC20(_tokens[i]);
            uint256 assetBalance = token.balanceOf(address(this));
            if (assetBalance > 0) {
                token.safeTransfer(_to, assetBalance);
            }
        }

        // migrate ETH balance
        uint256 balanceGwei = address(this).balance;
        if (balanceGwei > 0 && _shouldTransferEth) {
            payable(_to).transfer(balanceGwei);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IVault {
    // ============================= View functions ================================

    /**
     * The amount of `shares` that the Vault would exchange for the amount of `assets` provided, in an ideal scenario where all the conditions are met.
     *
     * Does not show any variations depending on the caller.
     * Does not reflect slippage or other on-chain conditions, when performing the actual exchange.
     * Does not revert unless due to integer overflow caused by an unreasonably large input.
     * This calculation does not reflect the “per-user” price-per-share, and instead reflects the “average-user’s” price-per-share, meaning what the average user can expect to see when exchanging to and from.
     *
     * @param assets Amount of assets to convert.
     * @return shares Amount of shares calculated for the amount of given assets, rounded down towards 0. Does not include any fees that are charged against assets in the Vault.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * The amount of `assets` that the Vault would exchange for the amount of `shares` provided, in an ideal scenario where all the conditions are met.
     *
     * Does not show any variations depending on the caller.
     * Does not reflect slippage or other on-chain conditions, when performing the actual exchange.
     * Does not revert unless due to integer overflow caused by an unreasonably large input.
     * This calculation does not reflect the “per-user” price-per-share, and instead reflects the “average-user’s” price-per-share, meaning what the average user can expect to see when exchanging to and from.
     *
     * @return assets Amount of assets calculated for the given amount of shares, rounded down towards 0. Does not include fees that are charged against assets in the Vault.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * Maximum amount of the underlying asset that can be deposited into the Vault for the receiver, through a deposit call.
     * Returns the maximum amount of assets deposit would allow to be deposited for receiver and not cause a revert, which should be higher than the actual maximum that would be accepted (it should underestimate if necessary). This assumes that the user has infinite assets, i.e. does not rely on balanceOf of asset.
     *
     * Does not revert.
     * This is akin to `vaultCap` in legacy vaults.
     *
     * The `receiver` parameter is added for ERC-4626 parity and is not relevant to our use case
     * since we are not going to have user specific limits for deposits. Either deposits are limited
     * to everyone or no one.
     *
     * @return maxAssets Max assets that can be deposited for receiver. Returns 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited. Returns 0 if deposits are entirely disabled (even temporarily).
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
     *
     * Returns as close to and no more than the exact amount of Vault shares that would be minted in a deposit call in the same transaction. I.e. deposit will return the same or more shares as previewDeposit if called in the same transaction.
     * Does not account for deposit limits like those returned from maxDeposit and always acts as though the deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * Does not revert due to vault specific user/global limits. May revert due to other conditions that would also cause deposit to revert.
     *
     * Any unfavorable discrepancy between convertToShares and previewDeposit will be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by depositing.
     *
     * @return shares exact amount of shares that would be minted in a deposit call. That includes deposit fees. Integrators should be aware of the existence of deposit fees.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @return The current vault State
     */
    function state() external view returns (State);

    /**
     * The address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     */
    function asset() external view returns (address);

    /**
     * The address of the underlying shares token used used to represent tokenized vault.
     */
    function share() external view returns (address);

    /**
     * Total amount of the underlying asset that is managed by this vault.
     *
     * This includes any compounding that occurs from yield.
     * It must be inclusive of any fees that are charged against assets in the Vault.
     * Must not revert.
     *
     * @return totalManagedAssets amount of underlying asset managed by vault.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * Maximum amount of shares that can be minted from the Vault for the `receiver`, through a `mint` call.
     *
     * Returns `2 ** 256 - 1` if there is no limit on the maximum amount of shares that may be minted.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also cause mint to revert.
     * note: Any unfavorable discrepancy between `convertToAssets` and `previewMint` should be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by minting.
     *
     * Does not account for mint limits like those returned from maxMint and always acts as though the mint would be accepted, regardless if the user has enough tokens approved, etc.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * Maximum amount of the underlying asset that can be withdrawn from the `owner` balance in the Vault, through a `withdraw` call.
     *
     * Factors in both global and user-specific limits, like if withdrawals are entirely disabled (even temporarily) it must return 0.
     * Does not revert.
     *
     * @return maxAssets The maximum amount of assets that could be transferred from `owner` through `withdraw` and not cause a revert, which must not be higher than the actual maximum that would be accepted (it should underestimate if necessary).
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
     *
     * Does not revert due to vault specific user/global limits. May revert due to other conditions that would also cause withdraw to revert.
     * Any unfavorable discrepancy between convertToShares and previewWithdraw should be considered slippage in share price or some other type of condition, meaning the depositor will lose assets by depositing.
     *
     * @return shares Shares available to withdraw for specified assets. This includes of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * Maximum amount of Vault shares that can be redeemed from the `owner` balance in the Vault, through a `redeem` call.
     *
     * @return maxShares Max shares that can be redeemed. Factors in both global and user-specific limits, like if redemption is entirely disabled (even temporarily) it will return 0.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block, given current on-chain conditions.
     * Does not account for redemption limits like those returned from maxRedeem and should always act as though the redemption would be accepted, regardless if the user has enough shares, etc.
     *
     * Does not revert due to vault specific user/global limits. May revert due to other conditions that would also cause redeem to revert.
     *
     * @return assets Amount of assets redeemable for given shares. Includes of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    // ============================= User functions ================================

    /**
     * @dev Mints `shares` Vault shares to `receiver` by depositing `amount` of underlying tokens. This should only be called outside the management window.
     *
     * Reverts if all of assets cannot be deposited (ex due to deposit limit, slippage, approvals, etc).
     *
     * Emits a {Deposit} event
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * Mints exactly `shares` Vault shares to `receiver` by depositing `amount` of underlying tokens.
     *
     * Reverts if all of shares cannot be minted (ex. due to deposit limit being reached, slippage, etc).
     *
     * Emits a {Deposit} event
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * Burns `shares` from `owner` and sends exactly `assets` of underlying tokens to `receiver`. Only available outside of management window.
     *
     * Reverts if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
     * Any pre-requesting methods before withdrawal should be performed separately.
     *
     * Emits a {Withdraw} event
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * Burns exactly `shares` from `owner` and sends `assets` of underlying tokens to `receiver`. Only available outside of management window.
     *
     * Reverts if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner not having enough shares, etc).
     * Any pre-requesting methods before withdrawal should be performed separately.
     *
     * Emits a {Withdraw} event
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    // ============================= Strategy functions ================================

    /**
     * Sends the required amount of Asset from this vault to the calling strategy.
     * @dev can only be called by whitelisted strategies (KEEPER role)
     * @dev reverts if management window is closed.
     * @param assets the amount of tokens to pull
     */
    function pull(uint256 assets) external;

    /**
     * Deposits funds from Strategy (both profits and principal amounts).
     * @dev can only be called by whitelisted strategies (KEEPER role)
     * @dev reverts if management window is closed.
     * @param assets the amount of Assets being deposited from the strategy.
     */
    function depositStrategyFunds(uint256 assets) external;

    // ============================= Admin functions ================================

    /**
     * Sets the max deposit `amount` for vault. Akin to setting vault cap in v2 vaults.
     * Since we will not be limiting deposits per user there is no need to add `receiver` input
     * in the argument.
     */
    function setVaultCap(uint256 amount) external;

    /**
     * Adds a strategy to the whitelist.
     * @dev can only be called by governor (GOVERNOR role)
     * @param _address of the strategy to whitelist
     */
    function whitelistStrategy(address _address) external;

    /**
     * Removes a strategy from the whitelist.
     * @dev can only be called by governor (GOVERNOR role)
     * @param _address of the strategy to remove from whitelist
     */
    function removeStrategyFromWhitelist(address _address) external;

    /**
     * @notice Adds a contract to the whitelist.
     * @dev By default only EOA cann interact with the vault.
     * @dev Whitelisted contracts will be able to interact with the vault too.
     * @param contractAddress The address of the contract to whitelist.
     */
    function addContractAddressToWhitelist(address contractAddress) external;

    /**
     * @notice Used to check wheter a contract address is whitelisted to use the vault
     * @param _contractAddress The address of the contract to check
     * @return `true` if the contract is whitelisted, `false` otherwise
     */
    function whitelistedContract(address _contractAddress) external view returns (bool);

    /**
     * @notice Removes a contract from the whitelist.
     * @dev Removed contracts wont be able to interact with the vault.
     * @param contractAddress The address of the contract to whitelist.
     */
    function removeContractAddressFromWhitelist(address contractAddress) external;

    /**
     * Migrate vault to new vault contract.
     * @dev acts as emergency withdrawal if needed.
     * @dev can only be called by governor (GOVERNOR role)
     * @param _to New vault contract address.
     * @param _tokens Addresses of tokens to be migrated.
     *
     */
    function migrate(address _to, address[] memory _tokens) external;

    /**
     * Deposits and withdrawals close, assets are under vault control.
     * @dev can only be called by governor (GOVERNOR role)
     */
    function openManagementWindow() external;

    /**
     * Open vault for deposits and claims.
     * @dev can only be called by governor (GOVERNOR role)
     */
    function closeManagementWindow() external;

    /**
     * Open vault for deposits and claims, sets the snapshot of assets balance manually
     * @dev can only be called by governor (GOVERNOR role)
     * @dev can only be called on `State.INITIAL`
     * @param _snapshotAssetBalance Overrides the value of the snapshotted asset balance
     * @param _snapshotShareSupply Overrides the value of the snapshotted share supply
     */
    function initialRun(uint256 _snapshotAssetBalance, uint256 _snapshotShareSupply) external;

    /**
     * Enable/diable charging performance & management fees
     * @dev can only be called by GOVERNOR role
     * @param _status `true` if the vault should charge fees, `false` otherwise
     */
    function setChargeFees(bool _status) external;

    /**
     * Updated the fee distributor address
     * @dev can only be called by GOVERNOR role
     * @param _feeDistributor The address of the new fee distributor
     */
    function setFeeDistributor(address _feeDistributor) external;

    // ============================= Enums =================================

    /**
     * Enum to represent the current state of the vault
     * INITIAL = Right after deployment, can move to `UNMANAGED` by calling `initialRun`
     * UNMANAGED = Users are able to interact with the vault, can move to `MANAGED` by calling `openManagementWindow`
     * MANAGED = Strategies will be able to borrow & repay, can move to `UNMANAGED` by calling `closeManagementWindow`
     */
    enum State {
        INITIAL,
        UNMANAGED,
        MANAGED
    }

    // ============================= Events ================================

    /**
     * `caller` has exchanged `assets` for `shares`, and transferred those `shares` to `owner`.
     * Emitted when tokens are deposited into the Vault via the `mint` and `deposit` methods.
     */
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /**
     * `caller` has exchanged `shares`, owned by `owner`, for `assets`, and transferred those `assets` to `receiver`.
     * Will be emitted when shares are withdrawn from the Vault in `ERC4626.redeem` or `ERC4626.withdraw` methods.
     */
    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /**
     * emitted when vault balance snapshot is taken
     * @param _timestamp snapshot timestamp (indexed)
     * @param _vaultBalance vault balance value
     * @param _jonesAssetSupply jDPX total supply value
     */
    event Snapshot(uint256 indexed _timestamp, uint256 _vaultBalance, uint256 _jonesAssetSupply);

    /**
     * emitted when asset management window is opened
     * @param _timestamp snapshot timestamp (indexed)
     * @param _assetBalance new vault balance value
     * @param _shareSupply share token total supply at this time
     */
    event EpochStarted(uint256 indexed _timestamp, uint256 _assetBalance, uint256 _shareSupply);

    /**
     * emitted when claim and deposit windows are open
     * @param _timestamp snapshot timestamp (indexed)
     * @param _assetBalance new vault balance value
     * @param _shareSupply share token total supply at this time
     */
    event EpochEnded(uint256 indexed _timestamp, uint256 _assetBalance, uint256 _shareSupply);

    // ============================= Errors ================================
    error MSG_SENDER_NOT_WHITELISTED_USER();
    error DEPOSIT_ASSET_AMOUNT_EXCEEDS_MAX_DEPOSIT();
    error MINT_SHARE_AMOUNT_EXCEEDS_MAX_MINT();
    error ZERO_SHARES_AVAILABLE_WHEN_DEPOSITING();
    error INVALID_STATE(State _expected, State _actual);
    error INVALID_ASSETS_AMOUNT();
    error INVALID_SHARES_AMOUNT();
    error CONTRACT_ADDRESS_MAKING_PROHIBITED_FUNCTION_CALL();
    error INVALID_ADDRESS();
    error INVALID_SNAPSHOT_VALUE();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}