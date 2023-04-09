/**
 *Submitted for verification at Arbiscan on 2023-04-09
*/

pragma solidity ^0.8.0;

contract EthereumInvestment {
    address public owner;
    uint256 public pool;
    uint256 public fomoPool;
    uint256 public fomoDeadline;
    address public fomoWinner;
    bool public paused;

    uint256 constant INVESTMENT_MINIMUM = 10**13; // 0.00001 ETH
    uint256 constant DAILY_RETURN = 15; // 1.5%
    uint256 constant REFERRER_PERCENT = 25;
    uint256 constant POOL_PERCENT = 45;
    uint256 constant FOMO_PERCENT = 5;
    uint256 constant PAYOUT_INTERVAL = 1 days;
    uint256 constant FOMO_DURATION = 24 hours;

    struct User {
        uint256 investment;
        uint256 lastPayout;
        address payable referrer;
    }

    mapping(address => User) public users;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    event NewInvestment(address indexed user, uint256 amount);
    event ReferralRewarded(address indexed referrer, uint256 amount, uint8 level);
    event Payout(address indexed user, uint256 amount);
    event FomoPrizeWon(address indexed winner, uint256 amount);

    constructor() {
        owner = msg.sender;
        paused = false;
    }

    function invest(address payable referrer) external payable whenNotPaused {
        require(msg.value >= INVESTMENT_MINIMUM, "Investment below minimum threshold");

        User storage user = users[msg.sender];
        require(user.investment == 0, "User already invested");

        user.investment = msg.value;
        user.lastPayout = block.timestamp;
        user.referrer = referrer;

        uint256 referrerShare = (msg.value * REFERRER_PERCENT) / 100;
        uint256 secondLevelShare = (msg.value * REFERRER_PERCENT) / 100;

        if (referrer != address(0) && users[referrer].investment > 0) {
            users[referrer].referrer.transfer(referrerShare);
            users[referrer].investment += referrerShare;
            emit ReferralRewarded(referrer, referrerShare, 1);

            address payable secondLevelReferrer = users[referrer].referrer;
            if (secondLevelReferrer != address(0) && users[secondLevelReferrer].investment > 0) {
                users[secondLevelReferrer].referrer.transfer(secondLevelShare);
                users[secondLevelReferrer].investment += secondLevelShare;
                emit ReferralRewarded(secondLevelReferrer, secondLevelShare, 2);
            } else {
                payable(owner).transfer(secondLevelShare);
            }
        } else {
            payable(owner).transfer(referrerShare + secondLevelShare);
        }

        uint256 poolShare = (msg.value * POOL_PERCENT) / 100;
        pool += poolShare;

        uint256 fomoShare = (msg.value * FOMO_PERCENT) / 100;
        fomoPool += fomoShare;
        fomoDeadline = block.timestamp + FOMO_DURATION;
        fomoWinner = msg.sender;
        emit NewInvestment(msg.sender, msg.value);
    }

    function withdraw() external whenNotPaused {
        User storage user = users[msg.sender];
        require(user.investment > 0, "User has no investment");

        uint256 payout = getPendingPayout(msg.sender);
        require(payout > 0, "No payout pending");

        user.lastPayout = block.timestamp;
        payable(msg.sender).transfer(payout);

        emit Payout(msg.sender, payout);
    }

    function checkFomo() external {
        require(block.timestamp >= fomoDeadline, "FOMO deadline not reached");

        uint256 prize = fomoPool;
        fomoPool = 0;
        payable(fomoWinner).transfer(prize);

        emit FomoPrizeWon(fomoWinner, prize);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner address is not valid");
        owner = newOwner;
    }

    function getPendingPayout(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 daysElapsed = (block.timestamp - user.lastPayout) / PAYOUT_INTERVAL;
        uint256 payout = (user.investment * DAILY_RETURN * daysElapsed) / 1000;
        return payout;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
    }
}