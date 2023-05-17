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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract SibaAIStaking is Ownable {

// bool
    bool public hasUserLimit;
    bool public isInitialized;
    bool public poolIsOnline;
    bool public withdrawTimerStatus;
    bool public depositEnabled;
    bool public withdrawEnabled;
    bool public compoundEnabled;
    bool public emergencyWithdrawEnabled;
    bool public hasMinimumDeposit;
    bool private tempLock;
    bool private isSameToken;

// uint
    uint256 public totalUsersInStaking;
    uint256 public poolTotalReward;
    uint256 public minimumDeposit;
    uint256 public accTokenPerShare;
    uint256 public bonusEndBlock;
    uint256 public startBlock;
    uint256 public lastRewardBlock;
    uint256 public poolLimitPerUser;
    uint256 public rewardPerBlock;
    uint256 public minimumLockTime;
    uint256 public compoundLockTime;
    uint256 public PRECISION_FACTOR;
    uint256 public totalUsersStake;
    uint256 public totalUsersRewards;
    uint256 public emergencyWithdrawFee;

// custom
    IERC20Metadata public rewardToken;
    IERC20Metadata public stakedToken;

// mapping
    mapping(address => UserInfo) public userInfo;

// struct
    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        uint256 lockTime; // time when locked
    }

// event
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PoolFunded(uint256 amount);
    event Compound(address indexed user, uint256 amount);
    event ClaimReward(address indexed user, uint256 amount);

// constructor
    constructor() {
    }

    function enablePool() external onlyOwner {
        poolIsOnline = true;
        depositEnabled = true;
        withdrawEnabled = true;
        compoundEnabled = true;
        withdrawTimerStatus = true;
        emergencyWithdrawEnabled = true;
    }

// set emergency withdraw fee
    function setEmergencyWithdrawFee(uint256 _fee) external onlyOwner {
        emergencyWithdrawFee = _fee;
        require(emergencyWithdrawFee <= 30, "max fee is 30%");
    }

// set minimum deposit
    function setMinimumDeposit(bool _state, uint256 value) external onlyOwner {
        hasMinimumDeposit = _state;
        minimumDeposit = value;
    }

// set withdraw timer status
    function setwithdrawTimerStatus(bool _state) external onlyOwner {
        withdrawTimerStatus = _state;
    }

// set lock time
    function setLockTime(uint256 _deposit, uint256 _compound) external onlyOwner {
        if(_deposit != 1) {
            minimumLockTime = _deposit;
        }
        if(_compound != 1) {
            compoundLockTime = _compound;
        }
        require(minimumLockTime <= 90 days, "max lock time is 90 days");
        require(compoundLockTime <= 10 days, "max lock time is 90 days");
    }

    function fundPool(uint256 amount) external onlyOwner {
        poolTotalReward += amount;
        rewardToken.transferFrom(address(msg.sender), address(this), amount);
        emit PoolFunded(amount);
    }

    function istart(
        IERC20Metadata _stakedToken,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _poolLimitPerUser
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");

        isInitialized = true;
        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        emergencyWithdrawFee = 5;
        minimumLockTime = 30 days;
        compoundLockTime = 5 days;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;
            poolLimitPerUser = _poolLimitPerUser;
        }

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30) - decimalsRewardToken));

        lastRewardBlock = startBlock;

        if(rewardToken == stakedToken) {
            isSameToken = true;
        }
    }

    modifier isPoolOnline(uint8 action_type) {
        require(poolIsOnline,"staking platform not available now.");
        if (action_type == 0) {
            require(depositEnabled,"deposits not available now.");
        }
        else if (action_type == 1) {
            require(withdrawEnabled,"withdraws not available now.");
        }
        else if (action_type == 2) {
            require(compoundEnabled,"compounds not available now.");
        }
        else if (action_type == 6) {
            require(emergencyWithdrawEnabled,"emergency withdraws not available now.");
        }
        _;
    }

