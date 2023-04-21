// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Randomizer protocol interface
interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);

    function estimateFee(uint256 callbackGasLimit) external returns (uint256);

    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);

    function clientWithdrawTo(address _to, uint256 _amount) external;

    function getFeeStats(uint256 _request) external returns (uint256[2] memory);
}

// Coinflip contract
contract CoinFlip {
    // Enum Representing Heads or Tails
    enum CoinFlipValues {
        HEADS,
        TAILS
    }
    struct CoinFlipGame {
        address player;
        uint256 betAmount;
        uint256 totalAmountInitiallySpentBytheUser;
        uint256 houseCutFee;
        uint256 randomizerEstimateFee;
        CoinFlipValues prediction;
        CoinFlipValues result;
        uint256 seed;
    }

    // Arbitrum goerli
    IRandomizer public randomizer;

    address public owner;
    address public houseCut;
    address public bankRoll;

    uint256 public callbackGasLimit = 130000;
    uint256 houseCutNum = 3;
    uint256 houseCutDenom = 100;
    CoinFlipValues constant defaultChoice = CoinFlipValues.HEADS;
    // Stores each game to the player
    mapping(uint256 => CoinFlipGame) coinFlipGames;
    mapping(uint256 => address) public flipToAddress;
    mapping(uint256 => bool) public flipAmounts;
    mapping(address => uint256[]) userToGames;

    // Events
    event FlipRequest(uint256 requestId, address player);
    event FlipResult(
        address indexed player,
        uint256 indexed id,
        uint256 seed,
        CoinFlipValues prediction,
        CoinFlipValues result
    );
    event FlipAmountSet(uint256 amount, bool isAccepted);
    event BankRollSet(address _bankRoller, address owner);
    event HouseCutSet(address _houseCut, address owner);
    event CallBackGasLimitSet(uint256 _callBackGasLimit, address owner);
    event OwnershipTransferred(address indexed newOwner, address indexed previousOwner);
    event EtherWithdrawn(address indexed owner, uint256 amount);
    event EtherDeposited(address indexed from, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Sender is not owner');
        _;
    }

    constructor(address _randomizer) {
        owner = msg.sender;
        randomizer = IRandomizer(_randomizer);
    }

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    function flip(uint256 betAmount, CoinFlipValues _coinFlipValues) external payable {
        require(flipAmounts[betAmount], 'The Bet Amount Is Not Valid');
        uint256 estimateFee = randomizer.estimateFee(callbackGasLimit, 1);
        uint256 houseCutFee = (betAmount * houseCutNum) / houseCutDenom;
        uint256 feesAndBetAmount = betAmount + estimateFee + houseCutFee;
        require(msg.value >= feesAndBetAmount, 'Insufficient ETH being Sent');
        uint256 id = randomizer.request(callbackGasLimit);
        userToGames[msg.sender].push(id);
        coinFlipGames[id] = CoinFlipGame(
            msg.sender,
            betAmount,
            msg.value,
            houseCutFee,
            estimateFee,
            _coinFlipValues,
            defaultChoice,
            0
        );
        (bool sent, bytes memory data) = payable(houseCut).call{value: houseCutFee}('');
        string memory response = string(data);
        require(sent, response);
        emit FlipRequest(id, msg.sender);
    }

    // Callback function called by the randomizer contract when the random value is generated
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        //Callback can only be called by randomizer
        require(msg.sender == address(randomizer), 'Caller not Randomizer');
        CoinFlipGame memory game = coinFlipGames[_id];
        uint256 seed = uint256(_value);
        game.seed = seed;
        CoinFlipValues result = (seed % 2 == 0) ? CoinFlipValues.HEADS : CoinFlipValues.TAILS;
        game.result = result;
        coinFlipGames[_id] = game;
        uint256[2] memory feeStats = randomizer.getFeeStats(_id);
        uint256 extraSpentByUserIfAny = game.totalAmountInitiallySpentBytheUser -
            game.betAmount -
            game.houseCutFee -
            game.randomizerEstimateFee;
        uint256 refundAmount = feeStats[0] < extraSpentByUserIfAny ? extraSpentByUserIfAny - feeStats[0] : 0;

        if (game.prediction == result) {
            // If User Wins, Double the Amount of His Bet
            uint256 amountToBeSent = game.betAmount * 2 + refundAmount;
            (bool sent, bytes memory data) = payable(game.player).call{value: amountToBeSent}('');
            string memory response = string(data);
            require(sent, response);
        } else {
            // If User Loses, Send his Bet to BankRoll
            (bool sent, bytes memory data) = payable(bankRoll).call{value: game.betAmount}('');
            string memory response = string(data);
            require(sent, response);
            // Refund Amount to Player
            if (refundAmount > 0) {
                (bool sent, bytes memory data) = payable(game.player).call{value: refundAmount}('');
                string memory response = string(data);
                require(sent, response);
            }
        }

        emit FlipResult(game.player, _id, seed, game.prediction, result);
    }

    function setFlipAmounts(uint256 amount, bool isAccepted) external onlyOwner {
        flipAmounts[amount] = isAccepted;
        emit FlipAmountSet(amount, isAccepted);
    }

    function setHouseCutAddress(address _houseCut) external onlyOwner {
        houseCut = _houseCut;
        emit HouseCutSet(_houseCut, owner);
    }

    function setBankRollAddress(address _bankRoll) external onlyOwner {
        bankRoll = _bankRoll;
        emit BankRollSet(_bankRoll, owner);
    }

    function setCallBackGasLimit(uint256 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
        emit CallBackGasLimitSet(_callbackGasLimit, owner);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(_newOwner, oldOwner);
    }

    function withdrawEther(uint256 amount) external onlyOwner {
        (bool sent, bytes memory data) = payable(owner).call{value: amount}('');
        string memory response = string(data);
        require(sent, response);
        emit EtherWithdrawn(owner, amount);
    }
}