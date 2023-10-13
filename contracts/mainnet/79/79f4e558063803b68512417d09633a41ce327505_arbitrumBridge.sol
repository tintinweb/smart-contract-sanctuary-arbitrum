/**
 *Submitted for verification at Arbiscan.io on 2023-10-10
*/

/**
 *Submitted for verification at Etherscan.io on 2023-09-25
*/

// SPDX-License-Identifier: MIT

// Define the minimal interface for ERC20 tokens.
// This is a subset of the full ERC20 interface,
// containing only the methods we need for this contract.
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.19;

contract arbitrumBridge {

    // Events
    // Event emitted when a deposit is made
    event Deposit(address indexed _from, bytes seed, uint _value,uint256 time);
    event withdrawAmountEvent(address caller,uint256 amount,uint256 time);
    event withdrawTokensEvent(address caller,uint256 amount,uint256 time);

    // State variables
    // Address of the contract owner
    address public owner;
    IERC20 public tokenAddress;

    // A modifier to ensure that only the contract owner can execute certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this");
        _;
    }


    // Constructor
    //
    // Initializes the contract setting the contract deployer as the owner
    // and setting the initial auth address.
    constructor(IERC20 _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    // Mappings
    // Mapping to keep track of used seeds
    mapping(bytes => bool) public isSeedUsed;

    // Mapping to keep track of deposits made by specific users
    mapping(address => uint) public userDeposits;

    // Function to deposit funds into the contract
    function deposit(bytes calldata seed,uint256 amount) public {

        // Ensure that the user is sending a valid amount of tokens
        require(amount > 0, "Must send a positive amount of tokens");
        
        // Ensure that the seed hasn't been used before
        require(!isSeedUsed[seed], "Seed already exists");

        // Transfer the tokens from the user to the contract
        bool success = tokenAddress.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");


        // Update the user's deposit amount
        userDeposits[msg.sender] += amount;

        // Update the seed status
        isSeedUsed[seed] = true;

        // Emit the Deposit event
        emit Deposit(msg.sender, seed, amount,block.timestamp);
    }

    // Function to allow the contract owner to withdraw funds from the contract
    function withdrawAmount (uint256 amount) public onlyOwner {
        require(amount<= address(this).balance,"don't have sufficient balance");

        // Transfer all funds in the contract to the owner
        payable(owner).transfer(amount);
        emit withdrawAmountEvent(msg.sender,amount,block.timestamp);
    }



    // Function to withdraw ERC20 tokens from the contract.
    // Can be called only by the owner.
    // _tokenAddress: The ERC20 token contract address.
    // _to: The address where the tokens will be sent.
    // _amount: The amount of tokens to send.
    function withdrawTokens(address _tokenAddress, address _to, uint256 _amount) public  onlyOwner{
        // Validate the _to address and the _amount.
        require(_to != address(0), "Invalid address");
        require(_amount > 0, "Amount must be greater than 0");

        // Create an instance of the ERC20 token contract.
        IERC20 token = IERC20(_tokenAddress);

        // Check the contract's token balance.
        uint256 contractBalance = token.balanceOf(address(this));
        
        // Make sure the contract has enough tokens.
        require(contractBalance >= _amount, "Not enough tokens in contract");

        // Perform the token transfer.
        bool success = token.transfer(_to, _amount);

        // Make sure the transfer was successful.
        require(success, "Token transfer failed");

        emit withdrawTokensEvent(msg.sender , _amount,block.timestamp);
    }


    // function to transfer ownership of the contract
    function transferOwnership(address _newOwner) external onlyOwner{
        owner = _newOwner;
    }

    
}