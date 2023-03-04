// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './SafeMath.sol';
import './IERC20.sol';
import './SafeERC20.sol';
import './Ownable.sol';
import "./SharkyToken.sol";

// import "@nomiclabs/buidler/console.sol";

// MasterChef is the master of Sharky. He can make Sharky and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SHARKY is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of SHARKYs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accSharkyPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accSharkyPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SHARKYs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that SHARKYs distribution occurs.
        uint256 accSharkyPerShare; // Accumulated SHARKYs per share, times 1e12. See below.
    }

    // The SHARKY TOKEN!
    SharkyToken public sharky;
    // SHARKY tokens created per block - ownerFee.
    uint256 public sharkyPerBlock;
    // Bonus muliplier for early sharky makers.
    uint256 public BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // Allocation ratio for pool 0
    uint8 public allocRatio = 2;
    // The block number when SHARKY mining starts.
    uint256 public startBlock;
    // Owner fee
    uint256 public constant ownerFee = 2000; // 20%

    mapping (address => bool) public lpTokenAdded;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        SharkyToken _sharky,
        uint256 _sharkyPerBlock,
        uint256 _startBlock
    ) {
        sharky = _sharky;
        sharkyPerBlock = _sharkyPerBlock;
        startBlock = _startBlock;

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _sharky,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accSharkyPerShare: 0
        }));

        totalAllocPoint = 1000;
        lpTokenAdded[address(_sharky)] = true;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        require(lpTokenAdded[address(_lpToken)] == false, 'Pool for this token already exists!');
        lpTokenAdded[address(_lpToken)] = true;

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSharkyPerShare: 0
        }));
        updateStakingPool();
    }

    // Update the given pool's SHARKY allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
    }

    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(allocRatio);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending SHARKYs on frontend.
    function pendingSharky(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSharkyPerShare = pool.accSharkyPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sharkyReward = multiplier.mul(sharkyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSharkyPerShare = accSharkyPerShare.add(sharkyReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSharkyPerShare).div(1e12).sub(user.rewardDebt);
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
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sharkyReward = multiplier.mul(sharkyPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        sharky.mint(sharkyReward);
        pool.accSharkyPerShare = pool.accSharkyPerShare.add(sharkyReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;

        // mint ownerFee
        sharky.mintFor(owner(), sharkyReward.mul(ownerFee).div(10000));
    }

    // Deposit LP tokens to MasterChef for SHARKY allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSharkyPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeSharkyTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            // Thanks for RugDoc advice
            uint256 before = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 _after = pool.lpToken.balanceOf(address(this));
            _amount = _after.sub(before);
            // Thanks for RugDoc advice

            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSharkyPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Stake SHARKY tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        deposit(0, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSharkyPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeSharkyTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSharkyPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw SHARKY tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        withdraw(0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe SHARKY transfer function, just in case if rounding error causes pool to not have enough SHARKY.
    function safeSharkyTransfer(address _to, uint256 _amount) internal {
        sharky.safeSharkyTransfer(_to, _amount);
    }

    // Update pool 0 allocation ratio. Can only be called by the owner.
    function setAllocRatio(uint8 _allocRatio) public onlyOwner {
        require(
            _allocRatio >= 1 && _allocRatio <= 10, 
            "Allocation ratio must be in range 1-10"
        );

        allocRatio = _allocRatio;
    }

    function setSharkyPerBlock(uint _value) public onlyOwner {
        sharkyPerBlock = _value;
    }
}