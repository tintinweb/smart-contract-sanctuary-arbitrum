// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { IRewarder, IERC20 } from "./IRewarder.sol";

// @dev This is an internal struct, placed here as its shared between multiple libraries.
struct RewardPool {
    uint256 accRewardPerShare;
    address rewardToken;
    uint48 lastRewardTime;
    uint48 allocPoints;
    IERC20 stakingToken;
    bool removed;
    mapping(address => uint256) rewardDebt;
}

/// @notice A rewarder that can distribute multiple reward tokens (ERC20 and native) to `StargateStaking` pools.
/// @dev The native token is encoded as 0x0.
interface IMultiRewarder is IRewarder {
    struct RewardDetails {
        uint256 rewardPerSec;
        uint160 totalAllocPoints;
        uint48 start;
        uint48 end;
        bool exists;
    }

    /// @notice MultiRewarder renounce ownership is disabled.
    error MultiRewarderRenounceOwnershipDisabled();
    /// @notice The token is not connected to the staking contract, connect it first.
    error MultiRewarderDisconnectedStakingToken(address token);
    /// @notice This token is not registered via `setReward` yet, register it first.
    error MultiRewarderUnregisteredToken(address token);
    /**
     *  @notice Due to various functions looping over the staking tokens connected to a reward token,
     *          a maximum number of such links is instated.
     */
    error MultiRewarderMaxPoolsForRewardToken();
    /**
     *  @notice Due to various functions looping over the reward tokens connected to a staking token,
     *          a maximum number of such links is instated.
     */
    error MultiRewarderMaxActiveRewardTokens();
    /// @notice The function can only be called while the pool hasn't ended yet.
    error MultiRewarderPoolFinished(address rewardToken);
    /// @notice The pool emission duration cannot be set to zero, as this would cause the rewards to be voided.
    error MultiRewarderZeroDuration();
    /// @notice The pool start time cannot be set in the past, as this would cause the rewards to be voided.
    error MultiRewarderStartInPast(uint256 start);
    /**
     *  @notice The recipient failed to handle the receipt of the native tokens, do they have a receipt hook?
     *          If not, use `emergencyWithdraw`.
     */
    error MultiRewarderNativeTransferFailed(address to, uint256 amount);
    /**
     *  @notice A wrong `msg.value` was provided while setting a native reward, make sure it matches the function
     *          `amount`.
     */
    error MultiRewarderIncorrectNative(uint256 expected, uint256 actual);
    /**
     *  @notice Due to a zero input or rounding, the reward rate while setting this pool would be zero,
     *          which is not allowed.
     */
    error MultiRewarderZeroRewardRate();

    /// @notice Emitted when additional rewards were added to a pool, extending the reward duration.
    event RewardExtended(address indexed rewardToken, uint256 amountAdded, uint48 newEnd);
    /**
     *  @notice Emitted when a reward token has been registered. Can be emitted again for the same token after it has
     *          been explicitly stopped.
     */
    event RewardRegistered(address indexed rewardToken);
    /// @notice Emitted when the reward pool has been adjusted or intialized, with the new params.
    event RewardSet(
        address indexed rewardToken,
        uint256 amountAdded,
        uint256 amountPeriod,
        uint48 start,
        uint48 duration
    );
    /// @notice Emitted whenever rewards are claimed via the staking pool.
    event RewardsClaimed(address indexed user, address[] rewardTokens, uint256[] amounts);
    /**
     *  @notice Emitted whenever a new staking pool combination was registered via the allocation point adjustment
     *          function.
     */
    event PoolRegistered(address indexed rewardToken, IERC20 indexed stakeToken);
    /// @notice Emitted when the owner adjusts the allocation points for pools.
    event AllocPointsSet(address indexed rewardToken, IERC20[] indexed stakeToken, uint48[] allocPoint);
    /// @notice Emitted when a reward token is stopped.
    event RewardStopped(address indexed rewardToken, address indexed receiver, bool pullTokens);

