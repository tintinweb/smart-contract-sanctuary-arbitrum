/**
 *Submitted for verification at Arbiscan.io on 2024-06-12
*/

pragma solidity 0.5.10;

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

	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100 ether; 
	uint256[] public REFERRAL_PERCENTS = [10, 0, 0, 0, 0];
	uint256 constant public TOTAL_REF = 10;
	uint256 constant public PROJECT_FEE = 80;
	uint256 constant public DEV_FEE = 20;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	
	uint256 public totalInvested;

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
		uint256[5] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 withdrawn;
		mapping(address => address[]) refdet;
	}

	mapping (address => User) public users;

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

	constructor(address MarketingAddr,address  TreasuryAddr, address  devAddr, uint256 start,IERC20 _Token) public {
		require(!isContract(MarketingAddr) && !isContract(TreasuryAddr) && !isContract(devAddr));
		MarketingWallet = MarketingAddr;
		TreasuryWallet = TreasuryAddr;
		devWallet = devAddr;
		Token=_Token;

		if(start>0){
			startDate = start;
		}
		else{
			startDate = block.timestamp;
		}
        plans.push(Plan(30, 36));	
        plans.push(Plan(60, 19));	
        plans.push(Plan(90, 14));	
        plans.push(Plan(120, 12));	
        plans.push(Plan(150, 11));
	}

	modifier onlyOwner{
		require(msg.sender == devWallet);
		_;
	}

	function changeOwner(address _MarketingAddress,address _TreasuryAddresss,address _devAddress) public onlyOwner{
		MarketingWallet=_MarketingAddress;
		TreasuryWallet=_TreasuryAddresss;
		devWallet=_devAddress;
	}

	function setPause(bool _value) public onlyOwner{
		pause=_value;
	}
	

	function invest(address referrer, uint8 plan,uint256 investamount,address[] memory uplinead) public {
		require(pause == false,'Contract is paused');
		require(block.timestamp > startDate, "contract does not launch yet");
		require(investamount >= INVEST_MIN_AMOUNT);
        require(plan < 5, "Invalid plan");

		uint256 pFee = investamount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER).div(2);
		uint256 dFee = investamount.mul(DEV_FEE).div(PERCENTS_DIVIDER);
		Token.transferFrom(msg.sender,address(this),investamount);
		Token.transfer(MarketingWallet,pFee);
		Token.transfer(TreasuryWallet,pFee);
		Token.transfer(devWallet,dFee);
		emit FeePayed(msg.sender, pFee.add(dFee.mul(2)));

		User storage user = users[msg.sender];
		
		
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}


		for(uint256 i=0;i<uplinead.length;i++){
			if(uplinead.length == 1){
			require(uplinead[0] == getUserReferrer(msg.sender),'you are not the referrer');
			}
			if(i > 0){
				require(uplinead[i] == getUserReferrer(uplinead[i-1]),'you are not the referrer');
			}
		}
	

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = investamount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
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

		totalInvested = totalInvested.add(investamount);

		if(user.referrer == devWallet || user.referrer == address(0) || uplinead.length==0){
		Token.transfer(devWallet,investamount.div(100));
		}
		else{
			uint256 length=uplinead.length;
	
			if(length == 1){
				uint256 referrer=investamount.mul(10).div(100);
				Token.transfer(uplinead[0],referrer.mul(10).div(100));
			}
			if(length == 2){
				uint256 referrer=investamount.mul(10).div(100);
				Token.transfer(uplinead[0], referrer.mul(10).div(100));
			}
			if(length == 3){
				uint256 referrer=investamount.mul(10).div(100);
				Token.transfer(uplinead[0],referrer.mul(10).div(100));
			}
			if(length == 4){
				uint256 referrer=investamount.mul(10).div(100);
				Token.transfer(uplinead[0],referrer.mul(10).div(100));
			}
			if(length == 5){
				uint256 referrer=investamount.mul(10).div(100);
				Token.transfer(uplinead[0],referrer.mul(10).div(100));
			}
		}
	

    emit NewDeposit(msg.sender, plan, investamount, block.timestamp);

	}

	function getLevel(address _address) public view returns(uint256){
		User memory user = users[_address];
		address referrer=user.referrer;
		uint256 count;
		uint256[5] memory refcount=getUserDownlineCount(referrer);
		for(uint256 i=0;i<5;i++){
			count+=refcount[i];
		}
		return count;
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

		uint256 contractBalance = Token.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);
		Token.transfer(msg.sender,totalAmount);

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
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
				}
			}
		}

		return totalAmount;
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

	function getUserDownlineCount(address userAddress) public view returns(uint256[5] memory referrals) {
		return (users[userAddress].levels);
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
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalInvested.mul(TOTAL_REF).div(PERCENTS_DIVIDER));
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
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