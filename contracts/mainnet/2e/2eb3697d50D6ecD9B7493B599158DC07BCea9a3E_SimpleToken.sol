// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity >=0.7.0 <0.9.0;

contract SimpleToken {
    mapping(address => uint256) public balances;

    function mint(address _to, uint256 _amount) public {
        balances[_to] += _amount;
    }

    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }
}