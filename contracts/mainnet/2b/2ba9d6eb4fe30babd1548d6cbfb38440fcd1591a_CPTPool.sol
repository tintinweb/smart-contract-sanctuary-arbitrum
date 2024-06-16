/**
 *Submitted for verification at Arbiscan.io on 2024-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract CPTPool is Ownable {
    using SafeMath for uint256;
    IERC20 public Token;

    struct userInfo {
        uint256 DepositeToken;
        uint256 lastUpdated;
        uint256 lockableDays;
        uint256 WithdrawReward;
        uint256 WithdrawAbleReward;
        uint256 depositeTime;
        uint256 WithdrawDepositeAmount;
    }

    event Deposite_(address indexed to, address indexed from, uint256 amount, uint256 day, uint256 time);

    mapping(uint256 => uint256) public allocation;
    mapping(address => uint256[]) public depositeToken;
    mapping(address => uint256[]) public lockabledays;
    mapping(address => uint256[]) public depositetime;
    mapping(address => mapping(uint256 => uint256)) public lastClaimed; 
    mapping(address => userInfo) public Users;
    mapping(address => uint256) public UserReferalReward;

    uint256 public referralPercent = 5; // 5%
    uint256 public minimumDeposit = 1E18;
    uint256 public totalStaked;

    uint256 public time = 12 * 30 days;

    constructor(IERC20 _token) {
        Token = _token;
        allocation[1] = 100000000000000000000; // 100%
        allocation[2] = 120000000000000000000 * 2; // 120% * 2
        allocation[4] = 150000000000000000000 * 4; // 150% * 4
    }

    function farm(uint256 _amount, uint256 _lockableDays, address _Referral) public {
        require(_amount >= minimumDeposit, "Invalid amount");
        require(allocation[_lockableDays] > 0, "Invalid day selection");
        Token.transferFrom(msg.sender, address(this), _amount);
        uint256 __fee = _amount * referralPercent / 100;
        if (_Referral == address(0) || _Referral == msg.sender) {
            // Token.transfer(owner(),__fee);
        } else {
            Token.transfer(_Referral, __fee);
            UserReferalReward[_Referral] += __fee;
        }
        depositeToken[msg.sender].push(_amount);
        depositetime[msg.sender].push(uint40(block.timestamp));
        Users[msg.sender].DepositeToken += _amount;
        lockabledays[msg.sender].push(_lockableDays);
        totalStaked += _amount;
        emit Deposite_(msg.sender, address(this), _amount, _lockableDays, block.timestamp);
    }

    function dailyRewards(address _add, uint256 index) public view returns (uint256 reward) {
    require(index < depositeToken[_add].length, "Invalid index");

    uint256 lockTime = depositetime[_add][index] + (lockabledays[_add][index] * time);
    uint256 lastClaimTime = lastClaimed[_add][index] > 0 ? lastClaimed[_add][index] : depositetime[_add][index];
    uint256 currentTime = block.timestamp;

    if (currentTime > lastClaimTime + 1 days) {
        uint256 allocationForDays = allocation[lockabledays[_add][index]];
        uint256 depositedTokens = depositeToken[_add][index];

        uint256 totalReward = (allocationForDays * depositedTokens) / 100 / 1e18;
        uint256 stakingDuration = lockTime - depositetime[_add][index];
        uint256 elapsedTime;

        if (currentTime > lockTime) {
            elapsedTime = lockTime - lastClaimTime; // Only consider time up to the lockTime
        } else {
            elapsedTime = currentTime - lastClaimTime;
        }

        reward = (totalReward * elapsedTime) / stakingDuration;
    } else {
        reward = 0;
    }
    return reward;
    }


    function claimTokens(uint256 index) public {
        require(index < depositeToken[msg.sender].length, "Invalid index");

        uint256 reward = dailyRewards(msg.sender, index);
        require(reward > 0, "No rewards available");

        // Update last claimed time
        lastClaimed[msg.sender][index] = block.timestamp;

        // Transfer rewards to user
        Token.transfer(msg.sender, reward);
    }

    function harvest(uint256[] memory _index) public {
        for (uint256 z = 0; z < _index.length; z++) {
            require(Users[msg.sender].DepositeToken > 0, "No deposit found");
            uint256 lockTime = depositetime[msg.sender][_index[z]] + (lockabledays[msg.sender][_index[z]].mul(time));
            require(block.timestamp > lockTime, "Unstake time not reached!");
            uint256 reward = (allocation[lockabledays[msg.sender][_index[z]]].mul(depositeToken[msg.sender][_index[z]]).div(100)).div(1e18);
            Users[msg.sender].WithdrawAbleReward += reward;
            Users[msg.sender].DepositeToken -= depositeToken[msg.sender][_index[z]];
            Users[msg.sender].WithdrawDepositeAmount += depositeToken[msg.sender][_index[z]];
            depositeToken[msg.sender][_index[z]] = 0;
            lockabledays[msg.sender][_index[z]] = 0;
            depositetime[msg.sender][_index[z]] = 0;
        }
        // Cleanup arrays and reset lastClaimed mapping for removed stakes
        for (uint256 t = 0; t < _index.length; t++) {
            for (uint256 i = _index[t]; i < depositeToken[msg.sender].length - 1; i++) {
                depositeToken[msg.sender][i] = depositeToken[msg.sender][i + 1];
                lockabledays[msg.sender][i] = lockabledays[msg.sender][i + 1];
                depositetime[msg.sender][i] = depositetime[msg.sender][i + 1];
                lastClaimed[msg.sender][i] = lastClaimed[msg.sender][i + 1]; // Shift lastClaimed
            }
            depositeToken[msg.sender].pop();
            lockabledays[msg.sender].pop();
            depositetime[msg.sender].pop();
            delete lastClaimed[msg.sender][_index[t]];
        }
        uint256 totalwithdrawAmount;
        totalwithdrawAmount = Users[msg.sender].WithdrawDepositeAmount;
        Token.transfer(msg.sender, totalwithdrawAmount);
        Users[msg.sender].WithdrawReward = Users[msg.sender].WithdrawReward.add(Users[msg.sender].WithdrawAbleReward);
        Users[msg.sender].WithdrawAbleReward = 0;
        Users[msg.sender].WithdrawDepositeAmount = 0;
    }

    function UserInformation(address _add) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        return (depositeToken[_add], lockabledays[_add], depositetime[_add]);
    }

    function emergencyWithdraw(uint256 _token) external onlyOwner {
        Token.transfer(msg.sender, _token);
    }

    function emergencyWithdrawETH(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    function changetimeCal(uint256 _time) external onlyOwner {
        time = _time;
    }

    function changeMinimmumAmount(uint256 amount) external onlyOwner {
        minimumDeposit = amount;
    }

    function changePercentages(uint256 _1yearpercent, uint256 _2yearpercent, uint256 _4yearpercent) external onlyOwner {
        allocation[1] = _1yearpercent;
        allocation[2] = _2yearpercent;
        allocation[4] = _4yearpercent;
    }

    function changeToken(address newToken) external onlyOwner {
        Token = IERC20(newToken);
    }

    function setReferralPercent(uint256 _referralPercent) external onlyOwner {
        referralPercent = _referralPercent;
    }
}