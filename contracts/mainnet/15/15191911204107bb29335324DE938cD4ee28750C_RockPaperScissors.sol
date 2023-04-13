/**
 *Submitted for verification at Arbiscan on 2023-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RockPaperScissors {
    enum Move {ROCK, PAPER, SCISSORS}
    enum Result {TIE, PLAYER1_WIN, PLAYER2_WIN}
    
    struct Game {
        address player1;
        address player2;
        uint256 player1Move;
        uint256 player2Move;
        uint256 player1Bet;
        uint256 player2Bet;
    }
    
    mapping(uint256 => Game) private games;
    uint256 public gameIndex;
    
    function createGame(uint256 _player1Move) public payable returns (uint256) {
        require(_player1Move >= 0 && _player1Move <= 2, "Invalid move");
        
        gameIndex++;
        Game storage game = games[gameIndex];
        game.player1 = msg.sender;
        game.player1Move = _player1Move;
        game.player1Bet = msg.value;
        return gameIndex;
    }
    
    function joinGame(uint256 _gameIndex, uint256 _player2Move) public payable {
        Game storage game = games[_gameIndex];
        require(msg.value == game.player1Bet, "Invalid bet amount");
        require(_player2Move >= 0 && _player2Move <= 2, "Invalid move");
        require(game.player2 == address(0), "Game already has two players");

        game.player2 = msg.sender;
        game.player2Move = _player2Move;
        game.player2Bet = msg.value;
        
        Result result = determineWinner(game.player1Move, game.player2Move);
        
        if (result == Result.PLAYER1_WIN) {
            payable(game.player1).transfer(game.player1Bet + game.player2Bet);
        } else if (result == Result.PLAYER2_WIN) {
            payable(game.player2).transfer(game.player1Bet + game.player2Bet);
        } else {
            payable(game.player1).transfer(game.player1Bet);
            payable(game.player2).transfer(game.player2Bet);
        }
    }
    
    function determineWinner(uint256 _player1Move, uint256 _player2Move) private pure returns (Result) {
        if (_player1Move == _player2Move) {
            return Result.TIE;
        } else if ((_player1Move == uint256(Move.ROCK) && _player2Move == uint256(Move.SCISSORS)) ||
                   (_player1Move == uint256(Move.PAPER) && _player2Move == uint256(Move.ROCK)) ||
                   (_player1Move == uint256(Move.SCISSORS) && _player2Move == uint256(Move.PAPER))) {
            return Result.PLAYER1_WIN;
        } else {
            return Result.PLAYER2_WIN;
        }
    }
}