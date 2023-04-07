// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVe {

  enum DepositType {
    DEPOSIT_FOR_TYPE,
    CREATE_LOCK_TYPE,
    INCREASE_LOCK_AMOUNT,
    INCREASE_UNLOCK_TIME,
    MERGE_TYPE
  }

  struct Point {
    int128 bias;
    int128 slope; // # -dweight / dt
    uint ts;
    uint blk; // block
  }
  /* We cannot really do block numbers per se b/c slope is per time, not per block
  * and per block could be fairly bad b/c Ethereum changes blocktimes.
  * What we can do is to extrapolate ***At functions */

  struct LockedBalance {
    int128 amount;
    uint end;
  }

  function token() external view returns (address);

  function balanceOfNFT(uint) external view returns (uint);

  function isApprovedOrOwner(address, uint) external view returns (bool);

  function createLockFor(uint, uint, address) external returns (uint);
  
  function createLockForPartner(uint, uint, address) external returns (uint);

  function userPointEpoch(uint tokenId) external view returns (uint);

  function epoch() external view returns (uint);

  function userPointHistory(uint tokenId, uint loc) external view returns (Point memory);

  function pointHistory(uint loc) external view returns (Point memory);

  function checkpoint() external;

  function depositFor(uint tokenId, uint value) external;

  function attachToken(uint tokenId) external;

  function detachToken(uint tokenId) external;

  function voting(uint tokenId) external;

  function abstain(uint tokenId) external;
}


// File: contracts/interfaces/IBurger.sol


pragma solidity 0.8.9;

interface IBurger {
    function totalSupply() external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
}

// File: contracts/interfaces/IERC20.sol


pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity 0.8.9;

// The biggest change made is using per second instead of per block for rewards
// This is due to Fantoms extremely inconsistent block times
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once c is sufficiently
// distributed and the community can show to govern itself.

