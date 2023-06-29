// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/*
ERROR LIST REFERENCE:
E1 - Contract is paused
E2 - Insufficient funds provided with transaction
E3 - Provided entry fee is lower than minimum entry fee
E4 - User is already part of this or different game
E5 - Game has already started or has been finished
E6 - Game room is full
E7 - User is already part of this game
E8 - Game has alraedy started
E9 - User is not part of this game
E10 - Game has not started yet
E11 - Game has already finished
E12 - Not users turn
E13 - Vehicle is in base
E14 - Vehicle is rooted
E15 - Vehicle would start another lap
E16 - skill used on an empty tile
E17 - Can't use this skill on own vehicle
E18 - Incorrect vehicle selected
E19 - Dice need to be rolled first
E20 - Not enough funds
E21 - Failed to send Ether
E22 - Need to roll 6 to leave base
E23 - Vehicle is already on the board
E24 - Vehicle has already finished the lap
E25 - This move would cause a collision with user's own vehicle
E26 - Dice has already been rolled
E27 - Blockhash is not available yet
E28 - This move would be a waste of turn
E29 - Can't hurry this player yet
E30 - Destroy is on cooldown
E31 - Root is on cooldown
E32 - Dash is on cooldown
E33 - Bonus is on cooldown
*/

/* INTERFACES */
interface IRhascauManager {
    function increaseUserRanking(uint256, address) external;
    function getPlayerAddress(address) external view returns (address);
    function updateUserStats(address, bool) external;
}

interface IARBsys {
    function arbBlockNumber() external view returns (uint);
    function arbBlockHash(uint256) external view returns (bytes32);
}

