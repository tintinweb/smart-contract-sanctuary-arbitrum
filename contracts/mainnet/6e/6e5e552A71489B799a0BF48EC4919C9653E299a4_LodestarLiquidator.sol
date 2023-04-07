// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

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
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFlashLoanRecipient.sol";

interface IVault {
    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidator {
    struct LiquidationData {
        address user;
        ICERC20 borrowMarketAddress;
        uint256 loanAmount;
        ICERC20 collateralMarketAddress;
    }

    struct MarketData {
        address underlyingAddress;
        address wethPair;
        address usdcPair;
    }

    error UNAUTHORIZED(string);
    error INVALID_APPROVAL();
    error FAILED(string);
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}

interface ICERC20 is IERC20 {
    // CToken
    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Returns the current per-block borrow interest rate for this cToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this cToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    // Cerc20
    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function underlying() external view returns (address);

    function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface SushiRouterInterface {
    function WETH() external returns (address);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        fixed swapAmountETH,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;
}

interface PriceOracleProxyETHInterface {
    function getUnderlyingPrice(address lToken) external returns (uint256);

    struct AggregatorInfo {
        address source;
        uint8 base;
    }

    function aggregators(address lToken) external returns (AggregatorInfo memory);
}

interface IPlutusDepositor {
    function redeem(uint256 amount) external;

    function redeemAll() external;
}

interface IGLPRouter {
    function unstakeAndRedeemGlpETH(
        uint256 _glpAmount,
        uint256 _minOut,
        address payable _receiver
    ) external returns (uint256);

