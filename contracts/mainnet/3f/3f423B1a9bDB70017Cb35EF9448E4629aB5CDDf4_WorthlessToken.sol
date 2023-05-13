/**
 *Submitted for verification at Arbiscan on 2023-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract WorthlessToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    constructor() {
        name = "Worthless";
        symbol = "WORTH";
        totalSupply = 69420420420 * 10**18;
        balanceOf[msg.sender] = totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier validRecipient(address _recipient) {
        require(_recipient != address(0x0) && _recipient != address(this));
        _;
    }

    function transfer(address _to, uint256 _value) public validRecipient(_to) returns (bool) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
}