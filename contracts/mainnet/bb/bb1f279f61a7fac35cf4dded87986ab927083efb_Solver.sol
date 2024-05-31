// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";
import {RescueFundsLib} from "../lib/RescueFundsLib.sol";
import {ERC20, SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {BaseControlRoom} from "./../control-rooms/BaseControlRoom.sol";
import {AuthenticationLib} from "./../lib/AuthenticationLib.sol";

contract Solver is Ownable {
    using SafeTransferLib for ERC20;

    struct Approval {
        ERC20 token;
        address spender;
        uint256 amount;
    }

    struct Action {
        Approval[] approvals;
        address target;
        uint256 value;
        bytes data;
    }

    struct Fulfillment {
        Approval[] approvals;
        BaseControlRoom controlRoom;
        uint256 value;
        bytes batch;
    }

    error ActionFailed(uint256 index);
    error FulfillmentFailed();
    error InvalidSigner();
    error InvalidNonce();

    /// @notice address of the signer
    address internal immutable SOLVER_SIGNER;

    /// @notice mapping to track used nonces of SOLVER_SIGNER
    mapping(uint256 => bool) public nonceUsed;

    /**
     * @notice Constructor.
     * @param _owner address of the contract owner
     * @param _solverSigner address of the signer
     */
    constructor(address _owner, address _solverSigner) Ownable(_owner) {
        SOLVER_SIGNER = _solverSigner;
    }

    function performActionsAndFulfill(
        Action[] calldata actions,
        Fulfillment calldata fulfillment,
        uint256 nonce,
        bytes calldata signature
    ) external {
        verifySignature(hash(nonce, actions, fulfillment), signature);
        _useNonce(nonce);

        if (actions.length > 0) {
            _performActions(actions);
        }

        _fulfill(fulfillment);
    }

    function performActions(Action[] calldata actions, uint256 nonce, bytes calldata signature) external {
        verifySignature(hash(nonce, actions), signature);
        _useNonce(nonce);

        _performActions(actions);
    }

    function _performActions(Action[] calldata actions) internal {
        for (uint256 i = 0; i < actions.length; i++) {
            Action memory action = actions[i];

            if (action.approvals.length > 0) _setApprovals(action.approvals);

            (bool success, ) = action.target.call{value: action.value}(action.data);
            if (!success) {
                // TODO: should we bubble up the revert reasons? slightly hard to debug. need to run the txn with traces
                revert ActionFailed(i);
            }
        }
    }

    function _fulfill(Fulfillment calldata fulfillment) internal {
        if (fulfillment.approvals.length > 0) _setApprovals(fulfillment.approvals);

        fulfillment.controlRoom.obeyCommands{value: fulfillment.value}(fulfillment.batch);
    }

    function _setApprovals(Approval[] memory approvals) internal {
        for (uint256 i = 0; i < approvals.length; i++) {
            approvals[i].token.safeApprove(approvals[i].spender, approvals[i].amount);
        }
    }

    function _useNonce(uint256 nonce) internal {
        if (nonceUsed[nonce]) revert InvalidNonce();
        nonceUsed[nonce] = true;
    }

    function verifySignature(bytes32 messageHash, bytes calldata signature) public view {
        if (!(SOLVER_SIGNER == AuthenticationLib.authenticate(messageHash, signature))) revert InvalidSigner();
    }

    function hash(
        uint256 nonce,
        Action[] calldata actions,
        Fulfillment calldata fulfillment
    ) public view returns (bytes32) {
        return keccak256(abi.encode(address(this), nonce, block.chainid, actions, fulfillment));
    }

    function hash(uint256 nonce, Action[] calldata actions) public view returns (bytes32) {
        return keccak256(abi.encode(address(this), nonce, block.chainid, actions));
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Rescues funds from the contract if they are locked by mistake.
     * @param token_ The address of the token contract.
     * @param rescueTo_ The address where rescued tokens need to be sent.
     * @param amount_ The amount of tokens to be rescued.
     */
    function rescueFunds(address token_, address rescueTo_, uint256 amount_) external onlyOwner {
        RescueFundsLib.rescueFunds(token_, rescueTo_, amount_);
    }

    /*//////////////////////////////////////////////////////////////
                             RECEIVE ETHER
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    fallback() external payable {}
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