/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CRYPTODOGE {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint8 public decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Claim(address indexed to, uint256 value);

    constructor() {
        name = "CRYPTODOGE";
        symbol = "CRYPTODOGE";
        decimals = 18;
        totalSupply = 1000000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        uint256 _burnAmount = (_value * 10) / 100;
        uint256 _transferAmount = _value - _burnAmount;

        balanceOf[_from] -= _value;
        balanceOf[_to] += _transferAmount;
        balanceOf[address(0)] += _burnAmount;

        emit Transfer(_from, _to, _transferAmount);
        emit Burn(_from, _burnAmount);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function claimAirdrop() public returns (bool success) {
        uint256 _claimableTokens = (totalSupply * 40) / 100;
        uint256 _claimAmount = (_claimableTokens * 1) / 10000; // 0.01% от 40%

        require(_claimableTokens > 0, "No tokens available for claiming");
        require(balanceOf[address(this)] >= _claimAmount, "Not enough tokens in the contract");

        balanceOf[address(this)] -= _claimAmount;
        balanceOf[msg.sender] += _claimAmount;

        emit Transfer(address(this), msg.sender, _claimAmount);
        emit Claim(msg.sender, _claimAmount);

        return true;
    }
}