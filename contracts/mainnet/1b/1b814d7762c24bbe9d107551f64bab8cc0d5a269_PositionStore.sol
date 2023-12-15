// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";

import './Roles.sol';

/// @title PositionStore
/// @notice Persistent storage for Positions.sol
contract PositionStore is Roles {
    // Libraries
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Position struct
    struct Position {
        address user; // User that submitted the position
        address asset; // Asset address, e.g. address(0) for ETH
        string market; // Market this position was submitted on
        bool isLong; // Wether the position is long or short
        uint256 size; // The position's size (margin * leverage)
        uint256 margin; // Collateral tied to this position. In wei
        int256 fundingTracker; // Market funding rate tracker
        uint256 price; // The position's average execution price
        uint256 timestamp; // Time at which the position was created
    }

    // Constants
    uint256 public constant BPS_DIVIDER = 10000;
    uint256 public constant MAX_KEEPER_FEE_SHARE = 2000; // 20%

    // State variables
    uint256 public removeMarginBuffer = 1000;
    uint256 public keeperFeeShare = 500;

    // Mappings
    mapping(address => mapping(string => uint256)) private OI; // open interest. market => asset => amount
    mapping(address => mapping(string => uint256)) private OILong; // open interest. market => asset => amount
    mapping(address => mapping(string => uint256)) private OIShort; // open interest. market => asset => amount]

    mapping(bytes32 => Position) private positions; // key = asset,user,market
    EnumerableSet.Bytes32Set private positionKeys; // [position keys..]
    mapping(address => EnumerableSet.Bytes32Set) private positionKeysForUser; // user => [position keys..]

    constructor(RoleStore rs) Roles(rs) {}

    /// @notice Updates `removeMarginBuffer`
    /// @dev Only callable by governance
    /// @param bps new `removeMarginBuffer` in bps
    function setRemoveMarginBuffer(uint256 bps) external onlyGov {
        require(bps < BPS_DIVIDER, '!bps');
        removeMarginBuffer = bps;
    }

    /// @notice Sets keeper fee share
    /// @dev Only callable by governance
    /// @param bps new `keeperFeeShare` in bps
    function setKeeperFeeShare(uint256 bps) external onlyGov {
        require(bps <= MAX_KEEPER_FEE_SHARE, '!keeper-fee-share');
        keeperFeeShare = bps;
    }

    /// @notice Adds new position or updates exisiting one
    /// @dev Only callable by other protocol contracts
    /// @param position Position to add/update
    function addOrUpdate(Position memory position) external onlyContract {
        bytes32 key = _getPositionKey(position.user, position.asset, position.market);
        positions[key] = position;
        positionKeysForUser[position.user].add(key);
        positionKeys.add(key);
    }

    /// @notice Removes position
    /// @dev Only callable by other protocol contracts
    function remove(address user, address asset, string calldata market) external onlyContract {
        bytes32 key = _getPositionKey(user, asset, market);
        positionKeysForUser[user].remove(key);
        positionKeys.remove(key);
        delete positions[key];
    }

    /// @notice Increments open interest
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked by Positions.increasePosition
    function incrementOI(address asset, string calldata market, uint256 amount, bool isLong) external onlyContract {
        OI[asset][market] += amount;
        if (isLong) {
            OILong[asset][market] += amount;
        } else {
            OIShort[asset][market] += amount;
        }
    }

    /// @notice Decrements open interest
    /// @dev Only callable by other protocol contracts
    /// @dev Invoked whenever a position is closed or decreased
    function decrementOI(address asset, string calldata market, uint256 amount, bool isLong) external onlyContract {
        OI[asset][market] = OI[asset][market] <= amount ? 0 : OI[asset][market] - amount;
        if (isLong) {
            OILong[asset][market] = OILong[asset][market] <= amount ? 0 : OILong[asset][market] - amount;
        } else {
            OIShort[asset][market] = OIShort[asset][market] <= amount ? 0 : OIShort[asset][market] - amount;
        }
    }

    /// @notice Returns open interest of `asset` and `market`
    function getOI(address asset, string calldata market) external view returns (uint256) {
        return OI[asset][market];
    }

    /// @notice Returns open interest of long positions
    function getOILong(address asset, string calldata market) external view returns (uint256) {
        return OILong[asset][market];
    }

    /// @notice Returns open interest of short positions
    function getOIShort(address asset, string calldata market) external view returns (uint256) {
        return OIShort[asset][market];
    }

    /// @notice Returns position of `user`
    /// @param asset Base asset of position
    /// @param market Market this position was submitted on
    function getPosition(address user, address asset, string memory market) public view returns (Position memory) {
        bytes32 key = _getPositionKey(user, asset, market);
        return positions[key];
    }

    /// @notice Returns positions of `users`
    /// @param assets Base assets of positions
    /// @param markets Markets of positions
    function getPositions(
        address[] calldata users,
        address[] calldata assets,
        string[] calldata markets
    ) external view returns (Position[] memory) {
        uint256 length = users.length;
        Position[] memory _positions = new Position[](length);

        for (uint256 i = 0; i < length; i++) {
            _positions[i] = getPosition(users[i], assets[i], markets[i]);
        }

        return _positions;
    }

    /// @notice Returns positions
    /// @param keys Position keys
    function getPositions(bytes32[] calldata keys) external view returns (Position[] memory) {
        uint256 length = keys.length;
        Position[] memory _positions = new Position[](length);

        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[keys[i]];
        }

        return _positions;
    }

    /// @notice Returns number of positions
    function getPositionCount() external view returns (uint256) {
        return positionKeys.length();
    }

    /// @notice Returns `length` amount of positions starting from `offset`
    function getPositions(uint256 length, uint256 offset) external view returns (Position[] memory) {
        uint256 _length = positionKeys.length();
        if (length > _length) length = _length;
        Position[] memory _positions = new Position[](length);

        for (uint256 i = offset; i < length + offset; i++) {
            _positions[i] = positions[positionKeys.at(i)];
        }

        return _positions;
    }

    /// @notice Returns all positions of `user`
    function getUserPositions(address user) external view returns (Position[] memory) {
        uint256 length = positionKeysForUser[user].length();
        Position[] memory _positions = new Position[](length);

        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[positionKeysForUser[user].at(i)];
        }

        return _positions;
    }

    /// @dev Returns position key by hashing (user, asset, market)
    function _getPositionKey(address user, address asset, string memory market) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, asset, market));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import './Governable.sol';
import './RoleStore.sol';

/// @title Roles
/// @notice Role-based access control mechanism via onlyContract modifier
contract Roles is Governable {
    bytes32 public constant CONTRACT = keccak256('CONTRACT');

    RoleStore public roleStore;

    /// @dev Initializes roleStore address
    constructor(RoleStore rs) Governable() {
        roleStore = rs;
    }

    /// @dev Reverts if caller address has not the contract role
    modifier onlyContract() {
        require(roleStore.hasRole(msg.sender, CONTRACT), '!contract-role');
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title Governable
/// @notice Basic access control mechanism, gov has access to certain functions
contract Governable {
    address public gov;

    event SetGov(address prevGov, address nextGov);

    /// @dev Initializes the contract setting the deployer address as governance
    constructor() {
        _setGov(msg.sender);
    }

    /// @dev Reverts if called by any account other than gov
    modifier onlyGov() {
        require(msg.sender == gov, '!gov');
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import './Governable.sol';

/**
 * @title  RoleStore
 * @notice Role-based access control mechanism. Governance can grant and
 *         revoke roles dynamically via {grantRole} and {revokeRole}
 */
contract RoleStore is Governable {
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