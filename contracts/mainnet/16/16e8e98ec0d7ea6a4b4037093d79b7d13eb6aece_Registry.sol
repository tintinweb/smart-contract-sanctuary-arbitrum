// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IRegistry } from "src/interfaces/pool/IRegistry.sol";
import { IPool } from "src/interfaces/pool/IPool.sol";

import { Error } from "src/librairies/Error.sol";

import { EnumerableSet } from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { Ownable, Ownable2Step } from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract Registry is Ownable2Step, IRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice EnumerableSet where all the approved pools are stored
    EnumerableSet.AddressSet private pools;
    /**
     * @notice EnumerableSet where all the pending pools are stored
     * These pools can be either approved or rejected by the owner
     */
    EnumerableSet.AddressSet private pendingPools;

    /// @notice the address of the PoolFactory
    address public factory;

    /*///////////////////////////////////////////////////////////////
                        	CONSTRUCTOR
    ///////////////////////////////////////////////////////////////*/

    constructor(address _owner) Ownable(_owner) { }

    /*///////////////////////////////////////////////////////////////
                        VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRegistry
    function getPoolAt(uint256 _index, bool isPending) external view returns (address) {
        return isPending ? pendingPools.at(_index) : pools.at(_index);
    }

    /// @inheritdoc IRegistry
    function getPoolCount(bool isPending) external view returns (uint256) {
        return isPending ? pendingPools.length() : pools.length();
    }

    /// @inheritdoc IRegistry
    function hasPool(address _pool, bool isPending) external view returns (bool) {
        return isPending ? pendingPools.contains(_pool) : pools.contains(_pool);
    }

    /*///////////////////////////////////////////////////////////////
                            SETTERS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRegistry
    function setFactory(address _newFactory) external onlyOwner {
        _setFactory(_newFactory);
    }

    /*///////////////////////////////////////////////////////////////
                        MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRegistry
    function registerPool(address _newPool) external onlyFactory {
        if (_newPool == address(0)) revert Error.ZeroAddress();
        if (!pendingPools.add(_newPool)) revert Error.AddFailed();
        emit PoolPending(_newPool);
    }

    /// @inheritdoc IRegistry
    function approvePool(address _pool) external onlyOwner {
        if (!pools.add(_pool)) revert Error.AddFailed();
        if (!pendingPools.remove(_pool)) revert Error.RemoveFailed();
        emit PoolApproved(_pool);
        IPool(_pool).approvePool();
    }

    /// @inheritdoc IRegistry
    function rejectPool(address _pool) external onlyOwner {
        if (!pendingPools.remove(_pool)) revert Error.RemoveFailed();
        emit PoolRejected(_pool);
        IPool(_pool).rejectPool();
    }

    /// @inheritdoc IRegistry
    function removePool(address _pool) external onlyOwner {
        if (!pools.remove(_pool)) revert Error.RemoveFailed();
        emit PoolRemoved(_pool);
    }

    /*///////////////////////////////////////////////////////////////
    								INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifies the factory address
     * @param _newFactory The new factory address
     */
    function _setFactory(address _newFactory) internal {
        if (_newFactory == address(0)) revert Error.ZeroAddress();
        emit FactorySet(factory, _newFactory);
        factory = _newFactory;
    }

    /*///////////////////////////////////////////////////////////////
    									MODIFIERS
    ///////////////////////////////////////////////////////////////*/

    modifier onlyFactory() {
        if (msg.sender != factory) revert Error.Unauthorized();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRegistry {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event FactorySet(address indexed oldFactory, address indexed newFactory);

    event PoolApproved(address indexed pool);

    event PoolPending(address indexed pool);

    event PoolRejected(address indexed pool);

    event PoolRemoved(address indexed pool);

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the address of a pool located at _index
     *  @param _index The index of a pool stored in the EnumerableSet
     *  @param _isPending True if looking into the pending pools, false for the approved ones
     * @return The address of a pool
     */
    function getPoolAt(uint256 _index, bool _isPending) external view returns (address);

    /**
     * @notice Returns the total number of pools
     * @param _isPending True if looking into the pending pools, false for the approved ones
     * @return The total number of pools
     */
    function getPoolCount(bool _isPending) external view returns (uint256);

    /**
     * @notice Checks if an address is stored in the pools set
     * @param _pool The address of a pool
     * @param _isPending True if looking into the pending pools, false for the approved ones
     * @return True if the pool has been found, false otherwise
     */
    function hasPool(address _pool, bool _isPending) external view returns (bool);

    /*///////////////////////////////////////////////////////////////
                                SETTERS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Modifies the factory address
     * @param _newFactory The new factory address
     */
    function setFactory(address _newFactory) external;

    /*///////////////////////////////////////////////////////////////
                            MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Registers a new pool in the pending queue
     * @param _newPool The address of a pool
     */
    function registerPool(address _newPool) external;

    /**
     * @notice Approves a pool from the pending queue
     * @param _pool The address of a pool
     */
    function approvePool(address _pool) external;

    /**
     * @notice Rejects a pool from the pending queue
     * @param _pool The address of a pool
     */
    function rejectPool(address _pool) external;

    /**
     * @notice Removes a pool from the approved pool Set
     * @param _pool The address of a pool
     */
    function removePool(address _pool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IPool {
    /*///////////////////////////////////////////////////////////////
                            STRUCTS/ENUMS
    ///////////////////////////////////////////////////////////////*/

    enum Status {
        Uninitialized,
        Created,
        Approved,
        Rejected,
        Seeding,
        Locked,
        Unlocked
    }

    struct StakingSchedule {
        /// @notice The timestamp when the seeding period starts.
        uint256 seedingStart;
        /// @notice The duration of the seeding period.
        uint256 seedingPeriod;
        /// @notice The timestamp when the locked period starts.
        uint256 lockedStart;
        /// @notice The duration of the lock period, which is also the duration of rewards.
        uint256 lockPeriod;
        /// @notice The timestamp when the rewards period ends.
        uint256 periodFinish;
    }

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    ///////////////////////////////////////////////////////////////*/

    error StakeLimitMismatch();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    ///////////////////////////////////////////////////////////////*/

    event PoolInitialized(
        address indexed token,
        address indexed creator,
        uint256 seedingPeriod,
        uint256 lockPeriod,
        uint256 amount,
        uint256 fee,
        uint256 maxStakePerAddress,
        uint256 maxStakePerPool
    );

    event PoolApproved();

    event PoolRejected();

    event PoolStarted(uint256 seedingStart, uint256 periodFinish);

    event RewardsRetrieved(address indexed creator, uint256 amount);

    event Staked(address indexed account, uint256 amount);

    event Unstaked(address indexed account, uint256 amount);

    event RewardPaid(address indexed account, uint256 amount);

    event ProtocolFeePaid(address indexed treasury, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                            INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes a new staking pool
     * @param _creator The address of pool creator
     * @param _treasury The address of the treasury where the rewards will be distributed
     * @param _token The address of the token to be staked
     * @param _seedingPeriod The period in seconds during which users are able to stake
     * @param _lockPeriod The period in seconds during which the staked tokens are locked
     * @param _maxStakePerAddress The maximum amount of tokens that can be staked by a single address
     * @param _protocolFeeBps The fee charged by the protocol for each pool in bps
     * @param _maxStakePerPool The maximum amount of tokens that can be staked in the pool
     */
    function initialize(
        address _creator,
        address _treasury,
        address _token,
        uint256 _seedingPeriod,
        uint256 _lockPeriod,
        uint256 _maxStakePerAddress,
        uint256 _protocolFeeBps,
        uint256 _maxStakePerPool
    ) external;

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the registry this pool is setup with
     */
    function registry() external view returns (address);

    /**
     * @notice Returns the current operational status of the pool.
     * @return The current status of the pool.
     */
    function status() external view returns (Status);

    /**
     * @notice Returns the earned rewards of a specific account
     * @param account The address of the account
     * @return The amount of rewards earned by the account
     */
    function earned(address account) external view returns (uint256);

    /**
     * @notice Calculates the rewards per token for the current time.
     * @dev The total amount of rewards available in the system is fixed, and it needs to be distributed among the users
     * based on their token balances and the lock duration.
     * Rewards per token represent the amount of rewards that each token is entitled to receive at the current time.
     * The calculation takes into account the reward rate (rewardAmount / lockPeriod), the time duration since the last
     * update,
     * and the total supply of tokens in the pool.
     * @return The updated rewards per token value for the current block.
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @notice Get the last time where rewards are applicable.
     * @return The last time where rewards are applicable.
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @notice Get the token used in the pool
     * @return The ERC20 token used in the pool
     */
    function token() external view returns (IERC20);

    /*///////////////////////////////////////////////////////////////
    					MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice Approves the pool to start accepting stakes
    function approvePool() external;

    /// @notice Rejects the pool
    function rejectPool() external;

    /// @notice Retrieves the reward tokens from the pool if the pool is rejected
    function retrieveRewardToken() external;

    /// @notice Starts the seeding period for the pool, during which deposits are accepted
    function start() external;

    /**
     * @notice Stakes a certain amount of tokens
     * @param _amount The amount of tokens to stake
     */
    function stake(uint256 _amount) external;

    /**
     * @notice Stakes a certain amount of tokens for a specified address
     * @param _staker The address for which the tokens are being staked
     * @param _amount The amount of tokens to stake
     */
    function stakeFor(address _staker, uint256 _amount) external;

    /**
     * @notice Unstakes all staked tokens
     */
    function unstakeAll() external;

    /**
     * @notice Claims the earned rewards
     */
    function claim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Error {
    error AlreadyInitialized();
    error ZeroAddress();
    error ZeroAmount();
    error ArrayLengthMismatch();
    error AddFailed();
    error RemoveFailed();
    error Unauthorized();
    error UnknownTemplate();
    error DeployerNotFound();
    error PoolNotRejected();
    error PoolNotApproved();
    error DepositsDisabled();
    error WithdrawalsDisabled();
    error InsufficientBalance();
    error MaxStakePerAddressExceeded();
    error MaxStakePerPoolExceeded();
    error FeeTooHigh();
    error MismatchRegistry();
    error InvalidStatus();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.19;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.19;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
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
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.19;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.19;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.19;

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