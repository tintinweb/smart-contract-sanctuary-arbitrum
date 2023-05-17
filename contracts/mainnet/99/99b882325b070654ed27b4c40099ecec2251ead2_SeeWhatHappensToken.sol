/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

// SPDX-License-Identifier: MIT

/*

This token is mostly a test. 
But I'll add a little liquidity and see what happens.
No taxes, but there will be a max tx amount.
Enjoy!

*/

pragma solidity ^0.8.18;

contract SeeWhatHappensToken {
    mapping(address=> uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 110000 * 10 ** 18;
    string public name = "See What Happens Token";
    string public symbol = "SWHT";
    uint public decimals = 18;
    uint public maxTransactionAmount = 100000 * 10 ** 18;
    bool public isTradingEnabled = true;
    address public owner;
    mapping(address => bool) public isExempt;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TradingEnabled();

    constructor() {
        owner = msg.sender;
        isExempt[msg.sender] = true;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public returns(bool) {
    require(isTradingEnabled || isExempt[msg.sender], "Trading is not enabled yet");
    require(balanceOf(msg.sender) >= _value, 'balance too low');
    if (!isExempt[msg.sender]) {
        require(_value <= maxTransactionAmount, 'transaction amount exceeds maximum');
    }
    balances[_to] += _value;
    balances[msg.sender] -= _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
}

function transferFrom(address _from, address _to, uint _value) public returns(bool) {
    require(isTradingEnabled || isExempt[msg.sender], "Trading is not enabled yet");
    require(balanceOf(_from) >= _value, 'balance too low');
    require(allowance[_from][msg.sender] >= _value, 'allowance too low');
    if (!isExempt[msg.sender]) {
        require(_value <= maxTransactionAmount, 'transaction amount exceeds maximum');
    }
    balances[_to] += _value;
    balances[_from] -= _value;
    allowance[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
    return true;
}

    function approve(address _spender, uint _value) public returns(bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    } 

    function renounceOwnership() public {
        require(msg.sender == owner, "Only the owner can renounce ownership");
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address _newOwner) public {
        require(msg.sender == owner, "Only the owner can transfer ownership");
        require(_newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function setTradingEnabled(bool _isTradingEnabled) public {
        require(msg.sender == owner, "Only the owner can set trading enabled");
        isTradingEnabled = _isTradingEnabled;
        if (isTradingEnabled) {
            emit TradingEnabled();
        }
    }

    function setExempt(address _address, bool _isExempt) public {
        require(msg.sender == owner, "Only the owner can set exempt");
        isExempt[_address] = _isExempt;
    }

    function setMaxTransactionAmount(uint _maxTransactionAmount) public {
    require(msg.sender == owner, "Only the owner can set the max transaction amount");
    maxTransactionAmount = _maxTransactionAmount * 10 ** 3 * 10 ** 18;
    }
}