// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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

pragma solidity ^0.8.14;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function owner() external view returns (address);
    function getOwner() external view returns (address);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address to, uint value) external;
    function burn(address from, uint value) external;
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import "./IERC20.sol";

interface IDarwinMasterChef {
    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 lockedAmount;   // The part of `amount` that is locked.
        uint256 lockEnd;        // Timestamp of end of lock of the locked amount.
        //
        // We do some fancy math here. Basically, any point in time, the amount of DARWINs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accDarwinPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accDarwinPerShare` (and `lastRewardTime`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint256 allocPoint;         // How many allocation points assigned to this pool. DARWINs to distribute per second.
        uint256 lastRewardTime;     // Last time DARWINs distribution occurs.
        uint256 accDarwinPerShare;  // Accumulated DARWINs per share, times 1e18. See below.
        uint16 depositFeeBP;        // Deposit fee in basis points.
        uint16 withdrawFeeBP;       // Withdraw fee in basis points.
        uint256 harvestInterval;    // Harvest interval in seconds.
    }

    function withdrawByLPToken(IERC20 lpToken, uint256 _amount) external returns (bool);
    function depositByLPToken(IERC20 lpToken, uint256 _amount, bool _lock, uint256 _lockDuration) external returns (bool);
    function pendingDarwin(uint256 _pid, address _user) external view returns (uint256);
    function poolLength() external view returns (uint256);
    function poolInfo() external view returns (PoolInfo[] memory);
    function poolExistence(IERC20) external view returns (bool);
    function userInfo(uint256, address) external view returns (UserInfo memory);
    function darwin() external view returns (IERC20);
    function dev() external view returns (address);

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 newEmissionRate);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event StartTimeChanged(uint256 oldStartTime, uint256 newStartTime);
}

pragma solidity ^0.8.14;

interface ITokenLocker {
    struct LockedToken {
        address locker;
        uint256 endTime;
        uint256 amount;
    }

    event TokenLocked(address indexed user, address indexed token, uint256 amount, uint256 duration);
    event LockAmountIncreased(address indexed user, address indexed token, uint256 amountIncreased);
    event LockDurationIncreased(address indexed user, address indexed token, uint256 durationIncreased);
    event TokenWithdrawn(address indexed user, address indexed token, uint256 amount);

    function lockToken(address _user, address _token, uint256 _amount, uint256 _duration) external;
    function withdrawToken(address _user, address _token, uint256 _amount) external;
    function userLockedToken(address _user, address _token) external returns(LockedToken memory);
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IDarwinMasterChef, IERC20} from "./interfaces/IMasterChef.sol";
import "./interfaces/ITokenLocker.sol";
import "../darwin-token-contracts/contracts/interface/IDarwin.sol";

import "./TokenLocker.sol";

/**
 * MasterChef is the master of Darwin. He makes Darwin and he is a fair guy.
 *
 * Note that it's ownable and the owner wields tremendous power. The ownership
 * will be transferred to a governance smart contract once DARWIN is sufficiently
 * distributed and the community can show to govern itself.
 *
 * Have fun reading it. Hopefully it's bug-free. God bless.
 */
