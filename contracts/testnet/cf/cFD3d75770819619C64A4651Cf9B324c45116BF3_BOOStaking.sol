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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BOOStaking is Ownable {

    mapping(address => uint256) public stakedBalances;
    mapping(address => uint256) public lastClaimedTimes;
    mapping(address => uint256) public pendingRewards;

    uint256 public stakingRewardRate = 1; // 1 token per hour per token staked
    uint256 public lastHourlyDistributionTime = block.timestamp;
    uint256 public totalStaked;
    uint256 public rewardsPool;
   
    address[] public stakers;

    IERC20 public GODLY;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsAddedToPool(address indexed user, uint256 amount);

    constructor(address _godly) {
        GODLY = IERC20(_godly);
        lastHourlyDistributionTime = block.timestamp;
    }

    function stake(uint256 amount) public {
        require(amount > 0, "Cannot stake 0 tokens");
        require(GODLY.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(GODLY.allowance(msg.sender, address(this)) >= amount, "Must approve tokens first");

        GODLY.transferFrom(msg.sender, address(this), amount);

        if (stakedBalances[msg.sender] == 0) {
            stakers.push(msg.sender);
        }

        stakedBalances[msg.sender] += amount;
        totalStaked += amount;
        lastClaimedTimes[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function unstake() public {
        uint256 amount = stakedBalances[msg.sender];

        require(amount > 0, "Nothing to withdraw");

        stakedBalances[msg.sender] = 0;
        totalStaked -= amount;
        GODLY.transfer(msg.sender, amount);
        lastClaimedTimes[msg.sender] = block.timestamp;

        if (stakedBalances[msg.sender] == 0) {
            removeStaker(msg.sender);
        }

        emit Unstaked(msg.sender, amount);
    }

    function getStakers() public view returns (address[] memory) {
        return stakers;
    }

    function totalStakers() public view returns (uint256) {
        return stakers.length;
    }

    function removeStaker(address staker) internal {
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i] == staker) {
                stakers[i] = stakers[stakers.length - 1];
                stakers.pop();
                break;
            }
        }
    }

    function claimRewards() public {
        uint256 reward = pendingRewards[msg.sender];
        require(reward > 0, "No rewards to claim");

        pendingRewards[msg.sender] = 0;
        lastClaimedTimes[msg.sender] = block.timestamp;
        GODLY.transfer(msg.sender, reward);
        emit RewardsClaimed(msg.sender, reward);
    }

    function distributeRewards() public {
        uint256 timeSinceLastDistribution = block.timestamp - lastHourlyDistributionTime;
        if (timeSinceLastDistribution >= 1 hours && rewardsPool > 0) {
            uint256 rewardsPerToken = stakingRewardRate / totalStaked;
            for (uint256 i = 0; i < stakers.length; i++) {
                address staker = stakers[i];
                uint256 stakerReward = stakedBalances[staker] * rewardsPerToken;
                pendingRewards[staker] += stakerReward;
            }
            rewardsPool -= stakingRewardRate;
            lastHourlyDistributionTime = block.timestamp;
        }
    }

    function withdrawRewardsPool() public onlyOwner {
        uint256 reward = rewardsPool;
        rewardsPool = 0;
        GODLY.transfer(msg.sender, reward);
    }

    function addRewardsPool(uint _amount) public onlyOwner {
        require(_amount > 0, "Cannot add 0 tokens");

        uint dailyRewards = _amount / 30; // Calculate daily rewards
        uint hourlyRewards = dailyRewards / 24; // Calculate hourly rewards
        stakingRewardRate = hourlyRewards;

        GODLY.transferFrom(msg.sender, address(this), _amount);
        rewardsPool += _amount;
        emit RewardsAddedToPool(msg.sender, _amount);
    }

    function rescueToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function rescueETH(uint256 _amount) external onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    function changeGodly(address _godly) public onlyOwner {
        GODLY = IERC20(_godly);
    }
}