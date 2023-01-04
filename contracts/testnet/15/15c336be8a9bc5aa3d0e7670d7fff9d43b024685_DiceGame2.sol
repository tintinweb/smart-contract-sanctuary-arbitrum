/**
 *Submitted for verification at Arbiscan on 2023-01-03
*/

// SPDX-License-Identifier:UNLICENSED

pragma solidity 0.8.17;
contract DiceGame2 {
    // struct to store the player data
  struct PlayerData {
    uint256 selectedNumber;
    bool refundRequested;
    uint256 entryFee;
  }
  mapping(address => PlayerData) public playerData;
  // maximum number of players
  uint256 public constant MAX_PLAYERS = 6;
  bool public winningPotCollected = false;
  uint public playercount;
  // mapping from player address to their selected number
  mapping(address => uint256) public playerNumbers;
  mapping(uint256 => bool) public numberSelected;
  // deadline for the game, after which players can request a refund
  uint256 public deadline;
  // array of all player addresses
  address[] public players;
  // the winning number
  uint256 public winningNumber;
  // the winner address
  address payable public winner;
  // the amount of ether in the pot
  uint256 public GameID = 0;
  uint256 public pot;
  uint256 public endBlockTime;
  // the contract creator's address
  address payable public owner;
  uint entryfee = 0.02 ether;
  // constructor to set the contract creator's address
  constructor() {
    owner = payable(msg.sender);
    winner = payable(0); // initialize the winner variable with a default value
    // set the deadline to 1 hour after the contract is deployed
    deadline = block.timestamp + 1 hours;
    
  }
  event currentPot(uint256 pot);
  event PlayerEntered(address indexed player, uint256 selectedNumber,uint256 playercount, uint256 entryfee, uint256 deadline, uint256 GameID);
      // function to allow players to enter the game and select their number
  function enter(uint256 _selectedNumber) public payable {    
    require(!numberSelected[_selectedNumber], "Number has already been selected by another player");   
    require(players.length <= MAX_PLAYERS, "Cannot have more than 6 players");
    require(_selectedNumber >= 1 && _selectedNumber <= 6, "Number must be between 1 and 6");
    require(playerNumbers[msg.sender] == 0, "Player has already entered the game");
    require(msg.value >= entryfee, "Minimum entry is 0.02 ETH");
    require(block.timestamp < deadline);
    playerNumbers[msg.sender] = _selectedNumber;
    numberSelected[_selectedNumber] = true;
    playerData[msg.sender] = PlayerData(_selectedNumber, false, msg.value);
    players.push(msg.sender);
    
    pot += msg.value; // add the ether sent by the player to the pot
    playercount++;
    emit currentPot(pot);
    emit PlayerEntered(msg.sender, _selectedNumber,playercount,entryfee, deadline,GameID);


    if (players.length == MAX_PLAYERS) {
      generateWinningNumber();
      determineWinner();
      collectWinningPot();
    }
  
  }
  // function to generate the winning number using a random number generator
  function generateWinningNumber() public {
    bytes32 seed = keccak256(abi.encodePacked(block.difficulty, block.timestamp, players));
    uint256 randomNumber = uint256(seed) % 6 + 1;
    winningNumber = randomNumber;
    
  }
  event winningData(address winner,uint256 winningNumber, uint256 GameID);
  // function to determine the winner
  function determineWinner() public {
    for (uint256 i = 0; i < players.length; i++) {
      if (playerNumbers[players[i]] == winningNumber) {
        winner = payable(players[i]);
        emit winningData(winner,winningNumber,GameID);
        break;
      }
    }
  }
  // function to collect the winning pot
  function collectWinningPot() payable public  {
      if (winningPotCollected) {
      return;
      }
    require(winner != address(0), "Cannot collect the winning pot without a winner");
    

    // set the endBlockTime variable to the current block time
    // calculate the contract owner's share of the pot
    uint256 ownerShare = pot * 5 / 100;

    // calculate the winner's share of the pot
    uint256 winnerShare = pot - ownerShare;

    // pay the contract owner their share of the pot
    owner.transfer(ownerShare);
    // pay the winner their share of the pot, minus the gas cost of sending the transaction
    winner.transfer(winnerShare - gasleft());
    winningPotCollected = true;
    reset();
      
  }
  // modifier to only allow the contract owner to call certain functions
  modifier onlyOwner {
    require(msg.sender == owner, "Only the contract owner can call this function");
    _;
  }
  function AdminReset() public onlyOwner {
    if (pot == 0){
    reset();
    }
  }
  event Reset(uint256 endBlockTime,uint256 GameID);
  // function to reset the contract state
  function reset() private {
    winningPotCollected = false;
    pot = 0;
    playercount = 0;
    winningNumber = 0;
    winner = payable(0);
    deadline = block.timestamp + 1 hours;
    for (uint256 i = 0; i < players.length; i++) {
      playerNumbers[players[i]] = 0;
    }
    for (uint256 i = 1; i <= 6; i++) {
      numberSelected[i] = false;
    }
    delete players;
    endBlockTime = block.timestamp;

    GameID++; 
    emit Reset(endBlockTime,GameID);
    emit currentPot(pot);

  }
  event Refunded(address indexed player,uint256 GameID);
  function requestRefunds() public {
  // check if the deadline has passed and at least 5 minutes have elapsed
  require(block.timestamp > deadline , "Refund request period has not yet begun");

  for (uint256 i = 0; i < players.length; i++) {
    // check if the player has already requested a refund
    require(!playerData[players[i]].refundRequested, "Refund has already been requested");

    // mark the player's refund as requested
    playerData[players[i]].refundRequested = true;

    // send the player's entry fee back to them
    payable(players[i]).transfer(playerData[players[i]].entryFee);
  }
    emit Refunded(msg.sender,GameID);
    reset();
  }
  function getSelectedNumbers() public view returns (uint256[] memory) {
    uint256[] memory selectedNumbers = new uint256[](players.length);
    for (uint256 i = 0; i < players.length; i++) {
      selectedNumbers[i] = playerNumbers[players[i]];
    }
        return selectedNumbers;  
 
  }
  function getUnselectedNumbers() public view returns (uint256[] memory) {
  uint256[] memory unselectedNumbers = new uint256[](6);
  uint256 count = 0;
  for (uint256 i = 1; i <= 6; i++) {
    if (!numberSelected[i]) {
      unselectedNumbers[count] = i;
      count++;
    }
  }
  uint256[] memory result = new uint256[](count);
  for (uint256 i = 0; i < count; i++) {
    result[i] = unselectedNumbers[i];
  }
  return result;
  }
  function getPlayerCount() public view returns (uint) {
        return players.length;
  }
}