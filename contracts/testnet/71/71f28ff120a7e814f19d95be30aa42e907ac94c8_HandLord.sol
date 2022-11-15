/**
 *Submitted for verification at Arbiscan on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

//import "@std/console.sol";

interface IOracle {
    function requestRandom() external returns (uint256);
}

contract HandLord {
    // events
    event Win(uint256 indexed round, address indexed winner);

    struct Player {
        uint256 round;
        address user;
        bytes32 commitmentHash;
        uint256[] revealedCards;
        uint256[] candidateCards;
        uint256[] currentCards;
        uint256 lastActiveTime;
        uint256 status; // 0: not initialized; 1: ready; 2: commit; 3: reveal; 4: dead
        uint256 health;
    }

    // replay for settle
    struct Replay {
        address user1;
        uint256 card1; // cardType 1: stone;  2: scissors; 3: cloth
        address user2;
        uint256 card2;
        address winner;
    }
    Replay[] public replays;

    uint256 constant initialHealth = 5;
    uint256 constant timeout = 20; // timeout for 20s
    uint256 constant initialCardCount = 3;
    uint256 constant maxCardCount = 5;

    uint256 public status; // 0: not initialized; 1: new game; 2: playing;  3: game over
    uint256 public currentRound;

    address[] public players; // all players
    mapping(address => Player) public playerInfo;
    address[] internal activePlayers; // active players

    address internal oracle;
    address internal owner;

    constructor(address _oracle) {
        oracle = _oracle;
    }

    // new game
    function newGame() external {
        require(status == 0 || status == 3, "Game not end");

        // reset game
        _reset();

        // update players
        _setupNewPlayer(msg.sender);
        players.push(msg.sender);

        owner = msg.sender;
    }

    // join game
    function joinGame() external {
        require(status == 1, "Not ready!");
        require(playerInfo[msg.sender].status == 0, "Player is not ready or already playing!");

        _setupNewPlayer(msg.sender);
        players.push(msg.sender);
    }

    // start game
    function startGame() external {
        require(status == 1, "Not ready!");
        require(players.length >= 2, "Players must be at least 2");
        //        require(owner == msg.sender, "OnlyOwner");

        _prepareNextRound();

        // set game status: playing
        status = 2;
    }

    // commit encrypted cards
    function commit(uint256[] memory selectedCards, bytes32 commitmentHash) public {
        require(status == 2, "Game not started");
        require(playerInfo[msg.sender].health > 0, "You have lost the game!");

        // update current cards
        for (uint256 i = 0; i < selectedCards.length; i++) {
            require(
                _exist(selectedCards[i], playerInfo[msg.sender].candidateCards),
                "Selected cards not exist!"
            );
            playerInfo[msg.sender].currentCards.push(selectedCards[i]);
        }

        require(
            playerInfo[msg.sender].currentCards.length <= maxCardCount,
            "Current cards number > 5"
        );

        playerInfo[msg.sender].commitmentHash = commitmentHash;
        playerInfo[msg.sender].lastActiveTime = _now();
        playerInfo[msg.sender].status = 2; // commit
    }

    // reveal cards
    function reveal(uint256[] memory revealedCards) public {
        require(status == 2, "Game not started");
        require(playerInfo[msg.sender].health > 0, "You have lost the game!");

        bytes32 hash = keccak256(abi.encodePacked(revealedCards));
        require(hash == playerInfo[msg.sender].commitmentHash, "CommitmentHash not match");

        playerInfo[msg.sender].revealedCards = revealedCards;
        playerInfo[msg.sender].lastActiveTime = _now();
        playerInfo[msg.sender].status = 3; // reveal

        // delete revealedCards from currentCards
        for (uint256 i = 0; i < revealedCards.length; i++) {
            _deleteFromCurrentCards(msg.sender, revealedCards[i]);
        }

        // try settle
        _trySettle();
    }

    // settle current round
    function settle() external {
        require(status == 2, "Game not started");

        _settle();
    }

    function getGameInfo()
        external
        view
        returns (
            uint256 round,
            address winner,
            Player[] memory _playersInfo,
            Replay[] memory _replayInfo
        )
    {
        round = currentRound;
        winner = _getWinner();

        uint256 len = players.length;
        _playersInfo = new Player[](len);
        for (uint256 i = 0; i < len; i++) {
            address addr = players[i];
            _playersInfo[i] = playerInfo[addr];
        }

        _replayInfo = replays;
    }

    function autoRun() external {
        address account = msg.sender;
        // commit
        bytes32 hash = keccak256(abi.encodePacked(playerInfo[account].candidateCards));
        commit(playerInfo[account].candidateCards, hash);
        // reveal
        reveal(playerInfo[account].candidateCards);
    }

    function _setupNewPlayer(address account) internal {
        playerInfo[account].round = 0;
        playerInfo[account].user = msg.sender;
        playerInfo[account].commitmentHash = bytes32(0);
        playerInfo[account].lastActiveTime = _now();
        playerInfo[account].health = initialHealth;
        playerInfo[account].status = 1; // ready
    }

    function _deleteFromCurrentCards(address account, uint256 card) internal {
        uint256[] storage currentCards = playerInfo[account].currentCards;
        uint256 len = currentCards.length;
        uint256 idx;
        for (uint256 i = 0; i < len; i++) {
            if (card == currentCards[i]) {
                idx = i;
                break;
            }
        }
        require(idx < len, "Invalid revealedCards!");

        if (idx != len - 1) {
            currentCards[len - 1] = currentCards[idx];
        }

        currentCards.pop();
    }

    function _exist(uint256 card, uint256[] memory cards) internal pure returns (bool) {
        for (uint256 i = 0; i < cards.length; i++) {
            if (card == cards[i]) {
                return true;
            }
        }
        return false;
    }

    function _getWinner() internal view returns (address) {
        address winner;
        uint256 count;

        uint256 len = players.length;
        for (uint256 i = 0; i < len; i++) {
            address user = players[i];
            if (playerInfo[user].health > 0) {
                winner = playerInfo[user].user;
                count++;
            }
        }

        if (count > 1) {
            return address(0);
        } else {
            return winner;
        }
    }

    function _trySettle() internal {
        uint256 len = players.length;
        // only if all players has revealed cards
        for (uint256 i = 0; i < len; i++) {
            address user = players[i];
            if (playerInfo[user].health == 0) {
                // dead player
                continue;
            }
            if (playerInfo[user].round != currentRound || playerInfo[user].status != 3) {
                return;
            }
        }

        // settle
        _settle();
    }

    function _settle() internal {
        uint256 len = players.length;
        // init activePlayers
        delete activePlayers;
        for (uint256 i = 0; i < len; i++) {
            address user = players[i];
            if (playerInfo[user].health == 0) {
                // dead player
                continue;
            }

            if (
                playerInfo[user].status != 3 && playerInfo[user].lastActiveTime + timeout <= _now()
            ) {
                // timeout
                _decreaseHealth(user); // decrease health
                continue;
            }
            activePlayers.push(user);
        }

        uint256 activeLen = activePlayers.length;
        if (activeLen > 1) {
            // clear replays info for previous round
            delete replays;

            // battle
            uint256 minCardCount = maxCardCount;
            for (uint256 i = 0; i < activeLen; i++) {
                address user = activePlayers[i];
                minCardCount = _min(minCardCount, playerInfo[user].revealedCards.length);
            }

            for (uint256 j = 0; j < activeLen - 1; j++) {
                address user = activePlayers[j];
                if (playerInfo[user].revealedCards.length > minCardCount) {
                    _increaseHealth(user);
                }
            }

            for (uint256 i = 0; i < minCardCount; i++) {
                address winner = activePlayers[0];
                uint256 winnerCardNumber = playerInfo[winner].revealedCards[i];
                for (uint256 j = 1; j < activeLen; j++) {
                    address player2 = activePlayers[j];
                    uint256 card2 = playerInfo[player2].revealedCards[i];
                    (winner, winnerCardNumber) = _singlePK(
                        winner,
                        player2,
                        winnerCardNumber,
                        card2
                    );
                }
            }
        }

        // game end
        if (address(0) != _getWinner()) {
            emit Win(currentRound, _getWinner());
            // set game status: game over
            status = 3;
            return;
        }

        // enter next round
        _prepareNextRound();
    }

    function _prepareNextRound() internal {
        //  all players enter next round
        uint256 len = players.length;
        for (uint256 i = 0; i < len; i++) {
            address user = players[i];
            if (playerInfo[user].health == 0) {
                // dead player
                continue;
            }
            playerInfo[user].round = currentRound + 1;
            playerInfo[user].status = 1;
            playerInfo[user].lastActiveTime = _now();
            playerInfo[user].commitmentHash = 0;
            delete playerInfo[user].revealedCards;

            // deal candidates cards
            _dealCandidatesCards(user);
        }

        currentRound++;
    }

    function _dealCandidatesCards(address account) internal {
        // clear candidateCards
        delete playerInfo[account].candidateCards;

        for (uint256 j = 0; j < initialCardCount; j++) {
            playerInfo[account].candidateCards.push(_randomCard());
        }
    }

    function _increaseHealth(address account) internal {
        playerInfo[account].health = playerInfo[account].health + 1;
    }

    function _decreaseHealth(address account) internal {
        if (playerInfo[account].health >= 1) {
            playerInfo[account].health = playerInfo[account].health - 1;
        }
    }

    function _randomCard() internal returns (uint256) {
        return (IOracle(oracle).requestRandom() % 3) + 1;
    }

    function _now() internal view returns (uint256) {
        return block.timestamp;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return b;
        }
        return a;
    }

    function _isWinPK(uint256 card1, uint256 card2) internal pure returns (bool) {
        // 1 kill 2
        // 2 kill 3
        // 3 kill 1
        unchecked {
            if (card1 + 1 == card2 || card1 - 2 == card2) {
                return true;
            }
        }

        return false;
    }

    function _singlePK(
        address player1,
        address player2,
        uint256 card1,
        uint256 card2
    ) internal returns (address winner, uint256 winnerCardNumber) {
        // clear replays for previous round

        if (card1 == card2) {
            replays.push(
                Replay({
                    user1: player1,
                    card1: card1,
                    user2: player2,
                    card2: card2,
                    winner: address(0)
                })
            );

            winner = player1;
            winnerCardNumber = card1;
        } else if (_isWinPK(card1, card2)) {
            _increaseHealth(player1);
            _decreaseHealth(player2);
            replays.push(
                Replay({
                    user1: player1,
                    card1: card1,
                    user2: player2,
                    card2: card2,
                    winner: player1
                })
            );

            winner = player1;
            winnerCardNumber = card1;
        } else {
            _increaseHealth(player2);
            _decreaseHealth(player1);
            replays.push(
                Replay({
                    user1: player1,
                    card1: card1,
                    user2: player2,
                    card2: card2,
                    winner: player2
                })
            );

            winner = player2;
            winnerCardNumber = card2;
        }
    }

    function _reset() internal {
        // reset
        for (uint256 i = 0; i < players.length; i++) {
            delete playerInfo[players[i]];
        }

        delete players;

        currentRound = 0;

        // new game status: new game
        status = 1;
    }
}