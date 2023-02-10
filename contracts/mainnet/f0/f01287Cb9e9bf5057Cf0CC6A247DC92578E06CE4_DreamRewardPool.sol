// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ITradingHelper {

    function profitTax() external view returns (uint256);
    function fundsBackTax() external view  returns (uint256);
    function isAutoEnder(address autoEnder) external view  returns (bool);
    function getMaxBorrowAmount(uint256 pid) external view  returns (uint256);
    function getMaxMultiplier(uint256 pid) external view  returns (uint256);
    function getETHprice() external view returns (uint256);
    function SwapToWETH(uint256 inAmount) external returns (uint256 outAmount);
    function getEstimateWETH(uint256 inAmount) external view returns (uint256 estOutAmount);
    function SwapWETH(uint256 inAmount) external returns (uint256 outAmount);
    function getEstimateUSDC(uint256 inAmount) external view returns (uint256 estOutAmount);
}

interface IReferalHelper {

    function totalReferNum() external view returns (uint256);
    function totalReferProfitInUSDC() external view  returns (uint256);
    function totalReferProfitInWETH() external view  returns (uint256);
    function addReferWETHAmount(address depositor, address referrer, address token, uint256 amount) external;
    function addReferUSDCAmount(address depositor, address referrer, address token, uint256 amount) external;
}

