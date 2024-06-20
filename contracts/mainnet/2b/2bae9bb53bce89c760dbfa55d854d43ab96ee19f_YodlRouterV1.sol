/**
 *Submitted for verification at Arbiscan.io on 2024-06-20
*/

//SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.26;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma abicoder v2;

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

// The Uniswap IWETH9 has an incompatible version. However, this is just an interface, so the version is irrelevant.
/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

interface ICurveRouter {
    function exchange_multiple(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] calldata _pools,
        address _receiver
    ) external payable returns (uint256);
}

/// @title Yodl Router
/// @author YodlPay
/// @notice This contract facilitates payments for the yodl.me platform. It supports direct token payments
/// as well as payments using swaps through Uniswap and Curve. There is support for cross-currency payments
/// using Chainlink price feeds.
/// @dev Keep in mind when deploying that a IWETH9 compatible wrapped native token needs to be available on chain.
/// For Uniswap or Curve payments to work, there needs to be a valid router for each. The Curve router should support
/// the `exchange_multiple` method.
contract YodlRouterV1 is Ownable {
    enum SwapType {
        SINGLE,
        MULTI
    }

    /// @notice Parameters for a payment through Uniswap
    /// @dev The `returnRemainder` boolean determines if the excess token in should be returned to the user.
    struct YodlUniswapParams {
        address sender;
        address receiver;
        uint256 amountIn; // amount of tokenIn needed to satisfy amountOut
        uint256 amountOut; // The exact amount expected by merchant in tokenOut
        bytes32 memo;
        bytes path; // (address: tokenOut, uint24 poolfee, address: tokenIn) OR (address: tokenOut, uint24 poolfee2, address: tokenBase, uint24 poolfee1, tokenIn)
        address[2] priceFeeds;
        address extraFeeReceiver;
        uint256 extraFeeBps;
        bool returnRemainder;
        SwapType swapType;
    }

    /// @notice Parameters for a payment through Curve
    /// @dev The`route`, `swapParams` and `factoryAddresses` should be determined client-side by the CurveJS client.
    /// The `returnRemainder` boolean determines if the excess token out should be returned to the user.
    struct YodlCurveParams {
        address sender;
        address receiver;
        uint256 amountIn; // amount of tokenIn needed to satisfy amountOut
        // The exact amount expected by merchant in tokenOut
        // If we are using price feeds, this is in terms of the invoice amount, but it must have the same decimals as tokenOut
        uint256 amountOut;
        bytes32 memo;
        address[9] route;
        uint256[3][4] swapParams; // [i, j, swap_type] where i and j are the coin index for the n'th pool in route
        address[4] factoryAddresses;
        address[2] priceFeeds;
        address extraFeeReceiver;
        uint256 extraFeeBps;
        bool returnRemainder;
    }

    // This is not an actual token address, but we will use it to represent the native token in swaps
    address public constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MAX_FEE_BPS = 5_000; // 50%

    address public feeTreasury;
    uint256 public baseFeeBps; // fee = calculateFee(amount, baseFeeDivisor)
    ISwapRouter public uniswapRouter;
    ICurveRouter public curveRouter;
    // Before deploying to a L2 with its own native token,
    // we should check that its wrapped native token works with IWETH9
    IWETH9 public wrappedNativeToken;
    string public version;

    /// @notice Emitted when a payment goes through
    /// @param sender The address who has made the payment
    /// @param receiver The address who has received the payment
    /// @param token The address of the token that was used for the payment. Either an ERC20 token or the native token
    /// address.
    /// @param amount The amount paid by the sender in terms of the token
    /// @param fees The fees taken by the Yodl router from the amount paid
    /// @param memo The message attached to the payment
    event Yodl(
        address indexed sender,
        address indexed receiver,
        address token /* the token that payee receives, use address(0) for AVAX*/,
        uint256 amount,
        uint256 fees,
        bytes32 memo
    );

    /// @notice Emitted when a native token transfer occurs
    /// @param sender The address who has made the payment
    /// @param receiver The address who has received the payment
    /// @param amount The amount paid by the sender in terms of the native token
    event YodlNativeTokenTransfer(
        address indexed sender,
        address indexed receiver,
        uint256 indexed amount
    );


    /// @notice Emitted when a conversion has occurred from one currency to another using a Chainlink price feed
    /// @param priceFeed0 The address of the price feed used for conversion
    /// @param priceFeed1 The address of the price feed used for conversion
    /// @param exchangeRate0 The rate used from the price feed at the time of conversion
    /// @param exchangeRate1 The rate used from the price feed at the time of conversion
    event Convert(
        address indexed priceFeed0,
        address indexed priceFeed1,
        int256 exchangeRate0,
        int256 exchangeRate1
    );

    /// @notice Initializes the YodlRouter contract
    /// @dev Using an incorrect _wrappedNativeToken address will result in native token payments reverting
    /// @param _feeTreasury The address where we want the router to send fees. Can be a contract that supports receiving
    /// the native token or a regular address.
    /// @param _baseFeeBps The basis point amount as a whole number that we will take as a fee
    /// @param _version Version number of the contract
    /// @param _uniswapRouter The address of the Uniswap router, or address(0) if not supported
    /// @param _curveRouter The address of the Curve router, or address(0) if not supported
    /// @param _wrappedNativeToken The address of the IWETH9 compatible wrapped native token
    constructor(
        address _feeTreasury,
        uint256 _baseFeeBps,
        string memory _version,
        address _uniswapRouter,
        address _curveRouter,
        address _wrappedNativeToken
    ) {
        baseFeeBps = _baseFeeBps;
        feeTreasury = _feeTreasury;
        version = _version;
        uniswapRouter = ISwapRouter(_uniswapRouter);
        curveRouter = ICurveRouter(_curveRouter);
        wrappedNativeToken = IWETH9(_wrappedNativeToken);
    }

    /// @notice Enables the contract to receive Ether
    /// @dev We need a receive method for when we withdraw WETH to the router. It does not need to do anything.
    receive() external payable {}

    /**
     * @notice Handles payments when sending tokens directly without DEX.
     * ## Example: Pay without pricefeeds, e.g. USDC transfer
     *
     * yodlWithToken(
     *   "tx-123",         // memo
     *   5*10**18,         // 5$
     *   [0x0, 0x0],  // no pricefeeds
     *   0xUSDC,           // usdc token address
     *   0xAlice           // receiver token address
     * )
     *
     * ## Example: Pay with pricefeeds (EUR / USD)
     *
     * The user entered the amount in EUR, which gets converted into
     * USD by the on-chain pricefeed.
     *
     * yodlWithToken(
     *     "tx-123",               // memo
     *     4.5*10**18,             // 4.5 EUR (~5$).
     *     [0xEURUSD, 0x0],   // EUR/USD price feed
     *     0xUSDC,                 // usdc token address
     *     0xAlice                 // receiver token address
     * )
     *
     *
     * ## Example: Pay with extra fee
     *
     * 3rd parties can receive an extra fee that is taken directly from
     * the receivable amount.
     *
     * yodlWithToken(
     *     "tx-123",               // memo
     *     4.5*10**18,             // 4.5 EUR (~5$).
     *     [0xEURUSD, 0x0],   //
     *     0xUSDC,                 // usdc token address
     *     0xAlice,                // receiver token address
     *     0x3rdParty              // extra fee for 3rd party provider
     *     50,                    // extra fee bps 0.5%
     * )
     * @dev This is the most gas efficient payment method. It supports currency conversion using price feeds. The
     * native token (ETH, AVAX, MATIC) is represented by the NATIVE_TOKEN constant.
     * @param memo The message attached to the payment. If present, the router will take a fee.
     * @param amount The amount to pay before any price feeds are applied. This amount will be converted by the price
     * feeds and then the sender will pay the converted amount in the given token.
     * @param priceFeeds Array of Chainlink price feeds. See `exchangeRate` method for more details.
     * @param token Token address to be used for the payment. Either an ERC20 token or the native token address.
     * @param receiver Address to receive the payment
     * @param extraFeeReceiver Address to receive an extra fee that is taken from the payment amount
     * @param extraFeeBps Size of the extra fee in terms of basis points (or 0 for none)
     * @return Boolean representing whether the payment was successful
     */
    function yodlWithToken(
        bytes32 memo,
        uint256 amount,
        address[2] calldata priceFeeds,
        address token,
        address receiver,
        address extraFeeReceiver,
        uint256 extraFeeBps
    ) external payable returns (bool) {
        require(amount != 0, "invalid amount");

        // transform amount with priceFeeds
        if (priceFeeds[0] != address(0) || priceFeeds[1] != address(0)) {
            {
                int256[2] memory prices;
                address[2] memory priceFeedsUsed;
                (amount, priceFeedsUsed, prices) = exchangeRate(
                    priceFeeds,
                    amount
                );
                emit Convert(
                    priceFeedsUsed[0],
                    priceFeedsUsed[1],
                    prices[0],
                    prices[1]
                );
            }
        }

        if (token != NATIVE_TOKEN) {
            // ERC20 token
            require(
                IERC20(token).allowance(msg.sender, address(this)) >= amount,
                "insufficient allowance"
            );
        } else {
            // Native ether
            require(msg.value >= amount, "insufficient gas provided");
        }

        uint256 totalFee = 0;

        if (memo != "") {
            totalFee += transferFee(
                amount,
                baseFeeBps,
                token,
                token == NATIVE_TOKEN ? address(this) : msg.sender,
                feeTreasury
            );
        }

        if (extraFeeReceiver != address(0)) {
            // 50% maximum extra fee
            require(extraFeeBps < MAX_FEE_BPS, "extraFeeBps too high");

            totalFee += transferFee(
                amount,
                extraFeeBps,
                token,
                token == NATIVE_TOKEN ? address(this) : msg.sender,
                extraFeeReceiver
            );
        }

        // Transfer to receiver
        if (token != NATIVE_TOKEN) {
            // ERC20 token
            TransferHelper.safeTransferFrom(
                token,
                msg.sender,
                receiver,
                amount - totalFee
            );
        } else {
            // Native ether
            (bool success, ) = receiver.call{value: amount - totalFee}("");
            require(success, "transfer failed");
            emit YodlNativeTokenTransfer(msg.sender, receiver, amount - totalFee);
        }

        emit Yodl(msg.sender, receiver, token, amount, totalFee, memo);

        return true;
    }

    /// @notice Handles a payment with a swap through Uniswap
    /// @dev This needs to have a valid Uniswap router or it will revert. Excess tokens from the swap as a result
    /// of slippage are in terms of the token in.
    /// @param params Struct that contains all the relevant parameters. See `YodlUniswapParams` for more details.
    /// @return The amount spent in terms of token in by Uniswap to complete this payment
    function yodlWithUniswap(
        YodlUniswapParams calldata params
    ) external payable returns (uint256) {
        require(
            address(uniswapRouter) != address(0),
            "uniswap router not present"
        );
        (address tokenOut, address tokenIn) = decodeTokenInTokenOut(
            params.path,
            params.swapType
        );
        uint256 amountSpent;

        // This is how much the recipient needs to receive
        uint256 amountOutExpected;
        if (
            params.priceFeeds[0] != address(0) ||
            params.priceFeeds[1] != address(0)
        ) {
            // Convert amountOut from invoice currency to swap currency using price feed
            int256[2] memory prices;
            address[2] memory priceFeeds;
            (amountOutExpected, priceFeeds, prices) = exchangeRate(
                params.priceFeeds,
                params.amountOut
            );
            emit Convert(priceFeeds[0], priceFeeds[1], prices[0], prices[1]);
        } else {
            amountOutExpected = params.amountOut;
        }

        // There should be no other situation in which we send a transaction with native token
        if (msg.value != 0) {
            // Wrap the native token
            require(
                msg.value >= params.amountIn,
                "insufficient gas provided"
            );
            wrappedNativeToken.deposit{value: params.amountIn}();

            // Update the tokenIn to wrapped native token
            // wrapped native token has the same number of decimals as native token
            tokenIn = address(wrappedNativeToken);
        } else {
            // Transfer the ERC20 token from the sender to the YodlRouter
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                params.amountIn
            );
        }
        TransferHelper.safeApprove(
            tokenIn,
            address(uniswapRouter),
            params.amountIn
        );

        // Special case for when we want native token out
        bool useNativeToken = false;
        if (tokenOut == NATIVE_TOKEN) {
            useNativeToken = true;
            tokenOut = address(wrappedNativeToken);
        }

        if (params.swapType == SwapType.SINGLE) {
            uint24 poolFee = decodeSinglePoolFee(params.path);
            ISwapRouter.ExactOutputSingleParams
                memory routerParams = ISwapRouter.ExactOutputSingleParams({
                    tokenIn: tokenIn,
                    tokenOut: tokenOut,
                    fee: poolFee,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountOut: amountOutExpected,
                    amountInMaximum: params.amountIn,
                    sqrtPriceLimitX96: 0
                });

            amountSpent = uniswapRouter.exactOutputSingle(routerParams);
        } else {
            // We need to extract the path details so that we can use the tokenIn value from earlier which may have been replaced by WETH
            (, uint24 poolFee2, address tokenBase, uint24 poolFee1, ) = abi
                .decode(
                    params.path,
                    (address, uint24, address, uint24, address)
                );
            ISwapRouter.ExactOutputParams memory uniswapParams = ISwapRouter
                .ExactOutputParams({
                    path: abi.encodePacked(
                        tokenOut,
                        poolFee2,
                        tokenBase,
                        poolFee1,
                        tokenIn
                    ),
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountOut: amountOutExpected,
                    amountInMaximum: params.amountIn
                });

            amountSpent = uniswapRouter.exactOutput(uniswapParams);
        }

        // Handle unwrapping wrapped native token
        if (useNativeToken) {
            // Unwrap and use NATIVE_TOKEN address as tokenOut
            IWETH9(wrappedNativeToken).withdraw(amountOutExpected);
            tokenOut = NATIVE_TOKEN;
        }

        // Calculate fee from amount out
        uint256 totalFee = 0;
        if (params.memo != "") {
            totalFee += calculateFee(amountOutExpected, baseFeeBps);
        }

        // Handle extra fees
        if (params.extraFeeReceiver != address(0)) {
            // 50% maximum extra fee
            require(params.extraFeeBps < MAX_FEE_BPS, "extraFee too high");

            totalFee += transferFee(
                amountOutExpected,
                params.extraFeeBps,
                tokenOut,
                address(this),
                params.extraFeeReceiver
            );
        }

        if (tokenOut == NATIVE_TOKEN) {
            (bool success, ) = params.receiver.call{
                value: amountOutExpected - totalFee
            }("");
            require(success, "transfer failed");
            emit YodlNativeTokenTransfer(
                params.sender,
                params.receiver,
                amountOutExpected - totalFee
            );
        } else {
            // transfer tokens to receiver
            TransferHelper.safeTransfer(
                tokenOut,
                params.receiver,
                amountOutExpected - totalFee
            );
        }

        emit Yodl(
            params.sender,
            params.receiver,
            tokenOut,
            amountOutExpected,
            totalFee,
            params.memo
        );

        TransferHelper.safeApprove(tokenIn, address(uniswapRouter), 0);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the _uniswapRouter to spend 0.
        if (amountSpent < params.amountIn && params.returnRemainder == true) {
            uint256 remainder = params.amountIn - amountSpent;
            if (msg.value != 0) {
                // Unwrap wrapped native token and send to sender
                IWETH9(wrappedNativeToken).withdraw(remainder);
                (bool success, ) = params.sender.call{value: remainder}("");
                require(success, "transfer failed");
            } else {
                TransferHelper.safeTransfer(tokenIn, params.sender, remainder);
            }
        }

        return amountSpent;
    }

    /// @notice Handles a payment with a swap through Curve
    /// @dev This needs to have a valid Curve router or it will revert. Excess tokens from the swap as a result
    /// of slippage are in terms of the token out.
    /// @param params Struct that contains all the relevant parameters. See `YodlCurveParams` for more details.
    /// @return The amount received in terms of token out by the Curve swap
    function yodlWithCurve(
        YodlCurveParams calldata params
    ) external payable returns (uint256) {
        require(address(curveRouter) != address(0), "curve router not present");
        (address tokenOut, address tokenIn) = decodeTokenInTokenOutCurve(
            params.route
        );

        // This is how much the recipient needs to receive
        uint256 amountOutExpected;
        if (
            params.priceFeeds[0] != address(0) ||
            params.priceFeeds[1] != address(0)
        ) {
            // Convert amountOut from invoice currency to swap currency using price feed
            int256[2] memory prices;
            address[2] memory priceFeeds;
            (amountOutExpected, priceFeeds, prices) = exchangeRate(
                params.priceFeeds,
                params.amountOut
            );
            emit Convert(priceFeeds[0], priceFeeds[1], prices[0], prices[1]);
        } else {
            amountOutExpected = params.amountOut;
        }

        // There should be no other situation in which we send a transaction with native token
        if (msg.value != 0) {
            // Wrap the native token
            require(
                msg.value >= params.amountIn,
                "insufficient gas provided"
            );
            wrappedNativeToken.deposit{value: params.amountIn}();

            // Update the tokenIn to wrapped native token
            // wrapped native token has the same number of decimals as native token
            // wrapped native token is already the first token in the route parameter
            tokenIn = address(wrappedNativeToken);
        } else {
            // Transfer the ERC20 token from the sender to the YodlRouter
            TransferHelper.safeTransferFrom(
                tokenIn,
                msg.sender,
                address(this),
                params.amountIn
            );
        }
        TransferHelper.safeApprove(
            tokenIn,
            address(curveRouter),
            params.amountIn
        );

        // Make the swap - the YodlRouter will receive the tokens
        uint256 amountOut = curveRouter.exchange_multiple(
            params.route,
            params.swapParams,
            params.amountIn,
            amountOutExpected, // this will revert if we do not get at least this amount
            params.factoryAddresses, // this is for zap contracts
            address(this) // the Yodl router will receive the tokens
        );

        // Handle fees for the transaction - in terms out the token out
        uint256 totalFee = 0;
        if (params.memo != "") {
            totalFee += calculateFee(amountOutExpected, baseFeeBps);
        }

        // Handle extra fees
        if (params.extraFeeReceiver != address(0)) {
            // 50% maximum extra fee
            require(params.extraFeeBps < MAX_FEE_BPS, "extraFee too high");

            totalFee += transferFee(
                amountOutExpected,
                params.extraFeeBps,
                tokenOut,
                address(this),
                params.extraFeeReceiver
            );
        }

        if (tokenOut == NATIVE_TOKEN) {
            // Need to transfer native token to receiver
            (bool success, ) = params.receiver.call{
                value: amountOutExpected - totalFee
            }("");
            require(success, "transfer failed");
            emit YodlNativeTokenTransfer(
                params.sender,
                params.receiver,
                amountOutExpected - totalFee
            );
        } else {
            // Transfer tokens to receiver
            TransferHelper.safeTransfer(
                tokenOut,
                params.receiver,
                amountOutExpected - totalFee
            );
        }
        emit Yodl(
            params.sender,
            params.receiver,
            tokenOut,
            amountOutExpected,
            totalFee,
            params.memo
        );

        uint256 remainder = amountOut - amountOutExpected;
        if (remainder > 0 && params.returnRemainder) {
            if (tokenOut == NATIVE_TOKEN) {
                // Transfer remainder native token to sender
                (bool success, ) = params.sender.call{value: remainder}("");
                require(success, "transfer failed");
            } else {
                // Return the additional token out amount to the sender
                TransferHelper.safeTransfer(tokenOut, params.sender, remainder);
            }
        }

        return amountOut;
    }

    /// @notice Transfers all fees or slippage collected by the router to the treasury address
    /// @param token The address of the token we want to transfer from the router
    function sweep(address token) external onlyOwner {
        if (token == NATIVE_TOKEN) {
            // transfer native token out of contract
            (bool success, ) = feeTreasury.call{value: address(this).balance}(
                ""
            );
            require(success, "transfer failed in sweep");
        } else {
            // transfer ERC20 contract
            TransferHelper.safeTransfer(
                token,
                feeTreasury,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    /**
     * @notice Calculates exchange rates from a given price feed
     * @dev At most we can have 2 price feeds.
     *
     * We will use a zero address to determine if we need to inverse a singular price feeds.
     *
     * For multiple price feeds, we will always pass them in such that we multiply by the first and divide by the second.
     * This works because all of our price feeds have USD as the quote currency.
     *
     * a) CHF_USD/_______    =>  85 CHF invoiced, 100 USD sent
     * b) _______/CHF_USD    => 100 USD invoiced,  85 CHF sent
     * c) ETH_USD/CHF_USD    => ETH invoiced,         CHF sent
     *
     * The second pricefeed is inversed. So in b) and c) `CHF_USD` turns into `USD_CHF`.
     *
     * @param priceFeeds Array of Chainlink price feeds
     * @param amount Amount to be converted by the price feed exchange rates
     * @return converted The amount after conversion
     * @return priceFeedsUsed The price feeds in the order they were used
     * @return prices The exchange rates from the price feeds
     */
    function exchangeRate(
        address[2] calldata priceFeeds,
        uint256 amount
    )
        public
        view
        returns (
            uint256 converted,
            address[2] memory priceFeedsUsed,
            int256[2] memory prices
        )
    {
        require(
            priceFeeds[0] != address(0) || priceFeeds[1] != address(0),
            "invalid pricefeeds"
        );

        bool shouldInverse;

        AggregatorV3Interface priceFeedOne;
        AggregatorV3Interface priceFeedTwo; // might not exist

        if (priceFeeds[0] == address(0)) {
            // Inverse the price feed. invoiceAmount: USD, settlementAmount: CHF
            shouldInverse = true;
            priceFeedOne = AggregatorV3Interface(priceFeeds[1]);
        } else {
            // No need to inverse. invoiceAmount: CHF, settlementAmount: USD
            priceFeedOne = AggregatorV3Interface(priceFeeds[0]);
            if (priceFeeds[1] != address(0)) {
                // Multiply by the first, divide by the second
                // Will always be A -> USD -> B
                priceFeedTwo = AggregatorV3Interface(priceFeeds[1]);
            }
        }

        // Calculate the converted value using price feeds
        uint256 decimals = uint256(10 ** uint256(priceFeedOne.decimals()));
        (, int256 price, , , ) = priceFeedOne.latestRoundData();
        prices[0] = price;
        if (shouldInverse) {
            converted = (amount * decimals) / uint256(price);
        } else {
            converted = (amount * uint256(price)) / decimals;
        }

        // We will always divide by the second price feed
        if (address(priceFeedTwo) != address(0)) {
            decimals = uint256(10 ** uint256(priceFeedTwo.decimals()));
            (, price, , , ) = priceFeedTwo.latestRoundData();
            prices[1] = price;
            converted = (converted * decimals) / uint256(price);
        }

        return (
            converted,
            [address(priceFeedOne), address(priceFeedTwo)],
            prices
        );
    }

    /// @notice Helper function to calculate fees
    /// @dev A basis point is 0.01% -> 1/10000 is one basis point
    /// So multiplying by the amount of basis points then dividing by 10000
    /// will give us the fee as a portion of the original amount, expressed in terms of basis points.
    ///
    /// Overflows are allowed to occur at ridiculously large amounts.
    /// @param amount The amount to calculate the fee for
    /// @param feeBps The size of the fee in terms of basis points
    /// @return The fee
    function calculateFee(
        uint256 amount,
        uint256 feeBps
    ) public pure returns (uint256) {
        return (amount * feeBps) / 10_000;
    }

    /// @notice Helper method to determine the token in and out from a Uniswap path
    /// @param path The path for a Uniswap swap
    /// @param swapType Enum for whether the swap is a single hop or multiple hop
    /// @return The tokenOut and tokenIn
    function decodeTokenInTokenOut(
        bytes memory path,
        SwapType swapType
    ) internal pure returns (address, address) {
        address tokenOut;
        address tokenIn;
        if (swapType == SwapType.SINGLE) {
            (tokenOut, , tokenIn) = abi.decode(
                path,
                (address, uint24, address)
            );
        } else {
            (tokenOut, , , , tokenIn) = abi.decode(
                path,
                (address, uint24, address, uint24, address)
            );
        }
        return (tokenOut, tokenIn);
    }

    /// @notice Helper method to get the fee for a single hop swap for Uniswap
    /// @param path The path for a Uniswap swap
    /// @return The pool fee for given swap path
    function decodeSinglePoolFee(
        bytes memory path
    ) internal pure returns (uint24) {
        (, uint24 poolFee, ) = abi.decode(path, (address, uint24, address));
        return poolFee;
    }

    /// @notice Helper method to determine the token in and out from a Curve route
    /// @param route Route for a Curve swap in the form of [token, pool address, token...] with zero addresses once the
    /// swap has completed
    /// @return The tokenOut and tokenIn
    function decodeTokenInTokenOutCurve(
        address[9] memory route
    ) internal pure returns (address, address) {
        address tokenIn = route[0];
        address tokenOut = route[2];
        // Output tokens can be located at indices 2, 4, 6 or 8, if the loop finds nothing, then it is index 2
        for (uint i = 4; i >= 2; i--) {
            if (route[i * 2] != address(0)) {
                tokenOut = route[i * 2];
                break;
            }
        }
        require(tokenOut != address(0), "Invalid route parameter");
        return (tokenOut, tokenIn);
    }

    /// @notice Calculates and transfers fee directly from an address to another
    /// @dev This can be used for directly transferring the Yodl fee from the sender to the treasury, or transferring
    /// the extra fee to the extra fee receiver.
    /// @param amount Amount from which to calculate the fee
    /// @param feeBps The size of the fee in basis points
    /// @param token The token which is being used to pay the fee. Can be an ERC20 token or the native token
    /// @param from The address from which we are transferring the fee
    /// @param to The address to which the fee will be sent
    /// @return The fee sent
    function transferFee(
        uint256 amount,
        uint256 feeBps,
        address token,
        address from,
        address to
    ) private returns (uint256) {
        uint256 fee = calculateFee(amount, feeBps);
        if (fee > 0) {
            if (token != NATIVE_TOKEN) {
                // ERC20 token
                if (from == address(this)) {
                    TransferHelper.safeTransfer(token, to, fee);
                } else {
                    // safeTransferFrom requires approval
                    TransferHelper.safeTransferFrom(token, from, to, fee);
                }
            } else {
                require(
                    from == address(this),
                    "can only transfer eth from the router address"
                );

                // Native ether
                (bool success, ) = to.call{value: fee}("");
                require(success, "transfer failed in transferFee");
            }
            return fee;
        } else {
            return 0;
        }
    }
}