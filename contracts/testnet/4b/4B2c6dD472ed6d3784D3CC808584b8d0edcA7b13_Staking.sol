/**
 *Submitted for verification at Arbiscan on 2023-05-11
*/

/**
 *Submitted for verification at Etherscan.io on 2023-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _checkOwner() private view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    uint private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() private view returns (bool) {
        return _status == _ENTERED;
    }
}


contract Staking is Ownable, ReentrancyGuard {
    struct PoolInfo {
        uint lockupDuration;
        uint returnPer;
    }
    struct OrderInfo {
        address beneficiary;
        uint amount;
        uint lockupDuration;
        uint returnPer;
        uint starttime;
        uint endtime;
        uint claimedReward;
        bool claimed;
    }
     uint private constant _days7 = 604800;
    uint private constant _days14 = 1209600;
     uint256 private constant _days365 = 31536000;
    IERC20 public token;
    bool private  started = true;
    uint public emergencyWithdrawFees = 15;
    uint private latestOrderId = 0;
    uint public totalStakers ; // use 
     uint public totalStaked ; // use 


    mapping(uint => PoolInfo) public pooldata;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public totalRewardEarn;
    mapping(uint => OrderInfo) public orders;
    mapping(address => uint[]) private orderIds;
    mapping(address => mapping(uint => bool))public hasStaked;
    mapping(uint => uint) public stakeOnPool;
    mapping(uint => uint) public rewardOnPool;
    mapping(uint => uint) public stakersPlan;
     


    event Deposit(address indexed user, uint indexed lockupDuration, uint amount, uint returnPer);
    event Withdraw(address indexed user, uint amount, uint reward, uint total);
    event WithdrawAll(address indexed user, uint amount);
    event RewardClaimed(address indexed user, uint reward);

    constructor(address _token) {
        token = IERC20(_token);

        pooldata[30].lockupDuration = _days7; // 7 days
        pooldata[30].returnPer = 20;

        pooldata[60].lockupDuration = _days14; // 14 days
        pooldata[60].returnPer = 40;

    }

    function deposit(uint _amount, uint _lockupDuration) external {

        PoolInfo storage pool = pooldata[_lockupDuration];
        require(pool.lockupDuration > 0, "TokenStaking: asked pool does not exist");
        require(started, "TokenStaking: staking not yet started");
        require(_amount > 0, "TokenStaking: stake amount must be non zero");
        require(token.transferFrom(_msgSender(), address(this), _amount), "TokenStaking: token transferFrom via deposit not succeeded");

        orders[++latestOrderId] = OrderInfo( 
            _msgSender(),
            _amount,
            pool.lockupDuration,
            pool.returnPer,
            block.timestamp,
            block.timestamp + pool.lockupDuration,
            0,
            false
        );

        
         if (!hasStaked[msg.sender][_lockupDuration]) {
             stakersPlan[_lockupDuration] = stakersPlan[_lockupDuration] + 1;
             totalStakers = totalStakers + 1 ;
        }

        //updating staking status
        
        hasStaked[msg.sender][_lockupDuration] = true;
        stakeOnPool[_lockupDuration] = stakeOnPool[_lockupDuration] + _amount ;
        totalStaked = totalStaked + _amount ;
        balanceOf[_msgSender()] += _amount;
        orderIds[_msgSender()].push(latestOrderId); 
        emit Deposit(_msgSender(), pool.lockupDuration, _amount, pool.returnPer);
    }

    function withdraw(uint orderId) external nonReentrant {
        require(orderId <= latestOrderId, "TokenStaking: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId]; 
        require(_msgSender() == orderInfo.beneficiary, "TokenStaking: caller is not the beneficiary");
        require(!orderInfo.claimed, "TokenStaking: order already unstaked");
        require(block.timestamp >= orderInfo.endtime, "TokenStaking: stake locked until lock duration completion");

        uint claimAvailable = pendingRewards(orderId);
        uint total = orderInfo.amount + claimAvailable;

        totalRewardEarn[_msgSender()] += claimAvailable; 
        
        orderInfo.claimedReward += claimAvailable;
        balanceOf[_msgSender()] -= orderInfo.amount; 
        orderInfo.claimed = true;

        require(token.transfer(address(_msgSender()), total), "TokenStaking: token transfer via withdraw not succeeded");
       rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit Withdraw(_msgSender(), orderInfo.amount, claimAvailable, total);
    }

    function emergencyWithdraw(uint orderId) external nonReentrant {
        require(orderId <= latestOrderId, "TokenStaking: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId]; 
        require(_msgSender() == orderInfo.beneficiary, "TokenStaking: caller is not the beneficiary");
        require(!orderInfo.claimed, "TokenStaking: order already unstaked");

        uint claimAvailable = pendingRewards(orderId);
        uint fees = (orderInfo.amount * emergencyWithdrawFees) / 100; 
        orderInfo.amount -= fees; 
        uint total = orderInfo.amount + claimAvailable;

        totalRewardEarn[_msgSender()] += claimAvailable; 
    
        orderInfo.claimedReward += claimAvailable;


        balanceOf[_msgSender()] -= (orderInfo.amount + fees); 
      
        orderInfo.claimed = true;

        require(token.transfer(address(_msgSender()), total), "TokenStaking: token transfer via emergency withdraw not succeeded");
        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit WithdrawAll(_msgSender(), total);
    }

    function claimRewards(uint orderId) external nonReentrant {
        require(orderId <= latestOrderId, "TokenStaking: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId];
        require(_msgSender() == orderInfo.beneficiary, "TokenStaking: caller is not the beneficiary");
        require(!orderInfo.claimed, "TokenStaking: order already unstaked");

        uint claimAvailable = pendingRewards(orderId);
        totalRewardEarn[_msgSender()] += claimAvailable;
       
        orderInfo.claimedReward += claimAvailable;

        require(token.transfer(address(_msgSender()), claimAvailable), "TokenStaking: token transfer via claim rewards not succeeded");
        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit RewardClaimed(address(_msgSender()), claimAvailable);
    }

    function pendingRewards(uint orderId) public view returns (uint) {
        require(orderId <= latestOrderId, "TokenStaking: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId];
        if (!orderInfo.claimed) {
            if (block.timestamp >= orderInfo.endtime) {
                uint APY = (orderInfo.amount * orderInfo.returnPer) / 100;
                uint reward = (APY * orderInfo.lockupDuration) / _days365;
                uint claimAvailable = reward - orderInfo.claimedReward;
                return claimAvailable;
            } else {
                uint stakeTime = block.timestamp - orderInfo.starttime;
                uint APY = (orderInfo.amount * orderInfo.returnPer) / 100;
                uint reward = (APY * stakeTime) / _days365;
                uint claimAvailableNow = reward - orderInfo.claimedReward;
                return claimAvailableNow;
            }
        } else {
            return 0;
        }
    }

    function toggleStaking(bool _start) external onlyOwner returns (bool) {
        started = _start;
        return true;
    }

    function investorOrderIds(address investor) external view returns (uint[] memory ids)
    {
        uint[] memory arr = orderIds[investor];
        return arr;
    }





 function updatePlans(uint256 _plan1Days , uint256 _plan2Days , uint256 _plan1APY ,uint256 _plan2APY ) public onlyOwner {
      

        pooldata[30].lockupDuration = _plan1Days; // 7 days
        pooldata[30].returnPer = _plan1APY;

        pooldata[60].lockupDuration = _plan2Days; // 14 days
        pooldata[60].returnPer = _plan2APY;
    
    }


    function transferAnyERC20Token(address payaddress, address tokenAddress, uint amount) external onlyOwner {
        IERC20(tokenAddress).transfer(payaddress, amount);
    }

    
}