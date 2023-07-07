/**
 *Submitted for verification at Arbiscan on 2023-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

pragma solidity ^0.8.4;

contract AiThrone is Ownable {
    using SafeMath for uint256;

    IERC20 public arbToken;
    uint256 public constant WITHDRAW_MAX_PER_DAY_AMOUNT = 50000e18; // 50000 Arb per day
    uint256[] public REFERRAL_PERCENTS = [300, 250, 200, 150, 100, 70, 50]; //50 5%
    uint256 public PROJECT_FEE = 50;
    uint256 public DEV_FEE = 30;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;

    uint256 public totalStaked;
    uint256 public totalParticipants = 0;
    uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
        uint256 minAmount;
    }

    Plan[] internal plans;

    struct Refinfo {
        uint8 count;
        uint256 totalAmount;
    }

    mapping(address => Refinfo) public refInfos;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
        bool withdrawed;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
        uint256 firstwithdrawntime;
        uint256 daywithdrawnamount;
    }

    mapping(address => User) internal users;

    bool public started;
    address public feeWallet;
    address private devWallet;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Compound(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SwapAndLiquify(
        uint256 ethSwapped,
        uint256 tokenReceived,
        uint256 ethsIntoLiqudity
    );
    event FeeWalletUpdated(
        address indexed oldFeeWallet,
        address indexed newFeeWallet
    );
    event DevWalletUpdated(
        address indexed oldDevWallet,
        address indexed newDevWallet
    );

    constructor(
        IERC20 _arbToken,
        address wallet,
        address dev
    ) {
        arbToken = _arbToken;
        require(!isContract(wallet));
        feeWallet = wallet;
        require(!isContract(dev));
        devWallet = dev;

        plans.push(Plan(15, 50, 1 ether));
        plans.push(Plan(30, 80, 200 ether));
        plans.push(Plan(45, 120, 500 ether));
        plans.push(Plan(90, 150, 1000 ether));
    }

    receive() external payable {}

    function stake(
        address referrer,
        uint8 plan,
        uint256 amount
    ) public {
        if (!started) {
            if (msg.sender == feeWallet) {
                started = true;
            } else revert("Not started yet");
        }

        require(amount >= plans[plan].minAmount);
        require(plan < 4, "Invalid plan");
        require(referrer != msg.sender, "Invalid referrer");

        uint256 fee = amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        arbToken.transferFrom(msg.sender, feeWallet, fee);
        uint256 devfee = amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        arbToken.transferFrom(msg.sender, devWallet, devfee);

        emit FeePayed(msg.sender, fee.add(devfee));

        User storage user = users[msg.sender];

        if (referrer != address(0)) {

            if (refInfos[referrer].totalAmount == 0) {
                refInfos[referrer].count = refInfos[referrer].count + 1;
            }
            refInfos[referrer].totalAmount = refInfos[referrer].totalAmount.add(amount);
            uint256 refamount = 0;
            if (refInfos[referrer].totalAmount >= 10000 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[0]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 5000 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[1]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 2000 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[2]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 1000 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[3]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 500 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[4]).div(PERCENTS_DIVIDER);
            } else if (refInfos[referrer].totalAmount >= 200 * (10 ** 18)) {
                refamount = amount.mul(REFERRAL_PERCENTS[5]).div(PERCENTS_DIVIDER);
            } else {
                refamount = amount.mul(REFERRAL_PERCENTS[6]).div(PERCENTS_DIVIDER);
            }
            users[referrer].bonus = users[referrer].bonus.add(refamount);
            users[referrer].totalBonus = users[referrer].totalBonus.add(refamount);
            
            emit RefBonus(referrer, msg.sender, 0, refamount);
        }

        if (user.deposits.length == 0) {
            totalParticipants = totalParticipants.add(1);
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }
        arbToken.transferFrom(
            msg.sender,
            address(this),
            amount.sub(devfee).sub(fee)
        );

        user.deposits.push(Deposit(plan, amount, block.timestamp, false));

        totalStaked = totalStaked.add(amount);

        emit NewDeposit(msg.sender, plan, amount);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 referralBonus = getUserReferralBonus(msg.sender);

        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = arbToken.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            user.bonus = totalAmount.sub(contractBalance);
            totalAmount = contractBalance;
        } else {
            if (referralBonus > 0)
                totalRefBonus = totalRefBonus.add(referralBonus);
        }

        if (block.timestamp - user.firstwithdrawntime <= TIME_STEP) {
            require(
                user.daywithdrawnamount < WITHDRAW_MAX_PER_DAY_AMOUNT,
                "Exceed max withdrawn amount today"
            );

            if (
                user.daywithdrawnamount.add(totalAmount) >
                WITHDRAW_MAX_PER_DAY_AMOUNT
            ) {
                uint256 additionalBonus = user
                    .daywithdrawnamount
                    .add(totalAmount)
                    .sub(WITHDRAW_MAX_PER_DAY_AMOUNT);
                user.bonus = user.bonus.add(additionalBonus);
                totalAmount = WITHDRAW_MAX_PER_DAY_AMOUNT.sub(
                    user.daywithdrawnamount
                );
            }
            user.daywithdrawnamount = user.daywithdrawnamount.add(totalAmount);
        } else {
            if (totalAmount > WITHDRAW_MAX_PER_DAY_AMOUNT) {
                uint256 additionalBonus = totalAmount.sub(
                    WITHDRAW_MAX_PER_DAY_AMOUNT
                );
                user.bonus = user.bonus.add(additionalBonus);
                totalAmount = WITHDRAW_MAX_PER_DAY_AMOUNT;
            }
            user.firstwithdrawntime = block.timestamp;
            user.daywithdrawnamount = totalAmount;
        }

        user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(totalAmount);
        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(
                plans[user.deposits[i].plan].time.mul(1 days)
            );
            if (user.checkpoint > finish) {
                user.deposits[i].withdrawed = true;
            }
        }
        arbToken.transfer(msg.sender, totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function getRefInfo(address _addr) public view returns (Refinfo memory) {
        return refInfos[_addr];
    }

    function compound(uint8 plan, uint256 amount) public {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);
        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");
        require(amount < totalAmount, "Compound Amount is over");

        uint256 contractBalance = arbToken.balanceOf(address(this));
        if (contractBalance < amount) {
            user.bonus = amount.sub(contractBalance);
            amount = contractBalance;
        } else if (referralBonus > 0) {
            if (referralBonus > amount) {
                user.bonus = user.bonus.sub(amount);
                totalRefBonus = totalRefBonus.add(amount);
            } else {
                user.bonus = totalAmount.sub(amount);
                totalRefBonus = totalRefBonus.add(referralBonus);
            }
        }

        require(totalAmount >= plans[plan].minAmount);

        uint256 fee = amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        arbToken.transfer(feeWallet, fee);
        uint256 devfee = amount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
        arbToken.transfer(devWallet, devfee);

        emit FeePayed(msg.sender, fee.add(devfee));

        user.deposits.push(Deposit(plan, amount, block.timestamp, false));
        totalStaked = totalStaked.add(amount);
        user.checkpoint = block.timestamp;

        emit Compound(msg.sender, plan, amount);
    }

    function canHarvest(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (block.timestamp - user.firstwithdrawntime <= TIME_STEP) {
            return user.daywithdrawnamount < WITHDRAW_MAX_PER_DAY_AMOUNT;
        } else {
            return true;
        }
    }

    function canRestake(address userAddress, uint8 plan)
        public
        view
        returns (bool)
    {
        uint256 totalAmount = getUserDividends(userAddress);
        uint256 referralBonus = getUserReferralBonus(userAddress);
        if (referralBonus > 0) totalAmount = totalAmount.add(referralBonus);

        uint256 contractBalance = arbToken.balanceOf(address(this));
        if (contractBalance < totalAmount) totalAmount = contractBalance;

        return (totalAmount >= plans[plan].minAmount);
    }


    function getContractBalance() public view returns (uint256) {
        return arbToken.balanceOf(address(this));
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (
            uint256 time,
            uint256 percent,
            uint256 minAmount
        )
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
        minAmount = plans[plan].minAmount;
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(
                plans[user.deposits[i].plan].time.mul(1 days)
            );
            if (user.checkpoint < finish) {
                uint256 share = user
                    .deposits[i]
                    .amount
                    .mul(plans[user.deposits[i].plan].percent)
                    .div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = finish < block.timestamp
                    ? finish
                    : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(
                        share.mul(to.sub(from)).div(TIME_STEP)
                    );
                }
            } 
            if (block.timestamp > finish && !user.deposits[i].withdrawed) {
                totalAmount = totalAmount.add(user.deposits[i].amount);
            }
        }
        return totalAmount;
    }

    function getUserActiveStaking(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(
                plans[user.deposits[i].plan].time.mul(1 days)
            );
            if (block.timestamp < finish) {
                totalAmount = totalAmount.add(user.deposits[i].amount);
            } 
        }
        return totalAmount;
    }

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].withdrawn;
    }

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserTotalReferrals(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            refInfos[userAddress].count;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserReferralBonus(userAddress).add(
                getUserDividends(userAddress)
            );
    }

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint8 plan,
            uint256 percent,
            uint256 amount,
            uint256 start,
            uint256 finish
        )
    {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].start.add(
            plans[user.deposits[index].plan].time.mul(1 days)
        );
    }

    function getUserPlanInfo(address userAddress)
        public
        view
        returns (uint256[] memory planAmount)
    {
        User storage user = users[userAddress];
        uint256 index = getUserAmountOfDeposits(userAddress);
        planAmount = new uint256[](4);

        for (uint256 i = 0; i < index; i++) {
            uint256 userPlan = user.deposits[i].plan;
            uint256 amount = user.deposits[i].amount;
            planAmount[userPlan] = planAmount[userPlan].add(amount);
        }

        return planAmount;
    }

    function getSiteInfo()
        public
        view
        returns (uint256 _totalStaked, uint256 _totalBonus)
    {
        return (totalStaked, totalRefBonus);
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (
            uint256 totalDeposit,
            uint256 totalWithdrawn,
            uint256 totalReferrals
        )
    {
        return (
            getUserTotalDeposits(userAddress),
            getUserTotalWithdrawn(userAddress),
            getUserTotalReferrals(userAddress)
        );
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        _token.transfer(_to, _amount);
    }

}