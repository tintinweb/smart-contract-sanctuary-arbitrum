// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >0.7.6;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import './IWETH.sol';
// to get arbitrum dicord 16 roles in one click
// created by yiyi,https://github.com/orochi1972
contract ArbBot {
    bool entered =false;
    address public owner;
    ISwapRouter public constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    // tokens
    address public constant MAGIC =0x539bdE0d7Dbd336b79148AA742883198BBF60342;
    address public constant LINK =0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
    address public constant GMX =0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address public constant DPX =0x6C2C06790b3E3E3c38e12Ee22F8183b37a13EE55;
    address public constant LPT =0x289ba1701C2F088cf0faf8B3705246331cB8A839;
    address public constant UMAMI =0x1622bF67e6e5747b81866fE0b85178a93C7F86e3;
    address public constant JONES =0x10393c20975cF177a3513071bC110f7962CD67da;
    address public constant SPA =0x5575552988A3A80504bBaeB1311674fCFd40aD4B;
    address public constant MYC =0xC74fE4c715510Ec2F8C61d70D397B32043F55Abe;
    address public constant PLS =0x51318B7D00db7ACc4026C88c3952B66278B6A67F;
    address public constant VSTA =0xa684cd057951541187f288294a1e1C2646aA2d24;
    address public constant SYN =0x080F6AEd32Fc474DD5717105Dba5ea57268F46eb;
    address public constant DBL =0xd3f1Da62CAFB7E7BC6531FF1ceF6F414291F03D3;
    address public constant BRC =0xB5de3f06aF62D8428a8BF7b4400Ea42aD2E0bc53;
    address public constant ELK =0xeEeEEb57642040bE42185f49C52F7E9B38f8eeeE;
    address public constant SWPR =0xdE903E2712288A1dA82942DDdF2c20529565aC30;

    IWETH public constant ETH9 = IWETH(WETH);
    IERC20 public constant Eth9_20 = IERC20(WETH);
    uint public balance = address(this).balance;
    //pool fee to 0.3%.
    uint24 public constant poolFee = 3000;
    constructor() {
        owner=msg.sender;
    }
    receive() external payable {
    }
    modifier entrancyGuard(){
        require(entered==false,"you cannot do this now");
        entered =true;
        _;
        entered=false;
    }
    
    function swapETHForExactOutput(uint amountInMaximum,uint amountOut, address token) internal returns(uint WETHLeft){
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
        WETH,
        token,
        poolFee,
        msg.sender,
        block.timestamp,
        amountOut,
        amountInMaximum,
        0
        );
        //do swap
        swapRouter.exactOutputSingle(params);
        return Eth9_20.balanceOf(address(this));
    }
    function execute() external payable entrancyGuard{
        require(msg.value>=3*1e15,'not enough ETH');
        wrapETH();
        uint balanceNow = Eth9_20.balanceOf(address(this));
        balanceNow = swapETHForExactOutput(balanceNow, 1e15, MAGIC);
        balanceNow = swapETHForExactOutput(balanceNow, 1e15, LINK);
        balanceNow = swapETHForExactOutput(balanceNow, 1e15, GMX);
        balanceNow = swapETHForExactOutput(balanceNow, 1e14, DPX);
        balanceNow = swapETHForExactOutput(balanceNow, 1e15, LPT);
        balanceNow = swapETHForExactOutput(balanceNow, 1e15, UMAMI);
        balanceNow = swapETHForExactOutput(balanceNow, 1e15, JONES);
        balanceNow = swapETHForExactOutput(balanceNow, 1e16, SPA);
        balanceNow = swapETHForExactOutput(balanceNow, 1e16, MYC);
        balanceNow = swapETHForExactOutput(balanceNow, 1e15, PLS);
        balanceNow = swapETHForExactOutput(balanceNow, 1e16, VSTA);
        balanceNow = swapETHForExactOutput(balanceNow, 1e16, SYN);
        balanceNow = swapETHForExactOutput(balanceNow, 1e16, DBL);
        balanceNow = swapETHForExactOutput(balanceNow, 1e16, BRC);
        balanceNow = swapETHForExactOutput(balanceNow, 1e16, ELK);
        balanceNow = swapETHForExactOutput(balanceNow, 1e16, SWPR);
        unwrapETH();
        refund();
    }
    function wrapETH() internal{
        //wrapp to WETH
        TransferHelper.safeTransferETH(WETH,msg.value);
        //approve
        TransferHelper.safeApprove(WETH, address(swapRouter),msg.value);
    }
    function unwrapETH() internal{
        //unwrap
        ETH9.withdraw(Eth9_20.balanceOf(address(this)));
    }
    function refund() internal{
        TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }
    function withdraw() public {
        // in case someone send ether to this contract
        require(msg.sender==owner,'not owner');
        TransferHelper.safeTransferETH(msg.sender,address(this).balance);
    }
}

pragma solidity >=0.5.0;
// SPDX-License-Identifier: GPL-2.0-or-later
interface IWETH{
    function deposit() external payable;
    function withdraw(uint) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
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