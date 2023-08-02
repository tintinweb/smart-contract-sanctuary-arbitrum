/**
 *Submitted for verification at Arbiscan on 2023-08-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface INFT {
    function addTokenReward(uint256 rewardAmount) external;
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

interface ISwapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IToken {
    function giveMintReward() external;

    function addUserLPAmount(address account, uint256 lpAmount) external;
}

abstract contract AbsLPPool is Ownable {
    struct UserInfo {
        bool isActive;
        uint256 amount;
        uint256 rewardMintDebt;
        uint256 calMintReward;
    }

    struct PoolInfo {
        uint256 totalAmount;
        uint256 accMintPerShare;
        uint256 accMintReward;
        uint256 mintPerSec;
        uint256 lastMintTime;
        uint256 totalMintReward;
    }

    struct UserLPInfo {
        uint256 lockAmount;
        uint256 calAmount;
        uint256 claimedAmount;
        uint256 lastReleaseTime;
        //开始释放时的总量
        uint256 releaseInitAmount;
        //释放周期
        uint256 releaseDuration;
        uint256 speedUpTime;
    }

    PoolInfo private poolInfo;
    mapping(address => UserInfo) private userInfo;
    mapping(address => UserLPInfo) private _userLPInfo;

    ISwapRouter private immutable _swapRouter;
    address private immutable _usdt;
    uint256 private _minAmount;
    address private immutable _mintRewardToken;
    address public immutable _lp;
    INFT public _nft;

    mapping(address => address) public _invitor;
    mapping(address => address[]) public _binder;
    mapping(uint256 => uint256) public _inviteFee;
    uint256 private constant _inviteLen = 2;
    address private _defaultInvitor;

    mapping(address => uint256) private _inviteAmount;

    bool public _pauseSell;
    uint256 public _sellSelfRate = 5000;
    uint256 public _sellJoinRate = 4000;
    uint256 public _sellNFTRate = 500;
    address public _sellLPReceiver;
    mapping(address => uint256) private _sellJoinAmount;
    address public _fundAddress;

    function setPauseSell(bool p) external onlyWhiteList {
        _pauseSell = p;
    }

    function setSellSelfRate(uint256 r) external onlyWhiteList {
        _sellSelfRate = r;
        require(_sellSelfRate + _sellJoinRate + _sellNFTRate <= 10000, "T1w");
    }

    function setSellJoinRate(uint256 r) external onlyWhiteList {
        _sellJoinRate = r;
        require(_sellSelfRate + _sellJoinRate + _sellNFTRate <= 10000, "T1w");
    }

    function setSellNFTRate(uint256 r) external onlyWhiteList {
        _sellNFTRate = r;
        require(_sellSelfRate + _sellJoinRate + _sellNFTRate <= 10000, "T1w");
    }

    function setSellLPReceiver(address a) external onlyWhiteList {
        _sellLPReceiver = a;
    }

    function setFundAddress(address a) external onlyWhiteList {
        _fundAddress = a;
    }

    //卖出复投
    function sell(uint256 tokenAmount) public {
        address account = msg.sender;
        require(account == tx.origin, "notOrigin");

        _bindInvitor(account, _defaultInvitor);

        require(!_pauseSell, "PS");
        _takeToken(_mintRewardToken, account, address(this), tokenAmount);

        address usdt = _usdt;
        IERC20 USDT = IERC20(usdt);
        uint256 usdtBalanceBefore = USDT.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = _mintRewardToken;
        path[1] = usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );

        uint256 usdtAmount = USDT.balanceOf(address(this)) - usdtBalanceBefore;
        uint256 selfUsdt = usdtAmount * _sellSelfRate / 10000;
        _giveToken(usdt, account, selfUsdt);

        uint256 sellJoinUsdt = usdtAmount * _sellJoinRate / 10000;
        addLP(account, sellJoinUsdt, 0, false);

        _updatePool();
        uint256 sellJoinAmount = sellJoinUsdt * _lastAmountRate / _divFactor;
        _addUserAmount(account, sellJoinAmount, false);
        _sellJoinAmount[account] += sellJoinAmount;

        uint256 nftUsdt = usdtAmount * _sellNFTRate / 10000;
        _giveToken(usdt, address(_nft), nftUsdt);
        _nft.addTokenReward(nftUsdt);

        uint256 fundUsdt = usdtAmount - selfUsdt - sellJoinUsdt - nftUsdt;
        _giveToken(usdt, _fundAddress, fundUsdt);

        IToken(_mintRewardToken).giveMintReward();
    }

    bool private _pauseJoin = true;
    uint256 public _lastDailyUpTime;
    uint256 public _lastAmountRate = 10000;
    uint256 public _amountDailyUp = 10100;
    uint256 private constant _divFactor = 10000;
    uint256 private constant _dailyDuration = 1 days;

    uint256 public _lpReleaseDuration = 365 days;
    //LP加速释放
    uint256 private _speedUpCost;
    uint256 public _speedUpDuration = 30 days;
    address public _speedUpReceiver = address(0x000000000000000000000000000000000000dEaD);
    uint256 private _speedUpMaxTime = 6;

    function setSpeedUpMaxTime(uint256 mt) external onlyWhiteList {
        _speedUpMaxTime = mt;
    }

    function setSpeedUpCost(uint256 c) external onlyWhiteList {
        _speedUpCost = c;
    }

    function setSpeedUpDuration(uint256 d) external onlyWhiteList {
        _speedUpDuration = d;
    }

    function setSeedUpReceiver(address a) external onlyWhiteList {
        _speedUpReceiver = a;
    }

    function setLPReleaseDuration(uint256 d) external onlyWhiteList {
        require(d > 0, "gt0");
        _lpReleaseDuration = d;
    }

    function setAmountDailyUp(uint256 r) external onlyWhiteList {
        _amountDailyUp = r;
    }

    function setLastDailyUpTime(uint256 t) external onlyWhiteList {
        _lastDailyUpTime = t;
    }

    function setLastAmountRate(uint256 r) external onlyWhiteList {
        _lastAmountRate = r;
    }

    function _updateDailyUpRate() public {
        uint256 lastDailyUpTime = _lastDailyUpTime;
        if (0 == lastDailyUpTime) {
            return;
        }
        uint256 dailyDuration = _dailyDuration;
        uint256 nowTime = block.timestamp;
        if (nowTime < lastDailyUpTime + dailyDuration) {
            return;
        }
        uint256 ds = (nowTime - lastDailyUpTime) / dailyDuration;
        _lastDailyUpTime = lastDailyUpTime + ds * dailyDuration;

        uint256 lastAmountRate = _lastAmountRate;
        uint256 amountDailyUp = _amountDailyUp;
        for (uint256 i; i < ds; ++i) {
            lastAmountRate = lastAmountRate * amountDailyUp / _divFactor;
        }
        _lastAmountRate = lastAmountRate;
    }

    function getDailyRate() private view returns (uint256) {
        uint256 lastAmountRate = _lastAmountRate;
        uint256 lastDailyUpTime = _lastDailyUpTime;
        if (0 == lastDailyUpTime) {
            return lastAmountRate;
        }
        uint256 dailyDuration = _dailyDuration;
        uint256 nowTime = block.timestamp;
        if (nowTime < lastDailyUpTime + dailyDuration) {
            return lastAmountRate;
        }
        uint256 ds = (nowTime - lastDailyUpTime) / dailyDuration;

        uint256 amountDailyUp = _amountDailyUp;
        for (uint256 i; i < ds; ++i) {
            lastAmountRate = lastAmountRate * amountDailyUp / _divFactor;
        }
        return lastAmountRate;
    }

    function open() external onlyWhiteList {
        if (0 == _lastDailyUpTime) {
            _lastDailyUpTime = block.timestamp;
        }
        _pauseJoin = false;
    }

    function close() external onlyWhiteList {
        _pauseJoin = true;
    }

    constructor(
        address SwapRouter,
        address USDT,
        address MintRewardToken,
        address NFT,
        address DefaultInvitor,
        address FundAddress
    ){
        _swapRouter = ISwapRouter(SwapRouter);
        _usdt = USDT;
        _minAmount = 100 * 10 ** IERC20(USDT).decimals();
        _nft = INFT(NFT);
        _mintRewardToken = MintRewardToken;
        _lp = ISwapFactory(_swapRouter.factory()).getPair(USDT, MintRewardToken);
        poolInfo.lastMintTime = block.timestamp;
        _defaultInvitor = DefaultInvitor;
        userInfo[DefaultInvitor].isActive = true;
        _inviteFee[0] = 2000;
        _inviteFee[1] = 1000;
        _speedUpCost = 10 * 10 ** IERC20(_usdt).decimals();

        safeApprove(USDT, SwapRouter, ~uint256(0));
        safeApprove(MintRewardToken, SwapRouter, ~uint256(0));

        _sellLPReceiver = FundAddress;
        _fundAddress = FundAddress;
    }

    receive() external payable {}

    uint256 private _totalUsdt;

    //使用USDT参与挖矿
    function deposit(uint256 amount, uint256 minTokenAmount, address invitor) external {
        require(!_pauseJoin, "pause");

        require(amount >= _minAmount, "m");
        address account = msg.sender;
        require(account == tx.origin, "notOrigin");

        _totalUsdt += amount;

        _bindInvitor(account, invitor);

        _takeToken(_usdt, account, address(this), amount);

        addLP(account, amount, minTokenAmount, true);

        _updatePool();
        _addUserAmount(account, amount * _lastAmountRate / _divFactor, true);

        IToken(_mintRewardToken).giveMintReward();
    }

    //参与加池子或者卖出加池子，一半U买币再加池子
    function addLP(address account, uint256 usdtAmount, uint256 minTokenAmount, bool lockLP) private {
        address token = _mintRewardToken;
        IERC20 Token = IERC20(token);
        uint256 tokenBalanceBefore = Token.balanceOf(address(this));

        address usdt = _usdt;
        address[] memory path = new address[](2);
        path[0] = usdt;
        path[1] = token;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            usdtAmount / 2, minTokenAmount, path, address(this), block.timestamp
        );

        uint256 tokenAmount = Token.balanceOf(address(this)) - tokenBalanceBefore;

        address lpReceiver = lockLP ? address(this) : _sellLPReceiver;
        (, , uint liquidity) = _swapRouter.addLiquidity(
            usdt, token,
            usdtAmount / 2, tokenAmount,
            0, 0,
            lpReceiver, block.timestamp
        );
        //锁仓LP
        if (lockLP) {
            _addLockLP(account, liquidity);
        } else {
            IToken(_mintRewardToken).addUserLPAmount(lpReceiver, liquidity);
        }
    }

    //增加锁仓LP
    function _addLockLP(address account, uint liquidity) private {
        UserLPInfo storage userLPInfo = _userLPInfo[account];
        uint256 lastReleaseTime = userLPInfo.lastReleaseTime;
        uint256 nowTime = block.timestamp;
        if (lastReleaseTime > 0 && nowTime > lastReleaseTime) {
            uint256 releaseAmount = userLPInfo.releaseInitAmount * (nowTime - lastReleaseTime) / userLPInfo.releaseDuration;
            uint256 maxAmount = userLPInfo.lockAmount - userLPInfo.calAmount - userLPInfo.claimedAmount;
            if (releaseAmount > maxAmount) {
                releaseAmount = maxAmount;
            }
            userLPInfo.calAmount += releaseAmount;
        }
        uint256 remainAmount = userLPInfo.lockAmount - userLPInfo.calAmount - userLPInfo.claimedAmount;
        userLPInfo.lockAmount += liquidity;
        userLPInfo.releaseInitAmount = remainAmount + liquidity;
        userLPInfo.releaseDuration = _lpReleaseDuration;

        if (nowTime > lastReleaseTime) {
            userLPInfo.lastReleaseTime = nowTime;
        }
    }

    //领取LP
    function claimLP() public {
        address account = msg.sender;
        require(account == tx.origin, "notOrigin");
        UserLPInfo storage userLPInfo = _userLPInfo[account];
        uint256 lastReleaseTime = userLPInfo.lastReleaseTime;
        uint256 nowTime = block.timestamp;
        if (lastReleaseTime > 0 && nowTime > lastReleaseTime) {
            uint256 releaseAmount = userLPInfo.releaseInitAmount * (nowTime - lastReleaseTime) / userLPInfo.releaseDuration;
            uint256 maxAmount = userLPInfo.lockAmount - userLPInfo.calAmount - userLPInfo.claimedAmount;
            if (releaseAmount > maxAmount) {
                releaseAmount = maxAmount;
            }
            userLPInfo.calAmount += releaseAmount;
        }

        uint256 calAmount = userLPInfo.calAmount;
        if (calAmount > 0) {
            _giveToken(_lp, account, calAmount);
            userLPInfo.calAmount = 0;
            userLPInfo.claimedAmount += calAmount;
            IToken(_mintRewardToken).addUserLPAmount(account, calAmount);
        }

        if (nowTime > lastReleaseTime) {
            userLPInfo.lastReleaseTime = nowTime;
        }

        IToken(_mintRewardToken).giveMintReward();
    }

    //加速LP释放
    function speedUpLP(uint256 maxTokenAmount) public {
        address account = msg.sender;
        require(account == tx.origin, "notOrigin");
        UserLPInfo storage userLPInfo = _userLPInfo[account];
        uint256 lastReleaseTime = userLPInfo.lastReleaseTime;
        uint256 nowTime = block.timestamp;
        if (lastReleaseTime > 0 && nowTime > lastReleaseTime) {
            uint256 releaseAmount = userLPInfo.releaseInitAmount * (nowTime - lastReleaseTime) / userLPInfo.releaseDuration;
            uint256 maxAmount = userLPInfo.lockAmount - userLPInfo.calAmount - userLPInfo.claimedAmount;
            if (releaseAmount > maxAmount) {
                releaseAmount = maxAmount;
            }
            userLPInfo.calAmount += releaseAmount;
        }

        if (nowTime > lastReleaseTime) {
            userLPInfo.lastReleaseTime = nowTime;
        }

        require(userLPInfo.speedUpTime < _speedUpMaxTime, "MT");
        userLPInfo.speedUpTime++;
        uint256 tokenAmount = getSpeedUpTokenAmount();
        require(tokenAmount <= maxTokenAmount, "MA");
        _takeToken(_mintRewardToken, account, _speedUpReceiver, tokenAmount);

        //剩余解锁数量和剩余解锁时间
        uint256 remainAmount = userLPInfo.lockAmount - userLPInfo.calAmount - userLPInfo.claimedAmount;
        uint256 remainDuration = remainAmount * userLPInfo.releaseDuration / userLPInfo.releaseInitAmount;

        //更新解锁周期，周期总额度
        userLPInfo.releaseInitAmount = remainAmount;
        uint256 speedUpDuration = _speedUpDuration;
        require(remainDuration > speedUpDuration, "RltS");
        userLPInfo.releaseDuration = remainDuration - speedUpDuration;

        IToken(_mintRewardToken).giveMintReward();
    }

    function getSpeedUpTokenAmount() private view returns (uint256 tokenAmount){
        (uint256 rUsdt, uint256 rToken) = _getReserves();
        tokenAmount = _speedUpCost * rToken / rUsdt;
    }

    function _getReserves() public view returns (uint256 rUsdt, uint256 rToken){
        ISwapPair pair = ISwapPair(_lp);
        (uint r0, uint256 r1,) = pair.getReserves();

        if (_usdt < _mintRewardToken) {
            rUsdt = r0;
            rToken = r1;
        } else {
            rUsdt = r1;
            rToken = r0;
        }
    }

    function getJoinTokenAmountOut(uint256 usdtAmount) public view returns (uint256 tokenAmount){
        address[] memory path = new address[](2);
        path[0] = _usdt;
        path[1] = _mintRewardToken;
        uint256[] memory amounts = _swapRouter.getAmountsOut(usdtAmount / 2, path);
        tokenAmount = amounts[1];
    }

    function getSellUsdtOut(uint256 tokenAmount) public view returns (
        uint256 usdtAmount, uint256 selfUsdt, uint256 mintAmount
    ){
        address[] memory path = new address[](2);
        path[0] = _mintRewardToken;
        path[1] = _usdt;
        uint256[] memory amounts = _swapRouter.getAmountsOut(tokenAmount, path);
        usdtAmount = amounts[1];
        selfUsdt = usdtAmount * _sellSelfRate / 10000;
        mintAmount = usdtAmount * _sellJoinRate / 10000;
        mintAmount = mintAmount * getDailyRate() / 10000;
    }

    //增加算力内部方法
    function _addUserAmount(address account, uint256 amount, bool calInvite) private {
        UserInfo storage user = userInfo[account];
        _calReward(user, false);

        uint256 userAmount = user.amount;
        userAmount += amount;
        user.amount = userAmount;

        uint256 poolTotalAmount = poolInfo.totalAmount;
        poolTotalAmount += amount;

        uint256 poolAccMintPerShare = poolInfo.accMintPerShare;
        user.rewardMintDebt = userAmount * poolAccMintPerShare / 1e18;

        if (calInvite) {
            uint256 len = _inviteLen;
            UserInfo storage invitorInfo;
            address current = account;
            address invitor;
            uint256 invitorTotalAmount;
            address defaultInvitor = _defaultInvitor;
            for (uint256 i; i < len; ++i) {
                invitor = _invitor[current];
                if (address(0) == invitor) {
                    break;
                }
                invitorInfo = userInfo[invitor];
                if (invitorInfo.amount >= userAmount || invitor == defaultInvitor) {
                    _calReward(invitorInfo, false);
                    uint256 inviteAmount = amount * _inviteFee[i] / 10000;
                    _inviteAmount[invitor] += inviteAmount;

                    invitorTotalAmount = invitorInfo.amount;
                    invitorTotalAmount += inviteAmount;
                    invitorInfo.amount = invitorTotalAmount;
                    invitorInfo.rewardMintDebt = invitorTotalAmount * poolAccMintPerShare / 1e18;

                    poolTotalAmount += inviteAmount;
                }
                current = invitor;
            }
        }
        poolInfo.totalAmount = poolTotalAmount;
    }

    //增加挖矿算力
    function addUserAmount(address account, uint256 amount, bool calInvite) public {
        require(_inProject[msg.sender], "rq project");
        _updatePool();
        _addUserAmount(account, amount, calInvite);
    }

    //增加挖矿算力
    function addMintAmount(address account, uint256 amount) external onlyWhiteList {
        _updatePool();
        _addUserAmount(account, amount, false);
    }

    //领取收益
    function claim() public {
        address account = msg.sender;
        UserInfo storage user = userInfo[account];
        _calReward(user, true);
        uint256 pendingMint = user.calMintReward;
        if (pendingMint > 0) {
            _giveToken(_mintRewardToken, account, pendingMint);
            user.calMintReward = 0;
        }

        IToken(_mintRewardToken).giveMintReward();
    }

    //更新池子信息
    function _updatePool() private {
        _updateDailyUpRate();
        PoolInfo storage pool = poolInfo;
        uint256 blockTime = block.timestamp;
        uint256 lastRewardTime = pool.lastMintTime;
        if (blockTime <= lastRewardTime) {
            return;
        }
        pool.lastMintTime = blockTime;

        uint256 accReward = pool.accMintReward;
        uint256 totalReward = pool.totalMintReward;
        if (accReward >= totalReward) {
            return;
        }

        uint256 totalAmount = pool.totalAmount;
        uint256 rewardPerSec = pool.mintPerSec;
        if (0 < totalAmount && 0 < rewardPerSec) {
            uint256 reward = rewardPerSec * (blockTime - lastRewardTime);
            uint256 remainReward = totalReward - accReward;
            if (reward > remainReward) {
                reward = remainReward;
            }
            pool.accMintPerShare += reward * 1e18 / totalAmount;
            pool.accMintReward += reward;
        }
    }

    //计算用户待领取
    function _calReward(UserInfo storage user, bool updatePool) private {
        if (updatePool) {
            _updatePool();
        }
        if (user.amount > 0) {
            uint256 accMintReward = user.amount * poolInfo.accMintPerShare / 1e18;
            uint256 pendingMintAmount = accMintReward - user.rewardMintDebt;
            if (pendingMintAmount > 0) {
                user.rewardMintDebt = accMintReward;
                user.calMintReward += pendingMintAmount;
            }
        }
    }

    function getPendingMintReward(address account) public view returns (uint256 reward) {
        reward = 0;
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[account];
        if (user.amount > 0) {
            uint256 poolPendingReward;
            uint256 blockTime = block.timestamp;
            uint256 lastRewardTime = pool.lastMintTime;
            if (blockTime > lastRewardTime) {
                poolPendingReward = pool.mintPerSec * (blockTime - lastRewardTime);
                uint256 totalReward = pool.totalMintReward;
                uint256 accReward = pool.accMintReward;
                uint256 remainReward;
                if (totalReward > accReward) {
                    remainReward = totalReward - accReward;
                }
                if (poolPendingReward > remainReward) {
                    poolPendingReward = remainReward;
                }
            }
            reward = user.amount * (pool.accMintPerShare + poolPendingReward * 1e18 / pool.totalAmount) / 1e18 - user.rewardMintDebt;
        }
    }

    function viewPoolInfo() public view returns (
        uint256 totalAmount,
        uint256 accMintPerShare, uint256 accMintReward,
        uint256 mintPerSec, uint256 lastMintTime, uint256 totalMintReward
    ) {
        totalAmount = poolInfo.totalAmount;
        accMintPerShare = poolInfo.accMintPerShare;
        accMintReward = poolInfo.accMintReward;
        mintPerSec = poolInfo.mintPerSec;
        lastMintTime = poolInfo.lastMintTime;
        totalMintReward = poolInfo.totalMintReward;
    }

    function viewUserInfo(address account) public view returns (
        bool isActive, uint256 amount,
        uint256 calMintReward, uint256 rewardMintDebt
    ) {
        UserInfo storage user = userInfo[account];
        isActive = user.isActive;
        amount = user.amount;
        calMintReward = user.calMintReward;
        rewardMintDebt = user.rewardMintDebt;
    }

    function getUserLPInfo(address account) public view returns (
        uint256 lockAmount,
        uint256 calAmount,
        uint256 claimedAmount,
        uint256 lastReleaseTime,
        uint256 releaseInitAmount,
        uint256 releaseDuration,
        uint256 speedUpTime,
        uint256 tokenBalance,
        uint256 tokenAllowance
    ) {
        UserLPInfo storage userLPInfo = _userLPInfo[account];
        lockAmount = userLPInfo.lockAmount;
        calAmount = userLPInfo.calAmount;
        claimedAmount = userLPInfo.claimedAmount;
        releaseInitAmount = userLPInfo.releaseInitAmount;
        releaseDuration = userLPInfo.releaseDuration;
        speedUpTime = userLPInfo.speedUpTime;
        lastReleaseTime = userLPInfo.lastReleaseTime;
        tokenBalance = IERC20(_mintRewardToken).balanceOf(account);
        tokenAllowance = IERC20(_mintRewardToken).allowance(account, address(this));
    }

    function getUserInfo(address account) public view returns (
        uint256 amount, uint256 usdtBalance, uint256 usdtAllowance,
        uint256 pendingMintReward, uint256 inviteAmount, uint256 sellJoinAmount
    ) {
        UserInfo storage user = userInfo[account];
        amount = user.amount;
        usdtBalance = IERC20(_usdt).balanceOf(account);
        usdtAllowance = IERC20(_usdt).allowance(account, address(this));
        pendingMintReward = getPendingMintReward(account) + user.calMintReward;
        inviteAmount = _inviteAmount[account];
        sellJoinAmount = _sellJoinAmount[account];
    }

    function getBaseInfo() external view returns (
        address usdt,
        uint256 usdtDecimals,
        address mintRewardToken,
        uint256 mintRewardTokenDecimals,
        uint256 totalUsdt,
        uint256 totalAmount,
        uint256 lastDailyReward,
        uint256 dailyAmountRate,
        uint256 minAmount,
        address defaultInvitor,
        bool pauseJoin
    ){
        usdt = _usdt;
        usdtDecimals = IERC20(usdt).decimals();
        mintRewardToken = _mintRewardToken;
        mintRewardTokenDecimals = IERC20(mintRewardToken).decimals();
        totalUsdt = _totalUsdt;
        totalAmount = poolInfo.totalAmount;
        lastDailyReward = _lastDailyReward;
        dailyAmountRate = getDailyRate();
        minAmount = _minAmount;
        defaultInvitor = _defaultInvitor;
        pauseJoin = _pauseJoin;
    }

    function getLPInfo() external view returns (
        uint256 totalLP,
        uint256 lockLP,
        uint256 speedUpMaxTime,
        uint256 speedCostUsdt,
        uint256 speedCostToken
    ){
        totalLP = IERC20(_lp).totalSupply();
        lockLP = IERC20(_lp).balanceOf(address(this));
        speedUpMaxTime = _speedUpMaxTime;
        speedCostUsdt = _speedUpCost;
        speedCostToken = getSpeedUpTokenAmount();
    }

    function getBinderLength(address account) public view returns (uint256){
        return _binder[account].length;
    }

    //修改每秒产出
    function setMintPerSec(uint256 mintPerSec) external onlyWhiteList {
        _updatePool();
        poolInfo.mintPerSec = mintPerSec;
    }

    uint256 private _lastDailyReward;

    //增加挖矿产出
    function addTotalMintReward(uint256 reward) external {
        require(_inProject[msg.sender], "rq project");
        _updatePool();
        poolInfo.totalMintReward += reward;
        poolInfo.mintPerSec = reward / _dailyDuration;
        _lastDailyReward = reward;
    }

    //修改邀请算力比例
    function setInviteFee(uint256 i, uint256 fee) external onlyWhiteList {
        _inviteFee[i] = fee;
    }

    function claimBalance(address to, uint256 amount) external onlyWhiteList {
        safeTransferETH(to, amount);
    }

    function claimToken(address token, address to, uint256 amount) external onlyWhiteList {
        _giveToken(token, to, amount);
    }

    function setDefaultInvitor(address adr) external onlyWhiteList {
        _defaultInvitor = adr;
        userInfo[adr].isActive = true;
    }

    mapping(address => bool) public _inProject;

    function setInProject(address adr, bool enable) external onlyWhiteList {
        _inProject[adr] = enable;
    }

    function bindInvitor(address account, address invitor) public {
        address caller = msg.sender;
        require(_inProject[caller], "NA");
        _bindInvitor(account, invitor);
    }

    function _bindInvitor(address account, address invitor) private {
        UserInfo storage user = userInfo[account];
        if (!user.isActive) {
            require(address(0) != invitor, "invitor 0");
            require(userInfo[invitor].isActive, "invitor !Active");
            _invitor[account] = invitor;
            _binder[invitor].push(account);
            user.isActive = true;
        }
    }

    function getBinderList(
        address account,
        uint256 start,
        uint256 length
    ) external view returns (
        uint256 returnCount,
        address[] memory binders
    ){
        address[] storage _binders = _binder[account];
        uint256 recordLen = _binders.length;
        if (0 == length) {
            length = recordLen;
        }
        returnCount = length;
        binders = new address[](length);
        uint256 index = 0;
        for (uint256 i = start; i < start + length; i++) {
            if (i >= recordLen) {
                return (index, binders);
            }
            binders[index] = _binders[i];
            index++;
        }
    }

    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'AF');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'ETF');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TFF');
    }

    function _giveToken(address tokenAddress, address account, uint256 amount) private {
        if (0 == amount) {
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "PTNE");
        safeTransfer(tokenAddress, account, amount);
    }

    function _takeToken(address tokenAddress, address from, address to, uint256 tokenNum) private {
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(from)) >= tokenNum, "TNE");
        safeTransferFrom(tokenAddress, from, to, tokenNum);
    }

    modifier onlyWhiteList() {
        address msgSender = msg.sender;
        require(msgSender == _fundAddress || msgSender == _owner, "nw");
        _;
    }
}

contract MintPool is AbsLPPool {
    constructor() AbsLPPool(
    //SwapRouter,sushi
        address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506),
    //USDT6
        address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9),
    //BOS
        address(0xfd4f180534F3415eC621777Ae78Ae86A0678A493),
    //NFT
        address(0x32a8e2fF7C75F2c188018E5b6de536A76234fdE1),
    //DefaultInvitor
        address(0x005584053bfE94C9feDe05121327A13813DF4008),
    //Fund
        address(0x005584053bfE94C9feDe05121327A13813DF4008)
    ){

    }
}