// Note that this pool has no minter key of DREAM (rewards).
// Instead, the governance will call DREAM distributeReward method and send reward to this pool at the beginning.
contract DreamRewardPool is ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // governance
    address public operator;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        bool isTrading;
        int256 totalProfit;
        uint256 currentTradeId;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. DREAMs to distribute per block.
        uint256 lastRewardTime; // Last time that DREAMs distribution occurs.
        uint256 accDreamPerShare; // Accumulated DREAMs per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
        uint256 depositFeeBP;
        uint256 minAmountFortrading;
        uint256 totalDepositAmount;
    }

    IERC20 public dream;
    address public daoAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) public investAmount;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The time when DREAM mining starts.
    uint256 public poolStartTime;

    // The time when DREAM mining ends.
    uint256 public poolEndTime;

    uint256 public DreamPerSecond = 0.0039 ether; // 62000 dream / (180 days * 24h * 60min * 60s)
    uint256 public runningTime = 180 days; // 180 days
    uint256 public constant TOTAL_REWARDS = 62000 ether;

    // For Leverage Trading
    struct Trade {
        uint256 id;
        address user;
        uint256 pid;
        bool isTrading;
        uint256 borrowAmount;
        uint256 swappedAmount;
        uint256 returnAmount;
        uint256 startPrice;
        uint256 endPrice;
        uint256 limitPrice;
        int256 profit;
        uint256 startTime;
        uint256 endTime;
    }

    struct TradeInfo {
        uint256 totalBorrowedAmount;
        uint256 totalReturnedAmount;
        uint256 feeAmount;
        uint256 totalProfit;
        uint256 totalLoss;
        uint256 count;
        uint256 lastTradeEndTime;
    }

    mapping(uint256 => Trade) public trades;
    mapping(uint256 => TradeInfo) public tradeInfos;

    uint256 public feeDenominator = 10000;
    uint256 public tradeCount = 0;
    ITradingHelper public tradingHelper;
    IReferalHelper public referalHelper;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    constructor(
        address _dream,
        address _dao,
        uint256 _poolStartTime,
        address _tradingHelper,
        address _referalHelper
    ) {
        require(block.timestamp < _poolStartTime, "late");
        if (_dream != address(0)) dream = IERC20(_dream);
        poolStartTime = _poolStartTime;
        poolEndTime = poolStartTime + runningTime;
        daoAddress = _dao;
        operator = msg.sender;
        tradingHelper = ITradingHelper(_tradingHelper);
        referalHelper = IReferalHelper(_referalHelper);
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "DreamRewardPool: caller is not the operator");
        _;
    }

    function checkPoolDuplicate(IERC20 _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "DreamRewardPool: existing pool?");
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFeeBP,
        uint256 _minAmountFortrading
    ) external onlyOperator nonReentrant{
        require(_depositFeeBP <= 100, "add: invalid deposit fee basis points");
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // chef is sleeping
            if (_lastRewardTime == 0) {
                _lastRewardTime = poolStartTime;
            } else {
                if (_lastRewardTime < poolStartTime) {
                    _lastRewardTime = poolStartTime;
                }
            }
        } else {
            // chef is cooking
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted =
        (_lastRewardTime <= poolStartTime) ||
        (_lastRewardTime <= block.timestamp);
        poolInfo.push(PoolInfo({
            token : _token,
            allocPoint : _allocPoint,
            lastRewardTime : _lastRewardTime,
            accDreamPerShare : 0,
            isStarted : _isStarted,
            depositFeeBP: _depositFeeBP,
            minAmountFortrading: _minAmountFortrading,
            totalDepositAmount: 0
            }));
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's DREAM allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint256 _depositFeeBP, uint256 _minAmountFortrading) external onlyOperator nonReentrant{
        require(_depositFeeBP <= 100, "set: invalid deposit fee basis points");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].minAmountFortrading = _minAmountFortrading;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
        if (_fromTime >= _toTime) return 0;
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) return 0;
            if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(DreamPerSecond);
            return poolEndTime.sub(_fromTime).mul(DreamPerSecond);
        } else {
            if (_toTime <= poolStartTime) return 0;
            if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(DreamPerSecond);
            return _toTime.sub(_fromTime).mul(DreamPerSecond);
        }
    }

    // View function to see pending DREAMs on frontend.
    function pendingShare(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accDreamPerShare = pool.accDreamPerShare;
        uint256 tokenSupply = pool.totalDepositAmount;
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _dreamReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            accDreamPerShare = accDreamPerShare.add(_dreamReward.mul(1e18).div(tokenSupply));
        }
        return user.amount.mul(accDreamPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.totalDepositAmount;
        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
            uint256 _dreamReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
            pool.accDreamPerShare = pool.accDreamPerShare.add(_dreamReward.mul(1e18).div(tokenSupply));
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) external nonReentrant{
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 _pending = user.amount.mul(pool.accDreamPerShare).div(1e18).sub(user.rewardDebt);
            if (_pending > 0) {
                safeDreamTransfer(_sender, _pending);
                emit RewardPaid(_sender, _pending);
            }
        }
        if (_amount > 0) {
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalDepositAmount = pool.totalDepositAmount.add(_amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(feeDenominator);
                user.amount = user.amount.sub(depositFee);
                pool.totalDepositAmount = pool.totalDepositAmount.sub(depositFee);

                if(_amount >= pool.minAmountFortrading && _referrer != address(0) && _referrer != msg.sender) {
                    uint256 referFee = depositFee.div(2);
                    pool.token.safeTransfer(_referrer, referFee);
                    if(_pid == 0) {
                        referalHelper.addReferWETHAmount(msg.sender, _referrer, address(pool.token), referFee);
                    } else {
                        referalHelper.addReferUSDCAmount(msg.sender, _referrer, address(pool.token), referFee);
                    }
                    depositFee = depositFee.sub(referFee);
                }
                pool.token.safeTransfer(daoAddress, depositFee);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accDreamPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant{
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(user.amount >= _amount, "withdraw: not good");
        require(!user.isTrading, "withdraw: you are trading now, end trade first");
        updatePool(_pid);
        uint256 _pending = user.amount.mul(pool.accDreamPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeDreamTransfer(_sender, _pending);
            emit RewardPaid(_sender, _pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalDepositAmount = pool.totalDepositAmount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accDreamPerShare).div(1e18);
        emit Withdraw(_sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if(user.isTrading) {
            endTrade(user.currentTradeId);
        }
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.totalDepositAmount = pool.totalDepositAmount.sub(_amount);
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe dream transfer function, just in case if rounding error causes pool to not have enough DREAMs.
    function safeDreamTransfer(address _to, uint256 _amount) internal {
        uint256 _dreamBal = dream.balanceOf(address(this));
        if (_dreamBal > 0) {
            if (_amount > _dreamBal) {
                dream.safeTransfer(_to, _dreamBal);
            } else {
                dream.safeTransfer(_to, _amount);
            }
        }
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setDaoAddress(address _daoAddress) external{
        require(msg.sender == daoAddress, "setDaoAddress: FORBIDDEN");
        require(_daoAddress != address(0), "setDaoAddress: ZERO");
        daoAddress = _daoAddress;
    }

    function invest(address _token, uint256 _amount) external {
        require(msg.sender == daoAddress, "invest: FORBIDDEN");
        investAmount[_token] = investAmount[_token].add(_amount);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function getInvestAmount(address _token) external {
        require(msg.sender == daoAddress, "invest: FORBIDDEN");
        require(investAmount[_token] > 0, "invest first");
        uint256 getAmount = investAmount[_token];
        investAmount[_token] = 0;
        require(IERC20(_token).balanceOf(address(this)) >= getAmount, 'balance');
        IERC20(_token).safeTransfer(msg.sender, getAmount);
    }

    function withdrawTradingFee(uint256 _pid) external {
        require(msg.sender == daoAddress, "withdrawTradingFee: FORBIDDEN");
        require(_pid < 2, "wrong pid");
        PoolInfo storage pool = poolInfo[_pid];
        TradeInfo storage tradeInfo = tradeInfos[_pid];
        require(tradeInfo.feeAmount > 0, "invaild withdraw amount");
        require(tradeInfo.feeAmount <= pool.token.balanceOf(address(this)), "not available for now");
        uint256 feeAmount = tradeInfo.feeAmount;
        tradeInfo.feeAmount = 0;
        pool.token.safeTransfer(daoAddress, feeAmount);
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 amount, address to) external onlyOperator {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (dream or lps) if less than 90 days after pool ends
            require(_token != dream, "dream");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }

    function updateTradingHelper(address _tradingHelper) external onlyOperator {
        require(_tradingHelper != address(0), "invalid address");
        tradingHelper = ITradingHelper(_tradingHelper);
    }

    function updateReferalHelper(address _referalHelper) external onlyOperator {
        require(_referalHelper != address(0), "invalid address");
        referalHelper = IReferalHelper(_referalHelper);
    }

    function openTrade(uint256 _pid, uint256 _borrowAmount, uint256 _limitPrice) public {
        require(block.timestamp < poolEndTime.sub(1 hours), "leverage trading is disabled");
        address _trader = msg.sender;
        // _pid = 0: weth pool, _pid = 1: usdc pool
        // _pid = 0 ? short : long
        require(_pid < 2, "wrong pool id");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_trader];
        TradeInfo storage tradeInfo = tradeInfos[_pid];

        require(!user.isTrading, "already started one trading");
        require(user.amount >= pool.minAmountFortrading, "need to deposit min amount for trading");
        require(user.amount.mul(feeDenominator).div(feeDenominator.sub(pool.depositFeeBP)) >= pool.minAmountFortrading, "need to deposit min amount for trading");
        require(user.amount.mul(tradingHelper.getMaxMultiplier(_pid)) >= _borrowAmount, "exceed max multiplier");

        uint256 borrowableAmount = getBorrowableAmount(_pid);
        require(_borrowAmount <= borrowableAmount, "wrong borrow amount");
        require(_borrowAmount >= user.amount, "wrong borrow amount");

        tradeInfo.totalBorrowedAmount = tradeInfo.totalBorrowedAmount.add(_borrowAmount);

        uint256 swappedAmount = 0;
        uint256 liqPrice = 0;
        
        pool.token.safeIncreaseAllowance(address(tradingHelper), _borrowAmount);
        if(_pid == 1) {
            swappedAmount = tradingHelper.SwapToWETH(_borrowAmount);
            liqPrice = _borrowAmount.sub(user.amount).mul(1e14).div(swappedAmount);
            liqPrice = liqPrice.mul(105).div(100);
        } else {
            swappedAmount = tradingHelper.SwapWETH(_borrowAmount);
            liqPrice = swappedAmount.mul(1e14).div(_borrowAmount.sub(user.amount));
            liqPrice = liqPrice.mul(95).div(100);
        }

        uint256 startPrice = tradingHelper.getETHprice();

        user.isTrading = true;
        user.currentTradeId = tradeCount;
        trades[tradeCount] = Trade(
            tradeCount,
            msg.sender,
            _pid,
            true,
            _borrowAmount,
            swappedAmount,
            0,
            startPrice,
            liqPrice,
            _limitPrice,
            0,
            block.timestamp,
            0
        );
        tradeCount = tradeCount + 1;
        tradeInfo.count = tradeInfo.count + 1;
    }

    function getBorrowableAmount(uint256 _pid) public view returns(uint256) {
        TradeInfo storage tradeInfo = tradeInfos[_pid];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 available = pool.totalDepositAmount.add(tradeInfo.totalReturnedAmount).sub(tradeInfo.totalBorrowedAmount).add(investAmount[address(pool.token)]);
        uint256 maxAmount = tradingHelper.getMaxBorrowAmount(_pid);
        return available >= maxAmount ? maxAmount : available;
    }

    function getEstLiqudationPrice(uint256 _pid, uint256 _borrowAmount, uint256 _collateralAmount) public view returns(uint256) {
        uint256 estimateSwapAmount = 0;
        require(_borrowAmount >= _collateralAmount, "wrong borrow amount");
        if(_pid == 0) {
            estimateSwapAmount = tradingHelper.getEstimateUSDC(_borrowAmount);
            return estimateSwapAmount.mul(1e14).div(_borrowAmount.sub(_collateralAmount));
        } else {
            estimateSwapAmount = tradingHelper.getEstimateWETH(_borrowAmount);
            return _borrowAmount.sub(_collateralAmount).mul(1e14).div(estimateSwapAmount);
        }
    }

    function getBorrowFee(uint256 _tradeId) public view returns(uint256) {
        Trade storage trade = trades[_tradeId];
        uint256 endTime = trade.endTime;
        if(trade.isTrading) {
            endTime = block.timestamp;
        }
        uint256 fee = trade.borrowAmount.mul(endTime.sub(trade.startTime)).mul(tradingHelper.fundsBackTax()).div(1 days).div(feeDenominator);
        return fee;
    }

    function endTrade(uint256 _tradeId) public {
        Trade storage trade = trades[_tradeId];
        require(msg.sender == trade.user || tradingHelper.isAutoEnder(msg.sender), "wrong permission");
        // _pid = 0: weth pool, _pid = 1: usdc pool
        // _pid = 0 ? short : long
        require(trade.pid < 2, "wrong pool id");
        PoolInfo storage pool = poolInfo[trade.pid];
        UserInfo storage user = userInfo[trade.pid][trade.user];
        TradeInfo storage tradeInfo = tradeInfos[trade.pid];

        require(user.isTrading, "not started yet");
        require(trade.isTrading, "not started yet");

        uint256 lastAmount;
        
        if(trade.pid == 1) {
            poolInfo[0].token.safeIncreaseAllowance(address(tradingHelper), trade.swappedAmount);
            lastAmount = tradingHelper.SwapWETH(trade.swappedAmount);
        } else {
            poolInfo[1].token.safeIncreaseAllowance(address(tradingHelper), trade.swappedAmount);
            lastAmount = tradingHelper.SwapToWETH(trade.swappedAmount);
        }

        trade.returnAmount = lastAmount;
        trade.endPrice = tradingHelper.getETHprice();
        tradeInfo.totalReturnedAmount = tradeInfo.totalReturnedAmount.add(lastAmount);

        updatePool(trade.pid);
        uint256 _pending = user.amount.mul(pool.accDreamPerShare).div(1e18).sub(user.rewardDebt);
        if (_pending > 0) {
            safeDreamTransfer(trade.user, _pending);
            emit RewardPaid(trade.user, _pending);
        }

        uint256 borrowFee = getBorrowFee(_tradeId);
        uint256 feeAmount = 0;
        if(lastAmount >= trade.borrowAmount.add(borrowFee)) {
            uint256 profit = lastAmount.sub(trade.borrowAmount).sub(borrowFee);
            tradeInfo.totalProfit = tradeInfo.totalProfit.add(profit);
            uint256 profitFee = profit.mul(tradingHelper.profitTax()).div(feeDenominator);
            profit = profit.sub(profitFee);
            feeAmount = borrowFee.add(profitFee);
            if(profit > 0) {
                user.amount = user.amount.add(profit);
                user.totalProfit += int256(profit);
                trade.profit += int256(profit);
            }
        } else {
            uint256 loss = 0;
            if(lastAmount < trade.borrowAmount) {
                loss = trade.borrowAmount.sub(lastAmount);
                if(user.amount > loss) {
                    user.amount = user.amount.sub(loss);
                    if(user.amount > borrowFee) {
                        user.amount = user.amount.sub(borrowFee);
                        feeAmount = borrowFee;
                    } else {
                        feeAmount = user.amount;
                        user.amount = 0;
                    }
                } else {
                    user.amount = 0;
                }
                loss = loss.add(borrowFee);
            } else {
                loss = trade.borrowAmount.add(borrowFee).sub(lastAmount);
                if(user.amount > loss) {
                    user.amount = user.amount.sub(loss);
                    feeAmount = borrowFee;
                } else {
                    feeAmount = user.amount;
                    user.amount = 0;
                }
            }
        }

        trade.endTime = block.timestamp;
        tradeInfo.lastTradeEndTime = block.timestamp;
        tradeInfo.feeAmount = tradeInfo.feeAmount.add(feeAmount);
        user.rewardDebt = user.amount.mul(pool.accDreamPerShare).div(1e18);
        user.isTrading = false;
        trade.isTrading = false;
    }

    function needToEnd(uint256 _tradeId) public view returns (bool) {
        Trade storage trade = trades[_tradeId];
        // PoolInfo storage pool = poolInfo[trade.pid];
        UserInfo storage user = userInfo[trade.pid][trade.user];

        require(trade.isTrading, "not started yet");

        uint256 borrowFee = getBorrowFee(_tradeId);
        uint256 estimateAmount = 0;

        if(trade.pid == 0) {
            estimateAmount = tradingHelper.getEstimateWETH(trade.swappedAmount);
        } else {
            estimateAmount = tradingHelper.getEstimateUSDC(trade.swappedAmount);
        }

        if(estimateAmount.mul(95).div(100) <= trade.borrowAmount.add(borrowFee).sub(user.amount)){
            return true;
        } else {
            if(trade.limitPrice == 0) {
                return false;
            } else {
                if(trade.pid == 1) {
                    return trade.limitPrice <= tradingHelper.getETHprice();
                } else {
                    return trade.limitPrice >= tradingHelper.getETHprice();
                }
            }
        }
    }

    function getUserTradeInfo(uint256 _pid, address _account) public view returns(Trade memory) {
        UserInfo storage user = userInfo[_pid][_account];
        return trades[user.currentTradeId];
    }

    function getActiveTrades() public view returns(uint256[] memory) {
        uint256 count = 0;
        for(uint256 i = 0; i < tradeCount; i++) {
            if(trades[i].isTrading) {
                count += 1;
            }
        }
        uint256[] memory activeTrades = new uint256[](count);
        uint256 k = 0;
        for(uint256 i = 0; i < tradeCount; i++) {
            if(trades[i].isTrading) {
                activeTrades[k] = trades[i].id;
                k += 1;
            }
        }
        return activeTrades;
    }

    function getNeedToEndTrades() external view returns(uint256[] memory) {
        uint256[] memory activeTrades = getActiveTrades();
        uint256 count = 0;
        for(uint256 i = 0; i < activeTrades.length; i++) {
            if(needToEnd(activeTrades[i])) {
                count += 1;
            }
        }

        uint256[] memory needEndTrades = new uint256[](count);
        uint256 k = 0;
        for(uint256 i = 0; i < activeTrades.length; i++) {
            if(needToEnd(activeTrades[i])) {
                needEndTrades[k] = activeTrades[i];
                k += 1;
            }
        }
        return needEndTrades;
    }

    function getLatestEndTrades(uint256 length) external view returns(Trade[] memory) {
        uint256 tEndCount = 0;
        if(tradeCount < 1) {
            length = 0;
        } else {
            for(uint256 i = tradeCount; i > 0; i-- ){
                if(!trades[i-1].isTrading) {
                    tEndCount += 1;
                }
            }
            if(length > tEndCount) {
                length = tEndCount;
            }
        }
        Trade[] memory endTrades = new Trade[](length);
        if(length > 0) {
            uint256 k = 0;
            for(uint256 i = tradeCount; i > 0; i-- ){
                if(!trades[i-1].isTrading) {
                    endTrades[k] = trades[i-1];
                    k += 1;
                    if(k == length) {
                        break;
                    }
                }
            }
        }
        return endTrades;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}