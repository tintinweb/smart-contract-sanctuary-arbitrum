// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ITradeWarErrors.sol";
import "./ITradeWarEvents.sol";

/// @title Trade War Interface
interface ITradeWar is ITradeWarErrors, ITradeWarEvents {
    /*********/
    /* Enums */
    /*********/

    /// @notice Game Status
    enum GameStatus {
        NOT_CREATED,
        Created,
        Started,
        Cancelled,
        Ended
    }

    /***********/
    /* Structs */
    /***********/

    /// @notice Game data
    /// @param status Game status
    /// @param numTeams Number of teams
    /// @param wage Wager amount
    /// @param totalPlayers Total players joined the game
    /// @param winningTeam Winner team id
    /// @param feeCollected Collected fee amount
    struct Game {
        GameStatus status;
        address creator;
        uint256 numTeams;
        uint256 wage;
        uint256 totalPlayers;
        uint256 winningTeam;
        uint256 feeCollected;
    }

    /*******************/
    /* Admin Functions */
    /*******************/

    /// @notice Set new admin address
    /// @param _newAdmin New admin address
    function transferAdmin(address _newAdmin) external;

    /// @notice Accept admin
    function acceptAdmin() external;

    /// @notice Set new fee ratio
    /// @param _feeRatio New fee ratio
    function setFeeRatio(uint256 _feeRatio) external;

    /******************/
    /* Game Functions */
    /******************/

    /// @notice Create a new game
    /// @dev Anyone can create game
    /// @param _numTeams Number of teams
    function createGame(
        uint256 _numTeams
    ) external payable returns (uint256 gameId);

    /// @notice Join active game
    /// @dev Anyone can join the team
    /// @param _gameId Game Id
    /// @param _teamId Team Id
    function joinGame(uint256 _gameId, uint256 _teamId) external payable;

    /// @notice Leave joined game
    /// @dev Can exit before the game started
    /// @param _gameId Game Id
    function leaveGame(uint256 _gameId) external;

    /// @notice Start the game
    /// @dev Admin or game creator can call this function
    /// @param _gameId Game Id
    function startGame(uint256 _gameId) external;

    /// @notice Cancel the game
    /// @dev Only admin can call this function
    /// @param _gameId Game Id
    function cancelGame(uint256 _gameId) external;

    /// @notice End the game
    /// @dev Only admin can call this function
    /// @param _gameId Game Id
    /// @param _winningTeamId Winning team Id
    function endGame(uint256 _gameId, uint256 _winningTeamId) external;

    /// @notice Claim wage after the game is cancelled or ended
    /// @param _gameId Game Id
    function claim(uint256 _gameId) external;

    /******************/
    /* View Functions */
    /******************/

