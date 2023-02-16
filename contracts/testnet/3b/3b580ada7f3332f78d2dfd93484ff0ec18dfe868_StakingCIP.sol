/**
 *Submitted for verification at Arbiscan on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Referral is Ownable {
    struct User {
        bool referred;
        address referred_by;
    }

    struct Referral_rewards {
        uint256 level_1;
        uint256 level_2;
        uint256 level_3;
        uint256 level_4;
        uint256 level_5;
    }

    struct Referral_levels {
        uint256 level_1;
        uint256 level_2;
        uint256 level_3;
        uint256 level_4;
        uint256 level_5;
    }

    mapping(address => Referral_levels) public referInfo;
    mapping(address => User) public userInfo;
    mapping(address => Referral_rewards) public addressToRefRewards;
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
        require(userInfo[_msgSender()].referred == false, " Already referred ");
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

    function getReferees(address ref, uint256 level)
        public
        view
        returns (address[] memory)
    {
        address[] memory referees;
        if (level == 1) {
            referees = referrals_level_1[ref];
        } else if (level == 2) {
            referees = referrals_level_2[ref];
        } else if (level == 3) {
            referees = referrals_level_3[ref];
        } else if (level == 4) {
            referees = referrals_level_4[ref];
        } else {
            referees = referrals_level_5[ref];
        }
        return referees;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

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
}

contract StakingCIP is ReentrancyGuard, Referral {
    struct PoolInfo {
        uint256 lockupDuration;
        uint256 returnPer;
    }
    struct OrderInfo {
        address beneficiary;
        uint256 amount;
        uint256 lockupDuration;
        uint256 returnPer;
        uint256 starttime;
        uint256 endtime;
        uint256 claimedReward;
        bool claimed;
    }
    IERC20 public token;
    bool public started = true;
    uint256 private latestOrderId;
    uint256 public emergencyWithdrawFees; // 10% ~ 1000
    uint256 public totalStake;
    uint256 public totalWithdrawal;
    uint256 public totalRewardsDistribution;
    uint256 public totalRewardPending;
    uint256 public baseTime = 1 days;

    mapping(uint256 => PoolInfo) public pooldata;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public totalRewardEarn;
    mapping(uint256 => OrderInfo) public orders;
    mapping(address => uint256[]) private orderIds;

    constructor(
        address _token,
        bool _started,
        uint256 _emergencyWithdrawFees
    ) {
        token = IERC20(_token);
        started = _started;
        emergencyWithdrawFees = _emergencyWithdrawFees;

        //90 days
        pooldata[90].lockupDuration = 90;
        pooldata[90].returnPer = 3000; // 30%

        //180 days

        pooldata[180].lockupDuration = 180;
        pooldata[180].returnPer = 5000; // 50%

        //365 days
        pooldata[365].lockupDuration = 365;
        pooldata[365].returnPer = 100; // 100%
    }

    event Deposit(
        address indexed user,
        uint256 indexed lockupDuration,
        uint256 amount,
        uint256 returnPer
    );
    event MappedInvestment(
        address indexed user,
        uint256 indexed lockupDuration,
        uint256 amount,
        uint256 returnPer
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 reward,
        uint256 total
    );
    event WithdrawAll(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);

    function addPool(uint256 _lockupDuration, uint256 _returnPer)
        external
        onlyOwner
    {
        require(
            _lockupDuration > 0,
            "LockupDuration must be greater than zero"
        );
        require(_returnPer > 0, "ReturnPer must be greater than zero");
        PoolInfo storage pool = pooldata[_lockupDuration];
        pool.lockupDuration = _lockupDuration;
        pool.returnPer = _returnPer;
    }

    function investorOrderIds(address investor)
        external
        view
        returns (uint256[] memory ids)
    {
        uint256[] memory arr = orderIds[investor];
        return arr;
    }

    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    function setEmergencyWithdrawalFees(uint256 _emergencyWithdrawFees)
        external
        onlyOwner
    {
        require(
            _emergencyWithdrawFees != emergencyWithdrawFees,
            "Already set to the value!"
        );
        require(_emergencyWithdrawFees <= 35, "Can't set higher than 35%");
        emergencyWithdrawFees = _emergencyWithdrawFees;
    }

    function toggleStaking(bool _start) external onlyOwner {
        started = _start;
    }

    function pendingRewards(uint256 _orderId) public view returns (uint256) {
        OrderInfo storage orderInfo = orders[_orderId];

        if (
            _orderId <= latestOrderId &&
            orderInfo.amount > 0 &&
            !orderInfo.claimed
        ) {
            if (block.timestamp >= orderInfo.endtime) {
                uint256 reward = (orderInfo.amount *
                    orderInfo.returnPer *
                    orderInfo.lockupDuration) / (10000 * 365);
                uint256 claimAvailable = reward - orderInfo.claimedReward;
                return claimAvailable;
            }

            uint256 stakeTime = block.timestamp - orderInfo.starttime;
            uint256 totalReward = (orderInfo.amount *
                stakeTime *
                orderInfo.returnPer) / (10000 * 365 * 86400);
            uint256 claimAvailableNow = totalReward - orderInfo.claimedReward;
            return claimAvailableNow;
        } else {
            return 0;
        }
    }

    function claimRewards(uint256 _orderId) external nonReentrant {
        require(_orderId <= latestOrderId, "the order ID is incorrect"); // IOI
        require(
            address(_msgSender()) != address(0),
            "please Enter Valid Adderss"
        );
        OrderInfo storage orderInfo = orders[_orderId];
        require(_msgSender() == orderInfo.beneficiary, "not order beneficiary"); // NOO
        require(
            balanceOf[_msgSender()] >= orderInfo.amount && !orderInfo.claimed,
            "insufficient redeemable tokens"
        );
        uint256 pendingRewardsValue = pendingRewards(_orderId);
        orders[_orderId].claimedReward = pendingRewardsValue;
        totalRewardEarn[_msgSender()] =
            totalRewardEarn[_msgSender()] +
            pendingRewardsValue;
        totalRewardsDistribution =
            totalRewardsDistribution +
            pendingRewardsValue;

        token.transfer(address(_msgSender()), pendingRewardsValue);
        emit RewardClaimed(address(_msgSender()), pendingRewardsValue);
    }

    function deposit(
        uint256 _amount,
        uint256 _lockupDuration,
        address _referrer
    ) external {
        if (_referrer != address(0)) {
            addReferee(_referrer);
        }
        require(address(token) != address(0), "Token Not Set Yet");
        require(
            address(_msgSender()) != address(0),
            "please Enter Valid Adderss"
        );
        require(started, "Not Stared yet!");
        require(_amount > 0, "Amount must be greater than Zero!");

        PoolInfo storage pool = pooldata[_lockupDuration];

        require(
            pool.lockupDuration > 0 && pool.returnPer > 0,
            "No Pool exist With Locktime!"
        );
        uint256 userReward = (_amount * pool.returnPer * _lockupDuration) /
            (10000 * 365);
        uint256 requiredToken = (totalStake + totalRewardPending + userReward) -
            totalWithdrawal;
        require(
            token.balanceOf(address(this)) > requiredToken,
            "Sorry, Insufficient Staking Reward, Please Try Later."
        );
        require(
            token.transferFrom(_msgSender(), address(this), _amount),
            "Transfer failed"
        );

        orders[++latestOrderId] = OrderInfo(
            _msgSender(),
            _amount,
            _lockupDuration,
            pool.returnPer,
            block.timestamp,
            (block.timestamp + (_lockupDuration * baseTime)),
            0,
            false
        );

        totalStake = totalStake + _amount;
        totalRewardPending = totalRewardPending + userReward;
        balanceOf[_msgSender()] = balanceOf[_msgSender()] + _amount;
        orderIds[_msgSender()].push(latestOrderId);
        emit Deposit(_msgSender(), _lockupDuration, _amount, pool.returnPer);
    }

    function withdraw(uint256 orderId) external nonReentrant {
        require(orderId <= latestOrderId, "the order ID is incorrect"); // IOI
        require(
            address(_msgSender()) != address(0),
            "please Enter Valid Adderss"
        );
        OrderInfo storage orderInfo = orders[orderId];
        require(_msgSender() == orderInfo.beneficiary, "not order beneficiary"); // NOO
        require(
            balanceOf[_msgSender()] >= orderInfo.amount && !orderInfo.claimed,
            "insufficient redeemable tokens"
        ); // ITA
        require(
            block.timestamp >= orderInfo.endtime,
            "tokens are being locked"
        ); // TIL

        require(!orderInfo.claimed, "tokens are ready to be claimed"); // TAC

        uint256 amount = orderInfo.amount;
        uint256 reward = (amount *
            orderInfo.returnPer *
            orderInfo.lockupDuration) / (10000 * 365);
        uint256 claimAvailable = reward - orderInfo.claimedReward;
        uint256 total = amount + claimAvailable;

        require(
            token.balanceOf(address(this)) >= total,
            "Currently Withdraw not Avalible"
        );

        totalRewardEarn[_msgSender()] =
            totalRewardEarn[_msgSender()] +
            claimAvailable;
        totalWithdrawal = totalWithdrawal + amount;
        totalRewardsDistribution = totalRewardsDistribution + claimAvailable;
        totalRewardPending = totalRewardPending - reward;
        orderInfo.claimed = true;
        balanceOf[_msgSender()] = balanceOf[_msgSender()] - amount;
        token.transfer(address(_msgSender()), total);
        emit Withdraw(_msgSender(), amount, claimAvailable, total);
    }

    function emergencyWithdraw(uint256 orderId) external nonReentrant {
        require(orderId <= latestOrderId, "the order ID is incorrect"); // IOI
        require(
            address(_msgSender()) != address(0),
            "please Enter Valid Adderss"
        );

        OrderInfo storage orderInfo = orders[orderId];
        require(_msgSender() == orderInfo.beneficiary, "not order beneficiary"); // NOO
        require(
            balanceOf[_msgSender()] >= orderInfo.amount && !orderInfo.claimed,
            "insufficient redeemable tokens or already claimed"
        ); // ITA

        uint256 fees = (orderInfo.amount * emergencyWithdrawFees) / 10000;
        uint256 total = orderInfo.amount - fees;

        require(
            token.balanceOf(address(this)) >= total,
            "Currently Withdraw not Avalible"
        );

        totalWithdrawal = totalWithdrawal + orderInfo.amount;
        orderInfo.claimed = true;
        balanceOf[_msgSender()] = balanceOf[_msgSender()] - orderInfo.amount;
        uint256 userReward = (orderInfo.amount *
            orderInfo.returnPer *
            orderInfo.lockupDuration) / (10000 * 365);
        totalRewardPending = totalRewardPending - userReward;
        token.transfer(address(_msgSender()), total);
        address ownerAddress = owner();
        token.transfer(ownerAddress, fees);
        emit WithdrawAll(_msgSender(), total);
    }

    function nativeLiquidity(address payable _reciever, uint256 _amount)
        external
        onlyOwner
    {
        _reciever.transfer(_amount);
    }

    function transferAnyERC20Token(
        address payaddress,
        address tokenAddress,
        uint256 tokens
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(payaddress, tokens);
    }

    function setBaseToken(uint256 _basetime) external onlyOwner {
        baseTime = _basetime;
    }

    //fetching user referral rewards
    function getRefRewards(address _address)
        external
        view
        returns (Referral_rewards memory)
    {
        return _calculateRefRewards(_address);
    }

    //Allow user to claim referral rewards
    function claimRefRewards() external {
        Referral_rewards memory ref_rewards = _calculateRefRewards(
            _msgSender()
        );
        Referral_rewards memory claimed_ref_rewards = claimedRefRewards[
            _msgSender()
        ];
        uint256 availableRewards = _sumRefRewards(ref_rewards);

        Referral_rewards memory updatedClaimed = Referral_rewards(
            claimed_ref_rewards.level_1 + ref_rewards.level_1,
            claimed_ref_rewards.level_2 + ref_rewards.level_2,
            claimed_ref_rewards.level_3 + ref_rewards.level_3,
            claimed_ref_rewards.level_4 + ref_rewards.level_4,
            claimed_ref_rewards.level_5 + ref_rewards.level_5
        );
        claimedRefRewards[_msgSender()] = updatedClaimed;
        token.transfer(address(_msgSender()), availableRewards);
    }

    function _sumRefRewards(Referral_rewards memory _refRewards)
        internal
        pure
        returns (uint256)
    {
        uint256 rewards = _refRewards.level_1 +
            _refRewards.level_2 +
            _refRewards.level_3 +
            _refRewards.level_4 +
            _refRewards.level_5;
        return rewards;
    }

    //Calculate Ref Rewards
    function _calculateRefRewards(address ref)
        internal
        view
        returns (Referral_rewards memory)
    {
        uint256 level_1_rewards;
        for (uint256 i = 0; i < referrals_level_1[ref].length; i++) {
            level_1_rewards += _totalRewards(referrals_level_1[ref][i]);
        }
        uint256 level_2_rewards;
        for (uint256 i = 0; i < referrals_level_2[ref].length; i++) {
            level_2_rewards += _totalRewards(referrals_level_2[ref][i]);
        }
        uint256 level_3_rewards;
        for (uint256 i = 0; i < referrals_level_3[ref].length; i++) {
            level_3_rewards += _totalRewards(referrals_level_3[ref][i]);
        }
        uint256 level_4_rewards;
        for (uint256 i = 0; i < referrals_level_4[ref].length; i++) {
            level_4_rewards += _totalRewards(referrals_level_4[ref][i]);
        }
        uint256 level_5_rewards;
        for (uint256 i = 0; i < referrals_level_5[ref].length; i++) {
            level_5_rewards += _totalRewards(referrals_level_5[ref][i]);
        }

        return
            Referral_rewards(
                (((level_1_rewards) * 10) / 100) -
                    claimedRefRewards[ref].level_1,
                (((level_2_rewards) * 7) / 100) -
                    claimedRefRewards[ref].level_2,
                (((level_3_rewards) * 5) / 100) -
                    claimedRefRewards[ref].level_3,
                (((level_4_rewards) * 4) / 100) -
                    claimedRefRewards[ref].level_4,
                (((level_5_rewards) * 2) / 100) - claimedRefRewards[ref].level_5
            );
    }

    //Get Total Rewards for Address
    function _totalRewards(address ref) internal view returns (uint256) {
        uint256 rewards;
        uint256[] memory arr = orderIds[ref];
        for (uint256 i = 0; i < arr.length; i++) {
            OrderInfo memory order = orders[arr[i]];
            rewards += order.claimedReward + pendingRewards(arr[i]);
        }
        return rewards;
    }
}