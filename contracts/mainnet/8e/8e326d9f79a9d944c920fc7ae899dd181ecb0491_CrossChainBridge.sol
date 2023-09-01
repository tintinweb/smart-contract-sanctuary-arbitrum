/**
 *Submitted for verification at Arbiscan.io on 2023-08-31
*/

// SPDX-License-Identifier: GPL-2.0-or-later AND MIT

pragma abicoder v2;

// File @uniswap/v3-core/contracts/interfaces/callback/[email protected]

// Original license: SPDX_License_Identifier: GPL-2.0-or-later
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


// File @uniswap/v3-periphery/contracts/interfaces/[email protected]

// Original license: SPDX_License_Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
// Original pragma directive: pragma abicoder v2

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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


// File @uniswap/v3-periphery/contracts/libraries/[email protected]

// Original license: SPDX_License_Identifier: GPL-2.0-or-later
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


// File contracts/cctp/interfaces/IAvaxSwapRouter.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.1;
interface IAvaxSwapRouter {
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


// File contracts/cctp/interfaces/IMessageTransmitter.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.1;

interface IMessageTransmitter {
    event MessageSent(bytes message);
    
    function receiveMessage(
        bytes calldata message, 
        bytes calldata attestation
    ) external returns (bool success);
}


// File contracts/cctp/interfaces/ITokenMessenger.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.1;

interface ITokenMessenger {
    
    event DepositForBurn(
        uint64 indexed nonce,
        address indexed burnToken,
        uint256 amount,
        address indexed depositor,
        bytes32 mintRecipient,
        uint32 destinationDomain,
        bytes32 destinationTokenMessenger,
        bytes32 destinationCaller
    );

