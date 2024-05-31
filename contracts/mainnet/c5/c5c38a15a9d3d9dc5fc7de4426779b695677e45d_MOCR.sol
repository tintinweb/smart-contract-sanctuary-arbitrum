// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";
import {BaseControlRoom} from "./BaseControlRoom.sol";
import {ControlRoomAccessControl} from "../base/ControlRoomAccessControl.sol";
import {Permit2Lib} from "../lib/Permit2Lib.sol";
import {AffiliateFeesLib} from "../lib/AffiliateFeesLib.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {SignedBatch} from "../base/ControlRoomStructs.sol";
import {MultiOutputCRLib, MultiOutputCommand, MultiOutputExec, MultiOutputBatch} from "../lib/MOCRLib.sol";
import {
    BatchAuthenticationFailed,
    MinOutputNotMet,
    FulfillmentChainInvalid,
    CommandAlreadyFulfilled,
    NonSocketMessageInbound,
    InvalidCommand,
    PromisedAmountNotMet,
    InvalidMsgSender,
    FulfillDeadlineNotMet,
    InsufficientSwapOutputAmount
} from "../base/ControlRoomErrors.sol";

// Info representing the origin execution of a command
struct OriginExec {
    address commander;
    address inputToken;
    address beneficiary;
    uint32 switchBoardId;
    uint256 inputAmount;
    uint256[] promisedOutputs;
    uint256 fulfillDeadline;
    bytes affiliateFees;
}

// Info representing the destination execution of a command.
struct DestinationExec {
    address[] outputTokens;
    uint256[] amounts;
}

struct ExecutionCache {
    address target;
    uint256 msgValue;
    bytes encodedData;
}

