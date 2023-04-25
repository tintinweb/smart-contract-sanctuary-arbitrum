/**
 *Submitted for verification at Arbiscan on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DBZToken {
    string public name = "DBZ Token";
    string public symbol = "DBZ";
    uint8 public decimals = 18;
    uint256 public totalSupply = 0;
    uint256 public maxSupply = 69420000 * 10 ** decimals;
    uint256 public tokenPrice = 50000; // DBZ tokens per ETH
    uint256 public hardCap = 25 ether;
    address payable public owner;
    address payable public wallet = payable(0xeE6984b6E4692d683DEC0e8636983b7230E64769);
    mapping(address => uint256) public balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event TokensPurchased(address indexed purchaser, uint256 value, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
    
    constructor() {
        owner = payable(msg.sender);
    }
    
    function buyTokens() public payable {
        require(msg.value > 0, "You must send some ether to purchase tokens.");
        require(totalSupply < maxSupply, "The maximum supply of tokens has been reached.");
        require(msg.value <= hardCap, "The amount sent exceeds the hard cap for this sale.");
        
        uint256 tokens = msg.value * tokenPrice;
        require(totalSupply + tokens <= maxSupply, "The purchase would exceed the maximum supply of tokens.");
        
        balances[msg.sender] += tokens;
        totalSupply += tokens;
        
        emit Transfer(address(0), msg.sender, tokens);
        emit TokensPurchased(msg.sender, msg.value, tokens);
        
        wallet.transfer(msg.value);
    }
    
    function remainingTokens() public view returns (uint256) {
        return maxSupply - totalSupply;
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        wallet.transfer(balance);
    }
}