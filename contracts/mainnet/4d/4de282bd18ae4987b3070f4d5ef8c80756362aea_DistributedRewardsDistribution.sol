/**
                                             .::.
                                          .=***#*+:
                                        .=*********+.
                                      .=++++*********=.
                                    .=++=++++++++******-
                                  .=++=++++++++++++******-
                                .=++==+++++++++++==+******+:
                              .=+===+++++++++++++===+*******=
                            .=+===+++++++++++++++===-=*******=
                           .=====++++++++++++++++====-=*****#*.
                           :-===++++++++++++++++++====--+*###=
                          :==+++++++++++++++++++++====---=+*-
                        :=++***************++++++++====--:-
                      .-+*########*************++++++===-:
                     .=##%%##################*****++++===-.
                     =#%%%%%%###########%%#######***+++==--
                     +%@@#****************##%%%#####**++==-.
                     -%#==*##**********##*****#%%%####**+==:
                      *-=*%+##*******##%@@#******#%%###**+=-
                      :=+%%#@%******#%=*@@%*********#%##*++-
                      :=*%@@@**####*#@@@@@%********++*###*+.
                      =+**##*#######*#@@@%#####****++++**+-
                +*-  .+**#**#########*****######****+++=+-
               -#**+:-**++**########***###%%%%##**+++++=.
             ::-**+-=*#*=+**#######***#*###%%%##**++++*+=         :=-
            -###****##%==+**######*******#######**+===*#*+-::::-=*##*
            .#%#******==+***##%%%#********######**++==+%%%##**#####%*
              +#%##******###%%%####****+++*#%%%##*********#%%%%%%%%*.
               :%%%%%%%#%%%%###=.+##**********##########%%##%%%###=
                 #%#%%%%%##**=.  :########%%#:-**#%%%%%##*+++*+-:
                  ::+#**#+=-.     =#%%%%#%%#*.  :=*****=:
                                   :+##*##+=       ..
                                     :-.::

*/
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IRewardsDistribution.sol";
import "./interfaces/IRouter.sol";
import "./AccessControlledPausable.sol";

/**
 * @title Distributed Rewards Distribution Contract
 * @dev Contract has a list of whitelisted distributors
 * Each `roundRobinBlocks` blocks, a new subset of distributors are nominated as committers
 * One of them can then commit a distribution
 * Other distributors can approve it
 * After N approvals, the distribution is executed
 */
