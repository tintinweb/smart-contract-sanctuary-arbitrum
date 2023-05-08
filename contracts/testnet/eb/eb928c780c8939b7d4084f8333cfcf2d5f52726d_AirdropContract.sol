/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AirdropContract {
    
    uint256 public tokenAmount;
    
    uint256 public maxParticipants;
   
    uint256 public registeredParticipants;
   
    address public tokenContractAddress;
  
    bool public isActive;

   
    event ParticipantRegistered(address participant, uint256 tokens);

    
    modifier onlyActiveAirdrop() {
        require(isActive, "Airdrop is not active");
        _;
    }

    
    modifier onlyBeforeMaxParticipants() {
        require(registeredParticipants < maxParticipants, "Maximum participants reached");
        _;
    }


    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

  
    address public owner;

    
    mapping(address => bool) public hasClaimed;

   
    constructor(uint256 _tokenAmount, uint256 _maxParticipants, address _tokenContractAddress) {
        tokenAmount = _tokenAmount;
        maxParticipants = _maxParticipants;
        tokenContractAddress = _tokenContractAddress;
        owner = msg.sender;
        isActive = true;
    }

  
    function _checkClaimed(address participant) internal view returns (bool) {
        return hasClaimed[participant];
    }


    function register() public onlyActiveAirdrop onlyBeforeMaxParticipants {
        require(!_checkClaimed(msg.sender), "Already claimed");


        require(Token(tokenContractAddress).transferFrom(msg.sender, address(this), tokenAmount), "Token transfer failed");


        registeredParticipants++;

   
        hasClaimed[msg.sender] = true;

   
        emit ParticipantRegistered(msg.sender, tokenAmount);
    }

 
    function stopAirdrop() public onlyOwner {
        isActive = false;
    }


    function withdrawRemainingTokens() public onlyOwner {
        uint256 remainingBalance = Token(tokenContractAddress).balanceOf(address(this));
                require(Token(tokenContractAddress).transfer(owner, remainingBalance), "Token transfer failed");
    }
}


abstract contract Token {
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);
    function balanceOf(address account) external view virtual returns (uint256);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
}