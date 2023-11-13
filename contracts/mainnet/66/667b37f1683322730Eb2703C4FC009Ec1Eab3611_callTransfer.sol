/**
 *Submitted for verification at Arbiscan.io on 2023-11-09
*/

// SPDX-License-Identifier: MIT

// Define the minimal interface for ERC20 tokens.
// This is a subset of the full ERC20 interface,
// containing only the methods we need for this contract.
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.19;

contract callTransfer {

    // Events
    // Event emitted when a sendToken is made
    event sendTokenEvent(address indexed _from, bytes seed, uint _value);
    // Event emitted when a new aut address set
    event setAuthAddressEvent(address callerAddress,address authAddress);


    // State variables
    // Address of the contract owner
    address public owner;
    address public tokenAddress;
    address public authAddress;

    // A modifier to ensure that only the contract owner can execute certain functions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can execute this");
        _;
    }

    // A modifier to ensure that only the Auth address can execute certain functions
    modifier onlyAuth() {
        require(msg.sender == authAddress, "Only owner can execute this");
        _;
    }

    // Constructor
    // Initializes the contract setting the contract deployer as the owner
    // and setting the initial auth address.
    constructor(address _tokenAddress, address _authAddress) {
        owner = msg.sender;
        tokenAddress= _tokenAddress;
        authAddress = _authAddress;
    }

    // Mappings
    // Mapping to keep track of used seeds
    mapping(bytes => bool) public isSeedUsed;

    // Mapping to keep track of deposits made by specific users
    mapping(address => uint) public userDeposits;

    // Function to deposit funds into the contract
    function sendToken(bytes calldata seed,address userAddress,uint256 amount) public onlyAuth {
        // Ensure that the user is sending ether with the transaction
        require(amount > 0, "Must send token amount");
        
        // Ensure that the seed hasn't been used before
        require(!isSeedUsed[seed], "Seed already exists");

        //call transfer function
        IERC20(tokenAddress).transfer(userAddress,amount);

        // Update the user's deposit amount
        userDeposits[msg.sender] += amount;

        // Update the seed status
        isSeedUsed[seed] = true;

        // Emit the Deposit event
        emit sendTokenEvent(msg.sender, seed, amount);
    }


    // Function to allow the contract owner to withdraw all funds from the contract
    function withdrawAll() public onlyOwner {
        // Transfer all funds in the contract to the owner
        payable(owner).transfer(address(this).balance);
    }


    // Function to withdraw ERC20 tokens from the contract.
    // Can be called only by the owner.
    // _tokenAddress: The ERC20 token contract address.
    // _to: The address where the tokens will be sent.
    // _amount: The amount of tokens to send.
    function withdrawTokens(address _tokenAddress, address _to, uint256 _amount) public onlyOwner {
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
    }


    // function to transfer ownership of the contract
    function transferOwnership(address _newOwner) external onlyOwner  {
        owner = _newOwner;
    }

    function setAuthAddress(address _address) external onlyOwner {
        require(_address != address(0));
        authAddress = _address;
        emit setAuthAddressEvent( msg.sender,_address );
    }
}