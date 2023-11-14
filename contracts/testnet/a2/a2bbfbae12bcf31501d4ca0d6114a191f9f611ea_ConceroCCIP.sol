// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CCIPReceiver} from "@ccip/CCIPReceiver.sol";
import {IRouterClient} from "@ccip/interfaces/IRouterClient.sol";
import {Client} from "@ccip/libraries/Client.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {Ownable2Step} from "@openzeppelin/access/Ownable2Step.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

/// @title Contract for transferring tokens across chains.
contract ConceroCCIP is CCIPReceiver, Ownable2Step {
    using SafeERC20 for IERC20;

    /// TYPES ///

    /// @param token The address of token to swap.
    /// @param amount The amount of token to swap.
    /// @param target The address of DEX to process swap.
    /// @param callData The calldata for the swap.
    struct SwapData {
        address token;
        uint256 amount;
        address target;
        bytes callData;
    }

    /// CONSTANTS ///

    /// @notice The address of the LINK token.
    IERC20 public immutable linkToken;

    /// STORAGE ///

    /// @notice Mapping to keep track of allowlisted destination chains.
    mapping(uint64 => bool) public allowedDstChains;

    /// @notice Mapping to keep track of allowlisted source chains.
    mapping(uint64 => bool) public allowedSrcChains;

    /// @notice Mapping to keep track of allowlisted senders.
    mapping(address => bool) public allowedSrcSenders;

    /// EVENTS ///

    /// @notice Emitted when the tokens are transferred.
    /// @param messageId The unique ID of the message.
    /// @param dstChainSelector The chain selector of the destination chain.
    /// @param receiver The address of the receiver on the destination chain.
    /// @param token The token address that was transferred.
    /// @param amount The token amount that was transferred.
    /// @param data The data being sent.
    /// @param feeToken The token address used to pay CCIP fees.
    /// @param fees The fees paid for sending the message.
    event TokensTransferred(
        bytes32 indexed messageId,
        uint64 indexed dstChainSelector,
        address receiver,
        address token,
        uint256 amount,
        bytes data,
        address feeToken,
        uint256 fees
    );

    /// @notice Emitted when a message is received from another chain.
    /// @param messageId The unique ID of the CCIP message.
    /// @param sourceChainSelector The chain selector of the source chain.
    /// @param sender The address of the sender from the source chain.
    /// @param token The token address that was transferred.
    /// @param amount The token amount that was transferred.
    /// @param data The data that was received.
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender,
        address token,
        uint256 amount,
        bytes data
    );

    /// @notice Emitted when sweep is called.
    /// @param token The address of token.
    ///              It can be zero address if recovering the chain's native token.
    /// @param amount Withdrawn amount of token.
    event Sweep(address token, uint256 amount);

    /// ERRORS ///

    error ConceroCCIP__NotEnoughNativeAssetForFee(
        uint256 msgValue, uint256 requiredAmount
    );
    error ConceroCCIP__DestinationChainIsNotAllowed(uint64 dstChainSelector);
    error ConceroCCIP__SourceChainIsNotAllowed(uint64 srcChainSelector);
    error ConceroCCIP__SourceSenderIsNotAllowed(address srcSender);
    error ConceroCCIP__SwapFailed(bytes message);

    /// MODIFIERS ///

    /// @dev Throws if the given dstChainSelector is not allowlisted.
    /// @param dstChainSelector The selector of the destination chain.
    modifier onlyAllowedDstChain(uint64 dstChainSelector) {
        if (!allowedDstChains[dstChainSelector]) {
            revert ConceroCCIP__DestinationChainIsNotAllowed(dstChainSelector);
        }
        _;
    }

    /// @dev Throws if the given srcChainSelector is not allowlisted.
    /// @param srcChainSelector The selector of the destination chain.
    modifier onlyAllowedSrcChain(uint64 srcChainSelector) {
        if (!allowedSrcChains[srcChainSelector]) {
            revert ConceroCCIP__SourceChainIsNotAllowed(srcChainSelector);
        }
        _;
    }

    /// @dev Throws if the given srcSender is not allowlisted.
    /// @param srcSender The address of the sender.
    modifier onlyAllowedSrcSender(address srcSender) {
        if (!allowedSrcSenders[srcSender]) {
            revert ConceroCCIP__SourceSenderIsNotAllowed(srcSender);
        }
        _;
    }

    /// CONSTRUCTOR ///

    /// @notice Initializes the contract with the router address and Link address.
    /// @param router_ The address of the router contract.
    /// @param link_ The address of the LINK token.
    constructor(address router_, address link_) CCIPReceiver(router_) {
        linkToken = IERC20(link_);
    }

    /// EXTERNAL FUNCTIONS ///

    /// @notice Updates the allowlist status of destination chains.
    /// @param dstChainSelectors The array of selector of the destination chains.
    /// @param allowed The allowlist status to be set for the destination chains.
    function allowDestinationChains(
        uint64[] calldata dstChainSelectors,
        bool[] calldata allowed
    ) external onlyOwner {
        uint256 numSelectors = dstChainSelectors.length;

        for (uint256 i = 0; i < numSelectors; ++i) {
            allowedDstChains[dstChainSelectors[i]] = allowed[i];
        }
    }

    /// @notice Updates the allowlist status of a source chain.
    /// @param srcChainSelectors The array of selector of the source chains.
    /// @param allowed The allowlist status to be set for the source chains.
    function allowSourceChains(
        uint64[] calldata srcChainSelectors,
        bool[] calldata allowed
    ) external onlyOwner {
        uint256 numSelectors = srcChainSelectors.length;

        for (uint256 i = 0; i < numSelectors; ++i) {
            allowedSrcChains[srcChainSelectors[i]] = allowed[i];
        }
    }

    /// @notice Updates the allowlist status of source senders.
    /// @param srcSenders The array of address of the senders.
    /// @param allowed The allowlist status to be set for the source senders.
    function allowSourceSenders(
        address[] calldata srcSenders,
        bool[] calldata allowed
    ) external onlyOwner {
        uint256 numSenders = srcSenders.length;

        for (uint256 i = 0; i < numSenders; ++i) {
            allowedSrcSenders[srcSenders[i]] = allowed[i];
        }
    }

    /// @notice Transfer tokens to receiver on the destination chain.
    /// @dev The token must be in the list of supported tokens.
    /// @param swapDatas The array of struct data for swap.
    /// @param dstChainSelector The identifier for the destination chain.
    /// @param receiver The address of the recipient on the destination chain.
    /// @param token The address of token to transfer.
    /// @param amount The amount of token to transfer.
    /// @param data The data to be sent.
    /// @param payInLink Whether pay fee in Link or native token.
    function bridgeTokens(
        SwapData[] calldata swapDatas,
        uint64 dstChainSelector,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data,
        bool payInLink
    ) external payable onlyAllowedDstChain(dstChainSelector) {
        uint256 numSwapData = swapDatas.length;

        if (numSwapData > 0) {
            IERC20(swapDatas[0].token).safeTransferFrom(
                msg.sender, address(this), swapDatas[0].amount
            );

            for (uint256 i = 0; i < numSwapData; ++i) {
                _swapTokens(swapDatas[i]);
            }
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        _bridgeTokens(
            dstChainSelector, receiver, token, amount, data, payInLink
        );
    }

    function getFee(
        uint64 dstChainSelector,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data,
        bool payInLink
    ) external view returns (uint256) {
        // Effects: Create an EVM2AnyMessage struct with necessary information
        //          for sending a cross-chain message.
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(
            receiver,
            token,
            amount,
            data,
            payInLink ? address(linkToken) : address(0)
        );

        // Effects: Get the fee required to send the message.
        return IRouterClient(i_router).getFee(dstChainSelector, evm2AnyMessage);
    }

    /// @notice Withdraw any tokens accidentally sent to contract.
    /// @param token The address of token to withdraw.
    ///              It can be zero address for the chain's native token.
    /// @param amount The amount to withdraw.
    function sweep(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            msg.sender.call{value: amount}("");
        } else {
            IERC20(token).safeTransfer(msg.sender, amount);
        }

        emit Sweep(token, amount);
    }

    receive() external payable {}

    /// INTERNAL FUNCTIONS ///

    /// @notice handle a received message
    /// @param any2EvmMessage Any2EVMMessage struct which
    ///                       contains information for received CCIP message.
    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
        internal
        override
        onlyAllowedSrcChain(any2EvmMessage.sourceChainSelector)
        onlyAllowedSrcSender(abi.decode(any2EvmMessage.sender, (address)))
    {
        address token = any2EvmMessage.destTokenAmounts[0].token;
        uint256 amount = any2EvmMessage.destTokenAmounts[0].amount;

        // ToDo: Need to validate token of SwapData on source chain
        SwapData memory swapData = abi.decode(any2EvmMessage.data, (SwapData));

        _swapTokens(swapData);

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address)),
            token,
            amount,
            any2EvmMessage.data
        );
    }

    /// @notice Swap token on target DEX
    function _swapTokens(SwapData memory swapData) internal {
        _setAllowance(IERC20(swapData.token), swapData.target, swapData.amount);

        (bool success, bytes memory data) =
            swapData.target.call(swapData.callData);

        if (!success) {
            revert ConceroCCIP__SwapFailed(data);
        }
    }

    /// @notice Transfer tokens to receiver on the destination chain.
    /// @dev The token must be in the list of supported tokens.
    /// @param dstChainSelector The identifier for the destination chain.
    /// @param receiver The address of the recipient on the destination chain.
    /// @param token The address of token to transfer.
    /// @param amount The amount of token to transfer.
    /// @param data The data to be sent.
    /// @param payInLink Whether pay fee in Link or native token.
    function _bridgeTokens(
        uint64 dstChainSelector,
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data,
        bool payInLink
    ) internal {
        IRouterClient router = IRouterClient(i_router);

        address feeToken = payInLink ? address(linkToken) : address(0);

        // Effects: Create an EVM2AnyMessage struct with necessary information
        //          for sending a cross-chain message.
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(receiver, token, amount, data, feeToken);

        // Effects: Get the fee required to send the message.
        uint256 fees = router.getFee(dstChainSelector, evm2AnyMessage);

        // Requirements: Check fee token balance.
        if (payInLink) {
            linkToken.safeTransferFrom(msg.sender, address(this), fees);
        } else if (msg.value < fees) {
            revert ConceroCCIP__NotEnoughNativeAssetForFee(msg.value, fees);
        }

        if (payInLink) {
            // Effects: Approve the Router to transfer LINK tokens
            //          on contract's behalf.
            //          It will spend the fees in LINK.
            _setAllowance(linkToken, address(router), fees);
        }

        // Effects: Approve the Router to spend tokens on contract's behalf.
        //          It will spend the amount of the given token.
        _setAllowance(IERC20(token), address(router), amount);

        // Effects: Send the message through the router and store the returned
        //          message ID.
        bytes32 messageId = router.ccipSend{value: payInLink ? 0 : fees}(
            dstChainSelector, evm2AnyMessage
        );

        // Emit an event with message details
        emit TokensTransferred(
            messageId,
            dstChainSelector,
            receiver,
            token,
            amount,
            data,
            feeToken,
            fees
        );
    }

    /// @notice Construct a CCIP message.
    /// @param receiver The address of the receiver.
    /// @param token The token to be transferred.
    /// @param amount The amount of the token to be transferred.
    /// @param data The data to be sent.
    /// @param feeToken The address of the token used for fees.
    ///                 Set zero address for native gas.
    /// @return EVM2AnyMessage Returns an EVM2AnyMessage struct which
    ///                        contains information for sending a CCIP message.
    function _buildCCIPMessage(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data,
        address feeToken
    ) internal pure returns (Client.EVM2AnyMessage memory) {
        // Effects: Set the token amounts.
        Client.EVMTokenAmount[] memory tokenAmounts =
            new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({token: token, amount: amount});

        // Effects: Create an EVM2AnyMessage struct in memory with necessary
        //          information for sending a cross-chain message.
        return Client.EVM2AnyMessage({
            receiver: abi.encode(receiver), // ABI-encoded receiver address.
            data: data, //The data to be sent.
            tokenAmounts: tokenAmounts, // The amount and type of token.
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 0, strict: false})
                ),
            // Set the feeToken.
            feeToken: feeToken
        });
    }

    /// @notice Reset allowance of token for a spender.
    /// @dev Will only be called by setAllowance() and depositUnderlyingAsset().
    /// @param token Token of address to set allowance.
    /// @param spender Address to give spend approval to.
    function _clearAllowance(IERC20 token, address spender) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance > 0) {
            token.safeDecreaseAllowance(spender, allowance);
        }
    }

    /// @notice Set allowance of token for a spender.
    /// @dev Will only be called by initialDeposit(), depositTokens(),
    ///      depositToYieldTokens() and depositUnderlyingAsset().
    /// @param token Token of address to set allowance.
    /// @param spender Address to give spend approval to.
    /// @param amount Amount to approve for spending.
    function _setAllowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        _clearAllowance(token, spender);
        token.safeIncreaseAllowance(spender, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAny2EVMMessageReceiver} from
    "./interfaces/IAny2EVMMessageReceiver.sol";
