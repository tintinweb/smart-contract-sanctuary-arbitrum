// ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘ ⌘
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @notice Simple ERC20 token.
/// @author nani.eth (Nani DAO)
contract Token {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed from, address indexed to, uint256 amount);

    string public constant name = "NANI";
    string public constant symbol = unicode"⌘";
    uint256 public constant decimals = 18;
    uint256 public constant totalSupply = 1e27;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() payable {
        balanceOf[tx.origin] = totalSupply;
    }

    function approve(address to, uint256 amount) public payable returns (bool) {
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public payable returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public payable returns (bool) {
        if (msg.sender != from)
            if (allowance[from][msg.sender] != type(uint256).max)
                allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        unchecked { balanceOf[to] += amount; }
        emit Transfer(from, to, amount);
        return true;
    }
}