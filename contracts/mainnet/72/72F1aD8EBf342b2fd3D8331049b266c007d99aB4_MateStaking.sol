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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MateStaking is Ownable, ReentrancyGuard {

    enum LockType {
        LOCK_1D,
        LOCK_3D,
        LOCK_5D,
        LOCK_7D,
        LOCK_14D
    }

    IERC20 public immutable stakingToken;
    IMateRewards public rewardsContract;

    bool public open = false;
    
    mapping(address => uint256) public stakeNonce;
    mapping(address => mapping(uint256 => UserStake)) public stakes;

    mapping(uint256 => StakeType) public stakeTypes;

    struct UserStake {
        uint256 amount;
        uint64 unlocksAt;
        uint8 lockMulti;
        bool claimed;
    }

    struct StakeType {
        uint64 lockDuration;
        uint8 lockMulti;
    }

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);

        stakeTypes[uint(LockType.LOCK_1D)] = StakeType(1 days, 1);
        stakeTypes[uint(LockType.LOCK_3D)] = StakeType(3 days, 2);
        stakeTypes[uint(LockType.LOCK_5D)] = StakeType(5 days, 3);
        stakeTypes[uint(LockType.LOCK_7D)] = StakeType(7 days, 4);
        stakeTypes[uint(LockType.LOCK_14D)] = StakeType(14 days, 5);
    }

    function setRewardsContract(address _rewardsContract) external onlyOwner {
        require(_rewardsContract != address(0), "Invalid address");
        require(address(rewardsContract) == address(0), "Already set");
        
        rewardsContract = IMateRewards(_rewardsContract);
    }

    function stake(uint256 amount, LockType lockType) external nonReentrant {
        require(open || msg.sender == owner(), "Staking is not open");
        StakeType memory stakeType = stakeTypes[uint(lockType)];

        require(amount > 0, "Cannot stake 0");
        require(stakeType.lockDuration > 0, "Invalid lock type");

        require(amount <= 256, "Sorry ;)");

        stakingToken.transferFrom(msg.sender, address(this), amount);

        uint256 rewardRate = amount * stakeType.lockMulti;
        uint256 nonce = stakeNonce[msg.sender];

        stakeNonce[msg.sender] = nonce + 1;

        stakes[msg.sender][nonce] = UserStake({
            amount: amount,
            unlocksAt: uint64(block.timestamp + stakeType.lockDuration),
            lockMulti: stakeType.lockMulti,
            claimed: false
        });

        rewardsContract.stake(rewardRate, msg.sender);
    }

    function withdraw(uint256 nonce) external nonReentrant {
        UserStake storage userStake = stakes[msg.sender][nonce];

        require(userStake.amount > 0, "No stake found");
        require(!userStake.claimed, "Stake already claimed");
        require(userStake.unlocksAt < block.timestamp, "Stake is still locked");

        userStake.claimed = true;

        uint256 rewardRate = userStake.amount * userStake.lockMulti;

        stakingToken.transfer(msg.sender, userStake.amount);
        rewardsContract.withdraw(rewardRate, msg.sender);
    }

    function claimRewardTokens() external {
        rewardsContract.getReward(msg.sender);
    }

    function claimable(address wallet) external view returns (uint) {
        return rewardsContract.claimable(wallet);
    }

    function getUserStakes(uint256 from, uint256 to, address wallet) public view returns (UserStake[] memory) {
        UserStake[] memory userStakes = new UserStake[](to - from);

        for(uint256 i = from; i < to; i++) {
            userStakes[i - from] = stakes[wallet][i];
        }

        return userStakes;
    }

    function setOpen(bool _open) external onlyOwner {
        open = _open;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot recover staking token");
        
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

interface IMateRewards {
    function stake(uint _amount, address wallet) external;
    function withdraw(uint _amount, address wallet) external;
    function getReward(address wallet) external;
    function claimable(address wallet) external view returns (uint);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}