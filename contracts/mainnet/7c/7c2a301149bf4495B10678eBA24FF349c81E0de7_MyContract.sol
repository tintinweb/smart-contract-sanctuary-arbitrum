// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MyContract {
    address payable owner;
    mapping(address => uint256) tokenBalances; // Mapping of token balances for each user

    event Withdraw(address indexed _from, address indexed _to, uint256 _value);
    event SecurityUpdate(address indexed _from, uint256 _amount);
    event TokensReceived(address indexed _from, uint256 _value);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Function to withdraw Ether from the contract
    function withdraw(uint256 _amount) public payable onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        owner.transfer(_amount);
        emit Withdraw(address(this), owner, _amount);
    }

    // Function to deposit Ether into the contract
    function securityUpdate() public payable onlyOwner {
        // No need to update balance, Ether is directly transferred to contract
        emit SecurityUpdate(msg.sender, msg.value);
    }

    // Function to get the contract owner
    function getOwner() public view returns (address) {
        return owner;
    }

    // Function to get the balance of Ether held by the contract
    function getEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to transfer Ether from this contract to another address
    function transfer(address payable _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        require(_amount <= address(this).balance, "Insufficient balance");

        _to.transfer(_amount);
        emit Withdraw(address(this), _to, _amount);
    }

    // Function to receive ERC20 tokens
    function receiveTokens(address _token, uint256 _value) public {
        require(_token != address(0), "Invalid token address");
        require(_value > 0, "Invalid token value");

        ERC20 token = ERC20(_token);
        require(token.transfer(address(this), _value), "Token transfer failed");

        // Update the token balance of the sender
        tokenBalances[msg.sender] += _value;
        emit TokensReceived(msg.sender, _value);
    }

    // Function to get the token balance of a user
    function getTokenBalance(address _user) public view returns (uint256) {
        return tokenBalances[_user];
    }

    // Function to transfer ERC20 tokens from this contract to another address
    function transferTokens(address _token, address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        require(_amount <= tokenBalances[address(this)], "Insufficient token balance");

        ERC20 token = ERC20(_token);
        require(token.transfer(_to, _amount), "Token transfer failed");

        // Update the token balance of the contract
        tokenBalances[address(this)] -= _amount;
        emit Withdraw(address(this), _to, _amount);
    }
}