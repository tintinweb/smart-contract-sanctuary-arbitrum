// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

// Randomizer protocol interface
interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function estimateFee(uint256 _callbackGasLimit) external returns (uint256);

    function clientDeposit(address _client) external payable;

    function clientWithdrawTo(address _to, uint256 _amount) external;

    function getFeeStats(uint256 _request) external returns (uint256[2] memory);
}

// IBankRoll protocol interface
interface IBankRoll {
    function sendWinAmount(address user, uint256 amount) external;
}

// Coinflip contract
contract CoinFlip {
    // Enum Representing Heads or Tails
    enum CoinFlipValues {
        HEADS,
        TAILS
    }
    struct CoinFlipGame {
        uint256 betAmount;
        uint256 vrfFeeSent;
        uint256 seed;
        address user;
        CoinFlipValues prediction;
        uint8 result;
        bool isGameVRFDifferenceWithdrawn;
    }

    uint256 public callbackGasLimit;
    uint256 houseCutNum = 3;
    uint256 houseCutDenom = 100;
    uint256 private _reEntancyStatus = 1; //Non_Entered

    // Arbitrum goerli
    IRandomizer public randomizer;

    address public owner;
    address public houseCut;
    address public bankRoll;
    // Stores each game to the user
    mapping(uint256 => CoinFlipGame) public coinFlipGames;
    mapping(uint256 => bool) public flipAmounts;
    mapping(address => uint256[]) public userToGames;

    // Events
    event BetRequestDenied(
        uint256 indexed betRequestDeniedId,
        address indexed user,
        uint256 betAmount,
        uint256 bankRollBalance
    );
    event FlipRequest(uint256 requestId, address user);
    event FlipResult(
        address indexed user,
        uint256 indexed id,
        uint256 seed,
        CoinFlipValues prediction,
        CoinFlipValues result
    );
    event FlipAmountsSet(uint256[] amount, bool isAccepted);
    event LastGameDifferenceInVRFFee(
        address indexed user,
        uint256 indexed vrfDepositedInRandomizer,
        uint256 indexed vrfConsumedByRandomizer
    );
    event BankRollSet(address _bankRoller, address owner);
    event HouseCutSet(address _houseCut, address owner);
    event CallBackGasLimitSet(uint256 _callBackGasLimit, address owner);
    event OwnershipTransferred(address indexed newOwner, address indexed previousOwner);
    event EtherWithdrawn(address indexed owner, uint256 amount);
    event EtherDeposited(address indexed from, uint256 amount);

    error InvalidBetAmount(uint256 betAmount);
    error ArrayLengthCantBeZero();
    error NotEnoughEtherSent(uint256 etherSent);
    error CallerNotRandomizer();
    error CallerNotAuthorizedForRefund();
    error NothingToWithdraw();
    error ETHTransferFailed(address _to, uint256 _amount);
    error CallerIsNotOwner(address _owner);
    error ReEntrantCall();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert CallerIsNotOwner(owner);
        }
        _;
    }

    modifier nonReentrant() {
        if (_reEntancyStatus == 2) {
            revert ReEntrantCall();
        }
        _reEntancyStatus = 2; //Entered
        _;
        _reEntancyStatus = 1;
    }

    constructor(address _randomizer, address _houseCut, address _bankRoll, uint256 _callbackGasLimit) {
        owner = msg.sender;
        houseCut = _houseCut;
        bankRoll = _bankRoll;
        callbackGasLimit = _callbackGasLimit;
        randomizer = IRandomizer(_randomizer);
    }

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value);
    }

    function flip(uint256 betAmount, CoinFlipValues _coinFlipValue) external payable nonReentrant {
        if (!flipAmounts[betAmount]) {
            revert InvalidBetAmount(betAmount);
        }
        uint256 noOfBetsByUser = userToGames[msg.sender].length;
        if (noOfBetsByUser > 0) {
            uint256 indexOflastRequestId = noOfBetsByUser - 1;
            uint256 lastRequestId = userToGames[msg.sender][indexOflastRequestId];
            _refundVRFFee(lastRequestId, true);
        }

        uint256 houseCutFee = (betAmount * houseCutNum) / houseCutDenom;
        uint256 houseCutAndBetAmount = betAmount + houseCutFee;
        uint256 estimateFee = randomizer.estimateFee(callbackGasLimit);
        // Check if User Sent Enough ETH for FullFillment of VRF and House Cut
        if (msg.value < houseCutAndBetAmount + estimateFee) {
            revert NotEnoughEtherSent(msg.value);
        }
        uint256 vrfFeeSentByUser = msg.value - houseCutAndBetAmount;
        // Deposit VRF Fee by User
        randomizer.clientDeposit{value: vrfFeeSentByUser}(address(this));
        uint256 id = randomizer.request(callbackGasLimit);
        userToGames[msg.sender].push(id);
        coinFlipGames[id] = CoinFlipGame(betAmount, vrfFeeSentByUser, 0, msg.sender, _coinFlipValue, 0, false);

        // Take House Cut and Send it to the HouseCut Address
        _transferEther(houseCut, houseCutFee);
        emit FlipRequest(id, msg.sender);
    }

    // Callback function called by the randomizer contract when the random value is generated
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        //Check if Caller is Randomizer
        if (msg.sender != address(randomizer)) {
            revert CallerNotRandomizer();
        }
        CoinFlipGame memory game = coinFlipGames[_id];
        uint256 seed = uint256(_value);
        game.seed = seed;
        CoinFlipValues result = (seed % 2 == 0) ? CoinFlipValues.HEADS : CoinFlipValues.TAILS;
        game.result = uint8(result);
        coinFlipGames[_id] = game;

        if (game.prediction == result) {
            // If User Wins, Double the Amount of His Bet
            IBankRoll(bankRoll).sendWinAmount(game.user, game.betAmount * 2);
        } else {
            // If User Loses, Send his Bet to BankRoll
            _transferEther(bankRoll, game.betAmount);
        }

        emit FlipResult(game.user, _id, seed, game.prediction, result);
    }

    function setFlipAmounts(uint256[] calldata amounts, bool isAccepted) external onlyOwner {
        if (amounts.length == 0) {
            revert ArrayLengthCantBeZero();
        }
        for (uint256 i = 0; i < amounts.length; ) {
            flipAmounts[amounts[i]] = isAccepted;
            unchecked {
                ++i;
            }
        }

        emit FlipAmountsSet(amounts, isAccepted);
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

    // Allows the owner to withdraw their deposited randomizer funds
    function randomizerWithdraw(uint256 amount) external onlyOwner {
        randomizer.clientWithdrawTo(msg.sender, amount);
    }

    // Allows the user to withdraw their deposited randomizer funds If any
    function refundVRFFeeIfAny(uint256 requestId) external {
        _refundVRFFee(requestId, false);
    }

    // Withdraw Ether If any From the Contract
    function withdrawEther(uint256 amount) external onlyOwner {
        _transferEther(owner, amount);
        emit EtherWithdrawn(owner, amount);
    }

    // Transfer Ether From the Contract
    function _transferEther(address to, uint256 amount) internal {
        (bool sent, ) = payable(to).call{value: amount}('');
        if (!sent) {
            revert ETHTransferFailed(to, amount);
        }
    }

    function _refundVRFFee(uint256 requestId, bool isRequestFromFlip) internal {
        CoinFlipGame storage coinFlip = coinFlipGames[requestId];
        // If Request is Not from flip()
        if (!isRequestFromFlip) {
            if (msg.sender != coinFlip.user) {
                revert CallerNotAuthorizedForRefund();
            }
        }
        uint256 vrfFeeConsumed = randomizer.getFeeStats(requestId)[0];
        uint256 vrfFeeSent = coinFlip.vrfFeeSent;
        //Allow Withdraw If the User has not already withdrawn
        if (!coinFlip.isGameVRFDifferenceWithdrawn && vrfFeeSent > vrfFeeConsumed) {
            uint256 lastGameVRFFeeToRefund = vrfFeeSent - vrfFeeConsumed;
            coinFlip.isGameVRFDifferenceWithdrawn = true;
            randomizer.clientWithdrawTo(msg.sender, lastGameVRFFeeToRefund);
            emit LastGameDifferenceInVRFFee(msg.sender, vrfFeeSent, vrfFeeConsumed);
        } else {
            // If Request is Not from flip()
            if (!isRequestFromFlip) {
                revert NothingToWithdraw();
            }
        }
    }
}