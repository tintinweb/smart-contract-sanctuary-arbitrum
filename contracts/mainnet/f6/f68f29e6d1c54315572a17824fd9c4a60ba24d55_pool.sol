/**
 *Submitted for verification at Arbiscan on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Restakes Risk Pool Contract
// https://www.restakes.io

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}

// Stake with caution, there is no withdrawal function outside of the claim function.
// Paused staking does not affect claiming rewards.

// Visit the Restakes Github for more information and resources.

contract pool {
    address public tokenAddress; // ERC20 being staked.
    address public treasuryAddress = 0x6de77170E1F71B80642D55c29f595aC37b91eBf6; // Treasury.
    address public splitAddress = 0x000000000000000000000000000000000000dEaD; // Burn.
    address public owner; // Contract owner (initialized in constructor as deployer).
    uint256 public rewardPercentage; // Reward generated per hour (as a percentage of staker.amount).
    uint256 public riskModifier; // Additional risk generated per hour (as a flat percentage).
    uint256 public rewardChance; // Risk.
    address public support1 = 0x31d41e78BcE91fdb07FEadfCBAEDD67F43EdE387;
    address public support2 = 0x0F4AEA1865BEf07c405319C87Bf91F800d6DfEbc;

    bool public stakingPaused = false; // Pauses the ability to stake, claiming cannot be paused.

    struct Staker {
        uint256 amount;
        uint256 time;
        uint256 wins;
        uint256 losses;
    }

    mapping(address => Staker) public stakers;

    constructor(address _tokenAddress, uint256 _rewardChance) {
        tokenAddress = _tokenAddress;
        rewardChance = _rewardChance;
        rewardPercentage = 10; // 10 / 1%
        riskModifier = 5000; // 10000 / 1%
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier notPaused() {
        require(!stakingPaused, "The game is currently paused, you cannot play at this time.");
        _;
    }

    // User stakes an amount of tokens, contract stores current time.
    function stakeTokens(uint256 _amount) public notPaused { 
        Staker storage staker = stakers[msg.sender];
        require(_amount > 0, "Amount cannot be zero");
        require(staker.time == 0, "Complete your current staking cycle first.");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        
        staker.amount += _amount;
        if (staker.time == 0) {
            staker.time = block.timestamp; // Set the start time.
        }

        uint256 stakerTime = staker.time;
        emit TokensStaked(msg.sender, _amount, stakerTime);
    }

    event TokensStaked(address indexed staker, uint256 _amount, uint256 time);

    // Users claim their rewards to see if they've won or lost.
    function claimReward() public { 
        Staker memory staker = stakers[msg.sender];
        require(staker.amount > 0, "No tokens staked");
        require(block.timestamp >= staker.time + 0.01 hours, "You need to stake your tokens for a minimum of 1 hour(s), try again soon.");

        uint256 elapsedTime = (block.timestamp - staker.time);
        uint8 decimals = getTokenDecimals(tokenAddress);

        uint256 reward = staker.amount + (staker.amount * elapsedTime * rewardPercentage) / (1000 * 3600);

        uint256 additionalModifier = (staker.amount * (elapsedTime / 3600) * riskModifier) / (10**decimals);
        uint256 currentChance = rewardChance + additionalModifier;

        if (currentChance > 0 && block.timestamp % 1000000 < currentChance) {

            // Transfer fee and clear balance
            uint256 burnAmount = staker.amount / 5;
            uint256 trueBurnAmount = burnAmount / 2;
            uint256 treasuryAmount = burnAmount / 2;
            if (burnAmount > 0) {
                IERC20(tokenAddress).transfer(splitAddress, trueBurnAmount);
                IERC20(tokenAddress).transfer(treasuryAddress, treasuryAmount);
            }

            // Clear stakers balance
            stakers[msg.sender].amount = 0;
            stakers[msg.sender].time = 0;
            stakers[msg.sender].losses += 1;
            emit Loss(msg.sender, reward, currentChance, burnAmount);
        } else {

            // Transfer fee and the rest to the staker
            uint256 splitAmount = reward / 20;
            uint256 stakerAmount = reward - splitAmount;
            
            if (splitAmount > 0) {
                IERC20(tokenAddress).transfer(treasuryAddress, splitAmount);
            }
            if (stakerAmount > 0) {
                IERC20(tokenAddress).transfer(msg.sender, stakerAmount);
            }

            // Clear stakers balance and grant a win.
            stakers[msg.sender].amount = 0;
            stakers[msg.sender].time = 0;
            stakers[msg.sender].wins += 1;
            emit Win(msg.sender, reward, currentChance);
        }
    }

    event Loss(address indexed staker, uint256 reward, uint256 rewardChance, uint256 burnAmount);
    event Win(address indexed staker, uint256 reward, uint256 rewardChance);

    // Update the treasury address.

    function updateTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function updateSplitAddress(address _splitAddress) external onlyOwner { // Update the split address.
        splitAddress = _splitAddress;
    }

    function releaseValve() public onlyOwner { // Remove tokens.
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        IERC20(tokenAddress).transfer(owner, balance);
    }

    function getFullRewardAmount(address _staker) public view returns (uint256) { // Read reward of staker.
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time); // Calculate elapsed time in hours
        uint256 reward = staker.amount + (staker.amount * elapsedTime * rewardPercentage) / (1000 * 3600);
        return reward;
    }

    function getGeneratedRewardAmount(address _staker) public view returns (uint256) { // Read reward of staker.
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time); // Calculate elapsed time in hours
        uint256 reward = (staker.amount * elapsedTime * rewardPercentage) / (1000 * 3600);
        return reward;
    }

    // Get the total risk percentage for a staker's active stake.
    function getCurrentRiskChance(address _staker) public view returns (uint256) {
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time);
        uint8 decimals = getTokenDecimals(tokenAddress);

        uint256 additionalModifier = (staker.amount * (elapsedTime / 3600) * riskModifier) / (10**decimals);
        uint256 currentChance = rewardChance + additionalModifier;
        return currentChance;
    }

    // Get the total risk percentage for a staker's active stake.
    function getDebugRiskChance(address _staker) public view returns (uint256) {
        Staker memory staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        uint256 elapsedTime = (block.timestamp - staker.time);
        uint8 decimals = getTokenDecimals(tokenAddress);

        uint256 additionalModifier = (staker.amount * elapsedTime * riskModifier) / (10**decimals);
        uint256 currentChance = rewardChance + additionalModifier;
        return currentChance;
    }

    // Update the reward percentage.
    function updateRewardPercentage(uint256 _newPercentage) external onlyOwner { 
        rewardPercentage = _newPercentage;
    }

    // Update risk modifier.
    function updateRiskModifier(uint256 _newRiskModifier) external onlyOwner {
        riskModifier = _newRiskModifier;
    }

    // Support Team: Clear a staker and refund their original stake.
    function supportTool(address _staker) public {
        require(msg.sender == support1 || msg.sender == support2, "Only admins can call this function");
        
        Staker storage staker = stakers[_staker];
        require(staker.amount > 0, "No tokens staked");

        // Refund the staker directly, reset their stake data.
        IERC20(tokenAddress).transfer(_staker, staker.amount);
        staker.amount = 0;
        staker.time = 0;
    }

    // Pause staking to make pool contract upgrades seamless. Doesn't affect claiming.
    function pausePool() external onlyOwner {
        stakingPaused = true;
    }
    
    // Resume staking, probably never needed but precautionary include.
    function resumePool() external onlyOwner {
        stakingPaused = false;
    }

    function getTokenDecimals(address _tokenAddress) internal view returns (uint8) {
        IERC20 token = IERC20(_tokenAddress);
        return token.decimals();
    }
}