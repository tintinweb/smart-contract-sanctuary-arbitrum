/**
 *Submitted for verification at Arbiscan on 2023-02-02
*/

pragma solidity ^0.8.0;

contract Pisk {
    string public name = "Pisk";
    string public symbol = "PK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 initialSupply) public {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }


    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value && _value > 0, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
}