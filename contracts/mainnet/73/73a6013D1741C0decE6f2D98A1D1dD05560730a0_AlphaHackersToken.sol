/**
 *Submitted for verification at Arbiscan on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AlphaHackersToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private constant walletAddress = 0x91CeBC666E799c89Ef9C963865a1d3F9ed303f75;

    uint256 private constant buyTaxPercentage = 5;
    uint256 private constant sellTaxPercentage = 5;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "Alpha Hackers";
        symbol = "Hack";
        decimals = 18;
        totalSupply = 4000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");

        uint256 taxAmount = calculateSellTax(_value);
        uint256 transferAmount = _value - taxAmount;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[walletAddress] += taxAmount;

        emit Transfer(msg.sender, _to, transferAmount);
        emit Transfer(msg.sender, walletAddress, taxAmount);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");

        uint256 taxAmount = calculateSellTax(_value);
        uint256 transferAmount = _value - taxAmount;

        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[walletAddress] += taxAmount;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);
        emit Transfer(_from, walletAddress, taxAmount);
        return true;
    }

    function calculateSellTax(uint256 _value) private pure returns (uint256) {
        return (_value * sellTaxPercentage) / 100;
    }

    function calculateBuyTax(uint256 _value) private pure returns (uint256) {
        return (_value * buyTaxPercentage) / 100;
    }
}