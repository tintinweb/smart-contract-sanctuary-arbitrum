/**
 *Submitted for verification at Arbiscan on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract GSHP {
    string public name = "GSHP";
    string public symbol = "GSHP";
    uint256 public totalSupply = 0;
    uint8 public decimals = 18;
    uint256 public constant MAX_MINTS_PER_USER = 10;
    uint256 public constant MAX_MINTS_PER_TX = 10;
    uint256 public constant MINT_PRICE = 0.001 ether;

    address public owner;
    address public tokenAddress;
    bool public mintingStarted;
    bool public mintingEnded;

    mapping(address => uint256) public mintedCount;

    event Mint(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
    }

    function startMinting() external onlyOwner {
        require(!mintingStarted, "Minting has already started");
        mintingStarted = true;
    }

    function endMinting() external onlyOwner {
        require(mintingStarted, "Minting has not started yet");
        mintingEnded = true;
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available to withdraw");
        payable(owner).transfer(balance);
    }

    function mint(uint256 amount) external payable {
        require(mintingStarted, "Minting has not started yet");
        require(!mintingEnded, "Minting has ended");
        require(amount > 0 && amount <= MAX_MINTS_PER_TX, "Invalid mint amount");
        require(msg.value == amount * MINT_PRICE, "Incorrect payment amount");

        uint256 remainingMints = MAX_MINTS_PER_USER - mintedCount[msg.sender];
        require(remainingMints > 0, "You have reached the maximum mint limit");

        uint256 availableMints = amount > remainingMints ? remainingMints : amount;
        uint256 tokensToMint = availableMints * 100000;

        IERC20(tokenAddress).transfer(msg.sender, tokensToMint);
        mintedCount[msg.sender] += availableMints;
        totalSupply += tokensToMint;

        emit Mint(msg.sender, tokensToMint);
    }
}