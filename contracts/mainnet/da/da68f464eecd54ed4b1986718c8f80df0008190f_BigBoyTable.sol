/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


pragma solidity ^0.8.0;




/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/structs/[email protected]


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
 */
library EnumerableSetUpgradeable {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
     * @dev Returns the number of values on the set. O(1).
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
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


pragma solidity ^0.8.0;



/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]


pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}


// File @openzeppelin/contracts/utils/structs/[email protected]


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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
     * @dev Returns the number of values on the set. O(1).
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
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}


// File contracts/IBigBoyTable.sol


pragma solidity ^0.8.0;

interface IBigBoyTable {
  event FreeRoomCreated(uint roomId, address roomOwner);
  event JoinedFreeRoom(uint roomId, address participant);
  event RoomCreated(uint roomId, address roomOwner);
  event RoomFinished(uint roomId, address payable[] winners, address payable[] unseenParticipants);
  event AgedActiveRoomDeleted(uint roomId);
  event RoomLocked(uint roomId);
  event StakeAdded(uint roomId, address participant);
  event EmergencyUnstake(uint roomId);
  enum ROOM_MODE { SINGLE, DEATHMATCH, TEAM }

  struct Room {
    uint id;
    uint participantCount;
    address payable[] participants;
    uint requiredStakeAmount;
    bool isStakeInNativeCurrency;
    address payable owner;
    ROOM_MODE roomMode;
    uint rounds; 
    bool canJoinForFree;
    uint createdAt;
    uint lockedAt;
    uint totalStake;
    string pwdRef;
    bytes32 collectionId;
  }
  
  function getMinParticipantsPerRoom() external pure returns(uint);
  function getMaxParticipantsPerRoom() external pure returns(uint);
  
  function createFreeRoom(
    uint maxParticipantCount,
    uint totalStake,
    bool isStakeInNativeCurrency,
    ROOM_MODE roomMode,
    string calldata pwdRef,
    bytes32 collectionId,
    uint rounds
  ) payable external;

  function createRoom(
    uint maxParticipantCount,
    uint requiredStakeAmount,
    bool isStakeInNativeCurrency,
    ROOM_MODE roomMode,
    string calldata pwdRef,
    bytes32 collectionId,
    uint rounds
  ) external;
  
  function joinFreeRoom(uint roomId) external;
  function stakeUSDC(uint roomId) external;
  function stakeNative(uint roomId) payable external;
  function lockRoom(uint roomId) external;
  function reportWinners(
    uint roomId, 
    address payable[] memory winners,
    address payable[] memory players
  ) external;
  function deleteAgedActiveRoom(uint roomId) external;
  function emergencyUnstake(uint roomId) external;

  function getRoom(uint roomId) external view returns(Room memory);
  function getActiveRoomCount() external view returns(uint);
  function getFinishedRoomCount() external view returns(uint);
  function getActiveRooms(uint, uint) external view returns (Room[] memory);
  function getFinishedRooms(uint, uint) external view returns(Room[] memory);
  
  function getRoomCreationPriceInUSDC() external view returns (uint);
  function setRoomCreationPriceInUSDC(uint) external;

  // we have no oracle for native gas cost in usdc so we set manually
  function getNative2USDCRatioInEtherUnits() external view returns(uint, uint);
  function setNative2USDCRatioInEtherUnits(uint, uint) external;

  function getMinimalStakeInNative() external view returns(uint);
  function getMinimalStakeInUSDC() external view returns(uint);
  function setMinimalStakeInUSDC(uint) external;

  function getLockingWindowInSeconds() external view returns(uint);
  function setLockingWindowInSeconds(uint) external;

  function getStakingWindowInSeconds() external view returns(uint);
  function setStakingWindowInSeconds(uint) external;

  function getWinningFeeInPercents() external view returns(uint);
  function setWinningFeeInPercents(uint) external;

  function getActiveRoomDeletionDelayInSeconds() external view returns(uint);
  function setActiveRoomDeletionDelayInSeconds(uint) external;

  function getMaxRounds() external pure returns(uint);
  function getExtractorRole() external view returns(bytes32);
  function getPauserRole() external pure returns(bytes32);
  function getEmergencyExtractorRole() external view returns(bytes32);

