// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Airdrop is Ownable {
    IERC20 public token;

    // Define the reward amounts
    uint256 public constant TWITTER_FOLLOW_REWARD = 1500 * 10 ** 18;
    uint256 public constant TWEET_LIKE_REWARD = 1500 * 10 ** 18;
    uint256 public constant TWEET_REPLY_REWARD = 1500 * 10 ** 18;
    uint256 public constant TWEET_RETWEET_REWARD = 1500 * 10 ** 18;
    uint256 public constant DAILY_TWEET_REWARD = 3500 * 10 ** 18;
    uint256 public constant DAILY_TELEGRAM_REWARD = 500 * 10 ** 18;
    uint256 public constant YOUTUBE_POST_REWARD = 50000 * 10 ** 18;
    uint256 public constant TIKTOK_POST_REWARD = 25000 * 10 ** 18;
    uint256 public constant REFERRAL_REWARD_REFERRER = 10000 * 10 ** 18;
    uint256 public constant REFERRAL_REWARD_REFERRED = 5000 * 10 ** 18;

    // Mappings to keep track of claims
    mapping(address => bool) public hasClaimedTwitterFollow;
    mapping(address => bool) public hasClaimedTweetLike;
    mapping(address => bool) public hasClaimedTweetReply;
    mapping(address => bool) public hasClaimedTweetRetweet;
    mapping(address => uint256) public lastDailyTweetClaim;
    mapping(address => uint256) public lastDailyTelegramClaim;
    mapping(address => bool) public hasClaimedYouTubePost;
    mapping(address => bool) public hasClaimedTikTokPost;
    mapping(address => uint256) public referralCount;
    mapping(address => uint256) public referralRewards;
    mapping(address => bool) public hasUsedReferral;

    // Events to log actions
    event TwitterFollowClaimed(address indexed user);
    event TweetLikeClaimed(address indexed user);
    event TweetReplyClaimed(address indexed user);
    event TweetRetweetClaimed(address indexed user);
    event DailyTweetClaimed(address indexed user);
    event DailyTelegramClaimed(address indexed user);
    event YouTubePostClaimed(address indexed user);
    event TikTokPostClaimed(address indexed user);
    event ReferralUsed(address indexed referrer, address indexed referred);
    event ReferralRewardClaimed(address indexed user, uint256 amount);

    // Constructor to set the token address
    constructor(address _tokenAddress) Ownable(msg.sender) {
        token = IERC20(_tokenAddress);
    }

    // Function to claim Twitter follow reward (one-time claim)
    function claimTwitterFollow() external {
        require(!hasClaimedTwitterFollow[msg.sender], "Already claimed");
        hasClaimedTwitterFollow[msg.sender] = true;
        token.transfer(msg.sender, TWITTER_FOLLOW_REWARD);
        emit TwitterFollowClaimed(msg.sender);
    }

    // Function to claim Tweet like reward (one-time claim)
    function claimTweetLike() external {
        require(!hasClaimedTweetLike[msg.sender], "Already claimed");
        hasClaimedTweetLike[msg.sender] = true;
        token.transfer(msg.sender, TWEET_LIKE_REWARD);
        emit TweetLikeClaimed(msg.sender);
    }

    // Function to claim Tweet reply reward (one-time claim)
    function claimTweetReply() external {
        require(!hasClaimedTweetReply[msg.sender], "Already claimed");
        hasClaimedTweetReply[msg.sender] = true;
        token.transfer(msg.sender, TWEET_REPLY_REWARD);
        emit TweetReplyClaimed(msg.sender);
    }

    // Function to claim Tweet retweet reward (one-time claim)
    function claimTweetRetweet() external {
        require(!hasClaimedTweetRetweet[msg.sender], "Already claimed");
        hasClaimedTweetRetweet[msg.sender] = true;
        token.transfer(msg.sender, TWEET_RETWEET_REWARD);
        emit TweetRetweetClaimed(msg.sender);
    }

    // Function to claim daily tweet reward (once every 24 hours)
    function claimDailyTweet() external {
        require(block.timestamp - lastDailyTweetClaim[msg.sender] >= 1 days, "Already claimed today");
        lastDailyTweetClaim[msg.sender] = block.timestamp;
        token.transfer(msg.sender, DAILY_TWEET_REWARD);
        emit DailyTweetClaimed(msg.sender);
    }

    // Function to claim daily Telegram post reward (once every 24 hours)
    function claimDailyTelegram() external {
        require(block.timestamp - lastDailyTelegramClaim[msg.sender] >= 1 days, "Already claimed today");
        lastDailyTelegramClaim[msg.sender] = block.timestamp;
        token.transfer(msg.sender, DAILY_TELEGRAM_REWARD);
        emit DailyTelegramClaimed(msg.sender);
    }

    // Function to claim YouTube post reward (one-time claim)
    function claimYouTubePost() external {
        require(!hasClaimedYouTubePost[msg.sender], "Already claimed");
        hasClaimedYouTubePost[msg.sender] = true;
        token.transfer(msg.sender, YOUTUBE_POST_REWARD);
        emit YouTubePostClaimed(msg.sender);
    }

    // Function to claim TikTok post reward (one-time claim)
    function claimTikTokPost() external {
        require(!hasClaimedTikTokPost[msg.sender], "Already claimed");
        hasClaimedTikTokPost[msg.sender] = true;
        token.transfer(msg.sender, TIKTOK_POST_REWARD);
        emit TikTokPostClaimed(msg.sender);
    }

    // Function to handle referral and award referrer and referred
    function useReferral(address referrer) external {
        require(referrer != msg.sender, "Cannot refer yourself");
        require(!hasUsedReferral[msg.sender], "Referral already used");
        hasUsedReferral[msg.sender] = true;
        referralCount[referrer] += 1;
        referralRewards[referrer] += REFERRAL_REWARD_REFERRER;
        referralRewards[msg.sender] += REFERRAL_REWARD_REFERRED;
        emit ReferralUsed(referrer, msg.sender);
    }

    // Function to claim referral rewards
    function claimReferralReward() external {
        uint256 reward = referralRewards[msg.sender];
        require(reward > 0, "No referral rewards to claim");
        referralRewards[msg.sender] = 0;
        token.transfer(msg.sender, reward);
        emit ReferralRewardClaimed(msg.sender, reward);
    }

    // Function to get total referral rewards for a user
    function getReferralRewards(address user) external view returns (uint256) {
        return referralRewards[user];
    }
}