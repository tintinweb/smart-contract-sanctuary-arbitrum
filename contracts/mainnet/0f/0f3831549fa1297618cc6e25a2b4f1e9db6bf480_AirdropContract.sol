/**
 *Submitted for verification at Arbiscan.io on 2024-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function status(uint256 tokenId) external view returns (uint8);
}

contract AirdropContract {
    // Define the event to be emitted
    event ClaimReward(address indexed recipient, uint256 number1, uint256 number2, uint256 amount);

    // Rewards Token address (ARB)
    address public tokenAddress = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address public nftContractAddress = 0x133CAEecA096cA54889db71956c7f75862Ead7A0;
    uint256 public affiliateId = 8334;
    address public admin;
    bool public paused;

    // Mapping to track claimed rewardIds for each recipient
    mapping(address => mapping(uint256 => bool)) public recipientRewardTracker;

    constructor() {
        admin = msg.sender;
        paused = false;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    // Modifier to check if the contract is not paused
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    // Function to pause or unpause the contract, only callable by the admin
    function setPause(bool _paused) external onlyAdmin whenNotPaused {
        paused = _paused;
    }

    function claimReward(address recipient, uint256 tokenId, uint256 rewardId) external onlyAdmin {
        // Check if the recipient owns an NFT
        require(IERC721(nftContractAddress).balanceOf(recipient) >= 1, "Recipient does not own a Fiat24 NFT");
        
        // Check if the recipient in fact owns the provided tokenId
        require(IERC721(nftContractAddress).ownerOf(tokenId) == recipient, "Recipient does not own the NFT with the specified tokenId");

        // Check the status of the NFT (5 = KYC completed)
        require(IERC721(nftContractAddress).status(tokenId) == 5, "NFT status is not 5");

        uint256 amount;
        // Determine the amount based on the rewardId
        if (rewardId == 1) {
            amount = 10 * 10**18;
        } else if (rewardId == 2) {
            amount = 20 * 10**18;
        } else if (rewardId == 3) {
            amount = 10 * 10**18;
        } else if (rewardId == 4) {
            amount = 10 * 10**18;
        } else {
            revert("Invalid rewardId");
        }

        // Check if the recipient has already used this rewardId
        require(!recipientRewardTracker[recipient][rewardId], "RewardId already claimed by recipient");

        // Mark the rewardId as used for the recipient
        recipientRewardTracker[recipient][rewardId] = true;

        // Emit the event
        emit ClaimReward(recipient, tokenId, affiliateId, amount);

        // Call the transferFrom method of the token
        IERC20(tokenAddress).transferFrom(msg.sender, recipient, amount);
    }
}