    function unstakeAndRedeemGlp(address tokenOut, uint256 glpAmount, uint256 minOut, address receiver) external returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface ICETH is ICERC20 {
    function liquidateBorrow(
        address borrower,
        ICERC20 cTokenCollateral
    ) external payable;
}

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

// Ref: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Interfaces/IVault.sol";
import {ILiquidator, ICERC20, SushiRouterInterface, PriceOracleProxyETHInterface, IERC20Extended, IGLPRouter, IPlutusDepositor, IWETH, ICETH} from "./Interfaces/Interfaces.sol";
import "./Interfaces/ISwapRouter.sol";
import "./Interfaces/AggregatorV3Interface.sol";

contract LiquidatorConstants is ILiquidator {
    IVault internal constant BALANCER_VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    IERC20 internal constant USDC = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    IWETH internal constant WETH = IWETH(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 internal constant PLVGLP = IERC20(0x5326E71Ff593Ecc2CF7AcaE5Fe57582D6e74CFF1);
    IERC20 internal constant GLP = IERC20(0x1aDDD80E6039594eE970E5872D247bf0414C8903);
    SushiRouterInterface FRAX_ROUTER = SushiRouterInterface(0xCAAaB0A72f781B92bA63Af27477aA46aB8F653E7);
    ISwapRouter UNI_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    SushiRouterInterface SUSHI_ROUTER = SushiRouterInterface(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    IGLPRouter GLP_ROUTER = IGLPRouter(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);
    IPlutusDepositor PLUTUS_DEPOSITOR = IPlutusDepositor(0x13F0D29b5B83654A200E4540066713d50547606E);
    //placeholder address throws error otherwise
    PriceOracleProxyETHInterface PRICE_ORACLE =
        PriceOracleProxyETHInterface(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

    AggregatorV3Interface ETHUSD_AGGREGATOR = AggregatorV3Interface(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

    mapping(address => MarketData) public marketData;

    mapping(address => AggregatorV3Interface) public aggregators;
}

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IFlashLoanRecipient.sol";
import "./Interfaces/UniswapV2Interface.sol";
import "./Interfaces/AggregatorV3Interface.sol";
import "./LiquidatorConstants.sol";
import "./Swap.sol";

contract LodestarLiquidator is ILiquidator, LiquidatorConstants, Ownable, IFlashLoanRecipient {
    uint256 constant BASE = 1e18;

    constructor(address[] memory lTokens, address[] memory underlyingTokens) {
        for (uint8 i = 0; i < lTokens.length; i++) {
            ICERC20(lTokens[i]).approve(lTokens[i], type(uint256).max);
        }
        for (uint8 i = 0; i < underlyingTokens.length; i++) {
            IERC20(underlyingTokens[i]).approve(address(lTokens[i]), type(uint256).max);
            IERC20(underlyingTokens[i]).approve(address(SUSHI_ROUTER), type(uint256).max);
            IERC20(underlyingTokens[i]).approve(address(UNI_ROUTER), type(uint256).max);
            IERC20(underlyingTokens[i]).approve(address(FRAX_ROUTER), type(uint256).max);
        }
        WETH.approve(address(SUSHI_ROUTER), type(uint256).max);
        WETH.approve(address(UNI_ROUTER), type(uint256).max);
        WETH.approve(address(FRAX_ROUTER), type(uint256).max);
        //WETH.approve(address(PLUTUS), type(uint256).max);
        WETH.approve(address(GLP), type(uint256).max);
        WETH.approve(address(this), type(uint256).max);
        GLP.approve(address(GLP_ROUTER), type(uint256).max);
        PLVGLP.approve(address(PLUTUS_DEPOSITOR), type(uint256).max);
    }

    event Liquidation(address borrower, address borrowMarket, address collateralMarket, uint256 repayAmountUSD);

    function swapThroughUniswap(
        address token0Address,
        address token1Address,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal returns (uint256) {
        uint24 poolFee = 3000;

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(token0Address, poolFee, token1Address),
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minAmountOut
        });

        uint256 amountOut = UNI_ROUTER.exactInput(params);
        return amountOut;
    }

    //NOTE:Only involves swapping tokens for tokens, any operations involving ETH will be wrap/unwrap calls to WETH contract
    function swapThroughSushiswap(address token0Address, address token1Address, uint256 amountIn, uint256 minAmountOut) internal {
        address[] memory path = new address[](2);
        path[0] = token0Address;
        path[1] = token1Address;
        address to = address(this);
        uint256 deadline = block.timestamp;
        SUSHI_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, minAmountOut, path, to, deadline);
    }

    function swapThroughFraxswap(address token0Address, address token1Address, uint256 amountIn, uint256 minAmountOut) internal {
        address[] memory path = new address[](2);
        path[0] = token0Address;
        path[1] = token1Address;
        address to = address(this);
        uint256 deadline = block.timestamp;
        FRAX_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, minAmountOut, path, to, deadline);
    }

    //unwraps a position in plvGLP to native ETH, must be wrapped into WETH prior to repaying flash loan
    function unwindPlutusPosition() public {
        PLUTUS_DEPOSITOR.redeemAll();
        uint256 glpAmount = GLP.balanceOf(address(this));
        //TODO: update with a method to calculate minimum out given 2.5% slippage constraints.
        uint256 minOut = 0;
        GLP_ROUTER.unstakeAndRedeemGlp(address(WETH), glpAmount, minOut, address(this));
    }

    function plutusRedeem() public {
        PLUTUS_DEPOSITOR.redeemAll();
    }

    function glpRedeem() public {
        uint256 balance = GLP.balanceOf(address(this));
        GLP_ROUTER.unstakeAndRedeemGlp(address(WETH), balance, 0, address(this));
    }

    function wrapEther(uint256 amount) public returns (uint256) {
        address _owner = owner();
        require(msg.sender == _owner || msg.sender == address(this), "UNAUTHORIZED");
        (bool sent, ) = address(WETH).call{value: amount}("");
        require(sent, "Failed to send Ether");
        uint256 wethAmount = WETH.balanceOf(address(this));
        return wethAmount;
    }

    function unwrapEther(uint256 amountIn) public returns (uint256) {
        address _owner = owner();
        require(msg.sender == _owner || msg.sender == address(this), "UNAUTHORIZED");
        WETH.withdraw(amountIn);
        uint256 etherAmount = address(this).balance;
        return etherAmount;
    }

    function withdrawWETH() external onlyOwner {
        uint256 amount = WETH.balanceOf(address(this));
        WETH.transferFrom(address(this), msg.sender, amount);
    }

    function withdrawETH() external payable onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, ) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}

    //TODO:Updates for migration to WETH flash loans, swaps to/from WETH for liquidations and repayment, check for special swap cases

