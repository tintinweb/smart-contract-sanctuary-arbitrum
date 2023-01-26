/**
 *Submitted for verification at Arbiscan on 2023-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Bet {

  enum BetStatus {
    LONG,
    SHORT
  }

  enum BetState {
    ACTIVE,
    DECLARED,
    REVOKED
  }

  struct Game {
    uint256 betAmount;
    string coin;
    uint256 guess;
    BetStatus status;
    address maker;
    address taker;
    uint256 expiry;
    address winner;
    uint256 wonAmount;
    BetState betState;
    uint256 outcomePrice;
  }

  address public owner;
  Game[] public activeGames;
  uint256 public totalBetAmount;
  uint256 public totalTakeAmount;
  uint256 public totalBets;
  uint256 public totalPrizeAmount;
  uint256 public totalPrizeAmountWithFee;
  address payable public admin;
  address public creator;
  uint256 public adminFee;

  event BetMade(uint256);
  event BetTaken(uint256);
  event BetRevoked(uint256);
  event MakerWins(address);
  event TakerWins(address);
  event Received(address, uint256);

  constructor(address _creator, address _admin, uint256 _adminFee) {
    require(_creator != address(0),
      "Invalid creator");
    require(_admin != address(0), 
      "Invalid admin");

    owner = msg.sender;
    creator = _creator;
    admin = payable(_admin);
    adminFee = _adminFee;
  }

  function makeBet(
    string memory coin,
    uint256 guess,
    uint256 expiry,
    uint256 betStatus
  ) public payable {
    require(msg.value > 0,
      "Value should be above 0");

    require(expiry > block.timestamp,
      "Expiry time must be future timestamp!!");
  
    Game memory newGame = Game(
      msg.value,
      coin,
      guess,
      BetStatus(betStatus),
      msg.sender,
      address(0),
      expiry,
      address(0),
      0,
      BetState.ACTIVE,
      0
    );

    activeGames.push(newGame);
    totalBetAmount += msg.value;
    totalBets++;
    
    emit BetMade(activeGames.length - 1);
  }

  function takeBet(uint256 betId) public payable {
    require(activeGames[betId].taker == address(0),
      "The address is already in the process of taking this bet");

    require(activeGames[betId].expiry >= block.timestamp, 
      "Bet is expired!!");

    require(msg.value == activeGames[betId].betAmount,
      "Invalid bet Amount");

    activeGames[betId].taker = msg.sender;
    totalTakeAmount += msg.value;

    emit BetTaken(betId);
  }

  function revokeBet(uint256 betId) public {
    require(activeGames[betId].maker == msg.sender, 
      "access denied!!");

    require(activeGames[betId].expiry < block.timestamp,
      "Bet is not expired yet!!");

    require(activeGames[betId].taker == address(0),
      "Someone has taken your bet, You cann't revoke it!!");

    require(activeGames[betId].betState == BetState.ACTIVE, 
      "Bet is not active!!");

    activeGames[betId].betState = BetState.REVOKED;
    (bool sent, ) = activeGames[betId].maker.call{value: activeGames[betId].betAmount}("");
    require(sent, "Failed to send transaction");

    emit BetRevoked(betId);
  }

  function getBetOutcome(uint256 betId, uint256 current_price) public {
    require(msg.sender == creator,
      "This function can only be called via the creator");

    Game storage game = activeGames[betId];

    require(game.betState == BetState.ACTIVE,
      "Bet is not active!!");

    require(activeGames[betId].expiry < block.timestamp,
      "Bet is Live, can't declare result");
      
    require(game.winner == address(0), 
      "Bet already resolved");

    require(game.taker != address(0), 
      "Bet has no taker!!");

    if ((game.status == BetStatus.LONG && current_price >= game.guess) || 
        (game.status == BetStatus.SHORT && current_price <= game.guess)) {
      game.winner = game.maker;

      emit MakerWins(game.maker);
    } else {
      game.winner = game.taker;

      emit TakerWins(game.taker);
    }

    uint256 wonAmount = game.betAmount * 2;
    uint256 feeAmount = wonAmount * adminFee / 10000;
    wonAmount = wonAmount - feeAmount;

    totalPrizeAmount += wonAmount;
    totalPrizeAmountWithFee += (wonAmount + feeAmount);
    game.wonAmount = wonAmount;
    game.betState = BetState.DECLARED;
    game.outcomePrice = current_price;

    if (feeAmount > 0 && admin != address(0)) {
      (bool feeSent, ) = admin.call{value: feeAmount}("");
      require(feeSent, "admin fee Failed to send");  
    }

    (bool sent, ) = game.winner.call{value: wonAmount}("");
    require(sent, "Failed to send transaction");
  }

  function updateCreator(address _creator) external {
    require( msg.sender == owner,
      "Access denied!!");
    
    creator = _creator;
  }

  function updateAdmin(address _admin) external {
    require( msg.sender == owner,
      "Access denied!!");

    admin = payable(_admin);
  }

  function updateAdminFee(uint256 _fee) external {
    require( msg.sender == owner,
      "Access denied!!");

    adminFee = _fee;
  }

  function transferOwnership(address _owner) external {
    require( msg.sender == owner,
      "Access denied!!");

    owner = _owner;
  }

  function emergencyWithdraw() external {
    require( msg.sender == owner,
      "Access denied!!");

    (bool sent, ) = owner.call{value: address(this).balance}("");
    require(sent, "Failed to send transaction");
  }

  function emergencyERC20Withdraw(address _token) external {
    require( msg.sender == owner,
      "Access denied!!");

    IBEP20(_token).transfer(owner, IBEP20(_token).balanceOf(address(this)));
  }

  function getBalance() public view returns (uint256 balance) {
    return address(this).balance;
  }
}