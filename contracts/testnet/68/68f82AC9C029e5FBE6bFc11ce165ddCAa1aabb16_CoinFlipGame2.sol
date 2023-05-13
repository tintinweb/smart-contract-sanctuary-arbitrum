// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Coin flip game with randomizer VRF example
// Doesn't accept bets, just emits win/lose based on prediction

interface IRandomizer {

    function request(uint256 callbackGasLimit) external returns (uint256);

    function clientDeposit(address client) external payable;

    function clientWithdrawTo(address to, uint256 amount) external;

    function clientBalanceOf(address client) external view returns (uint256, uint256);

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256);

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256);

    function estimateFeeUsingGasPrice(uint256 callbackGasLimit, uint256 gasPrice) external view returns (uint256);

    function estimateFeeUsingConfirmationsAndGasPrice(uint256 callbackGasLimit, uint256 confirmations, uint256 gasPrice) external view returns (uint256);

}

contract CoinFlipGame2 {

    struct CoinFlipGameInfo {
        address player;
        uint256 seed;
    }

    event Flip(address indexed player, uint256 indexed id);

    event FlipResult(
        address indexed player,
        uint256 indexed id,
        uint256 seed
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    mapping(uint256 => CoinFlipGameInfo) coinFlipGameInfos;

    mapping(address => uint256[]) userToGames;

    mapping(uint256 => bool) gameToHeadsTails;

    address public owner;

    address public proposedOwner;

    IRandomizer private randomizer;

    constructor(address randomizer_) {
        randomizer = IRandomizer(randomizer_);
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    /**
     * @dev Called by player to initiate a coinflip
     * Using randomizer's request id as the game id
     */
    function flip() external {
        uint256 id = randomizer.request(500000);
        userToGames[msg.sender].push(id);
        coinFlipGameInfos[id] = CoinFlipGameInfo(msg.sender, 0);
        emit Flip(msg.sender, id);
    }

    // @dev The callback function called by randomizer when the random bytes are ready
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        require(
            msg.sender == address(randomizer),
            "Only the randomizer contract can call this function"
        );
        CoinFlipGameInfo storage game = coinFlipGameInfos[_id];
        uint256 seed = uint256(_value);
        game.seed = seed;
        emit FlipResult(game.player, _id, seed);
    }

    // @dev Get a game struct for a game id
    function getGame(uint256 _id) external view returns (CoinFlipGameInfo memory) {
        return coinFlipGameInfos[_id];
    }

    // @dev Get all games for a user
    function getPlayerGameIds(address _player) external view returns (uint256[] memory){
        return userToGames[_player];
    }

    // @dev Previews the outcome of a game based on the seed, used for front-end instant results sent by sequencer.
    function previewResult(bytes32 _value) external pure returns (bool) {
        bool headsOrTails = (uint256(_value) % 2 == 0);
        return headsOrTails;
    }

    /* Non-game functions */

    function depositFund() external payable {
        randomizer.clientDeposit{value : msg.value}(address(this));
    }

    function withdrawFund() external {
        require(msg.sender == owner);
        (uint256 balance_,uint256 balance2_) = balanceOfFund();
        require(balance_ > 0, "L2Unicorn: balance is zero");
        randomizer.clientWithdrawTo(msg.sender, (balance_ - balance2_));
    }

    function withdrawFund(uint256 amount_) external {
        require(msg.sender == owner);
        require(amount_ > 0, "L2Unicorn: amount is zero");
        randomizer.clientWithdrawTo(msg.sender, amount_);
    }

    function balanceOfFund() public view returns (uint256, uint256){
        return randomizer.clientBalanceOf(address(this));
    }

    function estimateFee(uint256 callbackGasLimit) external view returns (uint256) {
        return randomizer.estimateFee(callbackGasLimit);
    }

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256) {
        return randomizer.estimateFee(callbackGasLimit, confirmations);
    }

    function estimateFeeUsingGasPrice(uint256 callbackGasLimit, uint256 gasPrice) external view returns (uint256) {
        return randomizer.estimateFeeUsingGasPrice(callbackGasLimit, gasPrice);
    }

    function estimateFeeUsingConfirmationsAndGasPrice(uint256 callbackGasLimit, uint256 confirmations, uint256 gasPrice) external view returns (uint256) {
        return randomizer.estimateFeeUsingConfirmationsAndGasPrice(callbackGasLimit, confirmations, gasPrice);
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

}