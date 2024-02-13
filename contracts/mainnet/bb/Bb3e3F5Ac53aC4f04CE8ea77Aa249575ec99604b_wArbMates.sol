// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
    Wrapped ArbMates (wMate)

    X: https://twitter.com/ArbMates
	TG: https://t.me/ArbMatesPortal

*/

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface AM {
	function balanceOf(address) external view returns (uint256);
	function allowance(address, address) external view returns (uint256);
	function isApprovedForAll(address, address) external view returns (bool);
	function transfer(address _to, uint256 _tokens) external returns (bool);
	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool);
}


contract wArbMates {

	uint256 constant private UINT_MAX = type(uint256).max;

	AM constant public arbmates = AM(0x1eA354af25EBC73DE2f520517bE6b2C959623983);

	string constant public name = "Wrapped ArbMates";
	string constant public symbol = "wMate";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		mapping(address => User) users;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Wrap(address indexed owner, uint256 tokens);
	event Unwrap(address indexed owner, uint256 tokens);


	function wrap(uint256 _tokensOrTokenId) external {
		uint256 _balanceBefore = arbmates.balanceOf(address(this));
		arbmates.transferFrom(msg.sender, address(this), _tokensOrTokenId);
		uint256 _wrapped = arbmates.balanceOf(address(this)) - _balanceBefore;
		require(_wrapped > 0);
		info.users[msg.sender].balance += _wrapped * 1e18;
		emit Transfer(address(0x0), msg.sender, _wrapped * 1e18);
		emit Wrap(msg.sender, _wrapped);
	}

	function unwrap(uint256 _tokens) external {
		require(_tokens > 0);
		require(balanceOf(msg.sender) >= _tokens * 1e18);
		info.users[msg.sender].balance -= _tokens * 1e18;
		arbmates.transfer(msg.sender, _tokens);
		emit Transfer(msg.sender, address(0x0), _tokens * 1e18);
		emit Unwrap(msg.sender, _tokens);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		uint256 _allowance = allowance(_from, msg.sender);
		require(_allowance >= _tokens);
		if (_allowance != UINT_MAX) {
			info.users[_from].allowance[msg.sender] -= _tokens;
		}
		return _transfer(_from, _to, _tokens);
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}
	

	function totalSupply() public view returns (uint256) {
		return arbmates.balanceOf(address(this)) * 1e18;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) external view returns (uint256 totalTokens, uint256 userMates, uint256 userAllowance, bool userApprovedForAll, uint256 userBalance) {
		totalTokens = totalSupply();
		userMates = arbmates.balanceOf(_user);
		userAllowance = arbmates.allowance(_user, address(this));
		userApprovedForAll = arbmates.isApprovedForAll(_user, address(this));
		userBalance = balanceOf(_user);
	}


	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		unchecked {
			require(balanceOf(_from) >= _tokens);
			info.users[_from].balance -= _tokens;
			info.users[_to].balance += _tokens;
			emit Transfer(_from, _to, _tokens);
			return true;
		}
	}
}