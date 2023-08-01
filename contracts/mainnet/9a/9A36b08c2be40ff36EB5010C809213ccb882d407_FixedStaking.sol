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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FixedStaking is Ownable, ReentrancyGuard {
    struct UserInfo {
        uint256 lastStakeTime;
        uint256 amount;
        uint256 waitingRewards;
        UnbondInfo[] unbondings;
    }

    struct UnbondInfo {
        uint256 amount;
        uint256 release;
    }

    struct RewardPeriod {
        uint256 start;
        uint256 rate;
    }

    uint256 public constant RATE_DIVIDER = 100_000;
    uint256 public constant YEAR_DIVIDER = 31556952;

    IERC20 public token;
    RewardPeriod[] public rewardPeriods;
    mapping(address => UserInfo) public userInfo;
    uint256 public totalStaked;
    uint256 public unbondLimit = 5;
    uint256 public unbondTime = 7 days;
    uint256 private ethFee;

    event StakeStarted(address indexed user, uint256 amount);
    event UnstakeStarted(address indexed user, uint256 amount);
    event UnstakeFinished(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event Restaked(address indexed user, uint256 amount);
    event UnbondTimeUpdated(uint256 daysNumber);
    event Withdraw(address user, uint256 amount);
    event WithdrawEth(address user, uint256 amount);
    event UpdateFee(uint256 newFee);

    error TransferFailed();
    error WithdrawFailed();

    modifier checkEthFeeAndRefundDust(uint256 value) {
        require(value >= ethFee, "Insufficient fee: the required fee must be covered");
        uint256 dust = value - ethFee;
        (bool sent,) = address(msg.sender).call{value : dust}("");
        require(sent, "Failed to return overpayment");
        _;
    }

    constructor(IERC20 _token, uint256 _start, uint256 _rate, uint256 _ethFee) {
        token = _token;
        ethFee = _ethFee;
        rewardPeriods.push(RewardPeriod(_start, _rate));
    }

    function stake(uint256 _amount) external nonReentrant {
        require(token.transferFrom(msg.sender, address(this), _amount), "Stake transfer failed.");

        totalStaked += _amount;
        UserInfo storage user = userInfo[msg.sender];
        if (user.amount != 0) {
            uint256 pending = calculateReward(msg.sender);
            if (pending > 0) {
                user.waitingRewards += pending;
                user.lastStakeTime = block.timestamp;
            }
        }
        user.amount += _amount;
        user.lastStakeTime = block.timestamp;
        emit StakeStarted(msg.sender, _amount);
    }

    function pendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];

        uint256 pending = calculateReward(_user);
        return pending + user.waitingRewards;
    }


    function startUnstaking(uint256 _amount) external payable checkEthFeeAndRefundDust(msg.value) nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.unbondings.length < unbondLimit, "startUnstaking: limit reached");
        require(user.amount >= _amount, "startUnstaking: not enough staked amount");
        totalStaked -= _amount;
        uint256 pending = calculateReward(msg.sender);
        if (pending > 0) {
            user.waitingRewards += pending;
            user.lastStakeTime = block.timestamp;
        }
        user.amount -= _amount;

        UnbondInfo memory newUnbond = UnbondInfo({
        amount : _amount,
        release : block.timestamp + unbondTime
        });

        user.unbondings.push(newUnbond);
        emit UnstakeStarted(msg.sender, _amount);
    }

    function finishUnstaking() external payable checkEthFeeAndRefundDust(msg.value) nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 releasedAmount;

        uint256 i = 0;
        while (i < user.unbondings.length) {
            UnbondInfo storage unbonding = user.unbondings[i];
            if (unbonding.release <= block.timestamp) {
                releasedAmount += unbonding.amount;
                if (i != user.unbondings.length - 1) {
                    user.unbondings[i] = user.unbondings[user.unbondings.length - 1];
                }
                user.unbondings.pop();
            } else {
                i++;
            }
        }

        require(releasedAmount > 0, "Nothing to release");
        require(token.transfer(msg.sender, releasedAmount), "Finish unstaking transfer failed.");
        emit UnstakeFinished(msg.sender, releasedAmount);
    }

    function claim() external payable checkEthFeeAndRefundDust(msg.value) nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending = calculateReward(msg.sender) + user.waitingRewards;
        require(pending > 0, "claim: nothing to claim");
        user.waitingRewards = 0;
        user.lastStakeTime = block.timestamp;
        require(token.transfer(msg.sender, pending), "Claim transfer failed.");
        emit RewardClaimed(msg.sender, pending);
    }

    function restake() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 pending = calculateReward(msg.sender) + user.waitingRewards;
        require(pending > 0, "restake: nothing to restake");
        user.waitingRewards = 0;
        user.amount += pending;
        totalStaked += pending;
        user.lastStakeTime = block.timestamp;
        emit Restaked(msg.sender, pending);
    }

    function calculateReward(address _user) public view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        if (user.lastStakeTime == 0) {
            return 0;
        }
        uint256 reward = 0;
        uint256 startIndex = 0;
        for (uint256 i = 0; i < rewardPeriods.length; i++) {
            if (rewardPeriods[i].start < user.lastStakeTime) {
                startIndex = i;
            }
        }

        for (uint256 i = startIndex; i < rewardPeriods.length; i++) {
            uint256 timeDelta;
            if (i < rewardPeriods.length - 1) {
                uint256 tempStart = rewardPeriods[i].start < user.lastStakeTime ? user.lastStakeTime : rewardPeriods[i].start;
                timeDelta = rewardPeriods[i + 1].start - tempStart;
                reward += user.amount * rewardPeriods[i].rate * timeDelta / YEAR_DIVIDER / RATE_DIVIDER;
            } else {
                uint256 tempStart = rewardPeriods[i].start < user.lastStakeTime ? user.lastStakeTime : rewardPeriods[i].start;
                timeDelta = block.timestamp - tempStart;
                reward += user.amount * rewardPeriods[i].rate * timeDelta / YEAR_DIVIDER / RATE_DIVIDER;
            }
        }
        return reward;
    }

    function getUserInfo(address _user) external view returns (uint256, uint256) {
        uint256 pending = pendingReward(_user);
        return (userInfo[_user].amount, pending);
    }

    function getUserUnbondings(address _user) external view returns (uint256[] memory, uint256[] memory) {
        UnbondInfo[] memory unbondings = userInfo[_user].unbondings;
        uint256[] memory amounts = new uint256[](unbondings.length);
        uint256[] memory releases = new uint256[](unbondings.length);

        for (uint i = 0; i < unbondings.length; i++) {
            amounts[i] = unbondings[i].amount;
            releases[i] = unbondings[i].release;
        }

        return (amounts, releases);
    }

    function setUnbondTimeInDays(uint256 _days) external onlyOwner {
        require(_days < 100, "setUnbondTimeInDays: over 100 days");
        unbondTime = _days * 1 days;
        emit UnbondTimeUpdated(_days);
    }

    function setRate(uint256 _rate) external onlyOwner {
        rewardPeriods.push(RewardPeriod(block.timestamp, _rate));
    }

    function withdrawToken(IERC20 _token, uint256 amount) external onlyOwner {

        if (
            !_token.transfer(owner(), amount)
        ) {
            revert TransferFailed();
        }

        emit Withdraw(owner(), amount);
    }

    function withdrawEth(uint256 amount) external onlyOwner {

        (bool success,) = payable(owner()).call{value : amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
        emit WithdrawEth(owner(), amount);
    }

    function updateEthFee(uint256 _newFee) external onlyOwner {

        ethFee = _newFee;
        emit UpdateFee(_newFee);
    }
}