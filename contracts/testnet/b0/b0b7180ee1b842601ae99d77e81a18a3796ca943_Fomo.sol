// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ITransferManager } from "./interfaces/ITransferManager.sol";
import { TokenType as TransferManagerTokenType } from "./enums/TokenType.sol";
import { IERC20 } from "./interfaces/generic/IERC20.sol";
import { SignatureCheckerMemory } from "./SignatureCheckerMemory.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";
import { Pausable } from "./Pausable.sol";

import { LowLevelWETH } from "./lowLevelCallers/LowLevelWETH.sol";
import { LowLevelERC20Transfer } from "./lowLevelCallers/LowLevelERC20Transfer.sol";
import { LowLevelERC721Transfer } from "./lowLevelCallers/LowLevelERC721Transfer.sol";

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

import { IFomo } from "./interfaces/IFomo.sol";
import { IPriceOracle } from "./interfaces/IPriceOracle.sol";
import { Arrays } from "./libraries/Arrays.sol";

/**
 * @title Fomo
 */
contract Fomo is
    IFomo,
    AccessControl,
    VRFConsumerBaseV2,
    LowLevelWETH,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    ReentrancyGuard,
    Pausable
{
    using Arrays for uint256[];

    /**
     * @notice Operators are allowed to add/remove allowed ERC-20 and ERC-721 tokens.
     */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice The maximum protocol fee in basis points, which is 25%.
     */
    uint16 public constant MAXIMUM_PROTOCOL_FEE_BP = 2500;

    /**
     * @notice Reservoir oracle's message typehash.
     * @dev It is used to compute the hash of the message using the (message) id, the payload, and the timestamp.
     */
    bytes32 private constant RESERVOIR_ORACLE_MESSAGE_TYPEHASH =
        keccak256("Message(bytes32 id,bytes payload,uint256 timestamp,uint256 chainId)");

    /**
     * @notice Reservoir oracle's ID typehash.
     * @dev It is used to compute the hash of the ID using price kind, TWAP seconds, and the contract address.
     */
    bytes32 private constant RESERVOIR_ORACLE_ID_TYPEHASH = keccak256(
        "ContractWideCollectionPrice(uint8 kind,uint256 twapSeconds,address contract,bool onlyNonFlaggedTokens)"
    );

    /**
     * @notice Wrapped Ether address.
     */
    address private immutable WETH;

    /**
     * @notice The key hash of the Chainlink VRF.
     */
    bytes32 private immutable KEY_HASH;

    /**
     * @notice The subscription ID of the Chainlink VRF.
     */
    uint64 public immutable SUBSCRIPTION_ID;

    /**
     * @notice The Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface private immutable VRF_COORDINATOR;

    /**
     * @notice Transfer manager faciliates token transfers.
     */
    ITransferManager private immutable transferManager;

    /**
     * @notice The value of each entry in ETH.
     */
    uint256 public valuePerEntry;

    /**
     * @notice The duration of each round.
     */
    uint40 public roundDuration;

    /**
     * @notice The address of the protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The protocol fee basis points.
     */
    uint16 public protocolFeeBp;

    /**
     * @notice Number of rounds that have been created.
     * @dev In this smart contract, roundId is an uint256 but its
     *      max value can only be 2^40 - 1. Realistically we will still
     *      not reach this number.
     */
    uint40 public roundsCount;

    /**
     * @notice The maximum number of participants per round.
     */
    uint40 public maximumNumberOfParticipantsPerRound;

    /**
     * @notice The maximum number of deposits per round.
     */
    uint40 public maximumNumberOfDepositsPerRound;

    /**
     * @notice ERC-20 oracle address.
     */
    IPriceOracle public erc20Oracle;

    /**
     * @notice Reservoir oracle address.
     */
    address public reservoirOracle;

    /**
     * @notice Reservoir oracle's signature validity period.
     */
    uint40 public signatureValidityPeriod;

    /**
     * @notice Randomness request waiting time.
     */
    uint40 public randomnessRequestWaitingTime;

    /**
     * @notice It checks whether the currency is allowed.
     * @dev 0 is not allowed, 1 is allowed.
     */
    mapping(address => uint256) public isCurrencyAllowed;

    /**
     * @dev roundId => Round
     */
    mapping(uint256 => Round) public rounds;

    /**
     * @dev roundId => depositor => depositCount
     */
    mapping(uint256 => mapping(address => uint256)) public depositCount;

    /**
     * @notice The randomness requests.
     * @dev The key is the request ID returned by Chainlink.
     */
    mapping(uint256 => RandomnessRequest) public randomnessRequests;

    /**
     * @dev Token/collection => round ID => price.
     */
    mapping(address => mapping(uint256 => uint256)) public prices;

    /**
     * @param params The constructor params.
     */
    constructor(ConstructorCalldata memory params) VRFConsumerBaseV2(params.vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, params.owner);
        _grantRole(OPERATOR_ROLE, params.operator);
        _updateRoundDuration(params.roundDuration);
        _updateProtocolFeeRecipient(params.protocolFeeRecipient);
        _updateProtocolFeeBp(params.protocolFeeBp);
        _updateValuePerEntry(params.valuePerEntry);
        _updateERC20Oracle(params.erc20Oracle);
        _updateMaximumNumberOfDepositsPerRound(params.maximumNumberOfDepositsPerRound);
        _updateMaximumNumberOfParticipantsPerRound(params.maximumNumberOfParticipantsPerRound);
        _updateReservoirOracle(params.reservoirOracle);
        _updateSignatureValidityPeriod(params.signatureValidityPeriod);
        _updateRandomnessRequestWaitingTime(params.randomnessRequestWaitingTime);

        WETH = params.weth;
        KEY_HASH = params.keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(params.vrfCoordinator);
        SUBSCRIPTION_ID = params.subscriptionId;

        transferManager = ITransferManager(params.transferManager);

        _startRound({ _roundsCount: 0 });
    }

    /**
     * @inheritdoc IFomo
     */
    function cancelCurrentRoundAndDepositToTheNextRound(DepositCalldata[] calldata deposits)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        uint256 roundId = roundsCount;
        _cancel(roundId);
        _deposit(_unsafeAdd(roundId, 1), deposits);
    }

    /**
     * @inheritdoc IFomo
     */
    function deposit(
        uint256 roundId,
        DepositCalldata[] calldata deposits
    )
        external
        payable
        nonReentrant
        whenNotPaused
    {
        _deposit(roundId, deposits);
    }

    /**
     * @inheritdoc IFomo
     */
    function getDeposits(uint256 roundId) external view returns (Deposit[] memory) {
        return rounds[roundId].deposits;
    }

    function drawWinner() external nonReentrant whenNotPaused {
        uint256 roundId = roundsCount;
        Round storage round = rounds[roundId];

        _validateRoundStatus(round, RoundStatus.Open);

        if (block.timestamp < round.cutoffTime) {
            revert CutoffTimeNotReached();
        }

        if (round.numberOfParticipants < 2) {
            revert InsufficientParticipants();
        }

        _drawWinner(round, roundId);
    }

    function cancel() external nonReentrant whenNotPaused {
        _cancel({ roundId: roundsCount });
    }

    /**
     * @inheritdoc IFomo
     */
    function cancelAfterRandomnessRequest() external nonReentrant whenNotPaused {
        uint256 roundId = roundsCount;
        Round storage round = rounds[roundId];

        _validateRoundStatus(round, RoundStatus.Drawing);

        if (block.timestamp < round.drawnAt + randomnessRequestWaitingTime) {
            revert DrawExpirationTimeNotReached();
        }

        round.status = RoundStatus.Cancelled;

        emit RoundStatusUpdated(roundId, RoundStatus.Cancelled);

        _startRound({ _roundsCount: roundId });
    }

    /**
     * @inheritdoc IFomo
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        TransferAccumulator memory transferAccumulator;
        uint256 ethAmount;
        uint256 protocolFeeOwed;

        for (uint256 i; i < claimPrizesCalldata.length;) {
            ClaimPrizesCalldata calldata perRoundClaimPrizesCalldata = claimPrizesCalldata[i];

            Round storage round = rounds[perRoundClaimPrizesCalldata.roundId];

            _validateRoundStatus(round, RoundStatus.Drawn);

            if (msg.sender != round.winner) {
                revert NotWinner();
            }

            uint256[] calldata prizeIndices = perRoundClaimPrizesCalldata.prizeIndices;

            for (uint256 j; j < prizeIndices.length;) {
                uint256 index = prizeIndices[j];
                if (index >= round.deposits.length) {
                    revert InvalidIndex();
                }

                Deposit storage prize = round.deposits[index];

                if (prize.withdrawn) {
                    revert AlreadyWithdrawn();
                }

                prize.withdrawn = true;

                TokenType tokenType = prize.tokenType;
                if (tokenType == TokenType.ETH) {
                    ethAmount += prize.tokenAmount;
                } else if (tokenType == TokenType.ERC721) {
                    _executeERC721TransferFrom(prize.tokenAddress, address(this), msg.sender, prize.tokenId);
                } else if (tokenType == TokenType.ERC20) {
                    address prizeAddress = prize.tokenAddress;
                    if (prizeAddress == transferAccumulator.tokenAddress) {
                        transferAccumulator.amount += prize.tokenAmount;
                    } else {
                        if (transferAccumulator.amount != 0) {
                            _executeERC20DirectTransfer(
                                transferAccumulator.tokenAddress, msg.sender, transferAccumulator.amount
                            );
                        }

                        transferAccumulator.tokenAddress = prizeAddress;
                        transferAccumulator.amount = prize.tokenAmount;
                    }
                }

                unchecked {
                    ++j;
                }
            }

            protocolFeeOwed += round.protocolFeeOwed;
            round.protocolFeeOwed = 0;

            emit PrizesClaimed(perRoundClaimPrizesCalldata.roundId, msg.sender, prizeIndices);

            unchecked {
                ++i;
            }
        }

        if (protocolFeeOwed != 0) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, protocolFeeRecipient, protocolFeeOwed, gasleft());

            protocolFeeOwed -= msg.value; // msg.value is the protocol fee paid
            if (protocolFeeOwed < ethAmount) {
                // ethAmount is the total prize amount, if protocolFeeOwed is less than ethAmount, then pay the protocol
                    // fee with ethAmount
                unchecked {
                    ethAmount -= protocolFeeOwed;
                }
                protocolFeeOwed = 0;
            } else {
                // if protocolFeeOwed is greater than ethAmount or equal to ethAmount, then protocolFeeOwed -= ethAmount
                unchecked {
                    protocolFeeOwed -= ethAmount;
                }
                ethAmount = 0;
            }

            if (protocolFeeOwed != 0) {
                // if protocolFeeOwed is not 0, then revert. it means protocolFeeOwed is greater than the addition of
                    // ethAmount and msg.value
                revert ProtocolFeeNotPaid();
            }
        }

        if (transferAccumulator.amount != 0) {
            _executeERC20DirectTransfer(transferAccumulator.tokenAddress, msg.sender, transferAccumulator.amount);
        }

        if (ethAmount != 0) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, ethAmount, gasleft());
        }
    }

    /**
     * @inheritdoc IFomo
     * @dev This function does not validate claimPrizesCalldata to not contain duplicate round IDs and prize indices.
     *      It is the responsibility of the caller to ensure that. Otherwise, the returned protocol fee owed will be
     * incorrect.
     */
    function getClaimPrizesPaymentRequired(ClaimPrizesCalldata[] calldata claimPrizesCalldata)
        external
        view
        returns (uint256 protocolFeeOwed)
    {
        uint256 ethAmount;

        for (uint256 i; i < claimPrizesCalldata.length;) {
            ClaimPrizesCalldata calldata perRoundClaimPrizesCalldata = claimPrizesCalldata[i];
            Round storage round = rounds[perRoundClaimPrizesCalldata.roundId];

            _validateRoundStatus(round, RoundStatus.Drawn);

            uint256[] calldata prizeIndices = perRoundClaimPrizesCalldata.prizeIndices;
            uint256 numberOfPrizes = prizeIndices.length;
            uint256 prizesCount = round.deposits.length;

            for (uint256 j; j < numberOfPrizes;) {
                uint256 index = prizeIndices[j];
                if (index >= prizesCount) {
                    revert InvalidIndex();
                }

                Deposit storage prize = round.deposits[index];
                if (prize.tokenType == TokenType.ETH) {
                    ethAmount += prize.tokenAmount;
                }

                unchecked {
                    ++j;
                }
            }

            protocolFeeOwed += round.protocolFeeOwed;

            unchecked {
                ++i;
            }
        }

        if (protocolFeeOwed < ethAmount) {
            protocolFeeOwed = 0;
        } else {
            unchecked {
                protocolFeeOwed -= ethAmount;
            }
        }
    }

    /**
     * @inheritdoc IFomo
     */
    function withdrawDeposits(uint256 roundId, uint256[] calldata depositIndices) external nonReentrant whenNotPaused {
        Round storage round = rounds[roundId];

        _validateRoundStatus(round, RoundStatus.Cancelled);

        uint256 numberOfDeposits = depositIndices.length;
        uint256 depositsCount = round.deposits.length;
        uint256 ethAmount;

        for (uint256 i; i < numberOfDeposits;) {
            uint256 index = depositIndices[i];
            if (index >= depositsCount) {
                revert InvalidIndex();
            }

            Deposit storage depositedToken = round.deposits[index];
            if (depositedToken.depositor != msg.sender) {
                revert NotDepositor();
            }

            if (depositedToken.withdrawn) {
                revert AlreadyWithdrawn();
            }

            depositedToken.withdrawn = true;

            TokenType tokenType = depositedToken.tokenType;
            if (tokenType == TokenType.ETH) {
                ethAmount += depositedToken.tokenAmount;
            } else if (tokenType == TokenType.ERC721) {
                _executeERC721TransferFrom(
                    depositedToken.tokenAddress, address(this), msg.sender, depositedToken.tokenId
                );
            } else if (tokenType == TokenType.ERC20) {
                _executeERC20DirectTransfer(depositedToken.tokenAddress, msg.sender, depositedToken.tokenAmount);
            }

            unchecked {
                ++i;
            }
        }

        if (ethAmount != 0) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, msg.sender, ethAmount, gasleft());
        }

        emit DepositsWithdrawn(roundId, msg.sender, depositIndices);
    }

    /**
     * @inheritdoc IFomo
     */
    function togglePaused() external {
        _validateIsOwner();
        paused() ? _unpause() : _pause();
    }

    /**
     * @inheritdoc IFomo
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external {
        _validateIsOperator();

        uint256 count = currencies.length;
        for (uint256 i; i < count;) {
            isCurrencyAllowed[currencies[i]] = (isAllowed ? 1 : 0);
            unchecked {
                ++i;
            }
        }
        emit CurrenciesStatusUpdated(currencies, isAllowed);
    }

    /**
     * @inheritdoc IFomo
     */
    function updateRoundDuration(uint40 _roundDuration) external {
        _validateIsOwner();
        _updateRoundDuration(_roundDuration);
    }

    /**
     *  @inheritdoc IFomo
     */
    function updateRandomnessRequestWaitingTime(uint40 _randomnessRequestWaitingTime) external {
        _validateIsOwner();
        _updateRandomnessRequestWaitingTime(_randomnessRequestWaitingTime);
    }

    /**
     * @inheritdoc IFomo
     */
    function updateSignatureValidityPeriod(uint40 _signatureValidityPeriod) external {
        _validateIsOwner();
        _updateSignatureValidityPeriod(_signatureValidityPeriod);
    }

    /**
     * @inheritdoc IFomo
     */
    function updateValuePerEntry(uint256 _valuePerEntry) external {
        _validateIsOwner();
        _updateValuePerEntry(_valuePerEntry);
    }

    /**
     * @inheritdoc IFomo
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external {
        _validateIsOwner();
        _updateProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IFomo
     */
    function updateProtocolFeeBp(uint16 _protocolFeeBp) external {
        _validateIsOwner();
        _updateProtocolFeeBp(_protocolFeeBp);
    }

    /**
     * @inheritdoc IFomo
     */
    function updateMaximumNumberOfDepositsPerRound(uint40 _maximumNumberOfDepositsPerRound) external {
        _validateIsOwner();
        _updateMaximumNumberOfDepositsPerRound(_maximumNumberOfDepositsPerRound);
    }

    /**
     * @inheritdoc IFomo
     */
    function updateMaximumNumberOfParticipantsPerRound(uint40 _maximumNumberOfParticipantsPerRound) external {
        _validateIsOwner();
        _updateMaximumNumberOfParticipantsPerRound(_maximumNumberOfParticipantsPerRound);
    }

    /**
     * @inheritdoc IFomo
     */
    function updateReservoirOracle(address _reservoirOracle) external {
        _validateIsOwner();
        _updateReservoirOracle(_reservoirOracle);
    }

    /**
     * @inheritdoc IFomo
     */
    function updateERC20Oracle(address _erc20Oracle) external {
        _validateIsOwner();
        _updateERC20Oracle(_erc20Oracle);
    }

    function _validateIsOwner() private view {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NotOwner();
        }
    }

    function _validateIsOperator() private view {
        if (!hasRole(OPERATOR_ROLE, msg.sender)) {
            revert NotOperator();
        }
    }

    /**
     * @param _roundDuration The duration of each round.
     */
    function _updateRoundDuration(uint40 _roundDuration) private {
        if (_roundDuration > 1 hours) {
            revert InvalidRoundDuration();
        }

        roundDuration = _roundDuration;
        emit RoundDurationUpdated(_roundDuration);
    }

    /**
     * @param _randomnessRequestWaitingTime The randomness request waiting time of each round.
     */
    function _updateRandomnessRequestWaitingTime(uint40 _randomnessRequestWaitingTime) private {
        randomnessRequestWaitingTime = _randomnessRequestWaitingTime;
        emit RandomnessRequestWaitingTimeUpdate(_randomnessRequestWaitingTime);
    }

    /**
     * @param _signatureValidityPeriod The validity period of a Reservoir signature.
     */
    function _updateSignatureValidityPeriod(uint40 _signatureValidityPeriod) private {
        signatureValidityPeriod = _signatureValidityPeriod;
        emit SignatureValidityPeriodUpdated(_signatureValidityPeriod);
    }

    /**
     * @param _valuePerEntry The value of each entry in ETH.
     */
    function _updateValuePerEntry(uint256 _valuePerEntry) private {
        if (_valuePerEntry == 0) {
            revert InvalidValue();
        }
        valuePerEntry = _valuePerEntry;
        emit ValuePerEntryUpdated(_valuePerEntry);
    }

    /**
     * @param _protocolFeeRecipient The new protocol fee recipient address
     */
    function _updateProtocolFeeRecipient(address _protocolFeeRecipient) private {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidValue();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @param _protocolFeeBp The new protocol fee in basis points
     */
    function _updateProtocolFeeBp(uint16 _protocolFeeBp) private {
        if (_protocolFeeBp > MAXIMUM_PROTOCOL_FEE_BP) {
            revert InvalidValue();
        }
        protocolFeeBp = _protocolFeeBp;
        emit ProtocolFeeBpUpdated(_protocolFeeBp);
    }

    /**
     * @param _maximumNumberOfDepositsPerRound The new maximum number of deposits per round
     */
    function _updateMaximumNumberOfDepositsPerRound(uint40 _maximumNumberOfDepositsPerRound) private {
        maximumNumberOfDepositsPerRound = _maximumNumberOfDepositsPerRound;
        emit MaximumNumberOfDepositsPerRoundUpdated(_maximumNumberOfDepositsPerRound);
    }

    /**
     * @param _maximumNumberOfParticipantsPerRound The new maximum number of participants per round
     */
    function _updateMaximumNumberOfParticipantsPerRound(uint40 _maximumNumberOfParticipantsPerRound) private {
        if (_maximumNumberOfParticipantsPerRound < 2) {
            revert InvalidValue();
        }
        maximumNumberOfParticipantsPerRound = _maximumNumberOfParticipantsPerRound;
        emit MaximumNumberOfParticipantsPerRoundUpdated(_maximumNumberOfParticipantsPerRound);
    }

    /**
     * @param _reservoirOracle The new Reservoir oracle address
     */
    function _updateReservoirOracle(address _reservoirOracle) private {
        if (_reservoirOracle == address(0)) {
            revert InvalidValue();
        }
        reservoirOracle = _reservoirOracle;
        emit ReservoirOracleUpdated(_reservoirOracle);
    }

    /**
     * @param _erc20Oracle The new ERC-20 oracle address
     */
    function _updateERC20Oracle(address _erc20Oracle) private {
        if (_erc20Oracle == address(0)) {
            revert InvalidValue();
        }
        erc20Oracle = IPriceOracle(_erc20Oracle);
        emit ERC20OracleUpdated(_erc20Oracle);
    }

    /**
     * @param _roundsCount The current rounds count
     */
    function _startRound(uint256 _roundsCount) private returns (uint256 roundId) {
        unchecked {
            roundId = _roundsCount + 1;
        }
        roundsCount = uint40(roundId);
        rounds[roundId].status = RoundStatus.Open;
        rounds[roundId].protocolFeeBp = protocolFeeBp;
        rounds[roundId].cutoffTime = uint40(block.timestamp) + roundDuration;
        rounds[roundId].maximumNumberOfDeposits = maximumNumberOfDepositsPerRound;
        rounds[roundId].maximumNumberOfParticipants = maximumNumberOfParticipantsPerRound;
        rounds[roundId].valuePerEntry = valuePerEntry;

        emit RoundStatusUpdated(roundId, RoundStatus.Open);
    }

    /**
     * @param round The open round.
     * @param roundId The open round ID.
     */
    function _drawWinner(Round storage round, uint256 roundId) private {
        round.status = RoundStatus.Drawing;
        round.drawnAt = uint40(block.timestamp);

        uint256 requestId = VRF_COORDINATOR.requestRandomWords({
            keyHash: KEY_HASH,
            subId: SUBSCRIPTION_ID,
            minimumRequestConfirmations: uint16(3),
            callbackGasLimit: uint32(500_000),
            numWords: uint32(1)
        });

        if (randomnessRequests[requestId].exists) {
            revert RandomnessRequestAlreadyExists();
        }

        randomnessRequests[requestId].exists = true;
        randomnessRequests[requestId].roundId = uint40(roundId);

        emit RandomnessRequested(roundId, requestId);
        emit RoundStatusUpdated(roundId, RoundStatus.Drawing);
    }

    /**
     * @param roundId The open round ID.
     * @param deposits The ERC-20/ERC-721 deposits to be made.
     */
    function _deposit(uint256 roundId, DepositCalldata[] calldata deposits) private {
        Round storage round = rounds[roundId];
        if (round.status != RoundStatus.Open || block.timestamp >= round.cutoffTime) {
            revert InvalidStatus();
        }

        uint256 userDepositCount = depositCount[roundId][msg.sender];
        if (userDepositCount == 0) {
            unchecked {
                ++round.numberOfParticipants;
            }
        }
        uint256 roundDepositCount = round.deposits.length;
        uint40 currentEntryIndex;
        uint256 totalEntriesCount;

        uint256 depositsCalldataLength = deposits.length;
        if (msg.value == 0) {
            if (depositsCalldataLength == 0) {
                // if msg.value is 0 and depositsCalldataLength is 0, it means the user is depositing 0
                revert ZeroDeposits();
            }
        } else {
            uint256 roundValuePerEntry = round.valuePerEntry;
            if (msg.value % roundValuePerEntry != 0) {
                // if msg.value is not divisible by roundValuePerEntry, it means the user is depositing an amount that
                    // is not a multiple of valuePerEntry
                revert InvalidValue();
            }
            uint256 entriesCount = msg.value / roundValuePerEntry;
            totalEntriesCount += entriesCount;

            currentEntryIndex = _getCurrentEntryIndexWithoutAccrual(round, roundDepositCount, entriesCount);

            round.deposits.push(
                Deposit({
                    tokenType: TokenType.ETH,
                    tokenAddress: address(0),
                    tokenId: 0,
                    tokenAmount: msg.value,
                    depositor: msg.sender,
                    withdrawn: false,
                    currentEntryIndex: currentEntryIndex
                })
            );

            unchecked {
                roundDepositCount += 1;
            }
        }

        if (depositsCalldataLength != 0) {
            ITransferManager.BatchTransferItem[] memory batchTransferItems = new ITransferManager.BatchTransferItem[](
                depositsCalldataLength
            );
            for (uint256 i; i < depositsCalldataLength;) {
                DepositCalldata calldata singleDeposit = deposits[i];
                if (isCurrencyAllowed[singleDeposit.tokenAddress] != 1) {
                    // if the currency is not allowed, revert
                    revert InvalidCollection();
                }
                uint256 price = prices[singleDeposit.tokenAddress][roundId];
                if (singleDeposit.tokenType == TokenType.ERC721) {
                    if (price == 0) {
                        price = _getReservoirPrice(singleDeposit);
                        prices[singleDeposit.tokenAddress][roundId] = price;
                    }

                    uint256 entriesCount = price / round.valuePerEntry;
                    if (entriesCount == 0) {
                        revert InvalidValue();
                    }

                    uint256 tokenIdsLength = singleDeposit.tokenIdsOrAmounts.length;
                    uint256[] memory amounts = new uint256[](tokenIdsLength);
                    for (uint256 j; j < tokenIdsLength;) {
                        totalEntriesCount += entriesCount;

                        if (currentEntryIndex != 0) {
                            currentEntryIndex += uint40(entriesCount);
                        } else {
                            currentEntryIndex =
                                _getCurrentEntryIndexWithoutAccrual(round, roundDepositCount, entriesCount);
                        }

                        // tokenAmount is in reality 1, but we never use it and it is cheaper to set it as 0.
                        round.deposits.push(
                            Deposit({
                                tokenType: TokenType.ERC721,
                                tokenAddress: singleDeposit.tokenAddress,
                                tokenId: singleDeposit.tokenIdsOrAmounts[j],
                                tokenAmount: 0,
                                depositor: msg.sender,
                                withdrawn: false,
                                currentEntryIndex: currentEntryIndex
                            })
                        );

                        amounts[j] = 1;

                        unchecked {
                            ++j;
                        }
                    }

                    unchecked {
                        roundDepositCount += tokenIdsLength;
                    }

                    batchTransferItems[i].tokenAddress = singleDeposit.tokenAddress;
                    batchTransferItems[i].tokenType = TransferManagerTokenType.ERC721;
                    batchTransferItems[i].itemIds = singleDeposit.tokenIdsOrAmounts;
                    batchTransferItems[i].amounts = amounts;
                } else if (singleDeposit.tokenType == TokenType.ERC20) {
                    if (price == 0) {
                        price = erc20Oracle.getTWAP(singleDeposit.tokenAddress, uint32(3600));
                        prices[singleDeposit.tokenAddress][roundId] = price;
                    }

                    uint256[] memory amounts = singleDeposit.tokenIdsOrAmounts;
                    if (amounts.length != 1) {
                        revert InvalidLength();
                    }

                    uint256 amount = amounts[0];

                    uint256 entriesCount =
                        ((price * amount) / (10 ** IERC20(singleDeposit.tokenAddress).decimals())) / round.valuePerEntry;
                    if (entriesCount == 0) {
                        revert InvalidValue();
                    }

                    totalEntriesCount += entriesCount;

                    if (currentEntryIndex != 0) {
                        currentEntryIndex += uint40(entriesCount);
                    } else {
                        currentEntryIndex = _getCurrentEntryIndexWithoutAccrual(round, roundDepositCount, entriesCount);
                    }

                    round.deposits.push(
                        Deposit({
                            tokenType: TokenType.ERC20,
                            tokenAddress: singleDeposit.tokenAddress,
                            tokenId: 0,
                            tokenAmount: amount,
                            depositor: msg.sender,
                            withdrawn: false,
                            currentEntryIndex: currentEntryIndex
                        })
                    );

                    unchecked {
                        roundDepositCount += 1;
                    }

                    batchTransferItems[i].tokenAddress = singleDeposit.tokenAddress;
                    batchTransferItems[i].tokenType = TransferManagerTokenType.ERC20;
                    batchTransferItems[i].amounts = singleDeposit.tokenIdsOrAmounts;
                } else {
                    revert InvalidTokenType();
                }

                unchecked {
                    ++i;
                }
            }

            transferManager.transferBatchItemsAcrossCollections(batchTransferItems, msg.sender, address(this));
        }

        {
            uint256 maximumNumberOfDeposits = round.maximumNumberOfDeposits;
            if (roundDepositCount > maximumNumberOfDeposits) {
                revert MaximumNumberOfDepositsReached();
            }

            uint256 numberOfParticipants = round.numberOfParticipants;

            if (
                numberOfParticipants == round.maximumNumberOfParticipants
                    || (numberOfParticipants > 1 && roundDepositCount == maximumNumberOfDeposits)
            ) {
                _drawWinner(round, roundId);
            }
        }

        unchecked {
            depositCount[roundId][msg.sender] = userDepositCount + 1;
        }

        emit Deposited(msg.sender, roundId, totalEntriesCount);
    }

    /**
     * @param roundId The ID of the round to be cancelled.
     */
    function _cancel(uint256 roundId) private {
        Round storage round = rounds[roundId];

        _validateRoundStatus(round, RoundStatus.Open);

        if (block.timestamp < round.cutoffTime) {
            revert CutoffTimeNotReached();
        }

        if (round.numberOfParticipants > 1) {
            revert RoundCannotBeClosed();
        }

        round.status = RoundStatus.Cancelled;

        emit RoundStatusUpdated(roundId, RoundStatus.Cancelled);

        _startRound({ _roundsCount: roundId });
    }

    /**
     * @param requestId The ID of the request
     * @param randomWords The random words returned by Chainlink
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (randomnessRequests[requestId].exists) {
            uint256 roundId = randomnessRequests[requestId].roundId;
            Round storage round = rounds[roundId];

            if (round.status == RoundStatus.Drawing) {
                round.status = RoundStatus.Drawn;
                uint256 randomWord = randomWords[0];
                randomnessRequests[requestId].randomWord = randomWord;

                uint256 count = round.deposits.length;
                uint256[] memory currentEntryIndexArray = new uint256[](count);
                for (uint256 i; i < count;) {
                    currentEntryIndexArray[i] = uint256(round.deposits[i].currentEntryIndex);
                    unchecked {
                        ++i;
                    }
                }

                uint256 currentEntryIndex = currentEntryIndexArray[_unsafeSubtract(count, 1)];
                uint256 entriesSold = _unsafeAdd(currentEntryIndex, 1);
                uint256 winningEntry = uint256(randomWord) % entriesSold;
                round.winner = round.deposits[currentEntryIndexArray.findUpperBound(winningEntry)].depositor;
                round.protocolFeeOwed = (round.valuePerEntry * entriesSold * round.protocolFeeBp) / 10_000;

                emit RoundStatusUpdated(roundId, RoundStatus.Drawn);

                _startRound({ _roundsCount: roundId });
            }
        }
    }

    /**
     * @param round The round to check the status of.
     * @param status The expected status of the round
     */
    function _validateRoundStatus(Round storage round, RoundStatus status) private view {
        if (round.status != status) {
            revert InvalidStatus();
        }
    }

    /**
     * @param collection The collection address.
     * @param floorPrice The floor price response from Reservoir oracle.
     */
    function _verifyReservoirSignature(
        address collection,
        ReservoirOracleFloorPrice calldata floorPrice
    )
        private
        view
    {
        if (block.timestamp > floorPrice.timestamp + uint256(signatureValidityPeriod)) {
            revert SignatureExpired();
        }

        bytes32 expectedMessageId =
            keccak256(abi.encode(RESERVOIR_ORACLE_ID_TYPEHASH, uint8(1), 86_400, collection, false));

        if (expectedMessageId != floorPrice.id) {
            revert MessageIdInvalid();
        }

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encode(
                        RESERVOIR_ORACLE_MESSAGE_TYPEHASH,
                        expectedMessageId,
                        keccak256(floorPrice.payload),
                        floorPrice.timestamp,
                        block.chainid
                    )
                )
            )
        );

        SignatureCheckerMemory.verify(messageHash, reservoirOracle, floorPrice.signature);
    }

    function _getReservoirPrice(DepositCalldata calldata singleDeposit) private view returns (uint256 price) {
        address currency;
        _verifyReservoirSignature(singleDeposit.tokenAddress, singleDeposit.reservoirOracleFloorPrice);
        (currency, price) = abi.decode(singleDeposit.reservoirOracleFloorPrice.payload, (address, uint256));
        if (currency != address(0)) {
            revert InvalidCurrency();
        }
    }

    /**
     * @param round The open round.
     * @param roundDepositCount The number of deposits in the round.
     * @param entriesCount The number of entries to be added.
     */
    function _getCurrentEntryIndexWithoutAccrual(
        Round storage round,
        uint256 roundDepositCount,
        uint256 entriesCount
    )
        private
        view
        returns (uint40 currentEntryIndex)
    {
        if (roundDepositCount == 0) {
            currentEntryIndex = uint40(_unsafeSubtract(entriesCount, 1));
        } else {
            currentEntryIndex =
                uint40(round.deposits[_unsafeSubtract(roundDepositCount, 1)].currentEntryIndex + entriesCount);
        }
    }

    /**
     * Unsafe math functions.
     */

    function _unsafeAdd(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a + b;
        }
    }

    function _unsafeSubtract(uint256 a, uint256 b) private pure returns (uint256) {
        unchecked {
            return a - b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// Enums
import { TokenType } from "../enums/TokenType.sol";

/**
 * @title ITransferManager
 */
interface ITransferManager {
    /**
     * @notice This struct is only used for transferBatchItemsAcrossCollections.
     * @param tokenAddress Token address
     * @param tokenType 0 for ERC721, 1 for ERC1155
     * @param itemIds Array of item ids to transfer
     * @param amounts Array of amounts to transfer
     */
    struct BatchTransferItem {
        address tokenAddress;
        TokenType tokenType;
        uint256[] itemIds;
        uint256[] amounts;
    }

    /**
     * @notice It is emitted if operators' approvals to transfer NFTs are granted by a user.
     * @param user Address of the user
     * @param operators Array of operator addresses
     */
    event ApprovalsGranted(address user, address[] operators);

    /**
     * @notice It is emitted if operators' approvals to transfer NFTs are revoked by a user.
     * @param user Address of the user
     * @param operators Array of operator addresses
     */
    event ApprovalsRemoved(address user, address[] operators);

    /**
     * @notice It is emitted if a new operator is added to the global allowlist.
     * @param operator Operator address
     */
    event OperatorAllowed(address operator);

    /**
     * @notice It is emitted if an operator is removed from the global allowlist.
     * @param operator Operator address
     */
    event OperatorRemoved(address operator);

    /**
     * @notice It is returned if the operator to approve has already been approved by the user.
     */
    error OperatorAlreadyApprovedByUser();

    /**
     * @notice It is returned if the operator to revoke has not been previously approved by the user.
     */
    error OperatorNotApprovedByUser();

    /**
     * @notice It is returned if the transfer caller is already allowed by the owner.
     * @dev This error can only be returned for owner operations.
     */
    error OperatorAlreadyAllowed();

    /**
     * @notice It is returned if the operator to approve is not in the global allowlist defined by the owner.
     * @dev This error can be returned if the user tries to grant approval to an operator address not in the
     *      allowlist or if the owner tries to remove the operator from the global allowlist.
     */
    error OperatorNotAllowed();

    /**
     * @notice It is returned if the transfer caller is invalid.
     *         For a transfer called to be valid, the operator must be in the global allowlist and
     *         approved by the 'from' user.
     */
    error TransferCallerInvalid();

    /**
     * @notice This function transfers ERC20 tokens.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param amount amount
     */
    function transferERC20(address tokenAddress, address from, address to, uint256 amount) external;

    /**
     * @notice This function transfers a single item for a single ERC721 collection.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param itemId Item ID
     */
    function transferItemERC721(address tokenAddress, address from, address to, uint256 itemId) external;

    /**
     * @notice This function transfers items for a single ERC721 collection.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     */
    function transferItemsERC721(
        address tokenAddress,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    )
        external;

    /**
     * @notice This function transfers a single item for a single ERC1155 collection.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param itemId Item ID
     * @param amount Amount
     */
    function transferItemERC1155(
        address tokenAddress,
        address from,
        address to,
        uint256 itemId,
        uint256 amount
    )
        external;

    /**
     * @notice This function transfers items for a single ERC1155 collection.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param itemIds Array of itemIds
     * @param amounts Array of amounts
     * @dev It does not allow batch transferring if from = msg.sender since native function should be used.
     */
    function transferItemsERC1155(
        address tokenAddress,
        address from,
        address to,
        uint256[] calldata itemIds,
        uint256[] calldata amounts
    )
        external;

    /**
     * @notice This function transfers items across an array of tokens that can be ERC20, ERC721 and ERC1155.
     * @param items Array of BatchTransferItem
     * @param from Sender address
     * @param to Recipient address
     */
    function transferBatchItemsAcrossCollections(
        BatchTransferItem[] calldata items,
        address from,
        address to
    )
        external;

    /**
     * @notice This function allows a user to grant approvals for an array of operators.
     *         Users cannot grant approvals if the operator is not allowed by this contract's owner.
     * @param operators Array of operator addresses
     * @dev Each operator address must be globally allowed to be approved.
     */
    function grantApprovals(address[] calldata operators) external;

    /**
     * @notice This function allows a user to revoke existing approvals for an array of operators.
     * @param operators Array of operator addresses
     * @dev Each operator address must be approved at the user level to be revoked.
     */
    function revokeApprovals(address[] calldata operators) external;

    /**
     * @notice This function allows an operator to be added for the shared transfer system.
     *         Once the operator is allowed, users can grant NFT approvals to this operator.
     * @param operator Operator address to allow
     * @dev Only callable by owner.
     */
    function allowOperator(address operator) external;

    /**
     * @notice This function allows the user to remove an operator for the shared transfer system.
     * @param operator Operator address to remove
     * @dev Only callable by owner.
     */
    function removeOperator(address operator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC1271} from "./interfaces/generic/IERC1271.sol";

// Constants
import {ERC1271_MAGIC_VALUE} from "./constants/StandardConstants.sol";

// Errors
import {SignatureParameterSInvalid, SignatureParameterVInvalid, SignatureERC1271Invalid, SignatureEOAInvalid, NullSignerAddress, SignatureLengthInvalid} from "./errors/SignatureCheckerErrors.sol";

/**
 * @title SignatureCheckerMemory
 * @notice This library is used to verify signatures for EOAs (with lengths of both 65 and 64 bytes)
 *         and contracts (ERC1271).
 */
library SignatureCheckerMemory {
    /**
     * @notice This function verifies whether the signer is valid for a hash and raw signature.
     * @param hash Data hash
     * @param signer Signer address (to confirm message validity)
     * @param signature Signature parameters encoded (v, r, s)
     * @dev For EIP-712 signatures, the hash must be the digest (computed with signature hash and domain separator)
     */
    function verify(bytes32 hash, address signer, bytes memory signature) internal view {
        if (signer.code.length == 0) {
            if (_recoverEOASigner(hash, signature) == signer) return;
            revert SignatureEOAInvalid();
        } else {
            if (IERC1271(signer).isValidSignature(hash, signature) == ERC1271_MAGIC_VALUE) return;
            revert SignatureERC1271Invalid();
        }
    }

    /**
     * @notice This function is internal and splits a signature into r, s, v outputs.
     * @param signature A 64 or 65 bytes signature
     * @return r The r output of the signature
     * @return s The s output of the signature
     * @return v The recovery identifier, must be 27 or 28
     */
    function splitSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        uint256 length = signature.length;

        if (length == 65) {
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (length == 64) {
            assembly {
                r := mload(add(signature, 0x20))
                let vs := mload(add(signature, 0x40))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert SignatureLengthInvalid(length);
        }

        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert SignatureParameterSInvalid();
        }

        if (v != 27 && v != 28) {
            revert SignatureParameterVInvalid(v);
        }
    }

    /**
     * @notice This function is private and recovers the signer of a signature (for EOA only).
     * @param hash Hash of the signed message
     * @param signature Bytes containing the signature (64 or 65 bytes)
     * @return signer The address that signed the signature
     */
    function _recoverEOASigner(bytes32 hash, bytes memory signature) private pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        // If the signature is valid (and not malleable), return the signer's address
        signer = ecrecover(hash, v, r, s);

        if (signer == address(0)) {
            revert NullSignerAddress();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IReentrancyGuard} from "./interfaces/IReentrancyGuard.sol";

/**
 * @title ReentrancyGuard
 * @notice This contract protects against reentrancy attacks.
 *         It is adjusted from OpenZeppelin.
 */
abstract contract ReentrancyGuard is IReentrancyGuard {
    uint256 private _status;

    /**
     * @notice Modifier to wrap functions to prevent reentrancy calls.
     */
    modifier nonReentrant() {
        if (_status == 2) {
            revert ReentrancyFail();
        }

        _status = 2;
        _;
        _status = 1;
    }

    constructor() {
        _status = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Pausable
 * @notice This contract makes it possible to pause the contract.
 *         It is adjusted from OpenZeppelin.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    error IsPaused();
    error NotPaused();

    bool private _paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert IsPaused();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert NotPaused();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IWETH} from "../interfaces/generic/IWETH.sol";

/**
 * @title LowLevelWETH
 * @notice This contract contains a function to transfer ETH with an option to wrap to WETH.
 *         If the ETH transfer fails within a gas limit, the amount in ETH is wrapped to WETH and then transferred.
 */
contract LowLevelWETH {
    /**
     * @notice It transfers ETH to a recipient with a specified gas limit.
     *         If the original transfers fails, it wraps to WETH and transfers the WETH to recipient.
     * @param _WETH WETH address
     * @param _to Recipient address
     * @param _amount Amount to transfer
     * @param _gasLimit Gas limit to perform the ETH transfer
     */
    function _transferETHAndWrapIfFailWithGasLimit(
        address _WETH,
        address _to,
        uint256 _amount,
        uint256 _gasLimit
    ) internal {
        bool status;

        assembly {
            status := call(_gasLimit, _to, _amount, 0, 0, 0, 0)
        }

        if (!status) {
            IWETH(_WETH).deposit{value: _amount}();
            IWETH(_WETH).transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC20} from "../interfaces/generic/IERC20.sol";

// Errors
import {ERC20TransferFail, ERC20TransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC20Transfer
 * @notice This contract contains low-level calls to transfer ERC20 tokens.
 */
contract LowLevelERC20Transfer {
    /**
     * @notice Execute ERC20 transferFrom
     * @param currency Currency address
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20TransferFrom(address currency, address from, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.transferFrom, (from, to, amount)));

        if (!status) {
            revert ERC20TransferFromFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20TransferFromFail();
            }
        }
    }

    /**
     * @notice Execute ERC20 (direct) transfer
     * @param currency Currency address
     * @param to Recipient address
     * @param amount Amount to transfer
     */
    function _executeERC20DirectTransfer(address currency, address to, uint256 amount) internal {
        if (currency.code.length == 0) {
            revert NotAContract();
        }

        (bool status, bytes memory data) = currency.call(abi.encodeCall(IERC20.transfer, (to, amount)));

        if (!status) {
            revert ERC20TransferFail();
        }

        if (data.length > 0) {
            if (!abi.decode(data, (bool))) {
                revert ERC20TransferFail();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC721} from "../interfaces/generic/IERC721.sol";

// Errors
import {ERC721TransferFromFail} from "../errors/LowLevelErrors.sol";
import {NotAContract} from "../errors/GenericErrors.sol";

/**
 * @title LowLevelERC721Transfer
 * @notice This contract contains low-level calls to transfer ERC721 tokens.
 */
contract LowLevelERC721Transfer {
    /**
     * @notice Execute ERC721 transferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     */
    function _executeERC721TransferFrom(address collection, address from, address to, uint256 tokenId) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC721.transferFrom, (from, to, tokenId)));

        if (!status) {
            revert ERC721TransferFromFail();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IFomo {
    enum RoundStatus {
        None,
        Open,
        Drawing,
        Drawn,
        Cancelled
    }

    enum TokenType {
        ETH,
        ERC20,
        ERC721
    }

    event CurrenciesStatusUpdated(address[] currencies, bool isAllowed);
    event Deposited(address depositor, uint256 roundId, uint256 entriesCount);
    event ERC20OracleUpdated(address erc20Oracle);
    event MaximumNumberOfDepositsPerRoundUpdated(uint40 maximumNumberOfDepositsPerRound);
    event MaximumNumberOfParticipantsPerRoundUpdated(uint40 maximumNumberOfParticipantsPerRound);
    event PrizesClaimed(uint256 roundId, address winner, uint256[] prizeIndices);
    event DepositsWithdrawn(uint256 roundId, address depositor, uint256[] depositIndices);
    event ProtocolFeeBpUpdated(uint16 protocolFeeBp);
    event ProtocolFeeRecipientUpdated(address protocolFeeRecipient);
    event RandomnessRequested(uint256 roundId, uint256 requestId);
    event RandomnessRequestWaitingTimeUpdate(uint40 randomnessRequestWaitingTime);
    event ReservoirOracleUpdated(address reservoirOracle);
    event RoundDurationUpdated(uint40 roundDuration);
    event RoundStatusUpdated(uint256 roundId, RoundStatus status);
    event SignatureValidityPeriodUpdated(uint40 signatureValidityPeriod);
    event ValuePerEntryUpdated(uint256 valuePerEntry);

    error AlreadyWithdrawn();
    error CutoffTimeNotReached();
    error DrawExpirationTimeNotReached();
    error InsufficientParticipants();
    error InvalidCollection();
    error InvalidCurrency();
    error InvalidIndex();
    error InvalidLength();
    error InvalidRoundDuration();
    error InvalidStatus();
    error InvalidTokenType();
    error InvalidValue();
    error MaximumNumberOfDepositsReached();
    error MessageIdInvalid();
    error NotOperator();
    error NotOwner();
    error NotWinner();
    error NotDepositor();
    error ProtocolFeeNotPaid();
    error RandomnessRequestAlreadyExists();
    error RoundCannotBeClosed();
    error SignatureExpired();
    error ZeroDeposits();

    /**
     * @param owner The owner of the contract.
     * @param operator The operator of the contract.
     * @param roundDuration The duration of each round.
     * @param valuePerEntry The value of each entry in ETH.
     * @param protocolFeeRecipient The protocol fee recipient.
     * @param protocolFeeBp The protocol fee basis points.
     * @param keyHash Chainlink VRF key hash
     * @param subscriptionId Chainlink VRF subscription ID
     * @param vrfCoordinator Chainlink VRF coordinator address
     * @param reservoirOracle Reservoir off-chain oracle address
     * @param erc20Oracle ERC20 on-chain oracle address
     * @param transferManager Transfer manager
     * @param signatureValidityPeriod The validity period of a Reservoir signature.
     */
    struct ConstructorCalldata {
        address owner;
        address operator;
        uint40 maximumNumberOfDepositsPerRound;
        uint40 maximumNumberOfParticipantsPerRound;
        uint40 roundDuration;
        uint256 valuePerEntry;
        address protocolFeeRecipient;
        uint16 protocolFeeBp;
        bytes32 keyHash;
        uint64 subscriptionId;
        address vrfCoordinator;
        address reservoirOracle;
        address transferManager;
        address erc20Oracle;
        address weth;
        uint40 signatureValidityPeriod;
        uint40 randomnessRequestWaitingTime;
    }

    /**
     * @param id The id of the response.
     * @param payload The payload of the response.
     * @param timestamp The timestamp of the response.
     * @param signature The signature of the response.
     */
    struct ReservoirOracleFloorPrice {
        bytes32 id;
        bytes payload;
        uint256 timestamp;
        bytes signature;
    }

    struct DepositCalldata {
        TokenType tokenType;
        address tokenAddress;
        uint256[] tokenIdsOrAmounts;
        ReservoirOracleFloorPrice reservoirOracleFloorPrice;
    }

    struct Round {
        RoundStatus status;
        address winner;
        uint40 cutoffTime;
        uint40 drawnAt;
        uint40 numberOfParticipants;
        uint40 maximumNumberOfDeposits;
        uint40 maximumNumberOfParticipants;
        uint16 protocolFeeBp;
        uint256 protocolFeeOwed;
        uint256 valuePerEntry;
        Deposit[] deposits;
    }

    struct Deposit {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId;
        uint256 tokenAmount;
        address depositor;
        bool withdrawn;
        uint40 currentEntryIndex;
    }

    /**
     * @param exists Whether the request exists.
     * @param roundId The id of the round.
     * @param randomWord The random words returned by Chainlink VRF.
     *                   If randomWord == 0, then the request is still pending.
     */
    struct RandomnessRequest {
        bool exists;
        uint40 roundId;
        uint256 randomWord;
    }

    /**
     * @param roundId The id of the round.
     * @param prizeIndices The indices of the prizes to be claimed.
     */
    struct ClaimPrizesCalldata {
        uint256 roundId;
        uint256[] prizeIndices;
    }

    /**
     * @notice This is used to accumulate the amount of tokens to be transferred.
     * @param tokenAddress The address of the token.
     * @param amount The amount of tokens accumulated.
     */
    struct TransferAccumulator {
        address tokenAddress;
        uint256 amount;
    }

    function cancel() external;

    /**
     * @notice Cancels a round after randomness request if the randomness request
     *         does not arrive after a certain amount of time.
     *         Only callable by contract owner.
     */
    function cancelAfterRandomnessRequest() external;

    /**
     * @param claimPrizesCalldata The rounds and the indices for the rounds for the prizes to claim.
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata) external payable;

    /**
     * @notice This function calculates the ETH payment required to claim the prizes for multiple rounds.
     * @param claimPrizesCalldata The rounds and the indices for the rounds for the prizes to claim.
     */
    function getClaimPrizesPaymentRequired(ClaimPrizesCalldata[] calldata claimPrizesCalldata)
        external
        view
        returns (uint256 protocolFeeOwed);

    /**
     * @notice This function allows withdrawal of deposits from a round if the round is cancelled
     * @param roundId The drawn round ID.
     * @param depositIndices The indices of the deposits to withdraw.
     */
    function withdrawDeposits(uint256 roundId, uint256[] calldata depositIndices) external;

    /**
     * @param roundId The open round ID.
     * @param deposits The ERC-20/ERC-721 deposits to be made.
     */
    function deposit(uint256 roundId, DepositCalldata[] calldata deposits) external payable;

    /**
     * @param deposits The ERC-20/ERC-721 deposits to be made.
     */
    function cancelCurrentRoundAndDepositToTheNextRound(DepositCalldata[] calldata deposits) external payable;

    function drawWinner() external;

    /**
     * @param roundId The round ID.
     */
    function getDeposits(uint256 roundId) external view returns (Deposit[] memory);

    /**
     * @notice This function allows the owner to pause/unpause the contract.
     */
    function togglePaused() external;

    /**
     * @notice This function allows the owner to update currency statuses (ETH, ERC-20 and NFTs).
     * @param currencies Currency addresses (address(0) for ETH)
     * @param isAllowed Whether the currencies should be allowed in the fomos
     * @dev Only callable by owner.
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external;

    /**
     * @notice This function allows the owner to update the duration of each round.
     * @param _roundDuration The duration of each round.
     */
    function updateRoundDuration(uint40 _roundDuration) external;

    /**
     * @notice This function allows the owner to update the waiting time for the reqeust of the randomness.
     * @param _randomnessRequestWaitingTime The randomness request waiting time of each round.
     */
    function updateRandomnessRequestWaitingTime(uint40 _randomnessRequestWaitingTime) external;

    /**
     * @notice This function allows the owner to update the signature validity period.
     * @param _signatureValidityPeriod The signature validity period.
     */
    function updateSignatureValidityPeriod(uint40 _signatureValidityPeriod) external;

    /**
     * @notice This function allows the owner to update the value of each entry in ETH.
     * @param _valuePerEntry The value of each entry in ETH.
     */
    function updateValuePerEntry(uint256 _valuePerEntry) external;

    /**
     * @notice This function allows the owner to update the protocol fee in basis points.
     * @param protocolFeeBp The protocol fee in basis points.
     */
    function updateProtocolFeeBp(uint16 protocolFeeBp) external;

    /**
     * @notice This function allows the owner to update the protocol fee recipient.
     * @param protocolFeeRecipient The protocol fee recipient.
     */
    function updateProtocolFeeRecipient(address protocolFeeRecipient) external;

    /**
     * @notice This function allows the owner to update Reservoir oracle's address.
     * @param reservoirOracle Reservoir oracle address.
     */
    function updateReservoirOracle(address reservoirOracle) external;

    /**
     * @notice This function allows the owner to update the maximum number of participants per round.
     * @param _maximumNumberOfParticipantsPerRound The maximum number of participants per round.
     */
    function updateMaximumNumberOfParticipantsPerRound(uint40 _maximumNumberOfParticipantsPerRound) external;

    /**
     * @notice This function allows the owner to update the maximum number of deposits per round.
     * @param _maximumNumberOfDepositsPerRound The maximum number of deposits per round.
     */
    function updateMaximumNumberOfDepositsPerRound(uint40 _maximumNumberOfDepositsPerRound) external;

    /**
     * @notice This function allows the owner to update ERC20 oracle's address.
     * @param erc20Oracle ERC20 oracle address.
     */
    function updateERC20Oracle(address erc20Oracle) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IPriceOracle {
    error PoolNotAllowed();
    error PriceIsZero();

    event PoolAdded(address token, address pool);
    event PoolRemoved(address token);

    function getTWAP(address token, uint32 secondsAgo) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 *      Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Arrays.sol
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] memory array, uint256 element) internal pure returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                unchecked {
                    low = mid + 1;
                }
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            unchecked {
                return low - 1;
            }
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev ERC1271's magic value (bytes4(keccak256("isValidSignature(bytes32,bytes)"))
 */
bytes4 constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the signer is null.
 */
error NullSignerAddress();

/**
 * @notice It is emitted if the signature is invalid for an EOA (the address recovered is not the expected one).
 */
error SignatureEOAInvalid();

/**
 * @notice It is emitted if the signature is invalid for a ERC1271 contract signer.
 */
error SignatureERC1271Invalid();

/**
 * @notice It is emitted if the signature's length is neither 64 nor 65 bytes.
 */
error SignatureLengthInvalid(uint256 length);

/**
 * @notice It is emitted if the signature is invalid due to S parameter.
 */
error SignatureParameterSInvalid();

/**
 * @notice It is emitted if the signature is invalid due to V parameter.
 */
error SignatureParameterVInvalid(uint8 v);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IReentrancyGuard
 */
interface IReentrancyGuard {
    /**
     * @notice This is returned when there is a reentrant call.
     */
    error ReentrancyFail();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the ETH transfer fails.
 */
error ETHTransferFail();

/**
 * @notice It is emitted if the ERC20 approval fails.
 */
error ERC20ApprovalFail();

/**
 * @notice It is emitted if the ERC20 transfer fails.
 */
error ERC20TransferFail();

/**
 * @notice It is emitted if the ERC20 transferFrom fails.
 */
error ERC20TransferFromFail();

/**
 * @notice It is emitted if the ERC721 transferFrom fails.
 */
error ERC721TransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeTransferFrom fails.
 */
error ERC1155SafeTransferFromFail();

/**
 * @notice It is emitted if the ERC1155 safeBatchTransferFrom fails.
 */
error ERC1155SafeBatchTransferFromFail();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @notice It is emitted if the call recipient is not a contract.
 */
error NotAContract();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
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
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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