    function liquidateAccount(
        address borrowerAddress,
        ICERC20 borrowMarket,
        IERC20[] memory tokens,
        uint256[] memory loanAmounts,
        ICERC20 collateralMarket
    ) external {
        require(tx.origin == msg.sender, "Cannot be called by Smart Contracts");
        require(WETH.balanceOf(address(BALANCER_VAULT)) > loanAmounts[0], "Not enough liquidity in Balancer Pool");

        LiquidationData memory liquidationData = LiquidationData({
            user: borrowerAddress,
            borrowMarketAddress: borrowMarket,
            loanAmount: loanAmounts[0],
            collateralMarketAddress: collateralMarket
        });

        BALANCER_VAULT.flashLoan(IFlashLoanRecipient(address(this)), tokens, loanAmounts, abi.encode(liquidationData));
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory liquidationData
    ) external override {
        if (msg.sender != address(BALANCER_VAULT)) revert UNAUTHORIZED("!vault");

        // additional checks?

        LiquidationData memory data = abi.decode(liquidationData, (LiquidationData));
        if (data.loanAmount != amounts[0] || WETH != tokens[0]) revert FAILED("!chk");

        // sanity check: flashloan has no fees
        if (feeAmounts[0] > 0) revert FAILED("fee>0");

        address borrower = data.user;
        ICERC20 borrowMarketAddress = data.borrowMarketAddress;
        ICERC20 collateralMarketAddress = data.collateralMarketAddress;

        string memory borrowMarketSymbol = borrowMarketAddress.symbol();
        string memory collateralMarketSymbol = collateralMarketAddress.symbol();

        IERC20 borrowUnderlyingAddress;
        IERC20 collateralUnderlyingAddress;

        if(keccak256(bytes(borrowMarketSymbol)) != keccak256("lETH")) {
            borrowUnderlyingAddress = IERC20(borrowMarketAddress.underlying());
        }

        if(keccak256(bytes(collateralMarketSymbol)) != keccak256("lETH")) {
            collateralUnderlyingAddress = IERC20(collateralMarketAddress.underlying());
        }
        //so now we have the WETH to liquidate in hand and now need to swap to the appropriate borrowed asset and execute the liquidation
        

        if (keccak256(bytes(borrowMarketSymbol)) == keccak256("lETH")) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            unwrapEther(wethBalance);
            uint256 repayAmount = address(this).balance;
            require(repayAmount != 0, "Swap Failed");
            ICETH cEth = ICETH(address(borrowMarketAddress));
            cEth.liquidateBorrow{value: repayAmount}(borrower, collateralMarketAddress);
            emit Liquidation(borrower, address(borrowMarketAddress), address(collateralMarketAddress), repayAmount);
        } else if (keccak256(bytes(borrowMarketSymbol)) == keccak256("lUSDC")) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            swapThroughUniswap(address(WETH), address(borrowUnderlyingAddress), wethBalance, 0);
            uint256 repayAmount = borrowUnderlyingAddress.balanceOf(address(this));
            require(repayAmount != 0, "Swap Failed");
            borrowMarketAddress.liquidateBorrow(borrower, repayAmount, address(collateralMarketAddress));
            emit Liquidation(borrower, address(borrowMarketAddress), address(collateralMarketAddress), repayAmount);
        } else if (keccak256(bytes(borrowMarketSymbol)) == keccak256("lARB")) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            swapThroughUniswap(address(WETH), address(borrowUnderlyingAddress), wethBalance, 0);
            uint256 repayAmount = borrowUnderlyingAddress.balanceOf(address(this));
            require(repayAmount != 0, "Swap Failed");
            borrowMarketAddress.liquidateBorrow(borrower, repayAmount, address(collateralMarketAddress));
            emit Liquidation(borrower, address(borrowMarketAddress), address(collateralMarketAddress), repayAmount);
        } else if (keccak256(bytes(borrowMarketSymbol)) == keccak256("lWBTC")) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            swapThroughUniswap(address(WETH), address(borrowUnderlyingAddress), wethBalance, 0);
            uint256 repayAmount = borrowUnderlyingAddress.balanceOf(address(this));
            require(repayAmount != 0, "Swap Failed");
            borrowMarketAddress.liquidateBorrow(borrower, repayAmount, address(collateralMarketAddress));
            emit Liquidation(borrower, address(borrowMarketAddress), address(collateralMarketAddress), repayAmount);
        } else if (keccak256(bytes(borrowMarketSymbol)) == keccak256("lDAI")) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            swapThroughUniswap(address(WETH), address(borrowUnderlyingAddress), wethBalance, 0);
            uint256 repayAmount = borrowUnderlyingAddress.balanceOf(address(this));
            require(repayAmount != 0, "Swap Failed");
            borrowMarketAddress.liquidateBorrow(borrower, repayAmount, address(collateralMarketAddress));
            emit Liquidation(borrower, address(borrowMarketAddress), address(collateralMarketAddress), repayAmount);
        } else if (keccak256(bytes(borrowMarketSymbol)) == keccak256("lUSDT")) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            swapThroughUniswap(address(WETH), address(borrowUnderlyingAddress), wethBalance, 0);
            uint256 repayAmount = borrowUnderlyingAddress.balanceOf(address(this));
            require(repayAmount != 0, "Swap Failed");
            borrowMarketAddress.liquidateBorrow(borrower, repayAmount, address(collateralMarketAddress));
            emit Liquidation(borrower, address(borrowMarketAddress), address(collateralMarketAddress), repayAmount);
        } else if (keccak256(bytes(borrowMarketSymbol)) == keccak256("lMAGIC")) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            swapThroughSushiswap(address(WETH), address(borrowUnderlyingAddress), wethBalance, 0);
            uint256 repayAmount = borrowUnderlyingAddress.balanceOf(address(this));
            require(repayAmount != 0, "Swap Failed");
            borrowMarketAddress.liquidateBorrow(borrower, repayAmount, address(collateralMarketAddress));
            emit Liquidation(borrower, address(borrowMarketAddress), address(collateralMarketAddress), repayAmount);
        } else if (keccak256(bytes(borrowMarketSymbol)) == keccak256("lDPX")) {
            uint256 wethBalance = WETH.balanceOf(address(this));
            swapThroughSushiswap(address(WETH), address(borrowUnderlyingAddress), wethBalance, 0);
            uint256 repayAmount = borrowUnderlyingAddress.balanceOf(address(this));
            require(repayAmount != 0, "Swap Failed");
            borrowMarketAddress.liquidateBorrow(borrower, repayAmount, address(collateralMarketAddress));
            emit Liquidation(borrower, address(borrowMarketAddress), address(collateralMarketAddress), repayAmount);
        } else {
            uint256 wethBalance = WETH.balanceOf(address(this));
            swapThroughFraxswap(address(WETH), address(borrowUnderlyingAddress), wethBalance, 0);
            uint256 repayAmount = borrowUnderlyingAddress.balanceOf(address(this));
            require(repayAmount != 0, "Swap Failed");
            borrowMarketAddress.liquidateBorrow(borrower, repayAmount, address(collateralMarketAddress));
            emit Liquidation(borrower, address(borrowMarketAddress), address(collateralMarketAddress), repayAmount);
        }

        uint256 lTokenBalance = collateralMarketAddress.balanceOf(address(this));

        collateralMarketAddress.redeem(lTokenBalance);

        if (keccak256(bytes(collateralMarketSymbol)) == keccak256("lETH")) {
            uint256 etherBalance = address(this).balance;
            wrapEther(etherBalance);
        } else if (keccak256(bytes(collateralMarketSymbol)) == keccak256("lUSDC")) {
            uint256 collateralBalance = collateralUnderlyingAddress.balanceOf(address(this));
            swapThroughUniswap(address(collateralUnderlyingAddress), address(WETH), collateralBalance, 0);
        } else if (keccak256(bytes(collateralMarketSymbol)) == keccak256("lARB")) {
            uint256 collateralBalance = collateralUnderlyingAddress.balanceOf(address(this));
            swapThroughUniswap(address(collateralUnderlyingAddress), address(WETH), collateralBalance, 0);
        } else if (keccak256(bytes(collateralMarketSymbol)) == keccak256("lWBTC")) {
            uint256 collateralBalance = collateralUnderlyingAddress.balanceOf(address(this));
            swapThroughUniswap(address(collateralUnderlyingAddress), address(WETH), collateralBalance, 0);
        } else if (keccak256(bytes(collateralMarketSymbol)) == keccak256("lDAI")) {
            uint256 collateralBalance = collateralUnderlyingAddress.balanceOf(address(this));
            swapThroughUniswap(address(collateralUnderlyingAddress), address(WETH), collateralBalance, 0);
        } else if (keccak256(bytes(collateralMarketSymbol)) == keccak256("lUSDT")) {
            uint256 collateralBalance = collateralUnderlyingAddress.balanceOf(address(this));
            swapThroughUniswap(address(collateralUnderlyingAddress), address(WETH), collateralBalance, 0);
        } else if (keccak256(bytes(collateralMarketSymbol)) == keccak256("lMAGIC")) {
            uint256 collateralBalance = collateralUnderlyingAddress.balanceOf(address(this));
            swapThroughSushiswap(address(collateralUnderlyingAddress), address(WETH), collateralBalance, 0);
        } else if (keccak256(bytes(collateralMarketSymbol)) == keccak256("lDPX")) {
            uint256 collateralBalance = collateralUnderlyingAddress.balanceOf(address(this));
            swapThroughSushiswap(address(collateralUnderlyingAddress), address(WETH), collateralBalance, 0);
        } else if (keccak256(bytes(collateralMarketSymbol)) == keccak256("lFRAX")) {
            uint256 collateralBalance = collateralUnderlyingAddress.balanceOf(address(this));
            swapThroughFraxswap(address(collateralUnderlyingAddress), address(WETH), collateralBalance, 0);
        } else {
            unwindPlutusPosition();
        }

        WETH.transferFrom(address(this), msg.sender, amounts[0]);
    }
}

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IFlashLoanRecipient.sol";
import "./Interfaces/UniswapV2Interface.sol";
import "./Interfaces/AggregatorV3Interface.sol";
import "./LiquidatorConstants.sol";

