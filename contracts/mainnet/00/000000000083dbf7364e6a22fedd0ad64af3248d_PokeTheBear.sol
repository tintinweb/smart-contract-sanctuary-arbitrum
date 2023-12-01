// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LowLevelWETH} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelWETH.sol";
import {LowLevelERC20Transfer} from "@looksrare/contracts-libs/contracts/lowLevelCallers/LowLevelERC20Transfer.sol";
import {PackableReentrancyGuard} from "@looksrare/contracts-libs/contracts/PackableReentrancyGuard.sol";
import {Pausable} from "@looksrare/contracts-libs/contracts/Pausable.sol";

import {ITransferManager} from "@looksrare/contracts-transfer-manager/contracts/interfaces/ITransferManager.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {IPokeTheBear} from "./interfaces/IPokeTheBear.sol";

//       ∩＿＿＿∩
//      |ノ      ヽ
//     /   ●    ● | クマ──！！
//    |     (_●_) ミ
//   彡､     |∪|  ､｀＼
// / ＿＿    ヽノ /´>   )
// (＿＿＿）     /  (_／
//   |        /
//   |   ／＼  ＼
//   | /     )   )
//    ∪     （   ＼
//            ＼＿)

/**
 * @title Poke The Bear, a bear might maul you to death if you poke it.
 * @author LooksRare protocol team (👀,💎)
 */
