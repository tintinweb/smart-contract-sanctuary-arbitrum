// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "OpenZeppelin/access/Ownable.sol";
import "OpenZeppelin/utils/math/SafeMath.sol";
import "../interfaces/ICauldronV4.sol";
import "OpenZeppelin/utils/math/Math.sol";
import "../interfaces/IMasterChef.sol";

// MasterChef is the master of Cake. He can make Cake and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CAKE is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, IMasterChef {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    // Info of each pool.
    struct PoolInfo {
        address stakeToken;
        address rewardToken;
        uint256 lastRewardTimestamp;
        uint256 rewardPerSecond;
        uint256 rewardPerShare; //multiply 1e20
        bool isDynamicReward;
    }

    uint256 public arvLastRelease;
    uint256 public arvCirculatingSupply;
    uint256 public totalVinLock;
    mapping(uint256 => uint256) public totalStake;
    mapping(address => LockDetail[]) public userLock;
    mapping(address => uint256) public userUnlockIndex;
    IStrictERC20 public arv;
    IStrictERC20 public inToken;
    IStrictERC20 public vin;
    IStrictERC20 public lp;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public cauldronPoolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => VestingInfo[]) public userVestingInfo;
    mapping(address => uint256) public userPendingReward;

    uint256 public constant LOCK_POOL = 0;
    uint256 public constant VIN_POOL = 1;
    uint256 public constant ARV_POOL = 2;
    uint256 public constant LP_POOL = 3;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(address _arv, address _vin, address _in, address _lp, uint256 startTimestamp) {
        arv = IStrictERC20(_arv);
        vin = IStrictERC20(_vin);
        inToken = IStrictERC20(_in);
        lp = IStrictERC20(_lp);
        arvLastRelease = block.timestamp - (block.timestamp % 1 days) + 1 days;
        // staking pool
        poolInfo.push(
            PoolInfo({
                stakeToken: address(0),
                rewardToken: address(0),
                lastRewardTimestamp: block.timestamp - (block.timestamp % 1 days) + 1 days,
                rewardPerSecond: uint256(100 ether) / 1 days,
                rewardPerShare: 0,
                isDynamicReward: false
            })
        );
        poolInfo.push(
            PoolInfo({
                stakeToken: _vin,
                rewardToken: _in,
                lastRewardTimestamp: startTimestamp,
                rewardPerSecond: 0,
                rewardPerShare: 0,
                isDynamicReward: true
            })
        );
        poolInfo.push(
            PoolInfo({
                stakeToken: _arv,
                rewardToken: _in,
                lastRewardTimestamp: startTimestamp,
                rewardPerSecond: 0,
                rewardPerShare: 0,
                isDynamicReward: true
            })
        );
        // poolInfo.push(
        //     PoolInfo({
        //         stakeToken: _lp,
        //         rewardToken: _vin,
        //         lastRewardTimestamp: startTimestamp,
        //         rewardPerSecond: uint256(400 ether) / 1 days,
        //         rewardPerShare: 0,
        //         isDynamicReward: false
        //     })
        // );
    }

    function addRewardToPool(uint256 amount) public {
        uint256 totalStake1 = totalStake[1];
        uint256 totalStake2 = totalStake[2];
        IStrictERC20 reward = IStrictERC20(inToken);
        reward.transferFrom(msg.sender, address(this), amount);
        if (totalStake1 > 0 && totalStake2 > 0) {
            poolInfo[1].rewardPerShare += ((amount - (amount / 6)) * 1e20) / totalStake1;
            poolInfo[2].rewardPerShare += ((amount / 6) * 1e20) / totalStake2;
        } else if (totalStake1 > 0) {
            //50% distribute to the vin stakers
            poolInfo[1].rewardPerShare += (amount * 1e20) / totalStake1;
        } else if (totalStake2 > 0) {
            //20% of 50% tresury income distribute to the arv stakers
            poolInfo[2].rewardPerShare += (amount * 1e20) / totalStake2;
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _rewardPerSecond, address _cauldronAddress, uint256 startTimestamp, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        cauldronPoolInfo[_cauldronAddress] = poolInfo.length;
        poolInfo.push(
            PoolInfo({
                stakeToken: _cauldronAddress,
                rewardToken: address(vin),
                lastRewardTimestamp: startTimestamp,
                rewardPerSecond: _rewardPerSecond,
                rewardPerShare: 0,
                isDynamicReward: false
            })
        );
    }

    function updateRewardPerBlock(uint256 _rewardPerSecond, uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(!pool.isDynamicReward && _pid != 0, "can not update reward");
        updatePool(_pid);
        pool.rewardPerSecond = _rewardPerSecond;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending CAKEs on frontend.
    function pendingReward(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 rewardPerShare = pool.rewardPerShare;
        if (pool.isDynamicReward) {
            return (rewardPerShare * user.amount) / 1e20 - user.rewardDebt;
        } else {
            if (_pid == 0) {
                uint256 rPerSencond = pool.rewardPerSecond;
                uint256 epoch = block.timestamp;
                uint256 userLockAmount = getLockAmount(_user);
                if (epoch > pool.lastRewardTimestamp && userLockAmount != 0) {
                    uint256 lrt = pool.lastRewardTimestamp;
                    for (uint i = arvLastRelease; i < epoch; ) {
                        i += 1 days;
                        uint256 timestamp = Math.min(epoch, i);
                        uint256 multiplier = getMultiplier(lrt, timestamp);
                        uint256 reward = multiplier.mul(rPerSencond);
                        if (timestamp < epoch) {
                            rPerSencond = (rPerSencond * 999) / 1000;
                        }
                        rewardPerShare = rewardPerShare.add(reward.mul(1e20).div(totalVinLock));
                        lrt = timestamp;
                    }
                }
                return userLockAmount.mul(rewardPerShare).div(1e20).sub(user.rewardDebt);
            } else {
                Rebase memory lpSupply = ICauldronV4(pool.stakeToken).totalBorrow();
                if (block.timestamp > pool.lastRewardTimestamp && lpSupply.base != 0) {
                    uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
                    uint256 reward = multiplier.mul(pool.rewardPerSecond);
                    rewardPerShare = rewardPerShare.add(reward.mul(1e20).div(lpSupply.base));
                }
                return user.amount.mul(rewardPerShare).div(1e20).sub(user.rewardDebt);
            }
        }
    }

    function getLockInfo(address user) external view returns (LockDetail[] memory locks) {
        uint256 unlockCount = userLock[user].length - userUnlockIndex[user];
        locks = new LockDetail[](unlockCount);
        for (uint256 i = 0; i < unlockCount; i++) {
            locks[i] = (userLock[user][i + userUnlockIndex[user]]);
        }
    }

    function getLockAmount(address user) public view returns (uint256 amount) {
        LockDetail[] memory details = userLock[user];
        uint256 unlockIndex = userUnlockIndex[user];
        for (uint256 i = unlockIndex; i < details.length; i++) {
            amount += details[i].lockAmount - details[i].unlockAmount;
        }
    }

    function getUnlockableAmount(address user) public view returns (uint256 amount) {
        LockDetail[] memory details = userLock[user];
        uint256 unlockIndex = userUnlockIndex[user];
        for (uint256 i = unlockIndex; i < details.length; i++) {
            if (details[i].unlockTimestamp <= block.timestamp) {
                amount += details[i].lockAmount - details[i].unlockAmount;
            } else {
                break;
            }
        }
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
        if (pool.isDynamicReward || block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        if (_pid == 0) {
            uint256 epoch = block.timestamp;
            for (uint i = arvLastRelease; i < epoch; ) {
                i += 1 days;
                uint256 timestamp = Math.min(epoch, i);
                uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, timestamp);
                uint256 reward = multiplier.mul(pool.rewardPerSecond);
                if (timestamp < epoch) {
                    arvLastRelease = i;
                    pool.rewardPerSecond = (pool.rewardPerSecond * 999) / 1000;
                }
                arvCirculatingSupply += reward;
                pool.rewardPerShare = pool.rewardPerShare.add(reward.mul(1e20).div(totalVinLock));
                pool.lastRewardTimestamp = timestamp;
            }
        } else {
            Rebase memory lpSupply = ICauldronV4(pool.stakeToken).totalBorrow();
            if (lpSupply.base == 0) {
                pool.lastRewardTimestamp = block.timestamp;
                return;
            }
            uint256 multiplier = getMultiplier(pool.lastRewardTimestamp, block.timestamp);
            uint256 reward = multiplier.mul(pool.rewardPerSecond);
            pool.rewardPerShare = pool.rewardPerShare.add(reward.mul(1e20).div(lpSupply.base));
            pool.lastRewardTimestamp = block.timestamp;
        }
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        _deposit(address(0), _pid, _amount);
    }

    function deposit(address to) public {
        _deposit(to, 0, 0);
    }

    function depositLock(uint256 _amount) public {
        _deposit(address(0), 1, _amount);
        updatePool(0);
        address to = msg.sender;
        uint256 userLockAmount = getLockAmount(to);
        PoolInfo memory pool = poolInfo[0];
        UserInfo storage user = userInfo[0][to];
        if (userLockAmount > 0) {
            uint256 pending = userLockAmount.mul(pool.rewardPerShare).div(1e20).sub(user.rewardDebt);
            if (pending > 0) {
                arv.transfer(to, pending);
            }
        }
        userLockAmount += _amount;
        userLock[msg.sender].push(LockDetail({lockAmount: _amount, unlockAmount: 0, unlockTimestamp: block.timestamp + 21 days}));

        user.rewardDebt = userLockAmount.mul(pool.rewardPerShare).div(1e20);
        totalVinLock += _amount;
    }

    /// @notice Deposit tokens to MasterChef.
    /// @param to can be address(0) if the pool is dynamic reward. otherwise please use the user address;
    /// @param _pid can be 0 if the pool is non dynamic reward
    /// @param _amount can be 0 if the pool is non dynamic reward
    function _deposit(address to, uint256 _pid, uint256 _amount) private {
        if (_pid == 0) {
            _pid = cauldronPoolInfo[msg.sender];
        }
        require(_pid != 0, "deposit CAKE by staking");
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        if (pool.isDynamicReward || _pid == LP_POOL) {
            to = msg.sender;
        } else {
            require(msg.sender == pool.stakeToken, "only cauldron can deposit non dynamic pool");
        }
        UserInfo storage user = userInfo[_pid][to];
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.rewardPerShare).div(1e20).sub(user.rewardDebt);
            if (pending > 0) {
                if (!pool.isDynamicReward && _pid != LP_POOL) {
                    userPendingReward[to] += pending;
                } else {
                    IStrictERC20(pool.rewardToken).transfer(to, pending);
                }
            }
        }
        if (!pool.isDynamicReward && _pid != LP_POOL) {
            uint256 newAmount = ICauldronV4(pool.stakeToken).userBorrowPart(to);
            emit Deposit(msg.sender, _pid, newAmount - user.amount);
            user.amount = newAmount;
        } else {
            if (_amount > 0) {
                IStrictERC20(pool.stakeToken).transferFrom(address(to), address(this), _amount);
                user.amount = user.amount.add(_amount);
                totalStake[_pid] += _amount;
                emit Deposit(msg.sender, _pid, _amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.rewardPerShare).div(1e20);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        _withdraw(address(0), _pid, _amount, false);
    }

    function withdrawLock(uint256 _amount) public {
        updatePool(0);
        address to = msg.sender;
        uint256 userLockAmount = getLockAmount(to);
        PoolInfo memory pool = poolInfo[0];
        UserInfo storage user = userInfo[0][to];
        if (userLockAmount > 0) {
            uint256 pending = userLockAmount.mul(pool.rewardPerShare).div(1e20).sub(user.rewardDebt);
            if (pending > 0) {
                arv.transfer(to, pending);
            }
        }
        userLockAmount -= _amount;
        user.rewardDebt = userLockAmount.mul(pool.rewardPerShare).div(1e20);
        totalVinLock -= _amount;
        _withdraw(address(0), 1, _amount, true);
    }

    function withdraw(address[] calldata to) public {
        for (uint256 i = 0; i < to.length; i++) {
            withdraw(to[i]);
        }
    }

    function withdraw(address to) public {
        _withdraw(to, 0, 0, false);
    }

    /// @notice Withdraw tokens from MasterChef.
    /// @param to can be address(0) if the pool is dynamic reward. otherwise please use the user address;
    /// @param _pid can be 0 if the pool is non dynamic reward
    /// @param _amount can be 0 if the pool is non dynamic reward
    function _withdraw(address to, uint256 _pid, uint256 _amount, bool unlockVIN) private {
        if (_pid == 0) {
            _pid = cauldronPoolInfo[msg.sender];
        }
        require(_pid != 0, "withdraw CAKE by unstaking");
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        if (pool.isDynamicReward || _pid == LP_POOL) {
            to = msg.sender;
        } else {
            require(msg.sender == pool.stakeToken, "only cauldron can deposit non dynamic pool");
        }
        UserInfo storage user = userInfo[_pid][to];
        require(user.amount >= _amount, "withdraw: not good");
        uint256 pending = user.amount.mul(pool.rewardPerShare).div(1e20).sub(user.rewardDebt);
        if (pending > 0) {
            if (!pool.isDynamicReward && _pid != LP_POOL) {
                userPendingReward[to] += pending;
            } else {
                IStrictERC20(pool.rewardToken).transfer(to, pending);
            }
        }
        if (!pool.isDynamicReward && _pid != LP_POOL) {
            uint256 oldAmount = ICauldronV4(pool.stakeToken).userBorrowPart(to);
            emit Withdraw(to, _pid, user.amount - oldAmount);
            user.amount = oldAmount;
        } else {
            if (_amount > 0) {
                if (pool.stakeToken == address(vin) && unlockVIN) {
                    uint256 epoch = block.timestamp;
                    require(getUnlockableAmount(to) >= _amount, "no enough unlockable");
                    uint256 unlockAmountLeft = _amount;
                    uint256 i = 0;
                    uint256 unlockIndex = userUnlockIndex[to];
                    LockDetail[] storage details = userLock[to];
                    for (i = unlockIndex; i < details.length && unlockAmountLeft > 0; i++) {
                        LockDetail storage detail = userLock[to][i];
                        if (detail.unlockTimestamp <= epoch) {
                            uint256 unlockableAmount = detail.lockAmount - detail.unlockAmount;
                            if (unlockableAmount <= unlockAmountLeft) {
                                unlockAmountLeft -= unlockableAmount;
                                detail.unlockAmount = detail.lockAmount;
                            } else {
                                detail.unlockAmount += unlockAmountLeft;
                                unlockAmountLeft = 0;
                                break;
                            }
                        }
                    }
                    userUnlockIndex[to] = i;
                } else {
                    require(user.amount.sub(getLockAmount(to)) >= _amount, "not enough amount");
                }
                user.amount = user.amount.sub(_amount);
                totalStake[_pid] -= _amount;
                IStrictERC20(pool.stakeToken).transfer(to, _amount);
                emit Withdraw(to, _pid, _amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.rewardPerShare).div(1e20);
    }

    function claimPending(uint256 _pid) public {
        updatePool(_pid);
        PoolInfo memory pool = poolInfo[_pid];
        address to = msg.sender;
        UserInfo storage user = userInfo[_pid][to];
        if (_pid == 0) {
            uint256 userLockAmount = getLockAmount(to);
            if (userLockAmount > 0) {
                uint256 pending = userLockAmount.mul(pool.rewardPerShare).div(1e20).sub(user.rewardDebt);
                user.rewardDebt = userLockAmount.mul(pool.rewardPerShare).div(1e20);
                if (pending > 0) {
                    arv.transfer(to, pending);
                }
            }
        } else {
            uint256 pending = user.amount.mul(pool.rewardPerShare).div(1e20).sub(user.rewardDebt);
            user.rewardDebt = user.amount.mul(pool.rewardPerShare).div(1e20);
            if (pending > 0) {
                if (!pool.isDynamicReward && _pid != LP_POOL) {
                    userPendingReward[to] += pending;
                } else {
                    IStrictERC20(pool.rewardToken).transfer(to, pending);
                }
            }
        }
    }

    function vestingPendingReward(bool claim) public {
        if (claim) {
            for (uint256 i = 4; i < poolInfo.length; i++) {
                claimPending(i);
            }
        }
        userVestingInfo[msg.sender].push(
            VestingInfo({vestingReward: userPendingReward[msg.sender], claimTime: block.timestamp + 21 days, isClaimed: false})
        );
        userPendingReward[msg.sender] = 0;
    }

    function claimVestingReward() public {
        VestingInfo[] storage details = userVestingInfo[msg.sender];
        uint256 reward = 0;
        for (uint256 i = 0; i < details.length; i++) {
            if (!details[i].isClaimed && details[i].claimTime <= block.timestamp) {
                details[i].isClaimed = true;
                reward += details[i].vestingReward;
            } else {
                break;
            }
        }
        vin.transfer(msg.sender, reward);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        require(_pid != 0, "can not emergency withdraw arv release pool");
        PoolInfo storage pool = poolInfo[_pid];
        address operator = msg.sender;
        UserInfo storage user = userInfo[_pid][operator];
        IStrictERC20(pool.stakeToken).transfer(operator, user.amount);
        if (_pid == 1) {
            uint256 userLockAmount = getLockAmount(operator);
            totalVinLock -= userLockAmount;
            delete userLock[operator];
            delete userUnlockIndex[operator];
        }
        if (pool.isDynamicReward) {
            totalStake[_pid] -= user.amount;
        }
        emit EmergencyWithdraw(operator, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function estimateARVCirculatingSupply() public view returns (uint256 circulatingSupply) {
        PoolInfo memory pool = poolInfo[0];
        uint256 rPerSencond = pool.rewardPerSecond;
        uint256 epoch = block.timestamp;
        circulatingSupply = arvCirculatingSupply;
        if (block.timestamp > pool.lastRewardTimestamp) {
            uint256 lrt = pool.lastRewardTimestamp;
            for (uint i = arvLastRelease; i < epoch; ) {
                i += 1 days;
                uint256 timestamp = Math.min(epoch, i);
                uint256 multiplier = getMultiplier(lrt, timestamp);
                uint256 reward = multiplier.mul(rPerSencond);
                if (i < epoch) {
                    rPerSencond = (rPerSencond * 999) / 1000;
                }
                circulatingSupply += reward;
                lrt = timestamp;
            }
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
pragma solidity >=0.8.0;

import "interfaces/ICauldronV3.sol";

interface ICauldronV4 is ICauldronV3 {
    function setBlacklistedCallee(address callee, bool blacklisted) external;

    function blacklistedCallees(address callee) external view returns (bool);

    function repayForAll(uint128 amount, bool skim) external returns (uint128);

    function interestPerPart() external view returns (uint256);

    function userBorrowInterestDebt(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IMasterChef {
    struct LockDetail {
        uint256 lockAmount;
        uint256 unlockAmount;
        uint256 unlockTimestamp;
    }

    // Info of each user.
    struct VestingInfo {
        uint256 vestingReward;
        uint256 claimTime;
        bool isClaimed;
    }

    function addRewardToPool(uint256 amount) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function deposit(address to) external;

    function depositLock(uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function withdraw(address to) external;

    function withdraw(address[] calldata to) external;

    function withdrawLock(uint256 _amount) external;

    function totalStake(uint256 _pid) external returns (uint256 stakeAmount);

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function userPendingReward(address user) external view returns (uint256 pendingReward);

    function userInfo(uint256 _pid, address user) external view returns (uint256 amount, uint256 debt);

    function poolInfo(
        uint256 _pid
    )
        external
        view
        returns (
            address stakeToken,
            address rewardToken,
            uint256 lastRewardTimestamp,
            uint256 rewardPerSecond,
            uint256 rewardPerShare, //multiply 1e20
            bool isDynamicReward
        );

    function getLockAmount(address user) external view returns (uint256 amount);

    function getLockInfo(address user) external view returns (LockDetail[] memory locks);

    function getUnlockableAmount(address user) external view returns (uint256 amount);

    function vestingPendingReward(bool claim) external;

    function claimVestingReward() external;

    function emergencyWithdraw(uint256 _pid) external;

    function estimateARVCirculatingSupply() external view returns (uint256 circulatingSupply);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "interfaces/ICauldronV2.sol";

interface ICauldronV3 is ICauldronV2 {
    function borrowLimit() external view returns (uint128 total, uint128 borrowPartPerAddres);

    function changeInterestRate(uint64 newInterestRate) external;

    function changeBorrowLimit(uint128 newBorrowLimit, uint128 perAddressPart) external;

    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        address swapper,
        bytes calldata swapperData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IOracle.sol";

interface ICauldronV2 {
    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function accrueInfo() external view returns (uint64, uint128, uint64);

    function BORROW_OPENING_FEE() external view returns (uint256);

    function COLLATERIZATION_RATE() external view returns (uint256);

    function LIQUIDATION_MULTIPLIER() external view returns (uint256);

    function totalCollateralShare() external view returns (uint256);

    function bentoBox() external view returns (address);

    function feeTo() external view returns (address);

    function masterContract() external view returns (ICauldronV2);

    function collateral() external view returns (IERC20);

    function setFeeTo(address newFeeTo) external;

    function accrue() external;

    function totalBorrow() external view returns (Rebase memory);

    function userBorrowPart(address account) external view returns (uint256);

    function userCollateralShare(address account) external view returns (uint256);

    function withdrawFees() external;

    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);

    function addCollateral(address to, bool skim, uint256 share) external;

    function removeCollateral(address to, uint256 share) external;

    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

    function repay(address to, bool skim, uint256 part) external returns (uint256 amount);

    function reduceSupply(uint256 amount) external;

    function magicInternetMoney() external view returns (IERC20);

    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        address swapper
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}