/**
 *Submitted for verification at Arbiscan on 2023-04-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface ICamelotPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent);
    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);
    function kLast() external view returns (uint);

    function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address referrer) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


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


pragma solidity ^0.8.4;

contract GenericStaking is Ownable{

    IERC20 public rewardToken; // Token to be payed as reward
    ICamelotPair public stakeToken; // Token to be staked

    //uint256 private rewardTokensPerBlock; // Number of reward tokens minted per block
    uint256 private constant STAKER_SHARE_PRECISION = 1e18; // A big number to perform mul and div operations

    // Staking user for a pool
    struct PoolStaker {
        uint256 amount; // The tokens quantity the user has staked.
        uint256 rewards; // The reward tokens quantity the user can harvest
    }

    uint256 public tokensStaked; // Total tokens staked
    uint256 public lastTokensToReward; // Last amount of tokens that have been added to the pool to give out as rewards

    address[] public s_stakers; // Stakers in this pool

    // Mapping staker address => PoolStaker
    mapping(address => PoolStaker) public poolStakers;

    // Events
    event RewardsAdded(uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event HarvestRewards(address indexed user, uint256 amount);
    event PoolCreated(address indexed stakeToken);

    // Constructor
    constructor(address _rewardToken, address _stakeToken) {
        rewardToken = IERC20(_rewardToken);
        createPool(ICamelotPair(_stakeToken));
    }

    /**
     * @dev Create a new staking pool
     */
    function createPool(ICamelotPair _stakeToken) private {
        stakeToken =  _stakeToken;
        emit PoolCreated(address(_stakeToken));
    }

    /**
     * @dev Add staker address to the pool stakers if it's not there already
     * We don't have to remove it because if it has amount 0 it won't affect rewards.
     * (but it might save gas in the long run)
     */
    function addStakerToPoolIfInexistent(address depositingStaker) private {
        address[] memory stakers = s_stakers;
        for (uint256 i; i < stakers.length; i++) {
            address existingStaker = stakers[i];
            if (existingStaker == depositingStaker) return;
        }
        s_stakers.push(msg.sender);
    }

    /**
     * @dev Deposit tokens to an existing pool
     */
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Deposit amount can't be zero");
        PoolStaker storage staker = poolStakers[msg.sender];

        // Update pool stakers
        updateStakersRewards();
        addStakerToPoolIfInexistent(msg.sender);

        // Update current staker
        staker.amount = staker.amount + _amount;

        // Update pool
        tokensStaked = tokensStaked + _amount;

        // Deposit tokens
        emit Deposit(msg.sender, _amount);
        stakeToken.transferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
    }

    /**
     * @dev Withdraw all tokens from an existing pool
     */
    function withdraw() external {
        PoolStaker storage staker = poolStakers[msg.sender];
        uint256 amount = staker.amount;
        require(amount > 0, "Withdraw amount can't be zero");

        // Update pool stakers
        updateStakersRewards();

        // Pay rewards
        harvestRewards();

        // Update staker
        staker.amount = 0;

        // Update pool
        tokensStaked = tokensStaked - amount;

        // Withdraw tokens
        emit Withdraw(msg.sender, amount);
        stakeToken.transfer(      
            address(msg.sender),
            amount
        );
    }

    /**
     * @dev Harvest user reward
     */
    function harvestRewards() public {
        updateStakersRewards();
        PoolStaker storage staker = poolStakers[msg.sender];
        uint256 rewardsToHarvest = staker.rewards;
        staker.rewards = 0;
        lastTokensToReward = lastTokensToReward - rewardsToHarvest;
        emit HarvestRewards(msg.sender, rewardsToHarvest);
        rewardToken.transfer(msg.sender, rewardsToHarvest);
    }

    /**
     * @dev Loops over all stakers from a pool, updating their accumulated rewards according
     * to their participation in the pool.
     */
    function updateStakersRewards() private {
        address[] memory stakers = s_stakers;
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 addedTokens = balance - lastTokensToReward;

        for (uint256 i; i < stakers.length; i++) {
            address stakerAddress = stakers[i];
            PoolStaker storage staker = poolStakers[stakerAddress];
            if (staker.amount > 0){
                uint256 stakedAmount = staker.amount;
                uint256 stakerShare = (stakedAmount * STAKER_SHARE_PRECISION / tokensStaked);
                uint256 rewards = (addedTokens * stakerShare) / STAKER_SHARE_PRECISION;
                staker.rewards = staker.rewards + rewards;
            }
        }
        lastTokensToReward = balance;
    }

    /**
     * @dev Pending user rewards
     */
    function pendingRewards(address stakerAddress) external view returns (uint256) {
        PoolStaker memory staker = poolStakers[stakerAddress];
        if (staker.amount == 0) return 0;
        uint256 stakedAmount = staker.amount;
        uint256 stakerShare = (stakedAmount * STAKER_SHARE_PRECISION / tokensStaked);
        uint256 addedTokens = IERC20(rewardToken).balanceOf(address(this)) - lastTokensToReward;
        uint256 rewards = (addedTokens * stakerShare) / STAKER_SHARE_PRECISION;
        return staker.rewards + rewards;
    }
}