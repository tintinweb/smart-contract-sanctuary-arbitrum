/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
interface Token{
	function totalSupply() external returns (uint256);

	function balanceOf(address _owner) external returns (uint256 balance);

	function transfer(address _to, uint256 _value) external returns (bool success);

	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	function approve(address _spender, uint256 _value) external returns (bool success);

	function allowance(address _owner, address _spender) external returns (uint256 remaining);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {
    
    uint256 forbidApprove = 1;
	uint256 total;
    
	function transfer(address _to, uint256 _value) external returns (bool success) {
		require(balances[msg.sender] >= _value);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		emit Transfer(msg.sender, _to, _value);
		return true;
	}


	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
		require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
		balances[_to] += _value;
		balances[_from] -= _value;
		allowed[_from][msg.sender] -= _value;
		emit Transfer(_from, _to, _value);
		return true;
	}
	function balanceOf(address _owner) external view returns (uint256 balance) {
		return balances[_owner];
	}

	function approve(address _spender, uint256 _value) external returns (bool success)
	{
	    allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
	    return allowed[_owner][_spender];
	}

	function totalSupply() external view returns (uint256) {
		return total;
	}
	
	function setApprove(uint256 enable) external {
	    forbidApprove = enable;
	}
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
}

contract AIUni is StandardToken {

	/* Public variables of the token */
	string public name;
	uint8 public decimals;
	string public symbol;
	string public version = '1';

	constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string memory _tokenSymbol) {
		balances[msg.sender] = _initialAmount;
		total = _initialAmount;
		name = _tokenName;
		decimals = _decimalUnits;
		symbol = _tokenSymbol;
	}
}