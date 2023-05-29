/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AIX {
    string public name = "test";
    string public symbol = "test";
    uint256 public totalSupply = 1000000;
    uint8 public decimals = 18;
    
    address public TESTY = 0x621e6B4B9Ee21273BD8Ed9D029459f3Aa35f7D2e; // test wallet
    
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public dividendBalanceOf;
    
    uint256 public dividendPerToken;
    uint256 public totalDividendPoints;
    uint256 public lastTotalSupply;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Dividend(address indexed from, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        lastTotalSupply = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) private {
        require(_to != address(0), "Invalid address");
        uint256 tax = _value / 50; // 2% tax
        balanceOf[_from] -= _value;
        balanceOf[_to] += (_value - tax);
        uint256 dividend = tax / 2; // 2% of tax distributed as dividends
        dividendBalanceOf[_from] += dividend * lastTotalSupply / totalSupply;
        totalDividendPoints += dividend * 10**18 / totalSupply;
        balanceOf[TESTY] += tax / 2; // 2% of tax goes to Testy's wallet
        lastTotalSupply = totalSupply;
        emit Transfer(_from, _to, _value);
        emit Dividend(_from, dividend);
    }
    
    function claimDividend() public {
        uint256 owed = dividendBalanceOf[msg.sender];
        require(owed > 0, "No dividend owed");
        dividendBalanceOf[msg.sender] = 0;
        payable(msg.sender).transfer(owed);
    }
    
    function buy() public payable {
        uint256 amount = msg.value;
        require(amount > 0, "Invalid amount");
        uint256 tokens = amount * 100; // 1 ETH = 100 AIX
        _transfer(address(this), msg.sender, tokens);
    }
    
    function sell(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        uint256 amount = _value / 100; // 1 AIX = 0.01 ETH
        _transfer(msg.sender, address(this), _value);
        payable(msg.sender).transfer(amount);
    }
}