/**
 *Submitted for verification at Arbiscan on 2022-08-30
*/

pragma solidity ^0.5.7;

// @author K.C. @FHDO
// @title Eine simple, faire Lotterie
contract Lottery {
    // Globale Variablen
    address payable public owner;
    uint public currentRoundId;
    uint public roundDuration;
    uint public ticketPrice;

    struct Ticket {
        address buyer;
        uint amount;
    }

    struct Round {
        // Runden Informationen
        uint roundId;
        uint startTime;
        uint endTime;

        // Ticket Informationen
        uint ticketCounter;
        Ticket[] allTickets;

        // Gewinner Informationen
        address winner;
    }

    constructor() public {
        owner = msg.sender;
        currentRoundId = 0;
        roundDuration = 5 minutes;
        ticketPrice = 0.0001 ether;
    }

    // Mapping um die Spielrunden zu verwalten
    mapping (uint => Round) public rounds;

    // Mapping um die Preisgelder der Gewinner zu verwalten
    mapping (address => uint) public pendingWithdrawals;

    // Events für externe Programme
    event LogBuyTickets(address buyer, uint amount);
    event LogDrawWinner(address winner, uint prize);
    event LogWithdrawPrize(address winner, uint prize);

    // Methode um einen oder mehrere Tickets zu kaufen
    function buyTickets() external payable {
        require(msg.value >= ticketPrice,
                "You didn't send enough Ether.");
        require(msg.value % ticketPrice == 0,
                "You can only buy multiples of the ticket price.");

        Round storage curRound = rounds[currentRoundId];

        // Falls die letzte Runde beendet wurde,
        // wird die nächste Runde gestartet
        if (now > curRound.endTime) {
            currentRoundId++;
            curRound = rounds[currentRoundId];
            curRound.roundId = currentRoundId;
            curRound.startTime = now;
            curRound.endTime = curRound.startTime + roundDuration;
        }

        uint wantedTicketAmount = msg.value / ticketPrice;
        Ticket memory ticket = Ticket(msg.sender, wantedTicketAmount);
        curRound.allTickets.push(ticket);
        curRound.ticketCounter += wantedTicketAmount;
        emit LogBuyTickets(msg.sender, wantedTicketAmount);
    }

    // Methode um den Gewinner der gewünschten Lotterie Runde zu ziehen
    function drawWinner(uint roundId) public {
        Round storage curRound = rounds[roundId];

        require(curRound.ticketCounter > 0, "No Tickets were bought yet.");
        require(now > curRound.endTime, "The round didn't end yet.");
        require(curRound.winner == address(0), "Winner got already drawn!");

        // Generierung einer zufälligen Zahl
        // ACHTUNG: keine sichere Art der Zufallszahlgenerierung
        bytes memory randomBytes = abi.encodePacked(block.number, roundId);
        uint randomNumber = uint(keccak256(randomBytes));
        // Auslosung des Gewinner Tickets anhand der zufälligen Zahl
        uint winnerTicket = randomNumber % curRound.ticketCounter;
        uint prize = curRound.ticketCounter * ticketPrice;
        // Suche wem das gewinnende Ticket gehört
        uint tmpCounter = 0;
        for(uint i = 0; i<curRound.allTickets.length; i++) {
            tmpCounter += curRound.allTickets[i].amount;
            if (tmpCounter > winnerTicket) {
                curRound.winner = curRound.allTickets[i].buyer;
                pendingWithdrawals[curRound.winner] += prize;
                emit LogDrawWinner(curRound.winner, prize);
                break;
            }
        }
    }

    // Methode um den Gewinner der aktuellen Lotterie Runde zu ziehen
    function drawWinner() public {
        drawWinner(currentRoundId);
    }

    // Methode damit der Gewinner seine Preisgelder jederzeit abheben kann
    function withdrawPrize() external {
        require(pendingWithdrawals[msg.sender] > 0,
                "You don't have anything to withdraw.");

        uint prize = pendingWithdrawals[msg.sender];
        // pendingWithdrawals wird auf 0 gesetzt
        // um einen Reentrancy Attack zu verhindern
        pendingWithdrawals[msg.sender] = 0;
        emit LogWithdrawPrize(msg.sender, prize);
        msg.sender.transfer(prize);
    }

    // Getter für die selbst gekauften Tickets der aktuellen Runde
    function getOwnerTickets() external view returns(uint) {
        uint boughtTickets = 0;

        Ticket[] memory curTickets = rounds[currentRoundId].allTickets;
        for(uint i = 0; i<curTickets.length; i++) {
            Ticket memory curTicket = curTickets[i];
            if (msg.sender == curTicket.buyer) {
                boughtTickets += curTicket.amount;
            }
        }
        return boughtTickets;
    }

    // Methode um den Smart Contract zu beenden
    function kill() external {
        require(msg.sender == owner, "Only the owner can kill this contract.");
        selfdestruct(owner);
    }

    // Getter für das Preisgeld der gewünschten Lotterie Runde
    function getPrizeAmount(uint roundId) public view returns(uint){
        return rounds[roundId].ticketCounter * ticketPrice;
    }

    // Getter für das Preisgeld der aktuellen Lotterie Runde
    function getCurrentPrizeAmount() external view returns(uint){
        return getPrizeAmount(currentRoundId);
    }

    // Getter für den Gewinner der gewünschten Lotterie Runde
    function getWinner(uint roundId) public view returns(address) {
        return rounds[roundId].winner;
    }

    // Getter für den Gewinner der aktuellen Lotterie Runde
    function getCurrentWinner() external view returns(address) {
        return getWinner(currentRoundId);
    }
}