/**
 *Submitted for verification at Arbiscan on 2023-04-29
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract OppaiAI {
    string public name = "OppaiAI";
    string public symbol = "OPAI";
    uint256 public totalSupply = 100000000 * 10**18; // 100 million tokens
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public buyRate = 100;
    uint256 public sellRate = 100;
    uint256 public taxPercentage = 4;

    address private owner; // made owner address private
    uint256 private maxSellPercentage = 65; // added max sell percentage

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Buy(address indexed buyer, uint256 amount, uint256 cost);
    event Sell(address indexed seller, uint256 amount, uint256 reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");

        uint256 tax = _value * taxPercentage / 100;
        uint256 amountAfterTax = _value - tax;

        balanceOf[_from] -= _value;
        balanceOf[_to] += amountAfterTax;

        emit Transfer(_from, _to, amountAfterTax);
        if (tax > 0) {
            balanceOf[owner] += tax;
            emit Transfer(_from, owner, tax);
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function buy() public payable {
        require(msg.value > 0, "Invalid amount");
        uint256 amount = msg.value * buyRate;
        _transfer(address(this), msg.sender, amount);
        emit Buy(msg.sender, amount, msg.value);
    }

    function sell(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "Insufficient balance");

        uint256 maxSellAmount = (balanceOf[msg.sender] * maxSellPercentage) / 100; // added max sell amount
        require(_amount <= maxSellAmount, "Exceeds max sell percentage"); // added max sell amount check

        uint256 reward = _amount / sellRate;
        require(reward > 0, "Invalid amount");
        _transfer(msg.sender, address(this), _amount);
        payable(msg.sender).transfer(reward);
        emit Sell(msg.sender, _amount, reward);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
    payable(owner).transfer(_amount);
    }    }