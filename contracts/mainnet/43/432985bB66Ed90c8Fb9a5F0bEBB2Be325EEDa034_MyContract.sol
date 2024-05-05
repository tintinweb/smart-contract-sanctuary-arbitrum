// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256); // Added balanceOf function
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MyContract {
    address payable owner;
    mapping(address => uint256) tokenBalances; 

    event Withdraw(address indexed _from, address indexed _to, uint256 _value);
    event SecurityUpdate(address indexed _owner, uint256 _amount);
    event TokensReceived(address indexed _from, uint256 _value);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function withdraw(uint256 _amount) public payable onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        owner.transfer(_amount);
        emit Withdraw(address(this), owner, _amount);
    }

    function securityUpdate() public payable onlyOwner {
        emit SecurityUpdate(msg.sender, msg.value);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function transfer(address payable _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        require(_amount <= address(this).balance, "Insufficient balance");

        _to.transfer(_amount);
        emit Withdraw(address(this), _to, _amount);
    }

    function receiveTokens(address _token, uint256 _value) public {
        require(_token != address(0), "Invalid token address");
        require(_value > 0, "Invalid token value");

        ERC20 token = ERC20(_token);
        require(token.transferFrom(msg.sender, address(this), _value), "Token transfer failed");

        tokenBalances[_token] += _value;
        emit TokensReceived(msg.sender, _value);
    }

    function getTokenBalance(address _token) public view returns (uint256) {
        return tokenBalances[_token];
    }

    function transferTokens(address _token, address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        require(_amount <= tokenBalances[_token], "Insufficient token balance");

        ERC20 token = ERC20(_token);
        require(token.transfer(_to, _amount), "Token transfer failed");

        tokenBalances[_token] -= _amount;
        emit Withdraw(address(this), _to, _amount);
    }

    function approve(address _token, address _spender, uint256 _amount) public onlyOwner {
        ERC20 token = ERC20(_token);
        require(token.approve(_spender, _amount), "Approval failed");
    }
    function balanceOf(address _token, address _account) public view returns (uint256) {
    ERC20 token = ERC20(_token);
    return token.balanceOf(_account);
    }
}