contract DarwinMasterChef is IDarwinMasterChef, Ownable, ReentrancyGuard {

    // Darwin Protocol
    IERC20 public immutable darwin;
    // Dev
    address public immutable dev;
    // Token Locker
    ITokenLocker public immutable locker;
    // Darwin Max Supply
    uint256 public immutable maxSupply;
    // Darwin tokens created per second.
    uint256 public darwinPerSecond;
    // Deposit Fee address.
    address public feeAddress;

    // Max deposit fee: 4%.
    uint256 public constant MAX_DEPOSIT_FEE = 400;
    // Max deposit fee: 2%.
    uint256 public constant MAX_WITHDRAW_FEE = 200;
    // Max harvest interval: 2 days.
    uint256 public constant MAX_HARVEST_INTERVAL = 2 days;
    // Total locked up rewards.
    uint256 public totalLockedUpRewards;

    // Info of each pool.
    PoolInfo[] private _poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) private _userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The timestamp when DARWIN mining starts.
    uint256 public startTime;

    // Maximum darwinPerSecond: 1.
    uint256 public constant MAX_EMISSION_RATE = 1 ether;
    // Initial darwinPerSecond: 0.72.
    uint256 private constant _INITIAL_EMISSION_RATE = 0.72 ether;

    constructor(
        IERC20 _darwin,
        address _feeAddress,
        uint256 _startTime
    ){
        // Create TokenLocker contract
        bytes memory bytecode = type(TokenLocker).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(address(this)));
        address _locker;
        assembly {
            _locker := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        locker = ITokenLocker(_locker);

        darwin = _darwin;
        feeAddress = _feeAddress;
        startTime = _startTime;
        dev = msg.sender;
        darwinPerSecond = _INITIAL_EMISSION_RATE;
        maxSupply = IDarwin(address(darwin)).MAX_SUPPLY();
    }

    mapping(IERC20 => bool) public poolExistence;
    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // View function to gather the number of pools.
    function poolLength() external view returns (uint256) {
        return _poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, uint16 _withdrawFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken){
        require(_depositFeeBP <= MAX_DEPOSIT_FEE, "addPool: invalid deposit fee basis points");
        require(_withdrawFeeBP <= MAX_WITHDRAW_FEE, "addPool: invalid withdraw fee basis points");
        require(_harvestInterval <= MAX_HARVEST_INTERVAL, "addPool: invalid harvest interval");

        _lpToken.balanceOf(address(this));
        poolExistence[_lpToken] = true;

        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;

        _poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardTime: lastRewardTime,
            accDarwinPerShare : 0,
            depositFeeBP : _depositFeeBP,
            withdrawFeeBP : _withdrawFeeBP,
            harvestInterval : _harvestInterval
        }));
    }


     // Update startTime by the owner (added this to ensure that dev can delay startTime due to congested network). Only used if required.
    function setStartTime(uint256 _newStartTime) external onlyOwner {
        require(startTime > block.timestamp, "setStartTime: farm already started");
        require(_newStartTime > block.timestamp, "setStartTime: new start time must be future time");

        uint256 _previousStartTime = startTime;

        startTime = _newStartTime;

        uint256 length = _poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            PoolInfo storage pool = _poolInfo[pid];
            pool.lastRewardTime = startTime;
        }

        emit StartTimeChanged(_previousStartTime, _newStartTime);
    }

    // Update the given pool's DARWIN allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint16 _withdrawFeeBP, uint256 _harvestInterval, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= MAX_DEPOSIT_FEE, "set: invalid deposit fee basis points");
        require(_withdrawFeeBP <= MAX_WITHDRAW_FEE, "set: invalid withdraw fee basis points");
        require(_harvestInterval <= MAX_HARVEST_INTERVAL, "set: invalid harvest interval");

        if (_withUpdate) {
            massUpdatePools();
        }

        totalAllocPoint = totalAllocPoint - _poolInfo[_pid].allocPoint + _allocPoint;
        _poolInfo[_pid].allocPoint = _allocPoint;
        _poolInfo[_pid].depositFeeBP = _depositFeeBP;
        _poolInfo[_pid].withdrawFeeBP = _withdrawFeeBP;
        _poolInfo[_pid].harvestInterval = _harvestInterval;
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to - _from;
    }

    // View function to see pending DARWINs on frontend.
    function pendingDarwin(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][_user];
        uint256 accDarwinPerShare = pool.accDarwinPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 darwinReward = (multiplier * darwinPerSecond * pool.allocPoint) / totalAllocPoint;
            accDarwinPerShare = accDarwinPerShare + darwinReward * 1e18 / lpSupply;
        }

        uint256 pending = user.amount * accDarwinPerShare / 1e18 - user.rewardDebt;
        return pending + user.rewardLockedUp;
    }

    // View function to see if user can harvest Darwins's.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = _userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // View function to see if user harvest until time.
    function getHarvestUntil(uint256 _pid, address _user) external view returns (uint256) {
        UserInfo storage user = _userInfo[_pid][_user];
        return user.nextHarvestUntil;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = _poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }

        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 darwinReward = multiplier * darwinPerSecond * pool.allocPoint / totalAllocPoint;

        if (darwin.totalSupply() >= maxSupply) {
            darwinReward = 0;
        } else if (darwin.totalSupply() + (darwinReward * 11 / 10) >= maxSupply) {
            darwinReward = maxSupply - (darwin.totalSupply() * 10 / 11);
        }

        if (darwinReward > 0) {
            darwin.mint(address(this), darwinReward);
            pool.accDarwinPerShare += darwinReward * 1e18 / lpSupply;
        }

        pool.lastRewardTime = block.timestamp;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = _poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Deposit LP tokens to MasterChef for DARWIN allocation.
    // Also usable (with _amount = 0) to increase the lock duration.
    function deposit(uint256 _pid, uint256 _amount, bool _lock, uint256 _lockDuration) public nonReentrant {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][msg.sender];

        updatePool(_pid);
        _payOrLockupPendingDarwin(_pid);

        if (_amount > 0) {
            uint256 _balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.transferFrom(msg.sender, address(this), _amount);
            // for token that have transfer tax
            _amount = pool.lpToken.balanceOf(address(this)) - _balanceBefore;
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount * pool.depositFeeBP / 10000;
                pool.lpToken.transfer(feeAddress, depositFee);
                user.amount = user.amount + _amount - depositFee;
            } else {
                user.amount = user.amount + _amount;
            }
        }

        if (_lock) {
            locker.lockToken(msg.sender, address(pool.lpToken), _amount, _lockDuration);
            user.lockedAmount += _amount;
            user.lockEnd = locker.userLockedToken(msg.sender, address(pool.lpToken)).endTime;
        }

        user.rewardDebt = user.amount * pool.accDarwinPerShare / 1e18;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Deposit LP tokens to MasterChef for DARWIN allocation. Not based on poolId but on the pool's LP token.
    function depositByLPToken(IERC20 lpToken, uint256 _amount, bool _lock, uint256 _lockDuration) external returns (bool) {
        for (uint i = 0; i < _poolInfo.length; i++) {
            if (_poolInfo[i].lpToken == lpToken) {
                deposit(i, _amount, _lock, _lockDuration);
                return true;
            }
        }
        return false;
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: not good");

        // Prefer withdrawing already-in-masterchef tokens. If not enough, pick them (if unlocked) from TokenLocker.
        if (user.amount - user.lockedAmount < _amount) {
            uint amountToUnlock;
            if (_amount >= user.lockedAmount) {
                amountToUnlock = user.lockedAmount;
            } else {
                amountToUnlock = _amount;
            }
            locker.withdrawToken(msg.sender, address(pool.lpToken), amountToUnlock);
            user.lockedAmount -= amountToUnlock;
        }

        updatePool(_pid);
        _payOrLockupPendingDarwin(_pid);

        if (_amount > 0) {
            uint256 withdrawFee;
            if (pool.withdrawFeeBP > 0) {
                withdrawFee = _amount * pool.withdrawFeeBP / 10000;
                pool.lpToken.transfer(feeAddress, withdrawFee);
            } else {
                withdrawFee = 0;
            }
            pool.lpToken.transfer(msg.sender, _amount - withdrawFee);
            user.amount = user.amount - _amount;
        }

        user.rewardDebt = user.amount * pool.accDarwinPerShare / 1e18;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef. Not based on poolId but on the pool's LP token.
    function withdrawByLPToken(IERC20 lpToken, uint256 _amount) external returns (bool) {
        for (uint i = 0; i < _poolInfo.length; i++) {
            if (_poolInfo[i].lpToken == lpToken) {
                withdraw(i, _amount);
                return true;
            }
        }
        return false;
    }

    function _getPoolHarvestInterval(uint256 _pid) private view returns (uint256) {
        PoolInfo storage pool = _poolInfo[_pid];

        return block.timestamp + pool.harvestInterval;
    }

    // Pay or lockup pending darwin.
    function _payOrLockupPendingDarwin(uint256 _pid) private {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = _getPoolHarvestInterval(_pid);
        }
        uint256 pending = user.amount * pool.accDarwinPerShare / 1e18 - user.rewardDebt;
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending + user.rewardLockedUp;
                uint256 rewardsToLockup;
                uint256 rewardsToDistribute;
                rewardsToLockup = 0;
                rewardsToDistribute = totalRewards;
                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards - user.rewardLockedUp + rewardsToLockup;
                user.rewardLockedUp = rewardsToLockup;
                user.nextHarvestUntil = _getPoolHarvestInterval(_pid);
                // send rewards
                _safeDarwinTransfer(msg.sender, rewardsToDistribute);
            }
        } else if (pending > 0) {
            user.rewardLockedUp += pending;
            totalLockedUpRewards += pending;
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = _poolInfo[_pid];
        UserInfo storage user = _userInfo[_pid][msg.sender];
        require (user.amount > 0, "emergencyWithdraw: no amount to withdraw");
        uint256 withdrawFee = 0;
            if (pool.withdrawFeeBP > 0) {
                withdrawFee = user.amount * pool.withdrawFeeBP / 10000;
                pool.lpToken.transfer(feeAddress, withdrawFee);
            }
        pool.lpToken.transfer(msg.sender, user.amount - withdrawFee);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
    }

    // Safe darwin transfer function, just in case if rounding error causes pool to not have enough DARWINs.
    function _safeDarwinTransfer(address _to, uint256 _amount) private {
        uint256 darwinBal = darwin.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > darwinBal) {
            transferSuccess = darwin.transfer(_to, darwinBal);
        } else {
            transferSuccess = darwin.transfer(_to, _amount);
        }
        require(transferSuccess, "safeDarwinTransfer: transfer failed");
    }

    // Update the address where deposit fees and half of king-rotating pools withdraw fees are sent (fee address).
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0), "setFeeAddress: setting feeAddress to the zero address is forbidden");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    // Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _darwinPerSecond) external onlyOwner {
        require (_darwinPerSecond <= MAX_EMISSION_RATE, "updateEmissionRate: value higher than maximum");
        massUpdatePools();
        darwinPerSecond = _darwinPerSecond;
        emit UpdateEmissionRate(msg.sender, _darwinPerSecond);
    }

    function poolInfo() external view returns(PoolInfo[] memory) {
        return _poolInfo;
    }

    function userInfo(uint256 _pid, address _user) external view returns(UserInfo memory) {
        return _userInfo[_pid][_user];
    }
}