contract Rhascau is Ownable {

    IRhascauManager public rhascauManager;
    IARBsys public arbSys;

    /* CONSTANTS */
    uint256 constant REWARD_PER_ETH_WON = 4000;

    uint8 constant PIECE_PER_PLAYER = 4;
    uint8 constant MAX_PLAYERS = 4;
    uint8 constant TILE_COUNT = 40;
    uint256 constant MIN_ENTRY_FEE = 0.001 ether;

    uint8 constant DESTROY_COOLDOWN = 1;
    uint8 constant ROOT_COOLDOWN = 3;
    uint8 constant ROLLAGAIN_COOLDOWN = 4;
    uint8 constant DASH_COOLDOWN = 1;

    /* EVENTS */
    event GameStarted(uint256 _roomId);
    event RoomStateChanged(uint256 _roomId, uint8 _playersCount);
    event LapFinished(uint256 _roomId, uint8 _vehicleId);
    event VehicleLeftBase(uint256 _roomId, uint8 _vehicleId);
    event VehicleRooted(uint256 _roomId, uint8 _vehicleId);
    event VehicleDashed(uint256 _roomId, uint8 _vehicleId, uint8 _from, uint8 _to);
    event PlayerUsedBonus(uint256 _roomId, classEnum _class);
    event VehicleDestroyed(uint256 _roomId, uint8 _vehicleId, skillsEnum _skill);
    event VehicleMoved(uint256 _roomId, uint8 _vehicleId, uint8 _from, uint8 _to);
    event DiceRolled(classEnum _class, uint256 _roomId, uint8 _result);
    event VehicleUnrooted(uint256 _roomId, uint8 _vehicleId);
    event NewTurn(uint256 _roomId, classEnum _class); 
    event VehicleDashedAndDestroyed(uint256 _roomId, uint8 _vehicleId, uint8 _destroyedVehicleId, uint8 _from, uint8 _to);
    event VehicleMovedAndDestroyed(uint256 _roomId, uint8 _vehicleId, uint8 _from, uint8 _to, uint8 _destroyedVehicleId);
    event RapidMoves(uint256 _roomId);
    event EmojiSent(uint256 _roomId, classEnum _class, uint8 _type);
    event GameFinished(uint256 _roomId, classEnum _class, address _winner, uint256 _prize);

    constructor(address _rhascauManagerAddress, address _arbSysAddress) {
        rhascauManager = IRhascauManager(_rhascauManagerAddress);
        arbSys = IARBsys(_arbSysAddress);
    }

    /// @dev mapping handling the randomness of the dice roll (see rollDice)
    mapping (address => uint256) blockHashToBeUsed;
    /// @dev mapping handling first game of the day and first win of the day
    mapping (address => RewardsTimer) userToRewardTimer;
    mapping (address => bool) isUserInGame;

    //array of all game rooms
    GameRoom[] public games;
    
    bool public isContractPaused = false;
    uint256 public providerFee = 2;
    uint256 public turnTime = 50;
    address public protocolsFeeAddress = 0x56E380e2A76A35eb8f6caF8B03D085C786E0d436;

    enum classEnum {ONE, TWO, THREE, FOUR}
    enum skillsEnum {DESTROY, ROOT, ROLLAGAIN, DASH, NONE}

    struct GameInfo {
        uint8 playersCount;
        uint8 lastRoll;
        uint256 moveTimestamp;
        uint256 entryFee;
        bool hasStarted;
        bool hasEnded;        
    }

    struct SkillsCooldown {
        uint8 destroyCooldown;
        uint8 rootCooldown;
        uint8 rollAgainCooldown;
        uint8 dashCooldown;
    }

    struct Vehicle {
        uint8 id;
        bool isOnBoard;
        bool isRooted;
        bool isLapDone;
        bool isInitialized;
        classEnum class;
    }

    struct Tile {
        bool isOccupied;
        Vehicle vehicle; 
    }

    struct DiceRoll {
        uint8 diceResult;
        bool toBeUsed;
    }

    struct GameRoom {
        GameInfo info;
        Tile[TILE_COUNT] board;
        mapping(address => mapping(uint8 => Vehicle)) players;
        mapping(address => SkillsCooldown) cooldowns;
        mapping(address => DiceRoll) diceRolls;
        mapping(classEnum => address) classToPlayer;
        uint8 queue;
        uint8 killCount;
    }

    struct RewardsTimer {
        uint256 lastTimePlayed;
        uint256 lastTimeWon;
    }
    
    /* MODIFIERS */

    /// @dev Checks if the contract is paused
    modifier contractWorking() {
        require(isContractPaused == false, "E1");
        _;
    }

    /// @dev Checks if the user has enough funds to enter the game
    /// @param _fee amount provided by user
    modifier enoughFunds(uint256 _fee) {
        require(msg.value == _fee, "E2");
        if(_fee != 0) require(msg.value >= MIN_ENTRY_FEE, "E3");
        _;
    }

    /// @dev Checks if the user is eligable to join the game. User can not be part of another game at the moment of joining. Room must not be full. If game in the room has already started or finished, user can not join.
    /// @param _roomId id of the game room
    modifier joinableGame(uint256 _roomId) {
        require(isUserInGame[msg.sender] == false, "E4");
        require(games[_roomId].info.hasStarted == false && games[_roomId].info.hasEnded == false, "E5");
        require(games[_roomId].info.playersCount < 4, "E6");
        require(games[_roomId].players[msg.sender][getPlayerClass(_roomId, msg.sender) * PIECE_PER_PLAYER].isInitialized == false, "E7");
        _;
    }

    /// @dev Checks if the user can leave current game room. Possible only when the game has not started
    /// @param _roomId id of the game room
    modifier playerCanLeave(uint256 _roomId) {
        require(games[_roomId].info.hasStarted == false, "E8");
        require(isPlayerInGame(_roomId, msg.sender) == true, "E9");
        _;
    }

    /// @dev Checks if the user is in current game room. Game should have been started and not ended
    /// @param _roomId id of the game room
    modifier eligablePlayer(uint256 _roomId) {
        require(isPlayerInGame(_roomId, msg.sender) == true, "E9");
        require(games[_roomId].info.hasStarted == true, "E10");
        require(games[_roomId].info.hasEnded == false, "E11");
        _;
    }

    /// @dev Checks if its user turn to take an action.
    /// @param _roomId id of the game room
    modifier playersTurn(uint256 _roomId) {
        require(getPlayerClass(_roomId, msg.sender) == games[_roomId].queue, "E12");
        _;
    }

    /// @dev Checks wether user can take an action with the vehicle. Vehicle must be on board, not rooted, and can't cross the finish line with given _diceRoll.
    /// @param _roomId id of the game room
    /// @param _vehicleId id of the vehicle
    /// @param _diceRoll number of tiles to move
    modifier eligableVehicle(uint256 _roomId, uint8 _vehicleId, uint8 _diceRoll) {
        require(games[_roomId].players[msg.sender][_vehicleId].isOnBoard == true, "E13");
        require(games[_roomId].players[msg.sender][_vehicleId].isRooted == false, "E14");
        require(howManyTilesLeft(getPlayerClass(_roomId, msg.sender), getVehicleTileIndex(_roomId, _vehicleId, msg.sender)) >= _diceRoll, "E15");
        _;
    }
    
    /// @dev Checks if the user can use the skill. Skill can not be on cooldown, and must be casted on valid target. Check official rhascau rules at https://www.rhascau.com/
    /// @param _roomId id of the game room
    /// @param _skill skill to be used
    /// @param _targetTile tile on which the skill will be casted
    modifier skillAvailable(uint256 _roomId, skillsEnum _skill, uint8 _targetTile) {
        require(games[_roomId].board[_targetTile].isOccupied == true, "E16");
        if(_skill == skillsEnum.DESTROY) {
            require(games[_roomId].cooldowns[msg.sender].destroyCooldown == 0, "E30");
            require(games[_roomId].board[_targetTile].vehicle.class != games[_roomId].players[msg.sender][getPlayerClass(_roomId, msg.sender) * PIECE_PER_PLAYER].class, "E17");
        }
        else if(_skill == skillsEnum.ROOT) {
            require(games[_roomId].cooldowns[msg.sender].rootCooldown == 0, "E31");
            require(games[_roomId].board[_targetTile].vehicle.class != games[_roomId].players[msg.sender][getPlayerClass(_roomId, msg.sender) * PIECE_PER_PLAYER].class, "E17");
        }
        else {
            require(games[_roomId].cooldowns[msg.sender].dashCooldown == 0, "E32");
            require(games[_roomId].board[_targetTile].vehicle.class == games[_roomId].players[msg.sender][getPlayerClass(_roomId, msg.sender) * PIECE_PER_PLAYER].class, "E18");
            require(!games[_roomId].players[games[_roomId].classToPlayer[games[_roomId].board[_targetTile].vehicle.class]][games[_roomId].board[_targetTile].vehicle.id].isRooted, "E14");
        }
        _;
    }

    /// @dev Checks if the game is already started.
    /// @param _roomId id of the game room
    modifier gameStarted(uint256 _roomId) {
        require(games[_roomId].info.hasStarted == true, "E10");
        _;
    }

    /// @dev Ensures that dice has been rolled by player before taking an action.
    /// @param _roomId id of the game room
    modifier diceRolled(uint256 _roomId) {
        require(games[_roomId].diceRolls[msg.sender].toBeUsed == true, "E19");
        _;
    }

    /* SETTERS FOR OWNER */

    /// @dev Sets the address of the rhascau manager contract
    /// @param _rhascauManagerAddress address of the rhascau manager contract 
    function setRhascauManager(address _rhascauManagerAddress) external onlyOwner {
        rhascauManager = IRhascauManager(_rhascauManagerAddress);
    }
    
    /// @dev Swiches the state of contrat (paused or not)
    function switchContract() external onlyOwner {
        isContractPaused = !isContractPaused;
    }

    /// @dev Sets the fee collected by the protocol (in %)
    /// @param _providerFee fee collected by the protocol
    function setProviderFee(uint256 _providerFee) external onlyOwner {
        providerFee = _providerFee;
    }
    
    /// @dev Sets the time user has to take an action before other players can skip his turn.
    /// @param _turnTime time in blocks
    function setTurnTime(uint256 _turnTime) external onlyOwner {
        turnTime = _turnTime;
    }

    /// @dev Sets the address of the protocols fee collector
    /// @param _protocolsFeeAddress address of the protocols fee collector
    function setProtocolsFeeAddress(address _protocolsFeeAddress) external onlyOwner {
        protocolsFeeAddress = _protocolsFeeAddress;
    }

    /* SUPPORTING FUNCTIONS */

    /// @dev Removes vehicle form the board
    /// @param _roomId id of the game room
    /// @param _tileIndex id of the tile from which the vehicle will be removed
    function removeVehicleFromTile(uint256 _roomId, uint8 _tileIndex) internal {
        games[_roomId].players[games[_roomId].classToPlayer[games[_roomId].board[_tileIndex].vehicle.class]][games[_roomId].board[_tileIndex].vehicle.id].isOnBoard = false;
    }

    /// @dev Checks wether user plays via burner wallet or directly with his address (via smart contract). Neccessary for correct funds transfer and ranking system.
    /// @param _user address that plays the game
    /// @return address correct address of the user
    function getCorrectAddress(address _user) internal view returns (address) {
        if(rhascauManager.getPlayerAddress(_user) != address(0)) return rhascauManager.getPlayerAddress(_user);
        else return _user;
    }
    
    /// @dev Checks for missing player's id in the game room.
    /// @param _roomId id of the game room
    /// @return uint8 index of the missing player
    function getMissingPlayerIndex(uint256 _roomId) internal view returns (uint8) {
        for(uint i=0; i<MAX_PLAYERS; i++) {

if(games[_roomId].classToPlayer[classEnum(i)] == address(0)) return uint8(i);
        }
    }

    /// @dev Updates user statistics after the game has ended (games played, games won).
    /// @param _roomId id of the game room
    /// @param _winner address of the winner
    function updateStatistics(uint256 _roomId, address _winner) internal {
        uint8 winnerClass = getPlayerClass(_roomId, _winner);
        for(uint i=0; i<MAX_PLAYERS; i++)
        {
            address user = getCorrectAddress(games[_roomId].classToPlayer[classEnum(i)]);
            if(i == winnerClass) {
                rhascauManager.updateUserStats(user, true);
            }
            else {
                rhascauManager.updateUserStats(user, false);
            }
        }
    }

    /// @dev Helper function to increase user ranking appropriatly (see: getCorrectAddress).
    /// @param _burner address of the user/burner
    /// @param _amount amount of ranking points to be added
    function increaseRankingInternal(address _burner, uint256 _amount) internal {
        rhascauManager.increaseUserRanking(_amount, getCorrectAddress(_burner));
    }
    
    /// @dev Assigns game participation points to all players in the game room, taking into account first game/win of the day.
    /// @param _roomId id of the game room
    function assignGameParticipationPoints(uint256 _roomId) internal 
    {
        for(uint i=0; i<MAX_PLAYERS; i++)
        {

address user = games[_roomId].classToPlayer[classEnum(i)];
            if(block.timestamp - userToRewardTimer[user].lastTimePlayed >= 1 days)
            {
                increaseRankingInternal(user, 100);
            }
            else increaseRankingInternal(user, 50);
            isUserInGame[user] = false;
            userToRewardTimer[user].lastTimePlayed = block.timestamp;
        }
    }

    /// @dev Checks if the player is in the game room.
    /// @param _roomId id of the game room
    /// @param _player address of the player
    /// @return bool true if player is in the game room, otherwise false
    function isPlayerInGame(uint256 _roomId, address _player) internal view returns (bool) {
        return games[_roomId].players[_player][getPlayerClass(_roomId, _player) * PIECE_PER_PLAYER].isInitialized;
    }
    
    /// @dev Returns player class (see: classEnum)
    /// @param _roomId id of the game room
    /// @param _player address of the player
    /// @return uint8 player class
    function getPlayerClass(uint256 _roomId, address _player) public view returns (uint8) {
        if(games[_roomId].players[_player][0].isInitialized == true) return 0;
        else if(games[_roomId].players[_player][4].isInitialized == true) return 1;
        else if(games[_roomId].players[_player][8].isInitialized == true) return 2;
        else return 3;
    }

    /// @dev Returns player's starting tile index.
    /// @param _playerClass player class (see: classEnum)
    /// @return uint8 starting tile index
    function getPlayerStartingPoint(uint8 _playerClass) internal pure returns (uint8) {
        if(_playerClass == 0) return 39;
        else if(_playerClass == 1) return 9;
        else if(_playerClass == 2) return 19;
        else return 29;
    }

    /// @dev Returns how many tiles are left to the finish line from _tileIndex, with respect to _playerClass.
    /// @param _playerClass player class (see: classEnum)
    /// @param _tileIndex id of the tile
    /// @return uint8 number of tiles left
    function howManyTilesLeft(uint8 _playerClass, uint8 _tileIndex) internal pure returns (uint8) {
        int8 startingPoint = int8(getPlayerStartingPoint(_playerClass));
        int8 tileIndex = int8(_tileIndex);
        if(tileIndex == startingPoint) return 40;
        return uint8((40 - (tileIndex - startingPoint)) % 40);
    }

    /// @dev Checks if the player is about to finish the game with current _diceRoll.
    /// @param _roomId id of the game room
    /// @param _vehicleId id of the vehicle
    /// @param _diceRoll number of tiles player can move 
    /// @param _player address of the player
    /// @return bool true if player is about to finish the game, otherwise false
    function isAboutToFinish(uint256 _roomId, uint8 _vehicleId, uint8 _diceRoll, address _player) internal view returns (bool) {
        return howManyTilesLeft(getPlayerClass(_roomId, _player), getVehicleTileIndex(_roomId, _vehicleId, _player)) == _diceRoll;
    }

    /// @dev Sends reward to the winner and protocol fee to the protocol fee collector address.
    /// @param _winner address of the winner
    /// @param _prize reward for the winner
    /// @param _protocolFee protocol fee
    function sendReward(address _winner, uint256 _prize, uint256 _protocolFee) private {
        require(_prize <= address(this).balance, "E20");
        (bool sent,) = _winner.call{value: _prize}("");
        require(sent, "E21");
        require(_protocolFee <= address(this).balance, "E20");
        (bool sent2,) = protocolsFeeAddress.call{value: _protocolFee}("");
        require(sent2, "E21");
    }
    
    /// @dev Calculates the rewards and protocol fees, assigns ranking points depending on the game outcome. Check official rhascau point assignment rules at https://www.rhascau.com/
    /// @param _roomId id of the game room
    /// @param _player address of the winner
    /// @param _enemyInteraction true if the winner has interacted with the enemy in his game-finishing move, otherwise false
    function assignWinner(uint256 _roomId, address _player, bool _enemyInteraction) internal {
        games[_roomId].info.hasEnded = true;
        uint256 reward = 4 * games[_roomId].info.entryFee - 4 * games[_roomId].info.entryFee / 100 * providerFee;
        uint256 pointsReward = ((4 * games[_roomId].info.entryFee * 4000)/1e18);
        uint256 protocolsFee = 4 * games[_roomId].info.entryFee - reward; 
        if(games[_roomId].info.entryFee != 0)
        {
            sendReward(getCorrectAddress(_player), reward, protocolsFee);
        }
        if(block.timestamp - userToRewardTimer[_player].lastTimeWon >= 1 days) 
        {
            userToRewardTimer[_player].lastTimeWon = block.timestamp;
            if(_enemyInteraction) increaseRankingInternal(_player, 220 + pointsReward);
            else increaseRankingInternal(_player, 200 + pointsReward);
        }
        else 
        {
            if(_enemyInteraction) increaseRankingInternal(_player, 170 + pointsReward);
            else increaseRankingInternal(_player, 150 + pointsReward);
        }
        assignGameParticipationPoints(_roomId);
        updateStatistics(_roomId, _player);
        emit GameFinished(_roomId, classEnum(getPlayerClass(_roomId, _player)), getCorrectAddress(_player), reward);
    }

    /// @dev Finds the tile index on which given vehicle is currently located.
    /// @param _roomId id of the game room
    /// @param _vehicleId id of the vehicle
    /// @param _player address of the player
    /// @return uint8 tile index
    function getVehicleTileIndex(uint256 _roomId, uint8 _vehicleId, address _player) internal view returns (uint8) {
        for(uint i=0; i<TILE_COUNT; i++) {
            if(games[_roomId].board[i].vehicle.id == games[_roomId].players[_player][_vehicleId].id && games[_roomId].board[i].isOccupied) {
                    return uint8(i);
                } 
        }
        return 99;
    }

    /// @dev Removes the root efect from the vehicle and updates the cooldowns.
    /// @param _roomId id of the game room
    /// @param _player address of the player
    function checkRootAndCooldowns(uint256 _roomId, address _player) internal {
        uint8 playerClass = getPlayerClass(_roomId, _player);
        GameRoom storage game = games[_roomId];
        for(uint8 i=playerClass * PIECE_PER_PLAYER; i < playerClass * PIECE_PER_PLAYER + PIECE_PER_PLAYER; i++) {
            if(game.players[_player][i].isRooted) {
                game.players[_player][i].isRooted = false;
                emit VehicleUnrooted(_roomId, i);
            }
        }
        if(game.cooldowns[_player].rootCooldown > 0) game.cooldowns[_player].rootCooldown--;
        if(game.cooldowns[_player].rollAgainCooldown > 0) game.cooldowns[_player].rollAgainCooldown--;
        if(game.cooldowns[_player].dashCooldown > 0) game.cooldowns[_player].dashCooldown--;
    }

    /// @dev Updates the queue (turn order), sets the turn timestamp for the next player, updates roots and cooldowns (see checkRootAndCooldowns).
    /// @param _roomId id of the game room
    function updateQueue(uint256 _roomId) internal {
        address currentPlayer = games[_roomId].classToPlayer[classEnum(games[_roomId].queue)];
        games[_roomId].diceRolls[currentPlayer].toBeUsed = false;
        blockHashToBeUsed[currentPlayer] = 0;
        games[_roomId].queue = (games[_roomId].queue + 1) % 4;
        games[_roomId].info.moveTimestamp = arbSys.arbBlockNumber();
        //root handling
        checkRootAndCooldowns(_roomId, msg.sender);
        emit NewTurn(_roomId, classEnum(games[_roomId].queue)); 
    }
    
    /// @dev Checks if player has any possible moves. Mammoth function that checks all conditions being: 
    /// a) is vehicle on board and not rooted 
    /// b) can player take new vehicle from the base
    /// c) will given move result in a collision with his own vehicle (which is prohibited)
    /// @param _roomId id of the game room
    /// @param _player address of the player
    /// @param _diceRoll number of tiles to move
    /// @return bool true if player can move, otherwise false
    function canPlayerMove(uint256 _roomId, address _player, uint8 _diceRoll) public view returns (bool)
    {
        uint8[4] memory potentialShips;
        uint8 counter = 0;
        uint8 playerClass = getPlayerClass(_roomId, _player);
        uint8 startingPoint = getPlayerStartingPoint(playerClass);
        GameRoom storage game = games[_roomId];
        for(uint8 i=playerClass * PIECE_PER_PLAYER; i< playerClass * PIECE_PER_PLAYER + PIECE_PER_PLAYER; i++)
        {
            if((game.players[_player][i].isOnBoard == true && !game.players[_player][i].isRooted) || (game.players[_player][i].isLapDone == false && game.players[_player][i].isOnBoard == false))
            {
                potentialShips[counter] = i;
                counter++;
            }
        }
        if(
            ((game.killCount < 2 && (_diceRoll == 6 || _diceRoll == 1))) 
            || 
            ((game.killCount >= 2 && (_diceRoll == 12 || _diceRoll == 2)))
            ) 
        {
            for(uint i=0; i<counter; i++)
            {
                if(game.players[_player][potentialShips[i]].isOnBoard == false &&
                (

         game.board[startingPoint].isOccupied == false || 
                    game.board[startingPoint].isOccupied && game.board[startingPoint].vehicle.class != classEnum(playerClass)
                )
                ) return true;
            }
        }
        for(uint i=0; i<TILE_COUNT; i++)
        {
            if(game.board[i].isOccupied) 
            {
                for(uint j=0; j<counter; j++)
                {

     if(game.board[i].vehicle.id == potentialShips[j] && game.players[_player][potentialShips[j]].isOnBoard == true)
                    {
                        if((game.board[(i + _diceRoll) % 40].isOccupied == false || game.board[(i + _diceRoll) % 40].isOccupied && game.board[(i + _diceRoll) % 40].vehicle.class != classEnum(playerClass)) && howManyTilesLeft(getPlayerClass(_roomId, _player), getVehicleTileIndex(_roomId, potentialShips[j], _player)) >= _diceRoll) return true;
                        else if (isAboutToFinish(_roomId, potentialShips[j], _diceRoll, _player) && (game.board[startingPoint].isOccupied == false || (game.board[startingPoint].isOccupied && game.board[startingPoint].vehicle.class != classEnum(playerClass)))) return true;
                    }
                }
            }
        }
        return false;
    }

    /// @dev Allows to put another ship on board if _diceRoll is 6 or 1 (in case of rapid moves active, 12 or 2), 
    /// and if there is no other friendly ship on the field where ships are deployed (see: getPlayerStartingPoint). 
    /// Updates the queue unless the _diceRoll is 6 or 12 (in case of rapid moves active), which gives user additional move. 
    /// @param _roomId id of the game room
    /// @param _vehicleId id of the vehicle
    /// @param _diceRoll dice roll
    function leaveBase(uint256 _roomId, uint8 _vehicleId, uint8 _diceRoll) internal 
    {
        GameRoom storage room = games[_roomId];
        bool rapidActive = room.killCount >= 2;
        if(rapidActive) require(_diceRoll == 12 || _diceRoll == 2, "E22");
        else require(_diceRoll == 6 || _diceRoll == 1, "E22");
        require(room.players[msg.sender][_vehicleId].isOnBoard == false, "E23");
        require(room.players[msg.sender][_vehicleId].isLapDone == false, "E24");
        
        uint8 playerClass = getPlayerClass(_roomId, msg.sender);
        uint8 startingPoint = getPlayerStartingPoint(playerClass);

        if(room.board[startingPoint].isOccupied == true)
        {
            if(uint8(room.board[startingPoint].vehicle.class) == playerClass) revert("E25");
            removeVehicleFromTile(_roomId, startingPoint);
            increaseRankingInternal(msg.sender, 20);
            emit VehicleDestroyed(_roomId, room.board[startingPoint].vehicle.id, skillsEnum(4));
        }
        room.players[msg.sender][_vehicleId].isOnBoard = true;
        room.board[startingPoint].vehicle = games[_roomId].players[msg.sender][_vehicleId];
        room.board[startingPoint].isOccupied = true;
        room.diceRolls[msg.sender].toBeUsed = false;
        if(!rapidActive && _diceRoll == 1 || rapidActive && _diceRoll == 2) updateQueue(_roomId);

        emit VehicleLeftBase(_roomId, _vehicleId);
    }

    /// @dev Allows to use skill on the target tile, if the skill is available. DESTROY and ROOT can be used only on the tiles with enemy vehicles. DASH can be used on friendly vehicle, unless this would cause a collision with friendly vehicle, or crossing the finish line. 
    /// @param _roomId id of the game room
    /// @param _skill skill to use
    /// @param _targetTile id of target tile
    function useSkill(uint256 _roomId, skillsEnum _skill, uint8 _targetTile) internal 
    skillAvailable(_roomId,_skill,_targetTile)
    {
        GameRoom storage room = games[_roomId];
        Tile storage targetTile = room.board[_targetTile];
        if(_skill == skillsEnum.DESTROY)
        {
            targetTile.isOccupied = false;
            removeVehicleFromTile(_roomId, _targetTile);
            room.cooldowns[msg.sender].destroyCooldown = DESTROY_COOLDOWN;
            room.killCount++;
            if(room.killCount == 2) emit RapidMoves(_roomId);
            increaseRankingInternal(msg.sender, 20);
            emit VehicleDestroyed(_roomId, targetTile.vehicle.id, skillsEnum.DESTROY);
        }
        else if(_skill == skillsEnum.ROOT) 
        {
            games[_roomId].players[games[_roomId].classToPlayer[games[_roomId].board[_targetTile].vehicle.class]][games[_roomId].board[_targetTile].vehicle.id].isRooted = true;

  room.cooldowns[msg.sender].rootCooldown = ROOT_COOLDOWN;
            emit VehicleRooted(_roomId, targetTile.vehicle.id);
        }
        else //dash
        {
            
            room.cooldowns[msg.sender].dashCooldown = DASH_COOLDOWN;
            if(room.board[(_targetTile + 1) % 40].isOccupied == true)
            {
                emit VehicleDashedAndDestroyed(_roomId, targetTile.vehicle.id, room.board[(_targetTile + 1) % 40].vehicle.id, _targetTile, (_targetTile + 1) % 40);
                require(uint8(room.board[(_targetTile + 1) % 40].vehicle.class) != getPlayerClass(_roomId, msg.sender),"E25");
                removeVehicleFromTile(_roomId, (_targetTile + 1) % 40);
                if(isAboutToFinish(_roomId, games[_roomId].board[_targetTile].vehicle.id, 1, msg.sender))
                {
                    games[_roomId].players[msg.sender][games[_roomId].board[_targetTile].vehicle.id].isOnBoard = false;
                    games[_roomId].players[msg.sender][games[_roomId].board[_targetTile].vehicle.id].isLapDone = true;
                    room.board[(_targetTile + 1) % 40].isOccupied == false;

    emit LapFinished(_roomId, targetTile.vehicle.id);
                    assignWinner(_roomId, msg.sender, true);
                }
                else 
                {
                    room.board[(_targetTile + 1) % 40].vehicle = targetTile.vehicle;
                    increaseRankingInternal(msg.sender, 20); 
                }            
            }   
            else 
            {   
                emit VehicleDashed(_roomId, games[_roomId].board[_targetTile].vehicle.id, _targetTile, (_targetTile + 1) % 40);
                if(isAboutToFinish(_roomId, games[_roomId].board[_targetTile].vehicle.id, 1, msg.sender))
                {
                    games[_roomId].players[msg.sender][games[_roomId].board[_targetTile].vehicle.id].isOnBoard = false;
                    games[_roomId].players[msg.sender][games[_roomId].board[_targetTile].vehicle.id].isLapDone = true;

 room.board[(_targetTile + 1) % 40].isOccupied == false;
                    emit LapFinished(_roomId, targetTile.vehicle.id);
                    assignWinner(_roomId, msg.sender, false);
                }
                else 
                {
                    room.board[(_targetTile + 1) % 40].vehicle = targetTile.vehicle;
                    room.board[(_targetTile + 1) % 40].isOccupied = true;
                }
            }

targetTile.isOccupied = false;
        }
    }

    /// @dev Allows to move vehicle, optionally with skill casted on _targetTile (see: useSkill). Manages ROLLAGAIN skill, turn times, turn repetition, collisions, board state.
    /// @param _roomId id of the game room
    /// @param _vehicleId id of the vehicle to move
    /// @param _diceRoll number of tiles to move
    /// @param _skill skill to use (otherwise skillsEnum.NONE)
    /// @param _targetTile id of tile skill is casted on (if _skill == skillsEnum.NONE, then _targetTile can be set to any value)
    function moveVehicle(uint256 _roomId, uint8 _vehicleId, uint8 _diceRoll, skillsEnum _skill, uint8 _targetTile) internal
    eligableVehicle(_roomId, _vehicleId, _diceRoll)
    {

        GameRoom storage room = games[_roomId];
        bool rapidActive = room.killCount >= 2;
        uint8 currentTileIndex = getVehicleTileIndex(_roomId, _vehicleId, msg.sender);
        uint8 newTileIndex = (currentTileIndex + _diceRoll) % 40;
        uint8 playerClass = getPlayerClass(_roomId, msg.sender);
        Tile storage currentTile = room.board[currentTileIndex];
        Tile storage newTile = room.board[newTileIndex];
        bool repeat = false;
        if(_skill != skillsEnum.NONE)
        {
            if(_skill == skillsEnum.ROLLAGAIN)
            {
                require(room.cooldowns[msg.sender].rollAgainCooldown == 0, "E33");
                repeat = true;
                room.cooldowns[msg.sender].rollAgainCooldown = ROLLAGAIN_COOLDOWN;
            }
            else useSkill(_roomId, _skill, _targetTile);
        }
        if(_skill == skillsEnum.DASH && _targetTile == currentTileIndex) {
            if(newTileIndex == getPlayerStartingPoint(playerClass)) revert("E15");
            currentTileIndex = (currentTileIndex + 1) % 40;
            newTileIndex = (newTileIndex + 1) % 40;
            currentTile = room.board[currentTileIndex];
            newTile = room.board[newTileIndex];
            require(newTile.vehicle.class != classEnum(playerClass) || newTile.isOccupied != true, "E25");
        }
        if(((!rapidActive && _diceRoll == 6 ) || (rapidActive && _diceRoll == 12)) && repeat == false) {
            games[_roomId].info.moveTimestamp = arbSys.arbBlockNumber();
            repeat = true;
        }
        if(newTile.isOccupied == true)
        {   
            require(newTile.vehicle.class != classEnum(playerClass), "E25");
            removeVehicleFromTile(_roomId, newTileIndex);
            if(isAboutToFinish(_roomId, _vehicleId, _diceRoll, msg.sender)) 
            {
                room.players[msg.sender][_vehicleId].isOnBoard = false;
                room.players[msg.sender][_vehicleId].isLapDone = true;
                newTile.isOccupied = false;
                emit VehicleMovedAndDestroyed(_roomId, currentTile.vehicle.id, currentTileIndex, newTileIndex, newTile.vehicle.id);
                emit LapFinished(_roomId, _vehicleId);
                assignWinner(_roomId, msg.sender, true);
            }
            else //enemy destroyed reward
            {
                emit VehicleMovedAndDestroyed(_roomId, currentTile.vehicle.id, currentTileIndex, newTileIndex, newTile.vehicle.id);
                newTile.vehicle = room.players[msg.sender][_vehicleId];
                increaseRankingInternal(msg.sender, 20); //kill
            }
        }
        else
        {
            if(isAboutToFinish(_roomId, _vehicleId, _diceRoll, msg.sender)) 
            {
                room.players[msg.sender][_vehicleId].isOnBoard = false;
                room.players[msg.sender][_vehicleId].isLapDone = true;
                emit VehicleMoved(_roomId, currentTile.vehicle.id, currentTileIndex, newTileIndex);
                emit LapFinished(_roomId, _vehicleId);
                assignWinner(_roomId, msg.sender, false);

   }
            else 
            {
                newTile.isOccupied = true;
                newTile.vehicle = room.players[msg.sender][_vehicleId];
                emit VehicleMoved(_roomId, currentTile.vehicle.id, currentTileIndex, newTileIndex);
            }
        }
        currentTile.isOccupied = false;
        if(_skill == skillsEnum.ROLLAGAIN) 
        {
            emit PlayerUsedBonus(_roomId, classEnum(playerClass));
            games[_roomId].diceRolls[msg.sender].diceResult = 0;
            games[_roomId].info.moveTimestamp = arbSys.arbBlockNumber() + turnTime;
        }
        if(repeat == false)
        {
            updateQueue(_roomId);
        }
        else 
        {
            room.diceRolls[msg.sender].toBeUsed = false;
        }
    }

    /* EXTERNAL FUNCTIONS */

    /// @dev Sends the emoji.
    /// @param _roomId id of the game room
    /// @param _type type of the emoji
    function sendEmoji(uint256 _roomId, uint8 _type) external {
        require(isPlayerInGame(_roomId, msg.sender), "E9");
        classEnum class = classEnum(getPlayerClass(_roomId, msg.sender));
        emit EmojiSent(_roomId, class, _type);
    } 

    
    /// @dev Creates new game room with given stake (_entryFee), puts players ships on board, sets cooldowns, entry fees, isUserInGame mapping.
    /// @param _entryFee entry fee for the game
    function initiateGame(uint256 _entryFee) external payable 
    enoughFunds(_entryFee) contractWorking()
    {
        require(isUserInGame[msg.sender] == false, "E4");
        GameRoom storage room = games.push();
        room.info.playersCount = 1;
        room.info.entryFee = _entryFee;
        uint8 startingPoint = getPlayerStartingPoint(0);
        for(uint8 i = 0; i<PIECE_PER_PLAYER; i++)
        {
            if(i == 0) 
            {
                room.players[msg.sender][0] = Vehicle(0,true,false,false,true,classEnum(0));
                room.board[startingPoint].isOccupied = true;
                room.board[startingPoint].vehicle = room.players[msg.sender][0];
            }
            else if(i == 1) 
            {
                room.players[msg.sender][1] = Vehicle(1,true,false,false,true,classEnum(0));
                room.board[(startingPoint + 1) % 40].isOccupied = true;
                room.board[(startingPoint + 1) % 40].vehicle = room.players[msg.sender][1];
            }
            else 
            room.players[msg.sender][i] = Vehicle(i,false,false,false,true,classEnum(0));
        }
        room.cooldowns[msg.sender] = SkillsCooldown(0,0,0,0);
        room.classToPlayer[classEnum(0)] = msg.sender;
        room.cooldowns[msg.sender].rootCooldown = 1;
        isUserInGame[msg.sender] = true;
        emit RoomStateChanged(games.length - 1, 1);
    }
    
    /// @dev Joins the game with given id (_roomId), puts players ships on board, sets cooldowns, isUserInGame mapping, updates room statistics, and in case of last player, sets turn time.
    /// @param _roomId id of the game room
    /// @return counter id of the player in room
    function joinGame(uint256 _roomId) external payable 
    joinableGame(_roomId) 
    returns (uint256) 
    {
        GameRoom storage room = games[_roomId];
        require(msg.value == room.info.entryFee, "E2");
        uint8 counter = getMissingPlayerIndex(_roomId);
        uint8 startingPoint = getPlayerStartingPoint(counter);
        for(uint8 i=counter * PIECE_PER_PLAYER; i<counter * PIECE_PER_PLAYER + PIECE_PER_PLAYER; i++)
        {
            if(i == counter * PIECE_PER_PLAYER) 
            {

    room.players[msg.sender][i] = Vehicle(i,true,false,false,true,classEnum(counter));
                room.board[startingPoint].isOccupied = true;
                room.board[startingPoint].vehicle = room.players[msg.sender][i];
            }
            else if(i == counter * PIECE_PER_PLAYER + 1)
            {
                room.players[msg.sender][i] = Vehicle(i,true,false,false,true,classEnum(counter));
                room.board[(startingPoint + 1) % 40].isOccupied = true;
                room.board[(startingPoint + 1) % 40].vehicle = room.players[msg.sender][i];
            }
            else 
            room.players[msg.sender][i] = Vehicle(i,false,false,false,true,classEnum(counter));
        }
        room.cooldowns[msg.sender] = SkillsCooldown(0,0,0,0);
        room.classToPlayer[classEnum(counter)] = msg.sender;
        room.info.playersCount++;
        room.cooldowns[msg.sender].rootCooldown = 1;
        isUserInGame[msg.sender] = true;
        emit RoomStateChanged(_roomId, room.info.playersCount);
        if(room.info.playersCount == 4) 
        {
            room.info.hasStarted = true;

emit GameStarted(_roomId);
            room.info.moveTimestamp = arbSys.arbBlockNumber() + 2 * turnTime;
        }
        return counter;
    }

    /// @dev Leaves game room, returns entry fees, removes players ships from board, updates cooldowns, isUserInGame mapping, and room statistics.
    /// @param _roomId id of the game room
    function leaveGame(uint256 _roomId) external 
    playerCanLeave(_roomId)
    {
        GameRoom storage room = games[_roomId];
        uint8 playerClass = getPlayerClass(_roomId, msg.sender);
        uint8 startingPoint = getPlayerStartingPoint(playerClass);
        for(uint8 i=playerClass * PIECE_PER_PLAYER; i< playerClass * PIECE_PER_PLAYER + PIECE_PER_PLAYER; i++)
        {
            if(i == playerClass * PIECE_PER_PLAYER) 
            {
                room.players[msg.sender][i].isOnBoard = false;
                room.board[startingPoint].isOccupied = false;
            }
            else if(i == playerClass * PIECE_PER_PLAYER + 1)
            {

       room.players[msg.sender][i].isOnBoard = false;
                room.board[(startingPoint + 1) % 40].isOccupied = false;
            }
            room.players[msg.sender][i].isInitialized = false;
        }
        room.info.playersCount--;
        isUserInGame[msg.sender] = false;
        room.classToPlayer[classEnum(playerClass)] = address(0);
        room.cooldowns[msg.sender].rootCooldown = 0;
        if(room.info.entryFee > 0)
        {
            (bool sent,) = msg.sender.call{value: room.info.entryFee}("");
            require(sent, "E21");
        }
        emit RoomStateChanged(_roomId, room.info.playersCount);
    }


    
    /// @dev Handles commit reveal scheme for dice rolls based on arbitrum block number. First user interaction is commit, second is reveal. Commit is available for 256 blocks for security reasons. 
    /// @param _roomId id of the game room
    function rollDice(uint256 _roomId) external 
    eligablePlayer(_roomId)
    playersTurn(_roomId)
    gameStarted(_roomId)
    {
        DiceRoll storage rolls = games[_roomId].diceRolls[msg.sender];
        require(rolls.toBeUsed == false || ((rolls.diceResult == 6 && games[_roomId].killCount < 2) || (rolls.diceResult == 12 && games[_roomId].killCount >= 2) && rolls.toBeUsed == false) || rolls.diceResult == 0, "E26");
        if(blockHashToBeUsed[msg.sender] == 0 || arbSys.arbBlockNumber() > blockHashToBeUsed[msg.sender] + 252) //rolling the dice 
        {
            blockHashToBeUsed[msg.sender] = arbSys.arbBlockNumber() + 2;
            return;
        }
        bytes32 blockHash = arbSys.arbBlockHash(blockHashToBeUsed[msg.sender]);
        if(blockHash == bytes32(0)) revert("E27");
        uint256 rand = uint256(blockHash);
        blockHashToBeUsed[msg.sender] = 0;
        uint8 diceResult = uint8(rand % 6) + 1;
        if(games[_roomId].killCount >= 2) rolls.diceResult = 2 * diceResult;
        else rolls.diceResult = diceResult;
        rolls.toBeUsed = true;
        emit DiceRolled(classEnum(getPlayerClass(_roomId, msg.sender)), _roomId, diceResult);
    }

    /// @dev Handles player move logic. Checks if player can move, if so, moves him (optionally with the usage of certrain _skill). Skills can be used only while moving (_leaveBase = false). 
    /// @param _roomId id of the game room
    /// @param _vehicleId id of the vehicle to be moved or taken out of base
    /// @param _skill skill to be used
    /// @param _targetTile id of the tile where skill will be used
    /// @param _leaveBase if true and other conditions met (see leaveBase), vehicle will be taken out of base, otherwise it will be moved
    function makeMove(uint256 _roomId, uint8 _vehicleId, uint8 _skill, uint8 _targetTile, bool _leaveBase) external 
    diceRolled(_roomId)
    {   
        skillsEnum skill = skillsEnum(_skill);
        uint8 diceResult = games[_roomId].diceRolls[msg.sender].diceResult;
        require(games[_roomId].players[msg.sender][_vehicleId].isInitialized, "E18");
        if(_skill == 2 && ((games[_roomId].killCount < 2 && diceResult == 6) || diceResult == 12)) revert("E28");
        if(canPlayerMove(_roomId, msg.sender, diceResult))
        {
            if(_leaveBase) leaveBase(_roomId, _vehicleId, diceResult);
            else 
            {
                moveVehicle(_roomId, _vehicleId, diceResult, skill, _targetTile);
            }
        }
        else updateQueue(_roomId);
    }

    /// @dev Function switches the game queue to the next player if the current player is out of time for making move.
    /// @param _roomId id of the game room
    function hurryPlayer(uint256 _roomId) external {
        require(arbSys.arbBlockNumber() >= games[_roomId].info.moveTimestamp + turnTime, "E29");
        updateQueue(_roomId);
    }

    /* EXTERNAL VIEW FUNCTIONS */

    /// @dev Returns array of 40 tiles representing the board state.
    /// @param _roomId id of the game room
    /// @return array of 40 tiles representing the board state.
    function getBoardState(uint256 _roomId) external view returns (Tile[40] memory)
    {
        return (games[_roomId].board);
    }

    /// @dev Returns the information about the room for specified player: skills cooldowns, current player id to move in gameroom, dice result for specified player, rapid moves state
    /// @param _roomId id of the game room
    /// @param _player address of the player
    /// @return SkillsCooldown struct, uint8 current player id to move in gameroom, uint8 dice result for specified player, bool rapid moves state
    function getRoomInfo(uint256 _roomId, address _player) external view returns (SkillsCooldown memory, uint8, uint8, bool)
    {
        uint8 diceResult = 0;
        bool rapidMoves = games[_roomId].killCount >= 2;
        if(games[_roomId].diceRolls[_player].toBeUsed)
        {
            if(rapidMoves) diceResult = games[_roomId].diceRolls[_player].diceResult / 2;
            else diceResult = games[_roomId].diceRolls[_player].diceResult;
        }
        return (games[_roomId].cooldowns[_player], games[_roomId].queue, diceResult, rapidMoves);
    }

    /// @dev Returns the ids of the ships that are in the base
    /// @param _roomId id of the game room
    /// @return uint8[] array of the ids of ships in base
    function getShipsInBase(uint256 _roomId) external view returns (uint8[] memory)
    {
        uint8[16] memory shipsInBase;
        uint8 counter=0;
        for(uint8 i=0;i<MAX_PLAYERS;i++)
        {
            for(uint8 j=i*PIECE_PER_PLAYER; j < i*PIECE_PER_PLAYER + PIECE_PER_PLAYER;j++)
            {
                if(games[_roomId].players[games[_roomId].classToPlayer[classEnum(i)]][j].isLapDone) 
                {
                    shipsInBase[counter] = j;

     counter++;
                }
            }
        }

        uint8[] memory result = new uint8[](counter);
        for (uint8 i = 0; i < counter; i++) {
            result[i] = shipsInBase[i];
        }
        return result;
    }

    /// @dev Returns the ids of the ships that are rooted
    /// @param _roomId id of the game room
    /// @return uint8[] array of the ids of the rooted ships
    function getRootedShips(uint256 _roomId) external view returns (uint8[] memory)
    {
        uint8[16] memory rootedShips;
        uint8 counter=0;
        for(uint8 i=0;i<MAX_PLAYERS;i++)
        {
            for(uint8 j=i*PIECE_PER_PLAYER; j < i*PIECE_PER_PLAYER + PIECE_PER_PLAYER;j++)
            {
                if(games[_roomId].players[games[_roomId].classToPlayer[classEnum(i)]][j].isRooted) 
                {
                    rootedShips[counter] = j;
                    counter++;
                }
            }
        }
        uint8[] memory result = new uint8[](counter);
        for (uint8 i = 0; i < counter; i++) {
            result[i] = rootedShips[i];
        }
        return result;
    }

    /// @dev Returns the id of the player's game room.
    /// @param _player address of the player. Note that you will only receive the correct output if you use your burner's address (unless you play directly via smart contract).
    /// @return int256 id of the game room. Returns -1 if the player is not in any room.
    function getPlayersRoom(address _player) external view returns (int256)
    {
        for(uint256 i = 0; i < games.length; i++)
        {
            for(uint8 j = 0; j < MAX_PLAYERS; j++)
            {
                if(games[i].classToPlayer[classEnum(j)] == _player && !games[i].info.hasEnded) return int256(i);

 }
        }
        return -1;
    }
    
    /// @dev Returns the current state of the game room. It includes the players (addresses) in the room and the entry fee.
    /// @param _roomId id of the game room
    /// @return address[] array of players in the room, uint256 entryFee of the room.
    function getRoomState(uint256 _roomId) external view returns (address[] memory, uint256) {
        address[] memory players = new address[](MAX_PLAYERS);
        for(uint i = 0; i < MAX_PLAYERS; i++) {
            players[i] = getCorrectAddress(games[_roomId].classToPlayer[classEnum(i)]);
        }
        return (players, games[_roomId].info.entryFee);
    }
    
    /// @dev Returns the block number which indicate the time when the current move has started. Used to determine if the player has run out of time.
    /// @param _roomId id of the game room
    /// @return uin256 block number when the current move has started.
    function getCurrentMoveTimestamp(uint256 _roomId) external view returns (uint256) {
        return games[_roomId].info.moveTimestamp;
    }

    /// @dev Returns the total number of games that have been created.
    /// @return uint256 lenght of games array.
    function getGamesCount() external view returns (uint256) {
        return games.length;
    }

    /// @dev Checks if the game has ended.
    /// @param _roomId id of the game room
    /// @return bool hasEnded stored inside the game struct.
    function isGameFinished(uint256 _roomId) external view returns (bool) {
        return games[_roomId].info.hasEnded;
    }
}