contract VeMasterchef {
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 pendingReward;
        //
        // We do some fancy math here. Basically, any point in time, the amount of BURGER
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accBURGERPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accBURGERPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. BURGERs to distribute per block.
        uint256 lastRewardTime;  // Last block time that BURGERs distribution occurs.
        uint256 accBURGERPerShare; // Accumulated BURGERs per share, times 1e12. See below.
    }

    IBurger public burger;
    IVe public ve;

    // BURGER tokens created per second.
    uint256 public burgerPerSecond;
 
    uint256 public constant MAX_ALLOC_POINT = 4000;
    uint256 public constant LOCK = 86400 * 7 * 26;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block time when BURGER mining starts.
    uint256 public startTime;
    // The block time when BURGER mining stops.
    uint256 public endTime;

    bool public paused;

    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 totalReward, uint256 tokenId);
    event Paused(address indexed operator);
    event Unpaused(address indexed operator);
    
    constructor(
        address _ve,
        uint256 _burgerPerSecond, // 0,2755731922398589 = 275573192239858906
        uint256 _startTime, // 1681491600 - 14-04-2023 (17gmt)
        uint256 _endTime // 1683306000 - 05-05-2023 (17gmt)
    ) {
        owner = msg.sender;
        burger = IBurger(IVe(_ve).token());
        ve = IVe(_ve);
        burgerPerSecond = _burgerPerSecond;
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused, "Paused");
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function checkForDuplicate(IERC20 _lpToken) internal view {
        uint256 length = poolInfo.length;
        for (uint256 _pid = 0; _pid < length; _pid++) {
            require(poolInfo[_pid].lpToken != _lpToken, "add: pool already exists!!!!");
        }
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IERC20 _lpToken) external onlyOwner {
        require(_allocPoint <= MAX_ALLOC_POINT, "add: too many alloc points!!");

        checkForDuplicate(_lpToken); // ensure you cant add duplicate pools

        massUpdatePools();

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardTime: lastRewardTime,
            accBURGERPerShare: 0
        }));
    }

    // Update the given pool's BURGER allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) external onlyOwner {
        require(_allocPoint <= MAX_ALLOC_POINT, "add: too many alloc points!!");

        massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        _from = _from > startTime ? _from : startTime;
        if (_to < startTime || _from >= endTime) {
            return 0;
        } else if (_to <= endTime) {
            return _to - _from;
        } else {
            return endTime - _from;
        }
    }

    // View function to see pending BURGERs on frontend.
    function pendingBURGER(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBURGERPerShare = pool.accBURGERPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 burgerReward = multiplier * burgerPerSecond * pool.allocPoint / totalAllocPoint;
            accBURGERPerShare = accBURGERPerShare + (burgerReward * 1e12 / lpSupply);
        }
        // modified;  return user.amount * accBURGERPerShare / 1e12 - user.rewardDebt
        return user.amount * accBURGERPerShare / 1e12 - user.rewardDebt + user.pendingReward;
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 burgerReward = multiplier * burgerPerSecond * pool.allocPoint / totalAllocPoint;

        pool.accBURGERPerShare = pool.accBURGERPerShare + (burgerReward * 1e12 / lpSupply);
        pool.lastRewardTime = block.timestamp;
    }

    // Deposit LP tokens to MasterChef for BURGER allocation.
    function deposit(uint256 _pid, uint256 _amount) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        uint256 pending = user.amount * pool.accBURGERPerShare / 1e12 - user.rewardDebt;
    
        user.amount = user.amount + _amount;
        user.rewardDebt = user.amount * pool.accBURGERPerShare / 1e12;
        user.pendingReward = user.pendingReward + pending; // added

        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        uint256 pending = user.amount * pool.accBURGERPerShare / 1e12 - user.rewardDebt;

        user.amount = user.amount - _amount;
        user.rewardDebt = user.amount * pool.accBURGERPerShare / 1e12;
        user.pendingReward = user.pendingReward + pending; // added
        // modified
        /* if(pending > 0) {
            safeBURGERTransfer(msg.sender, pending);
        } */
        pool.lpToken.transfer(address(msg.sender), _amount);
        
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function harvestAll() public whenNotPaused {
        uint256 length = poolInfo.length;
        uint calc;
        uint pending;
        UserInfo storage user;
        PoolInfo storage pool;
        uint totalPending;
        for (uint256 pid = 0; pid < length; ++pid) {
            user = userInfo[pid][msg.sender];
            if (user.amount > 0) {
                pool = poolInfo[pid];
                updatePool(pid);

                calc = user.amount * pool.accBURGERPerShare / 1e12;
                pending = calc - user.rewardDebt + user.pendingReward; // modified; pending = calc - user.rewardDebt;
                user.rewardDebt = calc;

                if(pending > 0) {
                    totalPending += pending;
                    user.pendingReward = 0;
                }
            }
        }
        uint256 tokenId;
        if (totalPending > 0) {
            // modified
            // safeBURGERTransfer(msg.sender, totalPending); 
            burger.approve(address(ve), totalPending);
            tokenId = ve.createLockFor(totalPending, LOCK, msg.sender); // added
        }
        emit Harvest(msg.sender, totalPending, tokenId);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint oldUserAmount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        pool.lpToken.transfer(address(msg.sender), oldUserAmount);
        emit EmergencyWithdraw(msg.sender, _pid, oldUserAmount);
    }

    // Safe BURGER transfer function, just in case if rounding error causes pool to not have enough BURGERs.
    function safeBURGERTransfer(address _to, uint256 _amount) internal {
        uint256 burgerBal = burger.balanceOf(address(this));
        if (_amount > burgerBal) {
            burger.transfer(_to, burgerBal);
        } else {
            burger.transfer(_to, _amount);
        }
    }

    /// @notice set start & end time for airdrop
    /// @param _startTime start time (in seconds)
    /// @param _duration staking duration (in days) 
    function setTime(uint256 _startTime, uint256 _duration) external onlyOwner {
        require(_startTime > block.timestamp, "Invalid start time");
        startTime = _startTime;
        endTime = _startTime + _duration * 1 days;
    }

    /// @notice set burgerPerSecond value
    function setBurgerPerSecond(uint256 _burgerPerSecond) external onlyOwner {
        burgerPerSecond = _burgerPerSecond;
    }

    function pause() external whenNotPaused onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        require(paused, "not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @notice withdraw remaining tokens
    function withdrawBURGER(address _recipient) external onlyOwner {
        uint256 remaining = burger.balanceOf(address(this));
        require(remaining > 0, "No remaining tokens");
        burger.transfer(_recipient, remaining);
    }
}