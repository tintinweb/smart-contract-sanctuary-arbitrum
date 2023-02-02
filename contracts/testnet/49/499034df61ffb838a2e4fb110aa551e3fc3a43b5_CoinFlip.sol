/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

// SPDX-License-Identifier: MIT

// Coin flip game with randomizer VRF example
// Doesn't accept bets, just emits win/lose based on prediction

pragma solidity ^0.8.16;

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function clientWithdrawTo(address to, uint256 amount) external;
}

interface IRandomizerDeposit {
    function clientDeposit(address _client) external payable;
}

contract CoinFlip {
    struct CoinFlipGame {
        address player;
        bool prediction;
        bool result;
        uint256 seed;
    }

    event Flip(address indexed player, uint256 indexed id, bool prediction);

    event FlipResult(
        address indexed player,
        uint256 indexed id,
        uint256 seed,
        bool prediction,
        bool result
    );

    event OwnerUpdated(address indexed user, address indexed newOwner);

    mapping(uint256 => CoinFlipGame) coinFlipGames;
    mapping(address => uint256[]) userToGames;
    mapping(uint256 => bool) gameToHeadsTails;

    address public owner;
    address public proposedOwner;

    IRandomizer private randomizer;

    constructor(address _randomizer) {
        randomizer = IRandomizer(_randomizer);
        owner = msg.sender;
        emit OwnerUpdated(address(0), owner);
    }

    // Called by player to initiate a coinflip
    // Using randomizer's request id as the game id
    function flip(bool prediction) external {
        uint256 id = IRandomizer(randomizer).request(20000);
        userToGames[msg.sender].push(id);
        coinFlipGames[id] = CoinFlipGame(msg.sender, prediction, false, 0);
        emit Flip(msg.sender, id, prediction);
    }

    // The callback function called by randomizer when the random bytes are ready
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        require(
            msg.sender == address(randomizer),
            "Only the randomizer contract can call this function"
        );
        CoinFlipGame memory game = coinFlipGames[_id];
        uint256 seed = uint256(_value);
        game.seed = seed;
        bool headsOrTails = (seed % 2 == 0);
        game.result = headsOrTails;
        emit FlipResult(game.player, _id, seed, game.prediction, headsOrTails);
    }

    // Get a game struct for a game id
    function getGame(uint256 _id) external view returns (CoinFlipGame memory) {
        return coinFlipGames[_id];
    }

    // Get all games for a user
    function getPlayerGameIds(address _player)
        external
        view
        returns (uint256[] memory)
    {
        return userToGames[_player];
    }

    // Previews the outcome of a game based on the seed, used for front-end instant results sent by sequencer.
    function previewResult(bytes32 _value) external pure returns (bool) {
        bool headsOrTails = (uint256(_value) % 2 == 0);
        return headsOrTails;
    }

    /* Non-game functions */

    // Allows the owner to withdraw their deposited randomizer funds
    function randomizerWithdraw(address _randomizer, uint256 amount) external {
        require(msg.sender == owner);
        IRandomizer(_randomizer).clientWithdrawTo(msg.sender, amount);
    }

    // Propose a new owner
    function proposeNewOwner(address _newOwner) external {
        require(msg.sender == owner);
        proposedOwner = _newOwner;
    }

    // Accept the proposed owner
    function acceptNewOwner(address _newOwner) external {
        require(msg.sender == proposedOwner && msg.sender == _newOwner);
        owner = proposedOwner;
        proposedOwner = address(0);
        emit OwnerUpdated(address(0), owner);
    }
}