    /**
     *  @notice Sets the reward for `rewards` of `rewardToken` over `duration` seconds, starting at `start`. The actual
     *          reward over this period will be increased by any rewards on the pool that haven't been distributed yet.
     */
    function setReward(address rewardToken, uint256 rewards, uint48 start, uint48 duration) external payable;
    /**
     *  @notice Extends the reward duration for `rewardToken` by `amount` tokens, extending the duration by the
     *          equivalent time according to the `rewardPerSec` rate of the pool.
     */
    function extendReward(address rewardToken, uint256 amount) external payable;
    /**
     *  @notice Configures allocation points for a reward token over multiple staking tokens, setting the `allocPoints`
     *          for each `stakingTokens` and updating the `totalAllocPoint` for the `rewardToken`. The allocation
     *          points of any non-provided staking tokens will be left as-is, and won't be reset to zero.
     */
    function setAllocPoints(
        address rewardToken,
        IERC20[] calldata stakingTokens,
        uint48[] calldata allocPoints
    ) external;
    /**
     *  @notice Unregisters a reward token fully, immediately preventing users from ever harvesting their pending
     *          accumulated rewards. Optionally `pullTokens` can be set to false which causes the token balance to
     *          not be sent to the owner, this should only be set to false in case the token is bugged and reverts.
     */
    function stopReward(address rewardToken, address receiver, bool pullTokens) external;

    /**
     *  @notice Returns the reward pools linked to the `stakingToken` alongside the pending rewards for `user`
     *          for these pools.
     */
    function getRewards(IERC20 stakingToken, address user) external view returns (address[] memory, uint256[] memory);

    /// @notice Returns the allocation points for the `rewardToken` over all staking tokens linked to it.
    function allocPointsByReward(
        address rewardToken
    ) external view returns (IERC20[] memory stakingTokens, uint48[] memory allocPoints);
    /// @notice Returns the allocation points for the `stakingToken` over all reward tokens linked to it.
    function allocPointsByStake(
        IERC20 stakingToken
    ) external view returns (address[] memory rewardTokens, uint48[] memory allocPoints);

