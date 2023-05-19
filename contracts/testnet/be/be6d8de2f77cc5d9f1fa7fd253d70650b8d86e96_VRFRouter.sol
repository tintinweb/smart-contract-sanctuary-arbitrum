// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {TypeAndVersionInterface} from "./vendor/ocr2-contracts/interfaces/TypeAndVersionInterface.sol";
import {OwnerIsCreator} from "./vendor/ocr2-contracts/OwnerIsCreator.sol";
import {IVRFMigratableCoordinator} from "./IVRFMigratableCoordinator.sol";
import {IVRFMigration} from "./IVRFMigration.sol";
import {IVRFRouter} from "./IVRFRouter.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

////////////////////////////////////////////////////////////////////////////////
/// @title routes consumer requests to coordinators
///
/// @dev This router enables migrations from existing versions of the VRF coordinator to new ones.
/// @dev A VRF Consumer interacts directly with the router for requests and responses (fulfillment and redemption)
/// @dev RequestRandomness/RequestRandomnessFulfillment/RedeemRandomness are backwards-compatible
/// @dev functions across coordinators
/// @dev Consumer should allow calls from the router for fulfillment
contract VRFRouter is IVRFRouter, TypeAndVersionInterface, OwnerIsCreator {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => address) private s_routes; /* sub id */ /* vrf coordinator address*/
    EnumerableSet.AddressSet private s_coordinators;

    /// @dev Mapping of a globally unique request ID to the coordinator on which it was requested
    mapping(uint256 => address) public s_redemptionRoutes;

    /// @dev Emitted when given subID doesn't have any route defined
    error RouteNotFound(address route);
    /// @dev coordinator is already registered as a valid coordinator in the router
    error CoordinatorAlreadyRegistered();
    /// @dev Emitted when given address is not registered in the router
    error CoordinatorNotRegistered();
    /// @dev Emitted when given address returns unexpected migration version
    error UnexpectedMigrationVersion();
    /// @dev Emitted when given requestID doesn't have any redemption route defined
    error RedemptionRouteNotFound(uint256 requestID);

    /// @dev Emitted when new coordinator is registered
    event CoordinatorRegistered(address coordinatorAddress);
    /// @dev Emitted when new coordinator is deregistered
    event CoordinatorDeregistered(address coordinatorAddress);
    /// @dev Emitted when a route is set for given subID
    event RouteSet(uint256 indexed subID, address coordinatorAddress);

    function getRoute(uint256 subID) public view returns (address coordinator) {
        address route = s_routes[subID];
        if (route == address(0)) {
            revert RouteNotFound(route);
        }

        if (!s_coordinators.contains(route)) {
            // This case happens when a coordinator is deprecated,
            // causing dangling subIDs to become invalid
            revert RouteNotFound(route);
        }

        return route;
    }

    /// @dev whenever a subscription is created in coordinator, it must call
    /// @dev this function to register the route
    function setRoute(uint256 subID) external validateCoordinators(msg.sender) {
        s_routes[subID] = msg.sender;
        emit RouteSet(subID, msg.sender);
    }

    /// @dev whenever a subscription is cancelled/deleted in coordinator, it must call
    /// @dev this function to reset the route
    function resetRoute(uint256 subID)
        external
        validateCoordinators(msg.sender)
    {
        s_routes[subID] = address(0);
        emit RouteSet(subID, address(0));
    }

    function registerCoordinator(address coordinatorAddress)
        external
        onlyOwner
    {
        if (s_coordinators.contains(coordinatorAddress)) {
            revert CoordinatorAlreadyRegistered();
        }
        IVRFMigration coordinator = IVRFMigration(coordinatorAddress);
        // validate coordinator implements IVRFMigration and
        // returns valid migration version
        if (coordinator.migrationVersion() == 0) {
            revert UnexpectedMigrationVersion();
        }

        s_coordinators.add(coordinatorAddress);
        emit CoordinatorRegistered(coordinatorAddress);
    }

    function deregisterCoordinator(address coordinatorAddress)
        external
        onlyOwner
        validateCoordinators(coordinatorAddress)
    {
        s_coordinators.remove(coordinatorAddress);
        emit CoordinatorDeregistered(coordinatorAddress);
    }

    function getCoordinators() external view returns (address[] memory) {
        return s_coordinators.values();
    }

    function isCoordinatorRegistered(address coordinatorAddress)
        external
        view
        returns (bool)
    {
        return s_coordinators.contains(coordinatorAddress);
    }

    /**
     * @inheritdoc IVRFRouter
     */
    function requestRandomness(
        uint256 subID,
        uint16 numWords,
        uint24 confDelay,
        bytes memory extraArgs
    ) external override returns (uint256) {
        IVRFMigratableCoordinator coordinator = IVRFMigratableCoordinator(
            getRoute(subID)
        );
        uint256 requestID = coordinator.requestRandomness(
            msg.sender,
            subID,
            numWords,
            confDelay,
            extraArgs
        );

        s_redemptionRoutes[requestID] = address(coordinator);

        return requestID;
    }

    /**
     * @inheritdoc IVRFRouter
     */
    function requestRandomnessFulfillment(
        uint256 subID,
        uint16 numWords,
        uint24 confDelay,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external override returns (uint256) {
        IVRFMigratableCoordinator coordinator = IVRFMigratableCoordinator(
            getRoute(subID)
        );
        return
            coordinator.requestRandomnessFulfillment(
                msg.sender,
                subID,
                numWords,
                confDelay,
                callbackGasLimit,
                arguments,
                extraArgs
            );
    }

    /**
     * @inheritdoc IVRFRouter
     */
    function redeemRandomness(
        uint256 subID,
        uint256 requestID,
        bytes memory extraArgs
    ) external override returns (uint256[] memory randomness) {
        address coordinatorAddress = s_redemptionRoutes[requestID];
        if (coordinatorAddress == address(0)) {
            revert RedemptionRouteNotFound(requestID);
        }
        IVRFMigratableCoordinator coordinator = IVRFMigratableCoordinator(
            coordinatorAddress
        );
        return
            coordinator.redeemRandomness(
                msg.sender,
                subID,
                requestID,
                extraArgs
            );
    }

    /**
     * @inheritdoc IVRFRouter
     */
    function getFee(uint256 subID, bytes memory extraArgs)
        external
        view
        override
        returns (uint256)
    {
        IVRFMigratableCoordinator coordinator = IVRFMigratableCoordinator(
            getRoute(subID)
        );
        return coordinator.getFee(subID, extraArgs);
    }

    /**
     * @inheritdoc IVRFRouter
     */
    function getFulfillmentFee(
        uint256 subID,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external view override returns (uint256) {
        IVRFMigratableCoordinator coordinator = IVRFMigratableCoordinator(
            getRoute(subID)
        );
        return
            coordinator.getFulfillmentFee(
                subID,
                callbackGasLimit,
                arguments,
                extraArgs
            );
    }

    uint256 private constant CALL_WITH_EXACT_GAS_CUSHION = 5_000;

    /**
     * @dev calls target address with exactly gasAmount gas and data as calldata
     * or reverts if at least gasAmount gas is not available.
     */
    function callWithExactGasEvenIfTargetIsNoContract(
        uint256 gasAmount,
        address target,
        bytes memory data
    )
        external
        validateCoordinators(msg.sender)
        returns (bool success, bool sufficientGas)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let g := gas()
            // Compute g -= CALL_WITH_EXACT_GAS_CUSHION and check for underflow. We
            // need the cushion since the logic following the above call to gas also
            // costs gas which we cannot account for exactly. So cushion is a
            // conservative upper bound for the cost of this logic.
            if iszero(lt(g, CALL_WITH_EXACT_GAS_CUSHION)) {
                // i.e., g >= CALL_WITH_EXACT_GAS_CUSHION
                g := sub(g, CALL_WITH_EXACT_GAS_CUSHION)
                // If g - g//64 <= _gasAmount, we don't have enough gas. (We subtract g//64
                // because of EIP-150.)
                if gt(sub(g, div(g, 64)), gasAmount) {
                    // Call and receive the result of call. Note that we did not check
                    // whether a contract actually exists at the _target address.
                    success := call(
                        gasAmount, // gas
                        target, // address of target contract
                        0, // value
                        add(data, 0x20), // inputs
                        mload(data), // inputs size
                        0, // outputs
                        0 // outputs size
                    )
                    sufficientGas := true
                }
            }
        }
    }

    modifier validateCoordinators(address addr) {
        if (!s_coordinators.contains(addr)) {
            revert CoordinatorNotRegistered();
        }
        _;
    }

    function typeAndVersion() external pure override returns (string memory) {
        return "VRFRouter 1.0.0";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TypeAndVersionInterface {
    function typeAndVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {
    constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract IVRFMigratableCoordinator {
    //////////////////////////////////////////////////////////////////////////////
    /// @notice Register a future request for randomness,and return the requestID.
    ///
    /// @notice The requestID resulting from given requestRandomness call MAY
    /// @notice CHANGE if a set of transactions calling requestRandomness are
    /// @notice re-ordered during a block re-organization. Thus, it is necessary
    /// @notice for the calling context to store the requestID onchain, unless
    /// @notice there is a an offchain system which keeps track of changes to the
    /// @notice requestID.
    ///
    /// @param requester consumer address. msg.sender in router
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confirmationDelay minimum number of blocks before response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomness(
        address requester,
        uint256 subID,
        uint16 numWords,
        uint24 confirmationDelay,
        bytes memory extraArgs
    ) external virtual returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Request a callback on the next available randomness output
    ///
    /// @notice The contract at the callback address must have a method
    /// @notice rawFulfillRandomness(bytes32,uint256,bytes). It will be called with
    /// @notice the ID returned by this function, the random value, and the
    /// @notice arguments value passed to this function.
    ///
    /// @dev No record of this commitment is stored onchain. The VRF committee is
    /// @dev trusted to only provide callbacks for valid requests.
    ///
    /// @param requester consumer address. msg.sender in router
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confirmationDelay minimum number of blocks before response
    /// @param callbackGasLimit maximum gas allowed for callback function
    /// @param arguments data to return in response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomnessFulfillment(
        address requester,
        uint256 subID,
        uint16 numWords,
        uint24 confirmationDelay,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external virtual returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Get randomness for the given requestID
    /// @param requester consumer address. msg.sender in router
    /// @param subID subscription ID
    /// @param requestID ID of request r for which to retrieve randomness
    /// @param extraArgs extra arguments
    /// @return randomness r.numWords random uint256's
    function redeemRandomness(
        address requester,
        uint256 subID,
        uint256 requestID,
        bytes memory extraArgs
    ) external virtual returns (uint256[] memory randomness);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice gets request randomness price
    /// @param subID subscription ID
    /// @param extraArgs extra arguments
    /// @return fee amount in lowest denomination
    function getFee(uint256 subID, bytes memory extraArgs)
        external
        view
        virtual
        returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice gets request randomness fulfillment price
    /// @param subID subscription ID
    /// @param callbackGasLimit maximum gas allowed for callback function
    /// @param arguments data to return in response
    /// @param extraArgs extra arguments
    /// @return fee amount in lowest denomination
    function getFulfillmentFee(
        uint256 subID,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IVRFMigratableCoordinator} from "./IVRFMigratableCoordinator.sol";

interface IVRFMigration {
    /**
     * @notice Migrates user data (e.g. balance, consumers) from one coordinator to another.
     * @notice only callable by the owner of user data
     * @param newCoordinator new coordinator instance
     * @param encodedRequest abi-encoded data that identifies that migrate() request (e.g. version to migrate to, user data ID)
     */
    function migrate(
        IVRFMigration newCoordinator,
        bytes calldata encodedRequest
    ) external;

    /**
     * @notice called by older versions of coordinator for migration.
     * @notice only callable by older versions of coordinator
     * @param encodedData - user data from older version of coordinator
     */
    function onMigration(bytes calldata encodedData) external;

    /**
     * @return version - current migration version
     */
    function migrationVersion() external pure returns (uint8 version);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IVRFRouter {
    //////////////////////////////////////////////////////////////////////////////
    /// @notice Register a future request for randomness,and return the requestID.
    ///
    /// @notice The requestID resulting from given requestRandomness call MAY
    /// @notice CHANGE if a set of transactions calling requestRandomness are
    /// @notice re-ordered during a block re-organization. Thus, it is necessary
    /// @notice for the calling context to store the requestID onchain, unless
    /// @notice there is a an offchain system which keeps track of changes to the
    /// @notice requestID.
    ///
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confDelay minimum number of blocks before response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomness(
        uint256 subID,
        uint16 numWords,
        uint24 confDelay,
        bytes memory extraArgs
    ) external returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Request a callback on the next available randomness output
    ///
    /// @notice The contract at the callback address must have a method
    /// @notice rawFulfillRandomness(bytes32,uint256,bytes). It will be called with
    /// @notice the ID returned by this function, the random value, and the
    /// @notice arguments value passed to this function.
    ///
    /// @dev No record of this commitment is stored onchain. The VRF committee is
    /// @dev trusted to only provide callbacks for valid requests.
    ///
    /// @param subID subscription ID
    /// @param numWords number of uint256's of randomness to provide in response
    /// @param confDelay minimum number of blocks before response
    /// @param callbackGasLimit maximum gas allowed for callback function
    /// @param arguments data to return in response
    /// @param extraArgs extra arguments
    /// @return ID of created request
    function requestRandomnessFulfillment(
        uint256 subID,
        uint16 numWords,
        uint24 confDelay,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice Get randomness for the given requestID
    /// @param subID subscription ID
    /// @param requestID ID of request r for which to retrieve randomness
    /// @param extraArgs extra arguments
    /// @return randomness r.numWords random uint256's
    function redeemRandomness(
        uint256 subID,
        uint256 requestID,
        bytes memory extraArgs
    ) external returns (uint256[] memory randomness);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice gets request randomness price
    /// @param subID subscription ID
    /// @param extraArgs extra arguments
    /// @return fee amount in lowest denomination
    function getFee(uint256 subID, bytes memory extraArgs)
        external
        view
        returns (uint256);

    //////////////////////////////////////////////////////////////////////////////
    /// @notice gets request randomness fulfillment price
    /// @param subID subscription ID
    /// @param callbackGasLimit maximum gas allowed for callback function
    /// @param arguments data to return in response
    /// @param extraArgs extra arguments
    /// @return fee amount in lowest denomination
    function getFulfillmentFee(
        uint256 subID,
        uint32 callbackGasLimit,
        bytes memory arguments,
        bytes memory extraArgs
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
    constructor(address newOwner)
        ConfirmedOwnerWithProposal(newOwner, address(0))
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
    address private s_owner;
    address private s_pendingOwner;

    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);

    constructor(address newOwner, address pendingOwner) {
        require(newOwner != address(0), "Cannot set owner to zero");

        s_owner = newOwner;
        if (pendingOwner != address(0)) {
            _transferOwnership(pendingOwner);
        }
    }

    /**
     * @notice Allows an owner to begin transferring ownership to a new address,
     * pending.
     */
    function transferOwnership(address to) public override onlyOwner {
        _transferOwnership(to);
    }

    /**
     * @notice Allows an ownership transfer to be completed by the recipient.
     */
    function acceptOwnership() external override {
        require(msg.sender == s_pendingOwner, "Must be proposed owner");

        address oldOwner = s_owner;
        s_owner = msg.sender;
        s_pendingOwner = address(0);

        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    /**
     * @notice Get the current owner
     */
    function owner() public view override returns (address) {
        return s_owner;
    }

    /**
     * @notice validate, transfer ownership, and emit relevant events
     */
    function _transferOwnership(address to) private {
        require(to != msg.sender, "Cannot transfer to self");

        s_pendingOwner = to;

        emit OwnershipTransferRequested(s_owner, to);
    }

    /**
     * @notice validate access
     */
    function _validateOwnership() internal view {
        require(msg.sender == s_owner, "Only callable by owner");
    }

    /**
     * @notice Reverts if called by anyone other than the contract owner.
     */
    modifier onlyOwner() {
        _validateOwnership();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
    function owner() external returns (address);

    function transferOwnership(address recipient) external;

    function acceptOwnership() external;
}