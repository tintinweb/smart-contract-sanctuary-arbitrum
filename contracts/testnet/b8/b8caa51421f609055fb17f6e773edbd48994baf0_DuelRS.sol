/**
 *Submitted for verification at Arbiscan.io on 2023-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract DuelRS {

    struct Duel {
        uint256 duelId;
        uint256 duelType; 
        uint256 betAmount;
        address player1;
        address player2;
    }

    mapping(uint256 => Duel) public duels;
    uint256 public nextDuelId = 0;

    mapping(uint256 => mapping(address => bool)) private cancelMatchSignatures;

    address private _owner;

    uint256 public feePercentDenominator = 10000;

    uint256 public feePercentNumerator = 500;

    address public treasury;

    event DuelCreated(uint256 duelId, address indexed player1); 
    event DuelJoined(uint256 duelId, address indexed player2);
    event DuelCancelled(uint256 duelId);
    event DuelEnded(uint256 duelId, address winner);

    constructor(address _treasury) {
        _owner = msg.sender;
        treasury = _treasury;
    }

    /** External **/
    function createPrivateDuel(uint256 _duelType, uint256 _betAmount, address _player2) external payable {
        require(msg.value == _betAmount, "Bet amount must duel sent value");
        require(_player2 != address(0), "Player 2 cannot be null");
        require(_player2 != msg.sender, "Cannot duel yourself");
        
        duels[nextDuelId] = Duel(
            nextDuelId,
            _duelType,
            _betAmount,
            msg.sender,
            _player2
        );
        emit DuelCreated(nextDuelId, msg.sender);
        nextDuelId++;
    }

    function createPublicDuel(uint256 _duelType, uint256 _betAmount) external payable {
        require(msg.value == _betAmount, "Bet amount must duel sent value");
        duels[nextDuelId] = Duel(
            nextDuelId,
            _duelType,
            _betAmount,
            msg.sender,
            address(0)
        );
        emit DuelCreated(nextDuelId, msg.sender);
        nextDuelId++;
    }

    function joinDuel(uint256 _duelId) external payable {
        Duel storage duel = duels[_duelId];
        require(msg.sender != duel.player1, "Cannot join your own duel");
        require(duel.player2 == address(0), "duel already has second player"); 
        require(duels[_duelId].betAmount != 0, "Duel does not exist");
        require(msg.value == duel.betAmount, "Bet amount must duel");
        duel.player2 == msg.sender;
        emit DuelJoined(_duelId, msg.sender);
    }

    function cancelOpenDuel(uint256 _duelId) external {
        Duel storage duel = duels[_duelId];
        require(msg.sender == duel.player1, "Only player 1 can cancel");
        require(duel.player2 == address(0), "Cannot cancel duel that has begun");

        duel.betAmount = 0;
        (bool success, ) = duel.player1.call{value: duel.betAmount}("");
        require(success, "Transfer failed.");
        emit DuelCancelled(_duelId);
    }
    
    function signCancelDuel(uint256 _duelId) external {
      Duel storage duel = duels[_duelId];

      // Check caller is a player in this duel
      require(msg.sender == duel.player1 || msg.sender == duel.player2, "Not a player");

      // Set their signature 
      cancelMatchSignatures[_duelId][msg.sender] = true;
    }

    function cancelActiveDuel(uint256 _duelId) external {
        Duel storage duel = duels[_duelId];
        require (cancelMatchSignatures[_duelId][duel.player1] && 
            cancelMatchSignatures[_duelId][duel.player2], "Both players must sign") ;

        uint256 betAmount = duel.betAmount;
        duel.betAmount = 0;
        (bool success, ) = duel.player1.call{value: betAmount}("");
        require(success, "Transfer failed.");

        (bool success2, ) = duel.player2.call{value: betAmount}("");
        require(success2, "Transfer failed.");

        emit DuelCancelled(_duelId);
    }

    function endDuel(uint256 _duelId, address _winnerId) external {
        require(_owner == msg.sender, "Unauthorized");
        Duel storage duel = duels[_duelId];
        uint256 betAmount = duel.betAmount;
        duel.betAmount = 0;

        // Calculate fee based on percentage
        uint256 fee = (betAmount * feePercentNumerator) / feePercentDenominator;

        (bool success, ) = _winnerId.call{value: (betAmount - fee)}("");
        require(success, "Transfer failed.");

        (bool success2, ) = treasury.call{value: (fee)}("");
        require(success2, "Transfer failed.");

        emit DuelEnded(_duelId, _winnerId);
    }

    function updateFeePercent(uint256 _feeNumerator) external {
        require(msg.sender == _owner, "Unauthorized");
        feePercentNumerator = _feeNumerator; 
    }

    /** Getters **/
    function getOpenPublicDuels(uint256 startIndex, uint256 endIndex) external view returns (Duel[] memory) {
        Duel[] memory openDuels = new Duel[](endIndex - startIndex);
        uint256 currentIndex = 0;

        for (uint256 i = startIndex; i < endIndex; i++) {
            Duel storage duel = duels[i];
            if (duel.player2 == address(0) && duel.betAmount != 0) {
            openDuels[currentIndex] = duel;
            currentIndex++; 
            }
        }
        return openDuels;
    }

    function getDuelsByAddress(address player) external view returns (Duel[] memory) {
        Duel[] memory duelsForPlayer = new Duel[](nextDuelId); 
        uint256 count = 0;
        for (uint i = 0; i < nextDuelId; i++) {
            if (duels[i].player1 == player || duels[i].player2 == player) {
                duelsForPlayer[count] = duels[i];
                count++;
            }
        }
        Duel[] memory result = new Duel[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = duelsForPlayer[i];
        }
        return result;
    }
    
    function canCloseDuel(uint256 _duelId) external view returns (bool) {

      Duel storage duel = duels[_duelId];

      require(duel.player2 != address(0), "Duel not active");

      bool player1Signed = cancelMatchSignatures[_duelId][duel.player1];
      bool player2Signed = cancelMatchSignatures[_duelId][duel.player2];

      if(player1Signed && player2Signed) {
            return true; 
        } else {
            return false;
        }
    }
}