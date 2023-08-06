// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IRevenue.sol";

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IStorage {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function stakeFor(address _from, address _to,uint _value) external returns (uint);
    function withdraw(address account, uint _index) external;
    function getUserStakeLength(address _addr) external view returns (uint256);
}

interface IStake {
    function updateRewardByHelper(address director) external;
    function getRewardByHelper(address _sender) external returns(uint);
}

contract KStakeHelper is Ownable {
    using SafeMath for uint256;

    struct Boardseat {
        uint256 lastSnapshotIndex;
        uint256 rewardEarned;
    }

    struct BoardSnapshot {
        uint256 time;
        uint256 rewardReceived;
        uint256 rewardPerShare;
    }

    IERC20 public kToken;
    IStorage public stor;
    uint256 public rewardDuration = 1 hours;
    uint256 public refundTotal;
    uint256 public rewardTotal;

    address public revenue;
    address public stakeETH;
    address public stakeUSDT;

    mapping(address => Boardseat) private directors;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardAdded(address indexed user, uint256 reward);

    constructor(address _stor, address _revenue, address _stake, address _stakeu) {
        stor = IStorage(_stor);
        revenue = _revenue;
        stakeETH = _stake;
        stakeUSDT = _stakeu;
    }

    function setRevenue(address _revenue) external onlyOwner() {
        revenue = _revenue;
    }

    function stakeFor(address _to, uint _value) public returns (uint){
        IStake(stakeETH).updateRewardByHelper(_to);
        IStake(stakeUSDT).updateRewardByHelper(_to);
        require(_value > 0, 'Cannot stake 0');
        stor.stakeFor(msg.sender, _to, _value);
        return _value;
    }

    function stake(uint _value) public returns (uint){
        return stakeFor(msg.sender, _value);
    }

    function withdraw(uint _index) public {
        IStake(stakeETH).updateRewardByHelper(msg.sender);
        IStake(stakeUSDT).updateRewardByHelper(msg.sender);
        stor.withdraw(msg.sender, _index);
    }

    function withdrawAll() public {
        IStake(stakeETH).updateRewardByHelper(msg.sender);
        IStake(stakeUSDT).updateRewardByHelper(msg.sender);
        uint len = stor.getUserStakeLength(msg.sender);
        for(uint i = 0; i < len; i++){
            stor.withdraw(msg.sender, 0);
        }
    }

    function getReward() public returns (uint, uint) {
        uint eth_amt = IStake(stakeETH).getRewardByHelper(msg.sender);
        uint usdt_amt = IStake(stakeUSDT).getRewardByHelper(msg.sender);
        return (eth_amt, usdt_amt);
    }

    function withdrawForeignTokens(address token, address to, uint256 amount) onlyOwner public returns (bool) {
        require(token!=address(kToken), 'Wrong token!');
        return IERC20(token).transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IRevenue {
    function distribute(bool _withReferee) external payable;
    function distribute(uint _amt, bool _withReferee) external;
    function lpDividend(address _account, uint _share, uint _total) external;
    function lpDividendUSDT(address _account, uint _share, uint _total) external;
    function stakeReward(address _account, uint _amt) external;
    function stakeRewardUSDT(address _account, uint _amt) external;
    function stake_revenue() view external returns (uint);
    function usdt_stake_revenue() view external returns (uint);
}