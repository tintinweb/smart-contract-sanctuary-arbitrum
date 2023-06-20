/**
 *Submitted for verification at Arbiscan on 2023-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

//---------------------------------------------
//   Imports
//---------------------------------------------

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

//---------------------------------------------
//   Errors
//---------------------------------------------
error GeneralStaking__InsufficientDepositAmount();
error GeneralStaking__InvalidPoolId(uint256 _poolId);
error GeneralStaking__InvalidTransferFrom();
error GeneralStaking__InvalidTransfer();
error GeneralStaking__InvalidPoolApr(uint256 _poolApr);
error GeneralStaking__InvalidWithdrawLockPeriod(uint256 _withdrawLockPeriod);
error GeneralStaking__InvalidAmount();
error GeneralStaking__InvalidEarlyWithdrawFee();
error GeneralStaking__InvalidSettings();

//---------------------------------------------
//   Main Contract
//---------------------------------------------
/**
 * @title GeneralStaking contract has masterchef like functions
 * @author CFG-Ninja - SemiInvader
 * @notice This contract allows the creation of pools that deliver a specific APR for any user staking in it.
 *          It is the job of the owner to keep enough funds on the contract to pay the rewards.
 */

contract GeneralStaking is Ownable, ReentrancyGuard {
    //---------------------------------------------
    //   Type Definitions
    //---------------------------------------------
    struct UserInfo {
        uint256 depositAmount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 lastInteraction; // Last time the user interacted with the contract.
        uint256 lastDeposit; // Last time the user deposited.
        // We also removed debt, since we're working only with APRs, there's no need to keep track of debt.
    }

    struct PoolInfo {
        uint256 poolApr; // APR for the pool.
        uint256 totalDeposit; // Total amount of tokens deposited in the pool.
        uint256 withdrawLockPeriod; // Time in seconds that the user has to wait to withdraw.
        uint256 accAprOverTime; // Accumulated apr in a specific amount of time, times 1e12 for
        uint256 lastUpdate; // Last time the pool was updated.
    }
    //---------------------------------------------
    //   State Variables
    //---------------------------------------------
    // Info of each pool (APR, total deposit, withdraw lock period
    mapping(uint256 _poolId => PoolInfo pool) public poolInfo;
    // Track userInfo per pool
    mapping(uint256 _poolId => mapping(address _userAddress => UserInfo info))
        public userInfo;
    // Track all current pools

    address public marketingAddress; // Address to send marketing funds to.
    IERC20 public token; // Main token reward to be distributed
    uint256 public totalPools; // Total amount of pools
    uint256 public rewardTokens; // Amount of tokens to be distributed
    uint256 public constant FEE_BASE = 100;
    uint256 public constant BASE_APR = 100_00; // 100% APR
    uint256 public constant APR_TIME = 365 days;
    uint256 public constant REWARD_DENOMINATOR = 100_00 * 365 days;
    uint256 public totalLockedUpRewards;
    uint256 public earlyWithdrawFee = 10;

    //---------------------------------------------
    //   Events
    //---------------------------------------------
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event AprUpdated(address indexed caller, uint256 poolId, uint256 newApr);
    event RewardLockedUp(
        address indexed user,
        uint256 indexed pid,
        uint256 amountLockedUp
    );
    event TreasureRecovered();
    event MarketingWalletUpdate();
    event RewardUpdate();
    event EarlyWithdrawalUpdate(uint _old, uint _new);
    event TreasureAdded();
    event RewardsPaid();
    event PoolUpdated();
    event EditPool(
        uint indexed poolId,
        uint256 newApr,
        uint256 newWithdrawLockPeriod
    );
    event PoolAdd(uint _poolIdAdded);

    //---------------------------------------------
    //   Constructor
    //---------------------------------------------
    constructor(address _rewardToken, address _marketing) {
        token = IERC20(_rewardToken);
        marketingAddress = _marketing;
    }

    //---------------------------------------------
    //   External Functions
    //---------------------------------------------

    /**
     * @notice Deposit tokens into a pool
     * @param _pid Pool ID to deposit in
     * @param amount Amount of TOKEN to deposit
     */
    function deposit(uint _pid, uint amount) external nonReentrant {
        if (amount == 0) revert GeneralStaking__InsufficientDepositAmount();

        PoolInfo storage pool = poolInfo[_pid];

        if (_pid > totalPools || pool.poolApr == 0)
            revert GeneralStaking__InvalidPoolId(_pid);

        UserInfo storage user = userInfo[_pid][msg.sender];

        _updateAndPayOrLock(msg.sender, _pid);

        user.depositAmount += amount;

        user.rewardDebt = pool.accAprOverTime * user.depositAmount;
        user.lastInteraction = block.timestamp;
        user.lastDeposit = block.timestamp;
        pool.totalDeposit += amount;

        if (!token.transferFrom(msg.sender, address(this), amount))
            revert GeneralStaking__InvalidTransferFrom();

        emit Deposit(msg.sender, _pid, amount);
    }

    /**
     * @notice Withdraw all deposited tokens from pool
     * @param _pid Pool ID to withdraw from
     */
    function withdraw(uint _pid) external nonReentrant {
        if (_pid > totalPools) revert GeneralStaking__InvalidPoolId(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        _updateAndPayOrLock(msg.sender, _pid);

        uint256 amount = user.depositAmount;
        uint penalty = 0;

        if (!_canHarvest(user.lastDeposit, pool.withdrawLockPeriod)) {
            rewardTokens += user.rewardLockedUp;
            penalty = (amount * earlyWithdrawFee) / FEE_BASE;
            amount -= penalty;
        }
        pool.totalDeposit -= user.depositAmount;

        userInfo[_pid][msg.sender] = UserInfo({
            depositAmount: 0,
            rewardDebt: 0,
            rewardLockedUp: 0,
            lastInteraction: block.timestamp,
            lastDeposit: 0
        });

        _safeTokenTransfer(msg.sender, amount);
        if (penalty > 0) _safeTokenTransfer(marketingAddress, penalty);
        emit Withdraw(msg.sender, _pid, amount);
    }

    /**
     * @notice Withdraw all deposited tokens from the pool disregarding the lock period and rewards
     * @param _pid Pool ID to withdraw from
     */
    function emergencyWithdraw(uint _pid) external nonReentrant {
        if (_pid > totalPools) revert GeneralStaking__InvalidPoolId(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.depositAmount;
        pool.totalDeposit -= user.depositAmount;

        if(user.rewardLockedUp > 0) {
            // free up the locked up rewards
            rewardTokens += user.rewardLockedUp;
        }

        userInfo[_pid][msg.sender] = UserInfo({
            depositAmount: 0,
            rewardDebt: 0,
            rewardLockedUp: 0,
            lastInteraction: block.timestamp,
            lastDeposit: 0
        });

        _safeTokenTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @notice Harvest rewards from a pool
     * @param _pid Pool ID to harvest from
     * @dev If user still cant harvest, it will lock the rewards for the user until lock is lifted
     */
    function harvest(uint _pid) external nonReentrant {
        if (_pid > totalPools) revert GeneralStaking__InvalidPoolId(_pid);
        _updateAndPayOrLock(msg.sender, _pid);
    }

    /**
     * @notice add a pool to the list with the given APR and withdraw lock period
     * @param _poolApr APR that is assured for any user in the pool
     * @param _withdrawLockPeriod Time in days that the user has to wait to withdraw
     */
    function addPool(
        uint256 _poolApr,
        uint256 _withdrawLockPeriod
    ) external onlyOwner {
        if (_poolApr == 0) revert GeneralStaking__InvalidPoolApr(_poolApr);
        if (_withdrawLockPeriod > 365)
            revert GeneralStaking__InvalidWithdrawLockPeriod(
                _withdrawLockPeriod
            );
        _withdrawLockPeriod *= 1 days; // value in seconds

        poolInfo[totalPools] = PoolInfo({
            poolApr: _poolApr,
            totalDeposit: 0,
            withdrawLockPeriod: _withdrawLockPeriod,
            accAprOverTime: 0,
            lastUpdate: block.timestamp
        });

        emit PoolAdd(totalPools);
        totalPools++;
    }

    /**
     *
     * @param _poolId The id to edit
     * @param _poolApr the new pool APR, if 0, the pool is disabled to deposit
     * @param _withdrawLockPeriod the new lock period. if 0, lock is removed. I think max should be 1 year.
     */
    function editPool(
        uint256 _poolId,
        uint256 _poolApr,
        uint256 _withdrawLockPeriod
    ) external onlyOwner {
        if (_poolId > totalPools) revert GeneralStaking__InvalidPoolId(_poolId);
        if (_withdrawLockPeriod > 365)
            revert GeneralStaking__InvalidWithdrawLockPeriod(
                _withdrawLockPeriod
            );
        _updatePool(_poolId);
        _withdrawLockPeriod *= 1 days; // value in seconds
        poolInfo[_poolId].poolApr = _poolApr;
        poolInfo[_poolId].withdrawLockPeriod = _withdrawLockPeriod;
        emit EditPool(_poolId, _poolApr, _withdrawLockPeriod);
    }

    /**
     * @param _marketingAddress The new address to send marketing funds to
     */
    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        marketingAddress = _marketingAddress;
        emit MarketingWalletUpdate();
    }

    /**
     * @param _earlyWithdrawFee The new fee to be charged for early withdraws
     */
    function setEarlyWithdrawFee(uint256 _earlyWithdrawFee) external onlyOwner {
        if (_earlyWithdrawFee > 20)
            revert GeneralStaking__InvalidEarlyWithdrawFee();
        emit EarlyWithdrawalUpdate(earlyWithdrawFee, _earlyWithdrawFee);
        earlyWithdrawFee = _earlyWithdrawFee;
    }

    /**
     * Last resort to recover any tokens that were destined for rewards
     * @param _to The address to send the tokens to
     */
    function recoverTreasure(address _to) external onlyOwner {
        if (_to == address(0) || rewardTokens == 0)
            revert GeneralStaking__InvalidSettings();
        if (!token.transfer(_to, rewardTokens))
            revert GeneralStaking__InvalidTransfer();
        rewardTokens = 0;
        emit TreasureRecovered();
    }

    /**
     * Add tokens for rewards in the pool
     * @param _rewardTokens The amount of tokens to add to the reward pool
     */
    function addRewardTokens(uint256 _rewardTokens) external {
        if (_rewardTokens == 0) revert GeneralStaking__InvalidAmount();
        rewardTokens += _rewardTokens;

        if (!token.transferFrom(msg.sender, address(this), _rewardTokens))
            revert GeneralStaking__InvalidTransferFrom();
    }

    //---------------------------------------------
    //   Internal Functions
    //---------------------------------------------
    /**
     *
     * @param _poolId The pool ID to update values for
     * @dev Updates the current pool reward amount
     */
    function _updatePool(uint256 _poolId) internal {
        PoolInfo storage pool = poolInfo[_poolId];

        if (block.timestamp > pool.lastUpdate && pool.poolApr > 0) {
            uint256 timePassed = (block.timestamp - pool.lastUpdate) *
                pool.poolApr;
            pool.accAprOverTime += timePassed;
        }
        pool.lastUpdate = block.timestamp;
        return;
    }

    /**
     * @notice This function exists to prevent rounding error issues
     * @param _to Address to send the funds to
     * @param _amount amount of Reward Token to send to _to address
     */
    function _safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    function _payOrLockTokens(address _user, uint _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint pending = ((pool.accAprOverTime * user.depositAmount) -
            user.rewardDebt) / REWARD_DENOMINATOR;

        rewardTokens -= pending; // remove pending tokens from reward pool

        if (_canHarvest(user.lastDeposit, pool.withdrawLockPeriod)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                pending += user.rewardLockedUp;
                user.rewardLockedUp = 0;
                _safeTokenTransfer(_user, pending);
                emit RewardsPaid();
            }
        } else if (pending > 0) {
            user.rewardLockedUp += pending;
            emit RewardLockedUp(_user, _pid, pending);
        }
    }

    function _updateAndPayOrLock(address _user, uint _pid) internal {
        _updatePool(_pid);
        _payOrLockTokens(_user, _pid);
    }

    function _canHarvest(
        uint lastDeposit,
        uint withdrawLock
    ) internal view returns (bool) {
        return lastDeposit + withdrawLock < block.timestamp;
    }

    //---------------------------------------------
    //   Private Functions
    //---------------------------------------------

    //---------------------------------------------
    //   External & Public View Functions
    //---------------------------------------------
    /**
     *  @notice  Request an APPROXIMATE amount of time until the contract runs out of funds on rewards
     *  @notice PLEASE NOTE THAT THIS IS AN APPROXIMATION, IT DOES NOT TAKE INTO ACCOUNT PENDING REWARDS NEEDED TO BE CLAIMED
     *  @return Returns the amount of seconds when the contract runs out of funds
     */
    function timeToEmpty() external view returns (uint256) {
        uint allPools = totalPools;
        uint rewardsPerSecond = 0;
        for (uint i = 0; i < allPools; i++) {
            rewardsPerSecond +=
                (poolInfo[i].poolApr * poolInfo[i].totalDeposit) /
                (BASE_APR * 365 days);
        }
        if (rewardsPerSecond == 0 || rewardTokens == 0) return 0;
        return rewardTokens / rewardsPerSecond;
    }

    /**
     * @notice This function returns the pending Rewards for a specific user in a pool
     * @param _pid The pool Id to check
     * @param _userAddress The user address to check
     */
    function pendingReward(
        uint _pid,
        address _userAddress
    ) external view returns (uint256) {
        if (_pid > totalPools) revert GeneralStaking__InvalidPoolId(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAddress];

        uint256 accAprOverTime = pool.accAprOverTime;
        uint256 poolApr = pool.poolApr;
        uint256 lastUpdate = pool.lastUpdate;

        if (block.timestamp > lastUpdate && poolApr > 0) {
            uint256 timePassed = (block.timestamp - lastUpdate) * poolApr;
            accAprOverTime += timePassed;
        }

        return
            ((accAprOverTime * user.depositAmount) - user.rewardDebt) /
            (REWARD_DENOMINATOR);
    }
}