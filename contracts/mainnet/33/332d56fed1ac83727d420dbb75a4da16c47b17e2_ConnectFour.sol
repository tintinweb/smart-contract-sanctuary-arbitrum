/**
 *Submitted for verification at Arbiscan on 2022-09-16
*/

// SPDX-License-Identifier: MIT
//
// When you read this, you were probably challenged.
// So, let's play connect-four!
// Check out the contract for details.

pragma solidity =0.8.0;


contract ConnectFour {

    mapping (bytes32 =>  Game) games; // Game IDs ==> Games
    mapping (address => uint256) nrOfGames; // User ==> Nr. of Games
    mapping(address => mapping(uint256 => Game)) myGames; // User ==> uint[0,1,..] ==> Game
    mapping(address => mapping(address => Game)) openGame; // User ==> Opponent ==> Game

    struct Game {
        bytes32 gameID; // unique id
        address player1; // P1
        address player2; // P2
        bool alt; // false if its player1's turn
        bool started; // true if P2 joined after being challenged
        bool ended; // true if game ended
        uint8 [7][5] board; // 7x5 board
        uint256 lastmove; // timestamp of last move
        uint256 pot; // pot to win
        address draw; // draw proposals
    }

    event GameCreation(address indexed p1, address indexed p2, bytes32 indexed game, uint256 pot);
    event GameJoin(address indexed p2, address indexed p1, bytes32 indexed game, uint256 pot); 
    event Move(address indexed p, bytes32 indexed game, uint8 move); 
    event GameEnd(address indexed winner, address indexed loser, bytes32 indexed game); 
    event DrawProposed(address indexed proposer, bytes32 indexed game);

    /// Check that only players of a specific board are registered
    modifier onlyGamers(bytes32 id) {
        require(games[id].player1 == msg.sender || 
            games[id].player2 == msg.sender, "No Game initiated");
        _;
    }

    /// Check if game has started and p2 has supplied his pot
    modifier startedGames(bytes32 id) {
        require(games[id].started == true, "Game not started");
        _;
    }
    
    /**
    * @notice Join game of host.
    * @param victim Address of person to challenge for a game.
    * @return gameID The Id of the game
    */
    function challangevictim(address victim) public payable returns(bytes32 gameID) {
        require(openGame[msg.sender][victim].gameID == bytes32(0), "Game already initiated");
        require(msg.value > 0, "Ensure to attach min 1 wei");

        gameID = keccak256(abi.encodePacked(msg.sender, victim, block.timestamp));
        Game memory game;
        game.gameID = gameID;
        game.player1 = msg.sender;
        game.player2 = victim;
        game.alt = true;
        game.pot = msg.value-1 wei;
        games[gameID] = game;

        (bool sent, ) = victim.call{value: 1 wei }("You were challenged!");
        require(sent, "Failed to send Ether");
        
        myGames[msg.sender][nrOfGames[msg.sender]] = game;
        openGame[msg.sender][victim] = game;
        nrOfGames[msg.sender] += 1;
        emit GameCreation(msg.sender, victim, gameID, msg.value-1 wei);
        return gameID;
    }
    
    /**
    * @notice Join game of host.
    * @param host Address of the challenger.
    * @return gameID The Id of the game
    */
    function joinGame(address host) public payable returns(bytes32 gameID) {
        require(openGame[host][msg.sender].gameID != bytes32(0), "Game not open");
        require(openGame[host][msg.sender].player2 == msg.sender, "Not invited");
        require(openGame[host][msg.sender].pot <= msg.value, "Must call the pot");

        gameID = openGame[host][msg.sender].gameID;
        games[gameID].started = true;
        games[gameID].pot += msg.value;
        myGames[msg.sender][nrOfGames[msg.sender]] = games[gameID];
        nrOfGames[msg.sender] += 1;

        (bool sent, ) = host.call{value: 1 wei }("Challenge accept");
        require(sent, "Failed to send Ether");

        emit GameJoin(msg.sender, host, gameID, msg.value);
        return gameID;
    }
    
    /**
    * @notice Retrieve board of game with specified ID.
    * @param gameID The ID of the game.
    * @return board Board and turn
    * @return turn False if it's the turn of p1
    */
    function getBoard(
        bytes32 gameID
    ) public view
    returns(
        uint8 [7][5] memory board, 
        string memory turn
    ) {
        if(games[gameID].alt == false){
            turn = "Player 1";
        } else {
            turn = "Player 2";
        }
        return (games[gameID].board, turn);
    }
    
    /**
    * @notice Retrieve game with specified ID.
    * @param gameID The ID of the game.
    * @return p1 Address of player 1.
    * @return p2 Address of player 2.
    * @return turn False if it's the turn of p1.
    * @return ended Bool indicating if the game ended.
    * @return pot Size of the pot.
    */
    function getGame(
        bytes32 gameID
    ) public view returns(
        address p1, address p2, bool turn, bool ended, uint256 pot
    ) {
    return (
        games[gameID].player1, 
        games[gameID].player2, 
        games[gameID].alt,  
        games[gameID].ended,
        games[gameID].pot
    );
    }

    /**
    * @notice Place Stone in one of 0-7 columns.
    * @param gameID The ID of the game.
    * @param move The column where to place the stone.
    */
    function takeMove(
        bytes32 gameID, 
        uint8 move
    ) public 
        onlyGamers(gameID) 
        startedGames(gameID) 
    {
        require(move < 8, "Only 7 columns");
        uint8 _player;
        Game storage game = games[gameID];
        if(game.player1 == msg.sender){
            require(game.alt == false, "Other player's turn");
            _player = 1;
            game.alt = true;
        } else {
            require(game.alt == true, "Other player's turn");
            _player = 2;
            game.alt = false;
        }
        uint8 rowcount = 0;
        
        while(game.board[rowcount][move]!=0){
            rowcount +=1;
        }
        game.board[rowcount][move]=_player;
        emit Move(msg.sender, gameID, move);
    }

    
    /**
    * @notice Propose draw for specific game.
    * @dev The draw process requires both users to call the function. When called
    *  a second time, the contract will pay back the pot to both players.
    * @param gameID The ID of the game.
    */
    function proposeDraw(bytes32 gameID) public onlyGamers(gameID) {
        require(games[gameID].ended == false, "Game already ended");
        if ((games[gameID].draw != address(0)) && 
                (games[gameID].draw != msg.sender)) 
        {
            games[gameID].ended = true;
            address p1 = games[gameID].player1;
            address p2 = games[gameID].player2;
            openGame[p1][p2].gameID = bytes32(0);
            (bool sent, ) = p1.call{
                value: games[gameID].pot/2
            }("draw");
            require(sent, "Failed to send Ether");
            (bool _sent, ) = p2.call{
                value: games[gameID].pot/2
            }("draw");
            require(_sent, "Failed to send Ether");
            games[gameID].pot = 0;
            emit GameEnd(address(0), address(0), gameID);
        }
        else {
            games[gameID].draw = msg.sender;
            emit DrawProposed(msg.sender, gameID);
        }
    }

    /**
    * @notice Exit one or both players from the game.
    * @dev Inactive player will loose some funds.
    * @param gameID The ID of the game.
    */
    function emergencyExit(bytes32 gameID) public onlyGamers(gameID) {
        if (!games[gameID].started) {
            (bool sent, ) = msg.sender.call{
                    value: games[gameID].pot
                }("draw");
                require(sent, "Failed to send Ether");
                return;
        }
        require(games[gameID].ended == false, "Game already ended");
        if (games[gameID].alt && games[gameID].player1 == msg.sender) 
        {
            if (games[gameID].lastmove + 864e2 * 2 < block.timestamp) {
                games[gameID].draw = games[gameID].player2;
                uint bonus = games[gameID].pot/10;
                games[gameID].pot -= bonus;
                (bool sent, ) = msg.sender.call{
                    value: bonus
                }("draw");
                require(sent, "Failed to send Ether");
                proposeDraw(gameID);
            }
        }

        if (!games[gameID].alt && games[gameID].player2 == msg.sender) 
        {
            if (games[gameID].lastmove + 864e2 * 2 < block.timestamp) {
                games[gameID].draw = games[gameID].player1;
                uint bonus = games[gameID].pot/10;
                games[gameID].pot -= bonus;
                (bool sent, ) = msg.sender.call{
                    value: bonus
                }("draw");
                require(sent, "Failed to send Ether");
                proposeDraw(gameID);
            }
        }
        
    }

    /**
    * @notice Claim win for specific game.
    * @dev The function checks if a player won and sends
    *  the pot to the winner.
    * @param gameID The ID of the game.
    * @return win Returns true if own.
    */
    function claimWin(bytes32 gameID) public onlyGamers(gameID) returns (bool win) {
        require(games[gameID].ended == false, "Game already ended");
        uint8 _player;
        address loser;
        Game storage g = games[gameID];
        if(g.player1 == msg.sender){
            _player = 1;
            loser = g.player2;
        } else {
            _player = 2;
            loser = g.player1;
        }
        // horizontal
        for (uint i=0; i<5; i++){
            for (uint j=0; j<4; j++)
            {
                if (
                    g.board[i][j]==_player
                    &&g.board[i][j+1]==_player
                    &&g.board[i][j+2]==_player
                    &&g.board[i][j+3]==_player
                ) {
                    g.ended = true;
                }
            }
        }
        // vertical
        for (uint i=0; i<7; i++){
            for (uint j=0; j<2; j++)
            {
                if (
                    g.board[j][i]==_player
                    &&g.board[j+1][i]==_player
                    &&g.board[j+2][i]==_player
                    &&g.board[j+3][i]==_player
                ) {
                    g.ended = true;
                }
            }
        }
        // ascending - diagonal
        for (uint i=0; i<2; i++){
            for (uint j=0; j<4; j++)
            {   if (
                    g.board[i][j]==_player
                    &&g.board[i+1][j+1]==_player
                    &&g.board[i+2][j+2]==_player
                    &&g.board[i+3][j+3]==_player) 
                {
                    g.ended = true;
                }
            }
        }
        // descending - diagonal
        for (uint i=0; i<2; i++){
            for (uint j=0; j<4; j++)
            {
                if (
                    g.board[i+3][j]==_player
                    &&g.board[i+2][j+1]==_player
                    &&g.board[i+1][j+2]==_player
                    &&g.board[i][j+3]==_player) 
                {
                    g.ended = true;
                }
            }
        }
        if(g.ended == true){
            openGame[g.player1][g.player2].gameID = bytes32(0);
            emit GameEnd(msg.sender, loser, gameID);
            (bool sent, ) = msg.sender.call{value: g.pot}("You won");
            require(sent, "Failed to send Ether");
            return true;
        }
        return false;
    }

    /**
    * @notice Take Move and directly claim win afterwards
    * @dev This prevents being front-runned.
    * @param gameID The ID of the game.
    * @param move The column where to place the stone.
    */
    function takeMoveandClaimWin(
        bytes32 gameID, 
        uint8 move
    ) public 
        onlyGamers(gameID) 
        startedGames(gameID) 
    {
        takeMove(gameID, move);
        claimWin(gameID);
    }
}