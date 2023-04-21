/**
 *Submitted for verification at Arbiscan on 2023-04-21
*/

//Official Swaptrum Staking Contract - Version 1.5 - 14.04.2023

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Required contracts from OpenZeppelin (ERC20.sol and their dependencies)

// From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
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

// From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// From: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
contract ERC20 is Context, IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// Swaptrum Governance Token
contract SwaptrumGovernanceToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        _burn(from, amount);
    }
}

interface Token {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract SwaptrumStakingContract {
    address public immutable TOKEN;
    uint256 public immutable MIN_LOCKUP_DAYS = 30;
    uint256 public immutable MAX_LOCKUP_DAYS = 120;
    uint256 public constant MAX_APY = 2000; // max APY is 2000 (20%)
    address public owner;
    uint256 public rewardRate;

    struct Staker {
        mapping(uint256 => uint256) stakedAmount;
        mapping(uint256 => uint256) reward;
        mapping(uint256 => uint256) lastUpdated;
        mapping(uint256 => uint256) unlockTime;
    }

    struct Pool {
        uint256 lockupDays;
        uint256 apy;
        uint256 totalStaked;
        mapping(address => Staker) stakers;
    }

    mapping(uint256 => Pool) public pools;
    mapping(address => Staker) private stakers;

    event Staked(address indexed staker, uint256 amount, uint256 poolId);
    event Unstaked(address indexed staker, uint256 amount, uint256 poolId);
    event RewardsClaimed(address indexed staker, uint256 amount, uint256 poolId);

    SwaptrumGovernanceToken private governanceToken;

    constructor(address _token, uint256 _rewardRate, address _governanceToken) {
        TOKEN = _token;
        owner = msg.sender;
        rewardRate = _rewardRate;

        // add supported pools
        pools[1].lockupDays = 30;
        pools[1].apy = 50;
        pools[1].totalStaked = 0;

        pools[2].lockupDays = 60;
        pools[2].apy = 100;
        pools[2].totalStaked = 0;

        pools[3].lockupDays = 90;
        pools[3].apy = 150;
        pools[3].totalStaked = 0;

        pools[4].lockupDays = 120;
        pools[4].apy = 200;
        pools[4].totalStaked = 0;

        governanceToken = SwaptrumGovernanceToken(_governanceToken);
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        require(_rewardRate <= MAX_APY, "Reward rate too high");
        rewardRate = _rewardRate;
    }

    function approveTokens(uint256 amount) external {
        require(amount > 0, "Approval amount must be greater than 0");
        Token(0x620dA86403F5f9F8774454d6BB785A461f608C0E).approve(address(this), amount);
    }


