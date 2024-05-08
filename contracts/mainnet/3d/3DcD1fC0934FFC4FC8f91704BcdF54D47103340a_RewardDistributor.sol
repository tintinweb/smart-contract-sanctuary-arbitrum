/**
 *Submitted for verification at Arbiscan.io on 2024-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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
abstract contract DoubleOwnable is Context {
    address public firstOwner;
    address public secondOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _secondOwner) {
        _setFirstOwner(_msgSender());
        _setSecondOwner(_secondOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(firstOwner == _msgSender() || secondOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceFirstOwnership() public virtual onlyOwner {
        _setFirstOwner(address(0));
    }

    function renounceSecondOwnership() public virtual onlyOwner {
        _setSecondOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        if (_msgSender() == firstOwner) {
            _setFirstOwner(newOwner);
        } else {
            _setSecondOwner(newOwner);
        }
    }

    function _setFirstOwner(address newOwner) private {
        address oldOwner = firstOwner;
        firstOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setSecondOwner(address newOwner) private {
        address oldOwner = secondOwner;
        secondOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @title IRewardDistributor
/// @author Turbo Fifty
/// @notice A reward distributor allows for setting allocation
interface IRewardDistributor {
    function setAllocation(address holder, uint256 amount) external returns (bool);
}

/**
 * Reward Distributor without the distribution criteria
 */
contract RewardDistributor is IRewardDistributor, DoubleOwnable {
    address public _token;
    IERC20 public RewardToken;

    struct Allocation {
        uint256 amount; // how many allocations does this holder have
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 userRealised; // how much a user has claimed
        uint256 adminRealised; // how much an admin has claimed in case of emergency (e.g. forgotten secret phrase)
    }

    address[] public holders;
    mapping(address => uint256) public holderIndexes;
    mapping(address => uint256) public holderClaims;
    mapping(address => Allocation) public allocations;

    uint256 public totalAllocations;
    uint256 public totalRewards;
    uint256 public totalDistributed;
    uint256 public rewardsPerAllocation;
    uint256 public rewardsPerAllocationAccuracyFactor = 10 ** 36;

    uint256 public currentIndex;
    bool public initialized;

    bool public claimEnabled = true;

    // Events
    event DepositedRewards(uint256 indexed amount);
    event RewardDistributed(address indexed account, uint256 indexed amount);
    event AllocationSet(address indexed holder, uint256 indexed amount);

    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(_msgSender() == _token);
        _;
    }

    constructor(
        // address _reflectionToken, 
        address token, 
        address _secondOwner) 
        DoubleOwnable(_secondOwner) {
        // RewardToken = IERC20(_reflectionToken);
        RewardToken = IERC20(0xaF22d8FeF9ECf1394bE9f7b38e828fd735778E18); // SEIF
        _token = token;
    }

    function setAllocation(address holder, uint256 amount) external override onlyToken returns (bool) {
        if (allocations[holder].amount > 0) {
            distributeRewards(holder);
        }

        if (amount > 0 && allocations[holder].amount == 0) {
            addHolder(holder);
        } else if (amount == 0 && allocations[holder].amount > 0) {
            removeHolder(holder);
        }

        totalAllocations = totalAllocations - allocations[holder].amount + amount;
        allocations[holder].amount = amount;
        allocations[holder].totalExcluded = getCumulativeRewards(allocations[holder].amount);
        emit AllocationSet(holder, amount);
        return true;
    }

    function deposit(uint256 amountToDeposit) external returns (bool) {
        require(amountToDeposit <= RewardToken.balanceOf(msg.sender), "not enough balance");
        totalRewards += amountToDeposit;
        rewardsPerAllocation = rewardsPerAllocation + ((rewardsPerAllocationAccuracyFactor * amountToDeposit) / totalAllocations);
        bool success = RewardToken.transferFrom(msg.sender, address(this), amountToDeposit);
        require(success, "deposit failed");
        emit DepositedRewards(amountToDeposit);
        return true;
    }

    function distributeRewards(address holder) public returns (bool) {
        if (allocations[holder].amount == 0) {
            return false;
        }

        uint256 amount = getUnpaidRewards(holder);
        if (amount > 0) {
            totalDistributed += amount;
            holderClaims[holder] = block.timestamp;
            allocations[holder].totalRealised += amount;
            allocations[holder].userRealised += amount;
            allocations[holder].totalExcluded = getCumulativeRewards(allocations[holder].amount);
            bool success = RewardToken.transfer(holder, amount);
            require(success, "transfer failed");
            emit RewardDistributed(holder, amount);
            return true;
        }
        return false;
    }

    function claimRewards() external {
        require(claimEnabled, "Claim is not enabled");
        bool success = distributeRewards(_msgSender());
        require(success, "distribute failed");
    }

    function emergencyAdminClaim(address holder) external onlyOwner {
        uint256 amount = getUnpaidRewards(holder);
        if (amount > 0) {
            totalDistributed += amount;
            holderClaims[holder] = block.timestamp;
            allocations[holder].totalRealised += amount;
            allocations[holder].adminRealised += amount;
            allocations[holder].totalExcluded = getCumulativeRewards(allocations[holder].amount);
            RewardToken.transfer(msg.sender, amount);
        }
    }

    function getUnpaidRewards(address holder) public view returns (uint256) {
        if (allocations[holder].amount == 0) {
            return 0;
        }

        uint256 holderTotalRewards = getCumulativeRewards(allocations[holder].amount);
        uint256 holderTotalExcluded = allocations[holder].totalExcluded;

        if (holderTotalRewards <= holderTotalExcluded) {
            return 0;
        }

        return (holderTotalRewards - holderTotalExcluded);
    }

    function getCumulativeRewards(uint256 allocation) internal view returns (uint256) {
        return (allocation * rewardsPerAllocation) / rewardsPerAllocationAccuracyFactor;
    }

    function addHolder(address holder) internal {
        holderIndexes[holder] = holders.length;
        holders.push(holder);
    }

    function removeHolder(address holder) internal {
        holders[holderIndexes[holder]] = holders[holders.length - 1];
        holderIndexes[holders[holders.length - 1]] = holderIndexes[holder];
        holders.pop();
    }

    function setClaimEnabled(bool newState) external onlyOwner {
        claimEnabled = newState;
    }
}