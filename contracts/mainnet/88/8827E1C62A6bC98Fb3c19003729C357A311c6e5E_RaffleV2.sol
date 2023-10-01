// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {LowLevelWETH} from "./dependencies/LowLevelWETH.sol";
import {LowLevelERC20Transfer} from "./dependencies/LowLevelERC20Transfer.sol";
import {LowLevelERC721Transfer} from "./dependencies/LowLevelERC721Transfer.sol";
import {LowLevelERC1155Transfer} from "./dependencies/LowLevelERC1155Transfer.sol";
import {OwnableTwoSteps} from "./dependencies/OwnableTwoSteps.sol";
import {PackableReentrancyGuard} from "./dependencies/PackableReentrancyGuard.sol";
import {Pausable} from "./dependencies/Pausable.sol";
import {ITransferManager} from "./dependencies/ITransferManager.sol";

import {VRFCoordinatorV2Interface} from "./dependencies/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "./dependencies/VRFConsumerBaseV2.sol";

import {Arrays} from "./dependencies/Arrays.sol";

import {WinningEntrySearchLogicV2} from "./dependencies/WinningEntrySearchLogicV2.sol";

import {IRaffleV2} from "./dependencies/IRaffleV2.sol";

/**
 * @title RaffleV2
 * @notice This contract allows anyone to permissionlessly host raffles on NFTEarth
 * @author LooksRare protocol team
 */
