// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IStakingRewards} from "./interfaces/IStakingRewards.sol";

contract StakingRewardsRegistry is Ownable2Step {
    /* ========== STATE VARIABLES ========== */

    /// @notice If a stakingPool exists for a given token, it will be shown here.
    /// @dev Only stakingPools added to this registry will be shown.
    mapping(address => address) public stakingPool;

    /// @notice Tokens that this registry has added stakingPools for.
    address[] public tokens;

    /// @notice Check if a given stakingPool is known to this registry.
    mapping(address => bool) public isStakingPoolEndorsed;

    /// @notice Check if an address is allowed to own stakingPools from this registry.
    mapping(address => bool) public approvedPoolOwner;

    /// @notice Check if an address can add pools to this registry.
    mapping(address => bool) public poolEndorsers;

    /// @notice Staking pools that have been replaced by a newer version.
    address[] public replacedStakingPools;

    /// @notice Default StakingRewardsMulti contract to clone.
    address public stakingContract;

    /// @notice Default zap contract.
    address public zapContract;

    /* ========== EVENTS ========== */

    event StakingPoolAdded(address indexed token, address stakingPool);
    event ApprovedPoolOwnerUpdated(address governance, bool approved);
    event ApprovedPoolEndorser(address account, bool canEndorse);
    event DefaultContractsUpdated(address stakingContract, address zapContract);

    /* ========== VIEWS ========== */

    /// @notice The number of tokens with staking pools added to this registry.
    function numTokens() external view returns (uint256) {
        return tokens.length;
    }

    /* ========== CORE FUNCTIONS ========== */

    /**
     @notice Used for owner to clone an exact copy of the default staking pool and add to registry.
     @dev Also uses the default zap contract.
     @param _stakingToken Address of our staking token to use.
     @return newStakingPool Address of our new staking pool.
    */
    function cloneAndAddStakingPool(
        address _stakingToken
    ) external returns (address newStakingPool) {
        // don't let just anyone add to our registry
        require(poolEndorsers[msg.sender], "!authorized");

        // Clone new pool.
        newStakingPool = IStakingRewards(stakingContract).cloneStakingPool(
            owner(),
            _stakingToken,
            zapContract
        );

        bool tokenIsRegistered = stakingPool[_stakingToken] != address(0);

        // Add to the registry.
        _addStakingPool(newStakingPool, _stakingToken, tokenIsRegistered);
    }

    /**
    @notice
        Add a new staking pool to our registry, for new or existing tokens.
    @dev
        Throws if governance isn't set properly.
        Throws if sender isn't allowed to endorse.
        Throws if replacement is handled improperly.
        Emits a StakingPoolAdded event.
    @param _stakingPool The address of the new staking pool.
    @param _token The token to be deposited into the new staking pool.
    @param _replaceExistingPool If we are replacing an existing staking pool, set this to true.
     */
    function addStakingPool(
        address _stakingPool,
        address _token,
        bool _replaceExistingPool
    ) external {
        // don't let just anyone add to our registry
        require(poolEndorsers[msg.sender], "!authorized");
        _addStakingPool(_stakingPool, _token, _replaceExistingPool);
    }

    function _addStakingPool(
        address _stakingPool,
        address _token,
        bool _replaceExistingPool
    ) internal {
        // load up the staking pool contract
        IStakingRewards stakingRewards = IStakingRewards(_stakingPool);

        // check that gov is correct on the staking contract
        require(
            approvedPoolOwner[stakingRewards.owner()],
            "not allowed pool owner"
        );

        // make sure we didn't mess up our token/staking pool match
        require(
            stakingRewards.stakingToken() == _token,
            "staking token doesn't match"
        );

        // Make sure we're only using the latest stakingPool in our registry
        if (_replaceExistingPool) {
            require(
                stakingPool[_token] != address(0),
                "token isn't registered, can't replace"
            );
            address oldPool = stakingPool[_token];
            isStakingPoolEndorsed[oldPool] = false;
            stakingPool[_token] = _stakingPool;

            // move our old pool to the replaced list
            replacedStakingPools.push(oldPool);
        } else {
            require(
                stakingPool[_token] == address(0),
                "replace instead, pool already exists"
            );
            stakingPool[_token] = _stakingPool;
            tokens.push(_token);
        }

        isStakingPoolEndorsed[_stakingPool] = true;
        emit StakingPoolAdded(_token, _stakingPool);
    }

    /* ========== SETTERS ========== */

    /**
    @notice Set the ability of an address to endorse staking pools.
    @dev Throws if caller is not owner.
    @param _addr The address to approve or deny access.
    @param _approved Allowed to endorse
     */
    function setPoolEndorsers(
        address _addr,
        bool _approved
    ) external onlyOwner {
        poolEndorsers[_addr] = _approved;
        emit ApprovedPoolEndorser(_addr, _approved);
    }

    /**
    @notice Set the staking pool owners.
    @dev Throws if caller is not owner.
    @param _addr The address to approve or deny access.
    @param _approved Allowed to own staking pools
     */
    function setApprovedPoolOwner(
        address _addr,
        bool _approved
    ) external onlyOwner {
        approvedPoolOwner[_addr] = _approved;
        emit ApprovedPoolOwnerUpdated(_addr, _approved);
    }

    /**
    @notice Set our default zap and staking pool contracts.
    @dev Throws if caller is not owner, and can't be set to zero address.
    @param _stakingPool Address of the default staking contract to use.
    @param _zapContract Address of the default zap contract to use.
     */
    function setDefaultContracts(
        address _stakingPool,
        address _zapContract
    ) external onlyOwner {
        require(
            _stakingPool != address(0) && _zapContract != address(0),
            "no zero address"
        );
        stakingContract = _stakingPool;
        zapContract = _zapContract;
        emit DefaultContractsUpdated(_stakingPool, _zapContract);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

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
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

interface IStakingRewards {
    /* ========== VIEWS ========== */

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardsDistribution() external view returns (address);

    function rewardsToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function owner() external view returns (address);

    function stakingToken() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external;

    function stakeFor(address user, uint256 amount) external;

    function getReward() external;

    function withdraw(uint256 amount) external;

    function withdrawFor(address user, uint256 amount, bool exit) external;

    function exit() external;

    function cloneStakingPool(
        address _owner,
        address _stakingToken,
        address _zapContract
    ) external returns (address newStakingPool);
}

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