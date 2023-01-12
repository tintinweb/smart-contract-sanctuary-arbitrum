// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './interfaces/IGarbiFarm.sol';
import './interfaces/IERC20withMint.sol';

contract GarbiMining is Ownable{

    using SafeMath for uint256;

    IERC20withMint public veGRB;

    uint256 public totalBlockPerDay = 5760;// just use for dislay at UI
    // veGRB each block.
    uint256 public vegrbPerBlock = 1600000000000000;
    // The total point for all pools
    uint256 public totalAllocPoint = 1000;
    // The block when mining start
    uint256 public startBlock;

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => uint256)) public rewardDebtOf;

    uint public constant GRACE_PERIOD = 30 days;
    uint public constant MINIMUM_DELAY = 2 days;
    uint public constant MAXIMUM_DELAY = 30 days;
    uint public delay;

    mapping(bytes32 => TimeLock) public timeLockOf;

    struct TimeLock {
        bool queuedTransactions;
        uint256 timeOfExecute;
        mapping(bytes32 => address) addressOf;
        mapping(bytes32 => uint256) uintOf;
    }
    
    struct PoolInfo {
    	address want; // LP token Addess
        IGarbiFarm grabiFarm;             // Address of Garbi Farm Contract.
        uint256 allocPoint;                
        uint256 lastRewardBlock;            // Last block number when the pool get reward.
        uint256 accVeGRBPerShare;             // Garbi Per Share of the pool.
    }

    event onHarvest(uint256 _pid, address _user, uint256 _amt);

    event onQueuedTransactionsChangeAddress(string _functionName, string _fieldName, address _value);
    event onQueuedTransactionsChangeUint(string _functionName, string _fieldName, uint256 _value);
    event onQueuedTransactionSsetPoolPoint(uint256 _pid, uint256 _allocPoint);
    event onCancelTransactions(string _functionName);

    constructor(
        IERC20withMint _vegrb,
        uint256 _vegrbPerBlock,
        uint256 _startBlock
    ) {
        veGRB = _vegrb;
        vegrbPerBlock = _vegrbPerBlock;
        startBlock = _startBlock;
    }

    function setDelay(uint delay_) public onlyOwner 
    {
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay: Delay must exceed minimum delay.");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay: Delay must not exceed maximum delay.");

        delay = delay_;
    }

    function cancelTransactions(string memory _functionName) public onlyOwner 
    {
        TimeLock storage _timelock = timeLockOf[keccak256(abi.encode(_functionName))];
        _timelock.queuedTransactions = false;

        emit onCancelTransactions(_functionName);
    }

    function queuedTransactionsChangeAddress(string memory _functionName, string memory _fieldName, address _newAddr) public onlyOwner 
    {
        TimeLock storage _timelock = timeLockOf[keccak256(abi.encode(_functionName))];

        _timelock.addressOf[keccak256(abi.encode(_fieldName))] = _newAddr;
        _timelock.queuedTransactions = true;
        _timelock.timeOfExecute = block.timestamp.add(delay);

        emit onQueuedTransactionsChangeAddress(_functionName, _fieldName, _newAddr);
    }

    function queuedTransactionsChangeUint(string memory _functionName, string memory _fieldName, uint256 _value) public onlyOwner 
    {
        TimeLock storage _timelock = timeLockOf[keccak256(abi.encode(_functionName))];

        _timelock.uintOf[keccak256(abi.encode(_fieldName))] = _value;
        _timelock.queuedTransactions = true;
        _timelock.timeOfExecute = block.timestamp.add(delay);

        emit onQueuedTransactionsChangeUint(_functionName, _fieldName, _value);
    }

     function queuedTransactionSsetPoolPoint(uint256 _pid, uint256 _allocPoint) public onlyOwner 
    {
        TimeLock storage _timelock = timeLockOf[keccak256(abi.encode('setPoolPoint', _pid))];

        _timelock.uintOf[keccak256(abi.encode('allocPoint'))] = _allocPoint;
        _timelock.queuedTransactions = true;
        _timelock.timeOfExecute = block.timestamp.add(delay);

        emit onQueuedTransactionSsetPoolPoint(_pid, _allocPoint);
    }

    function setTotalBlockPerDay() public onlyOwner 
    {
        TimeLock storage _timelock = timeLockOf[keccak256(abi.encode('setTotalBlockPerDay'))];
        _validateTimelock(_timelock);
        require(_timelock.uintOf[keccak256(abi.encode('totalBlockPerDay'))] > 0, "INVALID_AMOUNT");

        totalBlockPerDay = _timelock.uintOf[keccak256(abi.encode('totalBlockPerDay'))];
        delete _timelock.uintOf[keccak256(abi.encode('totalBlockPerDay'))];
        _timelock.queuedTransactions = false;
    }

    function setTotalAllocPoint() public onlyOwner
    {
        TimeLock storage _timelock = timeLockOf[keccak256(abi.encode('setTotalAllocPoint'))];
        _validateTimelock(_timelock);
        require(_timelock.uintOf[keccak256(abi.encode('totalAllocPoint'))] > 0, "INVALID_AMOUNT");

        totalAllocPoint = _timelock.uintOf[keccak256(abi.encode('totalAllocPoint'))];
        delete _timelock.uintOf[keccak256(abi.encode('totalAllocPoint'))];
        _timelock.queuedTransactions = false;
    }

    function setGarbiTokenContract() public onlyOwner 
    {
        TimeLock storage _timelock = timeLockOf[keccak256(abi.encode('setGarbiTokenContract'))];

        _validateTimelock(_timelock);
        
        require(_timelock.addressOf[keccak256(abi.encode('veGRB'))] != address(0), "INVALID_ADDRESS");

        veGRB = IERC20withMint(_timelock.addressOf[keccak256(abi.encode('veGRB'))]);

        delete _timelock.addressOf[keccak256(abi.encode('veGRB'))];

        _timelock.queuedTransactions = false;
    }

    // Add a new pool. Can only be called by the owner.
    function addPool(uint256 _allocPoint, IGarbiFarm _vegrbFarm) public onlyOwner { 

        TimeLock storage _timelock = timeLockOf[keccak256(abi.encode('addPool'))]; //use queuedTransactionsChangeAddress
        _validateTimelock(_timelock);
        require(_timelock.addressOf[keccak256(abi.encode('grabiFarm'))] == address(_vegrbFarm), 'INVALID_ADDRESS');

    	address want = address(_vegrbFarm.want());
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        poolInfo.push(PoolInfo({
            want: want,
            grabiFarm: _vegrbFarm,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accVeGRBPerShare: 0
        }));
        delete _timelock.addressOf[keccak256(abi.encode('grabiFarm'))];
        _timelock.queuedTransactions = false;
    }

    //Update the given pool's allocation point. Can only be called by the owner.
    function setPoolPoint(uint256 _pid) public onlyOwner 
    {
        TimeLock storage _timelock = timeLockOf[keccak256(abi.encode('setPoolPoint', _pid))];

        _validateTimelock(_timelock);

    	require(poolInfo[_pid].allocPoint != _timelock.uintOf[keccak256(abi.encode('allocPoint'))], 'INVALID_INPUT');

    	updatePool(_pid);
        
        poolInfo[_pid].allocPoint = _timelock.uintOf[keccak256(abi.encode('allocPoint'))];
        delete _timelock.uintOf[keccak256(abi.encode('allocPoint'))];
        _timelock.queuedTransactions = false;
    }

    function _validateTimelock(TimeLock storage _timelock) private view {
        require(_timelock.queuedTransactions == true, "Transaction hasn't been queued.");
        require(_timelock.timeOfExecute <= block.timestamp, "Transaction hasn't surpassed time lock.");
        require(_timelock.timeOfExecute.add(GRACE_PERIOD) >= block.timestamp, "Transaction is stale.");
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {

        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 _totalShare = pool.grabiFarm.totalShare();
        
        uint256 _multiplier = getBlockFrom(pool.lastRewardBlock, block.number);

        uint256 _reward = _multiplier.mul(vegrbPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        if (_totalShare == 0) {

            pool.lastRewardBlock = block.number;

            return;
        }

        veGRB.mint(address(this), _reward);

        pool.accVeGRBPerShare = pool.accVeGRBPerShare.add(_reward.mul(1e12).div(_totalShare));

        pool.lastRewardBlock = block.number;
    }

    function harvest(uint256 _pid, address _user) external returns(uint256 _pendingVeGRB) 
    {	
    	updatePool(_pid);
    
    	uint256 _rewardDebt;
    	(_pendingVeGRB, _rewardDebt, ) = getUserInfo(_pid, _user);

    	//uint256 _vegrbBal = veGRB.balanceOf(address(this));

    	//rewardDebtOf[_pid][_user] = _rewardDebt;

    	//if (_pendingVeGRB > _vegrbBal) {
            //_pendingVeGRB = _vegrbBal;
    	//}
        //if (_pendingVeGRB > 0) {
            //veGRB.transfer(_user, _pendingVeGRB);
            //emit onHarvest(_pid, _user, _pendingVeGRB);
        //}
    }

    function updateUser(uint256 _pid, address _user) public returns(bool)
    {
        PoolInfo memory pool = poolInfo[_pid];
        require(address(pool.grabiFarm) == msg.sender, 'INVALID_PERMISSION');

        uint256 _userShare  = pool.grabiFarm.shareOf(_user);
        rewardDebtOf[_pid][_user] = _userShare.mul(pool.accVeGRBPerShare).div(1e12);

        return true;
    }


    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getBlockFrom(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function getMiningSpeedOf(uint256 _pid) public view returns(uint256) {
        return poolInfo[_pid].allocPoint.mul(100).div(totalAllocPoint);
    }

    function getTotalMintPerDayOf(uint256 _pid) public view returns(uint256) {
        return totalBlockPerDay.mul(vegrbPerBlock).mul(poolInfo[_pid].allocPoint).div(totalAllocPoint);
    }

    function getVeGRBAddr() public view returns(address) {
        return address(veGRB);
    }

    // View function to get User's Info in a pool.
    function getUserInfo(uint256 _pid, address _user) public view returns (uint256 _pendingVeGRB, uint256 _rewardDebt, uint256 _userShare) { 

        PoolInfo memory pool = poolInfo[_pid];

        uint256 accVeGRBPerShare = pool.accVeGRBPerShare;

        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 _totalShare = pool.grabiFarm.totalShare();
        _userShare  = pool.grabiFarm.shareOf(_user);

        if (block.number > pool.lastRewardBlock && _totalShare != 0) {
            uint256 _multiplier = getBlockFrom(pool.lastRewardBlock, block.number);
            uint256 _reward = _multiplier.mul(vegrbPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accVeGRBPerShare = accVeGRBPerShare.add(_reward.mul(1e12).div(_totalShare));
        }
        _rewardDebt  = _userShare.mul(accVeGRBPerShare).div(1e12);

        if (_rewardDebt > rewardDebtOf[_pid][_user]) {
            _pendingVeGRB = _rewardDebt.sub(rewardDebtOf[_pid][_user]);
        }
    }

    function getAddressChangeOnTimeLock(string memory _functionName, string memory _fieldName) public view returns(address) {
        return timeLockOf[keccak256(abi.encode(_functionName))].addressOf[keccak256(abi.encode(_fieldName))];
    }

    function getUintChangeOnTimeLock(string memory _functionName, string memory _fieldName) public view returns(uint256) {
        return timeLockOf[keccak256(abi.encode(_functionName))].uintOf[keccak256(abi.encode(_fieldName))];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IGarbiFarm {

   uint256 public totalShare;

   IERC20 public want;

   mapping(address => uint256) public shareOf; 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20withMint is IERC20 {
   function mint(address _user, uint256 _amount) external; 
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