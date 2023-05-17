/**
 *Submitted for verification at Arbiscan on 2023-05-15
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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
// File: @uniswap/v3-periphery/contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;


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

// File: @uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol


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

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


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

// File: @uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol


pragma solidity >=0.7.5;
pragma abicoder v2;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: PayinETHorUSDCFinal.sol


pragma solidity ^0.8.19;





contract PayinETHorUSDC is ReentrancyGuard {
    address constant private WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant private GMX = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address constant private USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address immutable private FactoryAddress;
    address immutable public Owner;
    IFactoryContract FactoryContract;
    ISwapRouter constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IPeripheryPayments constant refundrouter = IPeripheryPayments(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    receive() external payable {}
    
    fallback() external payable {}

    constructor (address _FactoryAddress) {
        FactoryAddress = _FactoryAddress;
        FactoryContract = IFactoryContract(FactoryAddress);
        Owner = 0xeA4D1a08300247F6298FdAF2F68977Af7bf93d01;
    }
    
    modifier OnlyOwner() {
        require(msg.sender == Owner);
        _;
    }

    modifier OnlyEscrows() {
        require(FactoryContract.EscrowsToOwners(msg.sender) != address(0), "This function can only be run by escrow accounts");
        _;
    }

    // Escrow only function for buying with ETH
    function ETHGMX(uint256 amountOut, uint24 poolFee, address _Buyer) external payable nonReentrant OnlyEscrows {
        if (poolFee == 5050) {
            uint256 amountOutHalf1 = amountOut / 2;
            uint256 amountOutHalf2 = amountOut - amountOutHalf1;
            uint256 amountInMaxHalf1 = msg.value / 2;
            uint256 amountInMaxHalf2 = msg.value - amountInMaxHalf1;
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: GMX,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1,
                sqrtPriceLimitX96: 0
            }); 
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: GMX,
                fee: 10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2,
                sqrtPriceLimitX96: 0
            }); 
            router.exactOutputSingle{ value: amountInMaxHalf1 }(params1);
            router.exactOutputSingle{ value: amountInMaxHalf2 }(params2);
        } 
        else if (poolFee == 7525) {
            uint256 amountOutHalf2 = amountOut / 4;
            uint256 amountOutHalf1 = amountOut - amountOutHalf2;
            uint256 amountInMaxHalf2 = msg.value / 4;
            uint256 amountInMaxHalf1 = msg.value - amountInMaxHalf2;
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: GMX,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1,
                sqrtPriceLimitX96: 0
            }); 
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: GMX,
                fee: 10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2,
                sqrtPriceLimitX96: 0
            }); 
            router.exactOutputSingle{ value: amountInMaxHalf1 }(params1);
            router.exactOutputSingle{ value: amountInMaxHalf2 }(params2);
        } 
        else if (poolFee == 2575) {
            uint256 amountOutHalf1 = amountOut / 4;
            uint256 amountOutHalf2 = amountOut - amountOutHalf1;
            uint256 amountInMaxHalf1 = msg.value / 4;
            uint256 amountInMaxHalf2 = msg.value - amountInMaxHalf1;
            ISwapRouter.ExactOutputSingleParams memory params1 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: GMX,
                fee: 3000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1,
                sqrtPriceLimitX96: 0
            }); 
            ISwapRouter.ExactOutputSingleParams memory params2 = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: WETH,
                tokenOut: GMX,
                fee: 10000,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2,
                sqrtPriceLimitX96: 0
            }); 
            router.exactOutputSingle{ value: amountInMaxHalf1 }(params1);
            router.exactOutputSingle{ value: amountInMaxHalf2 }(params2);
        }
        else {
            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
                .ExactOutputSingleParams({
                    tokenIn: WETH,
                    tokenOut: GMX,
                    fee: poolFee,
                    recipient: msg.sender,
                    deadline: block.timestamp,
                    amountOut: amountOut,
                    amountInMaximum: msg.value,
                    sqrtPriceLimitX96: 0
                });

            router.exactOutputSingle{ value: msg.value }(params);
            }
        refundrouter.refundETH();
        (bool success,) = _Buyer.call{ value: address(this).balance }("");
        require(success, "refund failed");

    }

    // Escrow only function for buying with ETH
    function USDCGMX(uint256 amountOut, uint256 amountInMax, uint24 poolFee, address _Buyer) external payable nonReentrant OnlyEscrows {
        uint24 poolFee3000 = 3000;
        uint24 poolFee10000 = 10000;
        uint24 poolFee500 = 500;
        uint256 amountInHalf1;
        uint256 amountInHalf2;
        uint256 amountIn;
        TransferHelper.safeApprove(USDC, address(router), amountInMax);
        if (poolFee == 5050) {
            uint256 amountOutHalf1 = amountOut / 2;
            uint256 amountOutHalf2 = amountOut - amountOutHalf1;
            uint256 amountInMaxHalf1 = amountInMax/ 2;
            uint256 amountInMaxHalf2 = amountInMax - amountInMaxHalf1;
            ISwapRouter.ExactOutputParams memory params1 = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(GMX, poolFee3000, WETH, poolFee500, USDC),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1
            }); 
            ISwapRouter.ExactOutputParams memory params2 = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(GMX, poolFee10000, WETH, poolFee500, USDC),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2
            }); 
            amountInHalf1 = router.exactOutput(params1);
            amountInHalf2 = router.exactOutput(params2);
            amountIn = amountInHalf1 + amountInHalf2;
        } 
        else if (poolFee == 7525) {
            uint256 amountOutHalf2 = amountOut / 4;
            uint256 amountOutHalf1 = amountOut - amountOutHalf2;
            uint256 amountInMaxHalf2 = amountInMax / 4;
            uint256 amountInMaxHalf1 = amountInMax - amountInMaxHalf2;
            ISwapRouter.ExactOutputParams memory params1 = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(GMX, poolFee3000, WETH, poolFee500, USDC),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1
            }); 
            ISwapRouter.ExactOutputParams memory params2 = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(GMX, poolFee10000, WETH, poolFee500, USDC),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2
            }); 
            amountInHalf1 = router.exactOutput(params1);
            amountInHalf2 = router.exactOutput(params2);
            amountIn = amountInHalf1 + amountInHalf2;
        } 
        else if (poolFee == 2575) {
            uint256 amountOutHalf1 = amountOut / 4;
            uint256 amountOutHalf2 = amountOut - amountOutHalf1;
            uint256 amountInMaxHalf1 = amountInMax / 4;
            uint256 amountInMaxHalf2 = amountInMax - amountInMaxHalf1;
            ISwapRouter.ExactOutputParams memory params1 = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(GMX, poolFee3000, WETH, poolFee500, USDC),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf1,
                amountInMaximum: amountInMaxHalf1
            }); 
            ISwapRouter.ExactOutputParams memory params2 = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(GMX, poolFee10000, WETH, poolFee500, USDC),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOutHalf2,
                amountInMaximum: amountInMaxHalf2
            }); 
            amountInHalf1 = router.exactOutput(params1);
            amountInHalf2 = router.exactOutput(params2);
            amountIn = amountInHalf1 + amountInHalf2;
        }
        else {
            ISwapRouter.ExactOutputParams memory params = ISwapRouter
                .ExactOutputParams({
                    path: abi.encodePacked(GMX, poolFee, WETH, poolFee500, USDC),
                    recipient: msg.sender,
                    deadline: block.timestamp,
                    amountOut: amountOut,
                    amountInMaximum: amountInMax
                });
            amountIn = router.exactOutput(params);
        }
        if (amountIn < amountInMax) {
            TransferHelper.safeApprove(USDC, address(router), 0);
            TransferHelper.safeTransfer(USDC, _Buyer, amountInMax - amountIn);
        }
    }

    // Withdraw all ETH from this contract
    function WithdrawETH() external payable OnlyOwner nonReentrant {
        require(address(this).balance > 0);
        (bool sent, ) = Owner.call{value: address(this).balance}("");
        require(sent);
    }
    
    // Withdraw any ERC20 token from this contract
    function WithdrawToken(address _tokenaddress, uint256 _Amount) external OnlyOwner nonReentrant {
        TransferHelper.safeTransfer(_tokenaddress, Owner, _Amount);
    }
}

interface IFactoryContract {
    function EscrowsToOwners(address _Address) external view returns (address);
}