/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
// LedgerLuck Arbitrum Goerli PoC for COS471

pragma solidity ^0.8.0;

// Interface for Randomizer.ai VRF
interface IRandomizer {
    function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256);
    function clientDeposit(address _client) external payable;
}

contract CoinFlipGame {
    // owner of the contract
    address public owner; 
    // minimum bet amount in wei
    uint256 public minimumBet; 
    // percentage of the bet that goes to the contract
    uint256 private constant CONTRACT_FEE_PERCENTAGE = 1; 
    // Randomizer.ai on Arbitrum Goerli 
    IRandomizer public randomizer = IRandomizer(0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc);

    struct Bet {
        address player;
        uint256 amount;
        bool choice;
        bool won;
        bool paid;
    }

    mapping (uint256 => Bet) private bets; // mapping of bet IDs to bets

    event BetPlaced(uint256 betId, address player, uint256 amount, bool choice);
    event BetResolved(uint256 betId, address player, uint256 amount, bool choice, bool result, bool won);
    event cashedOut(uint256 betId, address player, uint256 amount);
    event contractReplenished(address user, uint256 amount);


    constructor() {
        owner = msg.sender;
        minimumBet = 1e16; // set minimum bet to 0.01 ether
    }

    // Only the owner can call functions with this modifier 
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the contract owner!");
        _;
    }

    // Flip a coin. Head is true, tails is false
    function placeBet(bool choice) public payable {
        // Estimate the VRF fee and revert if user cannot cover the fee 
        uint256 vrffee = getVRFFee();
        require(msg.value >= (minimumBet + vrffee), "Bet amount or VRF Fee is too low!"); 
        randomizer.clientDeposit{value: vrffee}(address(this));

        uint256 betId = randomizer.request(500000, 4);
        bets[betId] = Bet(msg.sender, (msg.value - vrffee), choice, false, false);

        emit BetPlaced(betId, msg.sender, (msg.value - vrffee), choice);
    }

    function getVRFFee() public view returns (uint256 fee) {
        fee = (IRandomizer(randomizer).estimateFee(500000, 4) * 125) / 100;
        return fee;
    }

    // Function called by the VRF contract. Resolves the bet. 
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        // Require caller to be VRF contract 
        require(msg.sender == address(randomizer), "Caller is not VRF contract!");
        // Determine a win or loss 
        bool result = ((uint256(_value) %2) == 0);
        bool won = (result == bets[_id].choice);
        // Log results and emit event
        bets[_id].won = won;
        emit BetResolved(_id, bets[_id].player, bets[_id].amount, bets[_id].choice, result, won);
        
    }

    // Cash out a winning bet
    function cashout(uint256 _id) public {
        // Only the player who placed the bet can cashout 
        require(msg.sender == bets[_id].player, "Only the person who placed the bet can cash out!");
        // Require a win to cashout
        require(bets[_id].won == true);
        // Check if user has already cashed this bet out
        require(bets[_id].paid == false);
        // Check if the contract has enough funds to pay out 
        uint256 payout = bets[_id].amount * 2 * (100 - CONTRACT_FEE_PERCENTAGE) / 100;
        require(address(this).balance >= payout, "Insufficient funds in contract to cash out.");
        // Pay out and update bet struct
        bets[_id].paid = true;
        payable(bets[_id].player).transfer(payout);
        emit cashedOut(_id, bets[_id].player, bets[_id].amount);
        
    }

    // Allows owners to withdraw the funds stored in the contract in case of emergency 
    function withdrawContractBalance() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    // Allows the contract owner to change the minimum bet amount
    function setMinimumBet(uint256 _minimumBet) external onlyOwner {
        minimumBet = _minimumBet;
    }

    // Allows contract to receive Ether
    receive() external payable {
        emit contractReplenished(msg.sender, msg.value);
    }

}