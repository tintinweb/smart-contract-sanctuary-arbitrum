/**
 *Submitted for verification at Arbiscan on 2023-03-29
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

contract Referral is Context {
    struct User {
        bool referred;
        address referred_by;
    }

    struct Referral_rewards {
        uint level_1;
        uint level_2;
        uint level_3;
        uint level_4;
        uint level_5;
    }

    struct Referral_levels {
        uint level_1;
        uint level_2;
        uint level_3;
        uint level_4;
        uint level_5;
    }

    mapping(address => Referral_levels) public referInfo;
    mapping(address => User) public userInfo;
    mapping(address => Referral_rewards) public claimedRefRewards;
    mapping(address => address[]) internal referrals_level_1;
    mapping(address => address[]) internal referrals_level_2;
    mapping(address => address[]) internal referrals_level_3;
    mapping(address => address[]) internal referrals_level_4;
    mapping(address => address[]) internal referrals_level_5;

    function getReferInfo() external view returns (Referral_levels memory) {
        return referInfo[_msgSender()];
    }

    function addReferee(address ref) public {
        require(ref != _msgSender(), " You cannot refer yourself ");

        userInfo[_msgSender()].referred = true;
        userInfo[_msgSender()].referred_by = ref;

        address level1 = userInfo[_msgSender()].referred_by;
        address level2 = userInfo[level1].referred_by;
        address level3 = userInfo[level2].referred_by;
        address level4 = userInfo[level3].referred_by;
        address level5 = userInfo[level4].referred_by;

        if ((level1 != _msgSender()) && (level1 != address(0))) {
            referrals_level_1[level1].push(_msgSender());
            referInfo[level1].level_1 += 1;
        }
        if ((level2 != _msgSender()) && (level2 != address(0))) {
            referrals_level_2[level2].push(_msgSender());
            referInfo[level2].level_2 += 1;
        }
        if ((level3 != _msgSender()) && (level3 != address(0))) {
            referrals_level_3[level3].push(_msgSender());
            referInfo[level3].level_3 += 1;
        }
        if ((level4 != _msgSender()) && (level4 != address(0))) {
            referrals_level_4[level4].push(_msgSender());
            referInfo[level4].level_4 += 1;
        }
        if ((level5 != _msgSender()) && (level5 != address(0))) {
            referrals_level_5[level5].push(_msgSender());
            referInfo[level5].level_5 += 1;
        }
    }

    function getReferees(address ref, uint level) public view returns (address[] memory)
    {
        address[] memory referees;
        if (level == 1) {
            referees = referrals_level_1[ref];
        } 
        else if (level == 2) {
            referees = referrals_level_2[ref];
        } 
        else if (level == 3) {
            referees = referrals_level_3[ref];
        } 
        else if (level == 4) {
            referees = referrals_level_4[ref];
        } 
        else {
            referees = referrals_level_5[ref];
        }
        return referees;
    }
}

contract Staking is Ownable, ReentrancyGuard, Referral {
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
     uint private constant _days30 = 2592000;
    uint private constant _days60 = 5184000;
    uint private constant _days90 = 7776000;
    uint private constant _days180 = 15552000;
    uint private constant _days365 = 31536000;
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
    mapping(address => bool) public hasStaked;
    mapping(uint => uint) public stakeOnPool;
    mapping(uint => uint) public rewardOnPool;
    mapping(uint => uint) public stakersPlan;
     


    event Deposit(address indexed user, uint indexed lockupDuration, uint amount, uint returnPer);
    event Withdraw(address indexed user, uint amount, uint reward, uint total);
    event WithdrawAll(address indexed user, uint amount);
    event RewardClaimed(address indexed user, uint reward);
    event RefRewardClaimed(address indexed user, uint reward);

    constructor(address _token) {
        token = IERC20(_token);

        pooldata[30].lockupDuration = _days30; // 30 days
        pooldata[30].returnPer = 10;

        pooldata[60].lockupDuration = _days60; // 60 days
        pooldata[60].returnPer = 20;

        pooldata[90].lockupDuration = _days90; // 90 days
        pooldata[90].returnPer = 35;

          pooldata[180].lockupDuration = _days180; // 180 days
        pooldata[180].returnPer = 75;
    }

    function deposit(uint _amount, uint _lockupDuration, address _referrer) external {
        if (_referrer != address(0) && !userInfo[_msgSender()].referred) {
            addReferee(_referrer);
        }

        PoolInfo storage pool = pooldata[_lockupDuration];
        require(pool.lockupDuration > 0, "TokenStakingCIP: asked pool does not exist");
        require(started, "TokenStakingCIP: staking not yet started");
        require(_amount > 0, "TokenStakingCIP: stake amount must be non zero");
        require(token.transferFrom(_msgSender(), address(this), _amount), "TokenStakingCIP: token transferFrom via deposit not succeeded");

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

        
         if (!hasStaked[msg.sender]) {
             stakersPlan[_lockupDuration] = stakersPlan[_lockupDuration] + 1;
             totalStakers = totalStakers + 1 ;
        }

        //updating staking status
        
        hasStaked[msg.sender] = true;
        stakeOnPool[_lockupDuration] = stakeOnPool[_lockupDuration] + _amount ;
        totalStaked = totalStaked + _amount ;
        balanceOf[_msgSender()] += _amount;
        orderIds[_msgSender()].push(latestOrderId); 
        emit Deposit(_msgSender(), pool.lockupDuration, _amount, pool.returnPer);
    }

    function withdraw(uint orderId) external nonReentrant {
        require(orderId <= latestOrderId, "TokenStakingCIP: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId]; 
        require(_msgSender() == orderInfo.beneficiary, "TokenStakingCIP: caller is not the beneficiary");
        require(!orderInfo.claimed, "TokenStakingCIP: order already unstaked");
        require(block.timestamp >= orderInfo.endtime, "TokenStakingCIP: stake locked until lock duration completion");

        uint claimAvailable = pendingRewards(orderId);
        uint total = orderInfo.amount + claimAvailable;

        totalRewardEarn[_msgSender()] += claimAvailable; 
        
        orderInfo.claimedReward += claimAvailable;
        balanceOf[_msgSender()] -= orderInfo.amount; 
        orderInfo.claimed = true;

        require(token.transfer(address(_msgSender()), total), "TokenStakingCIP: token transfer via withdraw not succeeded");
       rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit Withdraw(_msgSender(), orderInfo.amount, claimAvailable, total);
    }

    function emergencyWithdraw(uint orderId) external nonReentrant {
        require(orderId <= latestOrderId, "TokenStakingCIP: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId]; 
        require(_msgSender() == orderInfo.beneficiary, "TokenStakingCIP: caller is not the beneficiary");
        require(!orderInfo.claimed, "TokenStakingCIP: order already unstaked");

        uint claimAvailable = pendingRewards(orderId);
        uint fees = (orderInfo.amount * emergencyWithdrawFees) / 100; 
        orderInfo.amount -= fees; 
        uint total = orderInfo.amount + claimAvailable;

        totalRewardEarn[_msgSender()] += claimAvailable; 
    
        orderInfo.claimedReward += claimAvailable;


        balanceOf[_msgSender()] -= (orderInfo.amount + fees); 
      
        orderInfo.claimed = true;

        require(token.transfer(address(_msgSender()), total), "TokenStakingCIP: token transfer via emergency withdraw not succeeded");
        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit WithdrawAll(_msgSender(), total);
    }

    function claimRewards(uint orderId) external nonReentrant {
        require(orderId <= latestOrderId, "TokenStakingCIP: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId];
        require(_msgSender() == orderInfo.beneficiary, "TokenStakingCIP: caller is not the beneficiary");
        require(!orderInfo.claimed, "TokenStakingCIP: order already unstaked");

        uint claimAvailable = pendingRewards(orderId);
        totalRewardEarn[_msgSender()] += claimAvailable;
       
        orderInfo.claimedReward += claimAvailable;

        require(token.transfer(address(_msgSender()), claimAvailable), "TokenStakingCIP: token transfer via claim rewards not succeeded");
        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit RewardClaimed(address(_msgSender()), claimAvailable);
    }

    function pendingRewards(uint orderId) public view returns (uint) {
        require(orderId <= latestOrderId, "TokenStakingCIP: INVALID orderId, orderId greater than latestOrderId");

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

    function claimRefRewards() external nonReentrant {
        Referral_rewards memory ref_rewards = _calculateRefRewards(_msgSender());
        Referral_rewards memory claimed_ref_rewards = claimedRefRewards[_msgSender()];
        uint availableRewards = _sumRefRewards(ref_rewards);

        Referral_rewards memory updatedClaimed = Referral_rewards(
            claimed_ref_rewards.level_1 + ref_rewards.level_1,
            claimed_ref_rewards.level_2 + ref_rewards.level_2,
            claimed_ref_rewards.level_3 + ref_rewards.level_3,
            claimed_ref_rewards.level_4 + ref_rewards.level_4,
            claimed_ref_rewards.level_5 + ref_rewards.level_5
        );
        claimedRefRewards[_msgSender()] = updatedClaimed;
       
        require(token.transfer(_msgSender(), availableRewards), "TokenStakingCIP: token transfer to beneficiary via referrer rewards not succeeded");
        emit RefRewardClaimed(address(_msgSender()), availableRewards);
    }

    function _calculateRefRewards(address ref) private view returns (Referral_rewards memory)
    {
        uint level_1_rewards;
        for (uint i = 0; i < referrals_level_1[ref].length; i++) {
            level_1_rewards += _totalRewards(referrals_level_1[ref][i]);
        }
        uint level_2_rewards;
        for (uint i = 0; i < referrals_level_2[ref].length; i++) {
            level_2_rewards += _totalRewards(referrals_level_2[ref][i]);
        }
        uint level_3_rewards;
        for (uint i = 0; i < referrals_level_3[ref].length; i++) {
            level_3_rewards += _totalRewards(referrals_level_3[ref][i]);
        }
        uint level_4_rewards;
        for (uint i = 0; i < referrals_level_4[ref].length; i++) {
            level_4_rewards += _totalRewards(referrals_level_4[ref][i]);
        }
        uint level_5_rewards;
        for (uint i = 0; i < referrals_level_5[ref].length; i++) {
            level_5_rewards += _totalRewards(referrals_level_5[ref][i]);
        }

        return Referral_rewards(
                ((level_1_rewards * 10) / 100) - claimedRefRewards[ref].level_1,
                ((level_2_rewards * 7) / 100) - claimedRefRewards[ref].level_2,
                ((level_3_rewards * 5) / 100) - claimedRefRewards[ref].level_3,
                ((level_4_rewards * 4) / 100) - claimedRefRewards[ref].level_4,
                ((level_5_rewards * 2) / 100) - claimedRefRewards[ref].level_5
            );
    }

    function _sumRefRewards(Referral_rewards memory _refRewards) private pure returns (uint)
    {
        uint rewards = _refRewards.level_1 + _refRewards.level_2 + _refRewards.level_3 + _refRewards.level_4 + _refRewards.level_5;
        return rewards;
    }

    function _totalRewards(address ref) private view returns (uint) {
        uint rewards;
        uint[] memory arr = orderIds[ref];
        for (uint i = 0; i < arr.length; i++) {
            OrderInfo memory order = orders[arr[i]];
            rewards += (order.claimedReward + pendingRewards(arr[i]));
        }
        return rewards;
    }

    function getRefRewards(address _address) public view returns (Referral_rewards memory)
    {
        return _calculateRefRewards(_address);
    }

    function transferAnyERC20Token(address payaddress, address tokenAddress, uint amount) external onlyOwner {
        IERC20(tokenAddress).transfer(payaddress, amount);
    }
}