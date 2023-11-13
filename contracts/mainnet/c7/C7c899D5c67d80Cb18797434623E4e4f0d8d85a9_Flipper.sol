// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.9;

contract Flipper {
    event PaymentMade(address winner, address loser, uint256 amount);
    event ContractChanged();
    address payable private owner = payable(0xE35Cc30779b15b6DA63d7C3B7e0ed793390A5592);
    address payable public player1;
    address payable public player2;
    uint256 public betAmount = 0;
    uint256 private lastBlock;

    function joinGame1() public payable {
        require(msg.value > 0, "You must bet some amount.");
        require(player1 == address(0), "Seat 1 is already occupied.");
        require(payable(msg.sender) != player2, "You cannot sit on both sides of the table.");
        if (player2 != address(0)) {
            require(msg.value == betAmount, "You must match the first player's bet.");
            player1 = payable(msg.sender);
            lastBlock = block.number;
        } else {
            betAmount = msg.value;
            player1 = payable(msg.sender);
        }
        emit ContractChanged();
    }

    function joinGame2() public payable {
        require(msg.value > 0, "You must bet some amount.");
        require(player2 == address(0), "Seat 2 is already occupied.");
        require(payable(msg.sender) != player1, "You cannot sit on both sides of the table.");
        if (player1 != address(0)) {
            require(msg.value == betAmount, "You must match the first player's bet.");
            player2 = payable(msg.sender);
            lastBlock = block.number;
        } else {
            betAmount= msg.value;
            player2 = payable(msg.sender);
        }
        emit ContractChanged();
    }

    function getWinner() public {
        require(player1 != address(0) && player2 != address(0), "Need 2 players before getting a winner.");
        require(block.number > lastBlock + 1, "Must wait for block delay before getting a winner");
        if (block.number <= lastBlock + 255) {
            owner.transfer(address(this).balance / 133);  // Send fee to owner
            if (uint256(blockhash(lastBlock)) % 2 == 0) {
                emit PaymentMade(player1, player2, address(this).balance);
                player1.transfer(address(this).balance);
            } else {
                emit PaymentMade(player2, player1, address(this).balance);
                player2.transfer(address(this).balance);
            }
        } else {
            invalidateGame();
            emit ContractChanged();
        }
        resetGame();
    }

    function terminateGame() public {
        require((msg.sender == player1 && player2 == address(0)) ||
        (msg.sender == player2 && player1 == address(0)) ||
        (msg.sender == owner && block.number > lastBlock + 50),
            "Only player 1, player 2 or the owner can terminate the game.");
        if (msg.sender == owner) {
            invalidateGame();
        } else {
            if (player1 != payable(address(0))) {
                player1.transfer(address(this).balance);
            }
            if (player2 != payable(address(0))) {
                player2.transfer(address(this).balance);
            }
        }
        resetGame();
        emit ContractChanged();
    }

    function invalidateGame() private {
        owner.transfer(address(this).balance / 20);
        if (player1 != payable(address(0)) && player2 != payable(address(0))) {
            player1.transfer(address(this).balance / 2);
            player2.transfer(address(this).balance);
        } else if (player1 != payable(address(0))) {
            player1.transfer(address(this).balance);
        } else if (player2 != payable(address(0))) {
            player2.transfer(address(this).balance);
        }
    }

    function resetGame() private {
        player1 = payable(address(0));
        player2 = payable(address(0));
    }
}