  function getFoundersAddress() external view returns(address payable);
  function setFoundersAddress(address payable) external;

}


// File contracts/BigBoyTable.sol


pragma solidity ^0.8.0;





contract BigBoyTable is IBigBoyTable, AccessControlEnumerableUpgradeable, PausableUpgradeable {
  using EnumerableSet for EnumerableSet.UintSet;

  struct InitializerParameters {
    address adminAccount;
    uint winningFeeInPercents;
    uint roomCreationPriceInUSDC;
    uint lockingWindowInSeconds;
    uint stakingWindowInSeconds;
    uint activeRoomDeletionDelayInSeconds;
    uint minimalStakeInUSDC;
    uint native2usdcNumerator;
    uint native2usdcDenominator;
    address payable foundersAddress;
    address usdc;
    address ecosystem;
  }

  using Counters for Counters.Counter;
  bytes32 private constant EXTRACTOR_ROLE = keccak256("EXTRACTOR_ROLE");
  bytes32 private constant EMERGENCY_EXTRACTOR_ROLE = keccak256("EMERGENCY_EXTRACTOR_ROLE");
  bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 private constant NONEXISTENT_COLLECTION_ID = 0x0;
  uint private constant MIN_PARTICIPANTS_PER_ROOM = 2;
  uint private constant MAX_PARTICIPANTS_PER_ROOM = 100;
  uint private constant _nativeCurrencyDecimals = 18; // ethereum-compatible networks
  uint private constant _usdcDecimals = 6;
  uint private constant MAX_ROUNDS = 24;

  Counters.Counter private _roomIds;
  
  address payable private _foundersAddress;
  IERC20 private _usdc;
  
  address private _ecosystem;
  // percent of SNK or Native, depending on room currency
  uint private _winningFeeInPercents;
  uint private _roomCreationPriceInUSDC;
  uint private _stakingWindowInSeconds;
  uint private _activeRoomDeletionDelayInSeconds;
  uint private _minimalStakeInUSDC;
  uint private _native2usdcNumerator;
  uint private _native2usdcDenominator;

  mapping(uint=>Room) private _rooms;
  EnumerableSet.UintSet private _activeRoomIds;
  EnumerableSet.UintSet private _finishedRoomIds;
  uint private _lockingWindowInSeconds;

  modifier onlyActiveRoom(uint roomId) {
    require(_activeRoomIds.contains(roomId), 'BBT: room is not active');
    _;
  }

  modifier whenStakePossible(uint roomId) {
    require(_activeRoomIds.contains(roomId), 'BBT: room is not active');
    require(
      _rooms[roomId].lockedAt > 0, 'BBT: room is not locked'
    );
    require(
      block.timestamp <= _rooms[roomId].lockedAt + _stakingWindowInSeconds,
      'BBT: staking window closed'
    );
    require(
      _rooms[roomId].participantCount < _rooms[roomId].participants.length,
      'BBT: no more participants possible'
    );
    _;
  }

  function getMaxRounds() external override pure returns(uint) {
    return MAX_ROUNDS;
  }

  function getExtractorRole() external override pure returns(bytes32) {
    return EXTRACTOR_ROLE;
  }

  function getEmergencyExtractorRole() external override pure returns(bytes32) {
    return EMERGENCY_EXTRACTOR_ROLE;
  }

  function getPauserRole() external override pure returns(bytes32) {
    return PAUSER_ROLE;
  }


  function initialize(InitializerParameters calldata params) initializer public {
    __AccessControlEnumerable_init();
    __Pausable_init();
    
    _setupRole(DEFAULT_ADMIN_ROLE, params.adminAccount);
    _setupRole(EXTRACTOR_ROLE, params.adminAccount);

    _foundersAddress = params.foundersAddress;
    _usdc = IERC20(params.usdc);
    _ecosystem = params.ecosystem;
    
    _winningFeeInPercents = params.winningFeeInPercents;
    _roomCreationPriceInUSDC = params.roomCreationPriceInUSDC;
    _lockingWindowInSeconds = params.lockingWindowInSeconds;
    _stakingWindowInSeconds = params.stakingWindowInSeconds;
    _activeRoomDeletionDelayInSeconds = params.activeRoomDeletionDelayInSeconds;
    _minimalStakeInUSDC = params.minimalStakeInUSDC;
    _native2usdcNumerator = params.native2usdcNumerator;
    _native2usdcDenominator = params.native2usdcDenominator;
    
  }

  function getMaxParticipantsPerRoom() external override pure returns(uint) {
    return MAX_PARTICIPANTS_PER_ROOM;
  }

  function getMinParticipantsPerRoom() external override pure returns(uint) {
    return MIN_PARTICIPANTS_PER_ROOM;
  }

  function getActiveRoomDeletionDelayInSeconds() external override view returns(uint) {
    return _activeRoomDeletionDelayInSeconds;
  }

  function setActiveRoomDeletionDelayInSeconds(uint activeRoomDeletionDelayInSeconds) 
    external override onlyRole(PAUSER_ROLE) 
  {
    _activeRoomDeletionDelayInSeconds = activeRoomDeletionDelayInSeconds;
  }

  function getWinningFeeInPercents() external override view returns(uint) {
    return _winningFeeInPercents;
  }

  function setWinningFeeInPercents(uint winningFeeInPercents) 
    external override onlyRole(PAUSER_ROLE) 
  {
    _winningFeeInPercents = winningFeeInPercents;
  }  

  function getLockingWindowInSeconds() external override view returns(uint) {
    return _lockingWindowInSeconds;
  }

  function setLockingWindowInSeconds(uint lockingWindowInSeconds) 
    external override onlyRole(PAUSER_ROLE) 
  {
    _lockingWindowInSeconds = lockingWindowInSeconds;
  } 

  function getStakingWindowInSeconds() external override view returns(uint) {
    return _stakingWindowInSeconds;
  }

  function setStakingWindowInSeconds(uint stakingWindowInSeconds) 
    external override onlyRole(PAUSER_ROLE) 
  {
    _stakingWindowInSeconds = stakingWindowInSeconds;
  } 

  function getRoomCreationPriceInUSDC() external override view returns(uint) {
    return _roomCreationPriceInUSDC;
  }

  function setRoomCreationPriceInUSDC(uint roomCreationPriceInUSDC) 
    external override onlyRole(PAUSER_ROLE) 
  {
    _roomCreationPriceInUSDC = roomCreationPriceInUSDC;
  }

  function getMinimalStakeInUSDC() external override view returns(uint) {
    return _minimalStakeInUSDC;
  }

  function setMinimalStakeInUSDC(uint minimalStakeInUSDC) 
    external override onlyRole(PAUSER_ROLE)
  {
    _minimalStakeInUSDC = minimalStakeInUSDC; 
  }

  function _getMinimalStakeInNative() internal view returns(uint) {
    return _convertUSDC2Native(_minimalStakeInUSDC);
  }

  function getMinimalStakeInNative() external override view returns(uint) {
    return _getMinimalStakeInNative();
  }

  function _convertUSDC2Native(uint usdc) internal view returns(uint native) {
    // numerator and denominator are for ETHER units of each token
    native = usdc * _native2usdcNumerator / _native2usdcDenominator * 10**_nativeCurrencyDecimals / 10**_usdcDecimals;
  }

  function getNative2USDCRatioInEtherUnits() external override view returns(uint, uint) {
    return (_native2usdcNumerator, _native2usdcDenominator);
  }

  function setNative2USDCRatioInEtherUnits(uint numerator, uint denominator) 
    external override onlyRole(PAUSER_ROLE)
  {
    _native2usdcNumerator = numerator;
    _native2usdcDenominator = denominator;
  }

  
  
  function _createRoom(
    uint maxParticipantCount,
    uint requiredStakeAmount,
    bool isStakeInNativeCurrency,
    ROOM_MODE roomMode,
    string calldata pwdRef,
    bytes32 collectionId,
    uint rounds
  ) internal returns(uint) {
    require(
      roomMode == ROOM_MODE.SINGLE || roomMode == ROOM_MODE.DEATHMATCH, 
      "BBT: unsupported mode"
    );
    require(
      rounds > 0 && rounds <= MAX_ROUNDS,
      "BBT: invalid rounds"
    );
    require(
      maxParticipantCount >= 2 && 
      maxParticipantCount <= MAX_PARTICIPANTS_PER_ROOM, 
      "BBT: invalid max number of participants"
    );

    require(
      isStakeInNativeCurrency == false && requiredStakeAmount >= _minimalStakeInUSDC ||
      isStakeInNativeCurrency == true && requiredStakeAmount >= _getMinimalStakeInNative(),
      "BBT: requiredStake is less than minimal"
    );
    ///@dev Creation fee is taken ONLY in SNK
    require(
      _usdc.transferFrom(msg.sender, _ecosystem, _roomCreationPriceInUSDC),
      'BBT: Not enough USDC for room creation'
    );
    
    _roomIds.increment();
    uint roomId = _roomIds.current();
   _rooms[roomId] = Room({
      id: roomId,
      participantCount: 0,
      participants: new address payable[](maxParticipantCount),
      requiredStakeAmount: requiredStakeAmount,
      isStakeInNativeCurrency: isStakeInNativeCurrency,
      owner: payable(msg.sender),
      roomMode: roomMode,
      rounds: rounds,
      canJoinForFree: false,
      createdAt: block.timestamp,
      lockedAt: 0,
      totalStake: 0,
      pwdRef: pwdRef,
      collectionId: collectionId
    });
    _activeRoomIds.add(roomId);
    return roomId;
  }
  
  function createFreeRoom(
    uint maxParticipantCount,
    uint totalStake,
    bool isStakeInNativeCurrency,
    ROOM_MODE roomMode,
    string calldata pwdRef,
    bytes32 collectionId,
    uint rounds
  ) payable external override {
    require(
      isStakeInNativeCurrency == false && _usdc.transferFrom(msg.sender, address(this), totalStake) ||
      isStakeInNativeCurrency == true && msg.value == totalStake,
      'BBT: not enough funds for stake'
    );
    uint roomId = _createRoom(
      maxParticipantCount,
      totalStake,
      isStakeInNativeCurrency,
      roomMode,
      pwdRef,
      collectionId,
      rounds
    );
    Room storage room = _rooms[roomId]; 
    room.totalStake = totalStake; 
    room.canJoinForFree = true;
    emit FreeRoomCreated(roomId, msg.sender);
  }

  function createRoom(
    uint maxParticipantCount,
    uint requiredStakeAmount,
    bool isStakeInNativeCurrency,
    ROOM_MODE roomMode,
    string calldata pwdRef,
    bytes32 collectionId,
    uint rounds
  ) external override
  {
    uint roomId = _createRoom(
      maxParticipantCount, 
      requiredStakeAmount, 
      isStakeInNativeCurrency, 
      roomMode,
      pwdRef,
      collectionId,
      rounds
    );
    emit RoomCreated(roomId, msg.sender); 
  }

  /// @dev After room locking, the stakes are possible during staking window.
  function lockRoom(uint roomId) external override onlyActiveRoom(roomId) {
    Room storage room = _rooms[roomId];
    require(msg.sender == room.owner, 'BBT: not a room owner');
    require(room.lockedAt == 0, 'BBT: room already locked');
    require(block.timestamp <= room.createdAt + _lockingWindowInSeconds, 'BBT: locking window is closed');
    room.lockedAt = block.timestamp;
    emit RoomLocked(roomId);
  } 

  function joinFreeRoom(uint roomId) whenStakePossible(roomId)
    external override 
  {
    Room storage room = _rooms[roomId];
    require(room.canJoinForFree == true, 'BBT: room is not free');
    room.participants[room.participantCount] = payable(msg.sender);
    room.participantCount += 1;
    emit JoinedFreeRoom(roomId, msg.sender); 
  }

  function stakeUSDC(uint roomId) 
    external override whenStakePossible(roomId) 
  {
    Room storage room = _rooms[roomId];
    require(
      room.isStakeInNativeCurrency == false,
      'BBT: stakes should be in native currency'
    );
    require(
      _usdc.transferFrom(msg.sender, address(this), room.requiredStakeAmount),
      'BBT: not enough SNK for stake'
    );
    
    room.participants[room.participantCount] = payable(msg.sender);
    room.participantCount += 1;
    room.totalStake += room.requiredStakeAmount;
    emit StakeAdded(roomId, msg.sender);
  }

  function stakeNative(uint roomId) 
    payable external override whenStakePossible(roomId)
  {
    Room storage room = _rooms[roomId];
    require(
      room.isStakeInNativeCurrency == true,
      'BBT: stakes should be in SNK'
    );
    require(
      msg.value == room.requiredStakeAmount,
      'BBT: not enough native currency for stake'
    );
    room.participants[room.participantCount] = payable(msg.sender);
    room.participantCount += 1;
    room.totalStake += room.requiredStakeAmount;
    emit StakeAdded(roomId, msg.sender);
  } 


  function _areParticipants(Room memory room, address payable[] memory winners) 
    internal pure returns(bool) 
  {
    for (uint i=0; i<winners.length; i++) {
      bool found = false;
      for (uint j=0; j<room.participantCount; j++) {
        if (winners[i] == room.participants[j]) {
          found = true;
          break;
        }
      }
      if (found == false) {
        return false;
      }
    }
    return true;
  }
  
  function _arrayDifference(
    address payable[] memory arr1, 
    address payable[] memory arr2
  ) internal pure returns(address payable[] memory) 
  {
    address payable[] memory a1 = arr1;
    address payable[] memory a2 = arr2;
    if (arr1.length < arr2.length) {
      a2 = arr1;
      a1 = arr2;
    }
    uint maxlen = a1.length + a2.length;
    address payable[] memory d = new address payable[](maxlen);
    uint k = 0;
    for (uint i=0; i<a1.length; i++) {
      bool found = false;
      for (uint j=0; j<a2.length; j++) {
        if (a1[i] == a2[j]) {
          found = true;
          break;
        }
      }
      if (found == false) {
        d[k++] = a1[i];
      }
    }
    address payable[] memory result = new address payable[](k);
    for (uint i=0; i<k; i++) {
      result[i] = d[i];
    }
    return result;
  }

  /**
    @dev
    Not all participants may successfully join the game (the server may not see an event of the stake from one of them).
    So we return the stake to participants who staked but not played. 
   */
  function reportWinners(
    uint roomId, 
    address payable[] memory winners,
    address payable[] memory players  
  ) onlyActiveRoom(roomId) onlyRole(EXTRACTOR_ROLE) external override  
  {
    Room memory room = _rooms[roomId];
    require(room.lockedAt > 0, "BBT: cannot report winners before room is locked");
    require(
      block.timestamp > room.lockedAt + _stakingWindowInSeconds,
      "BBT: cannot report winners before staking window is closed"
    );

    require(
      players.length >= MIN_PARTICIPANTS_PER_ROOM && // condition for GS to start the game
      players.length <= room.participantCount,
      "BBT: invalid number of players"
    );

    require(
      winners.length >= 1 && 
      winners.length <= players.length, 
      "BBT: invalid number of winners"
    );
    
    require(
      _areParticipants(room, winners) == true, 
      'BBT: one or more of reported winners are not participant'
    );

    require(
      _areParticipants(room, players) == true, 
      'BBT: one or more of reported players are not participant'
    );

    // For free rooms, we return stakes to the participants who were not seen by GS.
    uint returnedStake = 0;
    address payable[] memory unseenParticipants;
    if (
      _rooms[roomId].canJoinForFree == false && 
      players.length < room.participantCount
    ) 
    { 
      unseenParticipants = _arrayDifference(players, room.participants);
      returnedStake = room.requiredStakeAmount * unseenParticipants.length;
      room.totalStake -= returnedStake;
      for (uint i=0; i<unseenParticipants.length; i++) {
        if (room.isStakeInNativeCurrency == false) {
          _usdc.transfer(unseenParticipants[i], room.requiredStakeAmount);
        } else {
          unseenParticipants[i].transfer(room.requiredStakeAmount);
        }
      }
    }

    uint winningFeeAmount = room.totalStake * _winningFeeInPercents / 100;
    uint revshareAmount = 0;
    
    uint prizeAmount = (room.totalStake - winningFeeAmount - revshareAmount)/winners.length;

    /// @dev Send winning fee to Foundation.
    if (room.isStakeInNativeCurrency == false) {
      _usdc.transfer(_foundersAddress, winningFeeAmount);
    } else {
      (bool sent,) = _foundersAddress.call{value: winningFeeAmount}("");
      require(sent, "BBT: winning fee was not sent to founders");
    }

    /// @dev Send revshare if collection exists and active and revshareAmount > 0 
    

    /// @dev Send prize to the winners.
    for (uint i=0; i<winners.length; i++) {
      if (room.isStakeInNativeCurrency == false) {
        _usdc.transfer(winners[i], prizeAmount);
      } else {
        winners[i].transfer(prizeAmount);
      }
    }

    _activeRoomIds.remove(roomId);
    _finishedRoomIds.add(roomId);
    emit RoomFinished(roomId, winners, unseenParticipants);
  }

  function getRoom(uint roomId) external override view returns(Room memory) {
    require(
      _activeRoomIds.contains(roomId) || _finishedRoomIds.contains(roomId), 
      "BBT: invalid room id"
    );
    return _rooms[roomId];
  }

  function getActiveRoomCount() external override view returns(uint) {
    return _activeRoomIds.length();
  }

  function getFinishedRoomCount() external override view returns(uint) {
    return _finishedRoomIds.length();
  }

  function getActiveRooms(uint startIdx, uint endIdx) external override view 
    returns(Room[] memory)
  {
    require(
      startIdx < endIdx && endIdx <= _activeRoomIds.length(), 
      "BBT: invalid indexes"
    );
    Room[] memory slice = new Room[](endIdx-startIdx);
    for (uint i=startIdx; i<endIdx; i++) {
      slice[i-startIdx] = _rooms[_activeRoomIds.at(i)];
    } 
    return slice;
  }

  function getFinishedRooms(uint startIdx, uint endIdx) external override view 
    returns(Room[] memory)
  {
    require(
      startIdx < endIdx && endIdx <= _finishedRoomIds.length(), 
      "BBT: invalid indexes"
    );
    Room[] memory slice = new Room[](endIdx-startIdx);
    for (uint i=startIdx; i<endIdx; i++) {
      slice[i-startIdx] = _rooms[_finishedRoomIds.at(i)];
    } 
    return slice;
  }

  function deleteAgedActiveRoom(uint roomId) external override onlyActiveRoom(roomId) {
    require(
      block.timestamp > _rooms[roomId].createdAt + _activeRoomDeletionDelayInSeconds,
      "BBT: room is not aged enough"
    );
    Room storage room = _rooms[roomId];
    if (room.canJoinForFree == true) { // free room, return stake to the room creator
      if (room.isStakeInNativeCurrency == true) {
        room.owner.transfer(room.totalStake);
      } else {
        _usdc.transfer(room.owner, room.totalStake);
      }
    } else { // non-free room, return stakes to all participants (stakers)
      if (room.isStakeInNativeCurrency == true) {
        for (uint i=0; i<room.participantCount; i++) {
          room.participants[i].transfer(room.requiredStakeAmount);
        }
      } else {
        for (uint i=0; i<room.participantCount; i++) {
          _usdc.transfer(room.participants[i], room.requiredStakeAmount);
        }
      }
    }

    _activeRoomIds.remove(roomId);
    emit AgedActiveRoomDeleted(roomId);
  }

  function emergencyUnstake(uint roomId) 
    onlyActiveRoom(roomId) onlyRole(EMERGENCY_EXTRACTOR_ROLE) external override
  {
    Room storage room = _rooms[roomId];
    if (room.isStakeInNativeCurrency == false) {
      if (room.canJoinForFree == false) { // non free room, participants made stakes
        /// @dev Loop gas limit is prevents as during creation participantCount is limited.
        for (uint i=0; i<room.participantCount; i++) {
          _usdc.transfer(room.participants[i], room.requiredStakeAmount);
        }
      } 
    } else {
      if (room.canJoinForFree == false) {
        for (uint i=0; i<room.participantCount; i++) {
          room.participants[i].transfer(room.requiredStakeAmount);
        }
      }
    }

    room.createdAt = block.timestamp;
    room.lockedAt = 0;
    room.participantCount = 0;
    room.totalStake = 0;
    emit EmergencyUnstake(roomId);
  }

  function getFoundersAddress() external override view returns(address payable) {
    return _foundersAddress;
  }

  function setFoundersAddress(address payable foundersAddress) onlyRole(PAUSER_ROLE) external override {
    _foundersAddress = foundersAddress;
  }
}