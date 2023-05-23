/**
 *Submitted for verification at Arbiscan on 2023-05-22
*/

/**
 *Submitted for verification at Arbiscan on 2023-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;
}

contract AICOREFactory is Ownable {
    struct User {
        uint256 latestBurnAmount;
        uint256 totalBurned;
        uint256 lastBurnTime;
        uint256 rewardsTillNow;
        uint256 lastClaimDate;
        uint256 totalClaimed;
        bool nextClaimAllowed; //flag to keep in check when burn and claim done on same day
    }

    IERC20 public AICOREtoken;
    IERC20 public AIBBtoken;

    uint256 public dailyReward;
    uint256 public totalBurned;
    uint256 public totalDistributed;

    address public treasuryWallet;

    mapping(address => User) public users;
    mapping(address => bool) public isUserExist;
    mapping(uint256 => uint256) public totalBurnedByDay;
    mapping(uint256 => uint256) public totalDistributedByDay;

    event TokensBurned(address indexed user, uint256 amount, uint256 date);
    event RewardsClaimed(address indexed user, uint256 amount, uint256 date);

    constructor(
        address _AIBB_token,
        address _AICORE_token,
        address _treasuryWallet,
        uint256 _dailyReward
    ) {
        require(_AICORE_token != address(0), "Token address cannot be 0x0");
        require(_AIBB_token != address(0), "Token address cannot be 0x0");
        require(
            _treasuryWallet != address(0),
            "Treasury address cannot be 0x0"
        );
        require(_dailyReward > 0, "Daily reward must be greater than 0");

        AIBBtoken = IERC20(_AIBB_token);
        AICOREtoken = IERC20(_AICORE_token);
        treasuryWallet = _treasuryWallet;
        dailyReward = _dailyReward;
    }

    /**
     * @dev Updates the daily reward per share.
     * @param _dailyReward The new daily reward per share.
     */
    function setDailyReward(uint256 _dailyReward) external onlyOwner {
        require(_dailyReward > 0, "Daily reward must be greater than 0");
        dailyReward = _dailyReward;
    }

    /**
     * @dev Updates the treasury wallet
     * @param _treasuryWallet The new treasury wallet address
     */
    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        require(
            _treasuryWallet != address(0),
            "Treasury address cannot be 0x0"
        );
        treasuryWallet = _treasuryWallet;
    }

    /**
     * @dev Burns AIBB tokens and updates the user's burn amount, rewards and total burned.
     * @param amount The amount of AIBB tokens to burn.
     */
    function burn(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(
            AIBBtoken.allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );
        require(
            AIBBtoken.balanceOf(msg.sender) >= amount,
            "Insufficient balance"
        );

        //60% burn
        uint256 burnShare = (amount * 6) / 10;
        AIBBtoken.burnFrom(msg.sender, burnShare);
        //40% treasury
        uint256 treasuryShare = amount - burnShare;
        AIBBtoken.transferFrom(msg.sender, treasuryWallet, treasuryShare);

        User storage user = users[msg.sender];
        if (!isUserExist[msg.sender]) {
            user.latestBurnAmount = amount;
        } else {
            //first calcukate rewards before mutating user struct
            uint256 rewardsTillNow = calculateRewards(msg.sender);

            user.rewardsTillNow = rewardsTillNow;
            //if burn is on same day as previous then just increment , otherwise if on new day reset and put new
            if ((block.timestamp / 1 days) == (user.lastBurnTime / 1 days)) {
                user.latestBurnAmount += amount;
            } else {
                user.latestBurnAmount = amount;
            }
        }

        user.totalBurned += amount;
        user.lastBurnTime = block.timestamp;
        user.nextClaimAllowed = true;
        isUserExist[msg.sender] = true;

        uint256 day = block.timestamp / 1 days; // will give a day
        totalBurnedByDay[day] += amount;
        totalBurned += amount;

        // Emit TokensBurned event
        emit TokensBurned(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev calculate rewards till the current date
     * @param userAddress The address of user.
     */
    function calculateRewards(
        address userAddress
    ) public view returns (uint256) {
        User storage user = users[userAddress];

        if (
            user.lastBurnTime == 0 ||
            user.totalBurned == 0 ||
            !user.nextClaimAllowed
        ) {
            return 0;
        }

        uint256 currentTime = block.timestamp / 1 days;

        //if burn again on same day the reward is zero
        if (currentTime <= user.lastBurnTime / 1 days) {
            return user.rewardsTillNow;
        }

        // reward = rewardsTillNow + last burns rewards
        uint256 reward = user.rewardsTillNow +
            ((user.latestBurnAmount * dailyReward) /
                totalBurnedByDay[user.lastBurnTime / 1 days]);

        return reward;
    }

    /**
     * @dev estimate rewards till the current date
     * @param userAddress The address of user.
     */
    function estimateRewards(
        address userAddress
    ) public view returns (uint256) {
        User storage user = users[userAddress];
        if(block.timestamp / 1 days != user.lastBurnTime/1 days){
            return 0;
        }
        // reward = last burns rewards
        uint256 reward = 
            ((user.latestBurnAmount * dailyReward) /
                totalBurnedByDay[user.lastBurnTime / 1 days]);

        return reward;
    }

    /**
     * @dev claim rewards as AICORE tokens
     */
    function claimRewards() public {
        User storage user = users[msg.sender];
        //handle if user has not burned any tokens yet
        require(
            (user.lastBurnTime != 0 || user.totalBurned != 0),
            "You have not burned any AIBB tokens"
        );

        //check if there are any rewards to claim
        uint256 rewards = calculateRewards(msg.sender);
        require(rewards > 0, "No rewards to claim");
        require(user.nextClaimAllowed, "No rewards to claim");

        // Update user's pending rewards and last reward calculation time
        AICOREtoken.mint(msg.sender, rewards);

        user.rewardsTillNow = 0;
        user.lastClaimDate = block.timestamp;
        user.totalClaimed += rewards;
        totalDistributed += rewards;
        totalDistributedByDay[block.timestamp / 1 days] += rewards;
        
        //this is to allow claim if user (burn-claim-burn) on same day
        //example :- user burn on day 1(flag =true); on day 2 user burn again (flag is now true),
        //he claims his previous day rewards(we want the flag to be still true, for todays burn) 
        //so only set false if no burn was made previous to burn on the same day
        if (user.lastBurnTime / 1 days != block.timestamp / 1 days) {
            user.nextClaimAllowed = false;
        }
        // Emit RewardsClaimed event
        emit RewardsClaimed(msg.sender, rewards, block.timestamp);
    }
}