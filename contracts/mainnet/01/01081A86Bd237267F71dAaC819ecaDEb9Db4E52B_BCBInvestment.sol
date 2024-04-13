/**
 *Submitted for verification at Arbiscan.io on 2024-04-12
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}



pragma solidity 0.8.19;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address reBCBient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address reBCBient,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
        uint256 level_1;
    }

    struct Referral_levels {
        uint256 level_1;
    }

    mapping(address => Referral_levels) public referInfo;
    mapping(address => User) public userInfo;
    mapping(address => Referral_rewards) public claimedRefRewards;
    mapping(address => address[]) internal referrals_level_1;

    function getReferInfo() external view returns (Referral_levels memory) {
        return referInfo[_msgSender()];
    }

    function addReferee(address ref) public {
        require(ref != _msgSender(), " You cannot refer yourself ");

        userInfo[_msgSender()].referred = true;
        userInfo[_msgSender()].referred_by = ref;

        address level1 = userInfo[_msgSender()].referred_by;

        if ((level1 != _msgSender()) && (level1 != address(0))) {
            referrals_level_1[level1].push(_msgSender());
            referInfo[level1].level_1 += 1;
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
        }

        return referees;
    }
}

contract BCBInvestment is Ownable, ReentrancyGuard, Referral {

    AggregatorV3Interface public wbtcPriceFeed;
    AggregatorV3Interface public ethPriceFeed;

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


    uint256 private constant _days30 = 30 days;
    uint256 private constant _days365 = 365 days;
    uint256 private constant _days1095 = 1095 days;

    IERC20 public token;
    IERC20 public wBtc;
    bool public started = true;
    uint256 private _30daysPercentage = 1;
    uint256 private _365daysPercentage = 15;
    uint256 private _1095daysPercentage = 18;
    uint256 private latestOrderId = 0;
    uint256 public totalStake = 0;
    uint256 public totalWithdrawal = 0;

    uint256 crcPrice = 0.5 * 10 **18 ;  // 1 CRC = 0.5 USD ;

   uint public totalStakers ; 
    uint public totalStaked ; 
   
    uint256 public totalRewardPending = 0;
    uint256 public totalRewardsDistribution = 0;

    mapping(uint256 => PoolInfo) public pooldata;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public totalRewardEarn;
    mapping(uint256 => OrderInfo) public orders;
    mapping(address => uint256[]) private orderIds;

    mapping(address => mapping(uint => bool)) public hasStaked;
    mapping(uint => uint) public stakeOnPool;
    mapping(uint => uint) public rewardOnPool;
    mapping(uint => uint) public stakersPlan;

    event Deposit(
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
    event RefRewardClaimed(address indexed user, uint256 reward);

    constructor(
        address _token,
        address _wBtc,
        bool _started,
         address _wbtcPriceFeed,
        address _ethPriceFeed
    ) {
        token = IERC20(_token);
        wBtc = IERC20(_wBtc);
        started = _started;

        pooldata[1].lockupDuration =  _days30;
        pooldata[1].returnPer =   _30daysPercentage;

        pooldata[2].lockupDuration =  _days365;
        pooldata[2].returnPer =   _365daysPercentage;

        pooldata[3].lockupDuration = _days1095;
        pooldata[3].returnPer = _1095daysPercentage;

        wbtcPriceFeed = AggregatorV3Interface(_wbtcPriceFeed);
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
    }

     function getEthPriceInUSD() public view returns (uint256) {
        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        return uint256(price);
    }

     function getWbtcPriceInUSD() public view returns (uint256) {
        (, int256 price, , , ) = wbtcPriceFeed.latestRoundData();
        return uint256(price);
    }

    function stake(
        uint256 _amount,
        uint256 _lockupDuration,
        address _referrer
    ) external {
        if (_referrer != address(0) && !userInfo[_msgSender()].referred) {
            addReferee(_referrer);
        }

        PoolInfo storage pool = pooldata[_lockupDuration];
        require(
            pool.lockupDuration > 0,
            "BCBInvestment: asked pool does not exist"
        );
        require(started, "BCBInvestment: staking not yet started");
        require(_amount > 0, "BCBInvestment: stake amount must be non zero");

        uint256 APY = (_amount * pool.returnPer) / 100;
        uint256 userReward = (APY * pool.lockupDuration) / _days365;
        require(
            token.transferFrom(_msgSender(), address(this), _amount),
            "BCBInvestment: token transferFrom via deposit not succeeded"
        );

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

        totalStake += _amount;
        hasStaked[msg.sender][_lockupDuration] = true;
        stakeOnPool[_lockupDuration] = stakeOnPool[_lockupDuration] + _amount ;
        totalStaked = totalStaked + _amount ;
        totalRewardPending += userReward;
        balanceOf[_msgSender()] += _amount;
        orderIds[_msgSender()].push(latestOrderId);
        emit Deposit(
            _msgSender(),
            pool.lockupDuration,
            _amount,
            pool.returnPer
        );
    }

    function unstake(uint256 orderId) external nonReentrant {
        require(
            orderId <= latestOrderId,
            "BCBInvestment: INVALID orderId, orderId greater than latestOrderId"
        );

        OrderInfo storage orderInfo = orders[orderId];
        require(
            _msgSender() == orderInfo.beneficiary,
            "BCBInvestment: caller is not the beneficiary"
        );
        require(!orderInfo.claimed, "BCBInvestment: order already unstaked");
        require(
            block.timestamp >= orderInfo.endtime,
            "BCBInvestment: stake locked until lock duration completion"
        );

        uint256 total = orderInfo.amount ;

        balanceOf[_msgSender()] -= orderInfo.amount;
        totalWithdrawal += orderInfo.amount;
        orderInfo.claimed = true;

        require(
            token.transfer(address(_msgSender()), total),
            "BCBInvestment: token transfer via withdraw not succeeded"
        );
        emit Withdraw(_msgSender(), orderInfo.amount, total, total);
    }

    function claimRewardsInWBTC(uint256 orderId) external nonReentrant {
        require(
            orderId <= latestOrderId,
            "BCBInvestment: INVALID orderId, orderId greater than latestOrderId"
        );

        OrderInfo storage orderInfo = orders[orderId];
        require(
            _msgSender() == orderInfo.beneficiary,
            "BCBInvestment: caller is not the beneficiary"
        );
        require(!orderInfo.claimed, "BCBInvestment: order already unstaked");
         require(
            block.timestamp >= orderInfo.endtime,
            "BCBInvestment: stake locked until lock duration completion"
        );


        uint256 wbtcPriceInUSD =  getWbtcPriceInUSD() / 10**8;
        uint256 claimAvailable = pendingRewards(orderId) / 10 ** 18;
        uint256 claimInUSD = claimAvailable * crcPrice ;
        uint256 claimInWBTC = claimInUSD / wbtcPriceInUSD ;

        totalRewardEarn[_msgSender()] += claimAvailable;
        totalRewardsDistribution += claimAvailable;
        totalRewardPending -= claimAvailable;
        orderInfo.claimedReward += pendingRewards(orderId);

        require(
            wBtc.transfer(address(_msgSender()), claimInWBTC),
            "BCBInvestment: token transfer via claim rewards not succeeded"
        );

        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + pendingRewards(orderId) ;

        emit RewardClaimed(address(_msgSender()), claimAvailable);
    }

    function claimRewardsInETH(uint256 orderId) external nonReentrant {
        require(
            orderId <= latestOrderId,
            "BCBInvestment: INVALID orderId, orderId greater than latestOrderId"
        );

        OrderInfo storage orderInfo = orders[orderId];
        require(
            _msgSender() == orderInfo.beneficiary,
            "BCBInvestment: caller is not the beneficiary"
        );
        require(!orderInfo.claimed, "BCBInvestment: order already unstaked");
         require(
            block.timestamp >= orderInfo.endtime,
            "BCBInvestment: stake locked until lock duration completion"
        );


        uint256 wbtcPriceInUSD =  getEthPriceInUSD() / 10**8;
        uint256 claimAvailable = pendingRewards(orderId) / 10 ** 18;
        uint256 claimInUSD = claimAvailable * crcPrice ;
        uint256 claimInETH = claimInUSD / wbtcPriceInUSD ;
        totalRewardEarn[_msgSender()] += claimAvailable;
        totalRewardsDistribution += claimAvailable;
        totalRewardPending -= claimAvailable;
        orderInfo.claimedReward += pendingRewards(orderId);
        payable(_msgSender()).transfer(claimInETH);
        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + pendingRewards(orderId) ;

        emit RewardClaimed(address(_msgSender()), claimAvailable);
    }

    function pendingRewards(uint256 orderId) public view returns (uint256) {
        require(
            orderId <= latestOrderId,
            "BCBInvestment: INVALID orderId, orderId greater than latestOrderId"
        );

        OrderInfo storage orderInfo = orders[orderId];
        if (!orderInfo.claimed) {
                uint256 APY = (orderInfo.amount * orderInfo.returnPer) / 100;
                return APY - orderInfo.claimedReward;
        } else {
            return 0;
        }
    }

    function setCRCPrice(uint256 _price) external onlyOwner {
        crcPrice = _price ;
    }

    

    function toggleStaking(bool _start) external onlyOwner returns (bool) {
        started = _start;
        return true;
    }

    function investorOrderIds(address investor)
        external
        view
        returns (uint256[] memory ids)
    {
        uint256[] memory arr = orderIds[investor];
        return arr;
    }

    function claimRefRewardsInWBTC() external nonReentrant {
        Referral_rewards memory ref_rewards = _calculateRefRewards(
            _msgSender()
        );
        Referral_rewards memory claimed_ref_rewards = claimedRefRewards[
            _msgSender()
        ];
        uint256 availableRewards = _sumRefRewards(ref_rewards);

        Referral_rewards memory updatedClaimed = Referral_rewards(
            claimed_ref_rewards.level_1 + ref_rewards.level_1
        );
        claimedRefRewards[_msgSender()] = updatedClaimed;
        uint256 requiredToken = (totalStake - totalWithdrawal) +
            totalRewardPending +
            availableRewards;
        require(
            requiredToken <= wBtc.balanceOf(address(this)),
            "BCBInvestment: insufficient contract balance to return referrer rewards"
        );
        require(
            wBtc.transfer(_msgSender(), availableRewards),
            "BCBInvestment: token transfer to beneficiary via referrer rewards not succeeded"
        );
        emit RefRewardClaimed(address(_msgSender()), availableRewards);
    }

    function claimRefRewardsInETH() external nonReentrant {
        Referral_rewards memory ref_rewards = _calculateRefRewards(
            _msgSender()
        );
        Referral_rewards memory claimed_ref_rewards = claimedRefRewards[
            _msgSender()
        ];
        uint256 availableRewards = _sumRefRewards(ref_rewards);

        Referral_rewards memory updatedClaimed = Referral_rewards(
            claimed_ref_rewards.level_1 + ref_rewards.level_1
        );
        claimedRefRewards[_msgSender()] = updatedClaimed;

        payable(_msgSender()).transfer(availableRewards);
        emit RefRewardClaimed(address(_msgSender()), availableRewards);
    }

    function _calculateRefRewards(address ref)
        private
        view
        returns (Referral_rewards memory)
    {
        uint256 level_1_rewards;
        for (uint256 i = 0; i < referrals_level_1[ref].length; i++) {
            level_1_rewards += _totalRewards(referrals_level_1[ref][i]);
        }

        return
            Referral_rewards(
                ((level_1_rewards * 5) / 100) - claimedRefRewards[ref].level_1
            );
    }

    function _sumRefRewards(Referral_rewards memory _refRewards)
        private
        pure
        returns (uint256)
    {
        uint256 rewards = _refRewards.level_1;
        return rewards;
    }

    function _totalRewards(address ref) private view returns (uint256) {
        uint256 rewards;
        uint256[] memory arr = orderIds[ref];
        for (uint256 i = 0; i < arr.length; i++) {
            OrderInfo memory order = orders[arr[i]];
            rewards += (order.claimedReward + pendingRewards(arr[i]));
        }
        return rewards;
    }

    function getRefRewards(address _address)
        public
        view
        returns (Referral_rewards memory)
    {
        return _calculateRefRewards(_address);
    }

    function transferAnyERC20Token(
        address payaddress,
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(payaddress, amount);
    }

    function changeAPY(uint256 _apy) external onlyOwner {
        pooldata[1].returnPer = _apy;
    }

      fallback() external payable {}


}