    /// @notice Returns all enabled reward tokens. Stopped reward tokens are not included, while ended rewards are.
    function rewardTokens() external view returns (address[] memory);
    /// @notice Returns the emission details of a `rewardToken`, configured via `setReward`.
    function rewardDetails(address rewardToken) external view returns (RewardDetails memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 *  @notice A rewarder is connected to the staking contract and distributes rewards whenever the staking contract
 *          updates the rewarder.
 */
interface IRewarder {
    /**
     *  @notice This function is only callable by the staking contract.
     */
    error MultiRewarderUnauthorizedCaller(address caller);
    /**
     *  @notice The rewarder cannot be reconnected to the same staking token as it would cause wrongful reward
     *          attribution through reconfiguration.
     */
    error RewarderAlreadyConnected(IERC20 stakingToken);

    /**
     *  @notice Emitted when the rewarder is connected to a staking token.
     */
    event RewarderConnected(IERC20 indexed stakingToken);

    /**
     *  @notice Informs the rewarder of an update in the staking contract, such as a deposit, withdraw or claim.
     *  @dev Emergency withdrawals draw the balance of a user to 0, and DO NOT call `onUpdate`.
     *       The rewarder logic must keep this in mind!
     */
    function onUpdate(IERC20 token, address user, uint256 oldStake, uint256 oldSupply, uint256 newStake) external;

    /**
     *  @notice Called by the staking contract whenever this rewarder is connected to a staking token in the staking
     *          contract. Should only be callable once per staking token to avoid wrongful reward attribution through
     *          reconfiguration.
     */
    function connect(IERC20 stakingToken) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.22;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { IMultiRewarder, RewardPool, IERC20 } from "../interfaces/IMultiRewarder.sol";

/// @dev Internal representation for a staking pool.
struct RewardRegistry {
    uint256 rewardIdCount;
    mapping(uint256 => RewardPool) pools;
    mapping(address rewardToken => EnumerableSet.UintSet) byReward;
    mapping(IERC20 stakingToken => EnumerableSet.UintSet) byStake;
    mapping(address rewardToken => mapping(IERC20 stakingToken => uint256)) byRewardAndStake;
    mapping(address rewardToken => IMultiRewarder.RewardDetails) rewardDetails;
    EnumerableSet.AddressSet rewardTokens;
    mapping(IERC20 stakingToken => bool) connected;
}

/// @dev Library for staking pool logic.
library RewardRegistryLib {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private constant MAX_ACTIVE_POOLS_PER_REWARD = 100;
    uint256 private constant MAX_ACTIVE_REWARD_TOKENS = 100;

    //** REGISTRY ADJUSTMENTS **/
    function getOrCreateRewardDetails(
        RewardRegistry storage self,
        address rewardToken
    ) internal returns (IMultiRewarder.RewardDetails storage reward) {
        reward = self.rewardDetails[rewardToken];
        if (!reward.exists) {
            if (self.rewardTokens.length() >= MAX_ACTIVE_REWARD_TOKENS) {
                revert IMultiRewarder.MultiRewarderMaxActiveRewardTokens();
            }
            reward.exists = true;
            self.rewardTokens.add(rewardToken);
            emit IMultiRewarder.RewardRegistered(rewardToken);
        }
    }

    function getOrCreatePoolId(
        RewardRegistry storage self,
        address reward,
        IERC20 stake
    ) internal returns (uint256 poolId) {
        poolId = self.byRewardAndStake[reward][stake];
        if (poolId == 0) {
            if (self.byReward[reward].length() >= MAX_ACTIVE_POOLS_PER_REWARD) {
                revert IMultiRewarder.MultiRewarderMaxPoolsForRewardToken();
            }
            if (!self.connected[stake]) {
                revert IMultiRewarder.MultiRewarderDisconnectedStakingToken(address(stake));
            }
            poolId = ++self.rewardIdCount; // Start at 1
            self.byRewardAndStake[reward][stake] = poolId;
            self.byReward[reward].add(poolId);
            self.byStake[stake].add(poolId);
            self.pools[poolId].rewardToken = reward;
            self.pools[poolId].stakingToken = stake;
            self.pools[poolId].lastRewardTime = uint48(block.timestamp);

            emit IMultiRewarder.PoolRegistered(reward, stake);
        }
    }

    function removeReward(RewardRegistry storage self, address rewardToken) internal {
        if (!self.rewardDetails[rewardToken].exists) revert IMultiRewarder.MultiRewarderUnregisteredToken(rewardToken);
        uint256[] memory ids = self.byReward[rewardToken].values();
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            IERC20 stakingToken = self.pools[id].stakingToken;

            self.byStake[stakingToken].remove(id);
            self.byReward[rewardToken].remove(id);
            self.byRewardAndStake[rewardToken][stakingToken] = 0;
            self.pools[id].removed = true;
        }
        self.rewardTokens.remove(rewardToken);
        delete self.rewardDetails[rewardToken];
    }

    function setAllocPoints(
        RewardRegistry storage self,
        address rewardToken,
        IERC20[] calldata stakingTokens,
        uint48[] calldata allocPoints
    ) internal {
        IMultiRewarder.RewardDetails storage reward = getOrCreateRewardDetails(self, rewardToken);
        uint160 totalSubtract;
        uint160 totalAdd;
        uint256 length = stakingTokens.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 id = getOrCreatePoolId(self, rewardToken, stakingTokens[i]);
            totalSubtract += self.pools[id].allocPoints;
            totalAdd += allocPoints[i];
            self.pools[id].allocPoints = allocPoints[i];
        }

        reward.totalAllocPoints = reward.totalAllocPoints + totalAdd - totalSubtract;
    }

    //** VIEW FUNCTIONS **/

    function allocPointsByReward(
        RewardRegistry storage self,
        address rewardToken
    ) internal view returns (IERC20[] memory stakingTokens, uint48[] memory allocPoints) {
        uint256[] memory ids = self.byReward[rewardToken].values();
        stakingTokens = new IERC20[](ids.length);
        allocPoints = new uint48[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            stakingTokens[i] = self.pools[ids[i]].stakingToken;
            allocPoints[i] = self.pools[ids[i]].allocPoints;
        }
    }

    function allocPointsByStake(
        RewardRegistry storage self,
        IERC20 stakingToken
    ) internal view returns (address[] memory rewardTokens, uint48[] memory allocPoints) {
        uint256[] memory ids = self.byStake[stakingToken].values();
        rewardTokens = new address[](ids.length);
        allocPoints = new uint48[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            rewardTokens[i] = self.pools[ids[i]].rewardToken;
            allocPoints[i] = self.pools[ids[i]].allocPoints;
        }
    }
}