/**
 *Submitted for verification at Arbiscan on 2023-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v2;

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

/**
 * Transfer Helper
 */
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

/**
 * ISwapRouter With Payment
 */
interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

/// @title QuoterV2 Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps.
/// @notice For each pool also tells you the number of initialized ticks crossed and the sqrt price of the pool after the swap.
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoterV2 {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInput(bytes memory path, uint256 amountIn)
    external
    returns (
        uint256 amountOut,
        uint160[] memory sqrtPriceX96AfterList,
        uint32[] memory initializedTicksCrossedList,
        uint256 gasEstimate
    );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountIn The desired input amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
    external
    returns (
        uint256 amountOut,
        uint160 sqrtPriceX96After,
        uint32 initializedTicksCrossed,
        uint256 gasEstimate
    );

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutput(bytes memory path, uint256 amountOut)
    external
    returns (
        uint256 amountIn,
        uint160[] memory sqrtPriceX96AfterList,
        uint32[] memory initializedTicksCrossedList,
        uint256 gasEstimate
    );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountOut The desired output amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutputSingle(QuoteExactOutputSingleParams memory params)
    external
    returns (
        uint256 amountIn,
        uint160 sqrtPriceX96After,
        uint32 initializedTicksCrossed,
        uint256 gasEstimate
    );
}

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

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

/**
 * Manager
 */
abstract contract Manager is Context {

    mapping(address => bool) public managers;

    modifier onlyManager {
        require(managers[_msgSender()], "only manager");
        _;
    }

    event ManagerModified(address operater, address one, bool bln);

    constructor() {
        managers[_msgSender()] = true;
    }

    function setManager(address one, bool bln) public onlyManager {
        require(one != address(0), "address is zero");
        require(one != _msgSender(), "address is self");
        if (bln) {
            managers[one] = true;
        } else {
            delete managers[one];
        }
        emit ManagerModified(_msgSender(), one, bln);
    }
}

/**
 * Blacklist
 */
abstract contract Blacklist is Manager {
    mapping (address => bool) public blacklisted;

    modifier notBlacklisted {
        require(!blacklisted[_msgSender()], "blacklisted");
        _;
    }

    function addToBlacklist(address _user) public onlyManager {
        require(!blacklisted[_user], "User is already on the blacklist.");
        blacklisted[_user] = true;
    }

    function removeFromBlacklist(address _user) public onlyManager {
        require(blacklisted[_user], "User is not on the blacklist.");
        delete blacklisted[_user];
    }
}

/**
 * UXSwap
 */
