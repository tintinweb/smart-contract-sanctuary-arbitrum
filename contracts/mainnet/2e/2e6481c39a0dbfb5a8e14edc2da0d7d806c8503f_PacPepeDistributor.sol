/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract PacPepeDistributor {
    struct HighScore {
        address player;
        uint256 score;
    }
    
    HighScore[3] public topScores;
    mapping(address => uint256) public playerScores;
    mapping(address => bool) public claimedRewards;
    
    uint256 public totalSupply;
    uint256 public rewardPercentage;
    uint256 public rewardClaimInterval;
    uint256 public lastRewardClaimTime;
    IERC20 public token;
    address public owner;
    
    constructor(address tokenAddress, uint256 _rewardPercentage, uint256 _rewardClaimInterval) {
        token = IERC20(tokenAddress);
        totalSupply = token.totalSupply();
        rewardPercentage = _rewardPercentage;
        rewardClaimInterval = _rewardClaimInterval;
        lastRewardClaimTime = block.timestamp;
        owner = msg.sender;
    }
    
    function updateHighScores() internal {
        for (uint i = 0; i < 3; i++) {
            if (playerScores[msg.sender] > topScores[i].score) {
                for (uint j = 2; j > i; j--) {
                    topScores[j] = topScores[j-1];
                }
                topScores[i] = HighScore({player: msg.sender, score: playerScores[msg.sender]});
                break;
            }
        }
    }
    
    function claimReward() public {
        require(playerScores[msg.sender] > 0, "You haven't played yet!");
        require(!claimedRewards[msg.sender], "You already claimed your reward!");
        require(token.balanceOf(address(this)) > 0, "No rewards available right now!");
        require(block.timestamp >= lastRewardClaimTime + rewardClaimInterval, "It's not time to claim rewards yet!");
        uint256 rewardAmount = (totalSupply * rewardPercentage) / 100;
        uint256 contractBalance = token.balanceOf(address(this));
        if (rewardAmount > contractBalance) {
            rewardAmount = contractBalance;
        }
        claimedRewards[msg.sender] = true;
        token.transfer(msg.sender, rewardAmount);
    }
    
    function submitScore(uint256 score) public {
        playerScores[msg.sender] = score;
        updateHighScores();
    }
    
    function withdrawTokens() public {
        require(msg.sender == owner, "Only the contract owner can withdraw tokens!");
        token.transfer(owner, token.balanceOf(address(this)));
    }
}