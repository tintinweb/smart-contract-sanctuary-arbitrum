// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IGameCollector.sol";

contract SplitOrSteal {

    address collectorAddress;

    constructor (address gameCollectorAddress) {
        collectorAddress = gameCollectorAddress;
    }

    struct Game {
        uint256 id;
        uint256 player1Bet;
        uint256 player2Bet;
        uint256 prize;
        uint256 player1Choice;
        uint256 player2Choice;
        uint256 player1Prize;
        uint256 player2Prize;
        bool full;
        bool player1Chosen;
        bool player2Chosen;
        address player1;
        address player2;
        
    }

    mapping(uint256 => Game) public games;

    uint256 public gameCount = 1;

    function newGame() public {
        games[gameCount].id = gameCount;
        games[gameCount].full = false;
        games[gameCount].player1Chosen = false;
        games[gameCount].player2Chosen = false;

        gameCount++;
    }

    //Reentrancy guard
    function enterGame(uint256 gameID) payable public {

        //Making sure the game does not exist
        require(gameID <= gameCount, "GAME: Game does not exist");

        //Check they are not already in the game
        require(games[gameID].player1 != msg.sender, "PLAYER: Already exists");
        require(games[gameID].player2 != msg.sender, "PLAYER: Already exists");

        //Make sure the game has an open slot
        require(games[gameID].full == false, "GAME: Already full");

        require(msg.value > 0, "AMOUNT: Bet is not higher than zero");

        //Check whether they should be player 1 or 2
        if (games[gameID].player1 == address(0)) {
            games[gameID].player1 = msg.sender;
            games[gameID].player1Bet = msg.value;

            (bool playerSent, ) = collectorAddress.call{value: msg.value}("");
            require(playerSent, "RMS: ETH PAYMENT FAILED");


        }else{
            games[gameID].player2 = msg.sender;
            games[gameID].player2Bet = msg.value;
            games[gameID].full = true;

            (bool playerSent2, ) = collectorAddress.call{value: msg.value}("");
            require(playerSent2, "RMS: ETH PAYMENT FAILED");
            
            if(games[gameID].player1Bet < games[gameID].player2Bet){
                games[gameID].prize = games[gameID].player1Bet * 3;
                uint256 player2Refund = (games[gameID].player2Bet) - (games[gameID].player1Bet);
                IGameCollector(collectorAddress).payPrize(games[gameID].player2, player2Refund);

            }else if(games[gameID].player2Bet < games[gameID].player1Bet){
                games[gameID].prize = games[gameID].player2Bet * 3;
                uint256 player1Refund = (games[gameID].player1Bet) - (games[gameID].player2Bet);
                IGameCollector(collectorAddress).payPrize(games[gameID].player1, player1Refund);
            }else{
                games[gameID].prize = games[gameID].player1Bet * 3;
            }
        }
    }

    //Split = 0 ; Steal = 1
    function makeChoice(uint256 choice, uint256 gameID) public {

        require(gameID <= gameCount, "GAME: Game does not exist");
        require((choice == 0) || (choice == 1), "CHOICE: Choice does not exist");
        require((games[gameID].player1 == msg.sender) || (games[gameID].player2 == msg.sender), "PLAYER: Player does not exist");

        if(games[gameID].player1 == msg.sender){
            games[gameID].player1Choice = choice;
            games[gameID].player1Chosen = true;
        }else{
            games[gameID].player2Choice = choice;
            games[gameID].player2Chosen = true;
        }

    }

    //Split = 0 ; Steal = 1
    function calculateWinner(uint256 gameID) payable public {

        require((games[gameID].player1Chosen == true) && (games[gameID].player2Chosen == true), "GAME: Both players have not made their choices");

        uint256 player1Choice = games[gameID].player1Choice;
        uint256 player2Choice = games[gameID].player2Choice; 

        if(player1Choice == player2Choice){
            if(player1Choice == 0){

                games[gameID].player1Prize = games[gameID].prize / 2;
                games[gameID].player2Prize = games[gameID].prize / 2;

                IGameCollector(collectorAddress).payPrize(games[gameID].player1, games[gameID].player1Prize);
                IGameCollector(collectorAddress).payPrize(games[gameID].player2, games[gameID].player2Prize);
                
            }else{
                games[gameID].player1Prize = 0;
                games[gameID].player2Prize = 0;
            }
        }else{

            if(player1Choice == 1){
                games[gameID].player1Prize = games[gameID].prize;
                games[gameID].player2Prize = 0;
                IGameCollector(collectorAddress).payPrize(games[gameID].player1, games[gameID].player1Prize);


            }else{
                games[gameID].player2Prize = games[gameID].prize;
                games[gameID].player1Prize = 0;
                IGameCollector(collectorAddress).payPrize(games[gameID].player2, games[gameID].player2Prize);

            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IGameCollector {

    function payPrize(address player, uint256 totalPayment) external ;
}