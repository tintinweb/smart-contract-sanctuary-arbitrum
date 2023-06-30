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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DMTStake is Ownable {
    IERC20 public token;
    uint256 public prizePool;
    uint256 public APY = 420;
    uint256 public LOCKING_PERIOD = 1 minutes;
    bool public EMERGENCY = false;

    event WithdrawalRequested(address indexed user, uint256 amount, uint256 requestTS, uint256 releaseTime);
    event TokensLocked(address indexed user, uint256 amount, uint256 timestamp);
    event TokensUnlocked(address indexed user, uint256 amount, uint256 timestamp);
    event RewardsClaimed(address indexed user, uint256 reward, uint256 timestamp);

    struct UserInfo {
        uint256 lockedTokens;
        uint256 amountWithdrawTokens;
        uint256 lastRewardClaimTimeStamp;
        uint256 withdrawTimes;
        mapping(uint256 => uint256) withdrawrequest;
        mapping(uint256 => uint256) UnlockTimeStamp;
    }

    mapping(address => UserInfo) public userInfo;

    constructor(IERC20 _token) {
        token = _token;
    }

    function stake(uint256 amount) public {
        require(amount <= token.balanceOf(msg.sender), "Not Enough Token");
        require(!EMERGENCY, "Staking is Stopped");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        require(prizePool > 0, "Prize Pool is Empty");
        UserInfo storage user = userInfo[msg.sender];
        user.lockedTokens += amount;
        user.lastRewardClaimTimeStamp = block.timestamp;
        emit TokensLocked(msg.sender, amount, block.timestamp);
    }

    function stakeOnBehalfGroup(
        uint256[] calldata amounts,
        address[] calldata targets,
        uint256[] calldata stakeTimestamps
    ) public onlyOwner {
        require(amounts.length == targets.length, "Amounts and targets mismatch");
        require(amounts.length == stakeTimestamps.length, "Amounts and stakeTimestamps mismatch");
        for (uint256 i = 0; i < amounts.length; i++) {
            stakeOnBehalf(amounts[i], targets[i], stakeTimestamps[i]);
        }
    }

    function stakeOnBehalf(uint256 amount, address target, uint256 stakeTimestamp) public onlyOwner {
        require(amount <= token.balanceOf(msg.sender), "Not Enough Token");
        require(!EMERGENCY, "Staking is Stopped");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        UserInfo storage user = userInfo[target];
        user.lockedTokens += amount;
        user.lastRewardClaimTimeStamp = stakeTimestamp;
        emit TokensLocked(target, amount, stakeTimestamp);
    }

    function stakeAll(address userAddress) public {
        uint256 amount = token.balanceOf(userAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        require(!EMERGENCY, "Staking is Stopped");
        require(userAddress == msg.sender, "Not owner");
        require(amount > 0, "Not enough token to stake");
        require(prizePool > 0, "Prize Pool is Empty");
        UserInfo storage user = userInfo[userAddress];
        user.lockedTokens += amount;
        user.lastRewardClaimTimeStamp = block.timestamp;
        emit TokensLocked(msg.sender, amount, block.timestamp);
    }

    function unstake(uint256 amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.lockedTokens > 0, "No tokens locked");
        require(!EMERGENCY, "Unstaking is stopped");
        require(amount + user.amountWithdrawTokens <= user.lockedTokens, "Cannot withdraw more than locked");
        user.withdrawTimes += 1;
        uint256 withdrawID = user.withdrawTimes;
        uint256 unlockTimestamp = block.timestamp + LOCKING_PERIOD;
        user.UnlockTimeStamp[withdrawID] = unlockTimestamp;
        user.amountWithdrawTokens += amount;
        user.withdrawrequest[withdrawID] = amount;
        emit WithdrawalRequested(msg.sender, amount, block.timestamp, unlockTimestamp);
    }

    function unstakeAll() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.lockedTokens - user.amountWithdrawTokens;
        require(amount != 0, "You requested to withdraw all locked tokens");
        require(!EMERGENCY, "Unstaking is Stopped");
        user.withdrawTimes += 1;
        uint256 withdrawID = user.withdrawTimes;
        uint256 unlockTimestamp = block.timestamp + LOCKING_PERIOD;
        user.UnlockTimeStamp[withdrawID] = unlockTimestamp;
        user.amountWithdrawTokens += amount;
        user.withdrawrequest[withdrawID] = amount;
        emit WithdrawalRequested(msg.sender, amount, block.timestamp, unlockTimestamp);
    }

    function claimTokens(uint256 _id, address userAddress) public {
        UserInfo storage user = userInfo[userAddress];
        uint256 amount = user.withdrawrequest[_id];
        require(amount > 0, "No pending withdrawal");
        require(block.timestamp >= user.UnlockTimeStamp[_id], "No time to claim");
        require(!EMERGENCY, "Claiming is Stopped");
        claimRewardstoWithdraw(userAddress);
        user.lockedTokens -= amount;
        user.amountWithdrawTokens -= amount;
        user.withdrawrequest[_id] = 0;
        token.transfer(userAddress, amount);
        emit TokensUnlocked(userAddress, amount, block.timestamp);
    }

    function calculateReward(address userAddress) public view returns (uint256) {
        UserInfo storage user = userInfo[userAddress];
        uint256 stakedAmount = user.lockedTokens;
        uint256 lastClaimTime = user.lastRewardClaimTimeStamp;
        uint256 RewardforYear = (stakedAmount * APY) / 100;
        uint256 RewardperDay = RewardforYear / 365;
        uint256 timeelapsed = block.timestamp - lastClaimTime;
        uint256 rewards = (RewardperDay * timeelapsed) / 1 days;

        return rewards;
    }

    function stakeRewards() public {
        UserInfo storage user = userInfo[msg.sender];
        uint256 rewards = calculateReward(msg.sender);
        require(rewards > 0, "No Rewards to stake");
        require(prizePool >= rewards, "Prize Pool is Empty");
        require(!EMERGENCY, "Claiming is Stopped");
        claimRewardstoStake(msg.sender, rewards);
        user.lockedTokens += rewards;
        emit TokensLocked(msg.sender, rewards, block.timestamp);
    }

    function claimRewards(address userAddress) public {
        UserInfo storage user = userInfo[userAddress];
        uint256 reward = calculateReward(userAddress);
        require(reward > 0, "No rewards to claim");
        require(prizePool >= reward, "Prize Pool is Empty");
        require(!EMERGENCY, "Claiming is Stopped");
        if (reward > 0) {
            token.transfer(userAddress, reward);
            user.lastRewardClaimTimeStamp = block.timestamp;
            prizePool -= reward;
            emit RewardsClaimed(userAddress, reward, block.timestamp);
        }
    }

    function claimRewardstoWithdraw(address userAddress) internal {
        UserInfo storage user = userInfo[userAddress];
        uint256 reward = calculateReward(userAddress);
        if (prizePool >= reward) {
            token.transfer(userAddress, reward);
            prizePool -= reward;
        }
        user.lastRewardClaimTimeStamp = block.timestamp;
        emit RewardsClaimed(userAddress, reward, block.timestamp);
    }

    function claimRewardstoStake(address userAddress, uint256 rewards) internal {
        UserInfo storage user = userInfo[userAddress];
        require(rewards > 0, "No rewards to claim");

        if (rewards > 0) {
            user.lastRewardClaimTimeStamp = block.timestamp;
            prizePool -= rewards;
            emit RewardsClaimed(msg.sender, rewards, block.timestamp);
        }
    }

    function changeAPY(uint256 _newapy) public onlyOwner {
        APY = _newapy;
    }

    function changeLockPeriod(uint256 _newtimestamp) public onlyOwner {
        LOCKING_PERIOD = _newtimestamp;
    }

    function isEmergency(bool _status) public onlyOwner {
        EMERGENCY = _status;
    }

    function getWithdraws(address userAddr, uint256 _id) public view returns (uint256) {
        UserInfo storage user = userInfo[userAddr];
        return user.withdrawrequest[_id];
    }

    function getWithdrawUnlock(address userAddr, uint256 _id) public view returns (uint256) {
        UserInfo storage user = userInfo[userAddr];
        return user.UnlockTimeStamp[_id];
    }

    function chargePool(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer Failed");
        prizePool += amount;
    }

    function withdrawPool(uint256 amount, address _address) public onlyOwner {
        require(amount <= prizePool, "Amount greater than prizepool");
        token.transfer(_address, amount);
        prizePool -= amount;
    }

    function emergencyWithdraw(address _user) public {
        require(EMERGENCY, "Everything is fine, no need to panic");
        UserInfo storage user = userInfo[_user];
        uint256 amount = user.lockedTokens;
        token.transfer(_user, amount);
        user.lockedTokens = 0;
        user.amountWithdrawTokens = 0;
        user.lastRewardClaimTimeStamp = 0;
    }
}