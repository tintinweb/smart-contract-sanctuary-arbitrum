/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Deam {
	event Approval(address indexed owner, address indexed spender, uint value);
	event Transfer(address indexed from, address indexed to, uint value);
	address public owner;
	mapping(address => uint) private _balances;
	mapping(address => mapping(address => uint)) private _allowance;
	
	uint 	public totalSupply = 0;
	string  public name;
	string  public symbol;
	uint8   public constant decimals = 18;

    constructor (string memory _name, string memory _symbol, uint _initialMint) {
		name = _name;
		symbol = _symbol;
		_mint(msg.sender, _initialMint);
	}

	function balanceOf(address account) public view returns (uint) {
		return _balances[account];
	}

	function allowance(address account, address spender) public view returns (uint) {
		return _allowance[account][spender];
	}

    function transfer(address recipient, uint amount) public returns (bool) {
		_transfer(msg.sender, recipient, amount);
		return true;
	}

	function approve(address spender, uint amount) public returns (bool) {
		_approve(msg.sender, spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
		require(_allowance[sender][msg.sender] >= amount, 'ERC20: transfer amount exceeds _allowance');
		_approve(sender, msg.sender, _allowance[sender][msg.sender] - amount);
		_transfer(sender, recipient, amount);
		return true;
	}

	function burn(uint amount) external {
		_burn(msg.sender, amount);
	}
	
	function increaseAllowance(address spender, uint addedValue) public  returns (bool) {
		uint c = _allowance[msg.sender][spender] + addedValue;
		require(c >= addedValue, "ERC20: addition overflow");
		_approve(msg.sender, spender, c);
		return true;
	}

	function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
		require(_allowance[msg.sender][spender] >= subtractedValue, 'ERC20: decreased _allowance below zero');
		_approve(msg.sender, spender, _allowance[msg.sender][spender] - subtractedValue);
		return true;
	}

	function _transfer(address sender, address recipient, uint amount) internal {
		require(sender != address(0), 'ERC20: transfer from the zero address');
		require(recipient != address(0), 'ERC20: transfer to the zero address');
		require(_balances[sender] >= amount, 'ERC20: transfer amount exceeds balance');
		_balances[sender] -= amount;
		uint c = _balances[recipient] + amount;
		require(c >= amount, "ERC20: addition overflow");
		_balances[recipient] = c;
		emit Transfer(sender, recipient, amount);
	}

	function _mint(address account, uint amount) internal {
		require(account != address(0), 'ERC20: mint to the zero address');
		uint c = totalSupply + amount;
		require(c <= type(uint256).max, "ERC20: total supply overflow");
		totalSupply = c;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint amount) internal {
		require(account != address(0), 'ERC20: burn from the zero address');
		require(_balances[account] >= amount, 'ERC20: burn amount exceeds balance');
		_balances[account] -= amount;
		totalSupply -= amount;
		emit Transfer(account, address(0), amount);
	}

	function _approve(address account, address spender, uint amount) internal {
		require(account != address(0), 'ERC20: approve from the zero address');
		require(spender != address(0), 'ERC20: approve to the zero address');
		_allowance[account][spender] = amount;
		emit Approval(account, spender, amount);
	}
}

contract WrappedDeam is Deam {
    constructor () Deam("Wrapped Deam", "WDEAM", 1e9 * 1e18) {}
}