/**
 *Submitted for verification at Arbiscan on 2023-05-23
*/

pragma solidity ^0.8.0;

contract Chicken {
    string public name = "Chicken Coin";
    string public symbol = "Chicken";
    uint8 public decimals = 18;
    uint256 public totalSupply = 420_000_000_000_000 * 10**uint(decimals);
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");
        require(_value <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(_value > 0, "Invalid amount");
        require(_value <= balances[_from], "Insufficient balance");
        require(_value <= allowances[_from][msg.sender], "Insufficient allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid address");
        require(balances[msg.sender] >= _value, "Insufficient balance");

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }
}