contract PokeTheBear is
    IPokeTheBear,
    AccessControl,
    Pausable,
    PackableReentrancyGuard,
    LowLevelERC20Transfer,
    LowLevelWETH,
    VRFConsumerBaseV2
{
    /**
     * @notice Operators are allowed to commit rounds
     */
    bytes32 private constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
     * @notice 100% in basis points.
     */
    uint256 private constant ONE_HUNDRED_PERCENT_IN_BASIS_POINTS = 10_000;

    /**
     * @notice The maximum number of players per round.
     */
    uint256 private constant MAXIMUM_NUMBER_OF_PLAYERS_PER_ROUND = 32;

    /**
     * @notice The minimum duration for a round.
     */
    uint40 private constant MINIMUM_ROUND_DURATION = 1 minutes;

    /**
     * @notice The maximum duration for a round.
     */
    uint40 private constant MAXIMUM_ROUND_DURATION = 1 hours;

    /**
     * @notice Wrapped native token address. (WETH for most chains)
     */
    address private immutable WRAPPED_NATIVE_TOKEN;

    /**
     * @notice The key hash of the Chainlink VRF.
     */
    bytes32 private immutable KEY_HASH;

    /**
     * @notice The subscription ID of the Chainlink VRF.
     */
    uint64 private immutable SUBSCRIPTION_ID;

    /**
     * @notice The Chainlink VRF coordinator.
     */
    VRFCoordinatorV2Interface private immutable VRF_COORDINATOR;

    /**
     * @notice The transfer manager to handle ERC-20 deposits.
     */
    ITransferManager private immutable TRANSFER_MANAGER;

    mapping(uint256 requestId => RandomnessRequest) public randomnessRequests;

    mapping(uint256 caveId => mapping(uint256 => Round)) private rounds;

    /**
     * @notice Player participations in each round.
     * @dev 65,536 x 256 = 16,777,216 rounds, which is enough for 5 minutes rounds for 159 years.
     */
    mapping(address playerAddress => mapping(uint256 caveId => uint256[65536] roundIds)) private playerParticipations;

    mapping(uint256 caveId => Cave) public caves;

    /**
     * @notice The address of the protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The next cave ID.
     */
    uint256 public nextCaveId = 1;

    /**
     * @param _owner The owner of the contract.
     * @param _protocolFeeRecipient The address of the protocol fee recipient.
     * @param wrappedNativeToken The wrapped native token address.
     * @param _transferManager The transfer manager to handle ERC-20 deposits.
     * @param keyHash The key hash of the Chainlink VRF.
     * @param vrfCoordinator The Chainlink VRF coordinator.
     * @param subscriptionId The subscription ID of the Chainlink VRF.
     */
    constructor(
        address _owner,
        address _operator,
        address _protocolFeeRecipient,
        address wrappedNativeToken,
        address _transferManager,
        bytes32 keyHash,
        address vrfCoordinator,
        uint64 subscriptionId
    ) VRFConsumerBaseV2(vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(OPERATOR_ROLE, _operator);
        WRAPPED_NATIVE_TOKEN = wrappedNativeToken;
        KEY_HASH = keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        SUBSCRIPTION_ID = subscriptionId;
        TRANSFER_MANAGER = ITransferManager(_transferManager);

        _updateProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function addCave(
        uint256 enterAmount,
        address enterCurrency,
        uint8 playersPerRound,
        uint40 roundDuration,
        uint16 protocolFeeBp
    ) external returns (uint256 caveId) {
        _validateIsOwner();

        if (playersPerRound < 2) {
            revert InsufficientNumberOfPlayers();
        }

        if (playersPerRound > MAXIMUM_NUMBER_OF_PLAYERS_PER_ROUND) {
            revert ExceedsMaximumNumberOfPlayersPerRound();
        }

        if (protocolFeeBp > 2_500) {
            revert ProtocolFeeBasisPointsTooHigh();
        }

        unchecked {
            if (
                (enterAmount - ((enterAmount * protocolFeeBp) / ONE_HUNDRED_PERCENT_IN_BASIS_POINTS)) %
                    (playersPerRound - 1) !=
                0
            ) {
                revert IndivisibleEnterAmount();
            }
        }

        if (roundDuration < MINIMUM_ROUND_DURATION || roundDuration > MAXIMUM_ROUND_DURATION) {
            revert InvalidRoundDuration();
        }

        caveId = nextCaveId;

        caves[caveId].enterAmount = enterAmount;
        caves[caveId].enterCurrency = enterCurrency;
        caves[caveId].playersPerRound = playersPerRound;
        caves[caveId].roundDuration = roundDuration;
        caves[caveId].protocolFeeBp = protocolFeeBp;
        caves[caveId].isActive = true;

        _open({caveId: caveId, roundId: 1});

        unchecked {
            ++nextCaveId;
        }

        emit CaveAdded(caveId, enterAmount, enterCurrency, roundDuration, playersPerRound, protocolFeeBp);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function removeCave(uint256 caveId) external {
        _validateIsOwner();

        Cave storage cave = caves[caveId];
        if (cave.roundsCount < cave.lastCommittedRoundId) {
            revert RoundsIncomplete();
        }

        caves[caveId].isActive = false;
        emit CaveRemoved(caveId);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function commit(CommitmentCalldata[] calldata commitments) external {
        _validateIsOperator();
        uint256 commitmentsLength = commitments.length;
        for (uint256 i; i < commitmentsLength; ) {
            uint256 caveId = commitments[i].caveId;
            Cave storage cave = caves[caveId];
            if (!cave.isActive) {
                revert InactiveCave();
            }

            uint256 startingRoundId = cave.lastCommittedRoundId + 1;

            bytes32[] calldata perCaveCommitments = commitments[i].commitments;
            uint256 perCaveCommitmentsLength = perCaveCommitments.length;

            for (uint256 j; j < perCaveCommitmentsLength; ) {
                uint256 roundId = startingRoundId + j;
                bytes32 commitment = perCaveCommitments[j];

                if (commitment == bytes32(0)) {
                    revert InvalidCommitment(caveId, roundId);
                }

                rounds[caveId][roundId].commitment = commitment;

                unchecked {
                    ++j;
                }
            }

            cave.lastCommittedRoundId = uint40(startingRoundId + perCaveCommitmentsLength - 1);

            unchecked {
                ++i;
            }
        }

        emit CommitmentsSubmitted(commitments);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external {
        _validateIsOwner();
        _updateProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IPokeTheBear
     * @notice As rounds to enter are in numerical order and cannot be skipped,
               entering multiple rounds can revert when a round in between is already filled.
               Resolve by sending multiple transactions of consecutive rounds if such issue exists.
               Fee on transfer tokens will not be supported.
     * @dev Players can still deposit into the round past the cutoff time. Only when other players start withdrawing
     *      or deposit into the next round, the current round will be cancelled and no longer accept deposits.
     */
    function enter(
        uint256 caveId,
        uint256 startingRoundId,
        uint256 numberOfRounds
    ) external payable nonReentrant whenNotPaused {
        Cave storage cave = caves[caveId];

        address enterCurrency = cave.enterCurrency;
        uint256 enterAmount = cave.enterAmount * numberOfRounds;

        if (enterCurrency == address(0)) {
            if (msg.value != enterAmount) {
                revert InvalidEnterAmount();
            }
        } else {
            if (msg.value != 0) {
                revert InvalidEnterCurrency();
            }
            TRANSFER_MANAGER.transferERC20(enterCurrency, msg.sender, address(this), enterAmount);
        }

        _enter(caveId, startingRoundId, numberOfRounds);
    }

    /**
     * @inheritdoc IPokeTheBear
     * @dev Player index starts from 1 as the array has a fixed length of 32 and
     *      0 is used to indicate an empty slot.
     */
    function reveal(uint256 requestId, uint256 playerIndices, bytes32 salt) external whenNotPaused {
        RandomnessRequest storage randomnessRequest = randomnessRequests[requestId];
        uint256 caveId = randomnessRequest.caveId;
        uint256 roundId = randomnessRequest.roundId;

        Round storage round = rounds[caveId][roundId];
        if (round.status != RoundStatus.Drawn) {
            revert InvalidRoundStatus();
        }

        if (keccak256(abi.encodePacked(playerIndices, salt)) != round.commitment) {
            revert HashedPlayerIndicesDoesNotMatchCommitment();
        }

        uint256 numberOfPlayers = round.players.length;
        uint256 losingIndex = (randomnessRequest.randomWord % numberOfPlayers) + 1;

        // Check numbers are nonrepeating and within the range
        uint256 playerIndicesBitmap;
        for (uint256 i; i < numberOfPlayers; ) {
            uint8 playerIndex = uint8(playerIndices >> (i * 8));

            // Player index starts from 1
            if (playerIndex == 0 || playerIndex > numberOfPlayers) {
                revert InvalidPlayerIndex(caveId, roundId);
            }

            uint256 bitmask = 1 << playerIndex;

            if (playerIndicesBitmap & bitmask != 0) {
                revert RepeatingPlayerIndex();
            }

            playerIndicesBitmap |= bitmask;

            round.playerIndices[i] = playerIndex;

            if (playerIndex == losingIndex) {
                round.players[i].isLoser = true;
            }

            unchecked {
                ++i;
            }
        }

        round.salt = salt;
        round.status = RoundStatus.Revealed;

        emit RoundStatusUpdated(caveId, roundId, RoundStatus.Revealed);

        Cave storage cave = caves[caveId];
        _transferTokens(
            protocolFeeRecipient,
            cave.enterCurrency,
            (cave.enterAmount * cave.protocolFeeBp) / ONE_HUNDRED_PERCENT_IN_BASIS_POINTS
        );

        _open(caveId, _unsafeAdd(roundId, 1));
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function refund(WithdrawalCalldata[] calldata refundCalldataArray) external nonReentrant whenNotPaused {
        TransferAccumulator memory transferAccumulator;
        uint256 refundCount = refundCalldataArray.length;

        Withdrawal[] memory withdrawalEventData = new Withdrawal[](refundCount);

        for (uint256 i; i < refundCount; ) {
            WithdrawalCalldata calldata refundCalldata = refundCalldataArray[i];
            uint256 caveId = refundCalldata.caveId;
            Cave storage cave = caves[caveId];
            uint256 roundsCount = refundCalldata.playerDetails.length;

            Withdrawal memory withdrawal = withdrawalEventData[i];
            withdrawal.caveId = caveId;
            withdrawal.roundIds = new uint256[](roundsCount);

            for (uint256 j; j < roundsCount; ) {
                PlayerWithdrawalCalldata calldata playerDetails = refundCalldata.playerDetails[j];
                uint256 roundId = playerDetails.roundId;

                Round storage round = rounds[caveId][roundId];
                RoundStatus roundStatus = round.status;
                uint256 currentNumberOfPlayers = round.players.length;

                {
                    if (roundStatus < RoundStatus.Revealed) {
                        if (!_cancellable(round, roundStatus, cave.playersPerRound, currentNumberOfPlayers)) {
                            revert InvalidRoundStatus();
                        }
                        _cancel(caveId, roundId);
                    }

                    uint256 playerIndex = playerDetails.playerIndex;
                    if (playerIndex >= currentNumberOfPlayers) {
                        revert InvalidPlayerIndex(caveId, roundId);
                    }

                    Player storage player = round.players[playerIndex];
                    _validatePlayerCanWithdraw(caveId, roundId, player);
                    player.withdrawn = true;
                }

                withdrawal.roundIds[j] = roundId;

                unchecked {
                    ++j;
                }
            }

            _accumulateOrTransferTokenOut(cave.enterAmount * roundsCount, cave.enterCurrency, transferAccumulator);

            unchecked {
                ++i;
            }
        }

        if (transferAccumulator.amount != 0) {
            _transferTokens(msg.sender, transferAccumulator.tokenAddress, transferAccumulator.amount);
        }

        emit DepositsRefunded(withdrawalEventData, msg.sender);
    }

    /**
     * @inheritdoc IPokeTheBear
     * @dev If a player chooses to rollover his prizes, only the principal is rolled over. The profit is
     *      always sent back to the player.
     */
    function rollover(RolloverCalldata[] calldata rolloverCalldataArray) external payable nonReentrant whenNotPaused {
        TransferAccumulator memory entryAccumulator;
        TransferAccumulator memory prizeAccumulator;
        Rollover[] memory rolloverEventData = new Rollover[](rolloverCalldataArray.length);

        uint256 msgValueLeft = msg.value;
        for (uint256 i; i < rolloverCalldataArray.length; ) {
            RolloverCalldata calldata rolloverCalldata = rolloverCalldataArray[i];
            uint256 roundsCount = rolloverCalldata.playerDetails.length;
            if (roundsCount == 0) {
                revert InvalidPlayerDetails();
            }

            uint256 caveId = rolloverCalldata.caveId;
            Cave storage cave = caves[caveId];
            uint256 numberOfExtraRoundsToEnter = rolloverCalldata.numberOfExtraRoundsToEnter;
            address enterCurrency = cave.enterCurrency;

            // Enter extra rounds
            if (numberOfExtraRoundsToEnter != 0) {
                if (enterCurrency == address(0)) {
                    msgValueLeft -= cave.enterAmount * numberOfExtraRoundsToEnter;
                } else {
                    if (enterCurrency == entryAccumulator.tokenAddress) {
                        entryAccumulator.amount += cave.enterAmount * numberOfExtraRoundsToEnter;
                    } else {
                        if (entryAccumulator.amount != 0) {
                            TRANSFER_MANAGER.transferERC20(
                                entryAccumulator.tokenAddress,
                                msg.sender,
                                address(this),
                                entryAccumulator.amount
                            );
                        }

                        entryAccumulator.tokenAddress = enterCurrency;
                        entryAccumulator.amount = cave.enterAmount * numberOfExtraRoundsToEnter;
                    }
                }
            }

            Rollover memory rolloverEvent = rolloverEventData[i];
            rolloverEvent.caveId = caveId;
            rolloverEvent.rolledOverRoundIds = new uint256[](roundsCount);

            uint256 prizeAmount;

            for (uint256 j; j < roundsCount; ) {
                PlayerWithdrawalCalldata calldata playerDetails = rolloverCalldata.playerDetails[j];

                RoundStatus roundStatus = _handleRolloverRound(playerDetails, caveId, cave.playersPerRound);

                if (roundStatus == RoundStatus.Revealed) {
                    prizeAmount += _prizeAmount(cave);
                }

                rolloverEvent.rolledOverRoundIds[j] = playerDetails.roundId;

                unchecked {
                    ++j;
                }
            }

            uint256 startingRoundId = rolloverCalldata.startingRoundId;
            rolloverEvent.rollingOverToRoundIdStart = startingRoundId;

            _enter({
                caveId: caveId,
                startingRoundId: startingRoundId,
                numberOfRounds: roundsCount + numberOfExtraRoundsToEnter
            });

            if (prizeAmount != 0) {
                _accumulateOrTransferTokenOut(prizeAmount, enterCurrency, prizeAccumulator);
            }

            unchecked {
                ++i;
            }
        }

        if (msgValueLeft != 0) {
            revert InvalidEnterAmount();
        }

        if (entryAccumulator.amount != 0) {
            TRANSFER_MANAGER.transferERC20(
                entryAccumulator.tokenAddress,
                msg.sender,
                address(this),
                entryAccumulator.amount
            );
        }

        if (prizeAccumulator.amount != 0) {
            _transferTokens(msg.sender, prizeAccumulator.tokenAddress, prizeAccumulator.amount);
        }

        emit DepositsRolledOver(rolloverEventData, msg.sender);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function claimPrizes(WithdrawalCalldata[] calldata claimPrizeCalldataArray) external nonReentrant whenNotPaused {
        TransferAccumulator memory transferAccumulator;
        uint256 claimPrizeCount = claimPrizeCalldataArray.length;

        Withdrawal[] memory withdrawalEventData = new Withdrawal[](claimPrizeCount);

        for (uint256 i; i < claimPrizeCount; ) {
            WithdrawalCalldata calldata claimPrizeCalldata = claimPrizeCalldataArray[i];
            uint256 caveId = claimPrizeCalldata.caveId;

            Cave storage cave = caves[caveId];
            uint256 roundAmount = cave.enterAmount + _prizeAmount(cave);

            PlayerWithdrawalCalldata[] calldata playerDetailsArray = claimPrizeCalldata.playerDetails;
            uint256 roundsCount = playerDetailsArray.length;

            Withdrawal memory withdrawal = withdrawalEventData[i];
            withdrawal.caveId = caveId;
            withdrawal.roundIds = new uint256[](roundsCount);

            for (uint256 j; j < roundsCount; ) {
                PlayerWithdrawalCalldata calldata playerDetails = playerDetailsArray[j];
                uint256 roundId = playerDetails.roundId;

                Round storage round = rounds[caveId][roundId];
                if (round.status != RoundStatus.Revealed) {
                    revert InvalidRoundStatus();
                }

                Player storage player = round.players[playerDetails.playerIndex];
                _validatePlayerCanWithdraw(caveId, roundId, player);

                player.withdrawn = true;

                withdrawal.roundIds[j] = roundId;

                unchecked {
                    ++j;
                }
            }

            _accumulateOrTransferTokenOut(roundAmount * roundsCount, cave.enterCurrency, transferAccumulator);

            unchecked {
                ++i;
            }
        }

        if (transferAccumulator.amount != 0) {
            _transferTokens(msg.sender, transferAccumulator.tokenAddress, transferAccumulator.amount);
        }

        emit PrizesClaimed(withdrawalEventData, msg.sender);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function cancel(uint256 caveId) external nonReentrant {
        Cave storage cave = caves[caveId];
        uint40 roundsCount = cave.roundsCount;
        Round storage round = rounds[caveId][roundsCount];
        if (!_cancellable(round, round.status, cave.playersPerRound, round.players.length)) {
            revert NotCancellable();
        }
        _cancel(caveId, roundsCount);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function cancel(uint256 caveId, uint256 numberOfRounds) external nonReentrant whenPaused {
        _validateIsOwner();

        Cave storage cave = caves[caveId];
        uint256 startingRoundId = cave.roundsCount;
        uint256 lastRoundId = startingRoundId + numberOfRounds - 1;

        if (numberOfRounds == 0 || lastRoundId > cave.lastCommittedRoundId) {
            revert NotCancellable();
        }

        for (uint256 roundId = startingRoundId; roundId <= lastRoundId; ) {
            rounds[caveId][roundId].status = RoundStatus.Cancelled;
            unchecked {
                ++roundId;
            }
        }

        cave.roundsCount = uint40(lastRoundId);

        emit RoundsCancelled(caveId, startingRoundId, numberOfRounds);
    }

    function getRound(
        uint256 caveId,
        uint256 roundId
    )
        external
        view
        returns (
            RoundStatus status,
            uint40 cutoffTime,
            uint40 drawnAt,
            bytes32 commitment,
            bytes32 salt,
            uint8[32] memory playerIndices,
            Player[] memory players
        )
    {
        Round memory round = rounds[caveId][roundId];
        return (
            round.status,
            round.cutoffTime,
            round.drawnAt,
            round.commitment,
            round.salt,
            round.playerIndices,
            round.players
        );
    }

    /**
     * @dev Checks if the round is cancellable. A round is cancellable if its status is Cancelled,
     *      its status is Open but it has passed its cutoff time, its status is Drawing but Chainlink VRF
     *      callback did not happen on time, or its status is Drawn but the result was not revealed.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round.
     */
    function cancellable(uint256 caveId, uint256 roundId) external view returns (bool) {
        Round storage round = rounds[caveId][roundId];
        return _cancellable(round, round.status, caves[caveId].playersPerRound, round.players.length);
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function togglePaused() external {
        _validateIsOwner();
        paused() ? _unpause() : _pause();
    }

    /**
     * @inheritdoc IPokeTheBear
     */
    function isPlayerInRound(uint256 caveId, uint256 roundId, address player) public view returns (bool) {
        uint256 bucket = roundId >> 8;
        uint256 slot = 1 << (roundId & 0xff);
        return playerParticipations[player][caveId][bucket] & slot != 0;
    }

    /**
     * @param requestId The ID of the request
     * @param randomWords The random words returned by Chainlink
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        if (randomnessRequests[requestId].exists) {
            uint256 caveId = randomnessRequests[requestId].caveId;
            uint256 roundId = randomnessRequests[requestId].roundId;

            Round storage round = rounds[caveId][roundId];

            if (round.status == RoundStatus.Drawing) {
                round.status = RoundStatus.Drawn;
                randomnessRequests[requestId].randomWord = randomWords[0];

                emit RoundStatusUpdated(caveId, roundId, RoundStatus.Drawn);
            }
        }
    }

    /**
     * @dev This function is used to enter rounds, charging is done outside of this function.
     * @param caveId The ID of the cave.
     * @param startingRoundId The ID of the starting round.
     * @param numberOfRounds The number of rounds to enter.
     */
    function _enter(uint256 caveId, uint256 startingRoundId, uint256 numberOfRounds) private {
        if (startingRoundId == 0 || numberOfRounds == 0) {
            revert InvalidRoundParameters();
        }

        Cave storage cave = caves[caveId];

        if (!cave.isActive) {
            revert InactiveCave();
        }

        uint256 endingRoundIdPlusOne = startingRoundId + numberOfRounds;

        if (_unsafeSubtract(endingRoundIdPlusOne, 1) > cave.lastCommittedRoundId) {
            revert CommitmentNotAvailable();
        }

        Round storage startingRound = rounds[caveId][startingRoundId];
        // We just need to check the first round's status. If the first round is open,
        // subsequent rounds will not be drawn/cancelled as well.
        RoundStatus startingRoundStatus = startingRound.status;
        if (startingRoundStatus > RoundStatus.Open) {
            revert RoundCannotBeEntered(caveId, startingRoundId);
        }

        uint8 playersPerRound = cave.playersPerRound;

        if (startingRoundStatus == RoundStatus.None) {
            if (startingRoundId > 1) {
                uint256 lastRoundId = _unsafeSubtract(startingRoundId, 1);
                Round storage lastRound = rounds[caveId][lastRoundId];
                if (_cancellable(lastRound, lastRound.status, playersPerRound, lastRound.players.length)) {
                    _cancel(caveId, lastRoundId);
                    // The current round is now open (_cancel calls _open), we can manually change startingRoundStatus without touching the storage.
                    startingRoundStatus = RoundStatus.Open;
                }
            }
        }

        for (uint256 roundId = startingRoundId; roundId < endingRoundIdPlusOne; ) {
            if (isPlayerInRound(caveId, roundId, msg.sender)) {
                revert PlayerAlreadyParticipated(caveId, roundId, msg.sender);
            }
            // Starting round already exists from outside the loop so we can reuse it for gas efficiency.
            Round storage round = roundId == startingRoundId ? startingRound : rounds[caveId][roundId];
            uint256 newNumberOfPlayers = _unsafeAdd(round.players.length, 1);
            // This is not be a problem for the current open round, but this
            // can be a problem for future rounds.
            if (newNumberOfPlayers > playersPerRound) {
                revert RoundCannotBeEntered(caveId, roundId);
            }

            round.players.push(Player({addr: msg.sender, isLoser: false, withdrawn: false}));
            _markPlayerInRound(caveId, roundId, msg.sender);

            // Start countdown only for the current round and only if it is the first player.
            if (roundId == startingRoundId) {
                if (startingRoundStatus == RoundStatus.Open) {
                    if (round.cutoffTime == 0) {
                        round.cutoffTime = uint40(block.timestamp) + cave.roundDuration;
                    }

                    if (newNumberOfPlayers == playersPerRound) {
                        _draw(caveId, roundId);
                    }
                }
            }

            unchecked {
                ++roundId;
            }
        }

        emit RoundsEntered(caveId, startingRoundId, numberOfRounds, msg.sender);
    }

    /**
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round to draw.
     */
    function _draw(uint256 caveId, uint256 roundId) private {
        rounds[caveId][roundId].status = RoundStatus.Drawing;
        rounds[caveId][roundId].drawnAt = uint40(block.timestamp);

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
        randomnessRequests[requestId].caveId = uint40(caveId);
        randomnessRequests[requestId].roundId = uint40(roundId);

        emit RandomnessRequested(caveId, roundId, requestId);
        emit RoundStatusUpdated(caveId, roundId, RoundStatus.Drawing);
    }

    /**
     * @dev This function cancels the current round and opens the next round.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round to cancel.
     */
    function _cancel(uint256 caveId, uint256 roundId) private {
        rounds[caveId][roundId].status = RoundStatus.Cancelled;
        emit RoundStatusUpdated(caveId, roundId, RoundStatus.Cancelled);
        _open(caveId, _unsafeAdd(roundId, 1));
    }

    /**
     * @dev This function opens a new round.
     *      If the new round is already fully filled, it will be drawn immediately.
     *      If the round is partially filled, the countdown starts.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round to open.
     */
    function _open(uint256 caveId, uint256 roundId) private {
        Round storage round = rounds[caveId][roundId];
        uint256 playersCount = round.players.length;
        Cave storage cave = caves[caveId];

        if (playersCount == cave.playersPerRound) {
            _draw(caveId, roundId);
        } else {
            round.status = RoundStatus.Open;
            cave.roundsCount = uint40(roundId);
            emit RoundStatusUpdated(caveId, roundId, RoundStatus.Open);

            if (playersCount != 0) {
                round.cutoffTime = uint40(block.timestamp) + cave.roundDuration;
            }
        }
    }

    /**
     * @param playerDetails Information about the player to rollover.
     * @param caveId The ID of the cave.
     * @param playersPerRound The number of required players.
     */
    function _handleRolloverRound(
        PlayerWithdrawalCalldata calldata playerDetails,
        uint256 caveId,
        uint8 playersPerRound
    ) private returns (RoundStatus roundStatus) {
        uint256 roundId = playerDetails.roundId;
        uint256 playerIndex = playerDetails.playerIndex;
        Round storage round = rounds[caveId][roundId];
        roundStatus = round.status;
        uint256 currentNumberOfPlayers = round.players.length;

        if (roundStatus < RoundStatus.Revealed) {
            if (!_cancellable(round, roundStatus, playersPerRound, currentNumberOfPlayers)) {
                revert InvalidRoundStatus();
            }
            _cancel(caveId, roundId);
        }

        if (playerIndex >= currentNumberOfPlayers) {
            revert InvalidPlayerIndex(caveId, roundId);
        }

        Player storage player = round.players[playerIndex];
        _validatePlayerCanWithdraw(caveId, roundId, player);
        player.withdrawn = true;
    }

    /**
     * @param recipient The recipient of the transfer.
     * @param currency The transfer currency.
     * @param amount The transfer amount.
     */
    function _transferTokens(address recipient, address currency, uint256 amount) private {
        if (currency == address(0)) {
            _transferETHAndWrapIfFailWithGasLimit(WRAPPED_NATIVE_TOKEN, recipient, amount, gasleft());
        } else {
            _executeERC20DirectTransfer(currency, recipient, amount);
        }
    }

    /**
     * @param tokenAmount The amount of tokens to accumulate.
     * @param tokenAddress The token address to accumulate.
     * @param transferAccumulator The transfer accumulator state so far.
     */
    function _accumulateOrTransferTokenOut(
        uint256 tokenAmount,
        address tokenAddress,
        TransferAccumulator memory transferAccumulator
    ) private {
        if (tokenAddress == transferAccumulator.tokenAddress) {
            transferAccumulator.amount += tokenAmount;
        } else {
            if (transferAccumulator.amount != 0) {
                _transferTokens(msg.sender, transferAccumulator.tokenAddress, transferAccumulator.amount);
            }

            transferAccumulator.tokenAddress = tokenAddress;
            transferAccumulator.amount = tokenAmount;
        }
    }

    /**
     * @notice Marks a player as participated in a round.
     * @dev A round starts with the ID 1 and the bitmap starts with the index 0, therefore we need to subtract 1.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round.
     * @param player The address of the player.
     */
    function _markPlayerInRound(uint256 caveId, uint256 roundId, address player) private {
        uint256 bucket = roundId >> 8;
        uint256 slot = 1 << (roundId & 0xff);
        playerParticipations[player][caveId][bucket] |= slot;
    }

    /**
     * @notice Checks if the round data fulfills an expired open round.
     * @param roundStatus The status of the round.
     * @param cutoffTime The cutoff time of the round.
     * @param currentNumberOfPlayers The current number of players in the round.
     * @param playersPerRound The maximum number of players in a round.
     */
    function _isExpiredOpenRound(
        RoundStatus roundStatus,
        uint40 cutoffTime,
        uint256 currentNumberOfPlayers,
        uint8 playersPerRound
    ) private view returns (bool) {
        return
            roundStatus == RoundStatus.Open &&
            cutoffTime != 0 &&
            block.timestamp >= cutoffTime &&
            currentNumberOfPlayers < playersPerRound;
    }

    /**
     * @notice Checks if the round is pending VRF or commitment reveal for too long. We tolerate a delay of up to 1 day.
     * @param roundStatus The status of the round.
     * @param round The round to check.
     */
    function _pendingVRFOrRevealForTooLong(RoundStatus roundStatus, Round storage round) private view returns (bool) {
        return
            (roundStatus == RoundStatus.Drawing || roundStatus == RoundStatus.Drawn) &&
            block.timestamp >= round.drawnAt + 1 days;
    }

    /**
     * @dev player.isLoser is a check for claimPrize only, but it is also useful to act as an invariant for refund.
     * @param caveId The ID of the cave.
     * @param roundId The ID of the round.
     * @param player The player.
     */
    function _validatePlayerCanWithdraw(uint256 caveId, uint256 roundId, Player storage player) private view {
        if (player.isLoser || player.withdrawn || player.addr != msg.sender) {
            revert IneligibleToWithdraw(caveId, roundId);
        }
    }

    /**
     * @dev Checks if the round is cancellable. A round is cancellable if its status is Cancelled,
     *      its status is Open but it has passed its cutoff time, its status is Drawing but Chainlink VRF
     *      callback did not happen on time, or its status is Drawn but the result was not revealed.
     * @param round The round to check.
     * @param roundStatus The status of the round.
     * @param playersPerRound The maximum number of players in the round.
     * @param currentNumberOfPlayers The current number of players in the round.
     */
    function _cancellable(
        Round storage round,
        RoundStatus roundStatus,
        uint8 playersPerRound,
        uint256 currentNumberOfPlayers
    ) private view returns (bool) {
        return
            _isExpiredOpenRound(roundStatus, round.cutoffTime, currentNumberOfPlayers, playersPerRound) ||
            _pendingVRFOrRevealForTooLong(roundStatus, round);
    }

    /**
     * @param _protocolFeeRecipient The new protocol fee recipient address
     */
    function _updateProtocolFeeRecipient(address _protocolFeeRecipient) internal {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidValue();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @notice Calculates the prize amount.
     * @param cave The cave to calculate the prize amount.
     */
    function _prizeAmount(Cave storage cave) private view returns (uint256) {
        return
            (cave.enterAmount * (_unsafeSubtract(ONE_HUNDRED_PERCENT_IN_BASIS_POINTS, cave.protocolFeeBp))) /
            ONE_HUNDRED_PERCENT_IN_BASIS_POINTS /
            _unsafeSubtract(cave.playersPerRound, 1);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IWETH} from "../interfaces/generic/IWETH.sol";

/**
 * @title LowLevelWETH
 * @notice This contract contains a function to transfer ETH with an option to wrap to WETH.
 *         If the ETH transfer fails within a gas limit, the amount in ETH is wrapped to WETH and then transferred.
 * @author LooksRare protocol team (👀,💎)
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
 * @author LooksRare protocol team (👀,💎)
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
import {IReentrancyGuard} from "./interfaces/IReentrancyGuard.sol";

/**
 * @title PackableReentrancyGuard
 * @notice This contract protects against reentrancy attacks.
 *         It is adjusted from OpenZeppelin.
 *         The only difference between this contract and ReentrancyGuard
 *         is that _status is uint8 instead of uint256 so that it can be
 *         packed with other contracts' storage variables.
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract PackableReentrancyGuard is IReentrancyGuard {
    uint8 private _status;

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
 * @author LooksRare protocol team (👀,💎)
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
pragma solidity 0.8.20;

// Enums
import {TokenType} from "../enums/TokenType.sol";

/**
 * @title ITransferManager
 * @author LooksRare protocol team (👀,💎)
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
    function transferERC20(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) external;

    /**
     * @notice This function transfers a single item for a single ERC721 collection.
     * @param tokenAddress Token address
     * @param from Sender address
     * @param to Recipient address
     * @param itemId Item ID
     */
    function transferItemERC721(
        address tokenAddress,
        address from,
        address to,
        uint256 itemId
    ) external;

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
    ) external;

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
    ) external;

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
    ) external;

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
    ) external;

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

    /**
     * @notice This returns whether the user has approved the operator address.
     * The first address is the user and the second address is the operator.
     */
    function hasUserApprovedOperator(address user, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

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
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
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
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
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
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
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
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
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
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

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
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

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

interface IPokeTheBear {
    /**
     * @notice The status of a round.
     *         None: The round hasn't started yet.
     *         Open: The round is open for players to enter.
     *         Drawing: The round is being drawn using Chainlink VRF.
     *         Drawn: The round has been drawn. Chainlink VRF has returned a random number.
     *         Revealed: The loser has been revealed.
     *         Cancelled: The round has been cancelled.
     */
    enum RoundStatus {
        None,
        Open,
        Drawing,
        Drawn,
        Revealed,
        Cancelled
    }

    /**
     * @notice A player in a round.
     * @param addr The address of the player.
     * @param isLoser Whether the player is the loser.
     * @param withdrawn Whether the player has withdrawn the prize or the original deposit.
     */
    struct Player {
        address addr;
        bool isLoser;
        bool withdrawn;
    }

    /**
     * @notice A round of Poke The Bear.
     * @param status The status of the round.
     * @param cutoffTime The cutoff time to start or cancel the round if there aren't enough players.
     * @param drawnAt The timestamp when the round was drawn.
     * @param commitment The commitment of the shuffled player indices.
     * @param salt The salt used to generate the commitment.
     * @param playerIndices The player indices.
     * @param players The players.
     */
    struct Round {
        RoundStatus status;
        uint40 cutoffTime;
        uint40 drawnAt;
        bytes32 commitment;
        bytes32 salt;
        uint8[32] playerIndices;
        Player[] players;
    }

    /**
     * @param exists Whether the request exists.
     * @param caveId The id of the cave.
     * @param roundId The id of the round.
     * @param randomWord The random words returned by Chainlink VRF.
     *                   If randomWord == 0, then the request is still pending.
     */
    struct RandomnessRequest {
        bool exists;
        uint40 caveId;
        uint40 roundId;
        uint256 randomWord;
    }

    /**
     * @notice A cave of Poke The Bear.
     * @param enterAmount The amount to enter the cave with.
     * @param enterCurrency The currency to enter the cave with.
     * @param roundsCount The number of rounds in the cave.
     * @param lastCommittedRoundId The last committed round ID.
     * @param roundDuration The duration of a round.
     * @param playersPerRound The maximum number of players in a round.
     * @param protocolFeeBp The protocol fee in basis points.
     */
    struct Cave {
        uint256 enterAmount;
        address enterCurrency;
        uint40 roundsCount;
        uint40 lastCommittedRoundId;
        uint40 roundDuration;
        uint8 playersPerRound;
        uint16 protocolFeeBp;
        bool isActive;
    }

    /**
     * @notice The calldata for commitments.
     * @param caveId The cave ID of the commitments.
     * @param commitments The commitments. The pre-image of the commitment is the shuffled player indices.
     */
    struct CommitmentCalldata {
        uint256 caveId;
        bytes32[] commitments;
    }

    /**
     * @notice The calldata for a withdrawal/claim/rollover.
     * @param caveId The cave ID of the withdrawal/claim/rollover.
     * @param playerDetails The player's details in the rounds' players array.
     */
    struct WithdrawalCalldata {
        uint256 caveId;
        PlayerWithdrawalCalldata[] playerDetails;
    }

    /**
     * @notice The calldata for a withdrawal/claim/rollover.
     * @param caveId The cave ID of the withdrawal/claim/rollover.
     * @param startingRoundId The starting round ID to enter.
     * @param numberOfExtraRoundsToEnter The number of extra rounds to enter, in addition to rollover rounds.
     * @param playerDetails The player's details in the rounds' players array.
     */
    struct RolloverCalldata {
        uint256 caveId;
        uint256 startingRoundId;
        uint256 numberOfExtraRoundsToEnter;
        PlayerWithdrawalCalldata[] playerDetails;
    }

    /**
     * @notice The calldata for a single player withdrawal/claim/rollover.
     * @param roundId The round ID of the withdrawal/claim/rollover.
     * @param playerIndex The player index of the withdrawal/claim/rollover.
     */
    struct PlayerWithdrawalCalldata {
        uint256 roundId;
        uint256 playerIndex;
    }

    /**
     * @notice The withdrawal/claim/rollover.
     * @param caveId The cave ID of the withdrawal/claim/rollover.
     * @param roundIds The round IDs to withdraw/claim/rollover.
     */
    struct Withdrawal {
        uint256 caveId;
        uint256[] roundIds;
    }

    /**
     * @notice The rollover for event emission.
     * @param caveId The cave ID of the rollover.
     * @param rolledOverRoundIds The rolled over round IDs.
     * @param rollingOverToRoundIdStart The starting round ID to roll into
     */
    struct Rollover {
        uint256 caveId;
        uint256[] rolledOverRoundIds;
        uint256 rollingOverToRoundIdStart;
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

    event CommitmentsSubmitted(CommitmentCalldata[] commitments);
    event DepositsRolledOver(Rollover[] rollovers, address player);
    event DepositsRefunded(Withdrawal[] deposits, address player);
    event PrizesClaimed(Withdrawal[] prizes, address player);
    event ProtocolFeeRecipientUpdated(address protocolFeeRecipient);
    event RoundStatusUpdated(uint256 caveId, uint256 roundId, RoundStatus status);
    event RoundsCancelled(uint256 caveId, uint256 startingRoundId, uint256 numberOfRounds);
    event RoundsEntered(uint256 caveId, uint256 startingRoundId, uint256 numberOfRounds, address player);
    event RandomnessRequested(uint256 caveId, uint256 roundId, uint256 requestId);
    event CaveAdded(
        uint256 caveId,
        uint256 enterAmount,
        address enterCurrency,
        uint40 roundDuration,
        uint8 playersPerRound,
        uint16 protocolFeeBp
    );
    event CaveRemoved(uint256 caveId);

    error CommitmentNotAvailable();
    error ExceedsMaximumNumberOfPlayersPerRound();
    error HashedPlayerIndicesDoesNotMatchCommitment();
    error InactiveCave();
    error IndivisibleEnterAmount();
    error IneligibleToWithdraw(uint256 caveId, uint256 roundId);
    error InvalidEnterAmount();
    error InsufficientNumberOfPlayers();
    error InvalidCommitment(uint256 caveId, uint256 roundId);
    error InvalidPlayerDetails();
    error InvalidPlayerIndex(uint256 caveId, uint256 roundId);
    error InvalidRoundDuration();
    error InvalidRoundParameters();
    error InvalidRoundStatus();
    error InvalidEnterCurrency();
    error InvalidValue();
    error NotOperator();
    error NotOwner();
    error NotCancellable();
    error PlayerAlreadyParticipated(uint256 caveId, uint256 roundId, address player);
    error ProtocolFeeBasisPointsTooHigh();
    error RepeatingPlayerIndex();
    error RandomnessRequestAlreadyExists();
    error RoundCannotBeEntered(uint256 caveId, uint256 roundId);
    error RoundsIncomplete();

    /**
     * @notice Add a new cave. Only callable by the contract owner.
     * @param enterAmount The amount to enter the cave with.
     * @param enterCurrency The currency to enter the cave with.
     * @param playersPerRound The maximum number of players in a round.
     * @param roundDuration The duration of a round.
     * @param protocolFeeBp The protocol fee in basis points. Max 25%.
     */
    function addCave(
        uint256 enterAmount,
        address enterCurrency,
        uint8 playersPerRound,
        uint40 roundDuration,
        uint16 protocolFeeBp
    ) external returns (uint256 caveId);

    /**
     * @notice Remove a cave. Only callable by the contract owner.
     * @param caveId The cave ID to remove.
     */
    function removeCave(uint256 caveId) external;

    /**
     * @dev Update the protocol fee recipient. Only callable by the contract owner.
     * @param _protocolFeeRecipient The address of the protocol fee recipient
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external;

    /**
     * @notice Enter the current round of a cave.
     * @param caveId The cave ID of the round to enter.
     * @param startingRoundId The starting round ID to enter.
     * @param numberOfRounds The number of rounds to enter, starting from the starting round ID.
     */
    function enter(uint256 caveId, uint256 startingRoundId, uint256 numberOfRounds) external payable;

    /**
     * @notice Commit the player indices for multiple rounds.
     * @param commitments The array of commitments.
     */
    function commit(CommitmentCalldata[] calldata commitments) external;

    /**
     * @notice Reveal the result of a round.
     * @param requestId The Chainlink VRF request ID.
     * @param playerIndices The indices of the players.
     * @param salt The salt used to concatenate with the playerIndices to generate the commitment.
     */
    function reveal(uint256 requestId, uint256 playerIndices, bytes32 salt) external;

    /**
     * @notice Get a refund for cancelled rounds.
     * @param refundCalldataArray The array of refund calldata.
     */
    function refund(WithdrawalCalldata[] calldata refundCalldataArray) external;

    /**
     * @notice Rollover cancelled rounds' deposits to the current round + upcoming rounds.
     * @param rolloverCalldataArray The array of rollover calldata.
     */
    function rollover(RolloverCalldata[] calldata rolloverCalldataArray) external payable;

    /**
     * @notice Claim prizes for multiple rounds.
     * @param claimPrizeCalldataArray The array of claim prize calldata.
     */
    function claimPrizes(WithdrawalCalldata[] calldata claimPrizeCalldataArray) external;

    /**
     * @notice Cancel the latest round when the round is expired.
     * @param caveId The cave ID of the round to cancel.
     */
    function cancel(uint256 caveId) external;

    /**
     * @notice Allow the contract owner to cancel the current and future rounds if the contract is paused.
     * @param caveId The cave ID of the rounds to cancel.
     * @param numberOfRounds The number of rounds to cancel..
     */
    function cancel(uint256 caveId, uint256 numberOfRounds) external;

    /**
     * @notice Get a round of a given cave.
     * @param caveId The cave ID.
     * @param roundId The round ID.
     */
    function getRound(
        uint256 caveId,
        uint256 roundId
    )
        external
        view
        returns (
            RoundStatus status,
            uint40 cutoffTime,
            uint40 drawnAt,
            bytes32 commitment,
            bytes32 salt,
            uint8[32] memory playerIndices,
            Player[] memory players
        );

    /**
     * @notice Check if the player is in a specific round.
     * @param caveId The cave ID.
     * @param roundId The round ID.
     * @return The player's address.
     */
    function isPlayerInRound(uint256 caveId, uint256 roundId, address player) external view returns (bool);

    /**
     * @notice This function allows the owner to pause/unpause the contract.
     */
    function togglePaused() external;
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

/**
 * @title IReentrancyGuard
 * @author LooksRare protocol team (👀,💎)
 */
interface IReentrancyGuard {
    /**
     * @notice This is returned when there is a reentrant call.
     */
    error ReentrancyFail();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
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
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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