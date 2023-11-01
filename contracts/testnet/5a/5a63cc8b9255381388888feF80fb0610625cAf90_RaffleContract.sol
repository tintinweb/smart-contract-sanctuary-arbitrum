/**
 *Submitted for verification at Arbiscan.io on 2023-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function clientWithdrawTo(address _to, uint256 _amount) external;
}

contract RaffleContract {
    address public owner;
    IRandomizer public randomizer;
    uint256 public currentRaffleId = 0;

    enum RaffleStatus {
        ACTIVE,
        FINALIZING,
        FINALIZED
    }

    struct Raffle {
        uint256 id;
        uint256 entryFee;
        uint256 maxUsers;
        uint256 minEntries;
        uint256 endTimestamp;
        uint256 currentEntries;
        RaffleStatus status;
        mapping(address => uint256) participants;
        address[] participantAddresses;
        uint256 prizePool; // added prizePool to store the initial funds
        Discount[] discounts;
    }

    struct Discount {
        uint256 ticketThreshold; // Number of tickets for this discount (e.g., 5, 20, 50)
        uint256 discountPercent; // The discount in percentage (e.g., 10 for 10%)
    }

    mapping(uint256 => Raffle) public raffles;
    mapping(uint256 => uint256) public raffleToRandomId;
    mapping(uint256 => address) public raffleWinners;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function getRaffleWinner(uint256 raffleId) external view returns (address) {
    return raffleWinners[raffleId];
        }

    modifier raffleExists(uint256 raffleId) {
        require(
            raffles[raffleId].status != RaffleStatus.FINALIZED,
            "Raffle does not exist or is finalized."
        );
        _;
    }

    // Events
    event RaffleCreated(uint256 raffleId);
    event EntryPurchased(
        address indexed user,
        uint256 raffleId,
        uint256 numberOfEntries
    );
    event EntryRefunded(address indexed user, uint256 raffleId);
    event RaffleFinalized(uint256 raffleId, address winner);

    address public platformAddress;
    uint256 public platformFee; // This will be in basis points for precision. 100 basis points = 1%

    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(address _randomizerAddress) {
        owner = msg.sender;
        randomizer = IRandomizer(_randomizerAddress);
        platformAddress = msg.sender;
        platformFee = 500;
    }

    function setPlatformAddress(address _platformAddress) external onlyOwner {
        platformAddress = _platformAddress;
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= 10000, "Fee can't be more than 100%"); // 10000 basis points = 100%
        platformFee = _platformFee;
    }

    function createRaffle(
        uint256 _entryFee,
        uint256 _maxUsers,
        uint256 _minEntries,
        uint256 _endTimestamp,
        Discount[] memory _discounts
    ) external payable onlyOwner whenNotPaused {
        require(
            _endTimestamp > block.timestamp,
            "End timestamp should be in the future."
        );

        currentRaffleId++;
        Raffle storage newRaffle = raffles[currentRaffleId];
        newRaffle.id = currentRaffleId;
        newRaffle.entryFee = _entryFee;
        newRaffle.maxUsers = _maxUsers;
        newRaffle.minEntries = _minEntries;
        newRaffle.endTimestamp = _endTimestamp;
        newRaffle.currentEntries = 0;
        newRaffle.status = RaffleStatus.ACTIVE;
        newRaffle.prizePool = msg.value; // Storing the initial funds sent with the contract call

        for (uint256 i = 0; i < _discounts.length; i++) {
            newRaffle.discounts.push(_discounts[i]);
        }

        emit RaffleCreated(currentRaffleId);
    }

    function calculateTicketPrice(uint256 numberOfTickets, uint256 entryFee)
        internal
        pure
        returns (uint256)
    {
        if (numberOfTickets == 1) {
            return entryFee; // Full price
        } else if (numberOfTickets <= 5) {
            return (entryFee * 9 * numberOfTickets) / 10; // 10% discount
        } else if (numberOfTickets <= 20) {
            return (entryFee * 85 * numberOfTickets) / 100; // 15% discount
        } else if (numberOfTickets >= 50) {
            return (entryFee * 8 * numberOfTickets) / 10; // 20% discount
        }
    }

    function buyEntry(uint256 raffleId, uint256 numberOfTickets)
    external
    payable
    whenNotPaused
{
    Raffle storage raffle = raffles[raffleId];
    require(raffle.status == RaffleStatus.ACTIVE, "Raffle is not active");
    require(
        raffle.participantAddresses.length < raffle.maxUsers,
        "Max users limit reached"
    );

    uint256 discountedPrice = calculateTicketPrice(
        numberOfTickets,
        raffle.entryFee
    );
    require(msg.value == discountedPrice, "Incorrect Ether sent");

    if (raffle.participants[msg.sender] == 0) {
        require(
            raffle.participantAddresses.length < raffle.maxUsers,
            "Max participants reached"
        );
        raffle.participantAddresses.push(msg.sender);
    }
    raffle.participants[msg.sender] += numberOfTickets;

    // Update the currentEntries value here
    raffle.currentEntries += numberOfTickets;

    emit EntryPurchased(msg.sender, raffleId, numberOfTickets);
}


    function refundIfMinNotMet(uint256 raffleId)
        external
        raffleExists(raffleId)
    {
        require(
            block.timestamp >= raffles[raffleId].endTimestamp,
            "Raffle has not ended yet."
        );
        require(
            raffles[raffleId].currentEntries < raffles[raffleId].minEntries,
            "Minimum entries requirement met. Cannot refund."
        );

        uint256 participantEntries = raffles[raffleId].participants[msg.sender];
        require(participantEntries > 0, "You have no entries to refund.");

        uint256 refundAmount = participantEntries * raffles[raffleId].entryFee;
        raffles[raffleId].participants[msg.sender] = 0;
        payable(msg.sender).transfer(refundAmount);

        emit EntryRefunded(msg.sender, raffleId);
    }

    function getRaffleStatus(uint256 raffleId)
        external
        view
        returns (
            uint256 id,
            uint256 entryFee,
            uint256 maxUsers,
            uint256 minEntries,
            uint256 endTimestamp,
            uint256 currentEntries,
            RaffleStatus status
        )
    {
        Raffle storage raffle = raffles[raffleId];
        return (
            raffle.id,
            raffle.entryFee,
            raffle.maxUsers,
            raffle.minEntries,
            raffle.endTimestamp,
            raffle.currentEntries,
            raffle.status
        );
    }

    function getUserEntries(uint256 raffleId, address user)
        external
        view
        returns (uint256)
    {
        return raffles[raffleId].participants[user];
    }

    function finalizeRaffle(uint256 raffleId)
        external
        onlyOwner
        raffleExists(raffleId)
    {
        require(
            raffles[raffleId].status == RaffleStatus.ACTIVE,
            "Raffle already being finalized or finalized."
        );
        require(
            block.timestamp > raffles[raffleId].endTimestamp,
            "Raffle has not ended yet."
        );

        uint256 randomId = randomizer.request(50000);
        raffleToRandomId[raffleId] = randomId;

        raffles[raffleId].status = RaffleStatus.FINALIZING;
    }

    function randomizerCallback(uint256 _randomId, bytes32 _value)
        external
        whenNotPaused
    {
        require(msg.sender == address(randomizer), "Caller not Randomizer");

        uint256 raffleId = raffleToRandomId[_randomId];
        Raffle storage raffle = raffles[raffleId];
        require(
            raffle.status == RaffleStatus.FINALIZING,
            "Invalid raffle status"
        );

        uint256 randomWinnerIndex = uint256(_value) % raffle.currentEntries;
        uint256 count = 0;
        address winner;
        for (uint256 i = 0; i < raffle.participantAddresses.length; i++) {
            address participant = raffle.participantAddresses[i];
            uint256 entries = raffle.participants[participant];
            if (randomWinnerIndex < (count + entries)) {
                winner = participant;
                break;
            }
            count += entries;
        }
        raffleWinners[raffleId] = winner;
        raffle.status = RaffleStatus.FINALIZED;

        uint256 totalCollection = (raffle.entryFee * raffle.currentEntries) +
            raffle.prizePool; // Adjusting the totalCollection to include the prize pool
        uint256 feeAmount = (platformFee * totalCollection) / 10000;
        uint256 winnerAmount = totalCollection - feeAmount;

        payable(platformAddress).transfer(feeAmount);
        payable(winner).transfer(winnerAmount);

        emit RaffleFinalized(raffleId, winner);
    }

    /**
     * @dev Returns an array of raffle IDs that are currently active.
     */
    function getActiveRaffles() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= currentRaffleId; i++) {
            if (raffles[i].status == RaffleStatus.ACTIVE) {
                activeCount++;
            }
        }

        uint256[] memory activeRaffles = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= currentRaffleId; i++) {
            if (raffles[i].status == RaffleStatus.ACTIVE) {
                activeRaffles[index] = i;
                index++;
            }
        }
        return activeRaffles;
    }

    /**
     * @dev Returns an array of the last 5 raffle IDs that have been finalized.
     */
    function getLastFinishedRaffles() external view returns (uint256[] memory) {
        uint256[] memory finishedRaffles = new uint256[](5);
        uint256 index = 0;

        for (uint256 i = currentRaffleId; i > 0 && index < 5; i--) {
            if (raffles[i].status == RaffleStatus.FINALIZED) {
                finishedRaffles[index] = i;
                index++;
            }
        }

        // Resize array if fewer than 5 finished raffles
        if (index < 5) {
            uint256[] memory resizedArray = new uint256[](index);
            for (uint256 i = 0; i < index; i++) {
                resizedArray[i] = finishedRaffles[i];
            }
            return resizedArray;
        }

        return finishedRaffles;
    }

    function getLatestRaffleDetails()
        external
        view
        returns (
            uint256 raffleId,
            uint256 prizePool,
            uint256 totalPlayers,
            uint256 ticketPrice,
            uint256 endTime,
            RaffleStatus status // Add this line for the status
        )
    {
        Raffle storage latestRaffle = raffles[currentRaffleId];

        return (
            latestRaffle.id,
            latestRaffle.prizePool +
                (latestRaffle.entryFee * latestRaffle.currentEntries), // Total prize pool
            latestRaffle.participantAddresses.length, // Total unique players
            latestRaffle.entryFee,
            latestRaffle.endTimestamp,
            latestRaffle.status // Add this line for the status
        );
    }

    function getParticipantsWithEntries(uint256 raffleId) external view returns (address[] memory, uint256[] memory) {
    Raffle storage raffle = raffles[raffleId];
    uint256 participantCount = raffle.participantAddresses.length;

    address[] memory participants = new address[](participantCount);
    uint256[] memory entries = new uint256[](participantCount);

    for (uint256 i = 0; i < participantCount; i++) {
        participants[i] = raffle.participantAddresses[i];
        entries[i] = raffle.participants[participants[i]];
    }

    return (participants, entries);
   }


    // Pause mechanism
    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }
}