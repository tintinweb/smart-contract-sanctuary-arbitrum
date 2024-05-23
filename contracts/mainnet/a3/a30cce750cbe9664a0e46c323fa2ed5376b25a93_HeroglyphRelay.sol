// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IHeroglyphRelay } from "./IHeroglyphRelay.sol";
import { HeroglyphAttestation } from "./../HeroglyphAttestation.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SendNativeHelper } from "./../SendNativeHelper.sol";

import { ITickerOperator } from "./../identity/ITickerOperator.sol";
import { ITicker } from "./../identity/ticker/ITicker.sol";
import { IdentityRouter } from "./../identity/wallet/IdentityRouter.sol";
import { IDelegation } from "./../identity/wallet/delegation/IDelegation.sol";

/**
 * @title HeroglyphRelay
 * @notice The bridge between off-chain and on-chain execution. It receives graffiti metadata and executes based on its
 * parameters.
 * Since the graffiti originates from the block producer, we reward attestors of this block by
 * giving them "HeroglyphAttestation" tokens. Note: The miner won't receive any `HeroglyphAttestation` token.
 *
 * "HeroglyphAttestation" tokens can be redeemed for one of our own tokens that will be available at launch.
 * Other projects might have a redemption mechanism in place too.
 *
 * A "Ticker" can revert if it:
 * 1. Exceeds the gas limit,
 * 2. Fails to pay the fee, or
 * 3. Is invalid (empty address or not inheriting the ITickerOperation.sol interface),
 * we revert and continue to the next one in the list. Tickers are optional.
 *
 * See IHeroglyphRelay for function docs
 */