contract DistributedRewardsDistribution is AccessControlledPausable, IRewardsDistribution {
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant REWARDS_DISTRIBUTOR_ROLE = keccak256("REWARDS_DISTRIBUTOR_ROLE");
  bytes32 public constant REWARDS_TREASURY_ROLE = keccak256("REWARDS_TREASURY_ROLE");

  mapping(uint256 workerId => uint256) internal _claimable;
  mapping(uint256 fromBlock => mapping(uint256 toBlock => bytes32)) public commitments;
  mapping(uint256 fromBlock => mapping(uint256 toBlock => uint8)) public approves;
  mapping(bytes32 commitment => mapping(address distributor => bool)) public alreadyApproved;
  uint256 public requiredApproves;
  uint256 public lastBlockRewarded;
  // How often the current committers set is changed
  uint256 public roundRobinBlocks = 256;
  // Number of distributors which can commit a distribution at the same time
  uint256 public windowSize = 1;

  IRouter public immutable router;
  EnumerableSet.AddressSet private distributors;

  /// @dev Emitted on new commitment
  event NewCommitment(address indexed who, uint256 fromBlock, uint256 toBlock, bytes32 commitment);

  /// @dev Emitted when commitment is approved
  event Approved(address indexed who, uint256 fromBlock, uint256 toBlock, bytes32 commitment);

  /// @dev Emitted when commitment is approved
  event Distributed(
    uint256 fromBlock, uint256 toBlock, uint256[] recipients, uint256[] workerRewards, uint256[] stakerRewards
  );

  /// @dev Emitted when new distributor is added
  event DistributorAdded(address indexed distributor);
  /// @dev Emitted when distributor is removed
  event DistributorRemoved(address indexed distributor);
  /// @dev Emitted when required approvals is changed
  event ApprovesRequiredChanged(uint256 newApprovesRequired);
  /// @dev Emitted when window size is changed
  event WindowSizeChanged(uint256 newWindowSize);
  /// @dev Emitted when round robin blocks is changed
  event RoundRobinBlocksChanged(uint256 newRoundRobinBlocks);

  constructor(IRouter _router) {
    requiredApproves = 1;
    router = _router;
  }

  /**
   * @dev Add whitelisted distributor
   * Only admin can call this function
   */
  function addDistributor(address distributor) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(distributors.add(distributor), "Distributor already added");
    _grantRole(REWARDS_DISTRIBUTOR_ROLE, distributor);

    emit DistributorAdded(distributor);
  }

  /**
   * @dev Remove whitelisted distributor
   * Only admin can call this function
   */
  function removeDistributor(address distributor) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(distributors.length() > requiredApproves, "Not enough distributors to approve distribution");
    require(distributors.remove(distributor), "Distributor does not exist");
    _revokeRole(REWARDS_DISTRIBUTOR_ROLE, distributor);

    emit DistributorRemoved(distributor);
  }

  /**
   * @dev Get an index of the first distribuor which can currently commit a distribution
   */
  function distributorIndex() internal view returns (uint256) {
    return (block.number / roundRobinBlocks * roundRobinBlocks) % distributors.length();
  }

  function canCommit(address who) public view returns (bool) {
    uint256 firstIndex = distributorIndex();
    uint256 distributorsCount = distributors.length();
    for (uint256 i = 0; i < windowSize; i++) {
      if (distributors.at((firstIndex + i) % distributorsCount) == who) {
        return true;
      }
    }
    return false;
  }

  /**
   * @dev Commit rewards for a worker
   * @param fromBlock block from which the rewards are calculated
   * @param toBlock block to which the rewards are calculated
   * @param recipients array of workerIds. i-th recipient will receive i-th worker and staker rewards accordingly
   * @param workerRewards array of rewards for workers
   * @param _stakerRewards array of rewards for stakers
   * can only be called by current distributor
   * lengths of recipients, workerRewards and _stakerRewards must be equal
   * can recommit to same toBlock, but this drops approve count back to 1
   * @notice If only 1 approval is required, the distribution is executed immediately
   */
  function commit(
    uint256 fromBlock,
    uint256 toBlock,
    uint256[] calldata recipients,
    uint256[] calldata workerRewards,
    uint256[] calldata _stakerRewards
  ) external whenNotPaused {
    require(recipients.length == workerRewards.length, "Recipients and worker amounts length mismatch");
    require(recipients.length == _stakerRewards.length, "Recipients and staker amounts length mismatch");
    require(toBlock >= fromBlock, "toBlock before fromBlock");

    require(canCommit(msg.sender), "Not a committer");
    require(toBlock < block.number, "Future block");
    bytes32 commitment = keccak256(msg.data[4:]);
    require(!alreadyApproved[commitment][msg.sender], "Already approved");
    if (commitments[fromBlock][toBlock] == commitment) {
      _approve(commitment, fromBlock, toBlock, recipients, workerRewards, _stakerRewards);
      return;
    }

    commitments[fromBlock][toBlock] = commitment;
    approves[fromBlock][toBlock] = 0;

    emit NewCommitment(msg.sender, fromBlock, toBlock, commitment);
    _approve(commitment, fromBlock, toBlock, recipients, workerRewards, _stakerRewards);
  }

  /**
   * @dev Approve a commitment
   * Same args as for commit
   * After `requiredApproves` approvals, the distribution is executed
   */
  function approve(
    uint256 fromBlock,
    uint256 toBlock,
    uint256[] calldata recipients,
    uint256[] calldata workerRewards,
    uint256[] calldata _stakerRewards
  ) external onlyRole(REWARDS_DISTRIBUTOR_ROLE) whenNotPaused {
    require(commitments[fromBlock][toBlock] != 0, "Commitment does not exist");
    bytes32 commitment = keccak256(msg.data[4:]);
    require(commitments[fromBlock][toBlock] == commitment, "Commitment mismatch");
    require(!alreadyApproved[commitment][msg.sender], "Already approved");

    _approve(commitment, fromBlock, toBlock, recipients, workerRewards, _stakerRewards);
  }

  function _approve(
    bytes32 commitment,
    uint256 fromBlock,
    uint256 toBlock,
    uint256[] calldata recipients,
    uint256[] calldata workerRewards,
    uint256[] calldata _stakerRewards
  ) internal {
    approves[fromBlock][toBlock]++;
    alreadyApproved[commitment][msg.sender] = true;

    emit Approved(msg.sender, fromBlock, toBlock, commitment);

    if (approves[fromBlock][toBlock] == requiredApproves) {
      distribute(fromBlock, toBlock, recipients, workerRewards, _stakerRewards);
    }
  }

  /// @return true if the commitment can be approved by `who`
  function canApprove(
    address who,
    uint256 fromBlock,
    uint256 toBlock,
    uint256[] calldata recipients,
    uint256[] calldata workerRewards,
    uint256[] calldata _stakerRewards
  ) external view returns (bool) {
    if (!hasRole(REWARDS_DISTRIBUTOR_ROLE, who)) {
      return false;
    }
    if (commitments[fromBlock][toBlock] == 0) {
      return false;
    }
    bytes32 commitment = keccak256(abi.encode(fromBlock, toBlock, recipients, workerRewards, _stakerRewards));
    if (commitments[fromBlock][toBlock] != commitment) {
      return false;
    }
    if (alreadyApproved[commitment][who]) {
      return false;
    }
    return true;
  }

  /// @dev All distributions must be sequential and not blocks can be missed
  /// E.g. after distribution for blocks [A, B], next one bust be for [B + 1, C]
  function distribute(
    uint256 fromBlock,
    uint256 toBlock,
    uint256[] calldata recipients,
    uint256[] calldata workerRewards,
    uint256[] calldata _stakerRewards
  ) internal {
    require(lastBlockRewarded == 0 || fromBlock == lastBlockRewarded + 1, "Not all blocks covered");
    for (uint256 i = 0; i < recipients.length; i++) {
      _claimable[recipients[i]] += workerRewards[i];
    }
    router.staking().distribute(recipients, _stakerRewards);
    lastBlockRewarded = toBlock;

    emit Distributed(fromBlock, toBlock, recipients, workerRewards, _stakerRewards);
  }

  /// @dev Treasury claims rewards for an address
  /// @notice Can only be called by the treasury
  /// @notice Claimable amount should drop to 0 after function call
  function claim(address who) external onlyRole(REWARDS_TREASURY_ROLE) whenNotPaused returns (uint256 claimedAmount) {
    claimedAmount = router.staking().claim(who);
    uint256[] memory ownedWorkers = router.workerRegistration().getOwnedWorkers(who);
    for (uint256 i = 0; i < ownedWorkers.length; i++) {
      uint256 workerId = ownedWorkers[i];
      uint256 claimedFromWorker = _claimable[workerId];
      claimedAmount += claimedFromWorker;
      _claimable[workerId] = 0;
      emit Claimed(who, workerId, claimedFromWorker);
    }

    return claimedAmount;
  }

  /// @return claimable amount for the address
  function claimable(address who) external view returns (uint256) {
    uint256 reward = router.staking().claimable(who);
    uint256[] memory ownedWorkers = router.workerRegistration().getOwnedWorkers(who);
    for (uint256 i = 0; i < ownedWorkers.length; i++) {
      uint256 workerId = ownedWorkers[i];
      reward += _claimable[workerId];
    }
    return reward;
  }

  /// @dev Set required number of approvals
  function setApprovesRequired(uint256 _approvesRequired) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_approvesRequired > 0, "Approves required must be greater than 0");
    require(_approvesRequired <= distributors.length(), "Approves required must be less than distributors count");
    requiredApproves = _approvesRequired;

    emit ApprovesRequiredChanged(_approvesRequired);
  }

  /// @dev Set required number of approvals
  function setWindowSize(uint256 _windowSize) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_windowSize > 0, "Number of simultaneous committers must be positive");
    require(_windowSize <= distributors.length(), "Number of simultaneous committers less than distributors count");
    windowSize = _windowSize;

    emit WindowSizeChanged(_windowSize);
  }

  /// @dev Set round robin length
  function setRoundRobinBlocks(uint256 _roundRobinBlocks) external onlyRole(DEFAULT_ADMIN_ROLE) {
    require(_roundRobinBlocks > 0, "Round robin blocks must be positive");
    roundRobinBlocks = _roundRobinBlocks;

    emit RoundRobinBlocksChanged(_roundRobinBlocks);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

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
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
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
            set._positions[value] = set._values.length;
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
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IRewardsDistribution {
  /// @dev Emitted when rewards are claimed
  event Claimed(address indexed by, uint256 indexed worker, uint256 amount);

  /// @dev claim rewards for worker
  function claim(address worker) external returns (uint256 reward);

  /// @dev get currently claimable rewards for worker
  function claimable(address worker) external view returns (uint256 reward);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./IWorkerRegistration.sol";
import "./IStaking.sol";
import "./INetworkController.sol";
import "./IRewardCalculation.sol";

interface IRouter {
  function workerRegistration() external view returns (IWorkerRegistration);
  function staking() external view returns (IStaking);
  function rewardTreasury() external view returns (address);
  function networkController() external view returns (INetworkController);
  function rewardCalculation() external view returns (IRewardCalculation);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @dev abstract contract that allows wallets with special pauser role to pause contracts
abstract contract AccessControlledPausable is Pausable, AccessControl {
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(PAUSER_ROLE, msg.sender);
  }

  function pause() public virtual onlyRole(PAUSER_ROLE) {
    _pause();
  }

  function unpause() public virtual onlyRole(PAUSER_ROLE) {
    _unpause();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IWorkerRegistration {
  /// @dev Emitted when a worker is registered
  event WorkerRegistered(
    uint256 indexed workerId, bytes peerId, address indexed registrar, uint256 registeredAt, string metadata
  );

  /// @dev Emitted when a worker is deregistered
  event WorkerDeregistered(uint256 indexed workerId, address indexed account, uint256 deregistedAt);

  /// @dev Emitted when the bond is withdrawn
  event WorkerWithdrawn(uint256 indexed workerId, address indexed account);

  /// @dev Emitted when a excessive bond is withdrawn
  event ExcessiveBondReturned(uint256 indexed workerId, uint256 amount);

  /// @dev Emitted when metadata is updated
  event MetadataUpdated(uint256 indexed workerId, string metadata);

  function register(bytes calldata peerId, string calldata metadata) external;

  /// @return The number of active workers.
  function getActiveWorkerCount() external view returns (uint256);
  function getActiveWorkerIds() external view returns (uint256[] memory);

  /// @return The ids of all worker created by the owner account
  function getOwnedWorkers(address who) external view returns (uint256[] memory);

  function nextWorkerId() external view returns (uint256);

  function isWorkerActive(uint256 workerId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IStaking {
  struct StakerRewards {
    /// @dev the sum of (amount_i / totalStaked_i) for each distribution of amount_i when totalStaked_i was staked
    uint256 cumulatedRewardsPerShare;
    /// @dev the value of cumulatedRewardsPerShare when the user's last action was performed (deposit or withdraw)
    mapping(address staker => uint256) checkpoint;
    /// @dev the amount of tokens staked by the user
    mapping(address staker => uint256) depositAmount;
    /// @dev block from which withdraw is allowed for staker
    mapping(address staker => uint128) withdrawAllowed;
    /// @dev the total amount of tokens staked
    uint256 totalStaked;
  }

  /// @dev Emitted when rewards where distributed by the distributor
  event Distributed(uint256 epoch);
  /// @dev Emitted when a staker delegates amount to the worker
  event Deposited(uint256 indexed worker, address indexed staker, uint256 amount);
  /// @dev Emitted when a staker undelegates amount to the worker
  event Withdrawn(uint256 indexed worker, address indexed staker, uint256 amount);
  /// @dev Emitted when new claimable reward arrives
  event Rewarded(uint256 indexed workerId, address indexed staker, uint256 amount);
  /// @dev Emitted when a staker claims rewards
  event Claimed(address indexed staker, uint256 amount, uint256[] workerIds);
  /// @dev Emitted when max delegations is changed
  event EpochsLockChanged(uint128 epochsLock);

  event MaxDelegationsChanged(uint256 maxDelegations);

  /// @dev Deposit amount of tokens in favour of a worker
  /// @param worker workerId in WorkerRegistration contract
  /// @param amount amount of tokens to deposit
  function deposit(uint256 worker, uint256 amount) external;

  /// @dev Withdraw amount of tokens staked in favour of a worker
  /// @param worker workerId in WorkerRegistration contract
  /// @param amount amount of tokens to withdraw
  function withdraw(uint256 worker, uint256 amount) external;

  /// @dev Claim rewards for a staker
  /// @return amount of tokens claimed
  function claim(address staker) external returns (uint256);

  /// @return claimable amount
  /// MUST return same value as claim(address staker) but without modifying state
  function claimable(address staker) external view returns (uint256);

  /// @dev total staked amount for the worker
  function delegated(uint256 worker) external view returns (uint256);

  /// @dev Distribute tokens to stakers in favour of a worker
  /// @param workers array of workerIds in WorkerRegistration contract
  /// @param amounts array of amounts of tokens to distribute for i-th worker
  function distribute(uint256[] calldata workers, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface INetworkController {
  /// @dev Emitted when epoch length is updated
  event EpochLengthUpdated(uint128 epochLength);
  /// @dev Emitted when bond amount is updated
  event BondAmountUpdated(uint256 bondAmount);
  /// @dev Emitted when storage per worker is updated
  event StoragePerWorkerInGbUpdated(uint128 storagePerWorkerInGb);
  event StakingDeadlockUpdated(uint256 stakingDeadlock);
  event AllowedVestedTargetUpdated(address target, bool isAllowed);
  event TargetCapacityUpdated(uint256 target);
  event RewardCoefficientUpdated(uint256 coefficient);

  /// @dev Amount of blocks in one epoch
  function epochLength() external view returns (uint128);

  /// @dev Amount of tokens required to register a worker
  function bondAmount() external view returns (uint256);

  /// @dev Block when next epoch starts
  function nextEpoch() external view returns (uint128);

  /// @dev Number of current epoch (starting from 0 when contract is deployed)
  function epochNumber() external view returns (uint128);

  /// @dev Number of unrewarded epochs after which staking will be blocked
  function stakingDeadlock() external view returns (uint256);

  /// @dev Number of current epoch (starting from 0 when contract is deployed)
  function targetCapacityGb() external view returns (uint256);

  /// @dev Amount of storage in GB each worker is expected to provide
  function storagePerWorkerInGb() external view returns (uint128);

  /// @dev Can the `target` be used as a called by the vesting contract
  function isAllowedVestedTarget(address target) external view returns (bool);

  /// @dev Max part of initial reward pool that can be allocated during a year, in basis points
  /// example: 3000 will mean that on each epoch, max 30% of the initial pool * epoch length / 1 year can be allocated
  function yearlyRewardCapCoefficient() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IRewardCalculation {
  function currentApy() external view returns (uint256);

  function boostFactor(uint256 duration) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `_msgSender()`
     * is missing `role`. Overriding this function changes the behavior of the {onlyRole} modifier.
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Reverts with an {AccessControlUnauthorizedAccount} error if `account`
     * is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != _msgSender()) {
            revert AccessControlBadConfirmation();
        }

        _revokeRole(role, callerConfirmation);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Attempts to grant `role` to `account` and returns a boolean indicating if `role` was granted.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Attempts to revoke `role` to `account` and returns a boolean indicating if `role` was revoked.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual returns (bool) {
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
 */
interface IAccessControl {
    /**
     * @dev The `account` is missing a role.
     */
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    /**
     * @dev The caller of a function is not the expected one.
     *
     * NOTE: Don't confuse with {AccessControlUnauthorizedAccount}.
     */
    error AccessControlBadConfirmation();

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `callerConfirmation`.
     */
    function renounceRole(bytes32 role, address callerConfirmation) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}