    function stake(uint256 amount, uint256 poolId) external {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");
        Pool storage pool = pools[poolId];

        require(amount > 0, "Staking amount must be greater than 0");
        require(Token(TOKEN).transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // update staker's rewards in the pool they are staking
        updateRewards(msg.sender, poolId);

        Staker storage staker = pool.stakers[msg.sender];

        //staker.stakedAmount[poolId] = amount;
        staker.stakedAmount[poolId] += amount;
        staker.lastUpdated[poolId] = block.timestamp;
        staker.unlockTime[poolId] = block.timestamp + (pool.lockupDays * 1 days);
        pool.totalStaked += amount;

        // Mint governance tokens for the staker
        governanceToken.mint(msg.sender, amount);

        emit Staked(msg.sender, amount, poolId);
    }

    function unstake(uint256 poolId) external {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");

        Pool storage pool = pools[poolId];
        Staker storage staker = pool.stakers[msg.sender];

        require(block.timestamp >= staker.unlockTime[poolId], "Staking period has not ended yet");

        updateRewards(msg.sender, poolId);

        uint256 stakedAmount = staker.stakedAmount[poolId];
        require(stakedAmount > 0, "No staked amount");

        uint256 reward = getRewards(msg.sender, poolId);

        staker.stakedAmount[poolId] = 0;
        pool.totalStaked -= stakedAmount;
        require(Token(TOKEN).transfer(msg.sender, stakedAmount), "Transfer failed");

        // Burn governance tokens from the staker
        governanceToken.burn(msg.sender, stakedAmount);

        emit Unstaked(msg.sender, stakedAmount, poolId);
    }

    function claimRewards(uint256 poolId) external {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");

        updateRewards(msg.sender, poolId);

        uint256 reward = getRewards(msg.sender, poolId);
        require(reward > 0, "No rewards available");

        Staker storage staker = pools[poolId].stakers[msg.sender];
        staker.reward[poolId] = 0;
        require(Token(TOKEN).transfer(msg.sender, reward), "Transfer failed");

        emit RewardsClaimed(msg.sender, reward, poolId);
    }

    function updateRewards(address stakerAddress, uint256 poolId) private {
        Staker storage staker = pools[poolId].stakers[stakerAddress];
        Pool storage pool = pools[poolId];

        uint256 elapsedTime = block.timestamp - staker.lastUpdated[poolId];
        uint256 newReward = staker.stakedAmount[poolId] * elapsedTime * pool.apy / 365 days;
        staker.reward[poolId] += newReward;
        staker.lastUpdated[poolId] = block.timestamp;
    }

    function updateAllRewards(address stakerAddress) private {
        for (uint256 i = 1; i <= 4; i++) {
            Staker storage staker = pools[i].stakers[stakerAddress];
            Pool storage pool = pools[i];

            uint256 elapsedTime = block.timestamp - staker.lastUpdated[i];
            uint256 newReward = staker.stakedAmount[i] * elapsedTime * pool.apy / 365 days;
            staker.reward[i] += newReward;
            staker.lastUpdated[i] = block.timestamp;
        }
    }

    function getRewards(address stakerAddress, uint256 poolId) public view returns (uint256) {
        Staker storage staker = pools[poolId].stakers[stakerAddress];
        Pool storage pool = pools[poolId];
        uint256 elapsedTime = block.timestamp - staker.lastUpdated[poolId];
        uint256 newReward = staker.stakedAmount[poolId] * elapsedTime * pool.apy / 365 days;
        return staker.reward[poolId] + newReward;
    }

    function getStaker(address stakerAddress, uint256 poolId) internal view returns (Staker storage) {
        return pools[poolId].stakers[stakerAddress];
    }

    function getStakerStakedAmount(address stakerAddress, uint256 poolId) public view returns (uint256) {
        return getStaker(stakerAddress, poolId).stakedAmount[poolId];
    }

    function getStakerReward(address stakerAddress, uint256 poolId) public view returns (uint256) {
        return getStaker(stakerAddress, poolId).reward[poolId];
    }

    function getStakerLastUpdated(address stakerAddress, uint256 poolId) public view returns (uint256) {
        return getStaker(stakerAddress, poolId).lastUpdated[poolId];
    }

    function getStakerUnlockTime(address stakerAddress, uint256 poolId) public view returns (uint256) {
        return getStaker(stakerAddress, poolId).unlockTime[poolId];
    }

    function withdrawTokens() external onlyOwner {
        uint256 balance = Token(TOKEN).balanceOf(address(this));
        require(Token(TOKEN).transfer(msg.sender, balance), "Transfer failed");
    }

    function setPoolLockup(uint8 poolIndex, uint256 lockup) external onlyOwner {
        require(poolIndex < 5, "Invalid pool index");
        pools[poolIndex].lockupDays = lockup;
    }

    function setPoolAPY(uint8 poolIndex, uint256 apy) external onlyOwner {
        require(poolIndex < 5, "Invalid pool index");
        require(apy <= MAX_APY, "APY too high");
        pools[poolIndex].apy = apy;
    }

    function getTotalStakedTokens() public view returns (uint256) {
        uint256 totalStaked = 0;
        for (uint256 i = 1; i <= 4; i++) {
            totalStaked += pools[i].totalStaked;
        }
        return totalStaked;
    }

    function getCurrentPoolAPY(uint256 poolId) public view returns (uint256) {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");
        uint256 poolAPY = pools[poolId].apy;
        uint256 contractBalance = Token(TOKEN).balanceOf(address(this));

        if (contractBalance == 0) {
            return 0;
        }

        uint256 availableRewards = (contractBalance * rewardRate) / 100;
        uint256 totalStaked = getTotalStakedTokens();
        if (totalStaked == 0) {
            return 0;
        }

        uint256 apy = (availableRewards * 365 days * 100) / (totalStaked * poolAPY);
        return apy;
    }

    function getTotalValueLocked(uint256 tokenPrice) public view returns (uint256) {
        uint256 totalStaked = getTotalStakedTokens();
        uint256 totalValueLocked = totalStaked * tokenPrice;
        return totalValueLocked;
    }

    function getTokensStakedInPool(uint256 poolId) public view returns (uint256) {
        require(poolId >= 1 && poolId <= 4, "Invalid pool ID");
        return pools[poolId].totalStaked;
    }

    function getAllowance(address owner, address spender) public view returns (uint256) {
        return Token(TOKEN).allowance(owner, spender);
    }

    function calculateTotalRewards(address stakerAddress) public view returns (uint256) {
        uint256 totalRewards = 0;

        for (uint256 i = 1; i <= 4; i++) {
            totalRewards += getRewards(stakerAddress, i);
        }

        return totalRewards;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
}