import {Client} from "./libraries/Client.sol";
import {IERC165} from "@openzeppelin/utils/introspection/IERC165.sol";

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
    address internal immutable i_router;

    constructor(address router) {
        if (router == address(0)) revert InvalidRouter(address(0));
        i_router = router;
    }

    /// @notice IERC165 supports an interfaceId
    /// @param interfaceId The interfaceId to check
    /// @return true if the interfaceId is supported
    /// @dev Should indicate whether the contract implements IAny2EVMMessageReceiver
    /// e.g. return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId
    /// This allows CCIP to check if ccipReceive is available before calling it.
    /// If this returns false or reverts, only tokens are transferred to the receiver.
    /// If this returns true, tokens are transferred and ccipReceive is called atomically.
    /// Additionally, if the receiver address does not have code associated with
    /// it at the time of execution (EXTCODESIZE returns 0), only tokens will be transferred.
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IAny2EVMMessageReceiver).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IAny2EVMMessageReceiver
    function ccipReceive(Client.Any2EVMMessage calldata message)
        external
        virtual
        override
        onlyRouter
    {
        _ccipReceive(message);
    }

    /// @notice Override this function in your implementation.
    /// @param message Any2EVMMessage
    function _ccipReceive(Client.Any2EVMMessage memory message)
        internal
        virtual;

    /////////////////////////////////////////////////////////////////////
    // Plumbing
    /////////////////////////////////////////////////////////////////////

    /// @notice Return the current router
    /// @return i_router address
    function getRouter() public view returns (address) {
        return address(i_router);
    }

    error InvalidRouter(address router);

    /// @dev only calls from the set router are accepted.
    modifier onlyRouter() {
        if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IRouterClient {
    error UnsupportedDestinationChain(uint64 destChainSelector);
    error InsufficientFeeTokenAmount();
    error InvalidMsgValue();

    /// @notice Checks if the given chain ID is supported for sending/receiving.
    /// @param chainSelector The chain to check.
    /// @return supported is true if it is supported, false if not.
    function isChainSupported(uint64 chainSelector)
        external
        view
        returns (bool supported);

    /// @notice Gets a list of all supported tokens which can be sent or received
    /// to/from a given chain id.
    /// @param chainSelector The chainSelector.
    /// @return tokens The addresses of all tokens that are supported.
    function getSupportedTokens(uint64 chainSelector)
        external
        view
        returns (address[] memory tokens);

    /// @param destinationChainSelector The destination chainSelector
    /// @param message The cross-chain CCIP message including data and/or tokens
    /// @return fee returns guaranteed execution fee for the specified message
    /// delivery to destination chain
    /// @dev returns 0 fee on invalid message.
    function getFee(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage memory message
    ) external view returns (uint256 fee);

    /// @notice Request a message to be sent to the destination chain
    /// @param destinationChainSelector The destination chain ID
    /// @param message The cross-chain CCIP message including data and/or tokens
    /// @return messageId The message ID
    /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
    /// the overpayment with no refund.
    function ccipSend(
        uint64 destinationChainSelector,
        Client.EVM2AnyMessage calldata message
    ) external payable returns (bytes32);

    function getOnRamp(uint64 destinationChainSelector)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// End consumer library.
library Client {
    struct EVMTokenAmount {
        address token; // token address on the local chain.
        uint256 amount; // Amount of tokens.
    }

    struct Any2EVMMessage {
        bytes32 messageId; // MessageId corresponding to ccipSend on source.
        uint64 sourceChainSelector; // Source chain selector.
        bytes sender; // abi.decode(sender) if coming from an EVM chain.
        bytes data; // payload sent in original message.
        EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
    }

    // If extraArgs is empty bytes, the default is 200k gas limit and strict = false.
    struct EVM2AnyMessage {
        bytes receiver; // abi.encode(receiver address) for dest EVM chains
        bytes data; // Data payload
        EVMTokenAmount[] tokenAmounts; // Token transfers
        address feeToken; // Address of feeToken. address(0) means you will send msg.value.
        bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
    }

    // extraArgs will evolve to support new features
    // bytes4(keccak256("CCIP EVMExtraArgsV1"));
    bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;

    struct EVMExtraArgsV1 {
        uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR BETA TESTING
        bool strict; // See strict sequencing details below.
    }

    function _argsToBytes(EVMExtraArgsV1 memory extraArgs)
        internal
        pure
        returns (bytes memory bts)
    {
        return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
    /// @notice Called by the Router to deliver a message.
    /// If this reverts, any token transfers also revert. The message
    /// will move to a FAILED state and become available for manual execution.
    /// @param message CCIP Message
    /// @dev Note ensure you check the msg.sender is the OffRampRouter
    function ccipReceive(Client.Any2EVMMessage calldata message) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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