contract HeroglyphRelay is IHeroglyphRelay, Ownable, SendNativeHelper {
    uint32 public constant GAS_LIMIT_MINIMUM = 50_000;

    IdentityRouter public identityRouter;
    ITicker public tickers;
    address public dedicatedMsgSender;
    address public treasury;

    uint32 public lastBlockMinted;
    uint32 public gasLimitPerTicker;
    uint128 public executionFee;

    modifier onlyDedicatedMsgSender() {
        if (msg.sender != dedicatedMsgSender) revert NotDedicatedMsgSender();

        _;
    }

    constructor(
        address _owner,
        address _identityRouter,
        address _dedicatedMsgSender,
        address _tickers,
        address _treasury
    ) Ownable(_owner) {
        dedicatedMsgSender = _dedicatedMsgSender;
        identityRouter = IdentityRouter(_identityRouter);
        tickers = ITicker(_tickers);
        treasury = _treasury;

        gasLimitPerTicker = 400_000;
    }

    function executeRelay(GraffitiData[] calldata _graffities)
        external
        override
        onlyDedicatedMsgSender
        returns (uint256 totalOfExecutions_)
    {
        if (_graffities.length == 0) revert EmptyGraffities();

        uint32 cachedGasLimit = gasLimitPerTicker;
        uint32 lastBlockMintedCached = lastBlockMinted;
        uint128 cachedExecutionFee = executionFee;

        GraffitiData memory _graffiti;
        ITicker.TickerMetadata memory tickerData;
        uint32 mintedBlock;
        address validator;
        string[] memory tickerNames;
        uint32[] memory lzEndpoints;
        uint32 arraysLength;
        string memory tickerName;
        address tickerTarget;
        uint32 lzEndpointId;
        bool shouldBeSurrender;
        string memory validatorName;
        bool isDelegation;

        for (uint256 i = 0; i < _graffities.length; ++i) {
            _graffiti = _graffities[i];
            mintedBlock = _graffiti.mintedBlock;
            validatorName = _graffiti.validatorName;

            if (mintedBlock <= lastBlockMintedCached) continue;
            lastBlockMintedCached = mintedBlock;

            (validator, isDelegation) = identityRouter.getWalletReceiver(validatorName, _graffiti.validatorIndex);
            if (validator == address(0)) continue;

            tickerNames = _graffiti.tickers;
            lzEndpoints = _graffiti.lzEndpointTargets;
            arraysLength = uint32(lzEndpoints.length);

            if (tickerNames.length != arraysLength) continue;

            for (uint16 x = 0; x < arraysLength; ++x) {
                tickerName = tickerNames[x];
                lzEndpointId = lzEndpoints[x];

                (tickerData, shouldBeSurrender) = tickers.getTickerMetadata(0, tickerName);

                tickerTarget = tickerData.contractTarget;

                if (tickerTarget == address(0) || shouldBeSurrender || tickerData.price == 0) continue;

                try this.callTicker(
                    tickerTarget, cachedGasLimit, cachedExecutionFee, lzEndpointId, mintedBlock, validator
                ) {
                    emit TickerExecuted(tickerName, validator, mintedBlock, tickerTarget, lzEndpointId);

                    if (isDelegation) {
                        IDelegation(validator).snapshot(validatorName, _graffiti.validatorIndex, tickerTarget);
                    }
                } catch (bytes memory errorCode) {
                    emit TickerReverted(tickerName, tickerTarget, errorCode);
                    continue;
                }
            }

            ++totalOfExecutions_;
            emit BlockExecuted(mintedBlock, _graffiti.slotNumber, validator, _graffiti.graffitiText);
        }

        if (totalOfExecutions_ == 0) revert NoGraffitiExecution();

        lastBlockMinted = lastBlockMintedCached;

        _sendNative(treasury, address(this).balance, false);

        return totalOfExecutions_;
    }

    function callTicker(
        address _ticker,
        uint32 _gasLimit,
        uint128 _executionFee,
        uint32 _lzEndpointSelected,
        uint32 _blockNumber,
        address _identityReceiver
    ) external {
        if (msg.sender != address(this)) revert NoPermission();

        uint128 balanceBefore = uint128(address(this).balance);

        ITickerOperator(_ticker).onValidatorTriggered{ gas: _gasLimit }(
            _lzEndpointSelected, _blockNumber, _identityReceiver, _executionFee
        );

        uint128 balanceNow = uint128(address(this).balance) - balanceBefore;
        if (balanceNow < _executionFee) revert NotRefunded();
    }

    function updateGasLimitPerTicker(uint32 _gasPerTicker) external onlyOwner {
        if (_gasPerTicker < GAS_LIMIT_MINIMUM) revert GasLimitTooLow();

        gasLimitPerTicker = _gasPerTicker;
        emit GasPerTickerUpdated(_gasPerTicker);
    }

    function updateExecutionFee(uint128 _executionFee) external onlyOwner {
        executionFee = _executionFee;
        emit ExecutionFeeUpdated(_executionFee);
    }

    function updateDedicatedMsgSender(address _msg) external onlyOwner {
        dedicatedMsgSender = _msg;
        emit DedicatedMsgSenderUpdated(_msg);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert MissingTreasury();

        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function updateIdentityRouter(address _identityRouter) external onlyOwner {
        identityRouter = IdentityRouter(_identityRouter);
        emit IdentityRouterUpdated(_identityRouter);
    }

    function updateTickers(address _tickers) external onlyOwner {
        tickers = ITicker(_tickers);
        emit TickersUpdated(_tickers);
    }

    function withdrawETH(address _to) external onlyOwner {
        _sendNative(_to, address(this).balance, true);
    }

    receive() external payable { }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IHeroglyphRelay {
    error EmptyGraffities();
    error NoGraffitiExecution();
    error NoPermission();
    error NotRefunded();
    error NotDedicatedMsgSender();
    error MissingTreasury();
    error GasLimitTooLow();

    event BlockExecuted(
        uint32 indexed blockNumber, uint32 indexed slotNumber, address indexed validator, string graffiti
    );
    event TickerReverted(string indexed tickerName, address indexed contractTarget, bytes error);
    event TickerExecuted(
        string indexed tickerName,
        address indexed validatorWithdrawer,
        uint256 indexed blockNumber,
        address linkedContract,
        uint32 lzEndpointSelected
    );
    event ExecutionFeeUpdated(uint128 _fee);
    event GasPerTickerUpdated(uint32 _gas);
    event DedicatedMsgSenderUpdated(address indexed dedicatedMsgSender);
    event TreasuryUpdated(address indexed treasury);
    event IdentityRouterUpdated(address identityRouter);
    event TickersUpdated(address tickers);

    struct AttestationEpoch {
        uint32[] blockNumbers;
        bytes32[] blockAttestorsRoot;
        bool isCompleted;
    }

    struct GraffitiData {
        string validatorName; // validator identity name
        string[] tickers; // tickers in the graffiti, can be empty
        uint32[] lzEndpointTargets; //lzEndpointTargets for each tickers
        uint32 mintedBlock; // block minted
        uint32 slotNumber; // Slot of the block
        string graffitiText;
        uint32 validatorIndex;
    }

    /**
     * @notice executeRelay is the bridge between off-chain and on-chain. It will only be called if the produced
     * block contains our graffiti. It executes the tickers' code and reward the attestors.
     * @param _graffities graffiti metadata
     * @dev can only be called by the Dedicated Sender
     */
    function executeRelay(GraffitiData[] calldata _graffities) external returns (uint256 totalOfExecutions_);

    /**
     * @notice Call Ticker to execute its logic
     * @param _ticker Ticker Address
     * @param _gasLimit Gas Limit, it cannot exceed `tickerGasLimit` but can be lower
     * @param _blockNumber the minted block number
     * @param _lzEndpointSelected the LZ endpoint selected for this ticker
     * @param _executionFee Execution Fee to repay
     * @param _identityReceiver the miner
     * @dev We use public function to catch reverts without stopping the whole flow
     * @dev can only be called by itself
     */
    function callTicker(
        address _ticker,
        uint32 _gasLimit,
        uint128 _executionFee,
        uint32 _lzEndpointSelected,
        uint32 _blockNumber,
        address _identityReceiver
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IHeroglyphAttestation } from "./IHeroglyphAttestation.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SendNativeHelper } from "./SendNativeHelper.sol";

import { IValidatorIdentityV2 } from "./identity/wallet/v2/IValidatorIdentityV2.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title HeroglyphAttestation
 * @notice This contract serves as the reward mechanism for verified-attestor validators who have been selected.
 * To keep things batched and optimized, claiming starts a batch (if not already done) and will be executed only after
 * approximately 2 hours.
 * If for some reason the batch hasn't been executed after 4 hours, it can be triggered again.
 */
contract HeroglyphAttestation is IHeroglyphAttestation, ERC20, Ownable, SendNativeHelper {
    using MessageHashUtils for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    // (EPOCH_30_DAYS / 100 + 1) --- Add one to loop
    uint32 public constant MAX_EPOCHS_LOOP = 68;
    uint32 public constant FINALIZED_EPOCH_DELAY = 25 minutes;
    uint32 public constant START_CLAIMING_EPOCH = 285_400;
    uint32 public constant EPOCH_30_DAYS = 6725;
    uint32 public constant START_CLAIMING_TIMESTAMP = 1_716_417_623;
    uint32 public constant MAX_EPOCHS = 100;
    uint32 public constant MAX_VALIDATORS = 100;
    uint32 public constant CLAIM_REQUEST_TIMEOUT = 4 hours;
    uint32 public constant IDLE_WAIT = 2 hours;

    IValidatorIdentityV2 public validatorIdentity;
    address public dedicatedMsgSender;
    uint32 public timePerEpoch;
    uint256 public attestationPointRate;
    uint256 public sendingBatchesSize;
    bool public isSoulbound;
    bool public pausePermit;

    mapping(uint32 validatorIndex => uint32 highestEpoch) internal latestEpochHeadRequested;
    mapping(uint32 headEpoch => uint64[]) internal headEpochBatchIds;
    mapping(uint32 validatorId => uint32) internal penalityPoints;
    mapping(address => bool) public hasTransferPermission;
    mapping(address => address) public redirectBadges;

    EnumerableSet.UintSet internal idleBatchIds;
    mapping(uint64 => BatchRequest) internal allBatches;
    uint64 public currentBatchId;

    modifier onlyDedicatedMsgSender() {
        if (msg.sender != dedicatedMsgSender) revert NotDedicatedMsgSender();
        _;
    }

    constructor(address _dedicatedMsgSender, address _validatorIdentity, address _owner)
        ERC20("Badges", "BADGES")
        Ownable(_owner)
    {
        dedicatedMsgSender = _dedicatedMsgSender;
        validatorIdentity = IValidatorIdentityV2(_validatorIdentity);

        // ~12 seconds per slot | 32 slots
        timePerEpoch = 12 * 32;

        //1 / (15 days / timePerEpoch)
        attestationPointRate = 0.000297 ether;
        sendingBatchesSize = 15;
        isSoulbound = true;
    }

    function createAttestationRequest(string[] calldata _identityNames) external {
        if (block.timestamp < START_CLAIMING_TIMESTAMP) revert CreateAttestationRequestIsNotActive();

        uint32 timePerEpochCached = timePerEpoch;

        uint32 epochHead;
        uint32 validatorIndex;
        uint64 batchId;
        uint32 expectedTimelapse;
        bool atLeastOneSuccess;

        uint32 tailEpoch = getTailEpoch();

        uint32 differenceEpoch;

        IValidatorIdentityV2.Identifier memory identity;

        for (uint256 i = 0; i < _identityNames.length; ++i) {
            identity = validatorIdentity.getIdentityData(0, _identityNames[i]);
            if (identity.walletReceiver == address(0)) continue;

            validatorIndex = identity.validatorUUID;

            epochHead = latestEpochHeadRequested[validatorIndex];
            if (epochHead < tailEpoch) epochHead = tailEpoch;

            for (uint256 j = 0; j < MAX_EPOCHS_LOOP; ++j) {
                differenceEpoch = (epochHead + MAX_EPOCHS) - START_CLAIMING_EPOCH;
                expectedTimelapse = (differenceEpoch * timePerEpochCached) + START_CLAIMING_TIMESTAMP;

                if (expectedTimelapse + FINALIZED_EPOCH_DELAY > block.timestamp) {
                    break;
                }

                epochHead += MAX_EPOCHS;
                batchId = _addReceiptToBatch(validatorIndex, epochHead);
                atLeastOneSuccess = true;

                emit ClaimRequest(validatorIndex, batchId, epochHead);
            }

            latestEpochHeadRequested[validatorIndex] = epochHead;
        }

        if (!atLeastOneSuccess) revert AttestationRequestFailed();
    }

    function _addReceiptToBatch(uint32 _validatorIndex, uint32 _head) internal returns (uint64 batchId_) {
        uint64[] storage headBatchIds = headEpochBatchIds[_head];
        BatchRequest storage epochBatch;
        uint64 batchIdsSize = uint64(headBatchIds.length);
        uint32 totalValidators;

        if (batchIdsSize == 0) {
            return _createNewBatch(_head, _validatorIndex);
        }

        batchId_ = headBatchIds[batchIdsSize - 1];
        epochBatch = allBatches[batchId_];

        if (epochBatch.success || epochBatch.expiredTime != 0) {
            return _createNewBatch(_head, _validatorIndex);
        }

        epochBatch.validators.push(_validatorIndex);
        totalValidators = uint32(epochBatch.validators.length);

        if (totalValidators == MAX_VALIDATORS || epochBatch.idleEnd <= block.timestamp) {
            _sendBatchToExecute(epochBatch, batchId_);
        }

        return batchId_;
    }

    function _createNewBatch(uint32 _epochHead, uint32 _validatorToAdd) internal returns (uint64 batchId_) {
        BatchRequest memory newBatch = BatchRequest({
            headEpoch: _epochHead,
            validators: new uint32[](1),
            idleEnd: uint32(block.timestamp) + IDLE_WAIT,
            expiredTime: 0,
            success: false
        });

        newBatch.validators[0] = _validatorToAdd;

        ++currentBatchId;
        batchId_ = currentBatchId;

        allBatches[batchId_] = newBatch;
        headEpochBatchIds[_epochHead].push(batchId_);

        //No need to check for contains -> add already doing it
        idleBatchIds.add(batchId_);

        emit NewBatchCreated(_epochHead, batchId_);
        return batchId_;
    }

    function redirectClaimRewardsWithPermit(
        address _withdrawalCredential,
        address _to,
        uint32 _deadline,
        bytes calldata _signature
    ) external {
        if (pausePermit) revert PermitPaused();
        if (block.timestamp > _deadline) revert ExpiredSignature();

        bytes32 ethSignature = keccak256(abi.encodePacked(_to, _deadline)).toEthSignedMessageHash();

        if (!SignatureChecker.isValidSignatureNow(_withdrawalCredential, ethSignature, _signature)) {
            revert InvalidSignature();
        }

        redirectBadges[_withdrawalCredential] = _to;
        emit RedirectionSet(_withdrawalCredential, _to);
    }

    function redirectClaimRewards(address _to) external {
        redirectBadges[msg.sender] = _to;
        emit RedirectionSet(msg.sender, _to);
    }

    function manuallyExecuteBatch(uint64 batchId) external {
        _manuallyExecuteBatch(batchId, true);
    }

    function manuallyExecuteBatches(uint64[] calldata batchIds) external {
        bool atLeastOneSuccess;
        bool result;

        for (uint256 i = 0; i < batchIds.length; ++i) {
            result = _manuallyExecuteBatch(batchIds[i], false);

            if (!atLeastOneSuccess) atLeastOneSuccess = result;
        }

        if (!atLeastOneSuccess) revert NothingToExecute();
    }

    function _manuallyExecuteBatch(uint64 _batchId, bool _allowsRevert) internal returns (bool success_) {
        BatchRequest storage batch = allBatches[_batchId];
        if (batch.headEpoch == 0) {
            if (_allowsRevert) revert BatchNotFound();
            return false;
        }
        if (batch.expiredTime > block.timestamp || batch.idleEnd > block.timestamp) {
            if (_allowsRevert) revert BatchNotSentOrExpired();
            return false;
        }
        if (batch.success) {
            if (_allowsRevert) revert BatchAlreadyExecuted();
            return false;
        }

        _sendBatchToExecute(batch, _batchId);
        return true;
    }

    function checkerToExecuteIdles() external view returns (bool canExec, bytes memory execPayload) {
        uint256 pendingLength = idleBatchIds.length();

        canExec = pendingLength > 0;
        execPayload = abi.encodeCall(HeroglyphAttestation.tryExecutingIdleBatches, (pendingLength));

        return (canExec, execPayload);
    }

    function tryExecutingIdleBatches(uint256 _loop) external {
        uint256[] memory cachedBatchIds = idleBatchIds.values();
        uint256 totalPending = cachedBatchIds.length;
        uint256 maxLoop = sendingBatchesSize;

        if (_loop > maxLoop) _loop = maxLoop;
        if (_loop == 0 || _loop > totalPending) _loop = totalPending;

        bool atLeastOneTriggered;

        BatchRequest storage batch;
        uint64 batchId;
        for (uint256 i = 0; i < _loop; ++i) {
            batchId = uint64(cachedBatchIds[i]);
            batch = allBatches[batchId];
            if (batch.expiredTime > block.timestamp || batch.idleEnd > block.timestamp) continue;

            _sendBatchToExecute(batch, uint64(batchId));
            atLeastOneTriggered = true;
        }

        if (!atLeastOneTriggered) revert NothingToExecute();
    }

    function _sendBatchToExecute(BatchRequest storage _batch, uint64 _batchId) internal {
        _batch.expiredTime = uint32(block.timestamp) + CLAIM_REQUEST_TIMEOUT;

        //No need to check for contains -> remove's checking it
        idleBatchIds.remove(_batchId);

        emit SendBatchToExecute(_batchId, _batch.headEpoch, _batch.validators);
    }

    function executeClaiming(
        uint64 _batchId,
        address[] calldata _withdrawalAddresses,
        int32[] calldata _attestationPoints
    ) external onlyDedicatedMsgSender {
        BatchRequest storage batch = allBatches[_batchId];
        uint256 totalValidators = batch.validators.length;

        if (batch.headEpoch == 0) revert BatchNotFound();
        if (batch.success) revert BatchAlreadyExecuted();
        if (_withdrawalAddresses.length != totalValidators || _attestationPoints.length != totalValidators) {
            revert MismatchArrays();
        }

        batch.success = true;

        uint32 validatorIndex;
        address withdrawal;
        int32 attestationPoint;
        for (uint256 i = 0; i < _withdrawalAddresses.length; ++i) {
            validatorIndex = batch.validators[i];
            withdrawal = _withdrawalAddresses[i];
            attestationPoint = _attestationPoints[i];

            _executeSingleClaim(validatorIndex, withdrawal, attestationPoint);

            emit ExecutionAttestationClaim(
                _batchId, validatorIndex, withdrawal, attestationPoint, penalityPoints[validatorIndex]
            );
        }

        emit BatchExecuted(_batchId, _attestationPoints);
    }

    function _executeSingleClaim(uint32 _validator, address _withdrawalAddress, int32 _attestationPoint) internal {
        address redirectedAddress = redirectBadges[_withdrawalAddress];

        if (redirectedAddress != address(0)) {
            _withdrawalAddress = redirectedAddress;
        }

        uint32 penaltyPoints = penalityPoints[_validator];
        if (_attestationPoint == 0) {
            return;
        }

        if (_attestationPoint < 0) {
            penalityPoints[_validator] += uint32(_attestationPoint * -1);
            return;
        }
        uint32 pointUint32 = uint32(_attestationPoint);

        if (penaltyPoints >= pointUint32) {
            penaltyPoints -= pointUint32;
            pointUint32 = 0;
        } else {
            pointUint32 -= penaltyPoints;
            penaltyPoints = 0;
        }

        penalityPoints[_validator] = penaltyPoints;
        if (pointUint32 == 0) return;

        uint256 reward = uint256(pointUint32) * attestationPointRate;

        if (reward == 0) return;

        if (_withdrawalAddress != address(0)) {
            _mint(_withdrawalAddress, reward);
            return;
        }

        _mint(owner(), reward);
        emit NoWithdrawalAddressFound(_validator, reward);
    }

    function _update(address from, address to, uint256 value) internal override {
        super._update(from, to, value);

        if ((from == address(0) || to == address(0)) || !isSoulbound) return;
        if (!hasTransferPermission[msg.sender]) revert TokenSoulbound();
    }

    function setTransferPermissionOf(address _target, bool _enabled) external onlyOwner {
        hasTransferPermission[_target] = _enabled;
        emit TransferPermissionUpdated(_target, _enabled);
    }

    function updateDedicatedMsgSender(address _msg) external onlyOwner {
        dedicatedMsgSender = _msg;
        emit DedicatedMsgSenderUpdated(_msg);
    }

    function updateValidatorIdentity(address _validatorIdentity) external onlyOwner {
        validatorIdentity = IValidatorIdentityV2(_validatorIdentity);
        emit ValidatorIdentityUpdated(_validatorIdentity);
    }

    function updateAttestationPointRate(uint256 _rate) external onlyOwner {
        attestationPointRate = _rate;
        emit AttestationPointRateUpdated(_rate);
    }

    function updateTimePerEpoch(uint32 _perEpochInSeconds) external onlyOwner {
        timePerEpoch = _perEpochInSeconds;
        emit TimePerEpochUpdated(_perEpochInSeconds);
    }

    function updateSendingBatchesSize(uint256 _size) external onlyOwner {
        sendingBatchesSize = _size;
        emit SendingBatchesSizeUpdated(_size);
    }

    function updateSoulboundStatus(bool _isSoulbound) external onlyOwner {
        isSoulbound = _isSoulbound;
        emit SoulboundStatusUpdated(_isSoulbound);
    }

    function updatePausePermit(bool _status) external onlyOwner {
        pausePermit = _status;
        emit PermitPausedUpdated(_status);
    }

    function getTailEpoch() public view returns (uint32 tail_) {
        if (block.timestamp <= START_CLAIMING_TIMESTAMP) return START_CLAIMING_EPOCH;

        uint256 fromTheStart = (block.timestamp - START_CLAIMING_TIMESTAMP) / timePerEpoch;
        uint256 ceil = (fromTheStart + START_CLAIMING_EPOCH - EPOCH_30_DAYS) / MAX_EPOCHS;

        tail_ = uint32(ceil * MAX_EPOCHS);
        return (tail_ < START_CLAIMING_EPOCH) ? START_CLAIMING_EPOCH : tail_;
    }

    function getValidatorLatestEpochClaimed(uint32 _validatorIndex) external view returns (uint256 latest_) {
        latest_ = latestEpochHeadRequested[_validatorIndex];
        uint32 tails = getTailEpoch();

        return (latest_ > tails) ? latest_ : tails;
    }

    function getEpochHeadRequestBatchIds(uint32 _epochHead) external view returns (uint64[] memory) {
        return headEpochBatchIds[_epochHead];
    }

    function getBatchRequest(uint64 _batchId) external view returns (BatchRequest memory) {
        return allBatches[_batchId];
    }

    function getIdleRequestBatches() external view returns (uint256[] memory) {
        return idleBatchIds.values();
    }

    function getPenaltyPointBalance(uint32 _validatorId) external view returns (uint256) {
        return penalityPoints[_validatorId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
pragma solidity ^0.8.25;

/**
 * @title SendNativeHelper
 * @notice This helper facilitates the sending of native tokens and manages actions in case of reversion or tracking
 * rewards upon failure.
 */
abstract contract SendNativeHelper {
    error NotEnough();
    error FailedToSendETH();

    mapping(address wallet => uint256) internal pendingClaims;

    function _sendNative(address _to, uint256 _amount, bool _revertIfFails) internal {
        if (_amount == 0) return;

        (bool success,) = _to.call{ gas: 60_000, value: _amount }("");

        if (!success) {
            if (_revertIfFails) revert FailedToSendETH();
            pendingClaims[_to] += _amount;
        }
    }

    function claimFund() external {
        uint256 balance = pendingClaims[msg.sender];
        pendingClaims[msg.sender] = 0;

        if (balance == 0) revert NotEnough();

        _sendNative(msg.sender, balance, true);
    }

    function getPendingToClaim(address _user) external view returns (uint256) {
        return pendingClaims[_user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface ITickerOperator {
    error FailedToSendETH();
    error NotHeroglyph();
    error FeePayerCannotBeZero();

    event FeePayerUpdated(address indexed feePayer);
    event HeroglyphRelayUpdated(address relay);

    /**
     * @notice onValidatorTriggered() Callback function when your ticker has been selected
     * @param _lzEndpointSelected // The selected layer zero endpoint target for this ticker
     * @param _blockNumber  // The number of the block minted
     * @param _identityReceiver // The Identity's receiver from the miner graffiti
     * @param _heroglyphFee // The fee to pay for the execution
     * @dev be sure to apply onlyRelay to this function
     * @dev TIP: Avoid using reverts; instead, use return statements, unless you need to restore your contract to its
     * initial state.
     * @dev TIP:Keep in mind that a miner may utilize your ticker more than once in their graffiti. To avoid any
     * repetition, consider utilizing blockNumber to track actions.
     */
    function onValidatorTriggered(
        uint32 _lzEndpointSelected,
        uint32 _blockNumber,
        address _identityReceiver,
        uint128 _heroglyphFee
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface ITicker {
    error ProtectionStillActive();
    error TickerNotFound();
    error CantSelfBuy();
    error PriceTooLow();
    error ProtectionMinimumOneMinute();
    error TickerIsImmune();
    error TickerUnderWater();
    error FrontRunGuard();
    error InitializationPeriodActive();

    event TickerUpdated(uint256 indexed id, string indexed name, address executionContract, uint256 price);
    event TickerHijacked(
        uint256 indexed id,
        string indexed name,
        address indexed hijacker,
        uint256 boughtValue,
        uint256 sentToPreviousOwner
    );
    event AddedDepositToTicker(uint256 indexed id, string indexed name, uint128 totalDeposit, uint128 added);
    event WithdrawnFromTicker(uint256 indexed id, string indexed name, uint128 totalDeposit, uint128 removed);
    event TickerSurrendered(uint256 indexed id, string indexed name, address indexed prevOwner);
    event TaxPaid(uint256 indexed id, string indexed name, uint256 paid, uint256 depositBalance, uint32 timestamp);
    event ProtectionTimeUpdated(uint32 time);

    /**
     * @notice TickerMetadata
     * @param name Name of the Ticker
     * @param contractTarget Contract Targeted by this ticker
     * @param owningDate date in second of when the owner received the ownership of the ticker
     * @param lastTimeTaxPaid Last time the tax has been paid
     * @param immunityEnds *Only for Heroglyph* Adds immunity on creation to protect against the tax & the hijack
     * @param price The price the owner is ready to sell it's ticker, the tax is based on this price
     */
    struct TickerMetadata {
        string name;
        address contractTarget;
        uint32 owningDate;
        uint32 lastTimeTaxPaid;
        uint32 immunityEnds;
        uint128 price;
        uint128 deposit;
    }

    /**
     * @notice TickerCreation
     * @param name Name of the Ticker
     * @param contractTarget Contract Targeted by this ticker
     * @param gasLimit  Gas Limit of the execution, it's capped to the limit set by HeroglyphRelay::tickerGasLimit
     * @param setPrice The price the owner is ready to sell it's ticker, the tax is based on this price
     */
    struct TickerCreation {
        string name;
        address contractTarget;
        uint128 setPrice;
    }

    /**
     * @notice create Create an Identity
     * @param _tickerCreation tuple(string name, uint128 setPrice, address contractTarget, uint128 gasLimit)
     */
    function create(TickerCreation calldata _tickerCreation) external payable;

    /**
     * @notice updateTicker Update Ticker settings
     * @param _nftId Id of the Ticker NFT
     * @param _name Name of the Ticker
     * @param _contractTarget contract target
     * @dev Only the Ticker Owner can call this function
     * @dev if `_nftId` is zero, it will use `_name` instead
     */
    function updateTicker(uint256 _nftId, string calldata _name, address _contractTarget) external;

    /**
     * @notice hijack Buy a Ticker and set the new price
     * @param _nftId Id of the Ticker NFT
     * @param _name  name of the Ticker
     * @param _tickerPrice price of the ticker before hijack
     * @param _newPrice new price after hijackout
     * @dev if `_nftId` is zero, it will use `_name` instead
     */
    function hijack(uint256 _nftId, string calldata _name, uint128 _tickerPrice, uint128 _newPrice) external payable;

    /**
     * @notice updatePrice Update the price of a Ticker
     * @param _nftId Id of the Ticker NFT
     * @param _name Name of the Ticker
     * @param _newPrice New price of the Ticker
     * @dev Only the Ticker owner can update the price
     * @dev if `_nftId` is zero, it will use `_name` instead
     */
    function updatePrice(uint256 _nftId, string calldata _name, uint128 _newPrice) external;

    /**
     * @notice increaseDeposit Increase the deposit on a ticker to avoid losing it from tax
     * @param _nftId Id of the Ticker NFT
     * @param _name Name of the ticker
     * @dev only Ticker Owner can call this
     * @dev if `_nftId` is zero, it will use `_name` instead
     */
    function increaseDeposit(uint256 _nftId, string calldata _name) external payable;

    /**
     * @notice withdrawDeposit Withdraw deposit from Ticker
     * @param _nftId Id of the Ticker NFT
     * @param _name Name of the Ticker
     * @param _amount Amount to withdraw
     * @dev Only Ticker owner can call this function
     * @dev If the new deposit balance is lower than the tax or equals to zero the owner will lose their Ticker and the
     * new price of the Ticker will be zero
     * @dev if `_nftId` is zero, it will use `_name` instead
     * @dev if `_amount` is zero, it will withdraw all the deposit remaining
     */
    function withdrawDeposit(uint256 _nftId, string calldata _name, uint128 _amount) external;

    /**
     * @notice getDepositLeft() Get the deposit left after tax
     * @param _nftId Id of the Ticker NFT
     * @param _name Name of the Ticker
     * @dev if `_nftId` is zero, it will use `_name` instead
     */
    function getDepositLeft(uint256 _nftId, string calldata _name) external view returns (uint256 _left);

    /**
     * @notice getTaxDue() Get how much the Ticker is due on their taxes
     * @param _nftId Id of the Ticker NFT
     * @param _name Name of the Ticker
     * @dev if `_nftId` is zero, it will use `_name` instead
     */
    function getTaxDue(uint256 _nftId, string calldata _name) external view returns (uint256 _tax);

    /**
     * @notice getDeposit Get how many eth has been deposited for a Ticker
     * @param _nftId Id of the Ticker NFT
     * @param _name Name of the Ticker
     * @dev if `_nftId` is zero, it will use `_name` instead
     */
    function getDeposit(uint256 _nftId, string calldata _name) external view returns (uint256);

    /**
     * @notice getTickerMetadata Get Ticker Metadata and its status
     * @param _nftId Id of the Ticker NFT
     * @param _name Name of the Ticker
     * @return ticker_ tuple(string name, uint128 setPrice, address contractTarget, uint128 gasLimit)
     * @return shouldBeSurrender_ If it's true, the ticker will be surrendered. The only way to avoid this is if the
     * owner
     * calls deposit before any action.
     * @dev if `_nftId` is zero, it will use `_name` instead
     */
    function getTickerMetadata(uint256 _nftId, string calldata _name)
        external
        view
        returns (TickerMetadata memory ticker_, bool shouldBeSurrender_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ValidatorIdentityV2 } from "./v2/ValidatorIdentityV2.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IDelegation } from "./delegation/IDelegation.sol";
import { IIdentityRouter } from "./IIdentityRouter.sol";

contract IdentityRouter is Ownable, IIdentityRouter {
    mapping(string identityName => mapping(uint32 => RouterConfig)) internal routers;

    ValidatorIdentityV2 public validatorIdentity;
    IDelegation public delegation;

    constructor(address _owner, address _validatorIdentityV2) Ownable(_owner) {
        validatorIdentity = ValidatorIdentityV2(_validatorIdentityV2);
    }

    /**
     * @inheritdoc IIdentityRouter
     */
    function hookIdentities(string calldata _parentIdentiyName, string[] calldata _children) external override {
        if (validatorIdentity.ownerOf(_parentIdentiyName) != msg.sender) revert NotIdentityOwner();

        ValidatorIdentityV2.Identifier memory identity;
        string memory childIdentityName;

        for (uint256 i = 0; i < _children.length; ++i) {
            childIdentityName = _children[i];
            identity = validatorIdentity.getIdentityData(0, childIdentityName);

            routers[_parentIdentiyName][identity.validatorUUID] = RouterConfig(childIdentityName, false);

            emit HookedIdentity(_parentIdentiyName, identity.validatorUUID, childIdentityName);
        }
    }

    /**
     * @inheritdoc IIdentityRouter
     */
    function toggleUseChildWalletReceiver(string calldata _parentIdentiyName, uint32 _validatorId) external override {
        if (validatorIdentity.ownerOf(_parentIdentiyName) != msg.sender) revert NotIdentityOwner();

        RouterConfig storage routerConfig = routers[_parentIdentiyName][_validatorId];
        bool newStatus = !routerConfig.useChildWallet;

        routerConfig.useChildWallet = newStatus;

        emit UseChildWalletUpdated(_parentIdentiyName, _validatorId, routerConfig.childName, newStatus);
    }

    /**
     * @inheritdoc IIdentityRouter
     */
    function getWalletReceiver(string calldata _parentIdentiyName, uint32 _validatorId)
        external
        view
        override
        returns (address walletReceiver_, bool isDelegated_)
    {
        if (address(delegation) != address(0) && delegation.isDelegated(_parentIdentiyName, _validatorId)) {
            return (address(delegation), true);
        }

        RouterConfig memory routerConfig = routers[_parentIdentiyName][_validatorId];
        bool isRouted = keccak256(abi.encode(routerConfig.childName)) != keccak256(abi.encode(""));

        string memory idName = isRouted && routerConfig.useChildWallet ? routerConfig.childName : _parentIdentiyName;
        ValidatorIdentityV2.Identifier memory identityData = validatorIdentity.getIdentityData(0, idName);

        walletReceiver_ =
            (isRouted || identityData.validatorUUID == _validatorId) ? identityData.walletReceiver : address(0);

        return (walletReceiver_, false);
    }

    function updateValidatorIdentity(address _validatorIdentity) external onlyOwner {
        validatorIdentity = ValidatorIdentityV2(_validatorIdentity);
        emit ValidatorIdentityUpdated(_validatorIdentity);
    }

    function updateDelegation(address _delegation) external onlyOwner {
        delegation = IDelegation(_delegation);
        emit DelegationUpdated(_delegation);
    }

    /**
     * @inheritdoc IIdentityRouter
     */
    function getRouterConfig(string calldata _parentIdentityName, uint32 _validatorId)
        external
        view
        returns (RouterConfig memory)
    {
        return routers[_parentIdentityName][_validatorId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IDelegation {
    function isDelegated(string calldata _idName, uint32 _validatorId) external view returns (bool);

    function snapshot(string calldata _idName, uint32 _validatorId, address _tickerContract) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IHeroglyphAttestation {
    error NothingToExecute();
    error NotDedicatedMsgSender();
    error AttestationRequestFailed();
    error BatchNotSentOrExpired();
    error BatchAlreadyExecuted();
    error MismatchArrays();
    error CreateAttestationRequestIsNotActive();
    error TokenSoulbound();
    error ExpiredSignature();
    error InvalidSignature();
    error BatchNotFound();
    error PermitPaused();

    struct BatchRequest {
        uint32 headEpoch;
        uint32[] validators;
        uint32 idleEnd;
        uint32 expiredTime;
        bool success;
    }

    event DedicatedMsgSenderUpdated(address indexed dedicatedMsgSender);
    event NoWithdrawalAddressFound(uint32 indexed validator, uint256 rewards);
    event SendBatchToExecute(uint64 indexed batchId, uint32 indexed headEpoch, uint32[] validators);
    event ClaimRequest(uint32 indexed validatorId, uint64 indexed batchId, uint32 indexed headEpoch);
    event ExecutionAttestationClaim(
        uint64 indexed batchId,
        uint32 indexed validatorId,
        address indexed withdrawalAddress,
        int32 receivedPoints,
        uint32 penaltyBalance
    );
    event NewBatchCreated(uint32 indexed headEpoch, uint64 indexed batchId);
    event AttestationPointRateUpdated(uint256 newRate);
    event TimePerEpochUpdated(uint256 timePerEpochInSeconds);
    event BatchExecuted(uint64 indexed batchId, int32[] attestationPoints);
    event ValidatorIdentityUpdated(address validatorIdentity);
    event SendingBatchesSizeUpdated(uint256 size);
    event TransferPermissionUpdated(address indexed target, bool status);
    event RedirectionSet(address indexed withdrawalCredential, address indexed to);
    event SoulboundStatusUpdated(bool isSoulbound);
    event PermitPausedUpdated(bool status);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IValidatorIdentityV2 {
    error NoMigrationPossible();
    error NotBackwardCompatible();
    error MsgValueTooLow();
    error NoNeedToPay();
    error InvalidBPS();

    /**
     * @notice Identifier
     * @param name Name of the Wallet
     * @param walletReceiver Address that will be receiving Ticker's reward if any
     */
    struct Identifier {
        string name;
        uint32 validatorUUID;
        address walletReceiver;
    }

    event WalletReceiverUpdated(uint256 indexed walletId, string indexed identityName, address newWallet);
    event NewGraffitiIdentityCreated(
        uint256 indexed walletId, uint32 indexed validatorId, string identityName, uint256 cost
    );
    event MaxIdentityPerDayAtInitialPriceUpdated(uint32 maxIdentityPerDayAtInitialPrice);
    event PriceIncreaseThresholdUpdated(uint32 priceIncreaseThreshold);
    event PriceDecayBPSUpdated(uint32 priceDecayBPS);

    /**
     * isSoulboundIdentity Try to soulbound an identity
     * @param _name Name of the identity
     * @param _validatorId Validator ID of the validator
     * @return bool Returns true if the identity is soulbound & validatorId is the same
     */
    function isSoulboundIdentity(string calldata _name, uint32 _validatorId) external view returns (bool);

    /**
     * migrateFromOldIdentity Migrate from old identity to new identity
     * @param _name Name of the identity
     * @param _validatorId Validator ID of the validator
     */
    function migrateFromOldIdentity(string calldata _name, uint32 _validatorId) external;

    /**
     * create Create an Identity
     * @param _name name of the Identity
     * @param _validatorId Unique Id of the validator
     */
    function create(string calldata _name, address _receiverWallet, uint32 _validatorId) external payable;

    /**
     * updateReceiverAddress Update Receiver Wallet of an Identity
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _receiver address that will be receiving any rewards
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     * @dev Only the owner of the Identity can call this function
     */
    function updateReceiverAddress(uint256 _nftId, string memory _name, address _receiver) external;

    /**
     * getIdentityDataWithName Get Identity information with name
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @return identity_ tuple(name,tokenReceiver)
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function getIdentityData(uint256 _nftId, string calldata _name) external view returns (Identifier memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MessageHashUtils.sol)

pragma solidity ^0.8.20;

import {Strings} from "../Strings.sol";

/**
 * @dev Signature message hash utilities for producing digests to be consumed by {ECDSA} recovery or signing.
 *
 * The library provides methods for generating a hash of a message that conforms to the
 * https://eips.ethereum.org/EIPS/eip-191[EIP 191] and https://eips.ethereum.org/EIPS/eip-712[EIP 712]
 * specifications.
 */
library MessageHashUtils {
    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing a bytes32 `messageHash` with
     * `"\x19Ethereum Signed Message:\n32"` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * NOTE: The `messageHash` parameter is intended to be the result of hashing a raw message with
     * keccak256, although any bytes32 value can be safely used because the final digest will
     * be re-hashed.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 32 is the bytes-length of messageHash
            mstore(0x1c, messageHash) // 0x1c (28) is the length of the prefix
            digest := keccak256(0x00, 0x3c) // 0x3c is the length of the prefix (0x1c) + messageHash (0x20)
        }
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x45` (`personal_sign` messages).
     *
     * The digest is calculated by prefixing an arbitrary `message` with
     * `"\x19Ethereum Signed Message:\n" + len(message)` and hashing the result. It corresponds with the
     * hash signed when using the https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`] JSON-RPC method.
     *
     * See {ECDSA-recover}.
     */
    function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        return
            keccak256(bytes.concat("\x19Ethereum Signed Message:\n", bytes(Strings.toString(message.length)), message));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-191 signed data with version
     * `0x00` (data with intended validator).
     *
     * The digest is calculated by prefixing an arbitrary `data` with `"\x19\x00"` and the intended
     * `validator` address. Then hashing the result.
     *
     * See {ECDSA-recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"19_00", validator, data));
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, hex"19_01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            digest := keccak256(ptr, 0x42)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.20;

import {ECDSA} from "./ECDSA.sol";
import {IERC1271} from "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Safe Wallet (previously Gnosis Safe).
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error, ) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeCall(IERC1271.isValidSignature, (hash, signature))
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IdentityERC721 } from "../../IdentityERC721.sol";
import { IValidatorIdentityV2 } from "./IValidatorIdentityV2.sol";
import { IValidatorIdentity } from "../IValidatorIdentity.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title ValidatorIdentityV2
 * @notice Validators require an identity to link the wallet where they wish to receive rewards (if applicable).
 * Unlike the Ticker, ValidatorIdentity is permanently owned by its creator and contains no tax.
 *
 * For more details, refer to IValidatorIdentity.sol.
 */
contract ValidatorIdentityV2 is IValidatorIdentityV2, IdentityERC721 {
    uint256 public constant MAX_BPS = 10_000;

    IValidatorIdentity public immutable oldIdentity;
    mapping(uint256 => Identifier) internal identities;

    uint32 public resetCounterTimestamp;
    uint32 public boughtToday;
    uint32 public maxIdentityPerDayAtInitialPrice;
    uint32 public priceIncreaseThreshold;
    uint32 public priceDecayBPS;
    uint256 public currentPrice;

    constructor(address _owner, address _treasury, address _nameFilter, uint256 _cost, address _oldIdentity)
        IdentityERC721(_owner, _treasury, _nameFilter, _cost, "ValidatorIdentity", "EthI")
    {
        oldIdentity = IValidatorIdentity(_oldIdentity);
        resetCounterTimestamp = uint32(block.timestamp + 1 days);
        currentPrice = cost;
        maxIdentityPerDayAtInitialPrice = 25;
        priceIncreaseThreshold = 10;
        priceDecayBPS = 2500;
    }

    function isSoulboundIdentity(string calldata _name, uint32 _validatorId) external view override returns (bool) {
        uint256 nftId = identityIds[_name];
        return identities[nftId].validatorUUID == _validatorId;
    }

    function migrateFromOldIdentity(string calldata _name, uint32 _validatorId) external override {
        if (address(oldIdentity) == address(0)) revert NoMigrationPossible();

        // Happens if the user created an new identity on the old version while the name was already taken in this
        // version
        if (identityIds[_name] != 0) revert NotBackwardCompatible();

        IValidatorIdentity.DelegatedIdentity memory oldDelegation = oldIdentity.getDelegationData(0, _name);
        IValidatorIdentity.Identifier memory oldIdentityData = oldIdentity.getIdentityData(0, _name);

        bool isDelegatedAndOwner = oldDelegation.isEnabled && oldDelegation.owner == msg.sender;
        bool isOwner = IdentityERC721(address(oldIdentity)).ownerOf(_name) == msg.sender;

        if (!isDelegatedAndOwner && !isOwner) revert NotIdentityOwner();

        _createIdentity(_name, oldIdentityData.tokenReceiver, _validatorId, 0);
    }

    function create(string calldata _name, address _receiverWallet, uint32 _validatorId) external payable override {
        if (cost == 0 && msg.value != 0) revert NoNeedToPay();

        _executeCreate(_name, _receiverWallet, _validatorId);
    }

    function _executeCreate(string calldata _name, address _receiverWallet, uint32 _validatorId) internal {
        if (_isNameExistingFromOldVersion(_name)) revert NameAlreadyTaken();

        uint256 costAtDuringTx = _updateCost();

        if (msg.value < costAtDuringTx) revert MsgValueTooLow();

        _sendNative(treasury, costAtDuringTx, true);
        _sendNative(msg.sender, msg.value - costAtDuringTx, true);

        _createIdentity(_name, _receiverWallet, _validatorId, costAtDuringTx);
    }

    function _createIdentity(string calldata _name, address _receiverWallet, uint32 _validatorId, uint256 _cost)
        internal
    {
        if (_receiverWallet == address(0)) _receiverWallet = msg.sender;

        uint256 id = _create(_name, 0);
        identities[id] = Identifier({ name: _name, validatorUUID: _validatorId, walletReceiver: _receiverWallet });

        emit NewGraffitiIdentityCreated(id, _validatorId, _name, _cost);
        emit WalletReceiverUpdated(id, _name, _receiverWallet);
    }

    function _updateCost() internal returns (uint256 userCost_) {
        (resetCounterTimestamp, boughtToday, currentPrice, userCost_) = _getCostDetails();
        return userCost_;
    }

    function getCost() external view returns (uint256 userCost_) {
        (,,, userCost_) = _getCostDetails();
        return userCost_;
    }

    function _getCostDetails()
        internal
        view
        returns (
            uint32 resetCounterTimestampReturn_,
            uint32 boughtTodayReturn_,
            uint256 currentCostReturn_,
            uint256 userCost_
        )
    {
        uint32 maxPerDayCached = maxIdentityPerDayAtInitialPrice;
        resetCounterTimestampReturn_ = resetCounterTimestamp;
        boughtTodayReturn_ = boughtToday;
        currentCostReturn_ = currentPrice;

        if (block.timestamp >= resetCounterTimestampReturn_) {
            uint256 totalDayPassed = (block.timestamp - resetCounterTimestampReturn_) / 1 days + 1;
            resetCounterTimestampReturn_ += uint32(1 days * totalDayPassed);
            boughtTodayReturn_ = 0;

            for (uint256 i = 0; i < totalDayPassed; ++i) {
                currentCostReturn_ =
                    Math.max(cost, currentCostReturn_ - Math.mulDiv(currentCostReturn_, priceDecayBPS, MAX_BPS));

                if (currentCostReturn_ <= cost) break;
            }
        }

        bool boughtExceedsMaxPerDay = boughtTodayReturn_ > maxPerDayCached;

        if (boughtExceedsMaxPerDay && (boughtTodayReturn_ - maxPerDayCached) % priceIncreaseThreshold == 0) {
            currentCostReturn_ += cost / 2;
        }

        userCost_ = !boughtExceedsMaxPerDay ? cost : currentCostReturn_;
        boughtTodayReturn_++;

        return (resetCounterTimestampReturn_, boughtTodayReturn_, currentCostReturn_, userCost_);
    }

    function updateReceiverAddress(uint256 _nftId, string calldata _name, address _receiver) external override {
        if (_nftId == 0) {
            _nftId = identityIds[_name];
        }

        if (ownerOf(_nftId) != msg.sender) revert NotIdentityOwner();

        Identifier storage identity = identities[_nftId];
        identity.walletReceiver = _receiver;

        emit WalletReceiverUpdated(_nftId, identity.name, _receiver);
    }

    function updateMaxIdentityPerDayAtInitialPrice(uint32 _maxIdentityPerDayAtInitialPrice) external onlyOwner {
        maxIdentityPerDayAtInitialPrice = _maxIdentityPerDayAtInitialPrice;
        emit MaxIdentityPerDayAtInitialPriceUpdated(_maxIdentityPerDayAtInitialPrice);
    }

    function updatePriceIncreaseThreshold(uint32 _priceIncreaseThreshold) external onlyOwner {
        priceIncreaseThreshold = _priceIncreaseThreshold;
        emit PriceIncreaseThresholdUpdated(_priceIncreaseThreshold);
    }

    function updatePriceDecayBPS(uint32 _priceDecayBPS) external onlyOwner {
        if (_priceDecayBPS > MAX_BPS) revert InvalidBPS();
        priceDecayBPS = _priceDecayBPS;
        emit PriceDecayBPSUpdated(_priceDecayBPS);
    }

    function transferFrom(address, address, uint256) public pure override {
        revert("Non-Transferrable");
    }

    function getIdentityData(uint256 _nftId, string calldata _name)
        external
        view
        override
        returns (Identifier memory)
    {
        if (_nftId == 0) {
            _nftId = identityIds[_name];
        }

        return identities[_nftId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        Identifier memory identity = identities[tokenId];

        string memory data = string(
            abi.encodePacked(
                '{"name":"Graffiti Identity @',
                identity.name,
                '","description":"Required for your Heroglyph Graffiti","image":"',
                "ipfs://QmdTq1vZ6cZ6mcJBfkG49FocwqTPFQ8duq6j2tL2rpzEWF",
                '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;utf8,", data));
    }

    function _isNameAvailable(string calldata _name) internal view override returns (bool success_, int32 failedAt_) {
        if (_isNameExistingFromOldVersion(_name)) return (false, -1);

        return super._isNameAvailable(_name);
    }

    function _isNameExistingFromOldVersion(string calldata _name) internal view returns (bool) {
        return address(oldIdentity) != address(0) && IdentityERC721(address(oldIdentity)).getIdentityNFTId(_name) != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IIdentityRouter {
    error NotIdentityOwner();

    event HookedIdentity(string indexed parentIdentityName, uint32 indexed childValidatorIndex, string childName);
    event ValidatorIdentityUpdated(address validatorIdentity);
    event DelegationUpdated(address delegation);
    event UseChildWalletUpdated(
        string indexed parentIdentityName, uint32 indexed childValidatorIndex, string childName, bool useChildWallet
    );

    struct RouterConfig {
        string childName;
        bool useChildWallet;
    }

    /**
     * hookIdentities Hooks multiple identities to a parent identity.
     * @param _parentIdentiyName Parent identity name
     * @param _children Child identity names
     * @dev The reward will be sent to the Parent identity's wallet receiver.
     */
    function hookIdentities(string calldata _parentIdentiyName, string[] calldata _children) external;

    /**
     * toggleUseChildWalletReceiver Toggles the use of the child wallet receiver.
     * @param _parentIdentiyName Parent identity name
     * @param _validatorId Validator ID
     */
    function toggleUseChildWalletReceiver(string calldata _parentIdentiyName, uint32 _validatorId) external;

    /**
     * getWalletReceiver Returns the wallet receiver address for a given parent identity and validator id.
     * @param _parentIdentiyName Parent identity name
     * @param _validatorId Validator id
     * @return walletReceiver_ Wallet receiver address. Returns empty address if not routed or soulbound.
     * @return isDelegated_ True if the identity is delegated.
     */
    function getWalletReceiver(string calldata _parentIdentiyName, uint32 _validatorId)
        external
        view
        returns (address walletReceiver_, bool isDelegated_);

    /**
     * getRouterConfig Returns the router configuration for a given parent identity and validator id.
     * @param _parentIdentityName Parent identity name
     * @param _validatorId Validator id
     * @return RouterConfig_ Router configuration tuple(string childName, boolean useChildWallet)
     */
    function getRouterConfig(string calldata _parentIdentityName, uint32 _validatorId)
        external
        view
        returns (RouterConfig memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC1271.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IIdentityERC721 } from "./IIdentityERC721.sol";
import { SendNativeHelper } from "./../SendNativeHelper.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { NameFilter } from "./NameFilter.sol";

/**
 * @title IdentityERC721
 * @notice The base of Ticker & ValidatorIdentity. It handles name verification, id tracking and the payment
 */
abstract contract IdentityERC721 is IIdentityERC721, ERC721, SendNativeHelper, Ownable {
    address public treasury;
    uint256 public cost;
    NameFilter public nameFilter;

    mapping(string => uint256) internal identityIds;
    uint256 private nextIdToMint;

    /**
     * @dev Important, id starts at 1. When creating an Identity, call _create to validate and mint
     */
    constructor(
        address _owner,
        address _treasury,
        address _nameFilter,
        uint256 _cost,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) Ownable(_owner) {
        if (_treasury == address(0)) revert TreasuryNotSet();

        nameFilter = NameFilter(_nameFilter);
        nextIdToMint = 1;
        treasury = _treasury;
        cost = _cost;
    }

    function _create(string memory _name, uint256 _expectingCost) internal returns (uint256 mintedId_) {
        if (_expectingCost != 0 && msg.value != _expectingCost) revert ValueIsNotEqualsToCost();
        if (identityIds[_name] != 0) revert NameAlreadyTaken();

        (bool isNameHealthy, uint256 characterIndex) = nameFilter.isNameValidWithIndexError(_name);
        if (!isNameHealthy) revert InvalidCharacter(characterIndex);

        mintedId_ = nextIdToMint;
        ++nextIdToMint;

        identityIds[_name] = mintedId_;

        _safeMint(msg.sender, mintedId_);
        emit NewIdentityCreated(mintedId_, _name, msg.sender);

        if (_expectingCost == 0) return mintedId_;

        _sendNative(treasury, msg.value, true);

        return mintedId_;
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        if (tokenId == 0) revert InvalidIdZero();
        return super._update(to, tokenId, auth);
    }

    function isNameAvailable(string calldata _name) external view returns (bool success_, int32 failedAt_) {
        return _isNameAvailable(_name);
    }

    function _isNameAvailable(string calldata _name) internal view virtual returns (bool success_, int32 failedAt_) {
        if (identityIds[_name] != 0) return (false, -1);

        uint256 characterIndex;
        (success_, characterIndex) = nameFilter.isNameValidWithIndexError(_name);

        return (success_, int32(uint32(characterIndex)));
    }

    function getIdentityNFTId(string calldata _name) external view override returns (uint256) {
        return identityIds[_name];
    }

    function ownerOf(string calldata _name) external view returns (address) {
        return ownerOf(identityIds[_name]);
    }

    function updateNameFilter(address _newFilter) external onlyOwner {
        nameFilter = NameFilter(_newFilter);
        emit NameFilterUpdated(_newFilter);
    }

    function updateCost(uint256 _cost) external onlyOwner {
        cost = _cost;
        emit CostUpdated(_cost);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IValidatorIdentity {
    error EarlyBirdOnly();
    error InvalidProof();

    /**
     * @notice Identifier
     * @param name Name of the Wallet
     * @param tokenReceiver Address that will be receiving Ticker's reward if any
     */
    struct Identifier {
        string name;
        address tokenReceiver;
    }

    /**
     * @notice DelegatedIdentity
     * @param isEnabled If the Delegation is enabled
     * @param owner The original owner of the Identity
     * @param originalTokenReceiver The original Identifier::tokenReceiver
     * @param delegatee The one buying the delegation
     * @param durationInMonths The duration in months of the delegation
     * @param endDelegationTime The time when the bought delegation ends
     * @param cost The upfront cost of the delegation
     */
    struct DelegatedIdentity {
        bool isEnabled;
        address owner;
        address originalTokenReceiver;
        address delegatee;
        uint8 durationInMonths;
        uint32 endDelegationTime;
        uint128 cost;
    }

    error NotSigner();
    error ExpiredSignature();

    error DelegationNotOver();
    error DelegationNotActive();
    error DelegationOver();
    error NotDelegatee();
    error NotPaid();
    error InvalidMonthTime();

    event TokenReceiverUpdated(uint256 indexed walletId, string indexed walletName, address newTokenReceiver);
    event DelegationUpdated(string indexed identity, uint256 indexed nftId, bool isEnabled);
    event IdentityDelegated(
        string indexed identity, uint256 indexed nftId, address indexed delegatee, uint32 endPeriod
    );

    /**
     * createWithSignature Create an Identity with signature to avoid getting front-runned
     * @param _name Name of the Identity
     * @param _receiverWallet Wallet that will be receiving the rewards
     * @param _deadline Deadline of the signature
     * @param _signature signed message abi.encodePacket(userAddress,name,deadline)
     */
    function createWithSignature(
        string calldata _name,
        address _receiverWallet,
        uint256 _deadline,
        bytes memory _signature
    ) external payable;

    /**
     * create Create an Identity
     * @param _name name of the Identity
     * @param _receiverWallet Wallet that will be receiving the rewards
     */
    function create(string calldata _name, address _receiverWallet) external payable;

    /**
     * @notice delegate Send temporary your nft away to let other user use it for a period of time
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _delegateCost cost to accept this delegation
     * @param _amountOfMonths term duration in months
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function delegate(uint256 _nftId, string memory _name, uint128 _delegateCost, uint8 _amountOfMonths) external;

    /**
     * @notice acceptDelegation Accept a delegation to use it for yourself during the set period defined
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _receiverWallet wallet you want the token(s) to be minted to
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function acceptDelegation(uint256 _nftId, string memory _name, address _receiverWallet) external payable;
    /**
     * @notice toggleDelegation Disable/Enable your delegation, so if it's currently used, nobody won't be able to
     * accept it
     * when the term ends
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function toggleDelegation(uint256 _nftId, string memory _name) external;

    /**
     * @notice retrieveDelegation() your identity
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     * @dev Only the identity original; owner can call this and it shouldn't be during a delegation
     * @dev The system will automatically restore the original wallet receiver before transferring
     */
    function retrieveDelegation(uint256 _nftId, string memory _name) external;

    /**
     * updateDelegationWalletReceiver Update the wallet that will receive the token(s) from the delegation
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _receiverWallet wallet you want the token(s) to be minted to
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     * @dev only the delegatee can call this function. The term needs to be still active
     */
    function updateDelegationWalletReceiver(uint256 _nftId, string memory _name, address _receiverWallet) external;

    /**
     * updateReceiverAddress Update Receiver Wallet of an Identity
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @param _receiver address that will be receiving any rewards
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     * @dev Only the owner of the Identity can call this function
     */
    function updateReceiverAddress(uint256 _nftId, string memory _name, address _receiver) external;

    /**
     * getIdentityDataWithName Get Identity information with name
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @return identity_ tuple(name,tokenReceiver)
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function getIdentityData(uint256 _nftId, string calldata _name) external view returns (Identifier memory);

    /**
     * @notice getDelegationData() Retrieves delegation data using the identity name.
     * @param _nftId The ID of the NFT.
     * @param _name The name of the identity.
     * @dev Use either `_nftId` or `_name`. If you want to use `_name`, set `_nftId` to 0.
     */
    function getDelegationData(uint256 _nftId, string calldata _name)
        external
        view
        returns (DelegatedIdentity memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IIdentityERC721 {
    error NameAlreadyTaken();
    error InvalidCharacter(uint256 characterIndex);
    error ValueIsNotEqualsToCost();
    error TreasuryNotSet();
    error NotIdentityOwner();
    error InvalidIdZero();

    event NewIdentityCreated(uint256 indexed identityId, string indexed identityName, address indexed owner);
    event NameFilterUpdated(address indexed newNameFilter);
    event CostUpdated(uint256 newCost);
    event TreasuryUpdated(address newTreasury);

    /**
     * @notice getIdentityNFTId get the NFT Id attached to the name
     * @param _name Identity Name
     * @return nftId
     * @dev ID: 0 == DEAD_NFT
     */
    function getIdentityNFTId(string calldata _name) external view returns (uint256);

    /**
     * @notice ownerOf getOwner of the NFT with the Identity Name
     * @param _name Name of the Identity
     */
    function ownerOf(string calldata _name) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "./IERC721.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC721Metadata} from "./extensions/IERC721Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {Strings} from "../../utils/Strings.sol";
import {IERC165, ERC165} from "../../utils/introspection/ERC165.sol";
import {IERC721Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    mapping(uint256 tokenId => address) private _owners;

    mapping(address owner => uint256) private _balances;

    mapping(uint256 tokenId => address) private _tokenApprovals;

    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        unchecked {
            _balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                _balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title NameFilter
 * @notice It filters the character we do not allow in an Identity Name.
 * @dev It is in it's standalone as we might later on change the name filtering logic, allowing or removing unicodes
 */
contract NameFilter {
    function isNameValid(string calldata _str) external pure returns (bool valid_) {
        (valid_,) = isNameValidWithIndexError(_str);
        return valid_;
    }

    function isNameValidWithIndexError(string calldata _str) public pure returns (bool, uint256 index) {
        bytes memory strBytes = bytes(_str);
        uint8 charByte;
        uint16 charValue;

        if (strBytes.length == 0 || strBytes.length > 28) return (false, index);

        while (index < strBytes.length) {
            charByte = uint8(strBytes[index]);

            if (charByte <= 0x7F) {
                // Single byte character (Basic Latin range)
                if (
                    !(charByte > 0x20 && charByte <= 0x7E) || charByte == 0xA0 || charByte == 0x23 || charByte == 0x24
                        || charByte == 0x3A || charByte == 0x2C || charByte == 0x40 || charByte == 0x2D
                ) {
                    return (false, index);
                }
                index += 1;
            } else if (charByte < 0xE0) {
                // Two byte character
                if (index + 1 >= strBytes.length) {
                    return (false, index); // Incomplete UTF-8 sequence
                }
                charValue = (uint16(uint8(strBytes[index]) & 0x1F) << 6) | (uint16(uint8(strBytes[index + 1])) & 0x3F);
                if (
                    charValue < 0x00A0 || charValue == 0x200B || charValue == 0xFEFF
                        || (charValue >= 0x2000 && charValue <= 0x206F) // General Punctuation
                        || (charValue >= 0x2150 && charValue <= 0x218F) // Number Forms
                        || (charValue >= 0xFF00 && charValue <= 0xFFEF) // Halfwidth and Fullwidth Forms
                        || (charValue >= 161 && charValue <= 191) // Latin-1 Supplement
                        || charValue == 215 || charValue == 247 // Multiplication and Division signs
                ) {
                    return (false, index);
                }
                index += 2;
            } else {
                // Three byte character (CJK, Cyrillic, Arabic, Hebrew, Hangul Jamo, etc.)
                if (index + 2 >= strBytes.length) {
                    return (false, index); // Incomplete UTF-8 sequence
                }
                charValue = (uint16(uint8(strBytes[index]) & 0x0F) << 12)
                    | (uint16(uint8(strBytes[index + 1]) & 0x3F) << 6) | (uint16(uint8(strBytes[index + 2])) & 0x3F);
                if (
                    (charValue >= 0x1100 && charValue <= 0x11FF) // Hangul Jamo
                        || (charValue >= 0x0410 && charValue <= 0x044F) // Cyrillic
                        || (charValue >= 0x3040 && charValue <= 0x309F) // Hiragana
                        || (charValue >= 0x30A0 && charValue <= 0x30FF) // Katakana
                        || (charValue >= 0xAC00 && charValue <= 0xD7AF) // Hangul
                        || (charValue >= 0x0600 && charValue <= 0x06FF) // Arabic
                        || (charValue >= 0x05D0 && charValue <= 0x05EA) // Hebrew
                        || (charValue >= 20_000 && charValue <= 20_099) // Chinese limited range
                ) {
                    index += 3;
                } else {
                    return (false, index);
                }
            }
        }

        return (true, index);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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