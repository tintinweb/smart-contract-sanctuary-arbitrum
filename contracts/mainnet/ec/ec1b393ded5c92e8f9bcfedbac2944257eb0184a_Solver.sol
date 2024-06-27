// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";
import {RescueFundsLib} from "../lib/RescueFundsLib.sol";
import {ERC20, SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {AuthenticationLib} from "./../lib/AuthenticationLib.sol";
import {FulfilExec, BungeeGateway} from "../core/BungeeGateway.sol";

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
        BungeeGateway bungeeGateway;
        uint256 value;
        FulfilExec[] fulfilExecs;
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

        fulfillment.bungeeGateway.fulfilRequests{value: fulfillment.value}(fulfillment.fulfilExecs);
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

import {OnlyOwner, OnlyNominee} from "../common/BungeeErrors.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "../utils/Ownable.sol";
import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {IBaseRouter} from "../interfaces/IBaseRouter.sol";
import {ISwapExecutor} from "../interfaces/ISwapExecutor.sol";
import {ICalldataExecutor} from "../interfaces/ICalldataExecutor.sol";
import {ISwitchboardRouter} from "../interfaces/ISwitchboardRouter.sol";
import {IStakeVault} from "../interfaces/IStakeVault.sol";
import {IBungeeExecutor} from "../interfaces/IBungeeExecutor.sol";
import {SignedBatch, Request, FulfilExec, ExtractExec} from "../common/BungeeStructs.sol";
import {AuthenticationLib} from "../lib/AuthenticationLib.sol";
import {AffiliateFeesLib} from "../lib/AffiliateFeesLib.sol";
import {RequestLib} from "../lib/RequestLib.sol";
import {
    InsufficientNativeAmount,
    MofaSignatureInvalid,
    FulfillmentChainInvalid,
    RequestAlreadyFulfilled,
    RouterNotRegistered,
    MinOutputNotMet,
    InvalidRequest,
    FulfillmentDeadlineNotMet,
    CallerNotDelegate,
    BungeeSiblingDoesNotExist,
    InvalidMsg,
    SwapOutputInsufficient,
    NotDelegate,
    RequestProcessed,
    InvalidSwitchboard,
    InvalidRequest,
    PromisedAmountNotMet,
    CallerNotBungeeGateway,
    RequestNotProcessed,
    RouterAlreadyWhitelisted,
    RouterAlreadyRegistered,
    TransferFailed,
    InvalidStake,
    InsufficientCapacity
} from "../common/BungeeErrors.sol";
import {Permit2Lib} from "../lib/Permit2Lib.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {BungeeEvents} from "../common/BungeeEvents.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {IFeeCollector} from "../interfaces/IFeeCollector.sol";

// Structs
struct ExtractedRequest {
    uint256 expiry;
    address router;
    address sender;
    address delegate;
    uint32 switchboardId;
    address token;
    address transmitter; // For stake capacity
    address beneficiary; // For Transmitter
    uint256 amount;
    uint256[] promisedAmounts; // For Transmitter
    bytes affiliateFees; // For integrator
}

struct FulfilledRequest {
    uint256[] fulfilledAmounts;
    bool processed;
}

contract BungeeGateway is Ownable, BungeeEvents {
    using RequestLib for SignedBatch;
    using RequestLib for Request;
    using RequestLib for ExtractExec;
    using SafeTransferLib for ERC20;

    /// @notice address of the protocol signer
    /// @dev this address signs on the request batch that transmitter submits to the protocol.
    address public MOFA_SIGNER;

    // eslint-disable-next-line no-use-before-define
    ISwitchboardRouter public SWITCHBOARD_ROUTER;

    // eslint-disable-next-line no-use-before-define
    ISignatureTransfer immutable PERMIT2;

    /// @notice address of the protocol signer
    /// @dev this address signs on the request batch that transmitter submits to the protocol.
    ISwapExecutor public SWAP_EXECUTOR;

    /// @notice address of the CalldataExecutor
    /// @dev BungeeGateway delegates calldata execution at destination chain to this contract.
    ICalldataExecutor public CALLDATA_EXECUTOR;

    IFeeCollector public FEE_COLLECTOR;

    /// @notice address of the StakeVault
    /// @dev BungeeGateway transfers all stake to StakeVault
    /// @dev BungeeGateway triggers StakeVault to release stake funds
    IStakeVault public STAKE_VAULT;

    uint256 public immutable EXPIRY_BUFFER;
    uint8 public immutable SETTLEMENT_ID = 1;

    /// @dev the maximum capacity for whitelisted routers
    uint256 internal constant WHITELISTED_MAX_CAPACITY = type(uint256).max;

    // eslint-disable-next-line no-use-before-define
    address public immutable NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice this holds all the requests that have been fulfilled.
    mapping(bytes32 requestHash => FulfilledRequest request) public fulfilledRequests;

    /// @notice this holds all the requests that have been extracted.
    mapping(bytes32 requestHash => ExtractedRequest request) public extractedRequests;

    /// @dev this holds all the routers that are whitelisted.
    mapping(address router => bool whitelisted) public isWhitelisted;

    /// @notice this mapping holds all the receiver contracts, these contracts will receive funds.
    /// @dev bridged funds would reach receiver contracts first and then transmitter uses these funds to fulfil order.
    mapping(address router => mapping(uint256 toChainId => address whitelistedReceiver)) internal whitelistedReceivers;

    /// @notice this mapping holds all the addresses that are routers.
    /// @dev bungee sends funds from the users to these routers on the origin chain.
    /// @dev bungee calls these when fulfilment happens on the destination.
    mapping(address routers => bool supported) internal bungeeRouters;

    /// @notice this mapping holds capacity for a transmitter
    /// @dev token is checked against the inputToken or swapOutputToken of the request
    mapping(address transmitter => mapping(address token => uint256 capacity)) public transmitterCapacity;

    /**
     * @notice Constructor.
     * @param _owner owner of the contract.
     * @param _mofaSigner address of the mofa signer.
     * @param _switchboardRouter address of the switchboard router.
        Switchboard router is responsible for sending and delivering messages between chains.
     * @param _calldataRouter address of the calldata executror contract.
     * @param _permit2 address of the permit 2 contract.
     */
    constructor(
        address _owner,
        address _mofaSigner,
        address _switchboardRouter,
        address _swapExecutor,
        address _calldataRouter,
        address _permit2,
        uint256 _expiryBuffer
    ) Ownable(_owner) {
        MOFA_SIGNER = _mofaSigner;
        SWITCHBOARD_ROUTER = ISwitchboardRouter(_switchboardRouter);
        SWAP_EXECUTOR = ISwapExecutor(_swapExecutor);
        CALLDATA_EXECUTOR = ICalldataExecutor(_calldataRouter);
        PERMIT2 = ISignatureTransfer(_permit2);
        EXPIRY_BUFFER = _expiryBuffer;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice sets the new mofa signer address.  
        Can only be called by the owner.
     * @param _mofaSigner address of the new mofa signer.
     */
    function setMofaSigner(address _mofaSigner) external onlyOwner {
        MOFA_SIGNER = _mofaSigner;
    }

    /**
     * @notice sets the new switchboard router.  
        Can only be called by the owner.
     * @param _switchboardRouter address of the new switchboard router.
     */
    function setSwitchboardRouter(address _switchboardRouter) external onlyOwner {
        SWITCHBOARD_ROUTER = ISwitchboardRouter(_switchboardRouter);
    }

    /**
     * @notice sets the new fee collector.  
        Can only be called by the owner.
     * @param _feeCollector address of the new switchboard router.
     */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        FEE_COLLECTOR = IFeeCollector(_feeCollector);
    }

    /**
     * @notice sets the new swap executor contract.  
        Can only be called by the owner.
     * @param _swapExecutor address of the new swap executor.
     */
    function setSwapExecutor(address _swapExecutor) external onlyOwner {
        SWAP_EXECUTOR = ISwapExecutor(_swapExecutor);
    }

    /**
     * @notice sets the new calldata executor contract.  
        Can only be called by the owner.
     * @param _calldataExecutor address of the new calldata executor.
     */
    function setCalldataExecutor(address _calldataExecutor) external onlyOwner {
        CALLDATA_EXECUTOR = ICalldataExecutor(_calldataExecutor);
    }

    /**
     * @notice sets the new StakeVault contract.  
        Can only be called by the owner.
     * @param _stakeVault address of the new calldata executor.
     */
    function setStakeVault(address _stakeVault) external onlyOwner {
        STAKE_VAULT = IStakeVault(_stakeVault);
    }

    /// @notice register a whitelisted router
    function registerWhitelistedRouter(address whitelistedRouter) external onlyOwner {
        if (isWhitelisted[whitelistedRouter]) revert RouterAlreadyWhitelisted();
        if (bungeeRouters[whitelistedRouter]) revert RouterAlreadyRegistered();

        isWhitelisted[whitelistedRouter] = true;

        _addBungeeRouter(whitelistedRouter);
    }

    /// @notice register a staked router
    function registerStakedRouter(address stakedRouter) external onlyOwner {
        if (bungeeRouters[stakedRouter]) revert RouterAlreadyRegistered();

        _addBungeeRouter(stakedRouter);
    }

    /// @notice Adds a new router to the protocol
    function _addBungeeRouter(address _bungeeRouter) internal {
        bungeeRouters[_bungeeRouter] = true;
    }

    function isBungeeRouter(address router) public view returns (bool) {
        return bungeeRouters[router];
    }

    /**
     * @notice adds the new whitelisted receiver address against a router.  
        Can only be called by the owner.
     * @param receiver address of the new whitelisted receiver contract.
     * @param destinationChainId destination chain id where the receiver will exist.
     * @param router router address from which the funs will be routed from.
     */
    function setWhitelistedReceiver(address receiver, uint256 destinationChainId, address router) external onlyOwner {
        whitelistedReceivers[router][destinationChainId] = receiver;
    }

    /**
     * @notice gets the receiver address set for the router on the destination chain.
     * @param destinationChainId destination chain id where the receiver will exist.
     * @param router router address from which the funds will be routed from.
     */
    function getWhitelistedReceiver(address router, uint256 destinationChainId) external view returns (address) {
        return whitelistedReceivers[router][destinationChainId];
    }

    /**
     * @notice Transmitter can register and increment their stake against a token
     * @dev Transmitter would transfer their tokens for the stake
     */
    function registerTransmitterStake(address token, uint256 capacity) external payable {
        transmitterCapacity[msg.sender][token] = transmitterCapacity[msg.sender][token] + capacity;

        if (token == NATIVE_TOKEN_ADDRESS) {
            if (msg.value != capacity) revert InvalidStake();
            (bool success, ) = address(STAKE_VAULT).call{value: capacity, gas: 5000}("");
            if (!success) revert TransferFailed();
        } else {
            ERC20(token).safeTransferFrom(msg.sender, address(STAKE_VAULT), capacity);
        }
    }

    /**
     * @notice Transmitter can withdraw their stake against a token
     * @dev Transmitter would receive their tokens back
     * @dev Transmitter's capacity would be reduced
     */
    function withdrawTransmitterStake(address token, uint256 capacity) external {
        transmitterCapacity[msg.sender][token] = transmitterCapacity[msg.sender][token] - capacity;

        STAKE_VAULT.withdrawStake(token, capacity, msg.sender);
    }

    /// @notice check capacity for a whitelisted router or staked transmitter
    /// @dev if the router is whitelisted, it has a max capacity
    /// @dev if the router is not whitelisted, return registered transmitter capacity
    function checkCapacity(address router, address transmitter, address token) public view returns (uint256) {
        return transmitterCapacity[transmitter][token];
    }

    function _increaseCapacity(address router, address transmitter, address token, uint256 increaseBy) internal {
        if (!isWhitelisted[router])
            transmitterCapacity[transmitter][token] = transmitterCapacity[transmitter][token] + increaseBy;
    }

    function _reduceCapacity(address router, address transmitter, address token, uint256 reduceBy) internal {
        if (!isWhitelisted[router])
            transmitterCapacity[transmitter][token] = transmitterCapacity[transmitter][token] - reduceBy;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SOURCE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice extract the user requests and routes it via the respetive routers.
     * @notice the user requests can only be extracted if the mofa signature is valid.
     * @notice each request can be routed via a different router.
     * @notice it would be assumed as a successful execution if the router call does not revert.
     * @dev state of the request would be saved against the requesthash created.
     * @dev funds from the user wallet will be pulled and sent to the router.
     * @dev if there is a swap involved then swapped funds would reach the router.
     * @param signedBatch batch of extractions submitted by the transmitter.
     * @param mofaSignature signature of mofa on the batch.
     */
    function extractRequests(SignedBatch calldata signedBatch, bytes calldata mofaSignature) external {
        // Checks if batch has been authorised by MOFA
        _checkMofaSig(signedBatch, mofaSignature);

        // Iterate through extractExec
        unchecked {
            for (uint256 i = 0; i < signedBatch.extractExecs.length; i++) {
                // Check if the promised amount is more than the minOutputAmount
                for (uint256 j = 0; j < signedBatch.extractExecs[i].request.basicReq.outputTokens.length; j++) {
                    if (
                        signedBatch.extractExecs[i].promisedAmounts[j] <
                        signedBatch.extractExecs[i].request.basicReq.minOutputAmounts[j]
                    ) revert MinOutputNotMet();
                }

                // If a swap is involved the router would receive the swap output tokens specified in request.
                // If no swap is involved the router would receive the input tokens specified in request.
                // @todo check request.swapOutputToken, instead of swapPayload?
                if (signedBatch.extractExecs[i].swapPayload.length > 0) {
                    _swapAndCallRouter(signedBatch.extractExecs[i]);
                } else {
                    _callRouter(signedBatch.extractExecs[i]);
                }
            }
        }
    }

    /**
     * @notice extract the user requests and routes it via the respetive routers.
     * @notice the user requests can only be extracted if the mofa signature is valid.
     * @notice each request can be routed via a different router.
     * @dev if the switchboard id is not same as the user request, it will revert.
     * @dev if the fulfilled amounts is not equal to or greater than the promised amount, revert.
     * @dev mark the extracted hash deleted.
     * @param switchboardId id of the switchboar the message came from.
     * @param payload msg payload sent.
     */
    function inboundMsgFromSwitchboard(
        uint8 msgId,
        uint32,
        uint32 switchboardId,
        bytes calldata payload
    ) external payable {
        // If the msg sender is not switchboard router, revert.
        if (msg.sender != address(SWITCHBOARD_ROUTER)) revert InvalidMsg();
        if (msgId == SETTLEMENT_ID) {
            _handleSettlement(switchboardId, payload);
        } else {
            revert InvalidMsg();
        }
    }

    function _handleSettlement(uint32 switchboardId, bytes calldata payload) internal {
        (bytes32[] memory requestHashes, uint256[][] memory fulfilledAmounts) = abi.decode(
            payload,
            (bytes32[], uint256[][])
        );

        unchecked {
            for (uint256 i = 0; i < requestHashes.length; i++) {
                _validateAndReleaseSettleRequests(switchboardId, requestHashes[i], fulfilledAmounts[i]);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL SOURCE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice checks if the mofa signature is valid on the batch submitted by the transmitter.
     * @param signedBatch batch of extractions submitted by the transmitter.
     * @param mofaSignature signature of mofa on the batch.
     */
    function _checkMofaSig(SignedBatch calldata signedBatch, bytes memory mofaSignature) internal view {
        // Create the hash of BatchHash
        bytes32 batchHash = signedBatch.hashOriginBatch();
        // Get the signer
        address signer = AuthenticationLib.authenticate(batchHash, mofaSignature);

        // Check if addresses match
        if (signer != MOFA_SIGNER) revert MofaSignatureInvalid();
    }

    /**
     * @notice this function is used when the transmitter submits a swap for a user request.
     * @notice assumption is that the receiver of the swap will be the router mentioned in the exec.
     * @dev Funds would be transferred to the swap executor first.
     * @dev Swap executor will be called with the swap payload.
     * @dev Funds after the swap should reach the router.
     * @dev If the swap does not give back enough, revert.
     * @dev If all is good, the router will be called with relevant details.
     * @dev Saves the extraction details against the requestHash.
     * @param extractExec execution submitted by the transmitter for the request.
        When a request is settled beneficiary will receive funds.
     */
    function _swapAndCallRouter(ExtractExec memory extractExec) internal {
        // Create the request hash for the submitted request.
        bytes32 requestHash = extractExec.request.hashOriginRequest();

        bool isNativeToken = extractExec.request.swapOutputToken == NATIVE_TOKEN_ADDRESS;

        // Get the initial balance of the router for the swap output token
        uint256 initialBalance = isNativeToken
            ? extractExec.router.balance
            : ERC20(extractExec.request.swapOutputToken).balanceOf(extractExec.router);

        // Calls Permit2 to transfer funds from user to swap executor.
        PERMIT2.permitWitnessTransferFrom(
            Permit2Lib.toPermit(
                extractExec.request.basicReq.inputToken,
                extractExec.request.basicReq.inputAmount,
                extractExec.request.basicReq.nonce,
                extractExec.request.basicReq.deadline
            ),
            /// @dev transfer tokens to SwapExecutor
            Permit2Lib.transferDetails(extractExec.request.basicReq.inputAmount, address(SWAP_EXECUTOR)),
            extractExec.request.basicReq.sender,
            requestHash,
            RequestLib.PERMIT2_ORDER_TYPE,
            extractExec.userSignature
        );

        // Call the swap executor to execute the swap.
        /// @dev swap output tokens are expected to be sent to the router
        SWAP_EXECUTOR.executeSwap(
            extractExec.request.basicReq.inputToken,
            extractExec.request.basicReq.inputAmount,
            extractExec.swapRouter,
            extractExec.swapPayload
        );

        // Get the final balance of the swap output token on the router
        uint256 swappedAmount = isNativeToken
            ? extractExec.router.balance - initialBalance
            : ERC20(extractExec.request.swapOutputToken).balanceOf(extractExec.router) - initialBalance;

        // Check if the minimum swap output is sufficed after the swap. If not revert.
        if (swappedAmount < extractExec.request.minSwapOutput) revert SwapOutputInsufficient();

        if (!isWhitelisted[extractExec.router]) {
            _validateAndReduceStake(extractExec.router, swappedAmount, extractExec.request.swapOutputToken);
        }

        uint256 expiry = block.timestamp + EXPIRY_BUFFER;

        // Call the router with relevant details
        // @todo request hash might not be needed.
        IBaseRouter(extractExec.router).execute(
            swappedAmount,
            extractExec.request.swapOutputToken,
            requestHash,
            expiry,
            whitelistedReceivers[extractExec.router][extractExec.request.basicReq.destinationChainId],
            address(FEE_COLLECTOR),
            extractExec
        );

        // Save the extraction details
        extractedRequests[requestHash] = ExtractedRequest({
            expiry: expiry,
            router: extractExec.router,
            sender: extractExec.request.basicReq.sender,
            delegate: extractExec.request.basicReq.delegate,
            switchboardId: extractExec.request.basicReq.switchboardId,
            token: extractExec.request.swapOutputToken,
            amount: swappedAmount,
            affiliateFees: extractExec.request.affiliateFees,
            transmitter: msg.sender,
            beneficiary: extractExec.beneficiary,
            promisedAmounts: extractExec.promisedAmounts
        });

        // Emits Extraction Event
        emit RequestExtracted(requestHash, msg.sender, abi.encode(extractExec));
    }

    /**
     * @notice this function is used when the transmitter submits a request that does not involve a swap.
     * @dev funds would be transferred to the router directly from the user.
     * @dev Saves the extraction details against the requestHash.
     * @param extractExec execution submitted by the transmitter for the request.
        When a request is settled beneficiary will receive funds.
     */
    function _callRouter(ExtractExec memory extractExec) internal {
        // If not whitelisted, valiate if the router is part of the protocol and reduce transmitter stake
        if (!isWhitelisted[extractExec.router]) {
            _validateAndReduceStake(
                extractExec.router,
                extractExec.request.basicReq.inputAmount,
                extractExec.request.basicReq.inputToken
            );
        }

        // Create the request hash for the submitted request.
        bytes32 requestHash = extractExec.request.hashOriginRequest();

        // Calls Permit2 to transfer funds from user to the router.
        PERMIT2.permitWitnessTransferFrom(
            Permit2Lib.toPermit(
                extractExec.request.basicReq.inputToken,
                extractExec.request.basicReq.inputAmount,
                extractExec.request.basicReq.nonce,
                extractExec.request.basicReq.deadline
            ),
            Permit2Lib.transferDetails(extractExec.request.basicReq.inputAmount, extractExec.router),
            extractExec.request.basicReq.sender,
            requestHash,
            RequestLib.PERMIT2_ORDER_TYPE,
            extractExec.userSignature
        );

        uint256 expiry = block.timestamp + EXPIRY_BUFFER;

        // Call the router with relevant details
        IBaseRouter(extractExec.router).execute(
            extractExec.request.basicReq.inputAmount,
            extractExec.request.basicReq.inputToken,
            requestHash,
            expiry,
            whitelistedReceivers[extractExec.router][extractExec.request.basicReq.destinationChainId],
            address(FEE_COLLECTOR),
            extractExec
        );

        // Save the extraction details
        extractedRequests[requestHash] = ExtractedRequest({
            expiry: expiry,
            router: extractExec.router,
            sender: extractExec.request.basicReq.sender,
            delegate: extractExec.request.basicReq.delegate,
            switchboardId: extractExec.request.basicReq.switchboardId,
            token: extractExec.request.basicReq.inputToken,
            amount: extractExec.request.basicReq.inputAmount,
            affiliateFees: extractExec.request.affiliateFees,
            transmitter: msg.sender,
            beneficiary: extractExec.beneficiary,
            promisedAmounts: extractExec.promisedAmounts
        });

        // Emits Extraction Event
        emit RequestExtracted(requestHash, msg.sender, abi.encode(extractExec));
    }

    function _validateAndReduceStake(address router, uint256 inputAmount, address inputToken) internal {
        // Check if the router exists in the protocol
        // @review can move this outside, but gas cost seems higher
        if (!isBungeeRouter(router)) revert RouterNotRegistered();

        // check capacity before extraction
        if (checkCapacity(router, msg.sender, inputToken) < inputAmount) revert InsufficientCapacity();
        _reduceCapacity(router, msg.sender, inputToken, inputAmount);
    }

    /**
     * @notice validates the settlement details against the request.
     * @param switchboardId id of the switchboard that received the msg.
     * @param requestHash hash of the request that needs to be settled.
     * @param fulfilledAmounts amounts sent to the receiver on the destination.
     */
    function _validateAndReleaseSettleRequests(
        uint32 switchboardId,
        bytes32 requestHash,
        uint256[] memory fulfilledAmounts
    ) internal {
        // Check if the extraction exists and the switchboard id is correct.
        ExtractedRequest memory eReq = extractedRequests[requestHash];
        // @todo can switchboardId 0 bypass this check? SwitchboardRouter.switchboardIdCount starts at zero rn.
        if (eReq.switchboardId != switchboardId) revert InvalidSwitchboard();

        // Check if the request is valid.
        // Check if request has already been settled.
        // @review this loop wont be executed in case the order is settled
        // since eReq.promisedAmounts.length would be zero. hence check length
        if (eReq.promisedAmounts.length == 0) revert InvalidRequest();

        // Check if the fulfilment was done correctly.
        unchecked {
            for (uint256 i = 0; i < eReq.promisedAmounts.length; i++) {
                // Check if the request was fulfilled
                if (eReq.promisedAmounts[i] > fulfilledAmounts[i]) revert PromisedAmountNotMet();
            }
        }

        // Get the beneficiary amount to settle the request.
        // Checks if there was affilate fees involved.
        uint256 beneficiaryAmount = AffiliateFeesLib.getAmountAfterFee(eReq.amount, eReq.affiliateFees);

        if (isWhitelisted[eReq.router]) {
            // Settle Fee.
            FEE_COLLECTOR.settleFee(requestHash);

            // Transfer the tokens to the beneficiary
            IBaseRouter(eReq.router).releaseFunds(eReq.token, beneficiaryAmount, eReq.beneficiary);
        } else {
            // replenish transmitter stake by input amount
            _increaseCapacity(eReq.router, eReq.transmitter, eReq.token, eReq.amount);
        }

        // Delete the origin execution.
        delete extractedRequests[requestHash];

        // Emits Settlement event
        emit RequestSettled(requestHash);
    }

    /**
     * @notice this function can be called by user on source chain to revoke order after fulfill deadline has passed
     * @dev Asks router to send back escrowed funds to commander in case of RFQ.
     * @dev Slash the stake from the transmitter to pay back to the user.
     * @dev Funds routed via whitelisted routers cannot be withdrawn on source. Withdraw on destination can be done for whitelisted routes.
     * @param requestHash hash of the request
     */
    function withdrawRequestOnOrigin(bytes32 requestHash) external {
        /// @review no need to check if request exists, execution would revert if it doesn't
        ExtractedRequest memory eReq = extractedRequests[requestHash];

        // Checks deadline of request fulfillment and if its exceeded,
        if (block.timestamp < eReq.expiry) revert FulfillmentDeadlineNotMet();

        if (isWhitelisted[eReq.router]) {
            // Checks if there was affilate fees involved.
            uint256 routerAmount = AffiliateFeesLib.getAmountAfterFee(eReq.amount, eReq.affiliateFees);

            FEE_COLLECTOR.refundFee(requestHash, eReq.sender);
            // Ask router to transfer funds back to the user
            IBaseRouter(eReq.router).releaseFunds(eReq.token, routerAmount, eReq.sender);
        } else {
            // Withraw transmitter stake and give back to the user.
            /// @dev transmitter capacity would already be reduced when the request was extracted
            /// no need to change the capacity any way then
            STAKE_VAULT.withdrawStake(eReq.token, eReq.amount, eReq.sender);
        }

        // Emits Withdraw event
        emit WithdrawOnOrigin(requestHash, eReq.token, eReq.amount, eReq.sender);

        // Delete the origin execution
        delete extractedRequests[requestHash];
    }

    /*//////////////////////////////////////////////////////////////////////////
                                DESTINATION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Performs fulfillment of a batch of requests
     * @dev Called by transmitter to fulfil a request
     * @dev Calculates and tracks destination hash of fulfilled requests
     * @dev Can fulfill a batch of requests
     * @dev Checks if provided router contract is registered with Bungee protocol
     * @dev Can perform calldata execution on destination by delegating it to CalldataExecutor contract
     * @param fulfillExecs Array of FulfilExec
     */
    function fulfilRequests(FulfilExec[] calldata fulfillExecs) external payable {
        // Will be used to check if the msg value was sufficient at the end.
        uint256 nativeAmount = 0;

        // Iterate through the array of fulfil execs.
        for (uint256 i = 0; i < fulfillExecs.length; i++) {
            FulfilExec memory fulfillExec = fulfillExecs[i];

            // Calculate the request hash. Being tracked on fulfilledRequests
            bytes32 requestHash = fulfillExec.request.hashDestinationRequest();

            // 1.a Check if the command is already fulfilled / cancelled
            if (fulfilledRequests[requestHash].processed) revert RequestProcessed();

            // 1.c Check if the provided router address is part of the Bungee protocol
            if (!isBungeeRouter(fulfillExec.fulfilRouter)) revert RouterNotRegistered();

            // 1.d Check if promisedOutput amounts are more than minOutput amounts
            for (uint256 j = 0; j < fulfillExec.fulfilAmounts.length; j++) {
                if (fulfillExec.fulfilAmounts[j] < fulfillExec.request.basicReq.minOutputAmounts[j])
                    revert MinOutputNotMet();
            }

            // 2. Call the fulfil function on the router
            IBaseRouter(fulfillExec.fulfilRouter).fulfil{value: fulfillExec.msgValue}(
                requestHash,
                fulfillExec,
                msg.sender
            );

            nativeAmount += fulfillExec.msgValue;

            // 3. calldata execution via Calldata Executor using Request.destinationCalldata, Request.minDestGas
            _executeCalldata(
                fulfillExec.request.basicReq.receiver,
                fulfillExec.request.minDestGas,
                fulfillExec.fulfilAmounts,
                fulfillExec.request.basicReq.outputTokens,
                requestHash,
                fulfillExec.request.destinationCalldata
            );

            // 4. BungeeGateway stores order hash and its outputToken, promisedOutput
            fulfilledRequests[requestHash] = FulfilledRequest({
                fulfilledAmounts: fulfillExec.fulfilAmounts,
                processed: true
            });

            // Emits Fulfilment Event
            emit RequestFulfilled(requestHash, msg.sender, abi.encode(fulfillExec));
        }

        if (msg.value < nativeAmount) revert InsufficientNativeAmount();
    }

    /**
     * @notice Sends a settlement message back towards source to settle the requests.
     * @param requestHashes Array of request hashes to be settled.
     * @param gasLimit Gas limit to be used on the message receiving chain.
     * @param originChainId Chain Id to send the message towards.
     * @param switchboardId id of the switchboard to use. switchboardIds of all requests in the batch must match
     */
    function settleRequests(
        bytes32[] memory requestHashes,
        uint256 gasLimit,
        uint32 originChainId,
        uint32 switchboardId // @todo should this be checked against the switchboardId of any one of the request? will need to store on FulfilledRequest
    ) external payable {
        // Create an empty array of fulfilled amounts.
        uint256[][] memory fulfilledAmounts = new uint256[][](requestHashes.length);

        // Loop through the requestHashes and set fulfilled amounts
        unchecked {
            for (uint256 i = 0; i < requestHashes.length; i++) {
                // check if request already processed
                if (!fulfilledRequests[requestHashes[i]].processed) revert RequestNotProcessed();

                // @todo should it check if cancelled vs. fulfilled?

                // Get the amount send to he receiver of the command and push into array
                fulfilledAmounts[i] = fulfilledRequests[requestHashes[i]].fulfilledAmounts;
            }
        }

        // Call the switchboard router to  send the message.
        SWITCHBOARD_ROUTER.sendOutboundMsg{value: msg.value}(
            originChainId,
            switchboardId,
            SETTLEMENT_ID,
            gasLimit,
            abi.encode(requestHashes, fulfilledAmounts)
        );
    }

    function withdrawRequestOnDestination(
        address router,
        Request calldata request,
        bytes calldata withdrawRequestData
    ) external payable {
        // generate the requestHash
        bytes32 requestHash = request.hashDestinationRequest();

        // checks if the caller is the delegate
        if (msg.sender != request.basicReq.delegate) revert NotDelegate();

        // Check if the command is already fulfilled / cancelled
        if (fulfilledRequests[requestHash].processed) revert RequestProcessed();

        // mark request as cancelled
        fulfilledRequests[requestHash] = FulfilledRequest({fulfilledAmounts: new uint256[](0), processed: true});

        // check router is in system
        if (!isBungeeRouter(router)) revert RouterNotRegistered();

        /// @dev router should know if the request hash is not supposed to be handled by it
        IBaseRouter(router).withdrawRequestOnDestination(request, withdrawRequestData);

        // TODO : need to add an event here
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL DESTINATION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev delegates destination calldata execution to the CalldataExecutor contract
    /// @param to destination address
    /// @param minDestGasLimit minimum gas limit that should be used for the destination execution
    /// @param fulfilledAmounts array of amounts fulfilled on the destination in the request
    /// @param outputTokens array of output tokens in the request
    /// @param requestHash hash of the request
    /// @param executionData calldata to be executed on the destination
    function _executeCalldata(
        address to,
        uint256 minDestGasLimit,
        uint256[] memory fulfilledAmounts,
        address[] memory outputTokens,
        bytes32 requestHash,
        bytes memory executionData
    ) internal {
        // @review these checks & encoding must be here or in the CalldataExecutor contract?

        // Check and return with no action if the data is empty
        if (executionData.length == 0) return;
        // Check and return with no action if the destination is invalid
        if (to == address(0)) return;
        if (to == address(this)) return;

        // Encodes request data in the payload
        bytes memory encodedData = abi.encodeCall(
            // @todo too many hops for destination calldata? BungeeGateway → CalldataExecutor → IBungeeExecutor → Aave deposit
            IBungeeExecutor.executeData,
            (fulfilledAmounts, requestHash, outputTokens, executionData)
        );

        // Execute calldata
        CALLDATA_EXECUTOR.executeCalldata(to, encodedData, minDestGasLimit);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    GETTERS
    //////////////////////////////////////////////////////////////////////////*/
    function getExtractedRequest(bytes32 requestHash) external view returns (ExtractedRequest memory) {
        return extractedRequests[requestHash];
    }

    function getFulfilledRequest(bytes32 requestHash) external view returns (FulfilledRequest memory) {
        return fulfilledRequests[requestHash];
    }

    function hashOriginBatch(SignedBatch memory signedBatch) public view returns (bytes memory, bytes32, bytes memory) {
        return (abi.encode(signedBatch), signedBatch.hashOriginBatch(), abi.encode(signedBatch.extractExecs));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//

error MofaSignatureInvalid();
error InsufficientNativeAmount();

error FulfillmentChainInvalid();
error RequestAlreadyFulfilled();
error RouterNotRegistered();

error TransferFailed();
error CallerNotBungeeGateway();

error NoExecutionCacheFound();
error ExecutionCacheFailed();
error SwapOutputInsufficient();

error UnsupportedDestinationChainId();

error MinOutputNotMet();

error OnlyOwner();
error OnlyNominee();

error InvalidRequest();
error FulfillmentDeadlineNotMet();
error CallerNotDelegate();

error BungeeSiblingDoesNotExist();
error InvalidMsg();

error NotDelegate();
error RequestProcessed();
error RequestNotProcessed();

error InvalidSwitchboard();
error PromisedAmountNotMet();

error MsgReceiveFailed();

error RouterAlreadyWhitelisted();
error InvalidStake();
error RouterAlreadyRegistered();

error InvalidFulfil();

error InsufficientCapacity();

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import {FulfilExec, ExtractExec, Request} from "../common/BungeeStructs.sol";

interface IBaseRouter {
    function execute(
        uint256 amount,
        address inputToken,
        bytes32 requestHash,
        uint256 expiry,
        address receiverContract,
        address feeCollector,
        ExtractExec memory exec
    ) external;

    function fulfil(bytes32 requestHash, FulfilExec calldata fulfillExec, address transmitter) external payable;

    function releaseFunds(address token, uint256 amount, address recipient) external;

    function withdrawRequestOnDestination(Request calldata request, bytes calldata withdrawRequestData) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISwapExecutor {
    function executeSwap(address token, uint256 amount, address swapRouter, bytes memory swapPayload) external;
    function executeSwapWithValue(address swapRouter, bytes memory swapPayload, uint256 msgValue) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ICalldataExecutor {
    function executeCalldata(address to, bytes memory encodedData, uint256 msgGasLimit) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISwitchboardRouter {
    function sendOutboundMsg(
        uint32 originChainId,
        uint32 switchboardId,
        uint8 msgId,
        uint256 destGasLimit,
        bytes calldata payload
    ) external payable;

    function receiveAndDeliverMsg(uint32 switchboardId, uint32 siblingChainId, bytes calldata payload) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

interface IStakeVault {
    function withdrawStake(address token, uint256 capacity, address transmitter) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

interface IBungeeExecutor {
    function executeData(
        uint256[] calldata amounts,
        bytes32 commandHash,
        address[] calldata tokens,
        bytes memory callData
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Basic details in the request
struct BasicRequest {
    // src chain id
    uint256 originChainId;
    // dest chain id
    uint256 destinationChainId;
    // deadline of the request
    uint256 deadline;
    // nonce used for uniqueness in signature
    uint256 nonce;
    // address of the user placing the request.
    address sender;
    // address of the receiver on destination chain
    address receiver;
    // delegate address that has some rights over the request signed
    address delegate;
    // address of bungee gateway, this address will have access to pull funds from the sender.
    address bungeeGateway;
    // id of the switchboard
    uint32 switchboardId;
    // address of the input token
    address inputToken;
    // amount of the input tokens
    uint256 inputAmount;
    // array of output tokens to be received on the destination.
    address[] outputTokens;
    // array of minimum amounts to be receive on the destination for the output tokens array.
    uint256[] minOutputAmounts;
}

// The Request which user signs
struct Request {
    // basic details in the request.
    BasicRequest basicReq;
    // swap putput token that the user is okay with swapping input token to.
    address swapOutputToken;
    // minimum swap output the user is okay with swapping the input token to.
    // Transmitter can choose or not choose to swap tokens.
    uint256 minSwapOutput;
    // calldata execution parameter. Only to be used when execution is required on destination.
    // minimum dest gas limit to execute calldata on destination
    uint256 minDestGas;
    // array of addresses to check if request whitelists only certain transmitters
    address[] exclusiveTransmitters;
    // array of addresses to check if request whitelists only certain routers
    address[] exclusiveRouters;
    // any sort of metadata to be passed with the request
    bytes32 metadata;
    // fees of the affiliate if any
    bytes affiliateFees;
    // calldata to be executed on the destination
    // callata can only be executed on the receiver in the request.
    bytes destinationCalldata; //@todo rename to payload
}

// Transmitter's origin chain execution details for a request with promisedAmounts.
struct ExtractExec {
    // User signed Request
    Request request;
    // address of the router being used for the request.
    address router;
    // array of promised amounts for the corresponding output tokens on the destination
    uint256[] promisedAmounts;
    // RouterPayload (router specific data) + RouterValue (value required by the router) etc etc
    bytes routerData;
    // swapPayload 0x00 if no swap is involved.
    bytes swapPayload;
    // swapRouterAddress
    address swapRouter;
    // user signature against the request
    bytes userSignature;
    // address of the beneficiary submitted by the transmitter.
    // the beneficiary will be the one receiving locked tokens when a request is settled.
    address beneficiary;
}

// Batch of executions on the origin chain signed by MOFA.
struct SignedBatch {
    // Array of extraction executions
    ExtractExec[] extractExecs;
}

// Transmitter's destination chain execution details with fulfil amounts.
struct FulfilExec {
    // User Signed Request
    Request request;
    // address of the router
    address fulfilRouter;
    // amounts to be sent to the receiver for the corresponing output tokens.
    uint256[] fulfilAmounts;
    // extraPayload for router.
    bytes routerData;
    // total msg.value to be sent to fulfil native token output token
    uint256 msgValue;
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
     * @param bridgingAmount amount to be bridged
     * @param affiliateFees packed bytes containing feeTakerAddress and feeInBps
     *                      ensure the affiliateFees is packed as follows:
     *                      address feeTakerAddress (20 bytes) + uint48 feeInBps (6 bytes) = 26 bytes
     * @return bridgingAmount after deducting affiliate fees
     */
    function getAffiliateFees(
        uint256 bridgingAmount,
        bytes memory affiliateFees
    ) internal pure returns (uint256, uint256, address) {
        address feeTakerAddress;
        uint256 feeAmount = 0;
        if (affiliateFees.length > 0) {
            uint48 feeInBps;

            if (affiliateFees.length != 26) revert WrongAffiliateFeeLength();

            feeInBps = BytesLib.toUint48(affiliateFees, 20);
            feeTakerAddress = BytesLib.toAddress(affiliateFees, 0);

            if (feeInBps > 0) {
                // calculate fee
                feeAmount = ((bridgingAmount * feeInBps) / PRECISION);
                bridgingAmount -= feeAmount;
            }
        }

        return (bridgingAmount, feeAmount, feeTakerAddress);
    }

    function getAmountAfterFee(uint256 bridgingAmount, bytes memory affiliateFees) internal pure returns (uint256) {
        address feeTakerAddress;
        uint256 feeAmount = 0;
        if (affiliateFees.length > 0) {
            uint48 feeInBps;

            if (affiliateFees.length != 26) revert WrongAffiliateFeeLength();

            feeInBps = BytesLib.toUint48(affiliateFees, 20);
            feeTakerAddress = BytesLib.toAddress(affiliateFees, 0);

            if (feeInBps > 0) {
                // calculate fee
                feeAmount = ((bridgingAmount * feeInBps) / PRECISION);
                bridgingAmount -= feeAmount;
            }
        }

        return (bridgingAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import {BasicRequest, Request, ExtractExec, SignedBatch} from "../common/BungeeStructs.sol";
import {BasicRequestLib} from "./BasicRequestLib.sol";
import {Permit2Lib} from "./Permit2Lib.sol";

/// @title Bungee Request Library.
/// @author bungee protocol
/// @notice This library is responsible for all the hashing related to Request object.
library RequestLib {
    using BasicRequestLib for BasicRequest;

    // Permit 2 Witness Order Type.
    string internal constant PERMIT2_ORDER_TYPE =
        string(
            abi.encodePacked(
                "Request witness)",
                abi.encodePacked(BasicRequestLib.BASIC_REQUEST_TYPE, REQUEST_TYPE),
                Permit2Lib.TOKEN_PERMISSIONS_TYPE
            )
        );

    // REQUEST TYPE encode packed
    bytes internal constant REQUEST_TYPE =
        abi.encodePacked(
            "Request(",
            "BasicRequest basicReq,",
            "address swapOutputToken,",
            "uint256 minSwapOutput,",
            "uint256 minDestGas,",
            "address[] exclusiveTransmitters,",
            "address[] exclusiveRouters",
            "bytes32 metadata",
            "bytes affiliateFees",
            "bytes destinationCalldata)"
        );

    // EXTRACT EXEC TYPE.
    // @review this lib again, make sure things are solid
    bytes internal constant EXTRACT_EXEC_TYPE =
        abi.encodePacked(
            "ExtractExec(",
            "Request request,",
            "address router",
            "uint256[] promisedAmounts",
            "bytes routerData",
            "bytes swapPayload",
            "address swapRouter",
            "bytes userSignature",
            "address beneficiary)"
        );

    // BUNGEE_REQUEST_TYPE
    bytes internal constant BUNGEE_REQUEST_TYPE = abi.encodePacked(REQUEST_TYPE, BasicRequestLib.BASIC_REQUEST_TYPE);

    // Keccak Hash of BUNGEE_REQUEST_TYPE
    bytes32 internal constant BUNGEE_REQUEST_TYPE_HASH = keccak256(BUNGEE_REQUEST_TYPE);

    // Exec Type.
    bytes internal constant EXEC_TYPE = abi.encodePacked(EXTRACT_EXEC_TYPE, REQUEST_TYPE);

    // Keccak Hash of Exec Type.
    bytes32 internal constant EXTRACT_EXEC_TYPE_HASH = keccak256(EXEC_TYPE);

    /// @notice Hash of request on the origin chain
    /// @param request request that is signe by the user
    function hashOriginRequest(Request memory request) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BUNGEE_REQUEST_TYPE_HASH,
                    request.basicReq.originHash(),
                    request.swapOutputToken,
                    request.minSwapOutput,
                    request.minDestGas,
                    keccak256(abi.encodePacked(request.exclusiveTransmitters)),
                    keccak256(abi.encodePacked(request.exclusiveRouters)),
                    request.metadata,
                    keccak256(request.affiliateFees),
                    keccak256(request.destinationCalldata)
                )
            );
    }

    /// @notice Hash of request on the destination chain
    /// @param request request signed by the user
    function hashDestinationRequest(Request memory request) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BUNGEE_REQUEST_TYPE_HASH,
                    request.basicReq.destinationHash(),
                    request.swapOutputToken,
                    request.minSwapOutput,
                    request.minDestGas,
                    keccak256(abi.encodePacked(request.exclusiveTransmitters)),
                    keccak256(abi.encodePacked(request.exclusiveRouters)),
                    request.metadata,
                    keccak256(request.affiliateFees),
                    keccak256(request.destinationCalldata)
                )
            );
    }

    /// @notice Hash of Extract Exec on the origin chain
    /// @param execution Transmitter submitted extract exec object
    function hashOriginExtractExec(ExtractExec memory execution) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EXTRACT_EXEC_TYPE_HASH,
                    hashOriginRequest(execution.request),
                    execution.router,
                    keccak256(abi.encodePacked(execution.promisedAmounts)),
                    keccak256(execution.routerData),
                    keccak256(execution.swapPayload),
                    execution.swapRouter,
                    keccak256(execution.userSignature),
                    execution.beneficiary
                )
            );
    }

    /// @notice hash a batch of extract execs
    /// @param batch batch of extract exects to be hashed
    function hashOriginBatch(SignedBatch memory batch) internal view returns (bytes32) {
        unchecked {
            bytes32 outputHash = keccak256("BUNGEE_EXTRACT_EXEC");
            // Hash all of the extract execs present in the batch.
            for (uint256 i = 0; i < batch.extractExecs.length; i++) {
                outputHash = keccak256(abi.encode(outputHash, hashOriginExtractExec(batch.extractExecs[i])));
            }

            return outputHash;
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BungeeEvents {
    /// @notice Emitted when a request is extracted
    /// @param requestHash hash of the request
    /// @param transmitter address of the transmitter
    /// @param execution encoded execution data
    event RequestExtracted(bytes32 indexed requestHash, address transmitter, bytes execution);

    /// @notice Emitted when a request is fulfilled
    /// @param requestHash hash of the request
    /// @param fulfiller address of the fulfiller
    /// @param execution encoded execution data
    event RequestFulfilled(bytes32 indexed requestHash, address fulfiller, bytes execution);

    // emitted on the source once settlement completes
    /// @param requestHash hash of the request
    event RequestSettled(bytes32 indexed requestHash);

    /// @notice Emitted on the originChain when a request is withdrawn beyond fulfillment deadline
    /// @param requestHash hash of the request
    /// @param token token being withdrawn
    /// @param amount amount being withdrawn
    /// @param to address of the recipient
    event WithdrawOnOrigin(bytes32 indexed requestHash, address token, uint256 amount, address to);

    /// @notice Emitted on the destinationChain when a request is withdrawn if transmitter fails to fulfil
    /// @param requestHash hash of the request
    /// @param token token being withdrawn
    /// @param amount amount being withdrawn
    /// @param to address of the recipient
    event WithdrawOnDestination(bytes32 indexed requestHash, address token, uint256 amount, address to);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IFeeCollector {
    function registerFee(address feeTaker, uint256 feeAmount, address feeToken) external;
    function registerFee(address feeTaker, uint256 feeAmount, address feeToken, bytes32 requestHash) external;
    function settleFee(bytes32 requestHash) external;
    function refundFee(bytes32 requestHash, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {BasicRequest} from "../common/BungeeStructs.sol";

/// @notice helpers for handling CommandInfo objects
library BasicRequestLib {
    bytes internal constant BASIC_REQUEST_TYPE =
        abi.encodePacked(
            "BasicRequest(",
            "uint256 originChainId,",
            "uint256 destinationChainId,",
            "uint256 deadline,",
            "uint256 nonce,",
            "address sender,",
            "address receiver,",
            "address delegate,",
            "address bungeeGateway,",
            "uint32 switchboardId,",
            "address inputToken,",
            "uint256 inputAmount,",
            "address[] outputTokens,",
            "uint256[] minOutputAmounts)"
        );
    bytes32 internal constant BASIC_REQUEST_TYPE_HASH = keccak256(BASIC_REQUEST_TYPE);

    /// @notice Hash of BasicRequest struct on the origin chain
    /// @dev enforces originChainId to be the current chainId. Resulting hash would be the same on all chains.
    /// @dev helps avoid extra checking of chainId in the contract
    /// @param basicReq BasicRequest object to be hashed
    function originHash(BasicRequest memory basicReq) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BASIC_REQUEST_TYPE_HASH,
                    block.chainid,
                    basicReq.destinationChainId,
                    basicReq.deadline,
                    basicReq.nonce,
                    basicReq.sender,
                    basicReq.receiver,
                    basicReq.delegate,
                    basicReq.bungeeGateway,
                    basicReq.switchboardId,
                    basicReq.inputToken,
                    basicReq.inputAmount,
                    keccak256(abi.encodePacked(basicReq.outputTokens)),
                    keccak256(abi.encodePacked(basicReq.minOutputAmounts))
                )
            );
    }

    /// @notice Hash of BasicRequest struct on the destination chain
    /// @dev enforces destinationChain to be the current chainId. Resulting hash would be the same on all chains.
    /// @dev helps avoid extra checking of chainId in the contract
    /// @param basicReq BasicRequest object to be hashed
    function destinationHash(BasicRequest memory basicReq) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BASIC_REQUEST_TYPE_HASH,
                    basicReq.originChainId,
                    block.chainid,
                    basicReq.deadline,
                    basicReq.nonce,
                    basicReq.sender,
                    basicReq.receiver,
                    basicReq.delegate,
                    basicReq.bungeeGateway,
                    basicReq.switchboardId,
                    basicReq.inputToken,
                    basicReq.inputAmount,
                    keccak256(abi.encodePacked(basicReq.outputTokens)),
                    keccak256(abi.encodePacked(basicReq.minOutputAmounts))
                )
            );
    }
}