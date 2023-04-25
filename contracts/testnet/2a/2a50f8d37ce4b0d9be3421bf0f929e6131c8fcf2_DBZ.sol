/**
 *Submitted for verification at Arbiscan on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DBZ {

    string public name = "DBZ Token";
    string public symbol = "DBZ";
    address payable public owner;
    mapping(address => uint256) public balances;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public hardCap = 25 * (10 ** 18);
    uint256 public tokenPrice = 50000 * (10 ** uint256(decimals)); // 50000 DBZ for 1 ETH
    address public unSoldTokensReceiver = 0xeE6984b6E4692d683DEC0e8636983b7230E64769;
    bool public isICOActive;

    constructor() {
        owner = payable(msg.sender);
        isICOActive = true;
        totalSupply = 69420000 * (10 ** uint256(decimals));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function buyTokens() public payable {
        require(isICOActive, "ICO is not active.");
        require(msg.value > 0, "You need to send some ether.");
        require(totalSupply > 0, "All tokens have been sold.");
        require(msg.value <= hardCap, "You can't buy more than the hard cap.");

        uint256 tokensToBuy = msg.value * tokenPrice;
        uint256 tokensAvailable = totalSupply;
        uint256 tokensToSell = tokensToBuy;

        if (tokensToBuy > tokensAvailable) {
            tokensToSell = tokensAvailable;
        }

        totalSupply -= tokensToSell;
        balances[msg.sender] += tokensToSell;

        uint256 etherToRefund = msg.value - (tokensToSell / tokenPrice);
        if (etherToRefund > 0) {
            payable(msg.sender).transfer(etherToRefund);
        }
    }

    function endICO() public onlyOwner {
        require(isICOActive, "ICO is not active.");
        isICOActive = false;
        uint256 unsoldTokens = totalSupply;
        if (unsoldTokens > 0) {
            balances[unSoldTokensReceiver] += unsoldTokens;
            totalSupply -= unsoldTokens;
        }
    }

    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "No ether to withdraw.");
        payable(unSoldTokensReceiver).transfer(address(this).balance);
    }
}