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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BruhStaking is Ownable, ReentrancyGuard {
    struct SharedData {
        uint256 totalAmount;
        uint256 rewardPerShareToken;
        uint256 rewardRemain;
        uint256 rewardDeposited;
    }

    struct Reward {
        uint256 totalExcludedToken;
        uint256 lastClaim;
    }

    struct UserData {
        uint256 amount;
        uint256 lockedTime;
    }

    IERC20 public immutable rewardToken;

    SharedData public sharedData;

    uint256 public constant ACC_FACTOR = 10 ** 18;

    uint256 public minStakingAmount = 1_000 * 1e6;
    uint256 public totalTokenClaimed;
    uint256 public rewardPerSecond;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public lastDistribution;
    uint256 public totalUsers;

    uint256 public totalDistributed;

    bool public isFinished;
    bool public isEmergency;

    mapping(address => UserData) public userData;
    mapping(address => Reward) private rewards;

    event NewLock(address user, uint256 amount);
    event RewardDeposited(uint256 amount, uint256 time);
    event StakingCreated(uint256 totalAmount, uint256 startTime, uint256 endTime);
    event ClaimRewards(address indexed recipient, uint256 tokenAmount);
    event Unlock(address indexed user, uint256 amount);
    event SettingsUpdated(uint256 oldMinStakingAmount, uint256 newMinStakingAmount);
    event EmergencyEnabled(bool emergency, uint256 time);
    event EmergencyUnlock(address indexed user, uint256 amount);

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function start(
        uint256 _rewardAmount,
        uint256 _startTime
    ) external onlyOwner nonReentrant {
        require(startTime == 0, "already created");
        require(
            _startTime >= block.timestamp,
             "wrong time"
        );
        require(_rewardAmount > 0, 'zero amount passed');
        require(rewardToken.transferFrom(msg.sender, address(this), _rewardAmount), "Token transfer failed");

        endTime = _startTime + 90 days;
        uint256 totalStakingTimeInSeconds = endTime - _startTime;
        rewardPerSecond = _rewardAmount / totalStakingTimeInSeconds;
        startTime = _startTime;
        lastDistribution = startTime;
        sharedData.rewardRemain += _rewardAmount;
        sharedData.rewardDeposited += _rewardAmount;
        emit StakingCreated(_rewardAmount, startTime, endTime);
    }

    function participate(uint256 amount) external nonReentrant {
        require(block.timestamp < endTime, "staking ended");

        require(
            rewardToken.transferFrom(_msgSender(), address(this), amount),
            "token transfer failed"
        );

        _autoRewardDistribution();

        if (getUnpaid(msg.sender) > 0) {
            _claim(_msgSender());
        }

        uint256 storedAmount = userData[_msgSender()].amount;
        uint256 totalAmount = userData[_msgSender()].amount + amount;
        require(totalAmount >= minStakingAmount, "input less than minimum");

        if (storedAmount == 0) {
            totalUsers++;
        }

        sharedData.totalAmount += totalAmount - storedAmount;

        userData[_msgSender()].amount = totalAmount;
        userData[_msgSender()].lockedTime = block.timestamp;

        rewards[_msgSender()].totalExcludedToken = getCumulativeRewards(userData[_msgSender()].amount);

        emit NewLock(_msgSender(), totalAmount);
    }

    function claim() external nonReentrant {
        _autoRewardDistribution();
        _claim(_msgSender());
    }

    function unlock() public nonReentrant {
        require(userData[_msgSender()].amount > 0, "Nothing to unlock");

        _autoRewardDistribution();

        //claim reward
        uint256 unclaimedAmountToken = getUnpaid(_msgSender());
        if (unclaimedAmountToken > 0) {
            _claim(_msgSender());
        }

        sharedData.totalAmount -= userData[_msgSender()].amount;

        require(
            rewardToken.transfer(_msgSender(), userData[_msgSender()].amount),
            "token transfer failed"
        );

        totalUsers--;

        emit Unlock(_msgSender(), userData[_msgSender()].amount);
        delete userData[_msgSender()];
    }

    function emergencyUnlock() external nonReentrant {
        require(isEmergency, "Emergency not enabled");
        require(userData[_msgSender()].amount > 0, "Nothing to unlock");

        sharedData.totalAmount -= userData[_msgSender()].amount;

        require(
            rewardToken.transfer(_msgSender(), userData[_msgSender()].amount),
            "token transfer failed"
        );
        totalUsers--;
        emit EmergencyUnlock(_msgSender(), userData[_msgSender()].amount);
        delete userData[_msgSender()];
    }

    function _distributeReward(uint256 amount) internal {
        if (sharedData.totalAmount > 0) {
            sharedData.rewardPerShareToken += (amount * ACC_FACTOR) / sharedData.totalAmount;
            lastDistribution = block.timestamp;
            emit RewardDeposited(amount, block.timestamp);
        }
    }

    function getCumulativeRewards(
        uint256 share
    ) internal view returns (uint256) {
        return share * sharedData.rewardPerShareToken / ACC_FACTOR;
    }

    function getUnpaid(
        address shareholder
    ) internal view returns (uint256) {
        if (userData[shareholder].amount == 0) {
            return (0);
        }

        uint256 earnedRewardsToken = getCumulativeRewards(userData[shareholder].amount);
        uint256 rewardsExcludedToken = rewards[shareholder].totalExcludedToken;
        if (
            earnedRewardsToken <= rewardsExcludedToken
        ) {
            return (0);
        }

        return (
            earnedRewardsToken - rewardsExcludedToken
        );
    }

    function viewUnpaid(address user) external view returns (uint256) {
        if (userData[user].amount == 0) {
            return (0);
        }
        uint256 unpaidAmount = getUnpaid(user);
        uint256 time;
        if (block.timestamp >= endTime) {
            time = endTime;
        } else {
            time = block.timestamp;
        }
        if  (time > lastDistribution) {
            uint256 userRewardPerSecond = rewardPerSecond * userData[user].amount / sharedData.totalAmount;
            uint256 accumulatedRewards = userRewardPerSecond * (time - lastDistribution);
            unpaidAmount += accumulatedRewards;
        }
        return unpaidAmount;
    }

    function _autoRewardDistribution() internal {
        if (block.timestamp >= endTime && !isFinished){
            uint256 accumulatedRewards = (endTime - lastDistribution)*rewardPerSecond;
            totalDistributed += accumulatedRewards;
            _distributeReward(accumulatedRewards);
            lastDistribution = endTime;
            isFinished = true;
        } else {
            if  (block.timestamp > lastDistribution && !isFinished) {
                uint256 accumulatedRewards = (block.timestamp - lastDistribution)*rewardPerSecond;
                totalDistributed += accumulatedRewards;
                _distributeReward(accumulatedRewards);
            }
        }
    }

    function _claim(address user) internal {
        require(
            block.timestamp > rewards[user].lastClaim,
            "can only claim once per block"
        );
        require(userData[user].amount > 0, "no tokens staked");

        uint256 amountToken = getUnpaid(user);
        require(amountToken > 0, "nothing to claim");

        totalTokenClaimed += amountToken;
        rewards[user].totalExcludedToken = getCumulativeRewards(
            userData[user].amount
        );

        if (!isEmergency) {
           require(sharedData.rewardRemain - amountToken >= 0, "reward pool is empty");
            sharedData.rewardRemain -= amountToken;
        }

        require(rewardToken.transfer(user, amountToken), "token transfer failed");

        rewards[user].lastClaim = block.timestamp;
        emit ClaimRewards(user, amountToken);
    }

    function changeMinStakingAmount(
        uint256 _newMinStakingAmount
    ) external onlyOwner {
        uint256 oldMinStakingAmount = minStakingAmount;
        minStakingAmount = _newMinStakingAmount;
        emit SettingsUpdated(oldMinStakingAmount, minStakingAmount);
    }

    function enableEmergency() external onlyOwner {
        require(!isEmergency, "emergency already enabled");

        endTime = block.timestamp;
        _autoRewardDistribution();
        isEmergency = true;
        sharedData.rewardRemain = sharedData.rewardDeposited - totalDistributed;

        emit EmergencyEnabled(true, block.timestamp);
    }

    function withdraw(address _token, uint256 _amount) external onlyOwner {
        if (_token != address(0)) {
            if (_token == address(rewardToken)) {
                require(isEmergency, "Emergency not enabled");
                require(_amount <= sharedData.rewardRemain, "amount exceeded remain reward pool");
                sharedData.rewardRemain -= _amount;
            }
			IERC20(_token).transfer(msg.sender, _amount);
		} else {
			(bool success, ) = payable(msg.sender).call{ value: _amount }("");
			require(success, "Can't send ETH");
		}
	}

    receive() external payable {}
}