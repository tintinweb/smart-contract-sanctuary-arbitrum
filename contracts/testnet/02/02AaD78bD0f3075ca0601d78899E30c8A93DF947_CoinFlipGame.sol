/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);
    function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
    function clientWithdrawTo(address _to, uint256 _amount) external;
    function estimateFee(uint256 callbackGasLimit, uint256 confirmations) external view returns (uint256);
    function clientDeposit(address _client) external payable;
}

contract CoinFlipGame {
    address public owner; 
    uint256 public minimumBet; 
    uint256 private constant CONTRACT_FEE_PERCENTAGE = 1; 
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

    constructor() {
        owner = msg.sender;
        minimumBet = 1e17; 
    }

    function placeBet(bool choice) public payable {
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

    function randomizerCallback(uint256 _id, bytes32 _value) external {
        require(msg.sender == address(randomizer), "Caller is not VRF contract!");
        bool result = ((uint256(_value) %2) == 0);
        bool won = (result == bets[_id].choice);
        bets[_id].won = won;
        emit BetResolved(_id, bets[_id].player, bets[_id].amount, bets[_id].choice, result, won);
        
    }

    function cashout(uint256 _id) public {
        require(msg.sender == bets[_id].player, "Only the person who placed the bet can cash out!");
        require(bets[_id].won == true);
        require(bets[_id].paid == false);
        uint256 payout = bets[_id].amount * 2 * (100 - CONTRACT_FEE_PERCENTAGE) / 100;
        require(address(this).balance >= payout, "Insufficient funds in contract to cash out.");
        payable(bets[_id].player).transfer(payout);
        bets[_id].paid = true;
        emit cashedOut(_id, bets[_id].player, bets[_id].amount);
        
    }

    function withdrawContractBalance() public {
        require(msg.sender == owner, "Only the contract owner can withdraw the contract balance");
        payable(owner).transfer(address(this).balance);
    }

    function recieve() external payable {}

}