// user functions
    function deposit(uint256 _amount) external isPoolOnline(0) {
        require(!tempLock,"safety block");
        require(_amount > 0, "Amount must be greater than 0");
        tempLock = true;
        UserInfo storage user = userInfo[msg.sender];
        if (hasUserLimit) {
            require(_amount + user.amount <= poolLimitPerUser, "User amount above limit");
        }
        if (hasMinimumDeposit) {
            require(_amount >= minimumDeposit,"deposit too low.");
        }
        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
            if (pending > 0) {
                totalUsersRewards += pending;
                poolTotalReward -= pending;
                rewardToken.transfer(address(msg.sender), pending);
                emit ClaimReward(msg.sender,pending);
            }
        } else {
            totalUsersInStaking += 1;
        }

        user.amount = user.amount + _amount;
        totalUsersStake += _amount;
        stakedToken.transferFrom(address(msg.sender), address(this), _amount);
        

        user.rewardDebt = user.amount * accTokenPerShare / PRECISION_FACTOR;

        user.lockTime = block.timestamp + minimumLockTime;
        tempLock = false;
        emit Deposit(msg.sender, _amount);
    }
    function withdraw(uint256 _amount) external isPoolOnline(1) {
        require(!tempLock,"safety block");
        require(_amount > 0, "Amount must be greater than 0");
        tempLock = true;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");
        if(withdrawTimerStatus) {
            require(block.timestamp >= user.lockTime,"locking period has not expired"
            );
        }

        _updatePool();

        uint256 pending = user.amount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;

        user.amount = user.amount - _amount;
        totalUsersStake -= _amount;
        stakedToken.transfer(address(msg.sender), _amount);
        

        if (pending > 0) {
            totalUsersRewards += pending;
            poolTotalReward -= pending;
            rewardToken.transfer(address(msg.sender), pending);
            emit ClaimReward(msg.sender,pending);
        }

        user.rewardDebt = user.amount * accTokenPerShare / PRECISION_FACTOR;
        
        if (user.amount == 0) {
            user.lockTime = 0;
            totalUsersInStaking -= 1;
        }

        tempLock = false;
        emit Withdraw(msg.sender, _amount);
    }
    function compound() external isPoolOnline(2) returns(uint256 pending){
        require(!tempLock,"safety block");
        require(isSameToken,"cannot compound if reward token is not the same as staked token");
        tempLock = true;
        UserInfo storage user = userInfo[msg.sender];
        if(user.amount > 0) {
            _updatePool();
            pending = user.amount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
            if(pending > 0) {
                totalUsersRewards += pending;
                poolTotalReward -= pending;
                totalUsersStake += pending;
                user.amount = user.amount + pending;
                user.rewardDebt = user.amount * accTokenPerShare / PRECISION_FACTOR;
                if (user.lockTime < block.timestamp) {
                    user.lockTime = block.timestamp + compoundLockTime;
                } else {
                    user.lockTime += compoundLockTime;
                }
                emit Compound(msg.sender, pending);
            }
        } else {
            revert("nothing to compound");
        }
        tempLock = false;
        return pending;
    }

    function emergencyWithdraw() external isPoolOnline(6) {
        require(!tempLock,"safety block");
        tempLock = true;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "nothing to withdraw");

        uint256 fee = user.amount * emergencyWithdrawFee / 100;
        uint256 amountToTransfer = user.amount - fee;

        // reset user data
        user.amount = 0;
        user.rewardDebt = 0;
        user.lockTime = 0;

        if (amountToTransfer > 0) {
            totalUsersStake -= amountToTransfer + fee;
            totalUsersInStaking -= 1;
            if(isSameToken) {
                poolTotalReward += fee;
            } else {
                stakedToken.transfer(owner(), fee);
            }
            
            stakedToken.transfer(address(msg.sender), amountToTransfer);
        }

        tempLock = false;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }
    
    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        hasUserLimit = _hasUserLimit;
        poolLimitPerUser = _poolLimitPerUser;
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
    }

    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        lastRewardBlock = startBlock;
    }

    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply;
        if(isSameToken) {
            stakedTokenSupply = stakedToken.balanceOf(address(this)) - poolTotalReward;
        } else {
            stakedTokenSupply = stakedToken.balanceOf(address(this));
        }
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 cakeReward = multiplier * rewardPerBlock;
            uint256 adjustedTokenPerShare =
                accTokenPerShare + (cakeReward * PRECISION_FACTOR / stakedTokenSupply);
            return user.amount * adjustedTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        } else {
            return user.amount * accTokenPerShare / PRECISION_FACTOR - user.rewardDebt;
        }
    }

    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this));

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 cakeReward = multiplier * rewardPerBlock;
        accTokenPerShare = accTokenPerShare + (cakeReward * PRECISION_FACTOR / stakedTokenSupply);
        lastRewardBlock = block.number;
    }

    function getBlockData() public view returns(uint blockNumber,uint blockTime) {
        blockNumber = block.number;
        blockTime = block.timestamp;
        return (blockNumber,blockTime);
    }

    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }
}