/// @title MOCR - MultiOutputControlRoom
/// @notice Implements BaseControlRoom to support commands involving multiple outputTokens
contract MOCR is Ownable, BaseControlRoom, ControlRoomAccessControl {
    /// Libs
    using SafeTransferLib for ERC20;
    using MultiOutputCRLib for MultiOutputCommand;
    using MultiOutputCRLib for MultiOutputBatch;

    /// Constructor
    constructor(
        address _permit2Address,
        address _bungeeWhitelistRegistry,
        address _owner,
        uint256 _originExecExpiry
    ) Ownable(_owner) BaseControlRoom(_permit2Address, _bungeeWhitelistRegistry, _originExecExpiry) {}

    /// @notice origin execution details mapped to commandHash
    mapping(bytes32 => OriginExec) internal originExecs;

    /// @notice destination execution details mapped to commandHash
    mapping(bytes32 => DestinationExec) internal destinationExecs;

    /*//////////////////////////////////////////////////////////////////////////
                                ORIGIN CHAIN COMMANDS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Destructures Command into MultiOutputBatch and executes it on the origin chain
     * @param signedBatch batch of MultiOutput Commands that will be executed.
     *      The batch will first be authenticated for the Bungee Whitehouse signature.
     *      The Command details will be validated and funds will be transferred from the commander using their PERMIT2 signature
     */
    function engageCommands(SignedBatch calldata signedBatch) internal override {
        /// Decode the batch into Multi Output Batch
        MultiOutputBatch memory batch = abi.decode(signedBatch.batch, (MultiOutputBatch));

        // Validate the batch is appropriately signed.
        _validateBatch(batch, signedBatch.sig);

        // Loop through all the executions given by the soldier to execute commands.
        unchecked {
            for (uint256 i = 0; i < batch.execs.length; i++) {
                // Validate the command given by the commander.
                bytes32 commandHash = _validateExec(batch.execs[i]);

                // Transfer tokens and perform action if required.
                batch.execs[i].swapData.length == 0
                    ? _execBungee(batch.execs[i], commandHash, batch.beneficiary)
                    : _execBungeeSwap(batch.execs[i], commandHash, batch.beneficiary);

                // Emits event
                emit CommandExecuted(commandHash, msg.sender, abi.encode(batch.execs[i]));
            }
        }
    }

    /**
     * @dev Responsible for unlocking funds to the beneficiary if the conditions suffice.
     * @param switchBoardId array of commands.
     * @param payload gas limit for the msg
     */
    function inboundMsg(uint32 switchBoardId, bytes calldata payload) external payable override {
        // Check if the message is coming from the correct switchboard.
        if (msg.sender != address(BUNGEE_WHITELIST_REGISTRY.switchBoardPlugsMap(switchBoardId)))
            revert NonSocketMessageInbound();

        // Decode the payload
        // The payload is verified on the SwitchboardPlug
        (bytes32[] memory commandHashes, uint256[][] memory amounts) = abi.decode(payload, (bytes32[], uint256[][]));

        // Check for Command being cancelled
        // We send an empty amounts array for cancelled Commands in `annulCommand`
        if (amounts.length == 0 && commandHashes.length == 1) {
            _revertCommand(switchBoardId, commandHashes[0]);
            return;
        }

        // Loop and settle commands
        unchecked {
            for (uint256 i = 0; i < commandHashes.length; i++) {
                for (uint256 j = 0; j < amounts.length; j++) {
                    // Validate the execution done on destination for the command.
                    // Revert if the execution does not suffice.
                    // Send the tokens to the beneficiary if all suffices the command.
                    _validateAndRelease(switchBoardId, commandHashes[i], amounts[i]);

                    emit CommandInbound(commandHashes[i], abi.encode(amounts[i]));
                }
            }
        }
    }

    /**
     * @dev this function can be called by commander.
     * @notice this function is used to revoke the command given.
     * @param commandHash hash of the command
     */
    function lapseCommand(bytes32 commandHash) external payable override {
        // Get the origin execution
        OriginExec memory originExec = originExecs[commandHash];

        // Check if the deadline has passed
        if (block.timestamp < originExec.fulfillDeadline) {
            revert FulfillDeadlineNotMet();
        }

        // Send tokens back to the commander
        _sendFundsFromContract(originExec.inputToken, originExec.inputAmount, originExec.commander);

        // delete the origin execution
        delete originExecs[commandHash];

        emit CommandLapsed(commandHash);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            DESTINATION CHAIN COMMANDS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Responsible for executing the command on the destination chain
     * @notice Each exec will have the amount that will be used to fulfil command.
     * @notice Command hash is generated and will be used to unlock tokens on the origin chain.
     * @notice If the fulfilment is wrong the solver will not unlock tokens on the origin chain.
     * @notice User can unlock the funds even after execution if settlement not received.
     * @notice Funds will always be unlocked to the beneficiary.
     * @param batch Encoded batch array of MultiOutputExec
     */
    function obeyCommands(bytes calldata batch) external payable override {
        // Decodes batch into MultiOutputExec[]
        MultiOutputExec[] memory execs = abi.decode(batch, (MultiOutputExec[]));

        // Loop the executions and fulfill them
        unchecked {
            for (uint256 i = 0; i < execs.length; i++) {
                // Check if the chainId is correct for Command Execution
                if (block.chainid != execs[i].command.info.destinationChainId) revert FulfillmentChainInvalid();

                // Create the command hash against which the command is being executed.
                bytes32 commandHash = execs[i].command.hashDestinationCommand();

                // Check if the command is already fulfilled
                // assumes if first outputToken filled is over 0, the whole command was executed
                // @review needed here
                if (destinationExecs[commandHash].amounts.length > 0 && destinationExecs[commandHash].amounts[0] > 0)
                    revert CommandAlreadyFulfilled();

                for (uint256 j = 0; j < execs[i].command.outputTokens.length; j++) {
                    // Revert if promisedOutput is less than minOutput amount
                    if (execs[i].promisedOutputs[i] < execs[i].command.minOutputs[i]) revert MinOutputNotMet();

                    // Send the tokens in the command to the receiver.
                    _sendFundsToReceiver(
                        execs[i].command.outputTokens[j],
                        msg.sender,
                        execs[i].promisedOutputs[j],
                        execs[i].command.info.receiver
                    );
                }

                // Execute call data in the command.
                _callDestination(
                    execs[i].command.info.receiver,
                    execs[i].command.minDstGasLimit,
                    execs[i].promisedOutputs,
                    execs[i].command.outputTokens,
                    commandHash,
                    execs[i].command.dstData
                );

                // Save the Executed Command
                destinationExecs[commandHash] = DestinationExec(
                    execs[i].command.outputTokens,
                    execs[i].promisedOutputs
                );

                emit CommandFulfilled(commandHash, msg.sender, abi.encode(execs[i]));
            }
        }
    }

    /**
     * @dev Responsible for going back to base and informing that the command is executed.
     * @notice Each exec will have the amount that will be used to fulfil command.
     * @notice Array of commands and their following execution details will be sent back.
     * @notice If the fulfilment is wrong the solver will not unlock tokens on the origin chain.
     * @notice User can unlock the funds even after execution if settlement not received.
     * @notice Funds will always be unlocked to the beneficiary on the srcChainId.
     * @notice RESTRICTION - All commands should have the same switchboardId.
     * @param data arbitrary data to be decoded
     * @param gasLimit gas limit for the msg
     * @param originChainId chainId where the message has to be received.
     */
    function wrapUpAtBase(
        bytes calldata data,
        uint256 gasLimit,
        uint256 originChainId,
        uint32 switchboardId
    ) external payable override {
        // Decode data into array of orders.
        bytes32[] memory commandHashes = abi.decode(data, (bytes32[]));

        // amounts array
        uint256[][] memory promisedAmounts = new uint256[][](commandHashes.length);

        unchecked {
            for (uint256 i = 0; i < commandHashes.length; i++) {
                // Get the amount send to he receiver of the command and push into array
                promisedAmounts[i] = destinationExecs[commandHashes[i]].amounts;

                // @review what to return here for exec data?
                emit CommandWrapUp(commandHashes[i], msg.sender);
            }
        }

        // Send the message to return the execution information to base.
        // Switchboard id will be same for all the orders.
        _outbound(
            switchboardId,
            uint32(originChainId),
            gasLimit,
            msg.value,
            abi.encode(commandHashes, promisedAmounts)
        );
    }

    /**
     * @dev this function can be called by commander.
     * @notice this function is used to revoke the command given.
     * @param data arbitrary data to be decoded
     * @param gasLimit gas limit to be used on the source of order where message has to be executed.
     * @param originChainId chainId of the destination where the message has to be executed.
     */
    function annulCommand(bytes calldata data, uint256 gasLimit, uint256 originChainId) external payable override {
        // Decode the data to command
        MultiOutputCommand memory command = abi.decode(data, (MultiOutputCommand));

        // Check if the msg sender is the commander.
        if (msg.sender != command.info.delegate) revert InvalidMsgSender();

        // @note : chainId check removed from here since block.chainid is hashed in hashDestinationCommand
        /// @dev an invalid hash will be generated if command is annulled on an incorrect chain
        bytes32 commandHash = command.hashDestinationCommand();

        // Check if the command is already fulfilled
        // assumes if first outputToken filled is over 0, the whole command was executed
        if (destinationExecs[commandHash].amounts.length > 0 && destinationExecs[commandHash].amounts[0] > 0)
            revert CommandAlreadyFulfilled();

        // stores commandHash in the destinationExecs mapping
        // @dev notes that the order has been cancelled
        // @review can storing outputAmount as minOutputs cause any issues
        destinationExecs[commandHash] = DestinationExec(command.outputTokens, command.minOutputs);

        // Fill in empty arrays
        bytes32[] memory commandHashes = new bytes32[](1);

        uint256[][] memory amounts = new uint256[][](0);
        commandHashes[0] = commandHash;

        // Send msg to revoke the order.
        _outbound(
            command.info.switchBoardId,
            uint32(originChainId),
            gasLimit,
            msg.value,
            abi.encode(commandHashes, amounts)
        );

        emit CommandAnnulled(commandHash);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Validates the batch has been authorised by Bungee Protocol
     * @param batch batch of MultiOutput Command Executions
     * @param sig signature of Bungee White House authorising the batch
     */
    function _validateBatch(MultiOutputBatch memory batch, bytes calldata sig) internal view {
        if (!BUNGEE_WHITELIST_REGISTRY.isBungeeApproved(batch.hashOriginBatch(), sig)) {
            revert BatchAuthenticationFailed();
        }
    }

    /**
     * @dev checks the validity of the Command
     * @notice Reverts if any of the checks below are not met.
     * @notice Returns the command hash
     * @param exec MultiOutput Command Execution details sent by soldier
     */
    function _validateExec(MultiOutputExec memory exec) internal view returns (bytes32 commandHash) {
        // Create the command hash, command hash will be recreated on the fulfillment function.
        // This hash is solely responsible for unlocking funds for the soldier after execution.
        commandHash = exec.command.hashOriginCommand();

        // @note : Command deadline check removed from here since PERMIT2 checks it as well

        // Check if the soldier promised amount is less than the output amount and revert.
        unchecked {
            for (uint256 i = 0; i < exec.command.outputTokens.length; i++) {
                if (exec.promisedOutputs[i] < exec.command.minOutputs[i]) revert MinOutputNotMet();
            }
        }
    }

    /**
     * @dev PERMIT2 verifies if the commander signed the Command and it's valid, then transfers the amount of inputToken specified in the Command to the to address
     * @param exec MultiOutput Command Execution
     * @param commandHash Hash of the command
     * @param to The address that the funds are transferred to
     */
    function _transferTokens(MultiOutputExec memory exec, bytes32 commandHash, address to) internal {
        // Permit2 Transfer From User to this contract.
        PERMIT2.permitWitnessTransferFrom(
            Permit2Lib.toPermit(
                exec.command.info.inputToken,
                exec.command.info.inputAmount,
                exec.command.info.nonce,
                exec.command.info.deadline
            ),
            Permit2Lib.transferDetails(exec.command.info.inputAmount, to),
            exec.command.info.commander,
            commandHash,
            MultiOutputCRLib.PERMIT2_ORDER_TYPE,
            exec.signature
        );
    }

    /**
     * @dev Once funds are transferred to this contract, they are locked and can be claimed by the soldier once the Command is executed on the destination chain.
     * @dev In case the command is not executed on the destination chain, the user
     * @param exec MultiOutputCommand execution details
     */
    function _execBungee(MultiOutputExec memory exec, bytes32 commandHash, address beneficiary) internal {
        // Transfer Tokens to this address.
        _transferTokens(exec, commandHash, address(this));

        // Save the Bungee Execution.
        originExecs[commandHash] = OriginExec(
            exec.command.info.commander,
            exec.command.info.inputToken,
            beneficiary,
            exec.command.info.switchBoardId,
            exec.command.info.inputAmount,
            exec.promisedOutputs,
            block.timestamp + originExecExpiry,
            exec.command.affiliateFees
        );
    }

    /**
     * @dev Once funds are transferred to this contract, they are locked and can be claimed by the soldier once the Command is executed on the destination chain.
     * @dev In case the command is not executed on the destination chain, the user
     * @param exec MultiOutputCommand execution details
     */
    function _execBungeeSwap(MultiOutputExec memory exec, bytes32 commandHash, address beneficiary) internal {
        // Transfer Tokens to this address.
        _transferTokens(exec, commandHash, address(this));

        // Swap the tokens to the suggested tokens.
        bool isNativeToken = exec.command.info.swapOutputToken == NATIVE_TOKEN_ADDRESS;

        // check balance before swap
        uint256 balanceBeforeSwap = isNativeToken
            ? address(this).balance
            : ERC20(exec.command.info.swapOutputToken).balanceOf(address(this));

        // perform swap
        // approve swapRoute
        ERC20(exec.command.info.inputToken).safeApprove(exec.swapRoute, exec.command.info.inputAmount);
        (bool success, bytes memory result) = exec.swapRoute.call(exec.swapData);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        // check balance increased by atleast minSwapOutputAmount
        uint256 diff = isNativeToken
            ? address(this).balance - balanceBeforeSwap
            : ERC20(exec.command.info.swapOutputToken).balanceOf(address(this)) - balanceBeforeSwap;
        if (diff < exec.command.info.minSwapOutput) revert InsufficientSwapOutputAmount();

        // Save the Bungee Execution.
        originExecs[commandHash] = OriginExec(
            exec.command.info.commander,
            exec.command.info.swapOutputToken,
            beneficiary,
            exec.command.info.switchBoardId,
            diff,
            exec.promisedOutputs,
            block.timestamp + originExecExpiry,
            exec.command.affiliateFees
        );
    }

    /**
     * @notice Responsible to revert the given command by the commander.
     * @param switchBoardId id of the switchboard from where the message is being received.
     * @param commandHash hash of the command that needs to be reverted.
     */
    function _revertCommand(uint32 switchBoardId, bytes32 commandHash) internal {
        // Get the origin execution of the command.
        OriginExec memory originExec = originExecs[commandHash];

        // Check if the msg is coming from the correct switchboard.
        // ! prevent zero switchboardId from being used
        if (originExec.switchBoardId != switchBoardId) revert NonSocketMessageInbound();

        // Transfer the tokens back to the commander.
        _sendFundsFromContract(originExec.inputToken, originExec.inputAmount, originExec.commander);

        delete originExecs[commandHash];
    }

    /**
     * @notice Responsible to revert the given command by the commander.
     * @param commandHash hash of the command that needs to be reverted.
     * @param amounts amounts sent to the receiver on the destination.
     */
    function _validateAndRelease(uint32 switchBoardId, bytes32 commandHash, uint256[] memory amounts) internal {
        // Get the origin execution of the command.
        OriginExec memory originExec = originExecs[commandHash];

        // Check if the msg is coming from the correct switchboard.
        // ! prevent zero switchboardId from being used
        if (originExec.switchBoardId != switchBoardId) revert NonSocketMessageInbound();

        unchecked {
            for (uint256 i = 0; i < originExec.promisedOutputs.length; i++) {
                // Check if the soldier has been released from duty already
                if (originExec.promisedOutputs[i] == 0) revert InvalidCommand();

                // Check if the soldier obeyed the command correctly
                if (originExec.promisedOutputs[i] > amounts[i]) revert PromisedAmountNotMet();
            }
        }

        // Calculate & release fees if applicable
        uint256 bridgingAmount = AffiliateFeesLib.deductAffiliateFees(
            originExec.inputToken,
            originExec.inputAmount,
            originExec.affiliateFees
        );

        // Transfer the tokens to the beneficiary
        _sendFundsFromContract(originExec.inputToken, bridgingAmount, originExec.beneficiary);

        // Delete the origin execution.
        delete originExecs[commandHash];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CONFIG
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc BaseControlRoom
     */
    function siblingControlRoom(uint256 _chainId) public view override returns (address) {
        return siblingControlRooms[_chainId];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    GETTERS
    //////////////////////////////////////////////////////////////////////////*/
    function getOriginExec(bytes32 commandHash) external view returns (OriginExec memory) {
        return originExecs[commandHash];
    }

    function getDestinationExec(bytes32 commandHash) external view returns (DestinationExec memory) {
        return destinationExecs[commandHash];
    }

    function hashOriginBatch(MultiOutputBatch memory batch) public view returns (bytes memory, bytes32, bytes memory) {
        return (abi.encode(batch), batch.hashOriginBatch(), abi.encode(batch.execs));
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {OnlyOwner, OnlyNominee} from "../base/ControlRoomErrors.sol";

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {BungeeWhitelistRegistry} from "./../whitelists/BungeeWhitelistRegistry.sol";
import {ICRCallback} from "../interfaces/ICRCallback.sol";
import {SignedBatch, CommandInfo} from "../base/ControlRoomStructs.sol";
import {ControlRoomEvents} from "../base/ControlRoomEvents.sol";
import {NoExecutionCacheFound, ExecutionCacheFailed} from "../base/ControlRoomErrors.sol";
import {ReentrancyGuard} from "solmate/src/utils/ReentrancyGuard.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IExecuteCRData} from "../interfaces/IExecuteCRData.sol";
import {ExcessivelySafeCall} from "../lib/ExcessivelySafeCall.sol";

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {RescueFundsLib} from "../lib/RescueFundsLib.sol";
import {CommandInfoLib} from "../lib/CommandInfoLib.sol";
import {TransferFailed} from "../base/ControlRoomErrors.sol";

/**
 * @notice Generic control room logic for off-chain signed commands
 *     using arbitrary methods to fulfil commands.
 * @dev This contract is implemented by control room contracts
 */
abstract contract BaseControlRoom is Ownable, ReentrancyGuard, ControlRoomEvents {
    using ExcessivelySafeCall for address;
    using SafeTransferLib for ERC20;
    using CommandInfoLib for CommandInfo;

    /// @notice Execution cache for failed execution via _callDestination()
    /// @dev Used during retries of failed executions
    struct ExecutionCache {
        address target;
        bytes encodedData;
    }

    /// @dev maximum number of bytes of returndata to copy during excessivelySafeCall
    uint16 public constant MAX_COPY_BYTES = 0;

    /// @notice address to identify the native token
    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Permit2 Contract Address.
    ISignatureTransfer public immutable PERMIT2;

    /// @notice BungeeWhitelistRegistry Contract Address
    BungeeWhitelistRegistry public immutable BUNGEE_WHITELIST_REGISTRY;

    /// @notice flag used to pause contract
    bool public isPaused = false;

    /// @notice Command fulfillment deadline for the soldier once funds are transferred from user
    /// @dev Seconds added to block.timestamp after which OriginExec for commandHash will expire
    uint256 public originExecExpiry = 1 days;

    /// @notice execution cache for failed execution
    mapping(bytes32 commandHash => ExecutionCache) internal executionCache;

    /**
     * @notice Constructor.
     * @param _permit2Address address of the permit 2 contract.
     * @param _bungeeWhitelistRegistry address of the BungeeWhitelistRegistry contract.
     * @param _originExecExpiry Command fulfillment deadline for the soldier once funds are transferred from user
     */
    constructor(address _permit2Address, address _bungeeWhitelistRegistry, uint256 _originExecExpiry) {
        PERMIT2 = ISignatureTransfer(_permit2Address);
        BUNGEE_WHITELIST_REGISTRY = BungeeWhitelistRegistry(_bungeeWhitelistRegistry);
        originExecExpiry = _originExecExpiry;
    }

    // TODO - I think we can directly make runCommands external and virtual
    // NOTE - I think executeBatch and executeBatchWithCallback can be removed.

    /**
     * @notice Executes batch of commands
     * @dev Called by a soldier at source chain to execute a batch of commands from commander
     * @dev Signed command batch contains the signature on the batch by the Bungee White House.
     * @dev When a command is given, soldiers compete to execute the given command in the most efficient way.
     * @dev Bungee White house looks at the commands and assigns it to the best execution provided by the soldiers.
     * @param batch the batch of commands signed by the Bungee White House.
     */
    function executeBatch(SignedBatch calldata batch) external payable nonReentrant {
        engageCommands(batch);
    }

    /**
     * @notice executes the batch and then calls back caller soldier with callbackData
     * @param batch Signed command batch contains the signature on the batch by the Bungee White House.
     * @param callbackData The callbackData to pass to the callback
     */
    function executeBatchWithCallback(
        SignedBatch calldata batch,
        bytes calldata callbackData
    ) external payable nonReentrant {
        engageCommands(batch);
        ICRCallback(msg.sender).callback(callbackData);
    }

    /**
     * @notice Run the commands given by the commanders.
     * @dev Signed command batch contains the signature on the batch by the Bungee White House.
     * @dev When a command is given, soldiers compete to execute the given command in the most efficient way.
     * @dev Bungee White house looks at the commands and assigns it to the best execution provided by the soldiers.
     * @param batch the batch of commands signed by the Bungee White House.
     */
    function engageCommands(SignedBatch calldata batch) internal virtual;

    /**
     * @notice Fulfill a batch of commands given by the commander
     * @dev Called by the soldier on the destination chain to fulfill the commands they engaged on the source chain
     * @dev Command batch contains encoded array of Commands
     * @dev Once soldier engages command on the source chain, they need to obey the command to fulfill it on the destination chain via this method
     * @param batch Batch of encoded Commands to be fulfilled by soldier
     */
    function obeyCommands(bytes calldata batch) external payable virtual;

    /**
     * @dev this function can be called by commander on the destination chain to in turn revoke on source chain
     * @notice this function is used to revoke the command given.
     * @param data encoded data to be decoded into the command.
     * @param gasLimit gas limit to be used on the source of order where message has to be executed.
     * @param originChainId chainId of the destination where the message has to be executed.
     */
    function annulCommand(bytes calldata data, uint256 gasLimit, uint256 originChainId) external payable virtual;

    /**
     * @dev this function can be called by commander on source chain to revoke command after fulfill deadline has passed
     * @param commandHash hash of the command
     */
    function lapseCommand(bytes32 commandHash) external payable virtual;

    /**
     * @dev Responsible for going back to source chain and informing that the command is executed on destination
     * @param data arbitrary data to be decoded
     * @param gasLimit gas limit for the msg
     * @param originChainId chainId where the message has to be received.
     * @param switchboardId switchboardId to send the DL message via
     */
    function wrapUpAtBase(
        bytes calldata data,
        uint256 gasLimit,
        uint256 originChainId,
        uint32 switchboardId
    ) external payable virtual;

    /**
     * @dev Responsible for unlocking funds to the beneficiary if the conditions suffice.
     * @param switchBoardId array of commands.
     * @param payload gas limit for the msg
     */
    function inboundMsg(uint32 switchBoardId, bytes calldata payload) external payable virtual;

    /**
     * @dev this function can be called by SwitchboardPlug
     * @notice this function can be used to fetch corresponding control room on the sibling chain.
     * @param _chainId chainId of the sibling chain.
     */
    function siblingControlRoom(uint256 _chainId) public view virtual returns (address);

    /**
     * @dev call receiver with the data provided in the command.
     * @param to address to call
     * @param msgGaslimit gas limit for the execution.
     * @param amounts outputs that are received.
     * @param outputTokens address of the tokens received.
     * @param commandHash hash of the command.
     * @param data data to call the address.
     */
    function _callDestination(
        address to,
        uint256 msgGaslimit,
        uint256[] memory amounts,
        address[] memory outputTokens,
        bytes32 commandHash,
        bytes memory data
    ) internal {
        // return true if empty
        if (data.length == 0) return;

        // Check and return with no action
        if (to == address(0)) return;
        if (to == address(this)) return;

        bytes memory encodedData = abi.encode(
            IExecuteCRData.executeData.selector,
            amounts,
            commandHash,
            outputTokens,
            data
        );

        // Call the external contract with calldata
        (bool success, ) = to.excessivelySafeCall(msgGaslimit, MAX_COPY_BYTES, encodedData);

        if (!success) {
            executionCache[commandHash] = ExecutionCache({target: to, encodedData: encodedData});
            emit ExecutionCached(commandHash);
        }
    }

    /**
     * @dev this function can be called by anyone.
     * @notice can be called by anyone to execute the failed execution against the commandhash
     * @param commandHash arbitrary data to be decoded
     */
    function executeCachedData(bytes32 commandHash) external {
        // Get the execution cache for the commandhash
        ExecutionCache memory cache = executionCache[commandHash];

        // Check if the data is correct.
        if (cache.target == address(0)) revert NoExecutionCacheFound();

        // Call the data with gas left
        // TODO - What happens to value if called.
        (bool success, ) = cache.target.excessivelySafeCall(gasleft(), MAX_COPY_BYTES, cache.encodedData);

        // revert if call fails
        if (!success) revert ExecutionCacheFailed();

        // Delete the cache.
        delete executionCache[commandHash];
    }

    /**
     * @dev send funds to the provided address.
     * @param token address of the token
     * @param from atomic execution.
     * @param amount hash of the command.
     * @param to address, funds will be transferred to this address.
     */
    function _sendFundsToReceiver(address token, address from, uint256 amount, address to) internal {
        /// native token case
        if (token == NATIVE_TOKEN_ADDRESS) {
            (bool success, ) = to.call{value: amount, gas: 5000}("");
            if (!success) revert TransferFailed();
            return;
        }
        /// ERC20 case
        ERC20(token).safeTransferFrom(from, to, amount);
    }

    /**
     * @dev send funds to the provided address.
     * @param token address of the token
     * @param amount hash of the command.
     * @param to address, funds will be transferred to this address.
     */
    function _sendFundsFromContract(address token, uint256 amount, address to) internal {
        /// native token case
        if (token == NATIVE_TOKEN_ADDRESS) {
            (bool success, ) = to.call{value: amount, gas: 5000}("");
            if (!success) revert TransferFailed();
            return;
        }
        /// ERC20 case
        ERC20(token).safeTransfer(to, amount);
    }

    // ---------------------------------------- SOCKET DATA LAYER FUNCTIONS ---------------------------------------- //

    /**
     * @notice Function to send the message through socket data layer to the destination chain.
     * @param switchBoardId switchboard id represents the switchboard by which the message is being sent.
     * @param targetChain_ the destination chain slug to send the message to.
     * @param minMsgGasLimit_ gasLimit to use to execute the message on the destination chain.
     * @param msgValue socket data layer fees to send a message.
     * @param payload_ payload is the encoded message that the inbound will receive.
     */
    function _outbound(
        uint32 switchBoardId,
        uint32 targetChain_,
        uint256 minMsgGasLimit_,
        uint256 msgValue,
        bytes memory payload_
    ) internal {
        // Call the switchboard to send the message to the destination chain.
        BUNGEE_WHITELIST_REGISTRY.switchBoardPlugsMap(switchBoardId).outbound{value: msgValue}(
            targetChain_,
            minMsgGasLimit_,
            payload_
        );
    }

    // ---------------------------------------------- ADMIN FUNCTION ---------------------------------------------- //

    /**
     * @notice Sets the originExecExpiry value which determines the order fulfilment deadline
     * @param deadline deadline value in seconds
     */
    function setOriginExecExpiry(uint256 deadline) public virtual onlyOwner {
        originExecExpiry = deadline;
    }

    /**
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(address token_, address rescueTo_, uint256 amount_) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }

    /**
     * @notice Set the isPaused variable.
     * @dev if the isPaused variable is true no money should move in or out of the contract.
     * @param _isPaused boolean to pause or unpause the contract.
     */
    function setContractPause(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";

/**
 * @notice Generic access control contract for Control Rooms
 *         Stores & validates corresponding Control Room addresses on sibling chains
 * @dev To be inherited by corresponding Control Rooms on each chain to restrict message passing
 */
abstract contract ControlRoomAccessControl is Ownable {
    /// @notice Mapping of sibling chain id to corresponding Control Room address
    /// @dev used to validate the inbound message from sibling chain
    mapping(uint256 chainId => address controlRoom) internal siblingControlRooms;

    /// @notice Emitted when a new control room is added
    /// @param chainId sibling chain id
    /// @param controlRoom address of the control room
    event ControlRoomAdded(uint256 indexed chainId, address controlRoom);

    /// @notice Emitted when a control room is removed
    /// @param chainId sibling chain id
    /// @param controlRoom address of the control room
    event ControlRoomRemoved(uint256 indexed chainId, address controlRoom);

    /**
     * @notice Add a sibling control room address
     * @param _chainId sibling chain id
     * @param _controlRoom address of the control room
     */
    function addControlRoom(uint256 _chainId, address _controlRoom) external onlyOwner {
        siblingControlRooms[_chainId] = _controlRoom;
        emit ControlRoomAdded(_chainId, _controlRoom);
    }

    /**
     * @notice Remove a sibling control room address
     * @param _chainId sibling chain id
     */
    function removeControlRoom(uint256 _chainId) external onlyOwner {
        address _controlRoom = siblingControlRooms[_chainId];
        delete siblingControlRooms[_chainId];
        emit ControlRoomRemoved(_chainId, _controlRoom);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";

// Library to get Permit 2 related data.
library Permit2Lib {
    string public constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";

    function toPermit(
        address inputToken,
        uint256 inputAmount,
        uint256 nonce,
        uint256 deadline
    ) internal pure returns (ISignatureTransfer.PermitTransferFrom memory) {
        return
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({token: inputToken, amount: inputAmount}),
                nonce: nonce,
                deadline: deadline
            });
    }

    function transferDetails(
        uint256 amount,
        address spender
    ) internal pure returns (ISignatureTransfer.SignatureTransferDetails memory) {
        return ISignatureTransfer.SignatureTransferDetails({to: spender, requestedAmount: amount});
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {ERC20, SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {BytesLib} from "./BytesLib.sol";

/// @notice helpers for AffiliateFees struct
library AffiliateFeesLib {
    /// @notice SafeTransferLib - library for safe and optimized operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice error when affiliate fee length is wrong
    error WrongAffiliateFeeLength();

    /// @notice event emitted when affiliate fee is deducted
    event AffiliateFeeDeducted(address feeToken, address feeTakerAddress, uint256 feeAmount);

    // Precision used for affiliate fee calculation
    uint256 internal constant PRECISION = 10000000000000000;

    /**
     * @dev calculates & transfers fee to feeTakerAddress
     * @param feeToken address of the token to be used for fee
     * @param bridgingAmount amount to be bridged
     * @param affiliateFees packed bytes containing feeTakerAddress and feeInBps
     *                      ensure the affiliateFees is packed as follows:
     *                      address feeTakerAddress (20 bytes) + uint48 feeInBps (6 bytes) = 26 bytes
     * @return bridgingAmount after deducting affiliate fees
     */
    function deductAffiliateFees(
        address feeToken,
        uint256 bridgingAmount,
        bytes memory affiliateFees
    ) internal returns (uint256) {
        if (affiliateFees.length > 0) {
            address feeTakerAddress;
            uint48 feeInBps;

            if (affiliateFees.length != 26) revert WrongAffiliateFeeLength();

            feeInBps = BytesLib.toUint48(affiliateFees, 20);
            feeTakerAddress = BytesLib.toAddress(affiliateFees, 0);

            if (feeInBps > 0) {
                // calculate fee
                uint256 feeAmount = ((bridgingAmount * feeInBps) / PRECISION);
                bridgingAmount -= feeAmount;

                // transfer fee to feeTaker
                ERC20(feeToken).safeTransfer(feeTakerAddress, feeAmount);

                // Emits fee deducted event
                emit AffiliateFeeDeducted(feeToken, feeTakerAddress, feeAmount);
            }
        }

        return bridgingAmount;
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/// @dev generic basic info needed when the user places the command.
struct CommandInfo {
    // The address of the commander who is placing the order.
    // Note that this must be included so that order hashes are unique by commander.
    address commander;
    // Id of the switchboard to be used.
    uint32 switchBoardId;
    // The address of the commander who is placing the order.
    // Note that this must be included so that order hashes are unique by commander.
    address receiver;
    // The address of the control room where the command has to reach.
    // Note that this must be included in every order so that the commander
    // signature can commit to the specific control room they trust to fulfill their command.
    address controlRoom;
    // Address that will be able to annulCommand on the destination chain
    address delegate;
    // The address of the input token on the origin domain.
    address inputToken;
    // address of the desired swap output token if swap is involved.
    // Can be the same as the output token if no swap involved.
    address swapOutputToken;
    // The amount of tokens that are needed from the commander to satisy the command.
    uint256 inputAmount;
    // the minimum expected swqap output if swap is involved.
    // Can be the same as min output if not swap is involved.
    uint256 minSwapOutput;
    // The nonce of the command to protect from replay.
    uint256 nonce;
    // The timestamp after which the command is no longer valid.
    uint256 deadline;
    // The id of the origin domain.
    uint256 originChainId;
    // The id of the destination domain.
    uint256 destinationChainId;
}

/// @notice external struct including a generic encoded batch and the signature
///     of the Bungee White House.
/// @dev This batch of instruction will
struct SignedBatch {
    bytes batch;
    bytes sig;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {CommandInfo} from "../base/ControlRoomStructs.sol";
import {CommandInfoLib} from "./CommandInfoLib.sol";
import {Permit2Lib} from "./Permit2Lib.sol";

/// @notice Struct for commands with multiple output tokens on the destination
/// @dev This struct will be signed by the commander as PERMIT2 witness data
struct MultiOutputCommand {
    // generic command info
    CommandInfo info;
    // addresses of the output tokens
    address[] outputTokens;
    // the minimum expected output token amounts to the receiver on destination chain
    uint256[] minOutputs;
    // gasLimit for calldata execution
    uint256 minDstGasLimit;
    // metadata for integrators
    bytes32 metadata;
    // Affiliate fees info
    bytes affiliateFees;
    // data in bytes for calldata execution
    bytes dstData;
}

/// @notice This is the struct that the soldier will use as instruction
///     and promises an output against the command.
/// @dev if the promised amount is 0, it will be assumed that an
///     external party will be fulfilling a command.
struct MultiOutputExec {
    // Command to be executed.
    MultiOutputCommand command;
    // promised outputs of the command by the soldier to Bungee White House.
    uint256[] promisedOutputs;
    // address of the swap router to be used. Address 0 can be used if no swap involved.
    address swapRoute;
    // data to be sent to swap router to perform the swap
    bytes swapData;
    // signature of the commander
    bytes signature;
}

struct MultiOutputBatch {
    // Batch of executions to follow
    MultiOutputExec[] execs;
    // Address of the soldier who will receive the locked funds for obeying commands
    address beneficiary;
}

/// @title Multi Output Control Room (MOCR) Library
/// @author bungee-dev
/// @notice The Multi Output Control Room library is the helper for creating order hashes and batchhashes for
///     a multi output object type. The multi output object is when there are multiple output tokens
///     in the command.
/// @dev This library would mainly contain the Multi Command Object and the
///     corresponding hashing functions with it.
library MultiOutputCRLib {
    /// Libs
    using CommandInfoLib for CommandInfo;

    // Permit 2 Witness Order Type.
    string internal constant PERMIT2_ORDER_TYPE =
        string(
            abi.encodePacked(
                "MultiOutputCommand witness)",
                abi.encodePacked(CommandInfoLib.COMMAND_INFO_TYPE, MULTI_OUTPUT_COMMAND_TYPE),
                Permit2Lib.TOKEN_PERMISSIONS_TYPE
            )
        );

    // SingleOutputExec Type
    bytes internal constant MULTI_OUTPUT_COMMAND_TYPE =
        abi.encodePacked(
            "MultiOutputCommand(",
            "CommandInfo info,",
            "address[] outputTokens,",
            "address[] minOutputs,",
            "uint256 minDstGasLimit,",
            "bytes32 metadata,",
            "bytes affiliateFees",
            "bytes dstData)"
        );

    // Single Output Exec Type.
    bytes internal constant MULTI_OUTPUT_EXEC_TYPE =
        abi.encodePacked(
            "MultiOutputExec(",
            "MultiOutputCommand command,",
            "uint256[] promisedOutputs,",
            "address swapRoute,",
            "bytes swapData,",
            "bytes signature)"
        );

    // Command Type.
    bytes internal constant COMMAND_TYPE =
        abi.encodePacked(MULTI_OUTPUT_COMMAND_TYPE, CommandInfoLib.COMMAND_INFO_TYPE);

    // Keccak Hash of Command Type.
    bytes32 internal constant COMMAND_TYPE_HASH = keccak256(COMMAND_TYPE);

    // Exec Type.
    bytes internal constant EXEC_TYPE = abi.encodePacked(MULTI_OUTPUT_EXEC_TYPE, MULTI_OUTPUT_COMMAND_TYPE);

    // Keccak Hash of Exec Type.
    bytes32 internal constant EXEC_TYPE_HASH = keccak256(EXEC_TYPE);

    /// @notice Hash of MultiOutputCommand on the origin chain
    /// @param command command that is issued by the commander
    function hashOriginCommand(MultiOutputCommand memory command) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    COMMAND_TYPE_HASH,
                    command.info.originHash(),
                    keccak256(abi.encodePacked(command.outputTokens)),
                    keccak256(abi.encodePacked(command.minOutputs)),
                    command.minDstGasLimit,
                    command.metadata,
                    keccak256(command.affiliateFees),
                    keccak256(command.dstData)
                )
            );
    }

    /// @notice Hash of MultiOutputCommand on the destination chain
    /// @param command command that is issued by the commander
    function hashDestinationCommand(MultiOutputCommand memory command) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    COMMAND_TYPE_HASH,
                    command.info.destinationHash(),
                    keccak256(abi.encodePacked(command.outputTokens)),
                    keccak256(abi.encodePacked(command.minOutputs)),
                    command.minDstGasLimit,
                    command.metadata,
                    keccak256(command.affiliateFees),
                    keccak256(command.dstData)
                )
            );
    }

    /// @notice Hash of MultiOutputExec on the origin chain
    /// @param execution MultiOutputExec sent by the soldier to be hashed
    function hashOriginExec(MultiOutputExec memory execution) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EXEC_TYPE_HASH,
                    hashOriginCommand(execution.command),
                    keccak256(abi.encodePacked(execution.promisedOutputs)),
                    execution.swapRoute,
                    keccak256(execution.swapData),
                    keccak256(execution.signature)
                )
            );
    }

    /// @notice hashes batch of MultiOutputBatch
    /// @param batch batch of MultiOutputBatch
    function hashOriginBatch(MultiOutputBatch memory batch) internal view returns (bytes32) {
        unchecked {
            bytes32 outputHash = keccak256(
                "MultiOutputExec(MultiOutputCommand command,uint256[] promisedOutputs,address swapRoute,bytes swapData,bytes signature)"
            );
            for (uint256 i = 0; i < batch.execs.length; i++) {
                outputHash = keccak256(abi.encode(outputHash, hashOriginExec(batch.execs[i])));
            }

            return outputHash;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error BatchAuthenticationFailed();
error DeadlineNotMet();
error MinOutputNotMet();
error CommandAlreadyFulfilled();
error PromisedAmountNotMet();
error InvalidCommand();
error NonSocketMessageInbound();
error InvalidMsgSender();
error FulfillDeadlineNotMet();
error FulfillmentChainInvalid();
error AddressZero();
error NoExecutionCacheFound();
error ExecutionCacheFailed();
error InsufficientSwapOutputAmount();

error OnlyOwner();
error OnlyNominee();
error UnsupportedMethod();
error InvalidOrder();
error TransferFailed();
error DestinationChainInvalid();

/// RemoteCommandRoom
error ZeroAddressInvalid();
error IncorrectControlRoom();
error InvalidNonce();
error OriginChainIdInvalid();
error CommandAlreadyExecuted();
error RemoteCommandDoesNotExist();

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";
import {SwitchBoardPlug} from "../base/SwitchboardPlug.sol";
import {AuthenticationLib} from "../lib/AuthenticationLib.sol";

/**
 * @title BungeeWhitelistRegistry
 * @author Bungee
 * @notice Whitelist & Registry contract that can be reused by Control Rooms
 * @dev As a registry, it tracks Switchboard Ids and their corresponding SwitchboardPlugs
 * @dev As a whitelist, it handles all Bungee signer address whitelist
 */
contract BungeeWhitelistRegistry is Ownable {
    /// @notice Bungee signer that signs against the order thats submitted.
    mapping(address => bool) internal bungeeSigners;

    /// @notice store switch board plugs
    mapping(uint32 switchboardId => SwitchBoardPlug switchBoardPlug) public switchBoardPlugsMap;

    constructor(address _owner) Ownable(_owner) {}

    // --------------------------------------- BUNGEE SIGNER ADMIN FUNCTIONS --------------------------------------- //

    /**
     * @notice Set Signer Addresses.
     * @param _signerAddress address that can sign against a batch.
     */
    function addSignerAddress(address _signerAddress) external onlyOwner {
        bungeeSigners[_signerAddress] = true;
    }

    /**
     * @notice Disable Signer Address.
     * @param _signerAddress address that can sign against a batch.
     */
    function disableSignerAddress(address _signerAddress) external onlyOwner {
        bungeeSigners[_signerAddress] = false;
    }

    // --------------------------------------- BUNGEE SIGNER VIEW FUNCTIONS --------------------------------------- //

    /**
     * @notice Check if an messageHash has been approved by Bungee
     * @param _messageHash messageHash that has been signed by a Bungee signer
     * @param _sig is the signature produced by Bungee signer
     */
    function isBungeeApproved(bytes32 _messageHash, bytes calldata _sig) public view returns (bool) {
        return bungeeSigners[AuthenticationLib.authenticate(_messageHash, _sig)];
    }

    /**
     * @notice Check if an address is a Bungee permitted signer address.
     * @param _signerAddress address that can sign against a batch.
     */
    function isSigner(address _signerAddress) public view returns (bool) {
        return bungeeSigners[_signerAddress];
    }

    // ---------------------------------- SWITCHBOARDPLUG REGISTRY ADMIN FUNCTIONS ---------------------------------- //

    /**
     * @notice Sets a switchboard address against the given id.
     * @param switchBoardId id of the switchboard.
     * @param switchBoardAddress The address of the switchboard through which message will be sent.
     */
    function setSwitchBoardMap(uint32 switchBoardId, address switchBoardAddress) external onlyOwner {
        switchBoardPlugsMap[switchBoardId] = SwitchBoardPlug(switchBoardAddress);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

/// @notice Callback for running commands through the control room.
interface ICRCallback {
    /// @notice Called by the control room during running the command.
    /// @param callbackData The callbackData specified for a command run
    function callback(bytes calldata callbackData) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @notice Standard events for control rooms
interface ControlRoomEvents {
    /// @notice Emitted when a command is executed via a control room
    /// @param commandHash hash of the command
    /// @param executor address of the executor
    /// @param execution encoded execution data
    event CommandExecuted(bytes32 indexed commandHash, address indexed executor, bytes execution);

    /// @notice Emitted when a command is fulfilled via a control room
    /// @param commandHash hash of the command
    /// @param fulfiller address of the fulfiller
    /// @param execution encoded execution data
    event CommandFulfilled(bytes32 indexed commandHash, address indexed fulfiller, bytes execution);

    /// @notice Emitted when a command is annulled by a commander via a control room
    /// @param commandHash hash of the command
    event CommandAnnulled(bytes32 indexed commandHash);

    /// @notice Emitted when a command is lapsed after deadline via a control room
    /// @param commandHash hash of the command
    event CommandLapsed(bytes32 indexed commandHash);

    /// @notice Emitted when a command is wrapped & acknowledged back to src chain after fulfillment
    /// @param commandHash hash of the command
    /// @param executor address of the executor
    event CommandWrapUp(bytes32 indexed commandHash, address indexed executor);

    /// @notice Emitted when a wrap up inbound is received in the control room
    /// @param commandHash hash of the command
    /// @param inboundData encoded inbound data
    event CommandInbound(bytes32 indexed commandHash, bytes inboundData);

    /// @notice Emitted when an execution fails.
    /// @param commandHash hash of the command
    event ExecutionCached(bytes32 commandHash);
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

interface IExecuteCRData {
    function executeData(
        uint256[] calldata amounts,
        bytes32 commandHash,
        address[] calldata tokens,
        bytes memory callData
    ) external payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.17;

/// @title ExcessivelySafeCall from https://github.com/nomad-xyz/ExcessivelySafeCall
/// @dev Modified to remove msg.value transfers
library ExcessivelySafeCall {
    uint constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

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
    function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEIP712} from "./IEIP712.sol";

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer is IEIP712 {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {ERC20, SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

error ZeroAddress();

/**
 * @title RescueFundsLib
 * @dev A library that provides a function to rescue funds from a contract.
 */

library RescueFundsLib {
    /**
     * @dev The address used to identify ETH.
     */
    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

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
    function rescueFunds(address token_, address rescueTo_, uint256 amount_) internal {
        if (rescueTo_ == address(0)) revert ZeroAddress();

        if (token_ == ETH_ADDRESS) {
            SafeTransferLib.safeTransferETH(rescueTo_, amount_);
        } else {
            if (token_.code.length == 0) revert InvalidTokenAddress();
            SafeTransferLib.safeTransfer(ERC20(token_), rescueTo_, amount_);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {CommandInfo} from "../base/ControlRoomStructs.sol";

/// @notice helpers for handling CommandInfo objects
library CommandInfoLib {
    bytes internal constant COMMAND_INFO_TYPE =
        "CommandInfo(address commander,uint32 switchBoardId,address receiver,address controlRoom,address delegate,address inputToken,address swapOutputToken,uint256 inputAmount,uint256 minSwapOutput,uint256 nonce,uint256 deadline,uint256 originChainId,uint256 destinationChainId)";
    bytes32 internal constant COMMAND_INFO_TYPE_HASH = keccak256(COMMAND_INFO_TYPE);

    /// @notice Hash of CommandInfo struct on the origin chain
    /// @param info CommandInfo object to be hashed
    function originHash(CommandInfo memory info) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    COMMAND_INFO_TYPE_HASH,
                    info.commander,
                    info.switchBoardId,
                    info.receiver,
                    info.controlRoom,
                    info.delegate,
                    info.inputToken,
                    info.swapOutputToken,
                    info.inputAmount,
                    info.minSwapOutput,
                    info.nonce,
                    info.deadline,
                    block.chainid,
                    info.destinationChainId
                )
            );
    }

    /// @notice Hash of CommandInfo struct on the destination chain
    /// @param info CommandInfo object to be hashed
    function destinationHash(CommandInfo memory info) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    COMMAND_INFO_TYPE_HASH,
                    info.commander,
                    info.switchBoardId,
                    info.receiver,
                    info.controlRoom,
                    info.delegate,
                    info.inputToken,
                    info.swapOutputToken,
                    info.inputAmount,
                    info.minSwapOutput,
                    info.nonce,
                    info.deadline,
                    info.originChainId,
                    block.chainid
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.4 <0.9.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint48(bytes memory _bytes, uint256 _start) internal pure returns (uint48) {
        require(_bytes.length >= _start + 6, "toUint48_outOfBounds");
        uint48 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x6), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equal_nonAligned(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let endMinusWord := add(_preBytes, length)
                let mc := add(_preBytes, 0x20)
                let cc := add(_postBytes, 0x20)

                for {
                    // the next line is the loop condition:
                    // while(uint256(mc < endWord) + cb == 2)
                } eq(add(lt(mc, endMinusWord), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }

                // Only if still successful
                // For <1 word tail bytes
                if gt(success, 0) {
                    // Get the remainder of length/32
                    // length % 32 = AND(length, 32 - 1)
                    let numTailBytes := and(length, 0x1f)
                    let mcRem := mload(mc)
                    let ccRem := mload(cc)
                    for {
                        let i := 0
                        // the next line is the loop condition:
                        // while(uint256(i < numTailBytes) + cb == 2)
                    } eq(add(lt(i, numTailBytes), cb), 2) {
                        i := add(i, 1)
                    } {
                        if iszero(eq(byte(i, mcRem), byte(i, ccRem))) {
                            // unsuccess:
                            success := 0
                            cb := 0
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {ISocket} from "./../interfaces/ISocket.sol";
import {IPlug} from "./../interfaces/IPlug.sol";
import {IControlRoom} from "./../interfaces/IControlRoom.sol";

import {Ownable} from "../utils/Ownable.sol";

/**
 * @notice Switchboard Plug sends the message from the control room to
 *   the corresponding control room through socket DL.
 */
contract SwitchBoardPlug is IPlug, Ownable {
    /// @notice Switchboard id corresponding to this SwitchboardPlug
    uint32 internal switchBoardId;

    /// @notice Socket DL contract
    ISocket public immutable SOCKET;

    /// @notice Thrown when caller is not Socket contract
    error NotSocket();

    /// @notice Thrown when the inbound message tries to call invalid control room
    error InvalidInbound();

    /**
     * @dev  Initialize socket and switchboard id
     * @param _socket address of the socket data layer contract.
     * @param _switchBoardId switchboard id corresponding to this SwitchboardPlug.
     */
    constructor(address _socket, uint32 _switchBoardId, address _owner) Ownable(_owner) {
        SOCKET = ISocket(_socket);
        switchBoardId = _switchBoardId;
    }

    /**
     * @notice Function to send the message through socket data layer to the destination chain.
     * @param siblingChainSlug the destination chain slug to send the message to.
     * @param msgGasLimit gasLimit to use to execute the message on the destination chain.
     * @param payload payload is the encoded message that the inbound will receive.
     */
    function outbound(uint32 siblingChainSlug, uint256 msgGasLimit, bytes memory payload) external payable {
        // TODO - How do we validate that this can only be called by Control rooms.
        // I can spoof an outbound with false data to unlock funds.

        // encode sender dst & recipient src ControlRoom addresses along with payload
        payload = encodeOutboundPayload(siblingChainSlug, payload);

        SOCKET.outbound{value: msg.value}(siblingChainSlug, msgGasLimit, bytes32(0), bytes32(0), payload);
    }

    /**
     * @notice Message received from socket DL to unlock user funds.
     * @notice Message has to be received before an orders fulfillment deadline.
     *         Solver will not unlock user funds after this deadline.
     * @param payload payload to be executed.
     */
    function inbound(uint32 siblingChainSlug_, bytes calldata payload) external payable {
        if (msg.sender != address(SOCKET)) revert NotSocket();

        (address dstControlRoom, address srcControlRoom, bytes memory controlRoomPayload) = decodeInboundPayload(
            payload
        );

        validateSiblingControlRoom(dstControlRoom, srcControlRoom, siblingChainSlug_);

        IControlRoom(srcControlRoom).inboundMsg(switchBoardId, controlRoomPayload);
    }

    /**
     * @notice Connects the plug to the sibling chain via Socket DL
     * @param remoteChainSlug sibling chain slug
     * @param remotePlug address of plug present at sibling chain to send & receive messages
     * @param inboundSwitchboard address of switchboard to use for receiving messages
     * @param outboundSwitchboard address of switchboard to use for sending messages
     */
    function connect(
        uint32 remoteChainSlug,
        address remotePlug,
        address inboundSwitchboard,
        address outboundSwitchboard
    ) external onlyOwner {
        SOCKET.connect(remoteChainSlug, remotePlug, inboundSwitchboard, outboundSwitchboard);
    }

    /**
     * @notice Encodes an outbound payload.
     * @dev encodes sender dst & recipient src ControlRoom addresses along with payload
     * @param siblingChainSlug the destination chain slug to send the message to.
     * @param payload payload is the encoded message that control room is sending
     * @return encoded payload.
     */
    function encodeOutboundPayload(uint32 siblingChainSlug, bytes memory payload) public view returns (bytes memory) {
        return abi.encode(msg.sender, IControlRoom(msg.sender).siblingControlRoom(siblingChainSlug), payload);
    }

    /**
     * @notice Decodes an inbound payload.
     * @dev decodes sender dst & recipient src ControlRoom addresses along with payload
     * @param payload payload is the encoded message that the inbound will receive.
     * @return dstControlRoom, srcControlRoom, controlRoomPayload.
     */
    function decodeInboundPayload(bytes memory payload) public pure returns (address, address, bytes memory) {
        (address dstControlRoom, address srcControlRoom, bytes memory controlRoomPayload) = abi.decode(
            payload,
            (address, address, bytes)
        );

        return (dstControlRoom, srcControlRoom, controlRoomPayload);
    }

    /**
     * @notice Validates the sibling control room address.
     * @dev Queries src control room to check if the sibling control room address is valid.
     * @param dstControlRoom destination control room address.
     * @param srcControlRoom source control room address.
     * @param siblingChainSlug_ the sibling chain slug.
     */
    function validateSiblingControlRoom(
        address dstControlRoom,
        address srcControlRoom,
        uint32 siblingChainSlug_
    ) public view {
        if (IControlRoom(srcControlRoom).siblingControlRoom(siblingChainSlug_) != dstControlRoom)
            revert InvalidInbound();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Library to authenticate the signer address.
library AuthenticationLib {
    /// @notice authenticate a message hash signed by Bungee Protocol
    /// @param messageHash hash of the message
    /// @param signature signature of the message
    /// @return true if signature is valid
    function authenticate(bytes32 messageHash, bytes memory signature) internal pure returns (address) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature);
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

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

    event PlugConnected(
        address plug,
        uint32 siblingChainSlug,
        address siblingPlug,
        address inboundSwitchboard,
        address outboundSwitchboard,
        address capacitor,
        address decapacitor
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @title IPlug
 * @notice Interface for a plug contract that executes the message received from a source chain.
 */
interface IPlug {
    /**
     * @dev this should be only executable by Socket DL
     * @notice executes the message received from source chain
     * @notice It is expected to have original sender checks in the destination plugs using payload
     * @param srcChainSlug_ chain slug of source
     * @param payload_ the data which is needed by plug at inbound call on remote
     */
    function inbound(uint32 srcChainSlug_, bytes calldata payload_) external payable;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @notice Interface for the control room contract
 * @dev Included functions to send inbound message & fetch sibling control room
 */
interface IControlRoom {
    /**
     * @notice Function to send the message from the socket data layer to the control room.
     * @param switchBoardId id of switchboard to be used
     * @param payload encoded message from the socket data layer
     */
    function inboundMsg(uint32 switchBoardId, bytes calldata payload) external;

    /**
     * @notice Function to fetch the sibling control room address.
     * @param _chainId chainId of the sibling chain.
     */
    function siblingControlRoom(uint256 _chainId) external view returns (address);
}