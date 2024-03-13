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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../utils/Roles.sol";

/// @title OrderStore
/// @notice Persistent storage for Orders.sol
contract OrderStore is Roles {
    uint256 private constant swV = 1000101;
    // Libraries
    using EnumerableSet for EnumerableSet.UintSet;

    // Order struct
    struct Order {
        uint256 orderId; // incremental order id
        address user; // user that usubmitted the order
        address asset; // Asset address, e.g. address(0) for ETH
        string market; // Market this order was submitted on
        uint256 margin; // Collateral tied to this order. In wei
        uint256 size; // Order size (margin * leverage). In wei
        uint256 price; // The order's price if its a trigger or protected order
        uint256 fee; // Fee amount paid. In wei
        bool isLong; // Wether the order is a buy or sell order
        uint8 orderType; // 0 = market, 1 = limit, 2 = stop
        bool isReduceOnly; // Wether the order is reduce-only
        uint256 timestamp; // block.timestamp at which the order was submitted
        uint256 expiry; // block.timestamp at which the order expires
        uint256 cancelOrderId; // orderId to cancel when this order executes
    }

    uint256 public oid; // incremental order id
    mapping(uint256 => Order) private orders; // order id => Order
    mapping(address => EnumerableSet.UintSet) private userOrderIds; // user => [order ids..]
    EnumerableSet.UintSet private marketOrderIds; // [order ids..]
    EnumerableSet.UintSet private triggerOrderIds; // [order ids..]

    uint256 public maxMarketOrderTTL = 5 minutes;
    uint256 public maxTriggerOrderTTL = 180 days;
    uint256 public chainlinkCooldown = 5 minutes;

    bool public areNewOrdersPaused;
    bool public isProcessingPaused;

    constructor(RoleStore rs) Roles(rs) {}

    // Setters

    /// @notice Disable submitting new orders
    /// @dev Only callable by governance
    function setAreNewOrdersPaused(bool b) external onlyGov {
        areNewOrdersPaused = b;
    }

    /// @notice Disable processing new orders
    /// @dev Only callable by governance
    function setIsProcessingPaused(bool b) external onlyGov {
        isProcessingPaused = b;
    }

    /// @notice Set duration until market orders expire
    /// @dev Only callable by governance
    /// @param amount Duration in seconds
    function setMaxMarketOrderTTL(uint256 amount) external onlyGov {
        require(amount > 0, "!amount");
        require(amount < maxTriggerOrderTTL, "amount > maxTriggerOrderTTL");
        maxMarketOrderTTL = amount;
    }

    /// @notice Set duration until trigger orders expire
    /// @dev Only callable by governance
    /// @param amount Duration in seconds
    function setMaxTriggerOrderTTL(uint256 amount) external onlyGov {
        require(amount > 0, "!amount");
        require(amount > maxMarketOrderTTL, "amount < maxMarketOrderTTL");
        maxTriggerOrderTTL = amount;
    }

    /// @notice Set duration after orders can be executed with chainlink
    /// @dev Only callable by governance
    /// @param amount Duration in seconds
    function setChainlinkCooldown(uint256 amount) external onlyGov {
        require(amount > 0, "!amount");
        chainlinkCooldown = amount;
    }

    /// @notice Adds order to storage
    /// @dev Only callable by other protocol contracts
    function add(Order memory order) external onlyContract returns (uint256) {
        uint256 nextOrderId = ++oid;
        order.orderId = nextOrderId;
        orders[nextOrderId] = order;
        userOrderIds[order.user].add(nextOrderId);
        if (order.orderType == 0) {
            marketOrderIds.add(order.orderId);
        } else {
            triggerOrderIds.add(order.orderId);
        }
        return nextOrderId;
    }

    /// @notice Removes order from store
    /// @dev Only callable by other protocol contracts
    /// @param orderId Order to remove
    function remove(uint256 orderId) external onlyContract {
        Order memory order = orders[orderId];
        if (order.size == 0) return;
        userOrderIds[order.user].remove(orderId);
        marketOrderIds.remove(orderId);
        triggerOrderIds.remove(orderId);
        delete orders[orderId];
    }

    /// @notice Updates `cancelOrderId` of `orderId`, e.g. TP order cancels a SL order and vice versa
    /// @dev Only callable by other protocol contracts
    /// @param orderId Order which cancels `cancelOrderId` on execution
    /// @param cancelOrderId Order to cancel when `orderId` executes
    function updateCancelOrderId(uint256 orderId, uint256 cancelOrderId) external onlyContract {
        Order storage order = orders[orderId];
        order.cancelOrderId = cancelOrderId;
    }

    /// @notice Returns a single order
    /// @param orderId Order to get
    function get(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    /// @notice Returns many orders
    /// @param orderIds Orders to get, e.g. [1, 2, 5]
    function getMany(uint256[] calldata orderIds) external view returns (Order[] memory) {
        uint256 length = orderIds.length;
        Order[] memory _orders = new Order[](length);

        for (uint256 i = 0; i < length; i++) {
            _orders[i] = orders[orderIds[i]];
        }

        return _orders;
    }

    /// @notice Returns market orders
    /// @param length Amount of market orders to return
    function getMarketOrders(uint256 length) external view returns (Order[] memory) {
        uint256 _length = marketOrderIds.length();
        if (length > _length) length = _length;

        Order[] memory _orders = new Order[](length);

        for (uint256 i = 0; i < length; i++) {
            _orders[i] = orders[marketOrderIds.at(i)];
        }

        return _orders;
    }

    /// @notice Returns trigger orders
    /// @param length Amount of trigger orders to return
    /// @param offset Offset to start
    function getTriggerOrders(uint256 length, uint256 offset) external view returns (Order[] memory) {
        uint256 _length = triggerOrderIds.length();
        if (length > _length) length = _length;

        Order[] memory _orders = new Order[](length);

        for (uint256 i = offset; i < length + offset; i++) {
            _orders[i] = orders[triggerOrderIds.at(i)];
        }

        return _orders;
    }

    /// @notice Returns orders of `user`
    function getUserOrders(address user) external view returns (Order[] memory) {
        uint256 length = userOrderIds[user].length();
        Order[] memory _orders = new Order[](length);

        for (uint256 i = 0; i < length; i++) {
            _orders[i] = orders[userOrderIds[user].at(i)];
        }

        return _orders;
    }

    /// @notice Returns amount of market orders
    function getMarketOrderCount() external view returns (uint256) {
        return marketOrderIds.length();
    }

    /// @notice Returns amount of trigger orders
    function getTriggerOrderCount() external view returns (uint256) {
        return triggerOrderIds.length();
    }

    /// @notice Returns order amount of `user`
    function getUserOrderCount(address user) external view returns (uint256) {
        return userOrderIds[user].length();
    }

    /// @notice Returns true if order is from `user`
    /// @param orderId order to check
    /// @param user user to check
    function isUserOrder(uint256 orderId, address user) external view returns (bool) {
        return userOrderIds[user].contains(orderId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../utils/Governable.sol";

/**
 * @title  RoleStore
 * @notice Role-based access control mechanism. Governance can grant and
 *         revoke roles dynamically via {grantRole} and {revokeRole}
 */
contract RoleStore is Governable {
    uint256 private constant swV = 1000101;
    // Libraries
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Set of roles
    EnumerableSet.Bytes32Set internal roles;

    // Role -> address
    mapping(bytes32 => EnumerableSet.AddressSet) internal roleMembers;

    constructor() Governable() {}

    /// @notice Grants `role` to `account`
    /// @dev Only callable by governance
    function grantRole(address account, bytes32 role) external onlyGov {
        // add role if not already present
        if (!roles.contains(role)) roles.add(role);

        require(roleMembers[role].add(account));
    }

    /// @notice Revokes `role` from `account`
    /// @dev Only callable by governance
    function revokeRole(address account, bytes32 role) external onlyGov {
        require(roleMembers[role].remove(account));

        // Remove role if it has no longer any members
        if (roleMembers[role].length() == 0) {
            roles.remove(role);
        }
    }

    /// @notice Returns `true` if `account` has been granted `role`
    function hasRole(address account, bytes32 role) external view returns (bool) {
        return roleMembers[role].contains(account);
    }

    /// @notice Returns number of roles
    function getRoleCount() external view returns (uint256) {
        return roles.length();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Governable
/// @notice Basic access control mechanism, gov has access to certain functions
contract Governable {
    uint256 private constant swV = 1000101;
    address public gov;

    event SetGov(address prevGov, address nextGov);

    /// @dev Initializes the contract setting the deployer address as governance
    constructor() {
        _setGov(msg.sender);
    }

    /// @dev Reverts if called by any account other than gov
    modifier onlyGov() {
        require(msg.sender == gov, "!gov");
        _;
    }

    /// @notice Sets a new governance address
    /// @dev Only callable by governance
    function setGov(address _gov) external onlyGov {
        _setGov(_gov);
    }

    /// @notice Sets a new governance address
    /// @dev Internal function without access restriction
    function _setGov(address _gov) internal {
        address prevGov = gov;
        gov = _gov;
        emit SetGov(prevGov, _gov);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Governable.sol";
import "../stores/RoleStore.sol";

/// @title Roles
/// @notice Role-based access control mechanism via onlyContract modifier
contract Roles is Governable {
    uint256 private constant swV = 1000101;

    bytes32 public constant CONTRACT = keccak256("CONTRACT");

    RoleStore public roleStore;

    /// @dev Initializes roleStore address
    constructor(RoleStore rs) Governable() {
        roleStore = rs;
    }

    /// @dev Reverts if caller address has not the contract role
    modifier onlyContract() {
        require(roleStore.hasRole(msg.sender, CONTRACT), "!contract-role");
        _;
    }
}