contract UXSwap is Manager, Blacklist, Pausable {

    address public WETH = 0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3; // testnet
    address public UPUXUY = 0x3E1fDC46CD29377E27D9D6208C362fc4E54D5A14; // testnet
    address public USDT = 0xD3F8e7c3449906D689D022009453A7d72acEfc15; // testnet
    IUniswapRouter public swapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoterV2 public quoterV2 = IQuoterV2(0x61fFE014bA17989E743c5F6cB21bF9697530B21e);
    uint24 public poolFee = 10000; // 1%
    uint24 public poolFeeEthUsdt = 500; // 0.05%

    /**
     * manager set
     */
    function setFees(uint24 _poolFee, uint24 _poolFeeEthUsdt) public notBlacklisted onlyManager {
        poolFee = _poolFee;
        poolFeeEthUsdt = _poolFeeEthUsdt;
    }

    /**
     * manager set
     */
    function setTokens(address _weth, address _usdt, address _upuxuy) public notBlacklisted onlyManager {
        WETH = _weth;
        USDT = _usdt;
        UPUXUY = _upuxuy;
    }

    /**
     * manager set
     */
    function setUniswapEndpoint(address _swapRouter, address _quoterV2) public notBlacklisted onlyManager {
        swapRouter = IUniswapRouter(_swapRouter);
        quoterV2 = IQuoterV2(_quoterV2);
    }

    /**
     * manager pause
     */
    function pause() public notBlacklisted onlyManager whenNotPaused {
        _pause();
    }

    /**
     * manager unpause
     */
    function unpause() public notBlacklisted onlyManager whenPaused {
        _unpause();
    }

    /**
     * Quote: exact eth -> upuxuy
     * @return amountOut The amount of `tokenOut` that would be received
     * @return sqrtPriceX96After The sqrt price of the pool after the swap
     * @return initializedTicksCrossed The number of initialized ticks that the swap crossed
     * @return gasEstimate The estimate of the gas that the swap consumes
     */
    function quoteExactEthToUpuxuy(uint256 ethIn) public returns(uint256, uint160, uint32, uint256) {
        IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.QuoteExactInputSingleParams(
            WETH,
            UPUXUY,
            ethIn,
            poolFee,
            0
        );
        return quoterV2.quoteExactInputSingle(params);
    }

    /**
     * Convert: exact eth -> upuxuy
     * some eth will be back
     * @return upuxuyOut
     */
    function convertExactEthToUpuxuy(uint160 sqrtPriceLimitX96) public payable notBlacklisted whenNotPaused returns(uint256) {
        require(msg.value > 0, "Must pass non 0 ETH amount");
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            WETH,
            UPUXUY,
            poolFee,
            _msgSender(),
            block.timestamp + 15,
            msg.value,
            1,
            sqrtPriceLimitX96
        );
        uint256 upuxuyOut = swapRouter.exactInputSingle{value: msg.value}(params);
        swapRouter.refundETH();
        if (address(this).balance > 0) {
            TransferHelper.safeTransferETH(_msgSender(), address(this).balance);
        }
        return upuxuyOut;
    }

    /**
     * Quote: eth -> exact upuxuy
     * @return amountIn The amount required as the input for the swap in order to receive `amountOut`
     * @return sqrtPriceX96After The sqrt price of the pool after the swap
     * @return initializedTicksCrossed The number of initialized ticks that the swap crossed
     * @return gasEstimate The estimate of the gas that the swap consumes
     */
    function quoteEthToExactUpuxuy(uint256 upuxuyOut) public returns(uint256, uint160, uint32, uint256) {
        IQuoterV2.QuoteExactOutputSingleParams memory params = IQuoterV2.QuoteExactOutputSingleParams(
            WETH,
            UPUXUY,
            upuxuyOut,
            poolFee,
            0
        );
        return quoterV2.quoteExactOutputSingle(params);
    }

    /**
     * Convert: eth -> exact upuxuy
     * some eth will be back
     * @return ethIn
     */
    function convertEthToExactUpuxuy(uint256 upuxuyOut, uint160 sqrtPriceLimitX96) public payable notBlacklisted whenNotPaused returns(uint256) {
        require(msg.value > 0, "Must pass non 0 ETH amount");
        require(upuxuyOut > 0, "upuxuy out should be > 0");
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
            WETH,
            UPUXUY,
            poolFee,
            _msgSender(),
            block.timestamp + 15,
            upuxuyOut,
            msg.value,
            sqrtPriceLimitX96
        );
        uint256 ethIn = swapRouter.exactOutputSingle(params);
        swapRouter.refundETH();
        if (address(this).balance > 0 && msg.value > ethIn) {
            TransferHelper.safeTransferETH(_msgSender(), address(this).balance);
        }
        return ethIn;
    }

    /**
     * Quote: exact upuxuy -> eth
     * @return amountOut The amount of `tokenOut` that would be received
     * @return sqrtPriceX96After The sqrt price of the pool after the swap
     * @return initializedTicksCrossed The number of initialized ticks that the swap crossed
     * @return gasEstimate The estimate of the gas that the swap consumes
     */
    function quoteExactUpuxuyToEth(uint256 upuxuyIn) public returns(uint256, uint160, uint32, uint256) {
        IQuoterV2.QuoteExactInputSingleParams memory params = IQuoterV2.QuoteExactInputSingleParams(
            UPUXUY,
            WETH,
            upuxuyIn,
            poolFee,
            0
        );
        return quoterV2.quoteExactInputSingle(params);
    }

    /**
     * Convert: exact upuxuy -> eth
     * @return ethOut
     */
    function convertExactUpuxuyToEth(uint256 upuxuyIn, uint160 sqrtPriceLimitX96) public notBlacklisted whenNotPaused returns(uint256) {
        require(upuxuyIn > 0, "upuxuy in should be > 0");
        TransferHelper.safeTransferFrom(UPUXUY, _msgSender(), address(this), upuxuyIn);
        TransferHelper.safeApprove(UPUXUY, address(swapRouter), upuxuyIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            UPUXUY,
            WETH,
            poolFee,
            _msgSender(),
            block.timestamp + 15,
            upuxuyIn,
            1,
            sqrtPriceLimitX96
        );
        return swapRouter.exactInputSingle(params); // ethOut
    }

    /**
     * Quote: upuxuy -> exact eth
     * @return amountIn The amount required as the input for the swap in order to receive `amountOut`
     * @return sqrtPriceX96After The sqrt price of the pool after the swap
     * @return initializedTicksCrossed The number of initialized ticks that the swap crossed
     * @return gasEstimate The estimate of the gas that the swap consumes
     */
    function quoteUpuxuyToExactEth(uint256 ethOut) public returns(uint256, uint160, uint32, uint256) {
        IQuoterV2.QuoteExactOutputSingleParams memory params = IQuoterV2.QuoteExactOutputSingleParams(
            UPUXUY,
            WETH,
            ethOut,
            poolFee,
            0
        );
        return quoterV2.quoteExactOutputSingle(params);
    }

    /**
     * Convert: upuxuy -> exact eth
     * some upuxuy will be back
     * @return upuxuyIn
     */
    function convertUpuxuyToExactEth(uint256 upuxuyInMax, uint256 ethOut, uint160 sqrtPriceLimitX96) public notBlacklisted whenNotPaused returns(uint256) {
        require(upuxuyInMax > 0, "upuxuy in max should be > 0");
        require(ethOut > 0, "eth out should be > 0");
        TransferHelper.safeTransferFrom(UPUXUY, _msgSender(), address(this), upuxuyInMax);
        TransferHelper.safeApprove(UPUXUY, address(swapRouter), upuxuyInMax);
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
            UPUXUY,
            WETH,
            poolFee,
            _msgSender(),
            block.timestamp + 15,
            ethOut,
            upuxuyInMax,
            sqrtPriceLimitX96
        );
        uint256 upuxuyIn = swapRouter.exactOutputSingle(params);
        if (upuxuyIn < upuxuyInMax) {
            TransferHelper.safeApprove(UPUXUY, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(UPUXUY, address(this), msg.sender, upuxuyInMax - upuxuyIn);
        }
        return upuxuyIn;
    }

    /**
     * Quote: exact usdt -> upuxuy
     * @return amountOut The amount of the last token that would be received
     * @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
     * @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
     * @return gasEstimate The estimate of the gas that the swap consumes
     */
    function quoteExactUsdtToUpuxuy(uint256 usdtIn) public returns(uint256, uint160[] memory, uint32[] memory, uint256) {
        return quoterV2.quoteExactInput(
            abi.encodePacked(USDT, poolFeeEthUsdt, WETH, poolFee, UPUXUY),
            usdtIn
        );
    }

    /**
     * Convert: exact usdt -> upuxuy
     * @return upuxuyOut
     */
    function convertExactUsdtToUpuxuy(uint256 usdtIn) public notBlacklisted whenNotPaused returns(uint256) {
        require(usdtIn > 0, "usdt in should be > 0");
        TransferHelper.safeTransferFrom(USDT, _msgSender(), address(this), usdtIn);
        TransferHelper.safeApprove(USDT, address(swapRouter), usdtIn);
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
            abi.encodePacked(USDT, poolFeeEthUsdt, WETH, poolFee, UPUXUY),
            _msgSender(),
            block.timestamp + 15,
            usdtIn,
            1
        );
        return swapRouter.exactInput(params);
    }

    /**
     * Quote: usdt -> exact upuxuy
     * @return amountOut The amount of `tokenOut` that would be received
     * @return sqrtPriceX96After The sqrt price of the pool after the swap
     * @return initializedTicksCrossed The number of initialized ticks that the swap crossed
     * @return gasEstimate The estimate of the gas that the swap consumes
     */
    function quoteUsdtToExactUpuxuy(uint256 upuxuyOut) public returns(uint256, uint160[] memory, uint32[] memory, uint256) {
        return quoterV2.quoteExactOutput(
            abi.encodePacked(USDT, poolFeeEthUsdt, WETH, poolFee, UPUXUY),
            upuxuyOut
        );
    }

    /**
     * Convert: usdt -> exact upuxuy
     * some usdt will be back
     * @return usdtIn
     */
    function convertUsdtToExactUpuxuy(uint256 usdtInMax, uint256 upuxuyOut) public notBlacklisted whenNotPaused returns(uint256) {
        require(usdtInMax > 0, "usdt in max should be > 0");
        require(upuxuyOut > 0, "upuxuy out should be > 0");
        TransferHelper.safeTransferFrom(USDT, _msgSender(), address(this), usdtInMax);
        TransferHelper.safeApprove(USDT, address(swapRouter), usdtInMax);
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams(
            abi.encodePacked(USDT, poolFeeEthUsdt, WETH, poolFee, UPUXUY),
            _msgSender(),
            block.timestamp + 15,
            upuxuyOut,
            usdtInMax
        );
        uint256 usdtIn = swapRouter.exactOutput(params);
        if (usdtIn < usdtInMax) {
            TransferHelper.safeApprove(USDT, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(USDT, address(this), _msgSender(), usdtInMax - usdtIn);
        }
        return usdtIn;
    }

    /**
     * Quote: exact upuxuy -> usdt
     * @return amountOut The amount of the last token that would be received
     * @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
     * @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
     * @return gasEstimate The estimate of the gas that the swap consumes
     */
    function quoteExactUpuxuyToUsdt(uint256 upuxuyIn) public returns(uint256, uint160[] memory, uint32[] memory, uint256) {
        return quoterV2.quoteExactInput(
            abi.encodePacked(UPUXUY, poolFee, WETH, poolFeeEthUsdt, USDT),
            upuxuyIn
        );
    }

    /**
     * Convert: exact upuxuy -> usdt
     * @return usdtOut
     */
    function convertExactUpuxuyToUsdt(uint256 upuxuyIn) public notBlacklisted whenNotPaused returns(uint256) {
        require(upuxuyIn > 0, "upuxuy in should be > 0");
        TransferHelper.safeTransferFrom(UPUXUY, _msgSender(), address(this), upuxuyIn);
        TransferHelper.safeApprove(UPUXUY, address(swapRouter), upuxuyIn);
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
            abi.encodePacked(UPUXUY, poolFee, WETH, poolFeeEthUsdt, USDT),
            _msgSender(),
            block.timestamp + 15,
            upuxuyIn,
            1
        );
        return swapRouter.exactInput(params);
    }

    /**
     * Quote: upuxuy -> exact usdt
     * @return amountOut The amount of `tokenOut` that would be received
     * @return sqrtPriceX96After The sqrt price of the pool after the swap
     * @return initializedTicksCrossed The number of initialized ticks that the swap crossed
     * @return gasEstimate The estimate of the gas that the swap consumes
     */
    function quoteUpuxuyToExactUsdt(uint256 usdtOut) public returns(uint256, uint160[] memory, uint32[] memory, uint256) {
        return quoterV2.quoteExactOutput(
            abi.encodePacked(UPUXUY, poolFee, WETH, poolFeeEthUsdt, USDT),
            usdtOut
        );
    }

    /**
     * Convert: upuxuy -> exact usdt
     * some upuxuy will be back
     * @return upuxuyIn
     */
    function convertUpuxuyToExactUsdt(uint256 upuxuyInMax, uint256 usdtOut) public notBlacklisted whenNotPaused returns(uint256) {
        require(upuxuyInMax > 0, "upuxuy in max should be > 0");
        require(usdtOut > 0, "usdt out should be > 0");
        TransferHelper.safeTransferFrom(UPUXUY, _msgSender(), address(this), upuxuyInMax);
        TransferHelper.safeApprove(UPUXUY, address(swapRouter), upuxuyInMax);
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams(
            abi.encodePacked(UPUXUY, poolFee, WETH, poolFeeEthUsdt, USDT),
            _msgSender(),
            block.timestamp + 15,
            usdtOut,
            upuxuyInMax
        );
        uint256 upuxuyIn = swapRouter.exactOutput(params);
        if (upuxuyIn < upuxuyInMax) {
            TransferHelper.safeApprove(UPUXUY, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(UPUXUY, address(this), msg.sender, upuxuyInMax - upuxuyIn);
        }
        return upuxuyIn;
    }

    /**
     * receive ETH
     */
    receive() payable external {}
}