contract RaffleV2 is
    IRaffleV2,
    LowLevelWETH,
    LowLevelERC20Transfer,
    LowLevelERC721Transfer,
    LowLevelERC1155Transfer,
    VRFConsumerBaseV2,
    OwnableTwoSteps,
    PackableReentrancyGuard,
    Pausable,
    WinningEntrySearchLogicV2
{
    using Arrays for uint256[];

    address private immutable WETH;

    uint256 private constant ONE_DAY = 86_400 seconds;
    uint256 private constant ONE_WEEK = 604_800 seconds;

    /**
     * @notice 100% in basis points.
     */
    uint256 private constant ONE_HUNDRED_PERCENT_BP = 10_000;

    /**
     * @notice The raffles created.
     * @dev The key is the raffle ID.
     */
    mapping(uint256 => Raffle) public raffles;

    /**
     * @notice The participants stats of the raffles.
     * @dev The key is the raffle ID and the nested key is the participant address.
     */
    mapping(uint256 => mapping(address => ParticipantStats)) public rafflesParticipantsStats;

    /**
     * @notice It checks whether the currency is allowed.
     * @dev 0 is not allowed, 1 is allowed.
     */
    mapping(address => uint256) public isCurrencyAllowed;

    /**
     * @notice The maximum number of prizes per raffle.
     *         Each individual ERC-721 counts as one prize.
     *         Each ETH/ERC-20/ERC-1155 with winnersCount > 1 counts as one prize.
     */
    uint256 public constant MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE = 200;

    /**
     * @notice The maximum number of winners per raffle.
     */
    uint40 public constant MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE = 200;

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
     * @notice The randomness requests.
     * @dev The key is the request ID returned by Chainlink.
     */
    mapping(uint256 => RandomnessRequest) public randomnessRequests;

    /**
     * @notice The maximum protocol fee in basis points, which is 25%.
     */
    uint16 public constant MAXIMUM_PROTOCOL_FEE_BP = 2_500;

    /**
     * @notice The number of raffles created.
     * @dev In this smart contract, raffleId is an uint256 but its
     *      max value can only be 2^80 - 1. Realistically we will still
     *      not reach this number.
     */
    uint80 public rafflesCount;

    /**
     * @notice The protocol fee recipient.
     */
    address public protocolFeeRecipient;

    /**
     * @notice The protocol fee in basis points.
     */
    uint16 public protocolFeeBp;

    /**
     * @notice The maximum number of pricing options per raffle.
     */
    uint256 public constant MAXIMUM_PRICING_OPTIONS_PER_RAFFLE = 5;

    /**
     * @notice Transfer manager faciliates token transfers.
     */
    ITransferManager private immutable transferManager;

    /**
     * @param _weth The WETH address
     * @param _keyHash Chainlink VRF key hash
     * @param _subscriptionId Chainlink VRF subscription ID
     * @param _vrfCoordinator Chainlink VRF coordinator address
     * @param _owner The owner of the contract
     * @param _protocolFeeRecipient The recipient of the protocol fees
     * @param _protocolFeeBp The protocol fee in basis points
     * @param _transferManager The transfer manager address
     */
    constructor(
        address _weth,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _vrfCoordinator,
        address _owner,
        address _protocolFeeRecipient,
        uint16 _protocolFeeBp,
        address _transferManager
    ) VRFConsumerBaseV2(_vrfCoordinator) OwnableTwoSteps(_owner) {
        _setProtocolFeeBp(_protocolFeeBp);
        _setProtocolFeeRecipient(_protocolFeeRecipient);

        WETH = _weth;
        KEY_HASH = _keyHash;
        VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        SUBSCRIPTION_ID = _subscriptionId;
        transferManager = ITransferManager(_transferManager);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function createRaffle(CreateRaffleCalldata calldata params)
        external
        payable
        nonReentrant
        whenNotPaused
        returns (uint256 raffleId)
    {
        uint40 cutoffTime = params.cutoffTime;
        if (_unsafeAdd(block.timestamp, ONE_DAY) > cutoffTime || cutoffTime > _unsafeAdd(block.timestamp, ONE_WEEK)) {
            revert InvalidCutoffTime();
        }

        uint16 agreedProtocolFeeBp = params.protocolFeeBp;
        if (agreedProtocolFeeBp != protocolFeeBp) {
            revert InvalidProtocolFeeBp();
        }

        address feeTokenAddress = params.feeTokenAddress;
        if (feeTokenAddress != address(0)) {
            _validateCurrency(feeTokenAddress);
        }

        uint256 prizesCount = params.prizes.length;
        if (prizesCount == 0 || prizesCount > MAXIMUM_NUMBER_OF_PRIZES_PER_RAFFLE) {
            revert InvalidPrizesCount();
        }

        unchecked {
            raffleId = ++rafflesCount;
        }

        // The storage layout of a prize struct (3 slots) is as follows:
        // --------------------------------------------------------------------------------------------------------------------------------|
        // | prizeAddress (160 bits) | prizeTier (8 bits) | prizeType (8 bits) | cumulativeWinnersCount (40 bits) | winnersCount (40 bits) |
        // --------------------------------------------------------------------------------------------------------------------------------|
        // | prizeId (256 bits)                                                                                                            |
        // --------------------------------------------------------------------------------------------------------------------------------|
        // | prizeAmount (256 bits)                                                                                                        |
        //
        // The slot keccak256(raffleId, rafflesSlot) + 4 is used to store the length of the prizes array.
        // The slot keccak256(keccak256(raffleId, rafflesSlot) + 4) + i * 3 is used to store the prize at the i-th index
        // (x 3 because each prize consumes 3 slots).
        //
        // The assembly blocks are equivalent to `raffle.prizes.push(prize);`
        //
        // The primary benefit of using assembly is we only write the prizes length once instead of once per prize.
        uint256 raffleSlot;
        uint256 prizesLengthSlot;
        uint256 individualPrizeSlotOffset;
        assembly {
            mstore(0x00, raffleId)
            mstore(0x20, raffles.slot)
            raffleSlot := keccak256(0x00, 0x40)

            prizesLengthSlot := add(keccak256(0x00, 0x40), 4)

            mstore(0x00, prizesLengthSlot)
            individualPrizeSlotOffset := keccak256(0x00, 0x20)
        }

        uint256 expectedEthValue;
        uint40 cumulativeWinnersCount;
        {
            uint8 currentPrizeTier;
            for (uint256 i; i < prizesCount; ) {
                Prize memory prize = params.prizes[i];
                uint8 prizeTier = prize.prizeTier;
                if (prizeTier < currentPrizeTier) {
                    revert InvalidPrize();
                }
                _validatePrize(prize);

                TokenType prizeType = prize.prizeType;
                uint40 winnersCount = prize.winnersCount;
                address prizeAddress = prize.prizeAddress;
                uint256 prizeId = prize.prizeId;
                uint256 prizeAmount = prize.prizeAmount;
                if (prizeType == TokenType.ERC721) {
                    transferManager.transferItemERC721(prizeAddress, msg.sender, address(this), prizeId);
                } else if (prizeType == TokenType.ERC20) {
                    transferManager.transferERC20(prizeAddress, msg.sender, address(this), prizeAmount * winnersCount);
                } else if (prizeType == TokenType.ETH) {
                    expectedEthValue += (prizeAmount * winnersCount);
                } else {
                    transferManager.transferItemERC1155(
                        prizeAddress,
                        msg.sender,
                        address(this),
                        prizeId,
                        prizeAmount * winnersCount
                    );
                }

                cumulativeWinnersCount += winnersCount;
                currentPrizeTier = prizeTier;

                assembly {
                    let prizeSlotOne := winnersCount
                    prizeSlotOne := or(prizeSlotOne, shl(40, cumulativeWinnersCount))
                    prizeSlotOne := or(prizeSlotOne, shl(80, prizeType))
                    prizeSlotOne := or(prizeSlotOne, shl(88, prizeTier))
                    prizeSlotOne := or(prizeSlotOne, shl(96, prizeAddress))

                    let currentPrizeSlotOffset := add(individualPrizeSlotOffset, mul(i, 3))
                    sstore(currentPrizeSlotOffset, prizeSlotOne)
                    sstore(add(currentPrizeSlotOffset, 1), prizeId)
                    sstore(add(currentPrizeSlotOffset, 2), prizeAmount)
                }

                unchecked {
                    ++i;
                }
            }

            assembly {
                sstore(prizesLengthSlot, prizesCount)
            }
        }
        _validateExpectedEthValueOrRefund(expectedEthValue);

        uint40 minimumEntries = params.minimumEntries;
        if (cumulativeWinnersCount > minimumEntries || cumulativeWinnersCount > MAXIMUM_NUMBER_OF_WINNERS_PER_RAFFLE) {
            revert InvalidWinnersCount();
        }

        _validateAndSetPricingOptions(raffleId, minimumEntries, params.pricingOptions);

        bool isMinimumEntriesFixed = params.isMinimumEntriesFixed;
        uint40 maximumEntriesPerParticipant = params.maximumEntriesPerParticipant;
        // The storage layout of a raffle's first 2 slots is as follows:
        // ---------------------------------------------------------------------------------------------------------------------------------|
        // | drawnAt (40 bits) | cutoffTime (40 bits) | isMinimumEntriesFixed (8 bits) | status (8 bits) | owner (160 bits)                 |
        // ---------------------------------------------------------------------------------------------------------------------------------|
        // | agreedProtocolFeeBp (16 bits) | feeTokenAddress (160 bits) | maximumEntriesPerParticipant (40 bits) | minimumEntries (40 bits) |
        // ---------------------------------------------------------------------------------------------------------------------------------|
        //
        // And the slots for these values are calculated by the following formulas:
        // slot 1 = keccak256(raffleId, rafflesSlot)
        // slot 2 = keccak256(raffleId, rafflesSlot) + 1
        //
        // This assembly block is equivalent to
        // raffle.owner = msg.sender;
        // raffle.status = RaffleStatus.Open;
        // raffle.isMinimumEntriesFixed = isMinimumEntriesFixed;
        // raffle.cutoffTime = cutoffTime;
        // raffle.minimumEntries = minimumEntries;
        // raffle.maximumEntriesPerParticipant = maximumEntriesPerParticipant;
        // raffle.protocolFeeBp = agreedProtocolFeeBp;
        // raffle.feeTokenAddress = feeTokenAddress;
        assembly {
            let raffleSlotOneValue := caller()
            raffleSlotOneValue := or(raffleSlotOneValue, shl(160, 1))
            raffleSlotOneValue := or(raffleSlotOneValue, shl(168, isMinimumEntriesFixed))
            raffleSlotOneValue := or(raffleSlotOneValue, shl(176, cutoffTime))

            let raffleSlotTwoValue := minimumEntries
            raffleSlotTwoValue := or(raffleSlotTwoValue, shl(40, maximumEntriesPerParticipant))
            raffleSlotTwoValue := or(raffleSlotTwoValue, shl(80, feeTokenAddress))
            raffleSlotTwoValue := or(raffleSlotTwoValue, shl(240, agreedProtocolFeeBp))

            sstore(raffleSlot, raffleSlotOneValue)
            sstore(add(raffleSlot, 1), raffleSlotTwoValue)
        }

        emit RaffleStatusUpdated(raffleId, RaffleStatus.Open);
    }

    /**
     * @dev This function is required in order for the contract to receive ERC-1155 tokens.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @inheritdoc IRaffleV2
     * @notice If it is a delegated recipient, the amount paid should still be accrued to the payer.
     *         If a raffle is cancelled, the payer should be refunded and not the recipient.
     */
    function enterRaffles(EntryCalldata[] calldata entries) external payable nonReentrant whenNotPaused {
        (address feeTokenAddress, uint208 expectedValue) = _enterRaffles(entries);
        _chargeUser(feeTokenAddress, expectedValue);
    }

    /**
     * @param _requestId The ID of the request
     * @param _randomWords The random words returned by Chainlink
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        if (randomnessRequests[_requestId].exists) {
            uint256 raffleId = randomnessRequests[_requestId].raffleId;
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status == RaffleStatus.Drawing) {
                _setRaffleStatus(raffle, raffleId, RaffleStatus.RandomnessFulfilled);
                randomnessRequests[_requestId].randomWord = _randomWords[0];
            }
        }
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function selectWinners(uint256 requestId) external {
        RandomnessRequest memory randomnessRequest = randomnessRequests[requestId];
        if (!randomnessRequest.exists) {
            revert RandomnessRequestDoesNotExist();
        }

        uint256 raffleId = randomnessRequest.raffleId;
        Raffle storage raffle = raffles[raffleId];
        _validateRaffleStatus(raffle, RaffleStatus.RandomnessFulfilled);

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Drawn);

        Prize[] storage prizes = raffle.prizes;
        uint256 prizesCount = prizes.length;
        uint256 winnersCount = prizes[prizesCount - 1].cumulativeWinnersCount;

        Entry[] memory entries = raffle.entries;
        uint256 entriesCount = entries.length;

        uint256[] memory currentEntryIndexArray = new uint256[](entriesCount);
        for (uint256 i; i < entriesCount; ) {
            currentEntryIndexArray[i] = entries[i].currentEntryIndex;
            unchecked {
                ++i;
            }
        }

        uint256 currentEntryIndex = uint256(currentEntryIndexArray[entriesCount - 1]);

        uint256[] memory winningEntriesBitmap = new uint256[]((currentEntryIndex >> 8) + 1);

        uint256[] memory cumulativeWinnersCountArray = new uint256[](prizesCount);
        for (uint256 i; i < prizesCount; ) {
            cumulativeWinnersCountArray[i] = prizes[i].cumulativeWinnersCount;
            unchecked {
                ++i;
            }
        }

        uint256 randomWord = randomnessRequest.randomWord;
        uint256 winningEntry;

        // The storage layout of a winner slot is as follows:
        // ------------------------------------------------------------------------------------------------------------|
        // | unused (40 bits) | entryIndex (40 bits) | prizeIndex (8 bits) | claimed (8 bits) | participant (160 bits) |
        // ------------------------------------------------------------------------------------------------------------|
        //
        // The slot keccak256(raffleId, rafflesSlot) + 6 is used to store the length of the winners array.
        // The slot keccak256(keccak256(raffleId, rafflesSlot) + 6) + i is used to store the winner at the i-th index.
        //
        // The assembly blocks are equivalent to
        // raffle.winners.push(
        //   Winner({
        //     participant: entries[currentEntryIndexArray.findUpperBound(winningEntry)].participant,
        //     claimed: false,
        //     prizeIndex: uint8(cumulativeWinnersCountArray.findUpperBound(_unsafeAdd(i, 1))),
        //     entryIndex: uint40(winningEntry)
        //   })
        // );
        //
        // The primary benefit of using assembly is we only write the winners length once instead of once per winner.
        uint256 winnersLengthSlot;
        uint256 individualWinnerSlotOffset;
        assembly {
            mstore(0x00, raffleId)
            mstore(0x20, raffles.slot)
            winnersLengthSlot := add(keccak256(0x00, 0x40), 6)

            mstore(0x00, winnersLengthSlot)
            individualWinnerSlotOffset := keccak256(0x00, 0x20)
        }

        for (uint256 i; i < winnersCount; ) {
            (randomWord, winningEntry, winningEntriesBitmap) = _searchForWinningEntryUntilThereIsNotADuplicate(
                randomWord,
                currentEntryIndex,
                winningEntriesBitmap
            );

            address participant = entries[currentEntryIndexArray.findUpperBound(winningEntry)].participant;
            uint256 prizeIndex = cumulativeWinnersCountArray.findUpperBound(_unsafeAdd(i, 1));

            assembly {
                let winnerSlotValue := participant
                winnerSlotValue := or(winnerSlotValue, shl(168, prizeIndex))
                winnerSlotValue := or(winnerSlotValue, shl(176, winningEntry))

                sstore(add(individualWinnerSlotOffset, i), winnerSlotValue)
            }

            randomWord = uint256(keccak256(abi.encodePacked(randomWord)));

            unchecked {
                ++i;
            }
        }

        assembly {
            sstore(winnersLengthSlot, winnersCount)
        }
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function claimPrize(uint256 raffleId, uint256 winnerIndex) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        if (raffle.status != RaffleStatus.Drawn) {
            _validateRaffleStatus(raffle, RaffleStatus.Complete);
        }

        Winner[] storage winners = raffle.winners;
        if (winnerIndex >= winners.length) {
            revert InvalidIndex();
        }

        Winner storage winner = winners[winnerIndex];
        if (winner.claimed) {
            revert NothingToClaim();
        }
        _validateCaller(winner.participant);
        winner.claimed = true;

        _transferPrize({prize: raffle.prizes[winner.prizeIndex], recipient: msg.sender, multiplier: 1});

        emit PrizeClaimed(raffleId, winnerIndex);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata) external nonReentrant whenNotPaused {
        TransferAccumulator memory transferAccumulator;

        for (uint256 i; i < claimPrizesCalldata.length; ) {
            ClaimPrizesCalldata calldata perRaffleClaimPrizesCalldata = claimPrizesCalldata[i];
            uint256 raffleId = perRaffleClaimPrizesCalldata.raffleId;
            Raffle storage raffle = raffles[raffleId];
            if (raffle.status != RaffleStatus.Drawn) {
                _validateRaffleStatus(raffle, RaffleStatus.Complete);
            }

            Winner[] storage winners = raffle.winners;
            uint256[] calldata winnerIndices = perRaffleClaimPrizesCalldata.winnerIndices;
            uint256 winnersCount = winners.length;
            uint256 claimsCount = winnerIndices.length;

            for (uint256 j; j < claimsCount; ) {
                uint256 winnerIndex = winnerIndices[j];

                if (winnerIndex >= winnersCount) {
                    revert InvalidIndex();
                }

                Winner storage winner = winners[winnerIndex];
                if (winner.claimed) {
                    revert NothingToClaim();
                }
                _validateCaller(winner.participant);
                winner.claimed = true;

                Prize storage prize = raffle.prizes[winner.prizeIndex];
                if (prize.prizeType > TokenType.ERC1155) {
                    address prizeAddress = prize.prizeAddress;
                    if (prizeAddress == transferAccumulator.tokenAddress) {
                        transferAccumulator.amount += prize.prizeAmount;
                    } else {
                        if (transferAccumulator.amount != 0) {
                            _transferFungibleTokens(transferAccumulator);
                        }

                        transferAccumulator.tokenAddress = prizeAddress;
                        transferAccumulator.amount = prize.prizeAmount;
                    }
                } else {
                    _transferPrize({prize: prize, recipient: msg.sender, multiplier: 1});
                }

                unchecked {
                    ++j;
                }
            }

            emit PrizesClaimed(raffleId, winnerIndices);

            unchecked {
                ++i;
            }
        }

        if (transferAccumulator.amount != 0) {
            _transferFungibleTokens(transferAccumulator);
        }
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function claimFees(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        _validateRaffleStatus(raffle, RaffleStatus.Drawn);

        address raffleOwner = raffle.owner;
        if (msg.sender != raffleOwner) {
            _validateCaller(owner);
        }

        uint208 claimableFees = raffle.claimableFees;
        uint208 protocolFees = (claimableFees * uint208(raffle.protocolFeeBp)) / uint208(ONE_HUNDRED_PERCENT_BP);
        unchecked {
            claimableFees -= protocolFees;
        }

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Complete);

        raffle.claimableFees = 0;

        address feeTokenAddress = raffle.feeTokenAddress;
        _transferFungibleTokens(feeTokenAddress, raffleOwner, claimableFees);

        if (protocolFees != 0) {
            _transferFungibleTokens(feeTokenAddress, protocolFeeRecipient, protocolFees);
        }

        emit FeesClaimed(raffleId, claimableFees);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function cancel(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        _validateRafflePostCutoffTimeStatusTransferability(raffle);
        if (block.timestamp < raffle.cutoffTime + 1 hours) {
            _validateCaller(raffle.owner);
        }
        _setRaffleStatus(raffle, raffleId, RaffleStatus.Refundable);
    }

    /**
     * @inheritdoc IRaffleV2
     * @notice A raffle cannot be drawn if there are less entries than prizes.
     */
    function drawWinners(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];

        Entry[] storage entries = raffle.entries;
        uint256 entriesCount = entries.length;
        if (entriesCount == 0) {
            revert NotEnoughEntries();
        }

        Prize[] storage prizes = raffle.prizes;

        if (prizes[prizes.length - 1].cumulativeWinnersCount > entries[entriesCount - 1].currentEntryIndex + 1) {
            revert NotEnoughEntries();
        }

        _validateRafflePostCutoffTimeStatusTransferability(raffle);
        _validateCaller(raffle.owner);
        _drawWinners(raffleId, raffle);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function cancelAfterRandomnessRequest(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];

        _validateRaffleStatus(raffle, RaffleStatus.Drawing);

        if (block.timestamp < raffle.drawnAt + ONE_DAY) {
            revert DrawExpirationTimeNotReached();
        }

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Refundable);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function withdrawPrizes(uint256 raffleId) external nonReentrant whenNotPaused {
        Raffle storage raffle = raffles[raffleId];
        _validateRaffleStatus(raffle, RaffleStatus.Refundable);

        _setRaffleStatus(raffle, raffleId, RaffleStatus.Cancelled);

        uint256 prizesCount = raffle.prizes.length;
        address raffleOwner = raffle.owner;
        for (uint256 i; i < prizesCount; ) {
            Prize storage prize = raffle.prizes[i];
            _transferPrize({prize: prize, recipient: raffleOwner, multiplier: uint256(prize.winnersCount)});

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IRaffleV2
     * @dev Refundable and Cancelled are the only statuses that allow refunds.
     */
    function claimRefund(uint256[] calldata raffleIds) external nonReentrant whenNotPaused {
        (address feeTokenAddress, uint208 refundAmount) = _claimRefund(raffleIds);
        _transferFungibleTokens(feeTokenAddress, msg.sender, refundAmount);
    }

    /**
     * @inheritdoc IRaffleV2
     * @notice The fee token address for all the raffles involved must be the same.
     * @dev Refundable and Cancelled are the only statuses that allow refunds.
     */
    function rollover(uint256[] calldata refundableRaffleIds, EntryCalldata[] calldata entries)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        (address refundFeeTokenAddress, uint208 rolloverAmount) = _claimRefund(refundableRaffleIds);
        (address enterRafflesFeeTokenAddress, uint208 expectedValue) = _enterRaffles(entries);

        if (refundFeeTokenAddress != enterRafflesFeeTokenAddress) {
            revert InvalidCurrency();
        }

        if (rolloverAmount > expectedValue) {
            _transferFungibleTokens(refundFeeTokenAddress, msg.sender, _unsafeSubtract(rolloverAmount, expectedValue));
        } else if (rolloverAmount < expectedValue) {
            _chargeUser(refundFeeTokenAddress, _unsafeSubtract(expectedValue, rolloverAmount));
        }
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function setProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        _setProtocolFeeRecipient(_protocolFeeRecipient);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function setProtocolFeeBp(uint16 _protocolFeeBp) external onlyOwner {
        _setProtocolFeeBp(_protocolFeeBp);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external onlyOwner {
        uint256 count = currencies.length;
        for (uint256 i; i < count; ) {
            isCurrencyAllowed[currencies[i]] = (isAllowed ? 1 : 0);
            unchecked {
                ++i;
            }
        }
        emit CurrenciesStatusUpdated(currencies, isAllowed);
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function togglePaused() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function getWinners(uint256 raffleId) external view returns (Winner[] memory winners) {
        winners = raffles[raffleId].winners;
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function getPrizes(uint256 raffleId) external view returns (Prize[] memory prizes) {
        prizes = raffles[raffleId].prizes;
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function getEntries(uint256 raffleId) external view returns (Entry[] memory entries) {
        entries = raffles[raffleId].entries;
    }

    /**
     * @inheritdoc IRaffleV2
     */
    function getPricingOptions(uint256 raffleId) external view returns (PricingOption[] memory pricingOptions) {
        pricingOptions = raffles[raffleId].pricingOptions;
    }

    /**
     * @param _protocolFeeRecipient The new protocol fee recipient address
     */
    function _setProtocolFeeRecipient(address _protocolFeeRecipient) private {
        if (_protocolFeeRecipient == address(0)) {
            revert InvalidProtocolFeeRecipient();
        }
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
    }

    /**
     * @param _protocolFeeBp The new protocol fee in basis points
     */
    function _setProtocolFeeBp(uint16 _protocolFeeBp) private {
        if (_protocolFeeBp > MAXIMUM_PROTOCOL_FEE_BP) {
            revert InvalidProtocolFeeBp();
        }
        protocolFeeBp = _protocolFeeBp;
        emit ProtocolFeeBpUpdated(_protocolFeeBp);
    }

    /**
     * @param raffleId The ID of the raffle.
     * @param pricingOptions The pricing options for the raffle.
     */
    function _validateAndSetPricingOptions(
        uint256 raffleId,
        uint40 minimumEntries,
        PricingOption[] calldata pricingOptions
    ) private {
        uint256 count = pricingOptions.length;

        if (count == 0 || count > MAXIMUM_PRICING_OPTIONS_PER_RAFFLE) {
            revert InvalidPricingOptionsCount();
        }

        uint40 lowestEntriesCount = pricingOptions[0].entriesCount;

        // The storage layout of a pricing option slot is as follows:
        // ---------------------------------------------------------------|
        // | unused (8 bits) | price (208 bits) | entries count (40 bits) |
        // ---------------------------------------------------------------|
        //
        // The slot keccak256(raffleId, rafflesSlot) + 3 is used to store the length of the pricing options array.
        // The slot keccak256(keccak256(raffleId, rafflesSlot) + 3) + i is used to store the pricing option at the i-th index.
        //
        // The assembly blocks are equivalent to `raffles[raffleId].pricingOptions.push(pricingOption);`
        //
        // The primary benefit of using assembly is we only write the pricing options length once instead of once per pricing option.
        uint256 pricingOptionsLengthSlot;
        uint256 individualPricingOptionSlotOffset;
        assembly {
            mstore(0x00, raffleId)
            mstore(0x20, raffles.slot)
            pricingOptionsLengthSlot := add(keccak256(0x00, 0x40), 3)

            mstore(0x00, pricingOptionsLengthSlot)
            individualPricingOptionSlotOffset := keccak256(0x00, 0x20)
        }

        for (uint256 i; i < count; ) {
            PricingOption memory pricingOption = pricingOptions[i];

            uint40 entriesCount = pricingOption.entriesCount;
            uint208 price = pricingOption.price;

            if (i == 0) {
                if (minimumEntries % entriesCount != 0 || price == 0) {
                    revert InvalidPricingOption();
                }
            } else {
                PricingOption memory lastPricingOption = pricingOptions[_unsafeSubtract(i, 1)];
                uint208 lastPrice = lastPricingOption.price;
                uint40 lastEntriesCount = lastPricingOption.entriesCount;

                if (
                    entriesCount % lowestEntriesCount != 0 ||
                    price % entriesCount != 0 ||
                    entriesCount <= lastEntriesCount ||
                    price <= lastPrice ||
                    price / entriesCount > lastPrice / lastEntriesCount
                ) {
                    revert InvalidPricingOption();
                }
            }

            assembly {
                let pricingOptionValue := entriesCount
                pricingOptionValue := or(pricingOptionValue, shl(40, price))
                sstore(add(individualPricingOptionSlotOffset, i), pricingOptionValue)
            }

            unchecked {
                ++i;
            }
        }

        assembly {
            sstore(pricingOptionsLengthSlot, count)
        }
    }

    /**
     * @param prize The prize.
     */
    function _validatePrize(Prize memory prize) private view {
        TokenType prizeType = prize.prizeType;
        if (prizeType == TokenType.ERC721) {
            if (prize.prizeAmount != 1 || prize.winnersCount != 1) {
                revert InvalidPrize();
            }
        } else {
            if (prizeType == TokenType.ERC20) {
                _validateCurrency(prize.prizeAddress);
            }

            if (prize.prizeAmount == 0 || prize.winnersCount == 0) {
                revert InvalidPrize();
            }
        }
    }

    /**
     * @param prize The prize to transfer.
     * @param recipient The recipient of the prize.
     * @param multiplier The multiplier to apply to the prize amount.
     */
    function _transferPrize(
        Prize storage prize,
        address recipient,
        uint256 multiplier
    ) private {
        TokenType prizeType = prize.prizeType;
        address prizeAddress = prize.prizeAddress;
        if (prizeType == TokenType.ERC721) {
            _executeERC721TransferFrom(prizeAddress, address(this), recipient, prize.prizeId);
        } else if (prizeType == TokenType.ERC1155) {
            _executeERC1155SafeTransferFrom(
                prizeAddress,
                address(this),
                recipient,
                prize.prizeId,
                prize.prizeAmount * multiplier
            );
        } else {
            _transferFungibleTokens(prizeAddress, recipient, prize.prizeAmount * multiplier);
        }
    }

    /**
     * @param currency The currency to transfer.
     * @param recipient The recipient of the currency.
     * @param amount The amount of currency to transfer.
     */
    function _transferFungibleTokens(
        address currency,
        address recipient,
        uint256 amount
    ) private {
        if (currency == address(0)) {
            _transferETHAndWrapIfFailWithGasLimit(WETH, recipient, amount, gasleft());
        } else {
            _executeERC20DirectTransfer(currency, recipient, amount);
        }
    }

    /**
     * @param transferAccumulator The transfer accumulator.
     */
    function _transferFungibleTokens(TransferAccumulator memory transferAccumulator) private {
        _transferFungibleTokens(transferAccumulator.tokenAddress, msg.sender, transferAccumulator.amount);
    }

    /**
     * @param raffleId The ID of the raffle to draw winners for.
     * @param raffle The raffle to draw winners for.
     */
    function _drawWinners(uint256 raffleId, Raffle storage raffle) private {
        _setRaffleStatus(raffle, raffleId, RaffleStatus.Drawing);
        raffle.drawnAt = uint40(block.timestamp);

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
        randomnessRequests[requestId].raffleId = uint80(raffleId);

        emit RandomnessRequested(raffleId, requestId);
    }

    /**
     * @param raffle The raffle to check the status of.
     * @param status The expected status of the raffle
     */
    function _validateRaffleStatus(Raffle storage raffle, RaffleStatus status) private view {
        if (raffle.status != status) {
            revert InvalidStatus();
        }
    }

    /**
     * @param entries The entries to enter.
     */
    function _enterRaffles(EntryCalldata[] calldata entries)
        private
        returns (address feeTokenAddress, uint208 expectedValue)
    {
        uint256 count = entries.length;
        for (uint256 i; i < count; ) {
            EntryCalldata calldata entry = entries[i];

            address recipient = entry.recipient == address(0) ? msg.sender : entry.recipient;

            uint256 raffleId = entry.raffleId;
            Raffle storage raffle = raffles[raffleId];

            if (i == 0) {
                feeTokenAddress = raffle.feeTokenAddress;
            } else if (raffle.feeTokenAddress != feeTokenAddress) {
                revert InvalidCurrency();
            }

            if (entry.pricingOptionIndex >= raffle.pricingOptions.length) {
                revert InvalidIndex();
            }

            _validateRaffleStatus(raffle, RaffleStatus.Open);

            if (block.timestamp >= raffle.cutoffTime) {
                revert CutoffTimeReached();
            }

            uint40 entriesCount;
            uint208 price;
            {
                PricingOption memory pricingOption = raffle.pricingOptions[entry.pricingOptionIndex];

                uint40 multiplier = entry.count;
                if (multiplier == 0) {
                    revert InvalidCount();
                }

                entriesCount = pricingOption.entriesCount * multiplier;
                price = pricingOption.price * multiplier;

                uint40 newParticipantEntriesCount = rafflesParticipantsStats[raffleId][recipient].entriesCount +
                    entriesCount;
                if (newParticipantEntriesCount > raffle.maximumEntriesPerParticipant) {
                    revert MaximumEntriesPerParticipantReached();
                }
                rafflesParticipantsStats[raffleId][recipient].entriesCount = newParticipantEntriesCount;
            }

            expectedValue += price;

            uint256 raffleEntriesCount = raffle.entries.length;
            uint40 currentEntryIndex;
            if (raffleEntriesCount == 0) {
                currentEntryIndex = uint40(_unsafeSubtract(entriesCount, 1));
            } else {
                currentEntryIndex =
                    raffle.entries[_unsafeSubtract(raffleEntriesCount, 1)].currentEntryIndex +
                    entriesCount;
            }

            if (raffle.isMinimumEntriesFixed) {
                if (currentEntryIndex >= raffle.minimumEntries) {
                    revert MaximumEntriesReached();
                }
            }

            _pushEntry(raffle, currentEntryIndex, recipient);
            raffle.claimableFees += price;

            rafflesParticipantsStats[raffleId][msg.sender].amountPaid += price;

            emit EntrySold(raffleId, msg.sender, recipient, entriesCount, price);

            if (currentEntryIndex >= _unsafeSubtract(raffle.minimumEntries, 1)) {
                _drawWinners(raffleId, raffle);
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @param feeTokenAddress The address of the token to charge the fee in.
     * @param expectedValue The expected value of the fee.
     */
    function _chargeUser(address feeTokenAddress, uint256 expectedValue) private {
        if (feeTokenAddress == address(0)) {
            _validateExpectedEthValueOrRefund(expectedValue);
        } else {
            transferManager.transferERC20(feeTokenAddress, msg.sender, address(this), expectedValue);
        }
    }

    /**
     * @param raffleIds The IDs of the raffles to claim refunds for.
     */
    function _claimRefund(uint256[] calldata raffleIds)
        private
        returns (address feeTokenAddress, uint208 refundAmount)
    {
        uint256 count = raffleIds.length;

        for (uint256 i; i < count; ) {
            uint256 raffleId = raffleIds[i];
            Raffle storage raffle = raffles[raffleId];

            if (raffle.status < RaffleStatus.Refundable) {
                revert InvalidStatus();
            }

            ParticipantStats storage stats = rafflesParticipantsStats[raffleId][msg.sender];
            uint208 amountPaid = stats.amountPaid;

            if (stats.refunded || amountPaid == 0) {
                revert NothingToClaim();
            }

            if (i == 0) {
                feeTokenAddress = raffle.feeTokenAddress;
            } else if (feeTokenAddress != raffle.feeTokenAddress) {
                revert InvalidCurrency();
            }

            stats.refunded = true;
            refundAmount += amountPaid;

            emit EntryRefunded(raffleId, msg.sender, amountPaid);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @param caller The expected caller.
     */
    function _validateCaller(address caller) private view {
        if (msg.sender != caller) {
            revert InvalidCaller();
        }
    }

    /**
     * @param currency The currency to validate.
     */
    function _validateCurrency(address currency) private view {
        if (isCurrencyAllowed[currency] != 1) {
            revert InvalidCurrency();
        }
    }

    /**
     * @param expectedEthValue The expected ETH value to be sent by the caller.
     */
    function _validateExpectedEthValueOrRefund(uint256 expectedEthValue) private {
        if (expectedEthValue > msg.value) {
            revert InsufficientNativeTokensSupplied();
        } else if (msg.value > expectedEthValue) {
            _transferETHAndWrapIfFailWithGasLimit(
                WETH,
                msg.sender,
                _unsafeSubtract(msg.value, expectedEthValue),
                gasleft()
            );
        }
    }

    /**
     * @param raffle The raffle to validate.
     */
    function _validateRafflePostCutoffTimeStatusTransferability(Raffle storage raffle) private view {
        _validateRaffleStatus(raffle, RaffleStatus.Open);

        if (raffle.cutoffTime > block.timestamp) {
            revert CutoffTimeNotReached();
        }
    }

    /**
     * @param raffle The raffle to set the status of.
     * @param raffleId The ID of the raffle to set the status of.
     * @param status The status to set.
     */
    function _setRaffleStatus(
        Raffle storage raffle,
        uint256 raffleId,
        RaffleStatus status
    ) private {
        raffle.status = status;
        emit RaffleStatusUpdated(raffleId, status);
    }

    /**
     * @param raffle The raffle to add the entry to.
     * @param currentEntryIndex The cumulative number of entries in the raffle minus one.
     * @param recipient The recipient of the entry.
     */
    function _pushEntry(
        Raffle storage raffle,
        uint40 currentEntryIndex,
        address recipient
    ) private {
        raffle.entries.push(Entry({currentEntryIndex: currentEntryIndex, participant: recipient}));
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

import {Math} from "./Math.sol";

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

/**
 * @notice It is emitted if the call recipient is not a contract.
 */
error NotAContract();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
}

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
pragma solidity ^0.8.17;

/**
 * @title IOwnableTwoSteps
 * @author LooksRare protocol team (👀,💎)
 */
interface IOwnableTwoSteps {
    /**
     * @notice This enum keeps track of the ownership status.
     * @param NoOngoingTransfer The default status when the owner is set
     * @param TransferInProgress The status when a transfer to a new owner is initialized
     * @param RenouncementInProgress The status when a transfer to address(0) is initialized
     */
    enum Status {
        NoOngoingTransfer,
        TransferInProgress,
        RenouncementInProgress
    }

    /**
     * @notice This is returned when there is no transfer of ownership in progress.
     */
    error NoOngoingTransferInProgress();

    /**
     * @notice This is returned when the caller is not the owner.
     */
    error NotOwner();

    /**
     * @notice This is returned when there is no renouncement in progress but
     *         the owner tries to validate the ownership renouncement.
     */
    error RenouncementNotInProgress();

    /**
     * @notice This is returned when the transfer is already in progress but the owner tries
     *         initiate a new ownership transfer.
     */
    error TransferAlreadyInProgress();

    /**
     * @notice This is returned when there is no ownership transfer in progress but the
     *         ownership change tries to be approved.
     */
    error TransferNotInProgress();

    /**
     * @notice This is returned when the ownership transfer is attempted to be validated by the
     *         a caller that is not the potential owner.
     */
    error WrongPotentialOwner();

    /**
     * @notice This is emitted if the ownership transfer is cancelled.
     */
    event CancelOwnershipTransfer();

    /**
     * @notice This is emitted if the ownership renouncement is initiated.
     */
    event InitiateOwnershipRenouncement();

    /**
     * @notice This is emitted if the ownership transfer is initiated.
     * @param previousOwner Previous/current owner
     * @param potentialOwner Potential/future owner
     */
    event InitiateOwnershipTransfer(address previousOwner, address potentialOwner);

    /**
     * @notice This is emitted when there is a new owner.
     */
    event NewOwner(address newOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRaffleV2 {
    enum RaffleStatus {
        None,
        Open,
        Drawing,
        RandomnessFulfilled,
        Drawn,
        Complete,
        Refundable,
        Cancelled
    }

    enum TokenType {
        ERC721,
        ERC1155,
        ETH,
        ERC20
    }

    /**
     * @param entriesCount The number of entries that can be purchased for the given price.
     * @param price The price of the entries.
     */
    struct PricingOption {
        uint40 entriesCount;
        uint208 price;
    }

    /**
     * @param currentEntryIndex The cumulative number of entries in the raffle minus one.
     * @param participant The address of the participant.
     */
    struct Entry {
        uint40 currentEntryIndex;
        address participant;
    }

    /**
     * @param participant The address of the winner.
     * @param claimed Whether the winner has claimed the prize.
     * @param prizeIndex The index of the prize that was won.
     * @param entryIndex The index of the entry that won.
     */
    struct Winner {
        address participant;
        bool claimed;
        uint8 prizeIndex;
        uint40 entryIndex;
    }

    /**
     * @param winnersCount The number of winners.
     * @param cumulativeWinnersCount The cumulative number of winners in the raffle.
     * @param prizeType The type of the prize.
     * @param prizeTier The tier of the prize.
     * @param prizeAddress The address of the prize.
     * @param prizeId The id of the prize.
     * @param prizeAmount The amount of the prize.
     */
    struct Prize {
        uint40 winnersCount;
        uint40 cumulativeWinnersCount;
        TokenType prizeType;
        uint8 prizeTier;
        address prizeAddress;
        uint256 prizeId;
        uint256 prizeAmount;
    }

    /**
     * @param owner The address of the raffle owner.
     * @param status The status of the raffle.
     * @param isMinimumEntriesFixed Whether the minimum number of entries is fixed.
     * @param cutoffTime The time after which the raffle cannot be entered.
     * @param drawnAt The time at which the raffle was drawn. It is still pending Chainlink to fulfill the randomness request.
     * @param minimumEntries The minimum number of entries required to draw the raffle.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param feeTokenAddress The address of the token to be used as a fee. If the fee token type is ETH, then this address is ignored.
     * @param protocolFeeBp The protocol fee in basis points. It must be equal to the protocol fee basis points when the raffle was created.
     * @param claimableFees The amount of fees collected from selling entries.
     * @param pricingOptions The pricing options for the raffle.
     * @param prizes The prizes to be distributed.
     * @param entries The entries that have been sold.
     * @param winners The winners of the raffle.
     */
    struct Raffle {
        address owner;
        RaffleStatus status;
        bool isMinimumEntriesFixed;
        uint40 cutoffTime;
        uint40 drawnAt;
        uint40 minimumEntries;
        uint40 maximumEntriesPerParticipant;
        address feeTokenAddress;
        uint16 protocolFeeBp;
        uint208 claimableFees;
        PricingOption[] pricingOptions;
        Prize[] prizes;
        Entry[] entries;
        Winner[] winners;
    }

    /**
     * @param amountPaid The amount paid by the participant.
     * @param entriesCount The number of entries purchased by the participant.
     * @param refunded Whether the participant has been refunded.
     */
    struct ParticipantStats {
        uint208 amountPaid;
        uint40 entriesCount;
        bool refunded;
    }

    /**
     * @param raffleId The id of the raffle.
     * @param pricingOptionIndex The index of the selected pricing option.
     * @param count The number of entries to be purchased.
     * @param recipient The recipient of the entries.
     */
    struct EntryCalldata {
        uint256 raffleId;
        uint256 pricingOptionIndex;
        uint40 count;
        address recipient;
    }

    /**
     * @param cutoffTime The time at which the raffle will be closed.
     * @param minimumEntries The minimum number of entries required to draw the raffle.
     * @param isMinimumEntriesFixed Whether the minimum number of entries is fixed.
     * @param maximumEntriesPerParticipant The maximum number of entries allowed per participant.
     * @param protocolFeeBp The protocol fee in basis points. It must be equal to the protocol fee basis points when the raffle was created.
     * @param feeTokenAddress The address of the token to be used as a fee. If the fee token type is ETH, then this address is ignored.
     * @param prizes The prizes to be distributed.
     * @param pricingOptions The pricing options for the raffle.
     */
    struct CreateRaffleCalldata {
        uint40 cutoffTime;
        bool isMinimumEntriesFixed;
        uint40 minimumEntries;
        uint40 maximumEntriesPerParticipant;
        uint16 protocolFeeBp;
        address feeTokenAddress;
        Prize[] prizes;
        PricingOption[] pricingOptions;
    }

    /**
     * @param raffleId The id of the raffle.
     * @param winnerIndices The indices of the winners to be claimed.
     */
    struct ClaimPrizesCalldata {
        uint256 raffleId;
        uint256[] winnerIndices;
    }

    /**
     * @param exists Whether the request exists.
     * @param randomWord The random words returned by Chainlink VRF.
     *                   If randomWord == 0, then the request is still pending.
     * @param raffleId The id of the raffle.
     */
    struct RandomnessRequest {
        bool exists;
        uint80 raffleId;
        uint256 randomWord;
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

    event CurrenciesStatusUpdated(address[] currencies, bool isAllowed);
    event EntryRefunded(uint256 raffleId, address buyer, uint208 amount);
    event EntrySold(uint256 raffleId, address buyer, address recipient, uint40 entriesCount, uint208 price);
    event FeesClaimed(uint256 raffleId, uint256 amount);
    event PrizeClaimed(uint256 raffleId, uint256 winnerIndex);
    event PrizesClaimed(uint256 raffleId, uint256[] winnerIndex);
    event ProtocolFeeBpUpdated(uint16 protocolFeeBp);
    event ProtocolFeeRecipientUpdated(address protocolFeeRecipient);
    event RaffleStatusUpdated(uint256 raffleId, RaffleStatus status);
    event RandomnessRequested(uint256 raffleId, uint256 requestId);

    error CutoffTimeNotReached();
    error CutoffTimeReached();
    error DrawExpirationTimeNotReached();
    error InsufficientNativeTokensSupplied();
    error InvalidCaller();
    error InvalidCount();
    error InvalidCurrency();
    error InvalidCutoffTime();
    error InvalidIndex();
    error InvalidPricingOption();
    error InvalidPricingOptionsCount();
    error InvalidPrize();
    error InvalidPrizesCount();
    error InvalidProtocolFeeBp();
    error InvalidProtocolFeeRecipient();
    error InvalidStatus();
    error InvalidWinnersCount();
    error MaximumEntriesPerParticipantReached();
    error MaximumEntriesReached();
    error NothingToClaim();
    error NotEnoughEntries();
    error RandomnessRequestAlreadyExists();
    error RandomnessRequestDoesNotExist();

    /**
     * @notice Creates a new raffle.
     * @param params The parameters of the raffle.
     * @return raffleId The id of the newly created raffle.
     */
    function createRaffle(CreateRaffleCalldata calldata params) external payable returns (uint256 raffleId);

    /**
     * @notice Enters a raffle or multiple raffles.
     * @param entries The entries to be made.
     */
    function enterRaffles(EntryCalldata[] calldata entries) external payable;

    /**
     * @notice Select the winners for a raffle based on the random words returned by Chainlink.
     * @param requestId The request id returned by Chainlink.
     */
    function selectWinners(uint256 requestId) external;

    /**
     * @notice Claims a single prize for a winner.
     * @param raffleId The id of the raffle.
     * @param winnerIndex The index of the winner.
     */
    function claimPrize(uint256 raffleId, uint256 winnerIndex) external;

    /**
     * @notice Claims the prizes for a winner. A winner can claim multiple prizes
     *         from multiple raffles in a single transaction.
     * @param claimPrizesCalldata The calldata for claiming prizes.
     */
    function claimPrizes(ClaimPrizesCalldata[] calldata claimPrizesCalldata) external;

    /**
     * @notice Claims the fees collected for a raffle.
     * @param raffleId The id of the raffle.
     */
    function claimFees(uint256 raffleId) external;

    /**
     * @notice Cancels a raffle beyond cut-off time without meeting minimum entries.
     * @param raffleId The id of the raffle.
     */
    function cancel(uint256 raffleId) external;

    /**
     * @notice Draws winners for a raffle beyond cut-off time without meeting minimum entries.
     * @param raffleId The id of the raffle.
     */
    function drawWinners(uint256 raffleId) external;

    /**
     * @notice Cancels a raffle after randomness request if the randomness request
     *         does not arrive after a certain amount of time.
     *         Only callable by contract owner.
     * @param raffleId The id of the raffle.
     */
    function cancelAfterRandomnessRequest(uint256 raffleId) external;

    /**
     * @notice Withdraws the prizes for a raffle after it has been marked as refundable.
     * @param raffleId The id of the raffle.
     */
    function withdrawPrizes(uint256 raffleId) external;

    /**
     * @notice Rollover entries from cancelled raffles to open raffles.
     * @param refundableRaffleIds The ids of the refundable raffles.
     * @param entries The entries to be made.
     */
    function rollover(uint256[] calldata refundableRaffleIds, EntryCalldata[] calldata entries) external payable;

    /**
     * @notice Claims the refund for a cancelled raffle.
     * @param raffleIds The ids of the raffles.
     */
    function claimRefund(uint256[] calldata raffleIds) external;

    /**
     * @notice Sets the protocol fee in basis points. Only callable by contract owner.
     * @param protocolFeeBp The protocol fee in basis points.
     */
    function setProtocolFeeBp(uint16 protocolFeeBp) external;

    /**
     * @notice Sets the protocol fee recipient. Only callable by contract owner.
     * @param protocolFeeRecipient The protocol fee recipient.
     */
    function setProtocolFeeRecipient(address protocolFeeRecipient) external;

    /**
     * @notice This function allows the owner to update currency statuses.
     * @param currencies Currency addresses (address(0) for ETH)
     * @param isAllowed Whether the currencies should be allowed for trading
     * @dev Only callable by owner.
     */
    function updateCurrenciesStatus(address[] calldata currencies, bool isAllowed) external;

    /**
     * @notice Toggle the contract's paused status. Only callable by contract owner.
     */
    function togglePaused() external;

    /**
     * @notice Gets the winners for a raffle.
     * @param raffleId The id of the raffle.
     * @return winners The winners of the raffle.
     */
    function getWinners(uint256 raffleId) external view returns (Winner[] memory);

    /**
     * @notice Gets the pricing options for a raffle.
     * @param raffleId The id of the raffle.
     * @return pricingOptions The pricing options for the raffle.
     */
    function getPricingOptions(uint256 raffleId) external view returns (PricingOption[] memory);

    /**
     * @notice Gets the prizes for a raffle.
     * @param raffleId The id of the raffle.
     * @return prizes The prizes to be distributed.
     */
    function getPrizes(uint256 raffleId) external view returns (Prize[] memory);

    /**
     * @notice Gets the entries for a raffle.
     * @param raffleId The id of the raffle.
     * @return entries The entries entered for the raffle.
     */
    function getEntries(uint256 raffleId) external view returns (Entry[] memory);
}

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

// Enums
import {TokenType} from "./TokenType.sol";

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

// Interfaces
import {IERC1155} from "./IERC1155.sol";

// Errors
import {ERC1155SafeTransferFromFail, ERC1155SafeBatchTransferFromFail} from "./LowLevelErrors.sol";
import {NotAContract} from "./GenericErrors.sol";

/**
 * @title LowLevelERC1155Transfer
 * @notice This contract contains low-level calls to transfer ERC1155 tokens.
 * @author LooksRare protocol team (👀,💎)
 */
contract LowLevelERC1155Transfer {
    /**
     * @notice Execute ERC1155 safeTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenId tokenId to transfer
     * @param amount Amount to transfer
     */
    function _executeERC1155SafeTransferFrom(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(abi.encodeCall(IERC1155.safeTransferFrom, (from, to, tokenId, amount, "")));

        if (!status) {
            revert ERC1155SafeTransferFromFail();
        }
    }

    /**
     * @notice Execute ERC1155 safeBatchTransferFrom
     * @param collection Address of the collection
     * @param from Address of the sender
     * @param to Address of the recipient
     * @param tokenIds Array of tokenIds to transfer
     * @param amounts Array of amounts to transfer
     */
    function _executeERC1155SafeBatchTransferFrom(
        address collection,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) internal {
        if (collection.code.length == 0) {
            revert NotAContract();
        }

        (bool status, ) = collection.call(
            abi.encodeCall(IERC1155.safeBatchTransferFrom, (from, to, tokenIds, amounts, ""))
        );

        if (!status) {
            revert ERC1155SafeBatchTransferFromFail();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IERC20} from "./IERC20.sol";

// Errors
import {ERC20TransferFail, ERC20TransferFromFail} from "./LowLevelErrors.sol";
import {NotAContract} from "./GenericErrors.sol";

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
import {IERC721} from "./IERC721.sol";

// Errors
import {ERC721TransferFromFail} from "./LowLevelErrors.sol";
import {NotAContract} from "./GenericErrors.sol";

/**
 * @title LowLevelERC721Transfer
 * @notice This contract contains low-level calls to transfer ERC721 tokens.
 * @author LooksRare protocol team (👀,💎)
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

// Interfaces
import {IWETH} from "./IWETH.sol";

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

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IOwnableTwoSteps} from "./IOwnableTwoSteps.sol";

/**
 * @title OwnableTwoSteps
 * @notice This contract offers transfer of ownership in two steps with potential owner
 *         having to confirm the transaction to become the owner.
 *         Renouncement of the ownership is also a two-step process since the next potential owner is the address(0).
 * @author LooksRare protocol team (👀,💎)
 */
abstract contract OwnableTwoSteps is IOwnableTwoSteps {
    /**
     * @notice Address of the current owner.
     */
    address public owner;

    /**
     * @notice Address of the potential owner.
     */
    address public potentialOwner;

    /**
     * @notice Ownership status.
     */
    Status public ownershipStatus;

    /**
     * @notice Modifier to wrap functions for contracts that inherit this contract.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @notice Constructor
     * @param _owner The contract's owner
     */
    constructor(address _owner) {
        owner = _owner;
        emit NewOwner(_owner);
    }

    /**
     * @notice This function is used to cancel the ownership transfer.
     * @dev This function can be used for both cancelling a transfer to a new owner and
     *      cancelling the renouncement of the ownership.
     */
    function cancelOwnershipTransfer() external onlyOwner {
        Status _ownershipStatus = ownershipStatus;
        if (_ownershipStatus == Status.NoOngoingTransfer) {
            revert NoOngoingTransferInProgress();
        }

        if (_ownershipStatus == Status.TransferInProgress) {
            delete potentialOwner;
        }

        delete ownershipStatus;

        emit CancelOwnershipTransfer();
    }

    /**
     * @notice This function is used to confirm the ownership renouncement.
     */
    function confirmOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.RenouncementInProgress) {
            revert RenouncementNotInProgress();
        }

        delete owner;
        delete ownershipStatus;

        emit NewOwner(address(0));
    }

    /**
     * @notice This function is used to confirm the ownership transfer.
     * @dev This function can only be called by the current potential owner.
     */
    function confirmOwnershipTransfer() external {
        if (ownershipStatus != Status.TransferInProgress) {
            revert TransferNotInProgress();
        }

        if (msg.sender != potentialOwner) {
            revert WrongPotentialOwner();
        }

        owner = msg.sender;
        delete ownershipStatus;
        delete potentialOwner;

        emit NewOwner(msg.sender);
    }

    /**
     * @notice This function is used to initiate the transfer of ownership to a new owner.
     * @param newPotentialOwner New potential owner address
     */
    function initiateOwnershipTransfer(address newPotentialOwner) external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.TransferInProgress;
        potentialOwner = newPotentialOwner;

        /**
         * @dev This function can only be called by the owner, so msg.sender is the owner.
         *      We don't have to SLOAD the owner again.
         */
        emit InitiateOwnershipTransfer(msg.sender, newPotentialOwner);
    }

    /**
     * @notice This function is used to initiate the ownership renouncement.
     */
    function initiateOwnershipRenouncement() external onlyOwner {
        if (ownershipStatus != Status.NoOngoingTransfer) {
            revert TransferAlreadyInProgress();
        }

        ownershipStatus = Status.RenouncementInProgress;

        emit InitiateOwnershipRenouncement();
    }

    function _onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Interfaces
import {IReentrancyGuard} from "./IReentrancyGuard.sol";

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

enum TokenType {
    ERC20,
    ERC721,
    ERC1155
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
pragma solidity 0.8.20;

/**
 * @title WinningEntrySearchLogicV2
 * @notice This contract contains the logic to search for a winning entry.
 * @author LooksRare protocol team (👀,💎)
 */
contract WinningEntrySearchLogicV2 {
    /**
     * @param randomWord The random word.
     * @param currentEntryIndex The current entry index.
     * @param winningEntriesBitmap The bitmap of winning entries.
     */
    function _searchForWinningEntryUntilThereIsNotADuplicate(
        uint256 randomWord,
        uint256 currentEntryIndex,
        uint256[] memory winningEntriesBitmap
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        uint256 winningEntry = randomWord % (currentEntryIndex + 1);

        uint256 bucket = winningEntry >> 8;
        uint256 mask = 1 << (winningEntry & 0xff);
        while (winningEntriesBitmap[bucket] & mask != 0) {
            randomWord = uint256(keccak256(abi.encodePacked(randomWord)));
            winningEntry = randomWord % (currentEntryIndex + 1);
            bucket = winningEntry >> 8;
            mask = 1 << (winningEntry & 0xff);
        }

        winningEntriesBitmap[bucket] |= mask;

        return (randomWord, winningEntry, winningEntriesBitmap);
    }
}