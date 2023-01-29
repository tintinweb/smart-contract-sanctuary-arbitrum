/**
 *Submitted for verification at Arbiscan on 2023-01-29
*/

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/ax-one/MasterChef.sol

pragma solidity ^0.8.0;

interface IReward {
    function getReward(address user, uint256 amount) external;
}

contract MasterChef is Ownable {

    struct UserInfo {
        uint256 amount; 
        uint256 rewardDebt; 
        uint256 pending;
    }

    struct PoolInfo {
        address lpToken;
        uint256 balance;
        uint256 allocPoint; 
        uint256 lastRewardTimestamp; 
        uint256 accRewardPerShare; 
    }
    
    address public reward;
    
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint = 0;

    
    uint256 public curRewardRate;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);


    function add(
        address _lpToken,
        uint256 _point
    ) public onlyOwner {
        massUpdatePools();
        totalAllocPoint += _point;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                balance: 0,
                allocPoint: _point,
                lastRewardTimestamp: block.timestamp,
                accRewardPerShare: 0
            })
        );
    }

    function set(
        uint256[] memory _pids,
        uint256[] memory _allocPoints
    ) public onlyOwner {        
        massUpdatePools();
        uint totalPoint = totalAllocPoint;
        for (uint i = 0; i < _pids.length; i++) {
            totalPoint = totalPoint - poolInfo[_pids[i]].allocPoint + _allocPoints[i];
            poolInfo[_pids[i]].allocPoint = _allocPoints[i];
        }
        totalAllocPoint = totalPoint;
    }

    function setReward(address _addr) public onlyOwner {
        reward = _addr;
    }

    function setRewardRate(uint256 _rate) public onlyOwner {
        massUpdatePools();
        curRewardRate = _rate;
    }

    function getRewardRate(uint256 _from, uint256 _to)
        public
        view
        returns (uint256) 
    {
        return curRewardRate * (_to - _from);
    }

    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.balance;
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 rewardReward =
                getRewardRate(pool.lastRewardTimestamp, block.timestamp) * pool.allocPoint / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + rewardReward * 1e12 / lpSupply;
        }
        return user.amount * accRewardPerShare / 1e12 - user.rewardDebt + user.pending;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 lpSupply = pool.balance;
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 rewardReward =
                getRewardRate(pool.lastRewardTimestamp, block.timestamp) * pool.allocPoint / totalAllocPoint;
        
        pool.accRewardPerShare += rewardReward * 1e12 / lpSupply;
        pool.lastRewardTimestamp = block.timestamp;
    }

    function deposit(uint256 _pid, uint256 _amount, address _for) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_for];
        require(pool.lpToken == msg.sender, "deposit");
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount * pool.accRewardPerShare / 1e12 - user.rewardDebt;
            user.pending += pending;
        }
        
        pool.balance += _amount;
        user.amount += _amount;
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;
        
        emit Deposit(_for, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount, address _for) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_for];
        require(pool.lpToken == msg.sender, "withdraw");
        
        uint256 amount = _amount;
        if (amount > user.amount) {
            amount = user.amount;
        }

        updatePool(_pid);
        
        uint256 pending = user.amount * pool.accRewardPerShare / 1e12 - user.rewardDebt;
        user.pending += pending;

        user.amount -= amount;
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;

        pool.balance -= amount;
        emit Withdraw(_for, _pid, amount);
    }

    function claimReward(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        
        uint256 pending = user.amount * pool.accRewardPerShare / 1e12 - user.rewardDebt;
        pending += user.pending;
        if (pending > 0) {
            IReward(reward).getReward(msg.sender, pending);
        }
        user.pending = 0;
        user.rewardDebt = user.amount * pool.accRewardPerShare / 1e12;
    }
    

}