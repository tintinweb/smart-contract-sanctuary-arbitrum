/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract RPS {
    address firstPlayer;
    address secondPlayer;

    bytes32 private firstPlayerHash;
    bytes32 private secondPlayerHash;

    enum Move {
        Empty,
        Rock,
        Paper,
        Scissor
    }

    enum Result {
        None,
        FirstPlayer,
        SecondPlayer,
        Draw
    }

    Move public firstPlayerChoice = Move.Empty;
    Move public secondPlayerChoice = Move.Empty;

    bool gameEnded = false;

    modifier notAlreadyRegistered() {
        require(
            msg.sender != firstPlayer && msg.sender != secondPlayer,
            "already registered"
        );
        _;
    }

    function resetAll() public {
        require(gameEnded);

        firstPlayerHash = 0x0;
        secondPlayerHash = 0x0;
        firstPlayerChoice = Move.Empty;
        secondPlayerChoice = Move.Empty;
        gameEnded = false;
    }

    function register() public notAlreadyRegistered {
        if (firstPlayer == address(0x0)) {
            firstPlayer = msg.sender;
        } else if (secondPlayer == address(0x0)) {
            secondPlayer = msg.sender;
        } else {
            revert("both players registered");
        }
    }

    // commit the choice (Rock / Paper / Scissor)
    function commitChoice(bytes32 hash) public payable {
        if (msg.sender == firstPlayer && firstPlayerHash == 0x0) {
            firstPlayerHash = hash;
        } else if (msg.sender == secondPlayer && secondPlayerHash == 0x0) {
            secondPlayerHash = hash;
        } else {
            revert("invalid player or move registered");
        }
    }

    // reveal the choice (Rock / Paper / Scissor)
    function revealChoice(Move move, uint salt) public {
        require(
            msg.sender == firstPlayer || msg.sender == secondPlayer,
            "player not registered"
        );
        require(
            firstPlayerHash != 0 && secondPlayerHash != 0,
            "someone did not submit hash"
        );
        require(move != Move.Empty, "have to choose Rock/Paper/Scissor");

        if (msg.sender == firstPlayer) {
            if (firstPlayerHash == sha256(abi.encodePacked(move, salt))) {
                firstPlayerChoice = move;
            }
        } else {
            if (secondPlayerHash == sha256(abi.encodePacked(move, salt))) {
                secondPlayerChoice = move;
            }
        }

        if (
            !(firstPlayerChoice == Move.Empty &&
                secondPlayerChoice == Move.Empty)
        ) {
            gameEnded = true;
        }
    }

    // check the result
    function getResult() public view returns (Result res) {
        require(gameEnded == true, "someone did not reveal their choice");

        // draw
        if (firstPlayerChoice == secondPlayerChoice) {
            res = Result.Draw;
        } else if (firstPlayerChoice == Move.Rock) {
            if (secondPlayerChoice == Move.Paper) {
                res = Result.SecondPlayer;
            } else {
                res = Result.FirstPlayer;
            }
        } else if (firstPlayerChoice == Move.Paper) {
            if (secondPlayerChoice == Move.Scissor) {
                res = Result.SecondPlayer;
            } else {
                res = Result.FirstPlayer;
            }
        } else if (firstPlayerChoice == Move.Scissor) {
            if (secondPlayerChoice == Move.Rock) {
                res = Result.SecondPlayer;
            } else {
                res = Result.FirstPlayer;
            }
        }
    }
}

contract Factory {
    address public rps;

    // Returns the address of the newly deployed contract
    function deploy(bytes32 _salt) public payable returns (address) {
        // This syntax is a newer way to invoke create2 without assembly, you just need to pass salt
        // https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
        rps = address(new RPS{salt: _salt}());
        return rps;
    }
}