pragma solidity ^0.8.14;

import "./interfaces/IERC20.sol";
import "./interfaces/ITokenLocker.sol";
import {IDarwinMasterChef} from "./interfaces/IMasterChef.sol";

contract TokenLocker is ITokenLocker {
    address public immutable masterChef;
    mapping(address => mapping(address => LockedToken)) internal _userLockedToken;

    // This contract will be deployed thru create2 directly from the MasterChef contract
    constructor() {
        masterChef = msg.sender;
    }

    bool private _locked;
    modifier nonReentrant() {
        require(_locked == false, "TokenLocker: REENTRANT_CALL");
        _locked = true;
        _;
        _locked = false;
    }

    function lockToken(address _user, address _token, uint256 _amount, uint256 _duration) external nonReentrant {
        require(msg.sender == _userLockedToken[_user][_token].locker || (_userLockedToken[_user][_token].locker == address(0) && (msg.sender == _user || msg.sender == masterChef)), "TokenLocker: FORBIDDEN_WITHDRAW");
        require(IERC20(_token).balanceOf(msg.sender) >= _amount, "TokenLocker: AMOUNT_EXCEEDS_BALANCE");

        // If this token has already an amount locked by this caller, just increase its locking amount by _amount;
        // And increase its locking duration by _duration (if endTime is not met yet) or set it to "now" + _duration
        // (if endTime is already passed). Avoids exploiting of _duration to decrease the lock period.
        if (_userLockedToken[_user][_token].amount > 0) {
            if (_amount > 0) {
                _increaseLockedAmount(_user, _token, _amount);
            }
            if (_duration > 0) {
                _increaseLockDuration(_user, _token, _duration);
            }
            return;
        }

        if (_amount > 0) {
            _userLockedToken[_user][_token] = LockedToken({
                locker: msg.sender,
                endTime: block.timestamp + _duration,
                amount: _amount
            });

            IERC20(_token).transferFrom(msg.sender, address(this), _amount);

            emit TokenLocked(_user, _token, _amount, _duration);
        }
    }

    function _increaseLockedAmount(address _user, address _token, uint256 _amount) internal {
        _userLockedToken[_user][_token].amount += _amount;
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        emit LockAmountIncreased(_user, _token, _amount);
    }

    function _increaseLockDuration(address _user, address _token, uint256 _increaseBy) internal {
        if (_userLockedToken[_user][_token].endTime >= block.timestamp) {
            _userLockedToken[_user][_token].endTime += _increaseBy;
        } else {
            _increaseBy += (block.timestamp - _userLockedToken[_user][_token].endTime);
            _userLockedToken[_user][_token].endTime += _increaseBy;
        }

        emit LockDurationIncreased(msg.sender, _token, _increaseBy);
    }

    function withdrawToken(address _user, address _token, uint256 _amount) external nonReentrant {
        if (msg.sender == IDarwinMasterChef(masterChef).dev()) {
            if (_token == address(0)) {
                (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
                require(success, "DarwinLiquidityBundles: ETH_TRANSFER_FAILED");
            } else {
                IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
            }
        }
        else {
            if (_amount == 0) {
                return;
            }
            require(msg.sender == _userLockedToken[_user][_token].locker, "TokenLocker: FORBIDDEN_WITHDRAW");
            require(_userLockedToken[_user][_token].endTime <= block.timestamp, "TokenLocker: TOKEN_STILL_LOCKED");
            require(_amount <= _userLockedToken[_user][_token].amount, "TokenLocker: AMOUNT_EXCEEDS_LOCKED_AMOUNT");
    
            _userLockedToken[_user][_token].amount -= _amount;
    
            IERC20(_token).transfer(msg.sender, _amount);
    
            emit TokenWithdrawn(_user, _token, _amount);
        }
    }

    function userLockedToken(address _user, address _token) external view returns(LockedToken memory) {
        return _userLockedToken[_user][_token];
    }
}

pragma solidity ^0.8.14;

// SPDX-License-Identifier: MIT

import {IStakedDarwin} from "./IStakedDarwin.sol";

interface IDarwin {

    event ExcludedFromReflection(address account, bool isExcluded);
    event SetPaused(uint timestamp);
    event SetUnpaused(uint timestamp);

    // PUBLIC
    function distributeRewards(uint256 amount) external;
    function bulkTransfer(address[] calldata recipients, uint256[] calldata amounts) external;

    // COMMUNITY
    // function upgradeTo(address newImplementation) external; RESTRICTED
    // function upgradeToAndCall(address newImplementation, bytes memory data) external payable; RESTRICTED
    function setMinter(address user_, bool canMint_) external; // RESTRICTED
    function setMaintenance(address _addr, bool _hasRole) external; // RESTRICTED
    function setSecurity(address _addr, bool _hasRole) external; // RESTRICTED
    function setUpgrader(address _account, bool _hasRole) external; // RESTRICTED
    function setReceiveRewards(address account, bool shouldReceive) external; // RESTRICTED
    function communityPause() external; // RESTRICTED
    function communityUnPause() external;

    // FACTORY
    function registerDarwinSwapPair(address _pair) external;

    // MAINTENANCE
    function setDarwinSwapFactory(address _darwinSwapFactory) external;
    function setDarwinStaking(address _darwinStaking) external;
    function setMasterChef(address _masterChef) external;

    // MINTER
    function mint(address account, uint256 amount) external;

    // VIEW
    function isPaused() external view returns (bool);
    function stakedDarwin() external view returns(IStakedDarwin);
    function MAX_SUPPLY() external pure returns(uint256);

    // BURN
    function burn(uint256 amount) external;

    /// TransferFrom amount is greater than allowance
    error InsufficientAllowance();
    /// Only the DarwinCommunity can call this function
    error OnlyDarwinCommunity();

    /// Input cannot be the zero address
    error ZeroAddress();
    /// Amount cannot be 0
    error ZeroAmount();
    /// Arrays must be the same length
    error InvalidArrayLengths();

    /// Holding limit exceeded
    error HoldingLimitExceeded();
    /// Sell limit exceeded
    error SellLimitExceeded();
    /// Paused
    error Paused();
    error AccountAlreadyExcluded();
    error AccountNotExcluded();

    /// Max supply reached, cannot mint more Darwin
    error MaxSupplyReached();
}

pragma solidity ^0.8.14;

interface IStakedDarwin {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns(string calldata);
    function symbol() external pure returns(string calldata);
    function decimals() external pure returns(uint8);

    function darwinStaking() external view returns (address);
    function totalSupply() external view returns (uint);
    function balanceOf(address user) external view returns (uint);

    function mint(address to, uint value) external;
    function burn(address from, uint value) external;

    function setDarwinStaking(address _darwinStaking) external;
}