    /// @notice Get Game Info
    /// @param _gameId Game Id
    /// @return status Game status
    /// @return creator Game creator address
    /// @return wage Game wage amount
    /// @return teams Array of team players
    function getGameInfo(
        uint256 _gameId
    )
        external
        view
        returns (
            GameStatus status,
            address creator,
            uint256 wage,
            address[][] memory teams
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Trade War Interface
interface ITradeWarErrors {
    /**********/
    /* Errors */
    /**********/

    /// @notice Not Admin
    error NotAdmin();

    /// @notice Not Pending Admin
    error NotPendingAdmin();

    /// @notice Not Admin or Game Creator
    error NotAdminOrCreator();

    /// @notice Parameter out of bounds
    error ParameterOutOfBounds();

    /// @notice Zero Address
    error ZeroAddress();

    /// @notice Zero Amount
    error ZeroAmount();

    /// @notice Invalid Number of Teams
    error InvalidNumTeams();

    /// @notice Invalid Game Status
    error InvalidGameStatus();

    /// @notice Invalid Game
    error InvalidTeam();

    /// @notice Invalid Wage Amount
    error InvalidWageAmount();

    /// @notice Already Joined
    error AlreadyJoined();

    /// @notice Not Joined
    error NotJoined();

    /// @notice Ether Transfer Failed
    error EthTransferFailed();

    /// @notice Insufficient Active Teams
    error InsufficientActiveTeams();

    /// @notice Not Game Participant
    error NotGameParticipant();

    /// @notice Not Winner
    error NotWinner();

    /// @notice Already Claimed
    error AlreadyClaimed();

    /// @notice Game Not Exist
    error GameNotExist();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Trade War Interface - Events
interface ITradeWarEvents {
    /**********/
    /* Events */
    /**********/

    /// @notice Admin Changed
    /// @param oldAdmin Old admin address
    /// @param newAdmin New admin address
    event AdminChanged(address oldAdmin, address newAdmin);

    /// @notice Fee Ratio Updated
    /// @param oldFeeRatio Old fee ratio
    /// @param newFeeRatio New fee ratio
    event FeeRatioUpdated(uint256 oldFeeRatio, uint256 newFeeRatio);

    /// @notice Game Created
    /// @param gameId Game Id
    /// @param creator Game creator address
    /// @param numTeams Number of teams
    /// @param wage Wage amount
    event GameCreated(
        uint256 gameId,
        address creator,
        uint256 numTeams,
        uint256 wage
    );

    /// @notice Game Started
    /// @param gameId Game Id
    event GameStarted(uint256 gameId);

    /// @notice Game Cancelled
    /// @param gameId Game Id
    event GameCancelled(uint256 gameId);

    /// @notice Game Ended
    /// @param gameId Game Id
    /// @param winningTeam Winning Team Id
    event GameEnded(uint256 gameId, uint256 winningTeam);

    /// @notice Player Joined
    /// @param gameId Game Id
    /// @param teamId Team Id
    /// @param player Player address
    event PlayerJoined(uint256 gameId, uint256 teamId, address player);

    /// @notice Player Left
    /// @param gameId Game Id
    /// @param teamId Team Id
    /// @param player Player address
    event PlayerLeft(uint256 gameId, uint256 teamId, address player);

    /// @notice Player Claimed
    /// @param gameId Game Id
    /// @param player Player address
    /// @param amount Claimed amount
    event Claimed(uint256 gameId, address player, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interface/ITradeWar.sol";

/// @title Trade War
contract TradeWar is ITradeWar {
    /***********/
    /* Storage */
    /***********/

    /// @notice Admin address
    address public admin;

    /// @notice Pending admin address
    address public pendingAdmin;

    /// @notice Fee ratio
    uint256 public feeRatio;

    /// @notice Treasury address
    address public treasury;

    /// @dev Number of total games
    uint256 public totalGames;

    /// @notice Game Id => Game data
    mapping(uint256 => Game) public games;

    /// @notice Game Id => Team Id => Players
    mapping(uint256 => mapping(uint256 => address[])) private teamPlayers;

    /// @notice Game Id => Team Id => Player => Player Index
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private teamPlayersIndex;

    /// @notice Game Id => Player => Team Id
    mapping(uint256 => mapping(address => uint256)) private joinedTeam;

    /// @notice Game Id => Player => Claimed
    mapping(uint256 => mapping(address => bool)) private claimed;

    /*************/
    /* Constants */
    /*************/

    uint256 public constant FEE_DENOMINATOR = 10_000;

    /*************/
    /* Modifiers */
    /*************/

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
        _;
    }

    modifier onlyAdminOrCreator(uint256 _gameId) {
        if (msg.sender != admin && msg.sender != games[_gameId].creator) {
            revert NotAdminOrCreator();
        }
        _;
    }

    /***************/
    /* Constructor */
    /***************/

    /// @notice TradeWar Constructor
    /// @param _feeRatio Fee ratio
    /// @param _treasury Treasury address
    constructor(uint256 _feeRatio, address _treasury) {
        if (_feeRatio >= FEE_DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        if (_treasury == address(0)) {
            revert ZeroAddress();
        }
        admin = msg.sender;
        feeRatio = _feeRatio;
        treasury = _treasury;
    }

    /*******************/
    /* Admin Functions */
    /*******************/

    /// @notice See {ITradeWar-transferAdmin}
    function transferAdmin(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0)) {
            revert ZeroAddress();
        }

        pendingAdmin = _newAdmin;
    }

    /// @notice See {ITradeWar-acceptAdmin}
    function acceptAdmin() external {
        if (msg.sender != pendingAdmin) {
            revert NotPendingAdmin();
        }

        address oldAdmin = admin;
        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit AdminChanged(oldAdmin, admin);
    }

    /// @notice See {ITradeWar-setFeeRatio}
    function setFeeRatio(uint256 _feeRatio) external onlyAdmin {
        if (_feeRatio >= FEE_DENOMINATOR) {
            revert ParameterOutOfBounds();
        }
        uint256 oldFeeRatio = feeRatio;
        feeRatio = _feeRatio;
        emit FeeRatioUpdated(oldFeeRatio, _feeRatio);
    }

    /******************/
    /* Game Functions */
    /******************/

    /// @notice See {ITradeWar-createGame}
    function createGame(
        uint256 _numTeams
    ) external payable returns (uint256 gameId) {
        if (_numTeams < 2) {
            revert InvalidNumTeams();
        }
        if (msg.value == 0) {
            revert ZeroAmount();
        }

        gameId = totalGames++;
        Game storage game = games[gameId];

        game.status = GameStatus.Created;
        game.creator = msg.sender;
        game.numTeams = _numTeams;
        game.wage = msg.value;

        _addTeamPlayer(gameId, 1, msg.sender);

        emit GameCreated(gameId, msg.sender, _numTeams, msg.value);
    }

    /// @notice See {ITradeWar-joinGame}
    function joinGame(uint256 _gameId, uint256 _teamId) external payable {
        Game memory game = games[_gameId];

        if (game.status != GameStatus.Created) {
            revert InvalidGameStatus();
        }
        // 1 <= team id <= numTeams
        if (_teamId == 0 || game.numTeams < _teamId) {
            revert InvalidTeam();
        }
        if (game.wage != msg.value) {
            revert InvalidWageAmount();
        }

        _addTeamPlayer(_gameId, _teamId, msg.sender);
    }

    /// @notice See {ITradeWar-leaveGame}
    function leaveGame(uint256 _gameId) external {
        Game memory game = games[_gameId];

        if (game.status != GameStatus.Created) {
            revert InvalidGameStatus();
        }

        _removeTeamPlayer(_gameId, msg.sender);

        _transferEther(msg.sender, game.wage);
    }

    /// @notice See {ITradeWar-startGame}
    function startGame(uint256 _gameId) external onlyAdminOrCreator(_gameId) {
        Game storage game = games[_gameId];

        if (game.status != GameStatus.Created) {
            revert InvalidGameStatus();
        }

        uint256 activeTeams;
        uint256 numTeams = game.numTeams;
        for (uint256 i = 1; i <= numTeams; ++i) {
            if (teamPlayers[_gameId][i].length > 0) {
                ++activeTeams;
                if (activeTeams == 2) {
                    break;
                }
            }
        }
        if (activeTeams < 2) {
            revert InsufficientActiveTeams();
        }

        game.status = GameStatus.Started;

        emit GameStarted(_gameId);
    }

    /// @notice See {ITradeWar-cancelGame}
    function cancelGame(uint256 _gameId) external onlyAdmin {
        Game storage game = games[_gameId];

        if (
            game.status != GameStatus.Created &&
            game.status != GameStatus.Started
        ) {
            revert InvalidGameStatus();
        }

        game.status = GameStatus.Cancelled;

        emit GameCancelled(_gameId);
    }

    /// @notice See {ITradeWar-endGame}
    function endGame(
        uint256 _gameId,
        uint256 _winningTeamId
    ) external onlyAdmin {
        Game storage game = games[_gameId];

        if (game.status != GameStatus.Started) {
            revert InvalidGameStatus();
        }
        if (teamPlayers[_gameId][_winningTeamId].length == 0) {
            revert InvalidTeam();
        }

        game.status = GameStatus.Ended;
        game.winningTeam = _winningTeamId;

        uint256 feeCollected = (game.wage * game.totalPlayers * feeRatio) /
            FEE_DENOMINATOR;
        game.feeCollected = feeCollected;

        _transferEther(treasury, feeCollected);

        emit GameEnded(_gameId, _winningTeamId);
    }

    /// @notice See {ITradeWar-claim}
    function claim(uint256 _gameId) external {
        Game storage game = games[_gameId];

        if (
            game.status != GameStatus.Cancelled &&
            game.status != GameStatus.Ended
        ) {
            revert InvalidGameStatus();
        }

        uint256 teamId = joinedTeam[_gameId][msg.sender];
        if (teamId == 0) {
            revert NotGameParticipant();
        }

        if (game.status == GameStatus.Ended && teamId != game.winningTeam) {
            revert NotWinner();
        }

        if (claimed[_gameId][msg.sender]) {
            revert AlreadyClaimed();
        }
        claimed[_gameId][msg.sender] = true;

        uint256 totalWage = game.wage * game.totalPlayers - game.feeCollected;
        uint256 numPlayers = game.status == GameStatus.Ended
            ? teamPlayers[_gameId][teamId].length
            : game.totalPlayers;
        uint256 claimAmount = totalWage / numPlayers;

        // transfer dust amount to team's first player
        if (
            teamPlayersIndex[_gameId][teamId][msg.sender] == 0 &&
            totalWage > claimAmount * numPlayers
        ) {
            claimAmount += totalWage - claimAmount * numPlayers;
        }

        _transferEther(msg.sender, claimAmount);

        emit Claimed(_gameId, msg.sender, claimAmount);
    }

    /******************/
    /* View Functions */
    /******************/

    /// @notice See {ITradeWar-getGameInfo}
    function getGameInfo(
        uint256 _gameId
    )
        external
        view
        returns (
            GameStatus status,
            address creator,
            uint256 wage,
            address[][] memory teams
        )
    {
        Game memory game = games[_gameId];

        if (game.status == GameStatus.NOT_CREATED) {
            revert GameNotExist();
        }

        status = game.status;
        creator = game.creator;
        wage = game.wage;
        teams = new address[][](game.numTeams);
        for (uint256 i; i != game.numTeams; ++i) {
            teams[i] = teamPlayers[_gameId][i + 1];
        }
    }

    /**********************/
    /* Internal Functions */
    /**********************/

    /// @dev Add a new player to the team
    /// @param _gameId Game Id
    /// @param _teamId Team Id
    /// @param _player Player address
    function _addTeamPlayer(
        uint256 _gameId,
        uint256 _teamId,
        address _player
    ) internal {
        if (joinedTeam[_gameId][_player] > 0) {
            revert AlreadyJoined();
        }
        joinedTeam[_gameId][_player] = _teamId;

        uint256 playerIndex = teamPlayers[_gameId][_teamId].length;
        teamPlayers[_gameId][_teamId].push(_player);
        teamPlayersIndex[_gameId][_teamId][_player] = playerIndex;

        ++games[_gameId].totalPlayers;

        emit PlayerJoined(_gameId, _teamId, _player);
    }

    /// @dev Remove player from the game
    /// @param _gameId Game Id
    /// @param _player Player address
    function _removeTeamPlayer(uint256 _gameId, address _player) internal {
        uint256 teamId = joinedTeam[_gameId][_player];
        if (teamId == 0) {
            revert NotJoined();
        }
        joinedTeam[_gameId][_player] = 0;

        uint256 playerIndex = teamPlayersIndex[_gameId][teamId][_player];
        teamPlayersIndex[_gameId][teamId][_player] = 0;
        uint256 numTeamPlayers = teamPlayers[_gameId][teamId].length;
        if (playerIndex != numTeamPlayers - 1) {
            address lastPlayer = teamPlayers[_gameId][teamId][
                numTeamPlayers - 1
            ];
            teamPlayers[_gameId][teamId][playerIndex] = lastPlayer;
            teamPlayersIndex[_gameId][teamId][lastPlayer] = playerIndex;
        }
        teamPlayers[_gameId][teamId].pop();

        --games[_gameId].totalPlayers;

        emit PlayerLeft(_gameId, teamId, _player);
    }

    /// @dev Transfer ETH to user
    /// @param _to ETH recipient address
    /// @param _value transfer amount
    function _transferEther(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}("");
        if (!success) {
            revert EthTransferFailed();
        }
    }
}