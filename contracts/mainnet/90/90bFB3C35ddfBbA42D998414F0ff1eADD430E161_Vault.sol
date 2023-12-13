// SPDX-License-Identifier: GPL-3.0-only
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

// SPDX-License-Identifier: GPL-3.0-only
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
        bytes calldata payload_
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

pragma solidity 0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {ISocket} from "../interfaces/ISocket.sol";
import {IPlug} from "../interfaces/IPlug.sol";
import {RescueFundsLib} from "./RescueFundsLib.sol";

interface IHub {
    function receiveInbound(bytes memory payload_) external;
}

interface IConnector {
    function outbound(
        uint256 msgGasLimit_,
        bytes memory payload_
    ) external payable;

    function siblingChainSlug() external view returns (uint32);

    function getMinFees(
        uint256 msgGasLimit_
    ) external view returns (uint256 totalFees);
}

contract ConnectorPlug is IConnector, IPlug, Ownable2Step {
    IHub public immutable hub__;
    ISocket public immutable socket__;
    uint32 public immutable siblingChainSlug;

    error NotHub();
    error NotSocket();

    event ConnectorPlugDisconnected();

    constructor(address hub_, address socket_, uint32 siblingChainSlug_) {
        hub__ = IHub(hub_);
        socket__ = ISocket(socket_);
        siblingChainSlug = siblingChainSlug_;
    }

    function outbound(
        uint256 msgGasLimit_,
        bytes memory payload_
    ) external payable override {
        if (msg.sender != address(hub__)) revert NotHub();

        socket__.outbound{value: msg.value}(
            siblingChainSlug,
            msgGasLimit_,
            bytes32(0),
            bytes32(0),
            payload_
        );
    }

    function inbound(
        uint32 /* siblingChainSlug_ */, // cannot be connected for any other slug, immutable variable
        bytes calldata payload_
    ) external payable override {
        if (msg.sender != address(socket__)) revert NotSocket();
        hub__.receiveInbound(payload_);
    }

    function getMinFees(
        uint256 msgGasLimit_
    ) external view override returns (uint256 totalFees) {
        return
            socket__.getMinFees(
                msgGasLimit_,
                64,
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
        socket__.connect(
            siblingChainSlug,
            siblingPlug_,
            switchboard_,
            switchboard_
        );
    }

    function disconnect() external onlyOwner {
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
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(
        address token_,
        address rescueTo_,
        uint256 amount_
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}

pragma solidity 0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {IExchangeRate} from "./ExchangeRate.sol";
import {Gauge} from "./Gauge.sol";
import {IConnector, IHub} from "./ConnectorPlug.sol";
import {IMintableERC20} from "./IMintableERC20.sol";
import {RescueFundsLib} from "./RescueFundsLib.sol";

contract Controller is IHub, Gauge, Ownable2Step {
    IMintableERC20 public immutable token__;
    IExchangeRate public exchangeRate__;

    struct UpdateLimitParams {
        bool isMint;
        address connector;
        uint256 maxLimit;
        uint256 ratePerSecond;
    }

    // connectorPoolId => totalLockedAmount
    mapping(uint256 => uint256) public poolLockedAmounts;

    // connector => connectorPoolId
    mapping(address => uint256) public connectorPoolIds;

    // connector => mintLimitParams
    mapping(address => LimitParams) _mintLimitParams;

    // connector => burnLimitParams
    mapping(address => LimitParams) _burnLimitParams;

    // connector => receiver => amount
    mapping(address => mapping(address => uint256)) public pendingMints;

    // connector => amount
    mapping(address => uint256) public connectorPendingMints;

    uint256 public totalMinted;

    error ConnectorUnavailable();
    error InvalidPoolId();
    error ZeroAmount();
    event ExchangeRateUpdated(address exchangeRate);
    event ConnectorPoolIdUpdated(address connector, uint256 poolId);
    event LimitParamsUpdated(UpdateLimitParams[] updates);
    event TokensWithdrawn(
        address connector,
        address withdrawer,
        address receiver,
        uint256 burnAmount
    );
    event PendingTokensMinted(
        address connector,
        address receiver,
        uint256 mintAmount,
        uint256 pendingAmount
    );
    event TokensPending(
        address connecter,
        address receiver,
        uint256 pendingAmount,
        uint256 totalPendingAmount
    );
    event TokensMinted(address connecter, address receiver, uint256 mintAmount);

    constructor(address token_, address exchangeRate_) {
        token__ = IMintableERC20(token_);
        exchangeRate__ = IExchangeRate(exchangeRate_);
    }

    function updateExchangeRate(address exchangeRate_) external onlyOwner {
        exchangeRate__ = IExchangeRate(exchangeRate_);
        emit ExchangeRateUpdated(exchangeRate_);
    }

    function updateConnectorPoolId(
        address[] calldata connectors,
        uint256[] calldata poolIds
    ) external onlyOwner {
        uint256 length = connectors.length;
        for (uint256 i; i < length; i++) {
            if (poolIds[i] == 0) revert InvalidPoolId();
            connectorPoolIds[connectors[i]] = poolIds[i];
            emit ConnectorPoolIdUpdated(connectors[i], poolIds[i]);
        }
    }

    function updateLimitParams(
        UpdateLimitParams[] calldata updates_
    ) external onlyOwner {
        for (uint256 i; i < updates_.length; i++) {
            if (updates_[i].isMint) {
                _consumePartLimit(0, _mintLimitParams[updates_[i].connector]); // to keep current limit in sync
                _mintLimitParams[updates_[i].connector].maxLimit = updates_[i]
                    .maxLimit;
                _mintLimitParams[updates_[i].connector]
                    .ratePerSecond = updates_[i].ratePerSecond;
            } else {
                _consumePartLimit(0, _burnLimitParams[updates_[i].connector]); // to keep current limit in sync
                _burnLimitParams[updates_[i].connector].maxLimit = updates_[i]
                    .maxLimit;
                _burnLimitParams[updates_[i].connector]
                    .ratePerSecond = updates_[i].ratePerSecond;
            }
        }

        emit LimitParamsUpdated(updates_);
    }

    // do we throttle burn amount or unlock amount? burn for now
    function withdrawFromAppChain(
        address receiver_,
        uint256 burnAmount_,
        uint256 msgGasLimit_,
        address connector_
    ) external payable {
        if (burnAmount_ == 0) revert ZeroAmount();

        if (_burnLimitParams[connector_].maxLimit == 0)
            revert ConnectorUnavailable();

        _consumeFullLimit(burnAmount_, _burnLimitParams[connector_]); // reverts on limit hit

        totalMinted -= burnAmount_;
        _burn(msg.sender, burnAmount_);

        uint256 connectorPoolId = connectorPoolIds[connector_];
        if (connectorPoolId == 0) revert InvalidPoolId();
        uint256 unlockAmount = exchangeRate__.getUnlockAmount(
            burnAmount_,
            poolLockedAmounts[connectorPoolId]
        );
        poolLockedAmounts[connectorPoolId] -= unlockAmount; // underflow revert expected

        IConnector(connector_).outbound{value: msg.value}(
            msgGasLimit_,
            abi.encode(receiver_, unlockAmount)
        );

        emit TokensWithdrawn(connector_, msg.sender, receiver_, burnAmount_);
    }

    function _burn(address user_, uint256 burnAmount_) internal virtual {
        token__.burn(user_, burnAmount_);
    }

    function mintPendingFor(address receiver_, address connector_) external {
        if (_mintLimitParams[connector_].maxLimit == 0)
            revert ConnectorUnavailable();

        uint256 pendingMint = pendingMints[connector_][receiver_];
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            pendingMint,
            _mintLimitParams[connector_]
        );

        pendingMints[connector_][receiver_] = pendingAmount;
        connectorPendingMints[connector_] -= consumedAmount;
        totalMinted += consumedAmount;

        token__.mint(receiver_, consumedAmount);

        emit PendingTokensMinted(
            connector_,
            receiver_,
            consumedAmount,
            pendingAmount
        );
    }

    // receive inbound assuming connector called
    function receiveInbound(bytes memory payload_) external override {
        if (_mintLimitParams[msg.sender].maxLimit == 0)
            revert ConnectorUnavailable();

        (address receiver, uint256 lockAmount) = abi.decode(
            payload_,
            (address, uint256)
        );
        uint256 connectorPoolId = connectorPoolIds[msg.sender];
        if (connectorPoolId == 0) revert InvalidPoolId();
        poolLockedAmounts[connectorPoolId] += lockAmount;

        uint256 mintAmount = exchangeRate__.getMintAmount(
            lockAmount,
            poolLockedAmounts[connectorPoolId]
        );
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            mintAmount,
            _mintLimitParams[msg.sender]
        );

        if (pendingAmount > 0) {
            // add instead of overwrite to handle case where already pending amount is left
            pendingMints[msg.sender][receiver] += pendingAmount;
            connectorPendingMints[msg.sender] += pendingAmount;
            emit TokensPending(
                msg.sender,
                receiver,
                pendingAmount,
                pendingMints[msg.sender][receiver]
            );
        }

        totalMinted += consumedAmount;
        token__.mint(receiver, consumedAmount);

        emit TokensMinted(msg.sender, receiver, consumedAmount);
    }

    function getMinFees(
        address connector_,
        uint256 msgGasLimit_
    ) external view returns (uint256 totalFees) {
        return IConnector(connector_).getMinFees(msgGasLimit_);
    }

    function getCurrentMintLimit(
        address connector_
    ) external view returns (uint256) {
        return _getCurrentLimit(_mintLimitParams[connector_]);
    }

    function getCurrentBurnLimit(
        address connector_
    ) external view returns (uint256) {
        return _getCurrentLimit(_burnLimitParams[connector_]);
    }

    function getMintLimitParams(
        address connector_
    ) external view returns (LimitParams memory) {
        return _mintLimitParams[connector_];
    }

    function getBurnLimitParams(
        address connector_
    ) external view returns (LimitParams memory) {
        return _burnLimitParams[connector_];
    }

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
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}

pragma solidity 0.8.13;

import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {RescueFundsLib} from "./RescueFundsLib.sol";

interface IExchangeRate {
    // not marked pure, may involve state interactions in future
    function getMintAmount(
        uint256 lockAmount,
        uint256 totalLockedAmount
    ) external returns (uint256 mintAmount);

    // not marked pure, may involve state interactions in future
    function getUnlockAmount(
        uint256 burnAmount,
        uint256 totalLockedAmount
    ) external returns (uint256 unlockAmount);
}

contract ExchangeRate is IExchangeRate, Ownable2Step {
    // chainId input needed? what else? slippage?
    function getMintAmount(
        uint256 lockAmount,
        uint256 /* totalLockedAmount */
    ) external pure returns (uint256 mintAmount) {
        return lockAmount;
    }

    function getUnlockAmount(
        uint256 burnAmount,
        uint256 /* totalLockedAmount */
    ) external pure returns (uint256 unlockAmount) {
        return burnAmount;
    }

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
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}

pragma solidity 0.8.13;

import "lib/solmate/src/utils/SafeTransferLib.sol";
import {Controller} from "../Controller.sol";
import {IMintableERC20} from "../IMintableERC20.sol";
import {IFiatTokenV2_1_Mintable} from "./IFiatTokenV2_1_Mintable.sol";

contract FiatTokenV2_1_Controller is Controller {
    using SafeTransferLib for IMintableERC20;

    constructor(
        address token_,
        address exchangeRate_
    ) Controller(token_, exchangeRate_) {}

    function _burn(address user_, uint256 burnAmount_) internal override {
        token__.safeTransferFrom(user_, address(this), burnAmount_);
        IFiatTokenV2_1_Mintable(address(token__)).burn(burnAmount_);
    }
}

pragma solidity 0.8.13;

import "lib/solmate/src/tokens/ERC20.sol";

// USDC's standard token
abstract contract IFiatTokenV2_1_Mintable is ERC20 {
    function mint(address receiver_, uint256 amount_) external virtual;

    function burn(uint256 _amount) external virtual;
}

pragma solidity 0.8.13;

abstract contract Gauge {
    struct LimitParams {
        uint256 lastUpdateTimestamp;
        uint256 ratePerSecond;
        uint256 maxLimit;
        uint256 lastUpdateLimit;
    }

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

pragma solidity 0.8.13;

import "lib/solmate/src/tokens/ERC20.sol";

abstract contract IMintableERC20 is ERC20 {
    function mint(address receiver_, uint256 amount_) external virtual;

    function burn(address burner_, uint256 amount_) external virtual;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "lib/solmate/src/utils/SafeTransferLib.sol";

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

pragma solidity 0.8.13;

import "lib/solmate/src/utils/SafeTransferLib.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Gauge} from "./Gauge.sol";
import {IConnector, IHub} from "./ConnectorPlug.sol";
import {RescueFundsLib} from "./RescueFundsLib.sol";

// @todo: separate our connecter plugs
contract Vault is Gauge, IHub, Ownable2Step {
    using SafeTransferLib for ERC20;
    ERC20 public immutable token__;

    struct UpdateLimitParams {
        bool isLock;
        address connector;
        uint256 maxLimit;
        uint256 ratePerSecond;
    }

    // connector => receiver => pendingUnlock
    mapping(address => mapping(address => uint256)) public pendingUnlocks;

    // connector => amount
    mapping(address => uint256) public connectorPendingUnlocks;

    // connector => lockLimitParams
    mapping(address => LimitParams) _lockLimitParams;

    // connector => unlockLimitParams
    mapping(address => LimitParams) _unlockLimitParams;

    error ConnectorUnavailable();
    error ZeroAmount();

    event LimitParamsUpdated(UpdateLimitParams[] updates);
    event TokensDeposited(
        address connector,
        address depositor,
        address receiver,
        uint256 depositAmount
    );
    event PendingTokensTransferred(
        address connector,
        address receiver,
        uint256 unlockedAmount,
        uint256 pendingAmount
    );
    event TokensPending(
        address connector,
        address receiver,
        uint256 pendingAmount,
        uint256 totalPendingAmount
    );
    event TokensUnlocked(
        address connector,
        address receiver,
        uint256 unlockedAmount
    );

    constructor(address token_) {
        token__ = ERC20(token_);
    }

    function updateLimitParams(
        UpdateLimitParams[] calldata updates_
    ) external onlyOwner {
        for (uint256 i; i < updates_.length; i++) {
            if (updates_[i].isLock) {
                _consumePartLimit(0, _lockLimitParams[updates_[i].connector]); // to keep current limit in sync
                _lockLimitParams[updates_[i].connector].maxLimit = updates_[i]
                    .maxLimit;
                _lockLimitParams[updates_[i].connector]
                    .ratePerSecond = updates_[i].ratePerSecond;
            } else {
                _consumePartLimit(0, _unlockLimitParams[updates_[i].connector]); // to keep current limit in sync
                _unlockLimitParams[updates_[i].connector].maxLimit = updates_[i]
                    .maxLimit;
                _unlockLimitParams[updates_[i].connector]
                    .ratePerSecond = updates_[i].ratePerSecond;
            }
        }

        emit LimitParamsUpdated(updates_);
    }

    function depositToAppChain(
        address receiver_,
        uint256 amount_,
        uint256 msgGasLimit_,
        address connector_
    ) external payable {
        if (amount_ == 0) revert ZeroAmount();

        if (_lockLimitParams[connector_].maxLimit == 0)
            revert ConnectorUnavailable();

        _consumeFullLimit(amount_, _lockLimitParams[connector_]); // reverts on limit hit

        token__.safeTransferFrom(msg.sender, address(this), amount_);

        IConnector(connector_).outbound{value: msg.value}(
            msgGasLimit_,
            abi.encode(receiver_, amount_)
        );

        emit TokensDeposited(connector_, msg.sender, receiver_, amount_);
    }

    function unlockPendingFor(address receiver_, address connector_) external {
        if (_unlockLimitParams[connector_].maxLimit == 0)
            revert ConnectorUnavailable();

        uint256 pendingUnlock = pendingUnlocks[connector_][receiver_];
        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            pendingUnlock,
            _unlockLimitParams[connector_]
        );

        pendingUnlocks[connector_][receiver_] = pendingAmount;
        connectorPendingUnlocks[connector_] -= consumedAmount;

        token__.safeTransfer(receiver_, consumedAmount);

        emit PendingTokensTransferred(
            connector_,
            receiver_,
            consumedAmount,
            pendingAmount
        );
    }

    // receive inbound assuming connector called
    function receiveInbound(bytes memory payload_) external override {
        if (_unlockLimitParams[msg.sender].maxLimit == 0)
            revert ConnectorUnavailable();

        (address receiver, uint256 unlockAmount) = abi.decode(
            payload_,
            (address, uint256)
        );

        (uint256 consumedAmount, uint256 pendingAmount) = _consumePartLimit(
            unlockAmount,
            _unlockLimitParams[msg.sender]
        );

        if (pendingAmount > 0) {
            // add instead of overwrite to handle case where already pending amount is left
            pendingUnlocks[msg.sender][receiver] += pendingAmount;
            connectorPendingUnlocks[msg.sender] += pendingAmount;
            emit TokensPending(
                msg.sender,
                receiver,
                pendingAmount,
                pendingUnlocks[msg.sender][receiver]
            );
        }
        token__.safeTransfer(receiver, consumedAmount);

        emit TokensUnlocked(msg.sender, receiver, consumedAmount);
    }

    function getMinFees(
        address connector_,
        uint256 msgGasLimit_
    ) external view returns (uint256 totalFees) {
        return IConnector(connector_).getMinFees(msgGasLimit_);
    }

    function getCurrentLockLimit(
        address connector_
    ) external view returns (uint256) {
        return _getCurrentLimit(_lockLimitParams[connector_]);
    }

    function getCurrentUnlockLimit(
        address connector_
    ) external view returns (uint256) {
        return _getCurrentLimit(_unlockLimitParams[connector_]);
    }

    function getLockLimitParams(
        address connector_
    ) external view returns (LimitParams memory) {
        return _lockLimitParams[connector_];
    }

    function getUnlockLimitParams(
        address connector_
    ) external view returns (LimitParams memory) {
        return _unlockLimitParams[connector_];
    }

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
    ) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

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
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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