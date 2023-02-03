/**
 *Submitted for verification at Arbiscan on 2023-02-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CBUToken {
    string public constant name = "CBU Token";
    string public constant symbol = "CBU";
    uint256 public constant totalSupply = 1000;
    uint256 public constant decimals = 0;

    mapping (address => uint256) public balanceOf;
    address public owner;

    constructor() public {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }

    function transferFrom(address _from, address _to, uint256 _value) public {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(_value <= balanceOf[_to], "Insufficient allowance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
    }
}