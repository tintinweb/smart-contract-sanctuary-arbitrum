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

// withdraw: unlock tokens from our smart contract
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error Staking__TransferFailed();
error Withdraw__TransferFailed();
error Staking__NeedsMoreThanZero();

contract Staking is ReentrancyGuard, Ownable {
    IERC20 public s_stakingToken;
    IERC20 public s_rewardToken;

    uint256 public s_reward_rate;
    uint256 public s_totalSupply;
    uint256 private s_rewardPerTokenStored;
    uint256 private s_lastUpdateTime;

    /** @dev Mapping from address to the amount the user has staked */
    mapping(address => uint256) private s_balances;

    /** @dev Mapping from address to the amount the user has been rewarded */
    mapping(address => uint256) private s_userRewardPerTokenPaid;

    /** @dev Mapping from address to the rewards claimable for user */
    mapping(address => uint256) private s_rewards;

    /** @dev Mapping from address to the last deposit time of user */
    mapping(address => uint256) private s_lastDepositTime;

    modifier updateReward(address account) {
        // how much reward per token?
        // get last timestamp
        // between 12 - 1pm , user earned X tokens. Needs to verify time staked to distribute correct amount to each
        // participant
        s_rewardPerTokenStored = rewardPerToken();
        s_lastUpdateTime = block.timestamp;
        s_rewards[account] = earned(account);
        s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;

        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert Staking__NeedsMoreThanZero();
        }
        _;
    }

    /**
     * Event for setting the rate
     * @param setter who set the rate
     * @param rate amount of tokens purchased
     */
    event RewardRateSet(address indexed setter, uint256 rate);

    /**
     * Event for token stake logging
     * @param staker who paid for the tokens
     * @param amount amount of tokens purchased
     */
    event BimUsdStake(address indexed staker, uint256 amount);

    /**
     * Event for reward claim logging
     * @param claimer who paid for the tokens
     * @param amount amount of tokens purchased
     */
    event RewardClaim(address indexed claimer, uint256 amount);

    /**
     * Event for token withdraw logging
     * @param unstaker who paid for the tokens
     * @param amount amount of tokens purchased
     */
    event BimUsdWithdraw(address indexed unstaker, uint256 amount);

    constructor(
        address stakingToken,
        address rewardToken,
        uint256 _reward_rate
    ) {
        s_stakingToken = IERC20(stakingToken);
        s_rewardToken = IERC20(rewardToken);
        s_reward_rate = _reward_rate;
    }

    function setRewardRate(uint256 _reward_rate) external onlyOwner {
        s_reward_rate = _reward_rate;
        emit RewardRateSet(msg.sender, _reward_rate);
    }

    function earned(address account) public view returns (uint256) {
        uint256 currentBalance = s_balances[account];
        // how much they were paid already
        uint256 amountPaid = s_userRewardPerTokenPaid[account];
        uint256 currentRewardPerToken = rewardPerToken();
        uint256 pastRewards = s_rewards[account];
        uint256 _earned = ((currentBalance *
            (currentRewardPerToken - amountPaid)) / 1e18) + pastRewards;

        return _earned;
    }

    /** @dev Basis of how long it's been during the most recent snapshot/block */
    function rewardPerToken() public view returns (uint256) {
        if (s_totalSupply == 0) {
            return s_rewardPerTokenStored;
        } else {
            return
                s_rewardPerTokenStored +
                (((block.timestamp - s_lastUpdateTime) * s_reward_rate * 1e9));
        }
    }

    function stake(
        uint256 amount
    ) external updateReward(msg.sender) moreThanZero(amount) {
        // keep track of how much this user has staked
        // keep track of how much token we have total
        // transfer the tokens to this contract
        /** @notice Be mindful of reentrancy attack here */
        s_balances[msg.sender] += amount;
        s_totalSupply += amount;
        s_lastDepositTime[msg.sender] = block.timestamp;
        //emit event
        bool success = s_stakingToken.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        // require(success, "Failed"); Save gas fees here
        if (!success) {
            revert Staking__TransferFailed();
        } else {
            emit BimUsdStake(msg.sender, amount);
        }
    }

    // Withdraw with rewards.

    function withdraw(
        uint256 amount
    ) external updateReward(msg.sender) moreThanZero(amount) nonReentrant {
        if (block.timestamp > s_lastDepositTime[msg.sender] + 48 hours) {
            //withdraw token
            s_balances[msg.sender] -= amount;
            s_totalSupply -= amount;
            bool success = s_stakingToken.transfer(msg.sender, amount);
            if (!success) {
                revert Withdraw__TransferFailed();
            }
            emit BimUsdWithdraw(msg.sender, amount);

            //Claim reward
            uint256 reward = s_rewards[msg.sender];
            s_rewards[msg.sender] = 0;
            bool successReward = s_rewardToken.transfer(msg.sender, reward);
            if (!successReward) {
                revert Staking__TransferFailed();
            }
            emit RewardClaim(msg.sender, reward);
        } else {
            //reward to 0
            s_rewards[msg.sender] = 0;
            s_balances[msg.sender] -= amount;
            s_totalSupply -= amount;
            // emit event
            bool success = s_stakingToken.transfer(msg.sender, amount);
            if (!success) {
                revert Withdraw__TransferFailed();
            }
            emit BimUsdWithdraw(msg.sender, amount);
        }
    }

    function claimReward() external updateReward(msg.sender) nonReentrant {
        if (block.timestamp > s_lastDepositTime[msg.sender] + 48 hours) {
            uint256 reward = s_rewards[msg.sender];
            s_rewards[msg.sender] = 0;
            bool success = s_rewardToken.transfer(msg.sender, reward);
            if (!success) {
                revert Staking__TransferFailed();
            }
            emit RewardClaim(msg.sender, reward);
        } else {
            //reward to 0
            s_rewards[msg.sender] = 0;
            emit RewardClaim(msg.sender, 0);
        }
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(
        uint256 amount
    ) external updateReward(msg.sender) moreThanZero(amount) nonReentrant {
        //reward to 0
        s_rewards[msg.sender] = 0;
        s_balances[msg.sender] -= amount;
        s_totalSupply -= amount;
        // emit event
        bool success = s_stakingToken.transfer(msg.sender, amount);
        if (!success) {
            revert Withdraw__TransferFailed();
        }
        emit BimUsdWithdraw(msg.sender, amount);
    }

    // Getter for UI
    function getStaked(address account) public view returns (uint256) {
        return s_balances[account];
    }
}