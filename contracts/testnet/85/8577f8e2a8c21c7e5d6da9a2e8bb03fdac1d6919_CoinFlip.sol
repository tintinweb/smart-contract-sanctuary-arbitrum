// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ISwitchboard} from "switchboard/ISwitchboard.sol";
import {SwitchboardCallbackHandler} from "switchboard/SwitchboardCallbackHandler.sol";

contract CoinFlip is SwitchboardCallbackHandler {
    ///////////////////
    // Errors
    ///////////////////
    error InvalidSender(address expected, address received);
    error MissingFunctionId();
    error InvalidFunction(address expected, address received);
    error InvalidRequest(uint256 requestId);
    error RequestAlreadyCompleted(uint256 requestId);
    error NotEnoughEthSent();
    error RandomnessResultOutOfBounds(uint256 result);
    error ActionBlocked();

    ///////////////////
    // Types
    ///////////////////
    enum GameType {
        NONE, // 0
        COIN_FLIP, // 1
        DICE_ROLL // 2
    }

    enum CoinFlipSelection {
        UNKNOWN, // should never be used
        HEADS,
        TAILS
    }

    struct CoinFlipRequest {
        address user;
        address callId;
        CoinFlipSelection guess;
        bool isWinner;
        bool isSettled;
        uint256 requestTimestamp;
        uint256 settledTimestamp;
    }

    struct FunctionRequestParams {
        uint256 gameType;
        address contractAddress;
        address user;
        uint256 requestId;
        uint256 requestTimestamp;
    }

    ///////////////////
    // State Variables
    ///////////////////
    uint256 private immutable i_entryFee;
    address private immutable i_functionId;
    uint256 private s_nextRequestId = 1;
    mapping(uint256 => CoinFlipRequest) public s_requests;
    ISwitchboard public switchboard;

    ///////////////////
    // Events
    ///////////////////
    event CoinFlipRequested(uint256 requestId, address callId, address user, address contractAddress);
    event CoinFlipSettled(uint256 requestId, address callId, address user, bool isWinner);

    ///////////////////
    // Modifiers
    ///////////////////

    ///////////////////
    // Functions
    ///////////////////
    constructor(address switchboardAddress, uint256 entryFee, address functionId) {
        i_entryFee = entryFee;
        i_functionId = functionId;
        switchboard = ISwitchboard(switchboardAddress);
    }

    // receive() external payable {
    //     revert ActionBlocked();
    // }

    // fallback() external payable {
    //     revert ActionBlocked();
    // }

    function coinFlipRequest(CoinFlipSelection guess) external payable {
        if (msg.value < i_entryFee) {
            revert NotEnoughEthSent();
        }

        uint256 nextRequestId = getCoinFlipNextRequestId();

        // encode the request parameters
        bytes memory encodedParams = abi.encode(
            FunctionRequestParams({
                gameType: uint256(GameType.COIN_FLIP),
                contractAddress: address(this),
                user: msg.sender,
                requestId: nextRequestId,
                requestTimestamp: block.timestamp
            })
        );

        address callId = switchboard.callFunction(i_functionId, encodedParams);

        s_requests[nextRequestId].user = msg.sender;
        s_requests[nextRequestId].callId = callId;
        s_requests[nextRequestId].guess = guess;
        s_requests[nextRequestId].requestTimestamp = block.timestamp;

        emit CoinFlipRequested(nextRequestId, callId, msg.sender, address(this));

        // increment
        s_nextRequestId++;
    }

    function coinFlipSettle(uint256 requestId, uint256 result) external isSwitchboardCaller isFunctionId {
        CoinFlipRequest storage request = s_requests[requestId];
        if (request.isSettled) {
            revert RequestAlreadyCompleted(requestId);
        }
        if (request.requestTimestamp == 0) {
            revert InvalidRequest(requestId);
        }

        request.settledTimestamp = block.timestamp;
        request.isSettled = true;

        CoinFlipSelection userResult = castCoinFlipSelection(result);

        bool isWinner = s_requests[requestId].guess == userResult;
        request.isWinner = isWinner;

        // TODO: if winner, pay out some reward. if loser, take some funds.

        // emit an event
        emit CoinFlipSettled(requestId, request.callId, request.user, isWinner);
    }

    ///////////////////////////////
    // External View Functions ////
    ///////////////////////////////
    function castCoinFlipSelection(uint256 input) public pure returns (CoinFlipSelection) {
        if (input == 1) {
            return CoinFlipSelection.HEADS;
        } else if (input == 2) {
            return CoinFlipSelection.TAILS;
        }

        revert RandomnessResultOutOfBounds(input);
    }

    function getNextRequestId() public view returns (uint256) {
        return s_nextRequestId;
    }

    function getCoinFlipEntryFee() public view returns (uint256) {
        return i_entryFee;
    }

    function getCoinFlipNextRequestId() public view returns (uint256) {
        return s_nextRequestId;
    }

    function getSbAddress() public view returns (address) {
        return address(switchboard);
    }

    function getSbFunctionId() public view returns (address) {
        return i_functionId;
    }

    function coinFlipRequestExists(uint256 requestId) public view returns (bool) {
        CoinFlipRequest memory request = requests(requestId);
        return request.requestTimestamp != 0;
    }

    function requests(uint256 requestId) public view returns (CoinFlipRequest memory request) {
        return s_requests[requestId];
    }

    // Needed for the SwitchboardCallbackHandler class
    function getSwithboardAddress() internal view override returns (address) {
        return address(switchboard);
    }

    function getSwitchboardFunctionId() internal view override returns (address) {
        return i_functionId;
    }

    function getAllRequests() public view returns (CoinFlipRequest[] memory) {
        CoinFlipRequest[] memory allRequests = new CoinFlipRequest[](s_nextRequestId);
        for (uint256 i = 0; i < s_nextRequestId; i++) {
            CoinFlipRequest memory request = s_requests[i];
            allRequests[i] = request;
        }

        return allRequests;
    }

    function getRequestIdsByUser(address user) public view returns (uint256[] memory) {
        uint256 userRequestCount = 0;
        uint256[] memory userRequestIds = new uint256[](s_nextRequestId);
        for (uint256 i = 0; i < s_nextRequestId; i++) {
            CoinFlipRequest memory request = s_requests[i];
            if (request.user == user) {
                userRequestIds[userRequestCount] = i;
                userRequestCount++;
            }
        }

        uint256[] memory parsedUserRequestIds = new uint256[](userRequestCount);
        for (uint256 i = 0; i < userRequestCount; i++) {
            parsedUserRequestIds[i] = userRequestIds[i];
        }

        return (parsedUserRequestIds);
    }

    function getRequestsByUser(address user) public view returns (uint256[] memory, CoinFlipRequest[] memory) {
        uint256[] memory userRequestIds = getRequestIdsByUser(user);

        CoinFlipRequest[] memory userRequests = new CoinFlipRequest[](userRequestIds.length);
        for (uint256 i = 0; i < userRequestIds.length; i++) {
            userRequests[i] = s_requests[userRequestIds[i]];
        }

        return (userRequestIds, userRequests);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISwitchboard {
    //=========================================================================
    // Events
    //=========================================================================

    // [Function Calls]
    event FunctionCallFund(address indexed functionId, address indexed funder, uint256 indexed amount);
    event FunctionCallEvent(address indexed functionId, address indexed sender, address indexed callId, bytes params);

    // [Functions]
    event FunctionFund(address indexed functionId, address indexed funder, uint256 indexed amount);
    event FunctionWithdraw(address indexed functionId, address indexed withdrawer, uint256 indexed amount);
    event FunctionAccountInit(address indexed authority, address indexed accountId);

    // [Attestation Queues]
    event AttestationQueueAccountInit(address indexed authority, address indexed accountId);
    event AddMrEnclave(address indexed queueId, bytes32 mrEnclave);
    event RemoveMrEnclave(address indexed queueId, bytes32 mrEnclave);
    event AttestationQueueSetConfig(address indexed queueId, address indexed authority);
    event AttestationQueuePermissionUpdated(
        address indexed queueId, address indexed granter, address indexed grantee, uint256 permission
    );

    // [Enclaves]
    event EnclaveAccountInit(address indexed signer, address indexed accountId);
    event EnclaveHeartbeat(address indexed enclaveId, address indexed signer);
    event EnclaveGC(address indexed enclaveId, address indexed queue);
    event EnclavePayoutEvent(address indexed nodeId, address indexed enclaveId, uint256 indexed amount);
    event EnclaveVerifyRequest(address indexed queueId, address indexed verifier, address indexed verifiee);
    event EnclaveRotateSigner(address indexed queueId, address indexed oldSigner, address indexed newSigner);

    // 0x863b154f
    error AggregatorDoesNotExist(address aggregatorId);

    // 0xaf9b8e16
    error OracleQueueDoesNotExist(address oracleQueueId);

    // 0xcf479181
    error InsufficientBalance(uint256 expectedBalance, uint256 receivedBalance);

    // 0xe65d3ee3
    error AggregatorAlreadyExists(address aggregatorId);

    // 0x07fefd1f
    error OracleAlreadyExists(address oracleId);

    // 0x8f939dfd
    error OracleExpired(address oracleId);

    // 0xbf89df83
    error InvalidAuthority(address expectedAuthority, address receivedAuthority);

    // 0x8f939dfd
    error InvalidSigner(address expectedSigner, address receivedSigner);

    // 0xd14e7c9b
    error InvalidArgument(uint256 argumentIndex);

    // 0xe65cb5d3
    error PermissionDenied(address granter, address grantee, uint256 permission);

    // 0x53b15160
    error InsufficientSamples(uint256 expected, uint256 received);

    // 0x9fcea1ba
    error EarlyOracleResponse(address oracleId);

    // 0xedfa5607
    error IntervalHistoryNotRecorded(address aggregatorId);

    // 0x93fc1a13
    error MrEnclaveNotAllowed(address queueId, bytes32 mrEnclave);

    // 0x2b69267c
    error QueuesDoNotMatch(address expectedQueueId, address receivedQueueId);

    // 0x9eb833a0
    error EnclaveUnverified(address enclaveId);

    // 0x089afb2c
    error EnclaveNotReadyForVerification(address enclaveId);

    // 0x4d7fe4fc
    error EnclaveNotOnQueue(address queueId, address enclaveId);

    // 0x1967584e
    error EnclaveNotAtQueueIdx(address queueId, address enclaveId, uint256 enclaveIdx);

    // 0xcd5d2b06
    error OracleNotOnQueue(address queueId, address oracleId);

    // 0x6dddf077
    error OracleNotAtQueueIdx(address queueId, address oracleId, uint256 oracleIdx);

    // 0x8bec1a4e
    error InvalidEnclave(address enclaveId);

    // 0xbc41a993
    error EnclaveExpired(address enclaveId);

    // 0x0da329cf
    error AttestationQueueDoesNotExist(address attestationQueueId);

    // 0x5c3197cc
    error EnclaveDoesNotExist(address enclaveId);

    // 0x3c3b1d62
    error FunctionDoesNotExist(address functionId);

    // 0x3af924d6
    error EnclaveAlreadyExists(address enclaveId);

    // 0x1179fb25
    error AttestationQueueAlreadyExists(address attestationQueueId);

    // 0x8f939dfd
    error FunctionAlreadyExists(address functionId);

    // 0x3c1222b1
    error InsufficientNodes(uint256 expected, uint256 received);

    // 0x887efaa5
    error InvalidEntry();

    // 0x1935f531
    error GasLimitExceeded(uint256 limit, uint256 used);

    // 0x6634e923
    error TransactionExpired(uint256 expirationTime);

    // 0xd1d36dcd
    error AlreadyExecuted(bytes32 txHash);

    // 0xd491963d
    error InvalidSignature(address expectedSender, bytes32 txHash, bytes signature);

    // 0x3926c8c8
    error FunctionCallerNotPermitted(address functionId, address sender);

    // 0x552d918e
    error FunctionMrEnclaveMismatch(bytes32 expected, bytes32 received);

    // 0xe2c62da7
    error FunctionSignerAlreadySet(address current, address received);

    // 0x3c3b1d62
    error FunctionFeeTooLow(address functionId, uint256 expected, uint256 received);

    // 0x3c3b1d62
    error FunctionIncorrectTarget(address functionId, address received);

    // 0x3ff1de92
    error IncorrectReportedTime(uint256 maxExpectedTime, uint256 reportedTime);

    // 0xc7d91853
    error SubmittedResultsMismatch(uint256 aggregators, uint256 results);

    // 0xb209a6cc
    error ForceOverrideNotReady(address queueId);

    // 0xee56daf8
    error InvalidStatus(address account, uint256 expected, uint256 received);

    // 0x67c42515
    error ExcessiveGasSpent(uint256 gasLimit, uint256 gasSpent);

    // 0x00ea207e
    error ACLNotAdmin(address account);

    // 0xea9a4ba0
    error ACLNotAllowed(address account);

    // 0x7373cb0d
    error ACLAdminAlreadyInitialized();

    // 0x8f939dfd
    error IncorrectToken(address expected, address received);
    error TokenTransferFailure(address token, address to, uint256 amount);
    error StakeNotReady(address queueId, address staker, uint256 readyAt);
    error StakeNotReadyForWithdrawal(address queueId, address staker, uint256 readyAt);
    error EnclaveNotFullyStaked(address enclaveId);

    //=========================================================================
    // Structs
    //=========================================================================

    // [Function Calls]
    struct FunctionCall {
        address functionId;
        address caller;
        uint256 timestamp;
        bytes callData;
        bool executed;
        uint256 consecutiveFailures;
        uint256 feePaid;
    }

    struct FunctionCallSettings {
        // require the function call to pay the estimated run cost fee
        bool requireEstimatedRunCostFee;
        // minimum fee that a function call must pay
        uint256 minimumFee;
        // maximum gas cost that a function call can cost
        uint256 maxGasCost;
        // fail calls if the caller does not pay the full cost of the call
        bool requireCallerPayFullCost;
        // requires the callback target to be the caller contract
        bool requireSenderBeReturnAddress;
    }

    // [Functions]
    enum FunctionStatus {
        NONE,
        ACTIVE,
        NON_EXECUTABLE,
        EXPIRED,
        OUT_OF_FUNDS,
        INVALID_PERMISSIONS,
        DEACTIVATED
    }

    struct SbFunction {
        string name;
        address authority;
        address enclaveId;
        address queueId;
        uint256 balance;
        FunctionStatus status;
        FunctionConfig config;
        FunctionState state;
    }

    struct FunctionConfig {
        string schedule;
        address[] permittedCallers;
        string containerRegistry;
        string container;
        string version;
        string paramsSchema;
        bytes32[] mrEnclaves;
        bool allowAllFnCalls;
        bool useFnCallEscrow;
    }

    struct FunctionState {
        uint256 consecutiveFailures;
        uint256 lastExecutionTimestamp;
        uint256 nextAllowedTimestamp;
        uint256 lastExecutionGasCost;
        uint256 triggeredSince; // first call time in seconds
        uint256 triggerCount; // number of calls
        // queueIdx should only be referenced off-chain
        // - and only with modulo queue length in case the queue is resized
        uint256 queueIdx;
        bool triggered;
        uint256 createdAt;
    }

    // [Attestation Queues]
    struct AttestationQueue {
        address authority;
        address[] data;
        uint256 maxSize;
        uint256 reward;
        uint256 lastHeartbeat;
        bytes32[] mrEnclaves;
        uint256 maxEnclaveVerificationAge;
        uint256 allowAuthorityOverrideAfter;
        uint256 maxConsecutiveFunctionFailures;
        bool requireAuthorityHeartbeatPermission; // require heartbeat permission to heartbeat
        bool requireUsagePermissions; // require permissions to enclave verify
        // queue state tracking
        uint256 enclaveTimeout;
        uint256 gcIdx;
        uint256 currIdx;
    }

    // [Enclaves]
    enum VerificationStatus {
        PENDING,
        FAILURE,
        SUCCESS,
        OVERRIDE
    }

    struct Enclave {
        address signer;
        address authority;
        address queueId;
        bytes cid;
        VerificationStatus verificationStatus;
        uint256 verificationTimestamp;
        uint256 validUntil;
        bytes32 mrEnclave;
        // verifiers
        bool isOnQueue;
        uint256 lastHeartbeat;
        // balance of the Enclave
        uint256 balance;
    }

    //=========================================================================
    // User Functions
    //=========================================================================

    // [Function Calls]

    /**
     * Call a function with params - and pay into the function's escrow (if applicable)
     * @param functionId the function's id to be called
     * @param params arbitrary data encoded and passed to the function (for off-chain use)
     * @return callId the call's id
     * @dev reverts if the function does not exist
     * @dev reverts if the caller's address is not allowed to call the function
     * @dev reverts if the function isn't called with enough funding
     * @dev emits FunctionCallEvent
     * @dev emits FunctionCallFund if the function call is funded
     */
    function callFunction(address functionId, bytes calldata params) external payable returns (address callId);

    /**
     * Get estimated run cost for a function (based on last run + gas price)
     * - this is just supposed to predict gas cost of running a function
     * @param functionId the function's id
     * @param gasPrice the gas price to use for the estimate
     */
    function estimatedRunCost(address functionId, uint256 gasPrice) external view returns (uint256);

    /**
     * Set parameters around calling functions - each of these defaults to 0 / false / empty
     * @param functionId the function's id
     * @param requireEstimatedRunCostFee require that the payment be at least the estimated run cost
     * (uses recent runs for gas cost estimation, so first is the least expensive)
     * @param minimumFee minimum fee that a function caller must pay
     * @param maxGasCost maximum gas cost that a function run can cost
     * @param requireCallerPayFullCost require that the caller pay the full cost of the call
     * @param requireSenderBeReturnAddress require that the callback target be the caller contract
     * @dev reverts if the caller is not the function's authority
     */
    function setFunctionCallSettings(
        address functionId,
        bool requireEstimatedRunCostFee,
        uint256 minimumFee,
        uint256 maxGasCost,
        bool requireCallerPayFullCost,
        bool requireSenderBeReturnAddress
    ) external;

    /**
     * Get a function call by callId
     * @param callId the call's id
     * @return FunctionCall struct for the call
     */
    function functionCalls(address callId) external view returns (FunctionCall memory);

    /**
     * Get a function call's settings
     * @param functionId the function's id
     * @return FunctionCallSettings struct for the function
     */
    function functionCallSettings(address functionId) external view returns (FunctionCallSettings memory);

    // [Functions]

    /**
     * Create a function with a particular id
     * @param functionId the function's id
     * @param name name exposed to the Switchboard Explorer
     * @param authority the function's authority
     * @param queueId the function's queue (which will resolve function runs)
     * @param containerRegistry "dockerhub"
     * @param container container name, ex: "switchboardlabs/function-example"
     * @param version container version tag, ex: "latest"
     * @param schedule cron schedule, ex: "0 * * * *"
     * @param paramsSchema json schema for the function's params
     * @param permittedCallers array of addresses that are allowed to call the function (empty array for all)
     * @dev emits FunctionAccountInit event
     */
    function createFunctionWithId(
        address functionId,
        string calldata name,
        address authority,
        address queueId,
        string calldata containerRegistry,
        string calldata container,
        string calldata version,
        string calldata schedule,
        string calldata paramsSchema,
        address[] calldata permittedCallers
    ) external payable;

    /**
     * Set parameters around calling functions - each of these defaults to 0 / false / empty
     * @param functionId the function's id
     * @param name name exposed to the Switchboard Explorer
     * @param authority the function's authority
     * @param containerRegistry "dockerhub"
     * @param container container name, ex: "switchboardlabs/function-example"
     * @param version container version tag, ex: "latest"
     * @param schedule cron schedule, ex: "0 * * * *"
     * @param paramsSchema json schema for the function's params
     * @param permittedCallers array of addresses that are allowed to call the function (empty array for all)
     * @dev reverts if the caller is not the function's authority
     */
    function setFunctionConfig(
        address functionId,
        string calldata name,
        address authority,
        string calldata containerRegistry,
        string calldata container,
        string calldata version,
        string calldata schedule,
        string calldata paramsSchema,
        address[] calldata permittedCallers
    ) external;

    /**
     * Fund a function's escrow
     * @param accountId the function's id
     * @dev emits FunctionFund event
     */
    function functionEscrowFund(address accountId) external payable;

    /**
     * Withdraw from a function's escrow
     * @param recipient recipient address
     * @param functionId the function's id
     * @param amount the amount to withdraw
     * @dev reverts if the caller is not the function's authority
     * @dev emits FunctionWithdraw event
     */
    function functionEscrowWithdraw(address payable recipient, address functionId, uint256 amount) external;

    /**
     * Check if function exists
     * @param functionId the function's id
     * @return bool true if the function exists
     */
    function functionExists(address functionId) external view returns (bool);

    /**
     * Get a function by id
     * @param functionId the function's id
     * @return SbFunction struct for the function
     */
    function funcs(address functionId) external view returns (SbFunction memory);

    /**
     * Get the allowed callers for a function
     * @param functionId the function's id
     */
    function getFunctionPermittedCallers(address functionId) external view returns (address[] memory);

    /**
     * Get all functions and their addresses
     * @return address[] array of function ids
     * @return SbFunction[] array of functions
     * @dev addresses returned and functions returned will be the same length
     */
    function getAllFunctions() external view returns (address[] memory, SbFunction[] memory);

    /**
     * Get all functions by authority and their addresses
     * @param user the user's address
     * @return address[] array of function ids
     * @return SbFunction[] array of functions
     * @dev addresses returned and functions returned will be the same length
     */
    function getFunctionsByAuthority(address user) external view returns (address[] memory, SbFunction[] memory);

    /**
     * Get the allowed enclave measurements for a function
     * @param functionId the function's id
     */
    function getFunctionMrEnclaves(address functionId) external view returns (bytes32[] memory);

    /**
     * Add an allowed enclave measurement to a function
     * @param functionId the function's id
     * @param mrEnclave the enclave measurement
     * @dev reverts if the caller is not the function's authority
     */
    function addMrEnclaveToFunction(address functionId, bytes32 mrEnclave) external;

    /**
     * Remove an enclave measurement from a function
     * @param functionId the function's id
     * @param mrEnclave the enclave measurement to remove
     * @dev reverts if the caller is not the function's authority
     */
    function removeMrEnclaveFromFunction(address functionId, bytes32 mrEnclave) external;

    // [Attestation Queues]

    /**
     * Get an attestation queue by id
     * @param queueId queue's id
     * @return AttestationQueue struct
     */
    function attestationQueues(address queueId) external view returns (AttestationQueue memory);

    // [Enclaves]

    /**
     * Get an enclave by ID
     * @param enclaveId the enclave's id
     */
    function enclaves(address enclaveId) external view returns (Enclave memory);

    //=========================================================================
    // Switchboard Internal Functions
    //=========================================================================

    // [Attestation Queues]

    /**
     * Check if an attestation queue allows a particular enclave measurement to verify
     * @param queueId the queue's id
     * @param mrEnclave the enclave measurement
     * @return bool true if the queue allows the enclave to verify
     */
    function attestationQueueHasMrEnclave(address queueId, bytes32 mrEnclave) external view returns (bool);

    /**
     * Get an enclave's index on the Attestation Queue
     * @param enclaveId the enclave's id
     * @return int256 the enclave's index on the queue
     * @dev returns -1 if the enclave is not on the queue
     */
    function getEnclaveIdx(address enclaveId) external view returns (int256);

    /**
     * Get all allowed enclave measurements for a given queue
     * @param queueId the queue's id
     * @return bytes32[] array of enclave measurements
     */
    function getAttestationQueueMrEnclaves(address queueId) external view returns (bytes32[] memory);

    /**
     * Get an array of all enclaves on a given queue
     * @param queueId the queue's id
     */
    function getEnclaves(address queueId) external view returns (address[] memory);

    /**
     * Create an Attestation Queue
     * @param authority the queue's authority
     * @param maxSize max number of enclaves allowed on the queue
     * @param reward reward for enclave verification
     * @param enclaveTimeout time in seconds before an enclave is timed out
     * @param maxEnclaveVerificationAge max age in seconds for an enclave verification
     * @param allowAuthorityOverrideAfter time in seconds before the authority can override an enclave
     * @param requireAuthorityHeartbeatPermission require authority permissions for enclave heartbeat
     * @param requireUsagePermissions require permissions for using the queue
     * @param maxConsecutiveFunctionFailures max number of consecutive function failures before an enclave is timed out
     * @dev emits AttestationQueueAccountInit event
     */
    function createAttestationQueue(
        address authority,
        uint256 maxSize,
        uint256 reward,
        uint256 enclaveTimeout,
        uint256 maxEnclaveVerificationAge,
        uint256 allowAuthorityOverrideAfter,
        bool requireAuthorityHeartbeatPermission,
        bool requireUsagePermissions,
        uint256 maxConsecutiveFunctionFailures
    ) external;

    /**
     * Set an Attestation Queue's config
     * @param queueId the queue's id
     * @param authority the queue's authority
     * @param maxSize max number of enclaves allowed on the queue
     * @param reward reward for enclave verification
     * @param enclaveTimeout time in seconds before an enclave is timed out
     * @param maxEnclaveVerificationAge max age in seconds for an enclave verification
     * @param allowAuthorityOverrideAfter time in seconds before the authority can override an enclave
     * @param requireAuthorityHeartbeatPermission require authority permissions for enclave heartbeat
     * @param requireUsagePermissions require permissions for using the queue
     * @param maxConsecutiveFunctionFailures max number of consecutive function failures before an enclave is timed out
     * @dev reverts if the caller is not the queue's authority
     * @dev emits AttestationQueueSetConfig event
     */
    function setAttestationQueueConfig(
        address queueId,
        address authority,
        uint256 maxSize,
        uint256 reward,
        uint256 enclaveTimeout,
        uint256 maxEnclaveVerificationAge,
        uint256 allowAuthorityOverrideAfter,
        bool requireAuthorityHeartbeatPermission,
        bool requireUsagePermissions,
        uint256 maxConsecutiveFunctionFailures
    ) external;

    /**
     * Add an enclave measurement to an attestation queue
     * @param queueId the queue's id
     * @param mrEnclave the enclave measurement
     * @dev reverts if the caller is not the queue's authority
     * @dev emits AddMrEnclave event
     */
    function addMrEnclaveToAttestationQueue(address queueId, bytes32 mrEnclave) external;

    /**
     * Remove an enclave measurement from an attestation queue
     * @param queueId the queue's id
     * @param mrEnclave the enclave measurement
     * @dev reverts if the caller is not the queue's authority
     * @dev emits RemoveMrEnclave event
     */
    function removeMrEnclaveFromAttestationQueue(address queueId, bytes32 mrEnclave) external;

    /**
     * Set an attestation queue's permissions
     * @param queueId the queue's id
     * @param grantee the address to grant permissions to
     * @param permission the permission to grant
     * @param on true if the permission should be granted
     * @dev reverts if the caller is not the queue's authority
     * @dev emits AttestationQueuePermissionUpdated event
     */
    function setAttestationQueuePermission(address queueId, address grantee, uint256 permission, bool on) external;

    // [Enclaves]

    /**
     * Get a signer's associated enclaveId
     * @param signer the enclave's signer
     * @return enclaveId the enclave's id
     * @dev returns address(0) if the enclave does not exist
     */
    function enclaveSignerToEnclaveId(address signer) external view returns (address);

    /**
     * Validate that a signer has a valid queue
     * @param signer signer's address
     * @param attestationQueueId the queue's id
     * @param validMeasurements  array of valid enclave measurements
     * @dev reverts if the signer does not have a valid enclave
     */
    function validate(address signer, address attestationQueueId, bytes32[] memory validMeasurements) external view;

    /**
     * Check if an enclave is valid
     * @param enclaveId the enclave's id
     * @return bool true if the enclave is valid
     */
    function isEnclaveValid(address enclaveId) external view returns (bool);

    /**
     * Create an enclave account
     * @param signer the enclave's signer address
     * @param queueId the enclave's queue
     * @param authority the enclave authority
     * @dev emits EnclaveAccountInit event
     */
    function createEnclave(address signer, address queueId, address authority) external;

    /**
     * Create an enclave account with a particular Id
     * @param enclaveId the enclave's id
     * @param signer the enclave's signer address
     * @param queueId the enclave's queue
     * @param authority the enclave authority
     * @dev emits EnclaveAccountInit event
     */
    function createEnclaveWithId(address enclaveId, address signer, address queueId, address authority) external;

    /**
     * @param enclaveId the enclave's id
     * @param cid the quote content address
     * @dev emits EnclaveVerifyRequest
     */
    function updateEnclave(address enclaveId, bytes calldata cid) external payable;

    /**
     * Override an enclave's verification status to initialize a queue
     * @param enclaveId the enclave's id
     * @dev reverts if the caller is not the queue's authority
     */
    function forceOverrideVerify(address enclaveId) external;

    /**
     * Try garbage collecting an enclave from a queue
     * @param enclaveId the enclave to gc
     * @param enclaveIdx the enclave's index on the queue
     * @dev emits EnclaveGC if the enclave is garbage collected
     */
    function enclaveGarbageCollect(address enclaveId, uint256 enclaveIdx) external;

    /**
     * Fail an enclave / deny verification
     * @param verifierId the verifying enclave's id
     * @param enclaveId enclave id
     * @param verifierIdx the verifier's index on the queue
     * @dev emits EnclavePayoutEvent
     */
    function failEnclave(address verifierId, address enclaveId, uint256 verifierIdx) external;

    /**
     * Verify enclave
     * @param verifierId verifying enclave id
     * @param enclaveId enclave id to verify
     * @param enclaveIdx verifier's index on the queue
     * @param timestamp timestamp of the verification
     * @param mrEnclave enclave measurement
     * @dev emits EnclavePayoutEvent
     */
    function verifyEnclave(
        address verifierId,
        address enclaveId,
        uint256 enclaveIdx,
        uint256 timestamp,
        bytes32 mrEnclave
    ) external;

    /**
     * Heartbeat enclave onto queue
     * @param enclaveId enclave id
     * @dev emits EnclaveHeartbeat event
     * @dev emits EnclaveGC event if the enclave is garbage collected
     */
    function enclaveHeartbeat(address enclaveId) external;

    /**
     * Swap enclave signers
     * @param enclaveId enclave id
     * @param newSigner new signer address
     * @dev will require an enclave verification or force override to actually heartbeat
     * @dev emits EnclaveRotateSigner
     */
    function rotateEnclaveSigner(address enclaveId, address newSigner) external;

    // [Function Calls]
    /**
     * Get all active functions by queue id
     * @param queueId the queue's id
     * @return address[] array of function ids on the queue (in order)
     * @return FunctionCall[] array of function calls on the queue (in order)
     * @dev addresses returned and functionCalls returned will be the same length
     */
    function getActiveFunctionCallsByQueue(address queueId)
        external
        view
        returns (address[] memory, FunctionCall[] memory);

    // [Functions]
    /**
     * Create a function with a particular id
     * @param name name exposed to the Switchboard Explorer
     * @param authority the function's authority
     * @param queueId the function's queue (which will resolve function runs)
     * @param containerRegistry "dockerhub"
     * @param container container name, ex: "switchboardlabs/function-example"
     * @param version container version tag, ex: "latest"
     * @param schedule cron schedule, ex: "0 * * * *"
     * @param paramsSchema json schema for the function's params
     * @param permittedCallers array of addresses that are allowed to call the function (empty array for all)
     * @dev emits FunctionAccountInit event
     */
    function createFunction(
        string calldata name,
        address authority,
        address queueId,
        string calldata containerRegistry,
        string calldata container,
        string calldata version,
        string calldata schedule,
        string calldata paramsSchema,
        address[] calldata permittedCallers
    ) external payable;

    /**
     * Get all active functions by queue id
     * @param queueId the queue's id
     * @return address[] array of function ids on the queue (in order)
     * @return SbFunction[] array of functions on the queue (in order)
     * @dev addresses returned and functions returned will be the same length
     */
    function getActiveFunctionsByQueue(address queueId) external view returns (address[] memory, SbFunction[] memory);

    /**
     * Get the eip712 hash for a function call
     * @param expirationTimeSeconds revert if past this time in seconds
     * @param gasLimit gas limit for the function call
     * @param value value to send with the function call
     * @param to the target for this function call
     * @param from the caller for this function call
     * @param data the encoded function call data
     * @return bytes32 the eip712 hash
     */
    function getTransactionHash(
        uint256 expirationTimeSeconds,
        uint256 gasLimit,
        uint256 value,
        address to,
        address from,
        bytes calldata data
    ) external view returns (bytes32);

    /**
     * Account for function run and execute function call
     * @param enclaveIdx enclave idx on the queue
     * @param functionId the function's id
     * @param delegatedSignerAddress the delegated signer's address (enclave signer)
     * @param observedTime the observed time of the function call
     * @param nextAllowedTimestamp the next allowed timestamp for the function call
     * @param isFailure true if the function call failed
     * @param mrEnclave enclave measurement
     * @param transactionsData array of transaction data
     * @param signatures array of signatures
     * @dev reverts if the caller is not a verified enclave authority
     */
    function functionVerify(
        uint256 enclaveIdx,
        address functionId,
        address delegatedSignerAddress,
        uint256 observedTime,
        uint256 nextAllowedTimestamp,
        bool isFailure,
        bytes32 mrEnclave,
        bytes32[] calldata transactionsData,
        bytes[] calldata signatures
    ) external;

    /**
     * Account for function run and execute function call, resolving a number of FuncionCalls
     * @param enclaveIdx enclave idx on the queue
     * @param functionId the function's id
     * @param delegatedSignerAddress the delegated signer's address (enclave signer)
     * @param observedTime the observed time of the function call
     * @param nextAllowedTimestamp the next allowed timestamp for the function call
     * @param isFailure true if the function call failed
     * @param mrEnclave enclave measurement
     * @param transactionsData array of transaction data
     * @param signatures array of signatures
     * @param functionCallIds array of function call ids
     * @dev reverts if the caller is not a verified enclave authority
     */
    function functionVerifyRequest(
        uint256 enclaveIdx,
        address functionId,
        address delegatedSignerAddress,
        uint256 observedTime,
        uint256 nextAllowedTimestamp,
        bool isFailure,
        bytes32 mrEnclave,
        bytes32[] calldata transactionsData,
        bytes[] calldata signatures,
        address[] calldata functionCallIds
    ) external;

    /**
     * Execute function call
     * @param transactionsData array of transaction data
     * @param signatures array of signatures
     * @dev reverts if the caller is not allocated permissions by admin
     */
    function forward(bytes32[] calldata transactionsData, bytes[] calldata signatures) external payable;

    /**
     * Deactivate a function - can only be called by queue authority
     * @param functionId function id for deactivation
     */
    function setFunctionDeactivated(address functionId) external;

    /**
     * Set the tolerated discrepancy between enclave reported time and on-chain time
     * @param tolerance the tolerance in seconds
     * @dev can only be called by contract admin
     */
    function setToleratedTimestampDiscrepancy(uint256 tolerance) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @title SwitchboardCallbackHandler
/// @author
/// @notice This contract provides modifiers which can optionally be overridden to allow Switchboard Function consumers to validate whether a instruction was invoked from the Switchboard program and corresponds to an expected functionId.
abstract contract SwitchboardCallbackHandler {
    error SwitchboardCallbackHandler__MissingFunctionId();
    error SwitchboardCallbackHandler__InvalidSender(address expected, address received);
    error SwitchboardCallbackHandler__InvalidFunction(address expected, address received);

    function getSwithboardAddress() internal view virtual returns (address);
    function getSwitchboardFunctionId() internal view virtual returns (address);

    modifier isSwitchboardCaller() virtual {
        address expectedSbAddress = getSwithboardAddress();
        address payable receivedCaller = payable(msg.sender);
        if (receivedCaller != expectedSbAddress) {
            revert SwitchboardCallbackHandler__InvalidSender(expectedSbAddress, receivedCaller);
        }
        _;
    }

    modifier isFunctionId() virtual {
        address expectedFunctionId = getSwitchboardFunctionId();

        if (msg.data.length < 20) {
            revert SwitchboardCallbackHandler__MissingFunctionId();
        }

        address receivedFunctionId;
        assembly {
            receivedFunctionId := shr(96, calldataload(sub(calldatasize(), 20)))
        }

        if (receivedFunctionId != expectedFunctionId) {
            revert SwitchboardCallbackHandler__InvalidFunction(expectedFunctionId, receivedFunctionId);
        }
        _;
    }
}