    function depositForBurn(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken
    ) external returns (uint64 _nonce);
}


// File contracts/cctp/libraries/BridgeHelper.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.1;

abstract contract BridgeUtil {
    function addressToBytes32(address addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
    function bytes32ToAddress(bytes32 _buf) public pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}


// File contracts/cctp/Bridge.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.1;






contract CrossChainBridge is BridgeUtil {
    struct SupportedToken {
        address token;
        uint24 fee;
    }

    uint32 public immutable CCTP_DOMAIN;

    ISwapRouter public immutable swapRouter;
    IAvaxSwapRouter public immutable avaxSwapRouter;
    IERC20 public immutable usdcToken;
    ITokenMessenger public immutable tokenMessenger;
    IMessageTransmitter public immutable messageTransmitter;

    mapping(address => SupportedToken) public supportedTokens;
    mapping(address => bool) public bridgeAdmins;

    event BridgeDepositReceived(
        address indexed from,
        address indexed recipient,
        uint32 sourceChain,
        uint32 destinationChain,
        uint64 nonce,
        uint256 amount,
        address sourceToken,
        address destinationToken
    );
    event BridgeWithdrawalMade(
        address indexed recipient,
        uint64 nonce,
        uint256 amount,
        address indexed token
    );

    constructor(
        SupportedToken[] memory _supportedTokens,
        address swapRouterAddr,
        address usdcTokenAddr,
        address tokenMessengerAddr,
        address messageTransmitterAddr,
        uint32 domain
    ) {
        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            require(
                _supportedTokens[i].token != address(0),
                "Invalid Supported Token"
            );
            supportedTokens[_supportedTokens[i].token] = _supportedTokens[i];
        }
        swapRouter = ISwapRouter(swapRouterAddr);
        avaxSwapRouter = IAvaxSwapRouter(swapRouterAddr);
        usdcToken = IERC20(usdcTokenAddr);
        tokenMessenger = ITokenMessenger(tokenMessengerAddr);
        messageTransmitter = IMessageTransmitter(messageTransmitterAddr);
        CCTP_DOMAIN = domain;
        bridgeAdmins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(bridgeAdmins[msg.sender], "Not Permitted");
        _;
    }

    function performSwap(
        address _tokenIn,
        address _tokenOut,
        address _recipient,
        uint256 amount
    ) internal returns (uint256 amountOut) {
        // Approve UNISWAP Router to spend token
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), amount);
        // Swap The token for USDC
        if (CCTP_DOMAIN == 1) {
            IAvaxSwapRouter.ExactInputSingleParams
                memory params = IAvaxSwapRouter.ExactInputSingleParams({
                    tokenIn: _tokenIn,
                    tokenOut: _tokenOut,
                    fee: supportedTokens[_tokenIn].fee,
                    recipient: _recipient,
                    amountIn: amount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
            amountOut = avaxSwapRouter.exactInputSingle(params);
        } else {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
                .ExactInputSingleParams({
                    tokenIn: _tokenIn,
                    tokenOut: _tokenOut,
                    fee: supportedTokens[_tokenIn].fee,
                    recipient: _recipient,
                    deadline: block.timestamp,
                    amountIn: amount,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });
            amountOut = swapRouter.exactInputSingle(params);
        }
    }

    /**
     * @notice Deposit an amount of a supported token to the bridge
     * @param amount Amount of tokens to be deposited to the bridge
     * @param sourceToken The supported token address to be deposited
     * @param destinationToken The supported token on the destination chain that the user receives
     * @param recipient The address to receive the destination token on the destination chain
     * @param destinationDomain CCTP Domain identifier of the destination chain
     * @param destinationContract Address of the contract on the destination chain where cctp sends the token
     */
    function deposit(
        uint256 amount,
        address sourceToken,
        address destinationToken,
        uint32 destinationDomain,
        address recipient,
        address destinationContract
    ) public returns (uint64) {
        require(
            supportedTokens[sourceToken].token != address(0),
            "Source Token not supported"
        );
        require(
            supportedTokens[destinationToken].token != address(0),
            "Destination Token not supported"
        );
        // Transfer the token from the caller to the bridge contract
        TransferHelper.safeTransferFrom(
            sourceToken,
            msg.sender,
            address(this),
            amount
        );
        uint256 amountOut = amount;

        if (sourceToken != address(usdcToken)) {
            amountOut = performSwap(
                sourceToken,
                address(usdcToken),
                address(this),
                amount
            );
        }

        // Approve Token Messenger to Spend the swapped amount
        TransferHelper.safeApprove(
            address(usdcToken),
            address(tokenMessenger),
            amountOut
        );
        // Move the USDC To CCTP Contract
        uint64 nonce = tokenMessenger.depositForBurn(
            amountOut,
            destinationDomain,
            addressToBytes32(destinationContract),
            address(usdcToken)
        );
        emit BridgeDepositReceived(
            msg.sender,
            recipient,
            CCTP_DOMAIN,
            destinationDomain,
            nonce,
            amountOut,
            sourceToken,
            destinationToken
        );
        return nonce;
    }

    /**
     * @notice Method to add token to the list of supported tokens. Only admin can call this method
     * @param token Address of the token
     * @param fee UNISWAP Fee TIER for swaps
     */
    function addToken(address token, uint24 fee) public onlyAdmin {
        require(token != address(0), "Invalid token address");
        SupportedToken storage newToken = supportedTokens[token];
        newToken.token = token;
        newToken.fee = fee;
    }

    /**
     * @notice Method to remove token from the list of supported tokens. Only admin can call this method
     * @param _token Address of the token
     */
    function removeToken(address _token) public onlyAdmin {
        require(_token != address(0), "Invalid token address");
        SupportedToken storage token = supportedTokens[_token];
        token.token = address(0);
        token.fee = 0;
    }

    /**
     * @notice Method to add admin to the bridge contract
     * @param _admin Address of the admin
     */
    function addAdmin(address _admin) public onlyAdmin {
        require(_admin != address(0), "Invalid Address");
        bridgeAdmins[_admin] = true;
    }

    /**
     * @notice Method to remove admin to the bridge contract
     * @param _admin Address of the admin
     */
    function removeAdmin(address _admin) public onlyAdmin {
        require(_admin != address(0), "Invalid Address");
        bridgeAdmins[_admin] = false;
    }

    /**
     * @notice Method to recieve tokens and transfer to the recipient on the destination chain. Only a contract admin can call this method
     * @param message cctp contract message from source chain
     * @param signature attestation from cctp attestation API for the message
     * @param nonce message nonce from cctp contract
     * @param amount Amount of destination token to be sent to recipient
     * @param destinationToken Token on the recipient receives
     * @param recipientAddress address of the recipient
     */
    function sendToRecipient(
        bytes calldata message,
        bytes calldata signature,
        uint64 nonce,
        uint256 amount,
        address destinationToken,
        address recipientAddress
    ) public onlyAdmin {
        require(
            messageTransmitter.receiveMessage(message, signature),
            "Receive Message Failed"
        );
        uint256 amountOut = amount;
        if (destinationToken != address(usdcToken)) {
            amountOut = performSwap(
                address(usdcToken),
                destinationToken,
                recipientAddress,
                amount
            );
        } else {
            usdcToken.transfer(recipientAddress, amountOut);
        }
        emit BridgeWithdrawalMade(
            recipientAddress,
            nonce,
            amountOut,
            destinationToken
        );
    }

    /**
     * @notice Method to withdraw USDC Fees. Only a contract admin can call this method
     * @param amount Amount of destination token to be sent to recipient
     */
    function withdraw(
        uint256 amount
    ) public onlyAdmin {
        TransferHelper.safeTransfer(address(usdcToken), msg.sender, amount);
    }
}