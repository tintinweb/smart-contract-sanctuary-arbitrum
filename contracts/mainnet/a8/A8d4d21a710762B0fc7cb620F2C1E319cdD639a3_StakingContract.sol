/**
 *Submitted for verification at Arbiscan.io on 2023-11-02
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: contracts/Staking.sol


pragma solidity ^0.8.0;





contract StakingContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    // Define the structure for each staking pool

    uint256 public rewardPool = 0;
    struct StakingPool {
        uint256 lockDuration; // Lock duration in days
        uint256 minStake; // Minimum stake amount (XRAI)
        uint256 maxStake; // Maximum stake amount (XRAI)
        uint256 apy; // Annual Percentage Yield
        uint256 earlyUnstakeFee; // Early unstake fee percentage
        uint256 totalStaked; // Total amount of XRAI staked in this pool
    }

    struct UserStakingInfo {
        uint256 stakingTime; // Time user staked that amount
        uint256 amountStake; // Amount staked => to calculate rewards
        uint256 claimedReward; // When user push more to pool =>
    }
    uint256 constant dayInSecond = 86400;

    mapping(uint8 => StakingPool) public currentPools;
    // Mapping of user addresses to their stakes in each pool
    mapping(address => mapping(uint8 => UserStakingInfo)) public userStakes;

    address public XraiTokenAddress =
        0x617B76412bD9f3f80FE87d1533dc7017Defa8AD1;

    constructor(address _owner) Ownable() {
        // Initialize the staking pools
        currentPools[0] = StakingPool(
            30,
            100_000 * 10**18,
            10_000_000 * 10**18,
            30,
            5,
            0
        );
        currentPools[1] = StakingPool(
            90,
            100_000 * 10**18,
            10_000_000 * 10**18,
            90,
            5,
            0
        );
        currentPools[2] = StakingPool(
            180,
            100_000 * 10**18,
            10_000_000 * 10**18,
            150,
            5,
            0
        );
        currentPools[3] = StakingPool(
            365,
            100_000 * 10**18,
            10_000_000 * 10**18,
            300,
            5,
            0
        );
        transferOwnership(_owner);
    }

    // Function to stake XRAI tokens in a pool
    function stake(uint8 poolIndex, uint256 amount) public nonReentrant {
        require(poolIndex >= 0 && poolIndex < 4, "Invalid pool index");
        StakingPool storage pool = currentPools[poolIndex];
        require(amount >= pool.minStake, "Amount is below the minimum stake");
        require(amount <= pool.maxStake, "Amount is above the maximum stake");

        // Transfer XRAI tokens from the sender to the contract
        // (Assuming XRAI is an ERC20 token)
        require(
            IERC20(XraiTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Transfer failed"
        );
        UserStakingInfo storage userInfo = userStakes[msg.sender][poolIndex];
        uint256 reward = calculateReward(poolIndex, msg.sender);
        if (reward > 0) {
            _harvest(poolIndex, msg.sender);
        }

        // Update the user's stake and the total staked amount in the pool
        // update reward for user
        // if user staking more XRAI to a pool => update staking date to now
        // => it mean reset date they stake
        userInfo.stakingTime = block.timestamp;
        userInfo.amountStake += amount;
        pool.totalStaked += amount;
    }

    // Function to unstake XRAI tokens from a pool
    function unstake(uint8 poolIndex) public nonReentrant {
        require(poolIndex >= 0 && poolIndex < 4, "Invalid pool index");
        UserStakingInfo storage userInfo = userStakes[msg.sender][poolIndex];
        require(userInfo.amountStake > 0, "You have no stake in this pool");
        require(
            (block.timestamp - userInfo.stakingTime) / dayInSecond > 7,
            "You can't unstake in 7 days"
        );

        // Calculate the rewards based on the staking duration
        uint256 reward = 0;

        if (rewardPool > 0) {
            reward = calculateReward(poolIndex, msg.sender);
        }

        uint256 fee = 0;
        // Calculate the early unstake fee
        if (
            ((block.timestamp - userInfo.stakingTime) / dayInSecond) <
            currentPools[poolIndex].lockDuration
        ) {
            fee = userInfo
                .amountStake
                .mul(currentPools[poolIndex].earlyUnstakeFee)
                .div(100);
        }

        uint256 amountForTransfer = userInfo.amountStake - fee + reward;

        // Transfer the staked amount minus the fee and rewards back to the user
        require(
            IERC20(XraiTokenAddress).transfer(msg.sender, amountForTransfer),
            "Transfer failed"
        );

        // When have any problem with reward pool => still let user can withraw their fund without reward
        if (rewardPool >= reward) {
            rewardPool -= reward;
        }
        userInfo.amountStake = 0;
        userInfo.stakingTime = 0;
        userInfo.claimedReward = 0;
        if (currentPools[poolIndex].totalStaked >= userInfo.amountStake) {
            currentPools[poolIndex].totalStaked -= userInfo.amountStake;
        }
    }

    // Function to view the total staked amount in a pool
    function getTotalStaked(uint8 poolIndex) public view returns (uint256) {
        require(poolIndex >= 0 && poolIndex < 4, "Invalid pool index");
        return currentPools[poolIndex].totalStaked;
    }

    // Function to view user staked amount
    function getStakedAmount(uint8 poolIndex, address user)
        public
        view
        returns (uint256)
    {
        UserStakingInfo storage userInfo = userStakes[user][poolIndex];
        return userInfo.amountStake;
    }

    function calculateReward(uint8 poolIndex, address user)
        public
        view
        returns (uint256)
    {
        StakingPool storage pool = currentPools[poolIndex];
        UserStakingInfo storage userInfo = userStakes[user][poolIndex];
        if (userInfo.stakingTime == 0) return 0;
        uint256 stakedTime = (block.timestamp - userInfo.stakingTime);
        uint256 uncalReward = userInfo
            .amountStake
            .mul(stakedTime)
            .mul(pool.apy)
            .div(100)
            .div(365)
            .div(dayInSecond);
        return uncalReward - userInfo.claimedReward;
    }

    function _harvest(uint8 poolIndex, address user) internal returns (bool) {
        uint256 reward = calculateReward(poolIndex, user);
        if (reward > 0 && rewardPool >= reward) {
            require(
                IERC20(XraiTokenAddress).transfer(msg.sender, reward),
                "Transfer failed"
            );
            UserStakingInfo storage userInfo = userStakes[user][poolIndex];
            userInfo.claimedReward += reward;
            rewardPool -= reward;
        }
        return true;
    }

    function harvest(uint8 poolIndex, address user) external nonReentrant {
        require(_harvest(poolIndex, user), "harvest faileds");
    }

    function ownerDepositReward(uint256 amount) external onlyOwner {
        require(
            IERC20(XraiTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Transfer failed"
        );
        rewardPool += amount;
    }

    function ownerWithdrawRewardPool() external onlyOwner nonReentrant {
        require(
            IERC20(XraiTokenAddress).transferFrom(
                msg.sender,
                address(this),
                rewardPool
            ),
            "Transfer failed"
        );
        rewardPool = 0;
    }

    function updateXraiContractAddress(address _xraiAddress)
        external
        onlyOwner
    {
        XraiTokenAddress = _xraiAddress;
    }

    function updatePoolConfiguation(
        uint8 poolIndex,
        StakingPool memory _stakingPool
    ) external onlyOwner {
        StakingPool storage pool = currentPools[poolIndex];
        pool.lockDuration = _stakingPool.lockDuration;
        pool.minStake = _stakingPool.minStake;
        pool.maxStake = _stakingPool.maxStake;
        pool.apy = _stakingPool.apy;
        pool.earlyUnstakeFee = _stakingPool.earlyUnstakeFee;
        pool.totalStaked = _stakingPool.totalStaked;
    }
}