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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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
pragma solidity =0.8.18;

uint8 constant ROLE_SETTER = 1;
uint8 constant ROLE_FUND_RECIPIENT = 2;

interface IAuthorizer {
    event Initialized();
    event SetAuthority(
        address indexed authority,
        uint8 role,
        address sender,
        bool isAuthority
    );

    function setAuthority(address _authority, uint8 role) external;

    function removeAuthority(address _authority, uint8 role) external;
}

interface IAuthorizerGetter {
    function isAuthorized(
        address candidate,
        uint8 role
    ) external view returns (bool);

    function isAuthorizedSetter(address candidate) external view returns (bool);

    function isAuthorizedRecipient(
        address candidate
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

struct RewardInfo {
    uint256 startBlock;
    uint256 bonusEndBlock;
    uint256 poolLimitPerUser;
    uint16 rewardWeight;
}

interface IRewardGetter {
    function rewardOf(address pair) external view returns (RewardInfo memory);

    function rewardStartBlock(address pair) external view returns (uint256);

    function rewardBonusEndBlock(address pair) external view returns (uint256);

    function rewardPerBlock(address pair) external view returns (uint256);

    function rewardPoolLimitPerUser(
        address pair
    ) external view returns (uint256);
}

interface IRewardSetter {
    event Initialized(address controller);
    event NewTotalRewardPerBlock(uint256 rewardWeight, address indexed sender);
    event NewStartAndEndBlocks(
        address indexed pool,
        uint256 startBlock,
        uint256 bonusEndBlock,
        address indexed sender
    );
    event NewLimitPerUser(
        address indexed pool,
        uint256 limitPerUser,
        address indexed sender
    );
    event NewRewardWeight(
        address indexed pool,
        uint16 rewardWeight,
        address indexed sender
    );

    function updateTotalRewardPerBlock(uint256 newRewardPerBlock) external;

    function updateStartAndEndBlocks(
        address pool,
        uint256 startBlock,
        uint256 bonusEndBlock
    ) external;

    function updateLimitPerUser(address pool, uint256 limitPerUser) external;

    function updateRewardWeight(address pool, uint16 rewardWeight) external;
}

interface IRewardCallback {
    function notifyRewardStartAndEndBlockChanged(address pool) external;

    function notifyRewardPerBlockWillChange(address pool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IReward.sol";
import "./interfaces/IAuthorizer.sol";

contract Reward is IRewardSetter, IRewardGetter, Ownable2Step, ReentrancyGuard {
    address public controller;
    uint256 public totalRewardPerBlock = 0;

    uint16 public constant REWARD_WEIGHT_DENOMINATOR = 10000;
    uint16 totalWeight = 0;

    bool public isInitialized;

    mapping(address => RewardInfo) public rewards;

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlySetter() {
        address sender = _msgSender();
        require(
            IAuthorizerGetter(controller).isAuthorizedSetter(sender),
            "REWARD: unauthorized"
        );
        _;
    }

    modifier initialized() {
        require(isInitialized, "REWARD: contract not initialized");
        _;
    }

    function initialize(address _controller) external onlyOwner {
        require(
            address(_controller) != address(0),
            "REWARD: controller cannot be zero address"
        );

        controller = _controller;

        isInitialized = true;

        emit Initialized(_controller);
    }

    // IRewardSetter implementation

    function updateTotalRewardPerBlock(
        uint256 newRewardPerBlock
    ) external initialized onlySetter nonReentrant {
        totalRewardPerBlock = newRewardPerBlock;

        emit NewTotalRewardPerBlock(newRewardPerBlock, _msgSender());
    }

    function updateStartAndEndBlocks(
        address pool,
        uint256 startBlock,
        uint256 bonusEndBlock
    ) external initialized onlySetter nonReentrant {
        RewardInfo storage _rewardInfo = rewards[pool];
        require(
            _rewardInfo.startBlock == 0 ||
                block.number < _rewardInfo.startBlock,
            "REWARD: pool has started"
        );
        require(
            startBlock < bonusEndBlock,
            "REWARD: new startBlock must be lower than new endBlock"
        );
        require(
            block.number < startBlock,
            "REWARD: new startBlock must be higher than current block"
        );

        _rewardInfo.startBlock = startBlock;
        _rewardInfo.bonusEndBlock = bonusEndBlock;
        rewards[pool] = _rewardInfo;

        IRewardCallback(controller).notifyRewardStartAndEndBlockChanged(pool);

        emit NewStartAndEndBlocks(
            pool,
            startBlock,
            bonusEndBlock,
            _msgSender()
        );
    }

    function updateLimitPerUser(
        address pool,
        uint256 poolLimitPerUser
    ) external initialized onlySetter nonReentrant {
        RewardInfo storage _rewardInfo = rewards[pool];
        require(
            poolLimitPerUser != _rewardInfo.poolLimitPerUser,
            "REWARD: new poolLimitPerUser should be different"
        );
        require(
            poolLimitPerUser == 0 ||
                poolLimitPerUser > _rewardInfo.poolLimitPerUser,
            "REWARD: New limit must be higher"
        );

        _rewardInfo.poolLimitPerUser = poolLimitPerUser;
        rewards[pool] = _rewardInfo;

        emit NewLimitPerUser(pool, poolLimitPerUser, _msgSender());
    }

    function updateRewardWeight(
        address pool,
        uint16 newWeight
    ) external initialized onlySetter nonReentrant {
        RewardInfo storage _rewardInfo = rewards[pool];
        require(
            newWeight != _rewardInfo.rewardWeight,
            "REWARD: new weight should be different"
        );

        totalWeight = totalWeight - _rewardInfo.rewardWeight + newWeight;
        require(
            totalWeight <= REWARD_WEIGHT_DENOMINATOR,
            "REWARD: total weight is too high"
        );

        IRewardCallback(controller).notifyRewardPerBlockWillChange(pool);

        _rewardInfo.rewardWeight = newWeight;
        rewards[pool] = _rewardInfo;

        emit NewRewardWeight(pool, newWeight, _msgSender());
    }

    /// IRewardGetter implementation

    function rewardOf(address pool) external view returns (RewardInfo memory) {
        return rewards[pool];
    }

    function rewardStartBlock(address pool) external view returns (uint256) {
        return rewards[pool].startBlock;
    }

    function rewardBonusEndBlock(address pool) external view returns (uint256) {
        return rewards[pool].bonusEndBlock;
    }

    function rewardPerBlock(address pool) external view returns (uint256) {
        RewardInfo storage _rewardInfo = rewards[pool];
        if (_rewardInfo.rewardWeight == 0) {
            return 0;
        }
        uint256 _rewardAllocation = (_rewardInfo.rewardWeight *
            totalRewardPerBlock) / REWARD_WEIGHT_DENOMINATOR;
        return
            _rewardAllocation /
            (_rewardInfo.bonusEndBlock - _rewardInfo.startBlock);
    }

    function rewardPoolLimitPerUser(
        address pool
    ) external view returns (uint256) {
        return rewards[pool].poolLimitPerUser;
    }
}