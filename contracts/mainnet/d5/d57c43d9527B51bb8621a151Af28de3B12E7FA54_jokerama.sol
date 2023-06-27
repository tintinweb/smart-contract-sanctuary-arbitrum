/**
 *Submitted for verification at Arbiscan on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract jokerama {
    address public tokenAddress;
    uint256 public lossChance;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD; // default burn address
    address public owner;

    struct Staker {
        uint256 amount;
        uint256 time;
        uint256 gamesPlayed;
        uint256 totalWinnings;
    }

    struct LeaderboardEntry {
        address stakerAddress;
        uint256 gamesPlayed;
        uint256 totalWinnings;
    }

    LeaderboardEntry[] public leaderboard;

    mapping(address => Staker) public stakers;

    // Events
    event Stake(address indexed user, uint256 amount);
    event Win(address indexed user, uint256 trueReward, uint256 winnerFee);
    event Loss(address indexed user, uint256 playerTokens, uint256 burn);

    constructor(address _tokenAddress, uint256 _lossChance) {
        tokenAddress = _tokenAddress;
        lossChance = _lossChance;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function stakeTokens(uint256 _amount) public {
        require(_amount > 0, "Amount cannot be zero");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        Staker storage staker = stakers[msg.sender];
        if (staker.amount > 0) {
            claimReward();
        }
        
        staker.amount += _amount;
        staker.time = block.timestamp;

        emit Stake(msg.sender, _amount);
        handleRewards();
    }

    function claimReward() public {
        require(stakers[msg.sender].amount > 0, "No tokens staked");
        handleRewards();
    }

    function handleRewards() private {
        Staker storage staker = stakers[msg.sender];
        staker.gamesPlayed += 1;
        uint256 reward = staker.amount * 3;
        uint256 winnerFee = reward / 20;
        uint256 trueReward = reward - winnerFee;
        uint256 burn = staker.amount / 10;
        uint256 playerTokens = staker.amount;

        if (lossChance > 0 && block.timestamp % 100 < lossChance) {
            IERC20(tokenAddress).transfer(burnAddress, burn);
            resetStaker();
            emit Loss(msg.sender, playerTokens, burn);
        } else {
            if (reward > 0) {
                IERC20(tokenAddress).transfer(burnAddress, winnerFee);
                IERC20(tokenAddress).transfer(msg.sender, trueReward);
                staker.totalWinnings += trueReward;
                updateLeaderboard(msg.sender);
                emit Win(msg.sender, trueReward, winnerFee);
            }
            resetStaker();
        }
    }

    function resetStaker() private {
        stakers[msg.sender].amount = 0;
        stakers[msg.sender].time = 0;
    }

    function updateLeaderboard(address stakerAddress) private {
        Staker storage staker = stakers[stakerAddress];
        LeaderboardEntry memory newEntry = LeaderboardEntry(stakerAddress, staker.gamesPlayed, staker.totalWinnings);

        for(uint i = 0; i < leaderboard.length; i++){
            if(newEntry.totalWinnings > leaderboard[i].totalWinnings){
                leaderboard.push(leaderboard[leaderboard.length - 1]);
                for(uint j = leaderboard.length - 2; j > i; j--){
                    leaderboard[j] = leaderboard[j-1];
                }
                leaderboard[i] = newEntry;
                break;
            }
        }
        if(leaderboard.length > 8){
            leaderboard.pop();
        }
    }

    function getLeaderboard() public view returns(LeaderboardEntry[] memory){
        return leaderboard;
    }

    function checkOverflow() public onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "Contract has no balance");
        IERC20(tokenAddress).transfer(owner, balance);
    }

    function setBurnAddress(address _burnAddress) external {
        burnAddress = _burnAddress;
    }
}