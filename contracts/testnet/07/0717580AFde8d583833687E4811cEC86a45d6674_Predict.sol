/**
 *Submitted for verification at Arbiscan on 2022-09-04
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.9.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface FlagsInterface {
  function getFlag(address) external view returns (bool);

  function getFlags(address[] calldata) external view returns (bool[] memory);

  function raiseFlag(address) external;

  function raiseFlags(address[] calldata) external;

  function lowerFlags(address[] calldata) external;

  function setRaisingAccessController(address) external;
}

//Maybe you can add code to make predictions for all coins in one smart contract to save gas money when deploying.

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Predict is ReentrancyGuard {
    address public admin;
    uint256 public minBetAmount;
    uint256 public treasuryFee;
    uint256 public treasuryAmount;
    uint256 public currentRound;
    uint256 public MAX_TREASURY_FEE = 10;

    event ClaimReward(address claimer, uint256 rewardAmount);
    event PredictionMade(address predictor, uint256 amountBet, bool bull_predicted);

    // Identifier of the Sequencer offline flag on the Flags contract 
    address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));
    FlagsInterface internal chainlinkFlags;

    constructor(uint256 _minBetAmount, uint256 _treasuryFee) public {
        admin = msg.sender;
        minBetAmount = _minBetAmount;
        treasuryFee = _treasuryFee;
        currentRound = 0;
        chainlinkFlags = FlagsInterface(0x491B1dDA0A8fa069bbC1125133A975BF4e85a91b);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin is allowed!");
        _;
    }

    struct Round {
        uint256 startTime;
        uint256 closeTime;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 startPrice;
        uint256 closePrice;
        bool bull_won;
        mapping(address => bool) predicted;
        mapping(address => bool) bull_predicted;
        mapping(address => uint256) betted_amount;
        mapping(address => bool) claimed_reward;
    }

    mapping(uint => Round) rounds;

    function getPredicted() external view returns(bool) {
        return rounds[currentRound - 1].predicted[msg.sender];
    }

    function claimTreasury() external onlyAdmin {
        require(treasuryAmount > 0, "The treasury must not be empty");
        //(bool success, ) = msg.sender.call{value: treasuryAmount}("");
        //require(success, "TransferHelper: BNB_TRANSFER_FAILED");
        payable(admin).transfer(address(this).balance);
        treasuryAmount = 0;
    }

    function setTreasuryFee(uint256 _treasuryFee) external onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee cannot exceed 10%");
        treasuryFee = _treasuryFee;
    }

    function setMinBetAmount(uint256 _minBetAmount) external onlyAdmin {
        minBetAmount = _minBetAmount;
    }

    function bullBet() external payable nonReentrant {
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(rounds[currentRound - 1].predicted[msg.sender] == false, "Already predicted for this round");
        require(block.timestamp < rounds[currentRound - 1].closeTime + 1 hours, "Round is closed");
        rounds[currentRound - 1].totalAmount += (msg.value * (100 - treasuryFee) / 100);
        rounds[currentRound - 1].bullAmount += (msg.value * (100 - treasuryFee) / 100);
        treasuryAmount += (msg.value * treasuryFee) / 100;
        rounds[currentRound - 1].predicted[msg.sender] = true;
        rounds[currentRound - 1].bull_predicted[msg.sender] = true;
        rounds[currentRound - 1].betted_amount[msg.sender] = msg.value * (100 - treasuryFee) / 100;
        emit PredictionMade(msg.sender, msg.value, true);
    }

    function bearBet() external payable nonReentrant {
        require(msg.value >= minBetAmount, "Bet amount must be greater than minBetAmount");
        require(rounds[currentRound - 1].predicted[msg.sender] == false, "Already predicted for this round");
        require(block.timestamp < rounds[currentRound - 1].closeTime + 1 hours, "Round is closed");
        rounds[currentRound - 1].totalAmount += (msg.value * (100 - treasuryFee) / 100);
        rounds[currentRound - 1].bearAmount += (msg.value * (100 - treasuryFee) / 100);
        treasuryAmount += (msg.value * treasuryFee) / 100;
        rounds[currentRound - 1].predicted[msg.sender] = true;
        rounds[currentRound - 1].bull_predicted[msg.sender] = false;
        rounds[currentRound - 1].betted_amount[msg.sender] = msg.value * (100 - treasuryFee) / 100;
        emit PredictionMade(msg.sender, msg.value, false);
    }

    function claimReward() external nonReentrant {
        require(block.timestamp >= rounds[currentRound - 2].closeTime, "The round has to be finished before claiming reward");
        require(rounds[currentRound - 2].bull_predicted[msg.sender] == rounds[currentRound - 2].bull_won, "You didn't win the round");
        require(rounds[currentRound - 2].claimed_reward[msg.sender] == false, "You already claimed your reward");
        uint256 reward;
        if (rounds[currentRound - 2].bull_won) {
            reward = rounds[currentRound - 2].betted_amount[msg.sender] * rounds[currentRound - 2].totalAmount / rounds[currentRound - 2].bullAmount;
        } else {
            reward = rounds[currentRound - 2].betted_amount[msg.sender] * rounds[currentRound - 2].totalAmount / rounds[currentRound - 2].bearAmount;
        }
        msg.sender.transfer(reward);
        emit ClaimReward(msg.sender, reward);
        rounds[currentRound - 2].claimed_reward[msg.sender] = true;
        //(bool success, ) = msg.sender.call{value: reward}("");
        //require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }

    function setWinningSide() external nonReentrant onlyAdmin {
        require(block.timestamp >= rounds[currentRound - 2].closeTime, "The round has to be finished to set the winning side");
        /*if (keccak256(abi.encodePacked(winningSide)) == keccak256(abi.encodePacked("bull"))) {
            rounds[currentRound - 1].bull_won = true;
        } else if (keccak256(abi.encodePacked(winningSide)) == keccak256(abi.encodePacked("bear"))) {
            rounds[currentRound - 1].bull_won = false;
        }*/
        rounds[currentRound - 1].startPrice = getPrice();
        rounds[currentRound - 2].closePrice = getPrice();
        if (rounds[currentRound - 2].startPrice < rounds[currentRound - 2].closePrice) {
            rounds[currentRound - 2].bull_won = true;
        } else {
            rounds[currentRound - 2].bull_won = false;
        }
    }

    function getWinningSide() external view returns(bool) {
        return rounds[currentRound - 1].bull_won;
    }

    function createRound() external onlyAdmin nonReentrant {
        Round storage round = rounds[currentRound];
        round.startTime = block.timestamp;
        round.closeTime = block.timestamp + 2 hours;
        round.totalAmount = 0;
        round.bullAmount = 0;
        round.bearAmount = 0;
        round.startPrice = 0;
        if (currentRound != 0) {
            rounds[currentRound - 1].startPrice = getPrice();
        }
        currentRound = currentRound + 1;
    }

    function getUpPayout(uint256 _roundNumber) external view returns(uint256) {
        uint256 payout = (rounds[_roundNumber].totalAmount * 100) / rounds[_roundNumber].bullAmount;
        if (payout != 0) {
            return payout;
        }
    }

    function getDownPayout(uint256 _roundNumber) external view returns(uint256) {
        uint256 payout = (rounds[_roundNumber].totalAmount * 100) / rounds[_roundNumber].bearAmount;
        if (payout != 0) {
            return payout;
        }
    }

    function getPrizePool(uint256 _roundNumber) external view returns(uint256) {
        return rounds[_roundNumber].totalAmount;
    }

    function getClosingTime(uint256 _roundNumber) external view returns(uint256) {
        return rounds[_roundNumber].closeTime;
    }

    function getCurrentTime() external view returns(uint256) {
        return now;
    }

    function getStartingPrice() external view returns(uint256) {
        return rounds[currentRound - 2].startPrice;
    }

    function getRoundData(uint256 _roundNumber) external view returns(uint256, uint256, uint256, uint256) {
        return (this.getPrizePool(_roundNumber - 1), this.getClosingTime(_roundNumber - 1), this.getUpPayout(_roundNumber - 1), this.getDownPayout(_roundNumber - 1));
    }

    function getCurrentRound() external view returns(uint256) {
        return currentRound;
    }

    //Functions relating to the price oracles
    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x0c9973e7a27d00e656B9f153348dA46CaD70d03d); //0xECe365B379E1dD183B20fc5f022230C044d51404
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        bool isRaised = chainlinkFlags.getFlag(FLAG_ARBITRUM_SEQ_OFFLINE);
        if (isRaised) {
            // If flag is raised we shouldn't perform any critical operations
            revert("Chainlink feeds are not being updated");
        }
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x0c9973e7a27d00e656B9f153348dA46CaD70d03d); //0xECe365B379E1dD183B20fc5f022230C044d51404
        (,int256 answer,,,) = priceFeed.latestRoundData();
         // ETH/USD rate in 18 digit 
         return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}