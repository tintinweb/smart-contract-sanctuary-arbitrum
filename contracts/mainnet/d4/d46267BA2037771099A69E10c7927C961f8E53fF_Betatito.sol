/**
 *Submitted for verification at Arbiscan on 2023-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Betatito {
    address public stakedTokenAddress; // But it’s all fake.
    address public rewardTokenAddress; // Understand what I’m sayin’?
    uint256 public rewardAmountPerToken; // This life. This game.
    uint256 public rewardChance; // There ain’t no love in it.
    address public owner; // It don’t love you back.
    address public burnAddress = 0x000000000000000000000000000000000000dEaD; // PIF.
    bool public gamePaused = false; // Pauses the ability to stake, claiming cannot be paused.

    struct Staker {
        uint256 tokenId;
        uint256 time;
        uint256 quantity;
    }

    mapping(address => Staker) public stakers;
    
    modifier notPaused() {
        require(!gamePaused, "The game is currently paused, you can not play at this time.");
        _;
    }

    constructor(address _stakedTokenAddress, address _rewardTokenAddress, uint256 _rewardAmountPerToken, uint256 _rewardChance) {
        stakedTokenAddress = _stakedTokenAddress;
        rewardTokenAddress = _rewardTokenAddress;
        rewardAmountPerToken = _rewardAmountPerToken;
        rewardChance = _rewardChance;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function stakeToken(uint256 _tokenId) public notPaused {
        require(IERC721(stakedTokenAddress).ownerOf(_tokenId) == msg.sender, "You do not own this token");
        require(stakers[msg.sender].tokenId == 0, "you gotta complete the bounty first");
        stakers[msg.sender].tokenId = _tokenId;
        stakers[msg.sender].time = block.timestamp;
        stakers[msg.sender].quantity = 1;
        IERC721(stakedTokenAddress).transferFrom(msg.sender, address(this), _tokenId);
    }

    function claimReward() public {
        Staker memory staker = stakers[msg.sender];
        require(staker.quantity != 0, "No tokens staked");
        require(block.timestamp >= staker.time + 0.01 hours, "0.01 hours not passed yet");
        require(IERC20(rewardTokenAddress).balanceOf(address(this)) >= rewardAmountPerToken, "Not enough reward tokens");

        if (rewardChance > 0 && block.timestamp % 100 < rewardChance) {
            // Reset the staker's data to 0
            stakers[msg.sender].tokenId = 0;
            stakers[msg.sender].time = 0;
            stakers[msg.sender].quantity = 0;
            emit PepeDied(msg.sender);
        } else {
            // Transfer the staker's reward to them
            if (rewardAmountPerToken > 0) {
                IERC20(rewardTokenAddress).transfer(msg.sender, rewardAmountPerToken);
            }
            // Transfer the staked NFT back to the staker
            IERC721(stakedTokenAddress).transferFrom(address(this), msg.sender, staker.tokenId);
            // Reset the staker's data to 0
            stakers[msg.sender].tokenId = 0;
            stakers[msg.sender].time = 0;
            stakers[msg.sender].quantity = 0;
        }
    }

    event PepeDied(address indexed staker);

    function updateRewardAmountPerToken(uint256 _newRewardAmountPerToken) external onlyOwner {
        rewardAmountPerToken = _newRewardAmountPerToken;
    }
    
    function setBurnAddress(address _burnAddress) external onlyOwner {
        burnAddress = _burnAddress;
    }

    function withdrawRewardTokenBalance() external onlyOwner {
        uint256 balance = IERC20(rewardTokenAddress).balanceOf(address(this));
        require(balance > 0, "No reward token balance to withdraw");
        IERC20(rewardTokenAddress).transfer(msg.sender, balance);
    }

    function pauseGame() external onlyOwner {
        gamePaused = true;
    }
    
    function resumeGame() external onlyOwner {
        gamePaused = false;
    }
}