contract Swap is ILiquidator, LiquidatorConstants, Ownable {
    constructor (address[] memory underlyingTokens) {
        for (uint8 i = 0; i < underlyingTokens.length; i++) {
            IERC20(underlyingTokens[i]).approve(address(SUSHI_ROUTER), type(uint256).max);
            IERC20(underlyingTokens[i]).approve(address(UNI_ROUTER), type(uint256).max);
            IERC20(underlyingTokens[i]).approve(address(FRAX_ROUTER), type(uint256).max);
        }
        WETH.approve(address(SUSHI_ROUTER), type(uint256).max);
        WETH.approve(address(UNI_ROUTER), type(uint256).max);
        WETH.approve(address(FRAX_ROUTER), type(uint256).max);
        WETH.approve(address(GLP), type(uint256).max);
        WETH.approve(address(this), type(uint256).max);
        GLP.approve(address(GLP_ROUTER), type(uint256).max);
        PLVGLP.approve(address(PLUTUS_DEPOSITOR), type(uint256).max);
    }

    function swapThroughUniswap(
        address token0Address,
        address token1Address,
        uint256 amountIn,
        uint256 minAmountOut
    ) public returns (uint256) {
        uint24 poolFee = 3000;

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(token0Address, poolFee, token1Address),
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minAmountOut
        });

        uint256 amountOut = UNI_ROUTER.exactInput(params);
        return amountOut;
    }

    //NOTE:Only involves swapping tokens for tokens, any operations involving ETH will be wrap/unwrap calls to WETH contract
    function swapThroughSushiswap(address token0Address, address token1Address, uint256 amountIn, uint256 minAmountOut) public {
        address[] memory path = new address[](2);
        path[0] = token0Address;
        path[1] = token1Address;
        address to = address(this);
        uint256 deadline = block.timestamp;
        SUSHI_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, minAmountOut, path, to, deadline);
    }

    function swapThroughFraxswap(address token0Address, address token1Address, uint256 amountIn, uint256 minAmountOut) public {
        address[] memory path = new address[](2);
        path[0] = token0Address;
        path[1] = token1Address;
        address to = address(this);
        uint256 deadline = block.timestamp;
        FRAX_ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, minAmountOut, path, to, deadline);
    }

    //unwraps a position in plvGLP to native ETH, must be wrapped into WETH prior to repaying flash loan
    function unwindPlutusPosition() public {
        PLUTUS_DEPOSITOR.redeemAll();
        uint256 glpAmount = GLP.balanceOf(address(this));
        //TODO: update with a method to calculate minimum out given 2.5% slippage constraints.
        uint256 minOut = 0;
        GLP_ROUTER.unstakeAndRedeemGlp(address(WETH), glpAmount, minOut, address(this));
    }

    function plutusRedeem() public {
        PLUTUS_DEPOSITOR.redeemAll();
    }

    function glpRedeem() public {
        uint256 balance = GLP.balanceOf(address(this));
        GLP_ROUTER.unstakeAndRedeemGlp(address(WETH), balance, 0, address(this));
    }

    function wrapEther(uint256 amount) public returns (uint256) {
        (bool sent, bytes memory data) = address(WETH).call{value: amount}("");
        require(sent, "Failed to send Ether");
        uint256 wethAmount = WETH.balanceOf(address(this));
        return wethAmount;
    }

    function unwrapEther(uint256 amountIn) public returns (uint256) {
        WETH.withdraw(amountIn);
        uint256 etherAmount = address(this).balance;
        return etherAmount;
    }

    function withdrawWETH() external onlyOwner {
        uint256 amount = WETH.balanceOf(address(this));
        WETH.transferFrom(address(this), msg.sender, amount);
    }

    function withdrawETH() external payable onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent, bytes memory data) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}