// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IMintableERC20} from "../interfaces/IMintableERC20.sol";
import {IConnector} from "../interfaces/IConnector.sol";
import "lib/solmate/src/utils/SafeTransferLib.sol";
import "../interfaces/IHook.sol";
import "../common/Errors.sol";
import "lib/solmate/src/utils/ReentrancyGuard.sol";
import "../interfaces/IBridge.sol";
import "../utils/RescueBase.sol";
import "../common/Constants.sol";

abstract contract Base is ReentrancyGuard, IBridge, RescueBase {
    address public immutable token;
    bytes32 public bridgeType;
    IHook public hook__;
    // message identifier => cache
    mapping(bytes32 => bytes) public identifierCache;

    // connector => cache
    mapping(address => bytes) public connectorCache;

    mapping(address => bool) public validConnectors;

    event ConnectorStatusUpdated(address connector, bool status);

    event HookUpdated(address newHook);

    event BridgingTokens(
        address connector,
        address sender,
        address receiver,
        uint256 amount,
        bytes32 messageId
    );
    event TokensBridged(
        address connecter,
        address receiver,
        uint256 amount,
        bytes32 messageId
    );

    constructor(address token_) AccessControl(msg.sender) {
        if (token_ != ETH_ADDRESS && token_.code.length == 0)
            revert InvalidTokenContract();
        token = token_;
        _grantRole(RESCUE_ROLE, msg.sender);
    }

    /**
     * @notice this function is used to update hook
     * @dev it can only be updated by owner
     * @dev should be carefully migrated as it can risk user funds
     * @param hook_ new hook address
     */
    function updateHook(
        address hook_,
        bool approve_
    ) external virtual onlyOwner {
        // remove the approval from the old hook
        if (token != ETH_ADDRESS) {
            if (ERC20(token).allowance(address(this), address(hook__)) > 0) {
                SafeTransferLib.safeApprove(ERC20(token), address(hook__), 0);
            }
            if (approve_) {
                SafeTransferLib.safeApprove(
                    ERC20(token),
                    hook_,
                    type(uint256).max
                );
            }
        }
        hook__ = IHook(hook_);

        emit HookUpdated(hook_);
    }

    function updateConnectorStatus(
        address[] calldata connectors,
        bool[] calldata statuses
    ) external onlyOwner {
        uint256 length = connectors.length;
        for (uint256 i; i < length; i++) {
            validConnectors[connectors[i]] = statuses[i];
            emit ConnectorStatusUpdated(connectors[i], statuses[i]);
        }
    }

    /**
     * @notice Executes pre-bridge operations before initiating a token bridge transfer.
     * @dev This internal function is called before initiating a token bridge transfer.
     * It validates the receiver address and the connector, and if a pre-hook contract is defined,
     * it executes the source pre-hook call.
     * @param connector_ The address of the connector responsible for the transfer.
     * @param transferInfo_ Information about the transfer.
     * @return transferInfo Information about the transfer after pre-bridge operations.
     * @return postHookData Data returned from the pre-hook call.
     * @dev Reverts with `ZeroAddressReceiver` if the receiver address is zero.
     * Reverts with `InvalidConnector` if the connector address is not valid.
     */
    function _beforeBridge(
        address connector_,
        TransferInfo memory transferInfo_
    )
        internal
        returns (TransferInfo memory transferInfo, bytes memory postHookData)
    {
        if (transferInfo_.receiver == address(0)) revert ZeroAddressReceiver();
        if (!validConnectors[connector_]) revert InvalidConnector();
        if (token == ETH_ADDRESS && msg.value < transferInfo_.amount)
            revert InsufficientMsgValue();

        if (address(hook__) != address(0)) {
            (transferInfo, postHookData) = hook__.srcPreHookCall(
                SrcPreHookCallParams(connector_, msg.sender, transferInfo_)
            );
        }
    }

    /**
     * @notice Executes post-bridge operations after completing a token bridge transfer.
     * @dev This internal function is called after completing a token bridge transfer.
     * It executes the source post-hook call if a hook contract is defined, calculates fees,
     * calls the outbound function of the connector, and emits an event for tokens withdrawn.
     * @param msgGasLimit_ The gas limit for the outbound call.
     * @param connector_ The address of the connector responsible for the transfer.
     * @param options_ Additional options for the outbound call.
     * @param postSrcHookData_ Data returned from the source post-hook call.
     * @param transferInfo_ Information about the transfer.
     * @dev Reverts with `MessageIdMisMatched` if the returned message ID does not match the expected message ID.
     */
    function _afterBridge(
        uint256 msgGasLimit_,
        address connector_,
        bytes memory options_,
        bytes memory postSrcHookData_,
        TransferInfo memory transferInfo_
    ) internal {
        TransferInfo memory transferInfo = transferInfo_;
        if (address(hook__) != address(0)) {
            transferInfo = hook__.srcPostHookCall(
                SrcPostHookCallParams(
                    connector_,
                    options_,
                    postSrcHookData_,
                    transferInfo_
                )
            );
        }

        uint256 fees = token == ETH_ADDRESS
            ? msg.value - transferInfo.amount
            : msg.value;

        bytes32 messageId = IConnector(connector_).getMessageId();
        bytes32 returnedMessageId = IConnector(connector_).outbound{
            value: fees
        }(
            msgGasLimit_,
            abi.encode(
                transferInfo.receiver,
                transferInfo.amount,
                messageId,
                transferInfo.data
            ),
            options_
        );
        if (returnedMessageId != messageId) revert MessageIdMisMatched();

        emit BridgingTokens(
            connector_,
            msg.sender,
            transferInfo.receiver,
            transferInfo.amount,
            messageId
        );
    }

    /**
     * @notice Executes pre-mint operations before minting tokens.
     * @dev This internal function is called before minting tokens.
     * It validates the caller as a valid connector, checks if the receiver is not this contract, the bridge contract,
     * or the token contract, and executes the destination pre-hook call if a hook contract is defined.
     * @param transferInfo_ Information about the transfer.
     * @return postHookData Data returned from the destination pre-hook call.
     * @return transferInfo Information about the transfer after pre-mint operations.
     * @dev Reverts with `InvalidConnector` if the caller is not a valid connector.
     * Reverts with `CannotTransferOrExecuteOnBridgeContracts` if the receiver is this contract, the bridge contract,
     * or the token contract.
     */
    function _beforeMint(
        uint32,
        TransferInfo memory transferInfo_
    )
        internal
        returns (bytes memory postHookData, TransferInfo memory transferInfo)
    {
        if (!validConnectors[msg.sender]) revert InvalidConnector();

        // no need of source check here, as if invalid caller, will revert with InvalidPoolId
        if (
            transferInfo_.receiver == address(this) ||
            // transferInfo_.receiver == address(bridge__) ||
            transferInfo_.receiver == token
        ) revert CannotTransferOrExecuteOnBridgeContracts();

        if (address(hook__) != address(0)) {
            (postHookData, transferInfo) = hook__.dstPreHookCall(
                DstPreHookCallParams(
                    msg.sender,
                    connectorCache[msg.sender],
                    transferInfo_
                )
            );
        }
    }

    /**
     * @notice Executes post-mint operations after minting tokens.
     * @dev This internal function is called after minting tokens.
     * It executes the destination post-hook call if a hook contract is defined and updates cache data.
     * @param messageId_ The unique identifier for the mint transaction.
     * @param postHookData_ Data returned from the destination pre-hook call.
     * @param transferInfo_ Information about the mint transaction.
     */
    function _afterMint(
        uint256,
        bytes32 messageId_,
        bytes memory postHookData_,
        TransferInfo memory transferInfo_
    ) internal {
        if (address(hook__) != address(0)) {
            CacheData memory cacheData = hook__.dstPostHookCall(
                DstPostHookCallParams(
                    msg.sender,
                    messageId_,
                    connectorCache[msg.sender],
                    postHookData_,
                    transferInfo_
                )
            );

            identifierCache[messageId_] = cacheData.identifierCache;
            connectorCache[msg.sender] = cacheData.connectorCache;
        }

        emit TokensBridged(
            msg.sender,
            transferInfo_.receiver,
            transferInfo_.amount,
            messageId_
        );
    }

    /**
     * @notice Executes pre-retry operations before retrying a failed transaction.
     * @dev This internal function is called before retrying a failed transaction.
     * It validates the connector, retrieves cache data for the given message ID,
     * and executes the pre-retry hook if defined.
     * @param connector_ The address of the connector responsible for the failed transaction.
     * @param messageId_ The unique identifier for the failed transaction.
     * @return postRetryHookData Data returned from the pre-retry hook call.
     * @return transferInfo Information about the transfer.
     * @dev Reverts with `InvalidConnector` if the connector is not valid.
     * Reverts with `NoPendingData` if there is no pending data for the given message ID.
     */
    function _beforeRetry(
        address connector_,
        bytes32 messageId_
    )
        internal
        returns (
            bytes memory postRetryHookData,
            TransferInfo memory transferInfo
        )
    {
        if (!validConnectors[connector_]) revert InvalidConnector();

        CacheData memory cacheData = CacheData(
            identifierCache[messageId_],
            connectorCache[connector_]
        );

        if (cacheData.identifierCache.length == 0) revert NoPendingData();
        (postRetryHookData, transferInfo) = hook__.preRetryHook(
            PreRetryHookCallParams(connector_, cacheData)
        );
    }

    /**
     * @notice Executes post-retry operations after retrying a failed transaction.
     * @dev This internal function is called after retrying a failed transaction.
     * It retrieves cache data for the given message ID, executes the post-retry hook if defined,
     * and updates cache data.
     * @param connector_ The address of the connector responsible for the failed transaction.
     * @param messageId_ The unique identifier for the failed transaction.
     * @param postRetryHookData Data returned from the pre-retry hook call.
     */
    function _afterRetry(
        address connector_,
        bytes32 messageId_,
        bytes memory postRetryHookData
    ) internal {
        CacheData memory cacheData = CacheData(
            identifierCache[messageId_],
            connectorCache[connector_]
        );

        (cacheData) = hook__.postRetryHook(
            PostRetryHookCallParams(
                connector_,
                messageId_,
                postRetryHookData,
                cacheData
            )
        );
        identifierCache[messageId_] = cacheData.identifierCache;
        connectorCache[connector_] = cacheData.connectorCache;
    }

    /**
     * @notice Retrieves the minimum fees required for a transaction from a connector.
     * @dev This function returns the minimum fees required for a transaction from the specified connector,
     * based on the provided message gas limit and payload size.
     * @param connector_ The address of the connector.
     * @param msgGasLimit_ The gas limit for the transaction.
     * @param payloadSize_ The size of the payload for the transaction.
     * @return totalFees The total minimum fees required for the transaction.
     */
    function getMinFees(
        address connector_,
        uint256 msgGasLimit_,
        uint256 payloadSize_
    ) external view returns (uint256 totalFees) {
        return IConnector(connector_).getMinFees(msgGasLimit_, payloadSize_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Base.sol";

contract Controller is Base {
    uint256 public totalMinted;

    constructor(address token_) Base(token_) {
        bridgeType = NORMAL_CONTROLLER;
    }

    /**
     * @notice Bridges tokens between chains.
     * @dev This function allows bridging tokens between different chains.
     * @param receiver_ The address to receive the bridged tokens.
     * @param amount_ The amount of tokens to bridge.
     * @param msgGasLimit_ The gas limit for the execution of the bridging process.
     * @param connector_ The address of the connector contract responsible for the bridge.
     * @param execPayload_ The payload for executing the bridging process on the connector.
     * @param options_ Additional options for the bridging process.
     */
    function bridge(
        address receiver_,
        uint256 amount_,
        uint256 msgGasLimit_,
        address connector_,
        bytes calldata execPayload_,
        bytes calldata options_
    ) external payable nonReentrant {
        (
            TransferInfo memory transferInfo,
            bytes memory postHookData
        ) = _beforeBridge(
                connector_,
                TransferInfo(receiver_, amount_, execPayload_)
            );

        // to maintain socket dl specific accounting for super token
        // re check this logic for mint and mint use cases and if other minter involved
        totalMinted -= transferInfo.amount;
        _burn(msg.sender, transferInfo.amount);
        _afterBridge(
            msgGasLimit_,
            connector_,
            options_,
            postHookData,
            transferInfo
        );
    }

    /**
     * @notice Receives inbound tokens from another chain.
     * @dev This function is used to receive tokens from another chain.
     * @param siblingChainSlug_ The identifier of the sibling chain.
     * @param payload_ The payload containing the inbound tokens.
     */
    function receiveInbound(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) external payable override nonReentrant {
        (
            address receiver,
            uint256 lockAmount,
            bytes32 messageId,
            bytes memory extraData
        ) = abi.decode(payload_, (address, uint256, bytes32, bytes));

        // convert to shares
        TransferInfo memory transferInfo = TransferInfo(
            receiver,
            lockAmount,
            extraData
        );
        bytes memory postHookData;
        (postHookData, transferInfo) = _beforeMint(
            siblingChainSlug_,
            transferInfo
        );

        _mint(transferInfo.receiver, transferInfo.amount);
        totalMinted += transferInfo.amount;

        _afterMint(lockAmount, messageId, postHookData, transferInfo);
    }

    /**
     * @notice Retry a failed transaction.
     * @dev This function allows retrying a failed transaction sent through a connector.
     * @param connector_ The address of the connector contract responsible for the failed transaction.
     * @param messageId_ The unique identifier of the failed transaction.
     */
    function retry(
        address connector_,
        bytes32 messageId_
    ) external nonReentrant {
        (
            bytes memory postRetryHookData,
            TransferInfo memory transferInfo
        ) = _beforeRetry(connector_, messageId_);
        _mint(transferInfo.receiver, transferInfo.amount);
        totalMinted += transferInfo.amount;

        _afterRetry(connector_, messageId_, postRetryHookData);
    }

    function _burn(address user_, uint256 burnAmount_) internal virtual {
        IMintableERC20(token).burn(user_, burnAmount_);
    }

    function _mint(address user_, uint256 mintAmount_) internal virtual {
        if (mintAmount_ == 0) return;
        IMintableERC20(token).mint(user_, mintAmount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IFiatTokenV2_1_Mintable} from "./IFiatTokenV2_1_Mintable.sol";
import "../Controller.sol";

contract FiatTokenV2_1_Controller is Controller {
    using SafeTransferLib for ERC20;

    constructor(address token_) Controller(token_) {
        bridgeType = FIAT_TOKEN_CONTROLLER;
    }

    function _burn(address user_, uint256 burnAmount_) internal override {
        ERC20(token).safeTransferFrom(user_, address(this), burnAmount_);
        IFiatTokenV2_1_Mintable(address(token)).burn(burnAmount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "lib/solmate/src/tokens/ERC20.sol";

// USDC's standard token
abstract contract IFiatTokenV2_1_Mintable is ERC20 {
    function mint(address receiver_, uint256 amount_) external virtual;

    function burn(uint256 _amount) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Base.sol";
import "../interfaces/IConnector.sol";
import "lib/solmate/src/tokens/ERC20.sol";

/**
 * @title SuperToken
 * @notice A contract which enables bridging a token to its sibling chains.
 * @dev This contract implements ISuperTokenOrVault to support message bridging through IMessageBridge compliant contracts.
 */
contract Vault is Base {
    using SafeTransferLib for ERC20;

    // /**
    //  * @notice constructor for creating a new SuperTokenVault.
    //  * @param token_ token contract address which is to be bridged.
    //  */

    constructor(address token_) Base(token_) {
        bridgeType = token_ == ETH_ADDRESS ? NATIVE_VAULT : ERC20_VAULT;
    }

    /**
     * @notice Bridges tokens between chains.
     * @dev This function allows bridging tokens between different chains.
     * @param receiver_ The address to receive the bridged tokens.
     * @param amount_ The amount of tokens to bridge.
     * @param msgGasLimit_ The gas limit for the execution of the bridging process.
     * @param connector_ The address of the connector contract responsible for the bridge.
     * @param execPayload_ The payload for executing the bridging process on the connector.
     * @param options_ Additional options for the bridging process.
     */
    function bridge(
        address receiver_,
        uint256 amount_,
        uint256 msgGasLimit_,
        address connector_,
        bytes calldata execPayload_,
        bytes calldata options_
    ) external payable nonReentrant {
        (
            TransferInfo memory transferInfo,
            bytes memory postHookData
        ) = _beforeBridge(
                connector_,
                TransferInfo(receiver_, amount_, execPayload_)
            );

        _receiveTokens(transferInfo.amount);

        _afterBridge(
            msgGasLimit_,
            connector_,
            options_,
            postHookData,
            transferInfo
        );
    }

    /**
     * @notice Receives inbound tokens from another chain.
     * @dev This function is used to receive tokens from another chain.
     * @param siblingChainSlug_ The identifier of the sibling chain.
     * @param payload_ The payload containing the inbound tokens.
     */
    function receiveInbound(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) external payable override nonReentrant {
        (
            address receiver,
            uint256 unlockAmount,
            bytes32 messageId,
            bytes memory extraData
        ) = abi.decode(payload_, (address, uint256, bytes32, bytes));

        TransferInfo memory transferInfo = TransferInfo(
            receiver,
            unlockAmount,
            extraData
        );

        bytes memory postHookData;
        (postHookData, transferInfo) = _beforeMint(
            siblingChainSlug_,
            transferInfo
        );

        _transferTokens(transferInfo.receiver, transferInfo.amount);

        _afterMint(unlockAmount, messageId, postHookData, transferInfo);
    }

    /**
     * @notice Retry a failed transaction.
     * @dev This function allows retrying a failed transaction sent through a connector.
     * @param connector_ The address of the connector contract responsible for the failed transaction.
     * @param messageId_ The unique identifier of the failed transaction.
     */
    function retry(
        address connector_,
        bytes32 messageId_
    ) external nonReentrant {
        (
            bytes memory postRetryHookData,
            TransferInfo memory transferInfo
        ) = _beforeRetry(connector_, messageId_);
        _transferTokens(transferInfo.receiver, transferInfo.amount);

        _afterRetry(connector_, messageId_, postRetryHookData);
    }

    function _transferTokens(address receiver_, uint256 amount_) internal {
        if (amount_ == 0) return;
        if (address(token) == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(receiver_, amount_);
        } else {
            ERC20(token).safeTransfer(receiver_, amount_);
        }
    }

    function _receiveTokens(uint256 amount_) internal {
        if (amount_ == 0 || address(token) == ETH_ADDRESS) return;
        ERC20(token).safeTransferFrom(msg.sender, address(this), amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

address constant ETH_ADDRESS = address(
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
);

bytes32 constant NORMAL_CONTROLLER = keccak256("NORMAL_CONTROLLER");
bytes32 constant FIAT_TOKEN_CONTROLLER = keccak256("FIAT_TOKEN_CONTROLLER");

bytes32 constant LIMIT_HOOK = keccak256("LIMIT_HOOK");
bytes32 constant LIMIT_EXECUTION_HOOK = keccak256("LIMIT_EXECUTION_HOOK");
bytes32 constant LIMIT_EXECUTION_YIELD_HOOK = keccak256(
    "LIMIT_EXECUTION_YIELD_HOOK"
);
bytes32 constant LIMIT_EXECUTION_YIELD_TOKEN_HOOK = keccak256(
    "LIMIT_EXECUTION_YIELD_TOKEN_HOOK"
);

bytes32 constant ERC20_VAULT = keccak256("ERC20_VAULT");
bytes32 constant NATIVE_VAULT = keccak256("NATIVE_VAULT");

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

error SiblingNotSupported();
error NotAuthorized();
error NotBridge();
error NotSocket();
error ConnectorUnavailable();
error InvalidPoolId();
error CannotTransferOrExecuteOnBridgeContracts();
error NoPendingData();
error MessageIdMisMatched();
error NotMessageBridge();
error InvalidSiblingChainSlug();
error InvalidTokenContract();
error InvalidExchangeRateContract();
error InvalidConnector();
error InvalidConnectorPoolId();
error ZeroAddressReceiver();
error ZeroAddress();
error ZeroAmount();
error DebtRatioTooHigh();
error NotEnoughAssets();
error VaultShutdown();
error InsufficientFunds();
error PermitDeadlineExpired();
error InvalidSigner();
error InsufficientMsgValue();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct UpdateLimitParams {
    bool isMint;
    address connector;
    uint256 maxLimit;
    uint256 ratePerSecond;
}

struct SrcPreHookCallParams {
    address connector;
    address msgSender;
    TransferInfo transferInfo;
}

struct SrcPostHookCallParams {
    address connector;
    bytes options;
    bytes postSrcHookData;
    TransferInfo transferInfo;
}

struct DstPreHookCallParams {
    address connector;
    bytes connectorCache;
    TransferInfo transferInfo;
}

struct DstPostHookCallParams {
    address connector;
    bytes32 messageId;
    bytes connectorCache;
    bytes postHookData;
    TransferInfo transferInfo;
}

struct PreRetryHookCallParams {
    address connector;
    CacheData cacheData;
}

struct PostRetryHookCallParams {
    address connector;
    bytes32 messageId;
    bytes postRetryHookData;
    CacheData cacheData;
}

struct TransferInfo {
    address receiver;
    uint256 amount;
    bytes data;
}

struct CacheData {
    bytes identifierCache;
    bytes connectorCache;
}

struct LimitParams {
    uint256 lastUpdateTimestamp;
    uint256 ratePerSecond;
    uint256 maxLimit;
    uint256 lastUpdateLimit;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./utils/RescueBase.sol";
import {ISocket} from "./interfaces/ISocket.sol";
import {IPlug} from "./interfaces/IPlug.sol";
import {IConnector} from "./interfaces/IConnector.sol";
import {IBridge} from "./interfaces/IBridge.sol";
import "./common/Errors.sol";

contract ConnectorPlug is IConnector, IPlug, RescueBase {
    IBridge public immutable bridge__;
    ISocket public immutable socket__;
    uint32 public immutable siblingChainSlug;
    uint256 public messageIdPart;

    event ConnectorPlugDisconnected();

    constructor(
        address bridge_,
        address socket_,
        uint32 siblingChainSlug_
    ) AccessControl(msg.sender) {
        bridge__ = IBridge(bridge_);
        socket__ = ISocket(socket_);
        siblingChainSlug = siblingChainSlug_;
        _grantRole(RESCUE_ROLE, msg.sender);
    }

    function outbound(
        uint256 msgGasLimit_,
        bytes memory payload_,
        bytes memory
    ) external payable override returns (bytes32 messageId_) {
        if (msg.sender != address(bridge__)) revert NotBridge();

        return
            socket__.outbound{value: msg.value}(
                siblingChainSlug,
                msgGasLimit_,
                bytes32(0),
                bytes32(0),
                payload_
            );
    }

    function inbound(
        uint32 siblingChainSlug_, // cannot be connected for any other slug, immutable variable
        bytes calldata payload_
    ) external payable override {
        if (msg.sender != address(socket__)) revert NotSocket();
        bridge__.receiveInbound(siblingChainSlug_, payload_);
    }

    /**
     * @notice this function calculates the fees needed to send the message to Socket.
     * @param msgGasLimit_ min gas limit needed at destination chain to execute the message.
     */
    function getMinFees(
        uint256 msgGasLimit_,
        uint256 payloadSize_
    ) external view returns (uint256 totalFees) {
        return
            socket__.getMinFees(
                msgGasLimit_,
                payloadSize_,
                bytes32(0),
                bytes32(0),
                siblingChainSlug,
                address(this)
            );
    }

    function connect(
        address siblingPlug_,
        address switchboard_
    ) external onlyOwner {
        messageIdPart =
            (uint256(socket__.chainSlug()) << 224) |
            (uint256(uint160(siblingPlug_)) << 64);

        socket__.connect(
            siblingChainSlug,
            siblingPlug_,
            switchboard_,
            switchboard_
        );
    }

    function disconnect() external onlyOwner {
        messageIdPart = 0;

        (
            ,
            address inboundSwitchboard,
            address outboundSwitchboard,
            ,

        ) = socket__.getPlugConfig(address(this), siblingChainSlug);

        socket__.connect(
            siblingChainSlug,
            address(0),
            inboundSwitchboard,
            outboundSwitchboard
        );

        emit ConnectorPlugDisconnected();
    }

    /**
     * @notice this function is used to calculate message id before sending outbound().
     * @return messageId
     */
    function getMessageId() external view returns (bytes32) {
        return bytes32(messageIdPart | (socket__.globalMessageCount()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {IMintableERC20} from "../interfaces/IMintableERC20.sol";
import "lib/solmate/src/utils/SafeTransferLib.sol";
import {IConnector} from "../ConnectorPlug.sol";
import "./LimitExecutionHook.sol";

interface IYieldToken {
    function updateTotalUnderlyingAssets(uint256 amount_) external;

    function calculateMintAmount(uint256 amount_) external returns (uint256);

    function convertToShares(
        uint256 underlyingAssets
    ) external view returns (uint256);

    function transfer(address to_, uint256 amount_) external returns (bool);

    function convertToAssets(uint256 shares) external view returns (uint256);
}

// limits on underlying or visible tokens
contract Controller_YieldLimitExecHook is LimitExecutionHook {
    using SafeTransferLib for IMintableERC20;
    using FixedPointMathLib for uint256;

    uint256 private constant MAX_BPS = 10_000;
    IYieldToken public immutable yieldToken__;

    // total yield
    uint256 public totalUnderlyingAssets;

    // if true, no funds can be invested in the strategy
    bool public emergencyShutdown;

    event ShutdownStateUpdated(bool shutdownState);

    modifier notShutdown() {
        if (emergencyShutdown) revert VaultShutdown();
        _;
    }

    constructor(
        address underlyingAsset_,
        address controller_,
        address executionHelper_
    ) LimitExecutionHook(msg.sender, controller_, executionHelper_, true) {
        yieldToken__ = IYieldToken(underlyingAsset_);
        hookType = LIMIT_EXECUTION_YIELD_TOKEN_HOOK;
        _grantRole(LIMIT_UPDATER_ROLE, msg.sender);
    }

    // assumed transfer info inputs are validated at controller
    // transfer info data is untrusted
    function srcPreHookCall(
        SrcPreHookCallParams calldata params_
    )
        public
        override
        notShutdown
        returns (TransferInfo memory transferInfo, bytes memory postSrcHookData)
    {
        super.srcPreHookCall(params_);
        uint256 amount = params_.transferInfo.amount;
        postSrcHookData = abi.encode(amount);

        totalUnderlyingAssets -= amount;
        transferInfo = params_.transferInfo;
        transferInfo.amount = yieldToken__.convertToShares(amount);
    }

    function srcPostHookCall(
        SrcPostHookCallParams memory srcPostHookCallParams_
    )
        public
        override
        isVaultOrController
        returns (TransferInfo memory transferInfo)
    {
        yieldToken__.updateTotalUnderlyingAssets(totalUnderlyingAssets);

        transferInfo.receiver = srcPostHookCallParams_.transferInfo.receiver;
        transferInfo.data = abi.encode(
            srcPostHookCallParams_.options,
            srcPostHookCallParams_.transferInfo.data
        );
        transferInfo.amount = abi.decode(
            srcPostHookCallParams_.postSrcHookData,
            (uint256)
        );
    }

    /**
     * @notice This function is called before the execution of a destination hook.
     * @dev It checks if the sibling chain is supported, consumes a part of the limit, and prepares post-hook data.
     */
    function dstPreHookCall(
        DstPreHookCallParams calldata params_
    )
        public
        override
        notShutdown
        isVaultOrController
        returns (bytes memory postHookData, TransferInfo memory transferInfo)
    {
        (uint256 increasedUnderlying, bytes memory payload) = abi.decode(
            params_.transferInfo.data,
            (uint256, bytes)
        );

        _poolDstHook(params_.connector, increasedUnderlying);
        totalUnderlyingAssets += increasedUnderlying;
        yieldToken__.updateTotalUnderlyingAssets(totalUnderlyingAssets);

        yieldToken__.updateTotalUnderlyingAssets(totalUnderlyingAssets);

        if (params_.transferInfo.amount == 0)
            return (abi.encode(0, 0, 0, address(0)), transferInfo);

        (uint256 consumedUnderlying, uint256 pendingUnderlying) = _limitDstHook(
            params_.connector,
            params_.transferInfo.amount
        );
        uint256 sharesToMint = yieldToken__.calculateMintAmount(
            params_.transferInfo.amount
        );

        postHookData = abi.encode(
            consumedUnderlying,
            pendingUnderlying,
            params_.transferInfo.amount,
            params_.transferInfo.receiver
        );

        transferInfo = params_.transferInfo;
        if (pendingUnderlying != 0) transferInfo.receiver = address(this);
        transferInfo.amount = sharesToMint;
        transferInfo.data = payload;
    }

    /**
     * @notice Handles post-hook logic after the execution of a destination hook.
     * @dev This function processes post-hook data to update the identifier cache and sibling chain cache.
     */
    function dstPostHookCall(
        DstPostHookCallParams calldata params_
    )
        public
        override
        isVaultOrController
        notShutdown
        returns (CacheData memory cacheData)
    {
        (
            uint256 consumedUnderlying,
            uint256 pendingUnderlying,
            uint256 depositUnderlying,
            address receiver
        ) = abi.decode(
                params_.postHookData,
                (uint256, uint256, uint256, address)
            );
        bytes memory execPayload = params_.transferInfo.data;

        uint256 connectorPendingShares = _getConnectorPendingAmount(
            params_.connectorCache
        );

        uint256 pendingShares;
        if (pendingUnderlying > 0) {
            // totalShares * consumedU / totalU
            uint256 consumedShares = (params_.transferInfo.amount *
                pendingUnderlying) / depositUnderlying;

            pendingShares = params_.transferInfo.amount - consumedShares;

            cacheData.identifierCache = abi.encode(
                params_.transferInfo.receiver,
                pendingShares,
                params_.connector,
                execPayload
            );
            yieldToken__.transfer(receiver, consumedUnderlying);

            emit TokensPending(
                params_.connector,
                params_.transferInfo.receiver,
                consumedShares,
                pendingShares,
                params_.messageId
            );
        } else {
            if (execPayload.length > 0) {
                // execute
                bool success = executionHelper__.execute(
                    params_.transferInfo.receiver,
                    execPayload,
                    params_.messageId,
                    depositUnderlying
                );

                if (success) {
                    emit MessageExecuted(
                        params_.messageId,
                        params_.transferInfo.receiver
                    );
                    cacheData.identifierCache = new bytes(0);
                } else
                    cacheData.identifierCache = abi.encode(
                        params_.transferInfo.receiver,
                        0,
                        params_.connector,
                        execPayload
                    );
            } else cacheData.identifierCache = new bytes(0);
        }

        cacheData.connectorCache = abi.encode(
            connectorPendingShares + pendingShares
        );
    }

    // /**
    //  * @notice Handles pre-retry hook logic before execution.
    //  * @dev This function can be used to mint funds which were in a pending state due to limits.
    //  * @param siblingChainSlug_ The unique identifier of the sibling chain.
    //  * @param identifierCache_ Identifier cache containing pending mint information.
    //  * @param connectorCache_ Sibling chain cache containing pending amount information.
    //  * @return updatedReceiver The updated receiver of the funds.
    //  * @return consumedUnderlying The amount consumed from the limit.
    //  * @return postRetryHookData The post-hook data to be processed after the retry hook execution.
    //  */
    function preRetryHook(
        PreRetryHookCallParams calldata params_
    )
        public
        override
        isVaultOrController
        notShutdown
        returns (
            bytes memory postRetryHookData,
            TransferInfo memory transferInfo
        )
    {
        (
            address receiver,
            uint256 totalPendingShares,
            address connector,

        ) = abi.decode(
                params_.cacheData.identifierCache,
                (address, uint256, address, bytes)
            );

        if (connector != params_.connector) revert InvalidConnector();

        (uint256 consumedShares, uint256 pendingShares) = _limitDstHook(
            params_.connector,
            totalPendingShares
        );

        postRetryHookData = abi.encode(receiver, consumedShares, pendingShares);
        uint256 consumedUnderlying = yieldToken__.convertToAssets(
            consumedShares
        );
        yieldToken__.transfer(receiver, consumedUnderlying);

        transferInfo = TransferInfo(transferInfo.receiver, 0, bytes(""));
    }

    // /**
    //  * @notice Handles post-retry hook logic after execution.
    //  * @dev This function updates the identifier cache and sibling chain cache based on the post-hook data.
    //  * @param siblingChainSlug_ The unique identifier of the sibling chain.
    //  * @param identifierCache_ Identifier cache containing pending mint information.
    //  * @param connectorCache_ Sibling chain cache containing pending amount information.
    //  * @param postRetryHookData_ The post-hook data containing updated receiver and consumed/pending amounts.
    //  * @return newIdentifierCache The updated identifier cache.
    //  * @return newConnectorCache The updated sibling chain cache.
    //  */
    function postRetryHook(
        PostRetryHookCallParams calldata params_
    ) public override returns (CacheData memory cacheData) {
        return super.postRetryHook(params_);
    }

    function updateEmergencyShutdownState(
        bool shutdownState_
    ) external onlyOwner {
        emergencyShutdown = shutdownState_;
        emit ShutdownStateUpdated(shutdownState_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "lib/solmate/src/utils/ReentrancyGuard.sol";
import "../common/Errors.sol";
import "../common/Constants.sol";
import "../interfaces/IHook.sol";
import "../utils/RescueBase.sol";

/**
 * @title Base contract for super token and vault
 * @notice It contains relevant execution payload storages.
 * @dev This contract implements Socket's IPlug to enable message bridging and IMessageBridge
 * to support any type of message bridge.
 */
abstract contract HookBase is ReentrancyGuard, IHook, RescueBase {
    address public immutable vaultOrController;
    bytes32 public hookType;

    /**
     * @notice Constructor for creating a new SuperToken.
     */
    constructor(
        address owner_,
        address vaultOrController_
    ) AccessControl(owner_) {
        vaultOrController = vaultOrController_;
        _grantRole(RESCUE_ROLE, owner_);
    }

    modifier isVaultOrController() {
        if (msg.sender != vaultOrController) revert NotAuthorized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./LimitHook.sol";

interface IKintoID {
    function isKYC(address) external view returns (bool);
}

interface IKintoFactory {
    function walletTs(address) external view returns (uint256);
}

interface IKintoWallet {
    function isFunderWhitelisted(address) external view returns (bool);
    function owners(uint256) external view returns (address);
}

/**
 * @title Kinto Hook
 * @notice meant to be deployed only Kinto. Inherits from LimitHook.
 */
contract KintoHook is LimitHook {
    address public constant BRIDGER_L2 =
        0x26181Dfc530d96523350e895180b09BAf3d816a0;
    IKintoID public immutable kintoID;
    IKintoFactory public immutable kintoFactory;

    // addresses that can bypass funder whitelisted check on dstPreHookCall
    mapping(address => bool) public senderAllowlist;

    error InvalidSender(address sender);
    error InvalidReceiver(address sender);
    error KYCRequired();
    error SenderNotAllowed(address sender);

    event SenderSet(address indexed sender, bool allowed);

    /**
     * @notice Constructor for creating a Kinto Hook
     * @param owner_ Owner of this contract.
     * @param controller_ Controller of this contract.
     * @param useControllerPools_ Whether to use controller pools.
     * @param kintoID_ KintoID contract address.
     * @param kintoFactory_ KintoFactory contract address.
     */
    constructor(
        address owner_,
        address controller_,
        bool useControllerPools_,
        address kintoID_,
        address kintoFactory_
    ) LimitHook(owner_, controller_, useControllerPools_) {
        hookType = keccak256("KINTO");
        kintoID = IKintoID(kintoID_);
        kintoFactory = IKintoFactory(kintoFactory_);
    }

    /*
     * @notice Sets a sender to be allowed (or not) to send funds to a Kinto wallet bypassing Kinto checks
     */
    function setSender(address sender, bool allowed) external onlyOwner {
        senderAllowlist[sender] = allowed;
        emit SenderSet(sender, allowed);
    }

    /**
     * @dev called when Kinto user wants to "withdraw" (bridge out). Checks if sender is a KintoWallet,
     * if the wallet's signer is KYC'd and if the receiver of the funds is whitelisted.
     */
    function srcPreHookCall(
        SrcPreHookCallParams memory params_
    )
        public
        override
        isVaultOrController
        returns (TransferInfo memory transferInfo, bytes memory postHookData)
    {
        address sender = params_.msgSender;
        if (kintoFactory.walletTs(sender) == 0) revert InvalidSender(sender);
        if (!kintoID.isKYC(IKintoWallet(sender).owners(0)))
            revert KYCRequired();

        return super.srcPreHookCall(params_);
    }

    function srcPostHookCall(
        SrcPostHookCallParams memory params_
    ) public view override isVaultOrController returns (TransferInfo memory) {
        return super.srcPostHookCall(params_);
    }

    /**
     * @dev called when user wants to bridge assets into Kinto. It checks if the receiver
     * is a Kinto Wallet, if the wallet's signer is KYC'd and if the "original sender"
     * (initiator of the tx on the vault chain) is whitelisted on the receiver's KintoWallet.
     *
     * If the receiver is the bridger L2, it skips all the checks.
     * The "original sender" is passed as an encoded param through the SenderHook.
     * If the sender is not in the allowlist (e.g Bridger L1), it checks it's whitelisted on the receiver's KintoWallet.
     */
    function dstPreHookCall(
        DstPreHookCallParams memory params_
    )
        public
        override
        isVaultOrController
        returns (bytes memory postHookData, TransferInfo memory transferInfo)
    {
        address receiver = params_.transferInfo.receiver;
        address msgSender = abi.decode(params_.transferInfo.data, (address));

        if (receiver != BRIDGER_L2) {
            if (kintoFactory.walletTs(receiver) == 0)
                revert InvalidReceiver(receiver);
            if (!kintoID.isKYC(IKintoWallet(receiver).owners(0)))
                revert KYCRequired();
            if (!senderAllowlist[msgSender]) {
                if (!IKintoWallet(receiver).isFunderWhitelisted(msgSender))
                    revert SenderNotAllowed(msgSender);
            }
        }

        return super.dstPreHookCall(params_);
    }

    function dstPostHookCall(
        DstPostHookCallParams memory params_
    ) public override isVaultOrController returns (CacheData memory cacheData) {
        return super.dstPostHookCall(params_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./plugins/LimitPlugin.sol";
import "./plugins/ExecutionHelper.sol";
import "./plugins/ConnectorPoolPlugin.sol";
import "../interfaces/IController.sol";

contract LimitExecutionHook is LimitPlugin, ConnectorPoolPlugin {
    bool public useControllerPools;
    ExecutionHelper executionHelper__;

    event MessageExecuted(bytes32 indexed messageId, address indexed receiver);

    /**
     * @notice Constructor for creating a new SuperToken.
     * @param owner_ Owner of this contract.
     */
    constructor(
        address owner_,
        address controller_,
        address executionHelper_,
        bool useControllerPools_
    ) HookBase(owner_, controller_) {
        useControllerPools = useControllerPools_;
        executionHelper__ = ExecutionHelper(executionHelper_);
        hookType = LIMIT_EXECUTION_HOOK;
        _grantRole(LIMIT_UPDATER_ROLE, owner_);
    }

    function setExecutionHelper(address executionHelper_) external onlyOwner {
        executionHelper__ = ExecutionHelper(executionHelper_);
    }

    function srcPreHookCall(
        SrcPreHookCallParams calldata params_
    )
        public
        virtual
        isVaultOrController
        returns (TransferInfo memory, bytes memory)
    {
        if (useControllerPools)
            _poolSrcHook(params_.connector, params_.transferInfo.amount);
        _limitSrcHook(params_.connector, params_.transferInfo.amount);
        return (params_.transferInfo, bytes(""));
    }

    function srcPostHookCall(
        SrcPostHookCallParams memory params_
    ) public virtual isVaultOrController returns (TransferInfo memory) {
        return params_.transferInfo;
    }

    function dstPreHookCall(
        DstPreHookCallParams calldata params_
    )
        public
        virtual
        isVaultOrController
        returns (bytes memory postHookData, TransferInfo memory transferInfo)
    {
        if (useControllerPools)
            _poolDstHook(params_.connector, params_.transferInfo.amount);

        (uint256 consumedAmount, uint256 pendingAmount) = _limitDstHook(
            params_.connector,
            params_.transferInfo.amount
        );
        postHookData = abi.encode(
            consumedAmount,
            pendingAmount,
            params_.transferInfo.amount
        );
        transferInfo = params_.transferInfo;
        transferInfo.amount = consumedAmount;
    }

    function dstPostHookCall(
        DstPostHookCallParams calldata params_
    ) public virtual isVaultOrController returns (CacheData memory cacheData) {
        bytes memory execPayload = params_.transferInfo.data;

        (
            uint256 consumedAmount,
            uint256 pendingAmount,
            uint256 bridgeAmount
        ) = abi.decode(params_.postHookData, (uint256, uint256, uint256));

        uint256 connectorPendingAmount = _getConnectorPendingAmount(
            params_.connectorCache
        );
        cacheData.connectorCache = abi.encode(
            connectorPendingAmount + pendingAmount
        );
        cacheData.identifierCache = abi.encode(
            params_.transferInfo.receiver,
            pendingAmount,
            bridgeAmount,
            params_.connector,
            execPayload
        );

        if (pendingAmount > 0) {
            emit TokensPending(
                params_.connector,
                params_.transferInfo.receiver,
                consumedAmount,
                pendingAmount,
                params_.messageId
            );
        } else {
            if (execPayload.length > 0) {
                // execute
                bool success = executionHelper__.execute(
                    params_.transferInfo.receiver,
                    execPayload,
                    params_.messageId,
                    bridgeAmount
                );

                if (success) {
                    emit MessageExecuted(
                        params_.messageId,
                        params_.transferInfo.receiver
                    );
                    cacheData.identifierCache = new bytes(0);
                }
            } else cacheData.identifierCache = new bytes(0);
        }
    }

    function preRetryHook(
        PreRetryHookCallParams calldata params_
    )
        public
        virtual
        isVaultOrController
        returns (
            bytes memory postRetryHookData,
            TransferInfo memory transferInfo
        )
    {
        (address receiver, uint256 pendingMint, , address connector, ) = abi
            .decode(
                params_.cacheData.identifierCache,
                (address, uint256, uint256, address, bytes)
            );

        if (connector != params_.connector) revert InvalidConnector();

        (uint256 consumedAmount, uint256 pendingAmount) = _limitDstHook(
            params_.connector,
            pendingMint
        );

        postRetryHookData = abi.encode(receiver, consumedAmount, pendingAmount);
        transferInfo = TransferInfo(receiver, consumedAmount, bytes(""));
    }

    function postRetryHook(
        PostRetryHookCallParams calldata params_
    ) public virtual isVaultOrController returns (CacheData memory cacheData) {
        (
            ,
            ,
            uint256 bridgeAmount,
            address connector,
            bytes memory execPayload
        ) = abi.decode(
                params_.cacheData.identifierCache,
                (address, uint256, uint256, address, bytes)
            );

        (address receiver, uint256 consumedAmount, uint256 pendingAmount) = abi
            .decode(params_.postRetryHookData, (address, uint256, uint256));

        uint256 connectorPendingAmount = _getConnectorPendingAmount(
            params_.cacheData.connectorCache
        );

        cacheData.connectorCache = abi.encode(
            connectorPendingAmount - consumedAmount
        );
        cacheData.identifierCache = abi.encode(
            receiver,
            pendingAmount,
            bridgeAmount,
            connector,
            execPayload
        );

        emit PendingTokensBridged(
            params_.connector,
            receiver,
            consumedAmount,
            pendingAmount,
            params_.messageId
        );

        if (pendingAmount == 0) {
            // receiver is not an input from user, can receiver check
            // no connector check required here, as already done in preRetryHook call in same tx

            // execute
            bool success = executionHelper__.execute(
                receiver,
                execPayload,
                params_.messageId,
                bridgeAmount
            );
            if (success) {
                emit MessageExecuted(params_.messageId, receiver);
                cacheData.identifierCache = new bytes(0);
            }
        }
    }

    function getConnectorPendingAmount(
        address connector_
    ) external returns (uint256) {
        bytes memory cache = IController(vaultOrController).connectorCache(
            connector_
        );
        return _getConnectorPendingAmount(cache);
    }

    function _getIdentifierPendingAmount(
        bytes memory identifierCache_
    ) internal pure returns (uint256) {
        if (identifierCache_.length > 0) {
            (, uint256 pendingAmount, , , ) = abi.decode(
                identifierCache_,
                (address, uint256, uint256, address, bytes)
            );
            return pendingAmount;
        } else return 0;
    }

    function getIdentifierPendingAmount(
        bytes32 messageId_
    ) external returns (uint256) {
        bytes memory cache = IController(vaultOrController).identifierCache(
            messageId_
        );
        return _getIdentifierPendingAmount(cache);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./plugins/LimitPlugin.sol";
import "../interfaces/IController.sol";
import "./plugins/ConnectorPoolPlugin.sol";

contract LimitHook is LimitPlugin, ConnectorPoolPlugin {
    bool public immutable useControllerPools;

    /**
     * @notice Constructor for creating a new SuperToken.
     * @param owner_ Owner of this contract.
     */
    constructor(
        address owner_,
        address controller_,
        bool useControllerPools_
    ) HookBase(owner_, controller_) {
        useControllerPools = useControllerPools_;
        hookType = LIMIT_HOOK;
        _grantRole(LIMIT_UPDATER_ROLE, owner_);
    }

    function srcPreHookCall(
        SrcPreHookCallParams memory params_
    )
        public
        virtual
        isVaultOrController
        returns (TransferInfo memory transferInfo, bytes memory postHookData)
    {
        if (useControllerPools)
            _poolSrcHook(params_.connector, params_.transferInfo.amount);

        _limitSrcHook(params_.connector, params_.transferInfo.amount);
        transferInfo = params_.transferInfo;
        postHookData = hex"";
    }

    function srcPostHookCall(
        SrcPostHookCallParams memory params_
    ) public view virtual isVaultOrController returns (TransferInfo memory) {
        return params_.transferInfo;
    }

    function dstPreHookCall(
        DstPreHookCallParams memory params_
    )
        public
        virtual
        isVaultOrController
        returns (bytes memory postHookData, TransferInfo memory transferInfo)
    {
        if (useControllerPools)
            _poolDstHook(params_.connector, params_.transferInfo.amount);

        (uint256 consumedAmount, uint256 pendingAmount) = _limitDstHook(
            params_.connector,
            params_.transferInfo.amount
        );
        postHookData = abi.encode(consumedAmount, pendingAmount);
        transferInfo = params_.transferInfo;
        transferInfo.amount = consumedAmount;
    }

    function dstPostHookCall(
        DstPostHookCallParams memory params_
    ) public virtual isVaultOrController returns (CacheData memory cacheData) {
        (uint256 consumedAmount, uint256 pendingAmount) = abi.decode(
            params_.postHookData,
            (uint256, uint256)
        );
        uint256 connectorPendingAmount = _getConnectorPendingAmount(
            params_.connectorCache
        );
        if (pendingAmount > 0) {
            cacheData = CacheData(
                abi.encode(
                    params_.transferInfo.receiver,
                    pendingAmount,
                    params_.connector
                ),
                abi.encode(connectorPendingAmount + pendingAmount)
            );

            emit TokensPending(
                params_.connector,
                params_.transferInfo.receiver,
                consumedAmount,
                pendingAmount,
                params_.messageId
            );
        } else {
            cacheData = CacheData(
                bytes(""),
                abi.encode(connectorPendingAmount + pendingAmount)
            );
        }
    }

    function preRetryHook(
        PreRetryHookCallParams memory params_
    )
        public
        virtual
        nonReentrant
        isVaultOrController
        returns (
            bytes memory postRetryHookData,
            TransferInfo memory transferInfo
        )
    {
        (address updatedReceiver, uint256 pendingMint, address connector) = abi
            .decode(
                params_.cacheData.identifierCache,
                (address, uint256, address)
            );

        if (connector != params_.connector) revert InvalidConnector();

        (uint256 consumedAmount, uint256 pendingAmount) = _limitDstHook(
            params_.connector,
            pendingMint
        );

        postRetryHookData = abi.encode(
            updatedReceiver,
            consumedAmount,
            pendingAmount
        );
        transferInfo = TransferInfo(updatedReceiver, consumedAmount, bytes(""));
    }

    function postRetryHook(
        PostRetryHookCallParams calldata params_
    )
        public
        virtual
        isVaultOrController
        nonReentrant
        returns (CacheData memory cacheData)
    {
        (
            address updatedReceiver,
            uint256 consumedAmount,
            uint256 pendingAmount
        ) = abi.decode(params_.postRetryHookData, (address, uint256, uint256));

        // code reaches here after minting/unlocking the pending amount
        emit PendingTokensBridged(
            params_.connector,
            updatedReceiver,
            consumedAmount,
            pendingAmount,
            params_.messageId
        );

        uint256 connectorPendingAmount = _getConnectorPendingAmount(
            params_.cacheData.connectorCache
        );
        cacheData.connectorCache = abi.encode(
            connectorPendingAmount - consumedAmount
        );
        cacheData.identifierCache = abi.encode(
            updatedReceiver,
            pendingAmount,
            params_.connector
        );

        if (pendingAmount == 0) {
            cacheData.identifierCache = new bytes(0);
        }
    }

    function getConnectorPendingAmount(
        address connector_
    ) external returns (uint256) {
        bytes memory cache = IController(vaultOrController).connectorCache(
            connector_
        );
        return _getConnectorPendingAmount(cache);
    }

    function _getIdentifierPendingAmount(
        bytes memory identifierCache_
    ) internal pure returns (uint256) {
        if (identifierCache_.length > 0) {
            (, uint256 pendingAmount, ) = abi.decode(
                identifierCache_,
                (address, uint256, address)
            );
            return pendingAmount;
        } else return 0;
    }

    function getIdentifierPendingAmount(
        bytes32 messageId_
    ) external returns (uint256) {
        bytes memory cache = IController(vaultOrController).identifierCache(
            messageId_
        );
        return _getIdentifierPendingAmount(cache);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../HookBase.sol";

abstract contract ConnectorPoolPlugin is HookBase {
    // connectorPoolId => totalLockedAmount
    mapping(uint256 => uint256) public poolLockedAmounts;

    // connector => connectorPoolId
    mapping(address => uint256) public connectorPoolIds;

    event ConnectorPoolIdUpdated(address connector, uint256 poolId);
    event PoolLockedAmountUpdated(uint256 poolId, uint256 amount);

    function updateConnectorPoolId(
        address[] calldata connectors,
        uint256[] calldata poolIds_
    ) external onlyOwner {
        uint256 length = connectors.length;
        for (uint256 i; i < length; i++) {
            if (poolIds_[i] == 0) revert InvalidPoolId();
            connectorPoolIds[connectors[i]] = poolIds_[i];
            emit ConnectorPoolIdUpdated(connectors[i], poolIds_[i]);
        }
    }

    function updatePoolLockedAmounts(
        uint256[] calldata poolIds_,
        uint256[] calldata amounts_
    ) external onlyOwner {
        uint256 length = poolIds_.length;
        for (uint256 i; i < length; i++) {
            if (poolIds_[i] == 0) revert InvalidPoolId();
            poolLockedAmounts[poolIds_[i]] = amounts_[i];
            emit PoolLockedAmountUpdated(poolIds_[i], amounts_[i]);
        }
    }

    function _poolSrcHook(address connector_, uint256 amount_) internal {
        uint256 connectorPoolId = connectorPoolIds[connector_];
        if (connectorPoolId == 0) revert InvalidPoolId();
        if (amount_ > poolLockedAmounts[connectorPoolId])
            revert InsufficientFunds();

        poolLockedAmounts[connectorPoolId] -= amount_;
    }

    function _poolDstHook(
        address connector_,
        uint256 amount_
    ) internal returns (uint256 oldLockedAmount) {
        uint256 connectorPoolId = connectorPoolIds[connector_];
        if (connectorPoolId == 0) revert InvalidPoolId();

        oldLockedAmount = poolLockedAmounts[connectorPoolId];
        poolLockedAmounts[connectorPoolId] += amount_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../../libraries/ExcessivelySafeCall.sol";
import "../../utils/RescueBase.sol";
import "../../common/Errors.sol";

/**
 * @title ExecutionHelper
 * @notice It is an untrusted contract used for payload execution by Super token and Vault.
 */
contract ExecutionHelper is RescueBase {
    using ExcessivelySafeCall for address;
    uint16 private constant MAX_COPY_BYTES = 0;
    address public hook;
    bytes32 public messageId;
    uint256 public bridgeAmount;

    constructor(address owner_) AccessControl(owner_) {
        _grantRole(RESCUE_ROLE, owner_);
    }

    modifier onlyHook() {
        require(msg.sender == hook, "ExecutionHelper: only hook");
        _;
    }

    function setHook(address hook_) external onlyOwner {
        hook = hook_;
    }

    /**
     * @notice this function is used to execute a payload at target_
     * @dev receiver address cannot be this contract address.
     * @param target_ address of target.
     * @param payload_ payload to be executed at target.
     */
    function execute(
        address target_,
        bytes memory payload_,
        bytes32 messageId_,
        uint256 bridgeAmount_
    ) external onlyHook returns (bool success) {
        if (target_ == address(this)) return false;

        messageId = messageId_;
        bridgeAmount = bridgeAmount_;

        (success, ) = target_.excessivelySafeCall(
            gasleft(),
            MAX_COPY_BYTES,
            payload_
        );

        messageId = bytes32(0);
        bridgeAmount = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../HookBase.sol";
import {Gauge} from "../../utils/Gauge.sol";

abstract contract LimitPlugin is Gauge, HookBase {
    bytes32 constant LIMIT_UPDATER_ROLE = keccak256("LIMIT_UPDATER_ROLE");

    // connector => receivingLimitParams
    mapping(address => LimitParams) _receivingLimitParams;

    // connector => sendingLimitParams
    mapping(address => LimitParams) _sendingLimitParams;

    ////////////////////////////////////////////////////////
    ////////////////////// EVENTS //////////////////////////
    ////////////////////////////////////////////////////////

    // Emitted when limit parameters are updated
    event LimitParamsUpdated(UpdateLimitParams[] updates);

    // Emitted when pending tokens are minted to the receiver
    event PendingTokensBridged(
        address connector,
        address receiver,
        uint256 consumedAmount,
        uint256 pendingAmount,
        bytes32 messageId
    );
    // Emitted when the transfer reaches the limit, and the token mint is added to the pending queue
    event TokensPending(
        address connector,
        address receiver,
        uint256 consumedAmount,
        uint256 pendingAmount,
        bytes32 messageId
    );

    /**
     * @notice This function is used to set bridge limits.
     * @dev It can only be updated by the owner.
     * @param updates An array of structs containing update parameters.
     */
    function updateLimitParams(
        UpdateLimitParams[] calldata updates
    ) external onlyRole(LIMIT_UPDATER_ROLE) {
        for (uint256 i = 0; i < updates.length; i++) {
            if (updates[i].isMint) {
                _consumePartLimit(
                    0,
                    _receivingLimitParams[updates[i].connector]
                ); // To keep the current limit in sync
                _receivingLimitParams[updates[i].connector].maxLimit = updates[
                    i
                ].maxLimit;
                _receivingLimitParams[updates[i].connector]
                    .ratePerSecond = updates[i].ratePerSecond;
            } else {
                _consumePartLimit(0, _sendingLimitParams[updates[i].connector]); // To keep the current limit in sync
                _sendingLimitParams[updates[i].connector].maxLimit = updates[i]
                    .maxLimit;
                _sendingLimitParams[updates[i].connector]
                    .ratePerSecond = updates[i].ratePerSecond;
            }
        }

        emit LimitParamsUpdated(updates);
    }

    function getCurrentReceivingLimit(
        address connector_
    ) external view returns (uint256) {
        return _getCurrentLimit(_receivingLimitParams[connector_]);
    }

    function getCurrentSendingLimit(
        address connector_
    ) external view returns (uint256) {
        return _getCurrentLimit(_sendingLimitParams[connector_]);
    }

    function getReceivingLimitParams(
        address connector_
    ) external view returns (LimitParams memory) {
        return _receivingLimitParams[connector_];
    }

    function getSendingLimitParams(
        address connector_
    ) external view returns (LimitParams memory) {
        return _sendingLimitParams[connector_];
    }

    function _limitSrcHook(address connector_, uint256 amount_) internal {
        if (_sendingLimitParams[connector_].maxLimit == 0)
            revert SiblingNotSupported();

        _consumeFullLimit(amount_, _sendingLimitParams[connector_]); // Reverts on limit hit
    }

    function _limitDstHook(
        address connector_,
        uint256 amount_
    ) internal returns (uint256 consumedAmount, uint256 pendingAmount) {
        if (_receivingLimitParams[connector_].maxLimit == 0)
            revert SiblingNotSupported();

        (consumedAmount, pendingAmount) = _consumePartLimit(
            amount_,
            _receivingLimitParams[connector_]
        );
    }

    function _getConnectorPendingAmount(
        bytes memory connectorCache_
    ) internal pure returns (uint256) {
        if (connectorCache_.length > 0) {
            return abi.decode(connectorCache_, (uint256));
        } else return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./LimitHook.sol";

/**
 * @title Sender Hook
 * @notice It only defines behaviour for `srcPreHookCall` to include the sender in the TransferInfo data field.
 */
contract SenderHook is LimitHook {
    /**
     * @notice meant to be deployed only on vault chains (all except Kinto).
     * Overrides `srcPreHookCall` to pass the `msg.sender` so that it can be used
     * in the `dstPreHookCall` on Kinto chain.
     * @param owner_ Owner of this contract.
     * @param controller_ Controller of this contract.
     * @param useControllerPools_ Whether to use controller pools.
     */
    constructor(
        address owner_,
        address controller_,
        bool useControllerPools_
    ) LimitHook(owner_, controller_, useControllerPools_) {
        hookType = keccak256("KINTO");
    }

    function srcPreHookCall(
        SrcPreHookCallParams memory params_
    )
        public
        override
        isVaultOrController
        returns (TransferInfo memory transferInfo, bytes memory postHookData)
    {
        // add `msgSender` inside data field
        params_.transferInfo.data = abi.encode(params_.msgSender);
        return super.srcPreHookCall(params_);
    }

    function srcPostHookCall(
        SrcPostHookCallParams memory params_
    ) public view override isVaultOrController returns (TransferInfo memory) {
        return super.srcPostHookCall(params_);
    }

    function dstPreHookCall(
        DstPreHookCallParams memory params_
    )
        public
        override
        isVaultOrController
        returns (bytes memory postHookData, TransferInfo memory transferInfo)
    {
        return super.dstPreHookCall(params_);
    }

    function dstPostHookCall(
        DstPostHookCallParams memory params_
    ) public override isVaultOrController returns (CacheData memory cacheData) {
        return super.dstPostHookCall(params_);
    }

    /// @dev not needed for this hook
    function preRetryHook(
        PreRetryHookCallParams memory params_
    )
        public
        override
        nonReentrant
        isVaultOrController
        returns (
            bytes memory postRetryHookData,
            TransferInfo memory transferInfo
        )
    {
        return super.preRetryHook(params_);
    }

    /// @dev not needed for this hook
    function postRetryHook(
        PostRetryHookCallParams calldata params_
    )
        public
        override
        isVaultOrController
        nonReentrant
        returns (CacheData memory cacheData)
    {
        return super.postRetryHook(params_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import "lib/solmate/src/tokens/ERC20.sol";

import "lib/solmate/src/utils/SafeTransferLib.sol";
import {IConnector} from "../ConnectorPlug.sol";

import "./LimitExecutionHook.sol";

contract Vault_YieldLimitExecHook is LimitExecutionHook {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    uint256 private constant MAX_BPS = 10_000;

    IStrategy public strategy; // address of the strategy contract
    ERC20 public immutable underlyingAsset__;

    uint256 public totalLockedInStrategy; // total funds deposited in strategy

    uint256 public totalIdle; // Amount of tokens that are in the vault
    uint256 public totalDebt; // Amount of tokens that strategy have borrowed
    uint128 public lastRebalanceTimestamp; // Timestamp of last rebalance

    uint128 public rebalanceDelay; // Delay between rebalance
    uint256 public debtRatio; // Debt ratio for the Vault (in BPS, <= 10k)
    bool public emergencyShutdown; // if true, no funds can be invested in the strategy

    uint256 public lastTotalUnderlyingAssetsSynced;

    event WithdrawFromStrategy(uint256 withdrawn);
    event Rebalanced(
        uint256 totalIdle,
        uint256 totalDebt,
        uint256 credit,
        uint256 debtOutstanding
    );
    event ShutdownStateUpdated(bool shutdownState);
    event DebtRatioUpdated(uint256 debtRatio);
    event StrategyUpdated(address strategy);
    event RebalanceDelayUpdated(uint128 rebalanceDelay);

    modifier notShutdown() {
        if (emergencyShutdown) revert VaultShutdown();
        _;
    }

    constructor(
        uint256 debtRatio_,
        uint128 rebalanceDelay_,
        address strategy_,
        address underlyingAsset_,
        address vault_,
        address executionHelper_,
        bool useControllerPools_
    )
        LimitExecutionHook(
            msg.sender,
            vault_,
            executionHelper_,
            useControllerPools_
        )
    {
        underlyingAsset__ = ERC20(underlyingAsset_);
        debtRatio = debtRatio_;
        rebalanceDelay = rebalanceDelay_;
        strategy = IStrategy(strategy_);
        hookType = LIMIT_EXECUTION_YIELD_HOOK;
        _grantRole(LIMIT_UPDATER_ROLE, msg.sender);
    }

    /**
     * @dev This function calls the srcHookCall function of the connector contract,
     * passing in the receiver, amount, siblingChainSlug, extradata, and msg.sender, and returns
     * the updated receiver, amount, and extradata.
     */
    function srcPreHookCall(
        SrcPreHookCallParams calldata params_
    ) public override notShutdown returns (TransferInfo memory, bytes memory) {
        totalIdle += params_.transferInfo.amount;
        return super.srcPreHookCall(params_);
    }

    function srcPostHookCall(
        SrcPostHookCallParams memory srcPostHookCallParams_
    )
        public
        override
        isVaultOrController
        returns (TransferInfo memory transferInfo)
    {
        _checkDelayAndRebalance();

        uint256 totalUnderlyingAsset = strategy.estimatedTotalAssets() +
            totalIdle;
        uint256 totalYieldSync = totalUnderlyingAsset -
            lastTotalUnderlyingAssetsSynced;
        lastTotalUnderlyingAssetsSynced = totalUnderlyingAsset;

        transferInfo = srcPostHookCallParams_.transferInfo;
        if (srcPostHookCallParams_.transferInfo.amount == 0) {
            transferInfo.data = abi.encode(totalYieldSync, bytes(""));
        } else {
            transferInfo.data = abi.encode(
                totalYieldSync,
                srcPostHookCallParams_.transferInfo.data
            );
        }
    }

    /**
     * @notice This function is called before the execution of a destination hook.
     * @dev It checks if the sibling chain is supported, consumes a part of the limit, and prepares post-hook data.
     */
    function dstPreHookCall(
        DstPreHookCallParams calldata params_
    )
        public
        override
        notShutdown
        returns (bytes memory postHookData, TransferInfo memory transferInfo)
    {
        (postHookData, transferInfo) = super.dstPreHookCall(params_);

        // ensure vault have enough idle underlyingAssets
        if (transferInfo.amount > totalUnderlyingAssets())
            revert NotEnoughAssets();

        (bytes memory options_, bytes memory payload_) = abi.decode(
            params_.transferInfo.data,
            (bytes, bytes)
        );
        bool pullFromStrategy = abi.decode(options_, (bool));

        if (transferInfo.amount > totalIdle) {
            if (pullFromStrategy) {
                _withdrawFromStrategy(transferInfo.amount - totalIdle);
            } else {
                (
                    uint256 consumedUnderlying,
                    uint256 pendingUnderlying,
                    uint256 bridgeUnderlying
                ) = abi.decode(postHookData, (uint256, uint256, uint256));

                pendingUnderlying += transferInfo.amount - totalIdle;
                postHookData = abi.encode(
                    transferInfo.amount,
                    pendingUnderlying,
                    bridgeUnderlying
                );
                transferInfo.amount = totalIdle;

                // Update the lastUpdateLimit as consumedAmount is reduced to totalIdle. This is to ensure that the
                // receiving limit is updated by correct transferred amount.
                LimitParams storage receivingParams = _receivingLimitParams[
                    params_.connector
                ];

                receivingParams.lastUpdateLimit +=
                    consumedUnderlying -
                    transferInfo.amount;
            }
            totalIdle = 0;
        } else totalIdle -= transferInfo.amount;

        transferInfo.data = payload_;
        transferInfo.receiver = params_.transferInfo.receiver;
    }

    function dstPostHookCall(
        DstPostHookCallParams calldata params_
    ) public override returns (CacheData memory cacheData) {
        return super.dstPostHookCall(params_);
    }

    /**
     * @notice Handles pre-retry hook logic before execution.
     * @dev This function can be used to mint funds which were in a pending state due to limits.
     */
    function preRetryHook(
        PreRetryHookCallParams calldata params_
    )
        public
        override
        notShutdown
        returns (
            bytes memory postRetryHookData,
            TransferInfo memory transferInfo
        )
    {
        (postRetryHookData, transferInfo) = super.preRetryHook(params_);
        if (transferInfo.amount > totalIdle) {
            _withdrawFromStrategy(transferInfo.amount - totalIdle);
            totalIdle = 0;
        } else totalIdle -= transferInfo.amount;
    }

    function postRetryHook(
        PostRetryHookCallParams calldata params_
    ) public override returns (CacheData memory cacheData) {
        return super.postRetryHook(params_);
    }

    function withdrawFromStrategy(
        uint256 underlyingAsset_
    ) external onlyOwner returns (uint256) {
        return _withdrawFromStrategy(underlyingAsset_);
    }

    function _withdrawFromStrategy(
        uint256 underlyingAsset_
    ) internal returns (uint256 withdrawn) {
        uint256 preBalance = underlyingAsset__.balanceOf(address(this));
        strategy.withdraw(underlyingAsset_);
        withdrawn = underlyingAsset__.balanceOf(address(this)) - preBalance;
        totalIdle += withdrawn;
        totalDebt -= withdrawn;

        underlyingAsset__.transfer(vaultOrController, withdrawn);
        emit WithdrawFromStrategy(withdrawn);
    }

    function _withdrawAllFromStrategy() internal returns (uint256) {
        uint256 preBalance = underlyingAsset__.balanceOf(address(this));
        strategy.withdrawAll();
        uint256 withdrawn = underlyingAsset__.balanceOf(address(this)) -
            preBalance;
        totalIdle += withdrawn;
        totalDebt = 0;

        underlyingAsset__.transfer(vaultOrController, withdrawn);
        emit WithdrawFromStrategy(withdrawn);
        return withdrawn;
    }

    function rebalance() external notShutdown {
        _rebalance();
    }

    function _checkDelayAndRebalance() internal {
        uint128 timeElapsed = uint128(block.timestamp) - lastRebalanceTimestamp;
        if (timeElapsed >= rebalanceDelay) {
            _rebalance();
        }
    }

    function _rebalance() internal {
        if (address(strategy) == address(0)) return;
        lastRebalanceTimestamp = uint128(block.timestamp);
        // Compute the line of credit the Vault is able to offer the Strategy (if any)
        uint256 credit = _creditAvailable();
        uint256 pendingDebt = _debtOutstanding();

        if (credit > 0) {
            // Credit surplus, give to Strategy
            totalIdle -= credit;
            totalDebt += credit;
            totalLockedInStrategy += credit;
            underlyingAsset__.safeTransferFrom(
                vaultOrController,
                address(strategy),
                credit
            );
            strategy.invest();
        } else if (pendingDebt > 0) {
            // Credit deficit, take from Strategy
            _withdrawFromStrategy(pendingDebt);
        }

        emit Rebalanced(totalIdle, totalDebt, credit, pendingDebt);
    }

    /// @notice Returns the total quantity of all underlyingAssets under control of this
    ///    Vault, whether they're loaned out to a Strategy, or currently held in
    /// the Vault.
    /// @return total quantity of all underlyingAssets under control of this Vault
    function totalUnderlyingAssets() public view returns (uint256) {
        return strategy.estimatedTotalAssets() + totalIdle;
    }

    function _creditAvailable() internal view returns (uint256) {
        uint256 vaultTotalAssets = totalUnderlyingAssets();
        uint256 vaultDebtLimit = (debtRatio * vaultTotalAssets) / MAX_BPS;
        uint256 vaultTotalDebt = totalDebt;

        if (vaultDebtLimit <= vaultTotalDebt) return 0;

        // Start with debt limit left for the Strategy
        uint256 availableCredit = vaultDebtLimit - vaultTotalDebt;

        // Can only borrow up to what the contract has in reserve
        // NOTE: Running near 100% is discouraged
        return Math.min(availableCredit, totalIdle);
    }

    function creditAvailable() external view returns (uint256) {
        // @notice
        //     Amount of tokens in Vault a Strategy has access to as a credit line.
        //     This will check the Strategy's debt limit, as well as the tokens
        //     available in the Vault, and determine the maximum amount of tokens
        //     (if any) the Strategy may draw on.
        //     In the rare case the Vault is in emergency shutdown this will return 0.
        // @param strategy The Strategy to check. Defaults to caller.
        // @return The quantity of tokens available for the Strategy to draw on.

        return _creditAvailable();
    }

    function _debtOutstanding() internal view returns (uint256) {
        // See note on `debtOutstanding()`.
        if (debtRatio == 0) {
            return totalDebt;
        }

        uint256 debtLimit = ((debtRatio * totalUnderlyingAssets()) / MAX_BPS);

        if (totalDebt <= debtLimit) return 0;
        else return totalDebt - debtLimit;
    }

    function debtOutstanding() external view returns (uint256) {
        // @notice
        //     Determines if `strategy` is past its debt limit and if any tokens
        //     should be withdrawn to the Vault.
        // @return The quantity of tokens to withdraw.

        return _debtOutstanding();
    }

    function updateEmergencyShutdownState(
        bool shutdownState_,
        bool detachStrategy
    ) external onlyOwner {
        if (shutdownState_ && detachStrategy) {
            // If we're exiting emergency shutdown, we need to empty strategy
            _withdrawAllFromStrategy();
            strategy = IStrategy(address(0));
        }
        emergencyShutdown = shutdownState_;
        emit ShutdownStateUpdated(shutdownState_);
    }

    ////////////////////////////////////////////////////////
    ////////////////////// SETTERS //////////////////////////
    ////////////////////////////////////////////////////////

    function setDebtRatio(uint256 debtRatio_) external onlyOwner {
        if (debtRatio_ > MAX_BPS) revert DebtRatioTooHigh();
        debtRatio = debtRatio_;

        emit DebtRatioUpdated(debtRatio_);
    }

    function setStrategy(address strategy_) external onlyOwner {
        strategy = IStrategy(strategy_);
        emit StrategyUpdated(strategy_);
    }

    function setRebalanceDelay(uint128 rebalanceDelay_) external onlyOwner {
        rebalanceDelay = rebalanceDelay_;
        emit RebalanceDelayUpdated(rebalanceDelay_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IBridge {
    function bridge(
        address receiver_,
        uint256 amount_,
        uint256 msgGasLimit_,
        address connector_,
        bytes calldata execPayload_,
        bytes calldata options_
    ) external payable;

    function receiveInbound(
        uint32 siblingChainSlug_,
        bytes memory payload_
    ) external payable;

    function retry(address connector_, bytes32 messageId_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IConnector {
    function outbound(
        uint256 msgGasLimit_,
        bytes memory payload_,
        bytes memory options_
    ) external payable returns (bytes32 messageId_);

    function siblingChainSlug() external view returns (uint32);

    function getMinFees(
        uint256 msgGasLimit_,
        uint256 payloadSize_
    ) external view returns (uint256 totalFees);

    function getMessageId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IController {
    function identifierCache(
        bytes32 messageId_
    ) external payable returns (bytes memory cache);

    function connectorCache(
        address connector_
    ) external payable returns (bytes memory cache);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "../common/Structs.sol";

interface IHook {
    /**
     * @notice Executes pre-hook call for source underlyingAsset.
     * @dev This function is used to execute a pre-hook call for the source underlyingAsset before initiating a transfer.
     * @param params_ Parameters for the pre-hook call.
     * @return transferInfo Information about the transfer.
     * @return postSrcHookData returned from the pre-hook call.
     */
    function srcPreHookCall(
        SrcPreHookCallParams calldata params_
    )
        external
        returns (
            TransferInfo memory transferInfo,
            bytes memory postSrcHookData
        );

    function srcPostHookCall(
        SrcPostHookCallParams calldata params_
    ) external returns (TransferInfo memory transferInfo);

    /**
     * @notice Executes pre-hook call for destination underlyingAsset.
     * @dev This function is used to execute a pre-hook call for the destination underlyingAsset before initiating a transfer.
     * @param params_ Parameters for the pre-hook call.
     */
    function dstPreHookCall(
        DstPreHookCallParams calldata params_
    )
        external
        returns (bytes memory postHookData, TransferInfo memory transferInfo);

    /**
     * @notice Executes post-hook call for destination underlyingAsset.
     * @dev This function is used to execute a post-hook call for the destination underlyingAsset after completing a transfer.
     * @param params_ Parameters for the post-hook call.
     * @return cacheData Cached data for the post-hook call.
     */
    function dstPostHookCall(
        DstPostHookCallParams calldata params_
    ) external returns (CacheData memory cacheData);

    /**
     * @notice Executes a pre-retry hook for a failed transaction.
     * @dev This function is used to execute a pre-retry hook for a failed transaction.
     * @param params_ Parameters for the pre-retry hook.
     * @return postRetryHookData Data from the post-retry hook.
     * @return transferInfo Information about the transfer.
     */
    function preRetryHook(
        PreRetryHookCallParams calldata params_
    )
        external
        returns (
            bytes memory postRetryHookData,
            TransferInfo memory transferInfo
        );

    /**
     * @notice Executes a post-retry hook for a failed transaction.
     * @dev This function is used to execute a post-retry hook for a failed transaction.
     * @param params_ Parameters for the post-retry hook.
     * @return cacheData Cached data for the post-retry hook.
     */
    function postRetryHook(
        PostRetryHookCallParams calldata params_
    ) external returns (CacheData memory cacheData);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IHook.sol";

interface ILimitHook is IHook {
    function updateLimitParams(UpdateLimitParams[] calldata updates) external;

    function checkLimit(address user, uint256 amount) external view;

    function getIdentifierPendingAmount(
        bytes32 messageId_
    ) external returns (uint256);

    function getConnectorPendingAmount(
        address connector_
    ) external returns (uint256);

    function getCurrentReceivingLimit(
        address connector_
    ) external view returns (uint256);

    function getCurrentSendingLimit(
        address connector_
    ) external view returns (uint256);

    function getReceivingLimitParams(
        address connector_
    ) external view returns (LimitParams memory);

    function getSendingLimitParams(
        address connector_
    ) external view returns (LimitParams memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMintableERC20 {
    function mint(address receiver_, uint256 amount_) external;

    function burn(address burner_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title IPlug
 * @notice Interface for a plug contract that executes the message received from a source chain.
 */
interface IPlug {
    /**
     * @dev this should be only executable by socket
     * @notice executes the message received from source chain
     * @notice It is expected to have original sender checks in the destination plugs using payload
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(
        uint32 srcChainSlug_,
        bytes calldata payload_
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title ISocket
 * @notice An interface for a cross-chain communication contract
 * @dev This interface provides methods for transmitting and executing messages between chains,
 * connecting a plug to a remote chain and setting up switchboards for the message transmission
 * This interface also emits events for important operations such as message transmission, execution status,
 * and plug connection
 */
interface ISocket {
    /**
     * @notice A struct containing fees required for message transmission and execution
     * @param transmissionFees fees needed for transmission
     * @param switchboardFees fees needed by switchboard
     * @param executionFee fees needed for execution
     */
    struct Fees {
        uint128 transmissionFees;
        uint128 executionFee;
        uint128 switchboardFees;
    }

    /**
     * @title MessageDetails
     * @dev This struct defines the details of a message to be executed in a Decapacitor contract.
     */
    struct MessageDetails {
        // A unique identifier for the message.
        bytes32 msgId;
        // The fee to be paid for executing the message.
        uint256 executionFee;
        // The maximum amount of gas that can be used to execute the message.
        uint256 minMsgGasLimit;
        // The extra params which provides msg value and additional info needed for message exec
        bytes32 executionParams;
        // The payload data to be executed in the message.
        bytes payload;
    }

    /**
     * @title ExecutionDetails
     * @dev This struct defines the execution details
     */
    struct ExecutionDetails {
        // packet id
        bytes32 packetId;
        // proposal count
        uint256 proposalCount;
        // gas limit needed to execute inbound
        uint256 executionGasLimit;
        // proof data required by the Decapacitor contract to verify the message's authenticity
        bytes decapacitorProof;
        // signature of executor
        bytes signature;
    }

    /**
     * @notice emits the message details when a new message arrives at outbound
     * @param localChainSlug local chain slug
     * @param localPlug local plug address
     * @param dstChainSlug remote chain slug
     * @param dstPlug remote plug address
     * @param msgId message id packed with remoteChainSlug and nonce
     * @param minMsgGasLimit gas limit needed to execute the inbound at remote
     * @param payload the data which will be used by inbound at remote
     */
    event MessageOutbound(
        uint32 localChainSlug,
        address localPlug,
        uint32 dstChainSlug,
        address dstPlug,
        bytes32 msgId,
        uint256 minMsgGasLimit,
        bytes32 executionParams,
        bytes32 transmissionParams,
        bytes payload,
        Fees fees
    );

    /**
     * @notice emits the status of message after inbound call
     * @param msgId msg id which is executed
     */
    event ExecutionSuccess(bytes32 msgId);

    /**
     * @notice emits the config set by a plug for a remoteChainSlug
     * @param plug address of plug on current chain
     * @param siblingChainSlug sibling chain slug
     * @param siblingPlug address of plug on sibling chain
     * @param inboundSwitchboard inbound switchboard (select from registered options)
     * @param outboundSwitchboard outbound switchboard (select from registered options)
     * @param capacitor capacitor selected based on outbound switchboard
     * @param decapacitor decapacitor selected based on inbound switchboard
     */
    event PlugConnected(
        address plug,
        uint32 siblingChainSlug,
        address siblingPlug,
        address inboundSwitchboard,
        address outboundSwitchboard,
        address capacitor,
        address decapacitor
    );

    /**
     * @notice registers a message
     * @dev Packs the message and includes it in a packet with capacitor
     * @param remoteChainSlug_ the remote chain slug
     * @param minMsgGasLimit_ the gas limit needed to execute the payload on remote
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function outbound(
        uint32 remoteChainSlug_,
        uint256 minMsgGasLimit_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        bytes memory payload_
    ) external payable returns (bytes32 msgId);

    /**
     * @notice executes a message
     * @param executionDetails_ the packet details, proof and signature needed for message execution
     * @param messageDetails_ the message details
     */
    function execute(
        ISocket.ExecutionDetails calldata executionDetails_,
        ISocket.MessageDetails calldata messageDetails_
    ) external payable;

    /**
     * @notice sets the config specific to the plug
     * @param siblingChainSlug_ the sibling chain slug
     * @param siblingPlug_ address of plug present at sibling chain to call inbound
     * @param inboundSwitchboard_ the address of switchboard to use for receiving messages
     * @param outboundSwitchboard_ the address of switchboard to use for sending messages
     */
    function connect(
        uint32 siblingChainSlug_,
        address siblingPlug_,
        address inboundSwitchboard_,
        address outboundSwitchboard_
    ) external;

    /**
     * @notice Retrieves the minimum fees required for a message with a specified gas limit and destination chain.
     * @param minMsgGasLimit_ The gas limit of the message.
     * @param remoteChainSlug_ The slug of the destination chain for the message.
     * @param plug_ The address of the plug through which the message is sent.
     * @return totalFees The minimum fees required for the specified message.
     */
    function getMinFees(
        uint256 minMsgGasLimit_,
        uint256 payloadSize_,
        bytes32 executionParams_,
        bytes32 transmissionParams_,
        uint32 remoteChainSlug_,
        address plug_
    ) external view returns (uint256 totalFees);

    /**
     * @notice returns chain slug
     * @return chainSlug current chain slug
     */
    function chainSlug() external view returns (uint32 chainSlug);

    function globalMessageCount() external view returns (uint64);

    /**
     * @notice returns the config for given `plugAddress_` and `siblingChainSlug_`
     * @param siblingChainSlug_ the sibling chain slug
     * @param plugAddress_ address of plug present at current chain
     */
    function getPlugConfig(
        address plugAddress_,
        uint32 siblingChainSlug_
    )
        external
        view
        returns (
            address siblingPlug,
            address inboundSwitchboard__,
            address outboundSwitchboard__,
            address capacitor__,
            address decapacitor__
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @title IStrategy
 * @notice Interface for strategy contract which interacts with other protocols
 */
interface IStrategy {
    function withdraw(uint256 amount_) external returns (uint256 loss_);

    function withdrawAll() external;

    function estimatedTotalAssets()
        external
        view
        returns (uint256 totalUnderlyingAssets_);

    function invest() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./utils/Ownable.sol";

/**
 * @title KintoDeployer
 * @dev Convenience contract for deploying contracts on Kinto using `CREATE2`
 * and nominating a new address to be the owner.
 */
contract KintoDeployer {
    event ContractDeployed(address indexed addr);

    /**
     * @dev Deploys a contract using `CREATE2` and nominates a new address
     * for owner (if set).
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * @param nominee address to be set as nominee (if set)
     * @param bytecode of the contract to deploy
     * @param salt to use for the calculation
     */
    function deploy(
        address nominee,
        bytes memory bytecode,
        bytes32 salt
    ) external payable returns (address) {
        address addr;
        // deploy the contract using `CREATE2`
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Failed to deploy contract");

        // nominate address if contract is Ownable
        try Ownable(addr).owner() returns (address owner_) {
            if (owner_ == address(this) && nominee != address(0)) {
                Ownable(addr).nominateOwner(nominee);
            }
        } catch {}
        emit ContractDeployed(addr);
        return addr;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.13;

library ExcessivelySafeCall {
    uint constant LOW_28_MASK =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(
        bytes4 _newSelector,
        bytes memory _buf
    ) internal pure {
        require(_buf.length >= 4);
        uint _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "lib/solmate/src/utils/SafeTransferLib.sol";
import "lib/solmate/src/tokens/ERC20.sol";

error ZeroAddress();

/**
 * @title RescueFundsLib
 * @dev A library that provides a function to rescue funds from a contract.
 */

library RescueFundsLib {
    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev thrown when the given token address don't have any code
     */
    error InvalidTokenAddress();

    /**
     * @dev Rescues funds from a contract.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address of the user.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) internal {
        if (rescueTo_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(rescueTo_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), rescueTo_, amount_);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "lib/solmate/src/tokens/ERC20.sol";
import "../utils/RescueBase.sol";
import "../interfaces/IHook.sol";

/**
 * @title SuperToken
 * @notice An ERC20 contract which enables bridging a token to its sibling chains.
 * @dev This contract implements ISuperTokenOrVault to support message bridging through IMessageBridge compliant contracts.
 */
contract SuperToken is ERC20, RescueBase {
    // for all controller access (mint, burn)
    bytes32 constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    /**
     * @notice constructor for creating a new SuperToken.
     * @param name_ token name
     * @param symbol_ token symbol
     * @param decimals_ token decimals (should be same on all chains)
     * @param initialSupplyHolder_ address to which initial supply will be minted
     * @param owner_ owner of this contract
     * @param initialSupply_ initial supply of super token
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address initialSupplyHolder_,
        address owner_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_, decimals_) AccessControl(owner_) {
        _mint(initialSupplyHolder_, initialSupply_);
        _grantRole(RESCUE_ROLE, owner_);
    }

    function burn(
        address user_,
        uint256 amount_
    ) external onlyRole(CONTROLLER_ROLE) {
        _burn(user_, amount_);
    }

    function mint(
        address receiver_,
        uint256 amount_
    ) external onlyRole(CONTROLLER_ROLE) {
        _mint(receiver_, amount_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./YieldTokenBase.sol";
import {IStrategy} from "../../interfaces/IStrategy.sol";
import {IConnector} from "../../interfaces/IConnector.sol";
import {IHook} from "../../interfaces/IHook.sol";

// add shutdown
contract YieldToken is YieldTokenBase {
    using FixedPointMathLib for uint256;

    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant HOOK_ROLE = keccak256("HOOK_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) YieldTokenBase(name_, symbol_, decimals_) AccessControl(msg.sender) {
        _grantRole(RESCUE_ROLE, msg.sender);
    }

    // move to hook
    // fix to round up and check other cases
    function calculateMintAmount(
        uint256 underlyingAssets_
    ) external view returns (uint256) {
        // total supply -> total shares
        // total yield -> total underlying from all chains
        // yield sent from src chain includes new amount hence subtracted here
        uint256 supply = _totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.
        return
            supply == 0
                ? underlyingAssets_
                : underlyingAssets_.mulDivDown(
                    supply,
                    totalUnderlyingAssets - underlyingAssets_
                );
    }

    function burn(
        address user_,
        uint256 shares_
    ) external nonReentrant onlyRole(MINTER_ROLE) {
        _burn(user_, shares_);
    }

    // minter role
    function mint(
        address receiver_,
        uint256 amount_
    ) external nonReentrant onlyRole(MINTER_ROLE) {
        _mint(receiver_, amount_);
    }

    // hook role
    function updateTotalUnderlyingAssets(
        uint256 amount_
    ) external onlyRole(HOOK_ROLE) {
        _updateTotalUnderlyingAssets(amount_);
    }

    function _updateTotalUnderlyingAssets(uint256 amount_) internal {
        totalUnderlyingAssets = amount_;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";
import "../../utils/RescueBase.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {PermitDeadlineExpired, InvalidSigner} from "../../common/Errors.sol";

abstract contract YieldTokenBase is RescueBase, ReentrancyGuard, IERC20 {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal _totalSupply;

    mapping(address => uint256) internal _balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                            YIELD STORAGE
    //////////////////////////////////////////////////////////////*/

    // total yield from all siblings
    uint256 public totalUnderlyingAssets;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function convertToShares(
        uint256 underlyingAssets
    ) public view virtual returns (uint256) {
        uint256 supply = _totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.
        return
            supply == 0
                ? underlyingAssets
                : underlyingAssets.mulDivDown(supply, totalUnderlyingAssets);
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual returns (uint256) {
        uint256 supply = _totalSupply; // Saves an extra SLOAD if _totalSupply is non-zero.
        return
            supply == 0
                ? shares
                : shares.mulDivDown(totalUnderlyingAssets, supply);
    }

    function balanceOf(address user_) external view returns (uint256) {
        uint256 balance = _balanceOf[user_];
        if (balance == 0) return 0;
        return convertToAssets(balance);
    }

    // recheck for multi yield
    function totalSupply() external view returns (uint256) {
        if (_totalSupply == 0) return 0;
        return totalUnderlyingAssets;
    }

    function approve(
        address spender_,
        uint256 amount_
    ) public virtual returns (bool) {
        uint256 shares = convertToShares(amount_);
        allowance[msg.sender][spender_] = shares;

        emit Approval(msg.sender, spender_, shares);

        return true;
    }

    function transfer(
        address to_,
        uint256 amount_
    ) public override returns (bool) {
        uint256 sharesToTransfer = convertToShares(amount_);
        _balanceOf[msg.sender] -= sharesToTransfer;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to_] += sharesToTransfer;
        }

        emit Transfer(msg.sender, to_, amount_);

        return true;
    }

    // transfer changes shares balance but reduces the amount
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public override returns (bool) {
        uint256 sharesToTransfer = convertToShares(amount_);

        uint256 allowed = allowance[from_][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from_][msg.sender] = allowed - sharesToTransfer;

        _balanceOf[from_] -= sharesToTransfer;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to_] += sharesToTransfer;
        }

        emit Transfer(from_, to_, amount_);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (deadline < block.timestamp) revert PermitDeadlineExpired();
        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                convertToShares(value),
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner)
                revert InvalidSigner();

            allowance[recoveredAddress][spender] = convertToShares(value);
        }

        emit Approval(owner, spender, convertToShares(value));
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        _totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            _balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        _balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./Ownable.sol";

/**
 * @title AccessControl
 * @dev This abstract contract implements access control mechanism based on roles.
 * Each role can have one or more addresses associated with it, which are granted
 * permission to execute functions with the onlyRole modifier.
 */
abstract contract AccessControl is Ownable {
    /**
     * @dev A mapping of roles to a mapping of addresses to boolean values indicating whether or not they have the role.
     */
    mapping(bytes32 => mapping(address => bool)) private _permits;

    /**
     * @dev Emitted when a role is granted to an address.
     */
    event RoleGranted(bytes32 indexed role, address indexed grantee);

    /**
     * @dev Emitted when a role is revoked from an address.
     */
    event RoleRevoked(bytes32 indexed role, address indexed revokee);

    /**
     * @dev Error message thrown when an address does not have permission to execute a function with onlyRole modifier.
     */
    error NoPermit(bytes32 role);

    /**
     * @dev Constructor that sets the owner of the contract.
     */
    constructor(address owner_) Ownable(owner_) {}

    /**
     * @dev Modifier that restricts access to addresses having roles
     * Throws an error if the caller do not have permit
     */
    modifier onlyRole(bytes32 role) {
        if (!_permits[role][msg.sender]) revert NoPermit(role);
        _;
    }

    /**
     * @dev Checks and reverts if an address do not have a specific role.
     * @param role_ The role to check.
     * @param address_ The address to check.
     */
    function _checkRole(bytes32 role_, address address_) internal virtual {
        if (!_hasRole(role_, address_)) revert NoPermit(role_);
    }

    /**
     * @dev Grants a role to a given address.
     * @param role_ The role to grant.
     * @param grantee_ The address to grant the role to.
     * Emits a RoleGranted event.
     * Can only be called by the owner of the contract.
     */
    function grantRole(
        bytes32 role_,
        address grantee_
    ) external virtual onlyOwner {
        _grantRole(role_, grantee_);
    }

    /**
     * @dev Revokes a role from a given address.
     * @param role_ The role to revoke.
     * @param revokee_ The address to revoke the role from.
     * Emits a RoleRevoked event.
     * Can only be called by the owner of the contract.
     */
    function revokeRole(
        bytes32 role_,
        address revokee_
    ) external virtual onlyOwner {
        _revokeRole(role_, revokee_);
    }

    /**
     * @dev Internal function to grant a role to a given address.
     * @param role_ The role to grant.
     * @param grantee_ The address to grant the role to.
     * Emits a RoleGranted event.
     */
    function _grantRole(bytes32 role_, address grantee_) internal {
        _permits[role_][grantee_] = true;
        emit RoleGranted(role_, grantee_);
    }

    /**
     * @dev Internal function to revoke a role from a given address.
     * @param role_ The role to revoke.
     * @param revokee_ The address to revoke the role from.
     * Emits a RoleRevoked event.
     */
    function _revokeRole(bytes32 role_, address revokee_) internal {
        _permits[role_][revokee_] = false;
        emit RoleRevoked(role_, revokee_);
    }

    /**
     * @dev Checks whether an address has a specific role.
     * @param role_ The role to check.
     * @param address_ The address to check.
     * @return A boolean value indicating whether or not the address has the role.
     */
    function hasRole(
        bytes32 role_,
        address address_
    ) external view returns (bool) {
        return _hasRole(role_, address_);
    }

    function _hasRole(
        bytes32 role_,
        address address_
    ) internal view returns (bool) {
        return _permits[role_][address_];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "from" argument.
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(ERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(ERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            )
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

error ZeroAddress();

/**
 * @title RescueFundsLib
 * @dev A library that provides a function to rescue funds from a contract.
 */

library RescueFundsLib {
    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /**
     * @dev thrown when the given token address don't have any code
     */
    error InvalidTokenAddress();

    /**
     * @dev Rescues funds from a contract.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address of the user.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) internal {
        if (rescueTo_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(rescueTo_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), rescueTo_, amount_);
        }
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract provides a simple way to manage ownership of a contract
 * and allows for ownership to be transferred to a nominated address.
 */
abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    error OnlyOwner();
    error OnlyNominee();

    /**
     * @dev Sets the contract's owner to the address that is passed to the constructor.
     */
    constructor(address owner_) {
        _claimOwner(owner_);
    }

    /**
     * @dev Modifier that restricts access to only the contract's owner.
     * Throws an error if the caller is not the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) revert OnlyOwner();
        _;
    }

    /**
     * @dev Returns the current owner of the contract.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the current nominee for ownership of the contract.
     */
    function nominee() external view returns (address) {
        return _nominee;
    }

    /**
     * @dev Allows the current owner to nominate a new owner for the contract.
     * Throws an error if the caller is not the owner.
     * Emits an `OwnerNominated` event with the address of the nominee.
     */
    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) revert OnlyOwner();
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    /**
     * @dev Allows the nominated owner to claim ownership of the contract.
     * Throws an error if the caller is not the nominee.
     * Sets the nominated owner as the new owner of the contract.
     * Emits an `OwnerClaimed` event with the address of the new owner.
     */
    function claimOwner() external {
        if (msg.sender != _nominee) revert OnlyNominee();
        _claimOwner(msg.sender);
    }

    /**
     * @dev Internal function that sets the owner of the contract to the specified address
     * and sets the nominee to address(0).
     */
    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}

/**
 * @title AccessControl
 * @dev This abstract contract implements access control mechanism based on roles.
 * Each role can have one or more addresses associated with it, which are granted
 * permission to execute functions with the onlyRole modifier.
 */
abstract contract AccessControl is Ownable {
    /**
     * @dev A mapping of roles to a mapping of addresses to boolean values indicating whether or not they have the role.
     */
    mapping(bytes32 => mapping(address => bool)) private _permits;

    /**
     * @dev Emitted when a role is granted to an address.
     */
    event RoleGranted(bytes32 indexed role, address indexed grantee);

    /**
     * @dev Emitted when a role is revoked from an address.
     */
    event RoleRevoked(bytes32 indexed role, address indexed revokee);

    /**
     * @dev Error message thrown when an address does not have permission to execute a function with onlyRole modifier.
     */
    error NoPermit(bytes32 role);

    /**
     * @dev Constructor that sets the owner of the contract.
     */
    constructor(address owner_) Ownable(owner_) {}

    /**
     * @dev Modifier that restricts access to addresses having roles
     * Throws an error if the caller do not have permit
     */
    modifier onlyRole(bytes32 role) {
        if (!_permits[role][msg.sender]) revert NoPermit(role);
        _;
    }

    /**
     * @dev Checks and reverts if an address do not have a specific role.
     * @param role_ The role to check.
     * @param address_ The address to check.
     */
    function _checkRole(bytes32 role_, address address_) internal virtual {
        if (!_hasRole(role_, address_)) revert NoPermit(role_);
    }

    /**
     * @dev Grants a role to a given address.
     * @param role_ The role to grant.
     * @param grantee_ The address to grant the role to.
     * Emits a RoleGranted event.
     * Can only be called by the owner of the contract.
     */
    function grantRole(
        bytes32 role_,
        address grantee_
    ) external virtual onlyOwner {
        _grantRole(role_, grantee_);
    }

    /**
     * @dev Revokes a role from a given address.
     * @param role_ The role to revoke.
     * @param revokee_ The address to revoke the role from.
     * Emits a RoleRevoked event.
     * Can only be called by the owner of the contract.
     */
    function revokeRole(
        bytes32 role_,
        address revokee_
    ) external virtual onlyOwner {
        _revokeRole(role_, revokee_);
    }

    /**
     * @dev Internal function to grant a role to a given address.
     * @param role_ The role to grant.
     * @param grantee_ The address to grant the role to.
     * Emits a RoleGranted event.
     */
    function _grantRole(bytes32 role_, address grantee_) internal {
        _permits[role_][grantee_] = true;
        emit RoleGranted(role_, grantee_);
    }

    /**
     * @dev Internal function to revoke a role from a given address.
     * @param role_ The role to revoke.
     * @param revokee_ The address to revoke the role from.
     * Emits a RoleRevoked event.
     */
    function _revokeRole(bytes32 role_, address revokee_) internal {
        _permits[role_][revokee_] = false;
        emit RoleRevoked(role_, revokee_);
    }

    /**
     * @dev Checks whether an address has a specific role.
     * @param role_ The role to check.
     * @param address_ The address to check.
     * @return A boolean value indicating whether or not the address has the role.
     */
    function hasRole(
        bytes32 role_,
        address address_
    ) external view returns (bool) {
        return _hasRole(role_, address_);
    }

    function _hasRole(
        bytes32 role_,
        address address_
    ) internal view returns (bool) {
        return _permits[role_][address_];
    }
}

/**
 * @title Base contract for super token and vault
 * @notice It contains relevant execution payload storages.
 * @dev This contract implements Socket's IPlug to enable message bridging and IMessageBridge
 * to support any type of message bridge.
 */
abstract contract RescueBase is AccessControl {
    bytes32 constant RESCUE_ROLE = keccak256("RESCUE_ROLE");

    /**
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}

contract Faucet is RescueBase {
    using SafeTransferLib for ERC20;

    constructor() AccessControl(msg.sender) {
        _grantRole(RESCUE_ROLE, msg.sender);
    }

    function getTokens(address receiver_, address[] calldata tokens_) external {
        for (uint256 i = 0; i < tokens_.length; i++) {
            ERC20 token = ERC20(tokens_[i]);
            uint256 amount = 10 ** token.decimals() * 1000;
            token.safeTransfer(receiver_, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "../common/Structs.sol";

abstract contract Gauge {
    error AmountOutsideLimit();

    function _getCurrentLimit(
        LimitParams storage _params
    ) internal view returns (uint256 _limit) {
        uint256 timeElapsed = block.timestamp - _params.lastUpdateTimestamp;
        uint256 limitIncrease = timeElapsed * _params.ratePerSecond;

        if (limitIncrease + _params.lastUpdateLimit > _params.maxLimit) {
            _limit = _params.maxLimit;
        } else {
            _limit = limitIncrease + _params.lastUpdateLimit;
        }
    }

    function _consumePartLimit(
        uint256 amount_,
        LimitParams storage _params
    ) internal returns (uint256 consumedAmount, uint256 pendingAmount) {
        uint256 currentLimit = _getCurrentLimit(_params);
        _params.lastUpdateTimestamp = block.timestamp;
        if (currentLimit >= amount_) {
            _params.lastUpdateLimit = currentLimit - amount_;
            consumedAmount = amount_;
            pendingAmount = 0;
        } else {
            _params.lastUpdateLimit = 0;
            consumedAmount = currentLimit;
            pendingAmount = amount_ - currentLimit;
        }
    }

    function _consumeFullLimit(
        uint256 amount_,
        LimitParams storage _params
    ) internal {
        uint256 currentLimit = _getCurrentLimit(_params);
        if (currentLimit >= amount_) {
            _params.lastUpdateTimestamp = block.timestamp;
            _params.lastUpdateLimit = currentLimit - amount_;
        } else {
            revert AmountOutsideLimit();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

/**
 * @title Ownable
 * @dev The Ownable contract provides a simple way to manage ownership of a contract
 * and allows for ownership to be transferred to a nominated address.
 */
abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    error OnlyOwner();
    error OnlyNominee();

    /**
     * @dev Sets the contract's owner to the address that is passed to the constructor.
     */
    constructor(address owner_) {
        _claimOwner(owner_);
    }

    /**
     * @dev Modifier that restricts access to only the contract's owner.
     * Throws an error if the caller is not the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != _owner) revert OnlyOwner();
        _;
    }

    /**
     * @dev Returns the current owner of the contract.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the current nominee for ownership of the contract.
     */
    function nominee() external view returns (address) {
        return _nominee;
    }

    /**
     * @dev Allows the current owner to nominate a new owner for the contract.
     * Throws an error if the caller is not the owner.
     * Emits an `OwnerNominated` event with the address of the nominee.
     */
    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) revert OnlyOwner();
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    /**
     * @dev Allows the nominated owner to claim ownership of the contract.
     * Throws an error if the caller is not the nominee.
     * Sets the nominated owner as the new owner of the contract.
     * Emits an `OwnerClaimed` event with the address of the new owner.
     */
    function claimOwner() external {
        if (msg.sender != _nominee) revert OnlyNominee();
        _claimOwner(msg.sender);
    }

    /**
     * @dev Internal function that sets the owner of the contract to the specified address
     * and sets the nominee to address(0).
     */
    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import {RescueFundsLib} from "../libraries/RescueFundsLib.sol";
import {AccessControl} from "./AccessControl.sol";

/**
 * @title Base contract for super token and vault
 * @notice It contains relevant execution payload storages.
 * @dev This contract implements Socket's IPlug to enable message bridging and IMessageBridge
 * to support any type of message bridge.
 */
abstract contract RescueBase is AccessControl {
    bytes32 constant RESCUE_ROLE = keccak256("RESCUE_ROLE");

    /**
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyRole(RESCUE_ROLE) {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}