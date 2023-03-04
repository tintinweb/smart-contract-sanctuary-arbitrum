/**
 *Submitted for verification at Arbiscan on 2023-03-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Benzozaphasti {
    string public name = "Benzozaphasti";
    string public symbol = "bnz";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000 * (10**uint256(decimals));
    address public constant owner = 0xB4264E181207E2e701f72331E0998c38e04c8512;

    mapping (address => uint256) public balanceOf;

    constructor() {
        balanceOf[owner] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Not enough balance");
        require(to != address(0), "Invalid address");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);

        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}