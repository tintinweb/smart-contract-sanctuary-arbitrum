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
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

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
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
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
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721Mint {
    /**
     * @dev Safely mints a token to an address.
     * @param to The address that will own the minted token.
     * @return tokenId The token ID.
     */
    function safeMint(address to) external returns (uint256 tokenId);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFeeTreasury {
    /**
     * @dev Returns the treasury address.
     * @return treasury Address of the treasury.
     */
    function getFeeTreasury() external view returns (address treasury);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface INodeSaleInit {
    function init(address admin, address _token, address _feeTreasury, uint96 _fee, uint96 _defaultReferralDiscount) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC721Mint.sol";
import "./INodeSaleInit.sol";
import "./IFeeTreasury.sol";

/**
 * @title NodeSale contract.
 * @dev This contract is for selling nodes, which are presented as NFTs.
 * The contract let's admin create tiers with different prices and quantities.
 * This contract is intended to be used as clone from `NodeSaleFactory` contract.
 */
contract NodeSale is INodeSaleInit, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    error AlreadyInitialized();
    error InvalidPrice();
    error InvalidQuantity();
    error TierNotFound();
    error TierMustBeWhitelistOnly();
    error ArraySizesDoesNotMatch();
    error UserNotWhitelisted();
    error QuantityExceeded();
    error UserQuantityExceeded();
    error TransferFailed();
    error ReferralFeeExceeded();
    error ReferralDiscountExceeded();
    error ReferralCannotBeBuyer();
    error WhitelistQuantityMoreThanTierQuantity();

    /// 100% in basis points.
    uint96 public constant PERCENTAGE = 10000;
    /// Max referral fee in basis points. (%50)
    uint96 public constant MAX_REFERRAL_FEE = 5000;
    /// Max referral discount in basis points. (%50)
    uint96 public constant MAX_REFERRAL_DISCOUNT = 5000;

    /**
     * @dev This struct holds information about the tier.
     * @param price Price of the node.
     * @param quantity Quantity of the nodes.
     * @param quantityWhitelist Quantity of the nodes for whitelist (must be lower than `quantity`).
     * @param quantityPerUser Quantity of the nodes per user.
     * @param totalSold Total sold nodes.
     * @param whitelistSold Total sold nodes for whitelist.
     * @param whitelistOnly If the tier is only for whitelisted users.
     */
    struct Tier {
        uint256 price;
        uint64 quantity;
        uint64 quantityWhitelist;
        uint64 quantityPerUser;
        uint64 totalSold;
        uint64 whitelistSold;
        bool whitelistOnly;
    }

    /**
     * @dev This struct holds information about the referral.
     * @param discountAmount The discount amount.
     * @param discountAmountUsed The discount amount used.
     * @param discountPercentage The discount percentage (in basis points).
     * @param referralFee The referral fee (in basis points).
     */
    struct ReferralStruct {
        uint64 discountAmount;
        uint64 discountAmountUsed;
        uint64 discountPercentage;
        uint64 referralFee;
    }

    /// Token interface.
    IERC721Mint public token;
    /// FeeTreasury interface.
    IFeeTreasury public feeTreasury;
    /// Next tier number.
    uint256 public nextTier;
    /// Fee (in basis points).
    uint96 public fee;
    /// Referral fee (in basis points).
    uint96 public referralFee;
    /// Default referral discount percentage (in basis points).
    uint96 public defaultReferralDiscount;
    // A mapping of the tier number to the tier details
    mapping(uint256 => Tier) public tiers;
    // A mapping of the user's address to the tier id to the tier price
    mapping(address => mapping(uint256 => uint256)) public userSpecificPrice;
    // A mapping of the user's address to the tier id to the user quantity
    mapping(address => mapping(uint256 => uint64)) public userSpecificQuantity;
    // A mapping of the user's address to the tier id to the user bought quantity
    mapping(address => mapping(uint256 => uint64)) public userTierQuantity;
    // A mapping of the token id to the tier id
    mapping(uint256 => uint256) public tokenTier;
    // A mapping of the referral address to the referral struct
    mapping(address => ReferralStruct) public referralStruct;

    /// Is contract initialized
    bool private _initialized;
    // A mapping of the tier id to the list of whitelisted addresses
    mapping(uint256 => EnumerableSet.AddressSet) private _tierWhitelist;

    /**
     * @dev Event emitted when a new tier is added.
     * @param tierId The id of the tier.
     */
    event TierAdded(uint256 indexed tierId);
    /**
     * @dev Event emitted when a tier is updated.
     * @param tierId The id of the tier.
     */
    event TierUpdated(uint256 indexed tierId);
    /**
     * @dev Event emitted when a node is purchased.
     * @param user The address of the user.
     * @param tierId The id of the tier.
     * @param amount The amount of the purchase.
     */
    event Purchase(address indexed user, uint256 indexed tierId, uint64 amount);

    function init(
        address admin,
        address _token,
        address _feeTreasury,
        uint96 _fee,
        uint96 _defaultReferralDiscount
    ) external override {
        if (_initialized) revert AlreadyInitialized();
        _initialized = true;

        token = IERC721Mint(_token);
        feeTreasury = IFeeTreasury(_feeTreasury);
        fee = _fee;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _setDefaultReferralDiscount(_defaultReferralDiscount);
    }

    /**
     * @dev Purchase a node.
     * @param _tierId The id of the tier.
     * @param amount The amount of the purchase.
     * @param referral The referral address.
     * @notice The referral address must have at least 1 node(NFT) to receive fee.
     * Also, this function will revert if amount is too much due to gas limit.
     */
    function purchase(uint256 _tierId, uint64 amount, address referral) external payable {
        Tier memory tier = tiers[_tierId];
        if (tier.price == 0) revert TierNotFound();
        if (tier.whitelistOnly && !_tierWhitelist[_tierId].contains(msg.sender)) revert UserNotWhitelisted();
        if (tier.whitelistOnly && tier.whitelistSold + amount > tier.quantityWhitelist) revert QuantityExceeded();
        if (tier.totalSold + amount > tier.quantity) revert QuantityExceeded();
        if (userTierQuantity[msg.sender][_tierId] + amount > getUserSpecificQuantity(msg.sender, _tierId))
            revert UserQuantityExceeded();
        if (msg.sender == referral) revert ReferralCannotBeBuyer();
        (uint256 price, uint64 amountReferralDiscount, ) = getPrice(msg.sender, referral, _tierId, amount);
        if (msg.value != price) revert InvalidPrice();

        tiers[_tierId].totalSold += amount;
        if (tier.whitelistOnly) tiers[_tierId].whitelistSold += amount;
        userTierQuantity[msg.sender][_tierId] += amount;
        referralStruct[referral].discountAmountUsed += amountReferralDiscount;

        _takeFeeTreasury(price);
        // take referral fee if referral struct is set or referral is NFT owner (if referral struct is set, no need to check if referral is NFT owner)
        if (
            referralStruct[referral].referralFee != 0 ||
            (referralFee > 0 && IERC721(address(token)).balanceOf(referral) > 0)
        ) _takeFeeReferral(price, referral);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = token.safeMint(msg.sender);
            tokenTier[tokenId] = _tierId;
        }

        emit Purchase(msg.sender, _tierId, amount);
    }

    /**
     * @dev Add multiple tiers at once.
     * @param _price The price list of the node.
     * @param _quantity The quantity list of the nodes.
     * @param _quantityWhitelist The quantity list of the nodes for whitelist (must be lower than `quantity`)
     * @param _quantityPerUser The quantity list of the nodes per user.
     * @param _whitelistOnly List if the tier is only for whitelisted users.
     */
    function addTierMulti(
        uint256[] calldata _price,
        uint64[] calldata _quantity,
        uint64[] calldata _quantityWhitelist,
        uint64[] calldata _quantityPerUser,
        bool[] calldata _whitelistOnly
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            _price.length != _quantity.length ||
            _price.length != _quantityWhitelist.length ||
            _price.length != _quantityPerUser.length ||
            _price.length != _whitelistOnly.length
        ) revert ArraySizesDoesNotMatch();

        for (uint256 i = 0; i < _price.length; i++) {
            if (_price[i] == 0) revert InvalidPrice();
            if (_quantity[i] == 0) revert InvalidQuantity();
            if (_quantityWhitelist[i] > _quantity[i]) revert WhitelistQuantityMoreThanTierQuantity();

            _addTier(
                nextTier + i,
                _price[i],
                _quantity[i],
                _quantityWhitelist[i],
                _quantityPerUser[i],
                _whitelistOnly[i]
            );
        }

        nextTier += _price.length;
    }

    /**
     * @dev Add a new tier.
     * @param _price The price of the node.
     * @param _quantity The quantity of the nodes.
     * @param _quantityWhitelist The quantity of the nodes for whitelist (must be lower than `quantity`).
     * @param _quantityPerUser The quantity of the nodes per user.
     * @param _whitelistOnly If the tier is only for whitelisted users.
     */
    function addTier(
        uint256 _price,
        uint64 _quantity,
        uint64 _quantityWhitelist,
        uint64 _quantityPerUser,
        bool _whitelistOnly
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_price == 0) revert InvalidPrice();
        if (_quantity == 0) revert InvalidQuantity();
        if (_quantityWhitelist > _quantity) revert WhitelistQuantityMoreThanTierQuantity();

        uint256 tierId = nextTier;
        nextTier++;

        _addTier(tierId, _price, _quantity, _quantityWhitelist, _quantityPerUser, _whitelistOnly);
    }

    /**
     * @dev Update a tier.
     * @param _tierId The id of the tier.
     * @param _price The price of the node.
     * @param _quantity The quantity of the nodes.
     * @param _quantityPerUser The quantity of the nodes per user.
     * @param _whitelistOnly If the tier is only for whitelisted users.
     * @notice Whitelist quantity will not be updated.
     */
    function updateTier(
        uint256 _tierId,
        uint256 _price,
        uint64 _quantity,
        uint64 _quantityPerUser,
        bool _whitelistOnly
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tiers[_tierId].price == 0) revert TierNotFound();
        if (_price == 0) revert InvalidPrice();
        if (_quantity == 0) revert InvalidQuantity();

        Tier storage tier = tiers[_tierId];
        tier.price = _price;
        tier.quantity = _quantity;
        tier.quantityPerUser = _quantityPerUser;
        tier.whitelistOnly = _whitelistOnly;

        emit TierUpdated(_tierId);
    }

    /**
     * @dev Add addresses to the whitelist.
     * @param _tierId The id of the tier.
     * @param _addresses The address list to add.
     */
    function addWhitelist(uint256 _tierId, address[] calldata _addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tiers[_tierId].price == 0) revert TierNotFound();
        if (!tiers[_tierId].whitelistOnly) revert TierMustBeWhitelistOnly();

        for (uint256 i = 0; i < _addresses.length; i++) {
            _tierWhitelist[_tierId].add(_addresses[i]);
        }
    }

    /**
     * @dev Remove addresses from the whitelist.
     * @param _tierId The id of the tier.
     * @param _addresses The address list to remove.
     */
    function removeWhitelist(uint256 _tierId, address[] calldata _addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tiers[_tierId].price == 0) revert TierNotFound();
        if (!tiers[_tierId].whitelistOnly) revert TierMustBeWhitelistOnly();

        for (uint256 i = 0; i < _addresses.length; i++) {
            _tierWhitelist[_tierId].remove(_addresses[i]);
        }
    }

    /**
     * @dev Set referral params.
     * @param referralAddress The referral address.
     * @param _discountAmount The discount amount.
     * @param _discountPercentage The discount percentage.
     * @param _referralFee The referral fee.
     */
    function setReferralParams(
        address referralAddress,
        uint64 _discountAmount,
        uint64 _discountPercentage,
        uint64 _referralFee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ReferralStruct storage ref = referralStruct[referralAddress];
        ref.discountAmount = _discountAmount;
        ref.discountPercentage = _discountPercentage;
        ref.referralFee = _referralFee;
    }

    /**
     * @dev Set the fee in basis points.
     * @param _referralFee The referral fee in basis points.
     */
    function setReferralFee(uint96 _referralFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_referralFee > MAX_REFERRAL_FEE) revert ReferralFeeExceeded();

        referralFee = _referralFee;
    }

    /**
     * @dev Set user specific price for a tier.
     * @param _tierId The id of the tier.
     * @param _users The user list.
     * @param _prices The price list.
     * @notice If you want to remove the user specific price, set it to 0.
     */
    function setUserSpecificPrice(
        uint256 _tierId,
        address[] calldata _users,
        uint256[] calldata _prices
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tiers[_tierId].price == 0) revert TierNotFound();
        if (_users.length != _prices.length) revert ArraySizesDoesNotMatch();

        for (uint256 i = 0; i < _users.length; i++) {
            userSpecificPrice[_users[i]][_tierId] = _prices[i];
        }
    }

    /**
     * @dev Set user specific price for a tier.
     * @param _tierId The id of the tier.
     * @param _users The user list.
     * @param _quantities The quantity list.
     * @notice If you want to remove the user specific quantity, set it to 0.
     */
    function setUserSpecificQuantity(
        uint256 _tierId,
        address[] calldata _users,
        uint64[] calldata _quantities
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tiers[_tierId].price == 0) revert TierNotFound();
        if (_users.length != _quantities.length) revert ArraySizesDoesNotMatch();

        for (uint256 i = 0; i < _users.length; i++) {
            userSpecificQuantity[_users[i]][_tierId] = _quantities[i];
        }
    }

    /**
     * @dev Withdraw the contract balance.
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev See {_setDefaultReferralDiscount}.
     */
    function setDefaultReferralDiscount(uint96 _defaultReferralDiscount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultReferralDiscount(_defaultReferralDiscount);
    }

    /**
     * @dev Returns the whitelist of a tier.
     * @param _tierId The id of the tier.
     * @return The whitelist of the tier.
     */
    function getTierWhitelist(uint256 _tierId) external view returns (address[] memory) {
        return _tierWhitelist[_tierId].values();
    }

    /**
     * @dev Returns batch of tier details.
     * @param from The start of the tier id (inclusive).
     * @param to The end of the tier id (exclusive).
     * @notice If `to` is greater than `nextTier`, it will be set to `nextTier`.
     * Also if array is too big, there might be gas limit issues.
     */
    function getTierBatch(uint256 from, uint256 to) external view returns (Tier[] memory) {
        if (to > nextTier) to = nextTier;

        Tier[] memory result = new Tier[](to - from);
        for (uint256 i = from; i < to; i++) {
            result[i - from] = tiers[i];
        }
        return result;
    }

    /**
     * @dev Returns batch of user specific price.
     * @param user The user address.
     * @param from The start of the tier id (inclusive).
     * @param to The end of the tier id (exclusive).
     * @notice If `to` is greater than `nextTier`, it will be set to `nextTier`.
     * Also if array is too big, there might be gas limit issues.
     */
    function getUserSpecificPriceBatch(
        address user,
        uint256 from,
        uint256 to
    ) external view returns (uint256[] memory) {
        if (to > nextTier) to = nextTier;

        uint256[] memory result = new uint256[](to - from);
        for (uint256 i = from; i < to; i++) {
            result[i - from] = userSpecificPrice[user][i];
        }
        return result;
    }

    /**
     * @dev Returns batch of user tier quantity.
     * @param user The user address.
     * @param from The start of the tier id (inclusive).
     * @param to The end of the tier id (exclusive).
     * @notice If `to` is greater than `nextTier`, it will be set to `nextTier`.
     * Also if array is too big, there might be gas limit issues.
     */
    function getUserTierQuantityBatch(address user, uint256 from, uint256 to) external view returns (uint64[] memory) {
        if (to > nextTier) to = nextTier;

        uint64[] memory result = new uint64[](to - from);
        for (uint256 i = from; i < to; i++) {
            result[i - from] = userTierQuantity[user][i];
        }
        return result;
    }

    /**
     * @dev Returns the price of the purchase.
     * @param user The user address.
     * @param referral The referral address.
     * @param tier The tier id.
     * @param amount The amount of the purchase.
     * @return price The price of the purchase.
     * @return amountReferralDiscount The amount of the referral discount.
     * @return amountWithoutDiscount The amount of the purchase without referral discount.
     */
    function getPrice(
        address user,
        address referral,
        uint256 tier,
        uint64 amount
    ) public view returns (uint256 price, uint64 amountReferralDiscount, uint64 amountWithoutDiscount) {
        // if user has specific price, just use that
        if (userSpecificPrice[user][tier] != 0) {
            price = userSpecificPrice[user][tier] * amount;
            return (price, 0, amount);
        }

        uint64 availableDiscountAmount = referralStruct[referral].discountAmount >
            referralStruct[referral].discountAmountUsed
            ? referralStruct[referral].discountAmount - referralStruct[referral].discountAmountUsed
            : 0;

        amountReferralDiscount = availableDiscountAmount > amount ? amount : availableDiscountAmount;

        amountWithoutDiscount = amount - amountReferralDiscount;
        // if referral has at least 1 node, apply default referral discount
        uint256 amountWithoutDiscountPercentage = IERC721(address(token)).balanceOf(referral) > 0
            ? defaultReferralDiscount
            : 0;

        uint256 totalPriceReferral = amountReferralDiscount *
            (tiers[tier].price - ((tiers[tier].price * referralStruct[referral].discountPercentage) / PERCENTAGE));

        uint256 totalPriceWithoutDiscount = amountWithoutDiscount *
            (tiers[tier].price - ((tiers[tier].price * amountWithoutDiscountPercentage) / PERCENTAGE));

        price = totalPriceReferral + totalPriceWithoutDiscount;
    }

    /**
     * @dev Returns the user specific quantity for a tier.
     * @param user The user address.
     * @param tier The tier id.
     */
    function getUserSpecificQuantity(address user, uint256 tier) public view returns (uint64 quantity) {
        quantity = userSpecificQuantity[user][tier] > 0
            ? userSpecificQuantity[user][tier]
            : tiers[tier].quantityPerUser;
    }

    /**
     * @dev Add a new tier.
     * @param tierId The id of the tier.
     * @param _price The price of the node.
     * @param _quantity The quantity of the nodes.
     * @param _quantityPerUser The quantity of the nodes per user.
     * @param _whitelistOnly If the tier is only for whitelisted users.
     * @notice This function assumes `tierId` is not used before.
     */
    function _addTier(
        uint256 tierId,
        uint256 _price,
        uint64 _quantity,
        uint64 _quantityWhitelist,
        uint64 _quantityPerUser,
        bool _whitelistOnly
    ) private {
        tiers[tierId] = Tier({
            price: _price,
            quantity: _quantity,
            quantityWhitelist: _quantityWhitelist,
            quantityPerUser: _quantityPerUser,
            totalSold: 0,
            whitelistSold: 0,
            whitelistOnly: _whitelistOnly
        });

        emit TierAdded(tierId);
    }

    /**
     * @dev Take fee from the purchase to send to the treasury.
     * @param amount The amount to take fee from.
     */
    function _takeFeeTreasury(uint256 amount) private {
        _takeFee(amount, fee, feeTreasury.getFeeTreasury());
    }

    /**
     * @dev Take fee from the purchase to send to the referral.
     * @param amount The amount to take fee from.
     * @param receiver The receiver of the fee.
     */
    function _takeFeeReferral(uint256 amount, address receiver) private {
        // if referral fee is not set, use the default referral fee
        uint96 calculatedFee = referralStruct[receiver].referralFee != 0 ? referralStruct[receiver].referralFee : referralFee;
        _takeFee(amount, calculatedFee, receiver);
    }

    /**
     * @dev Take fee from the purchase.
     * @param amount The amount to take fee from.
     * @param feePercentage The fee percentage.
     * @param receiver The receiver of the fee.
     */
    function _takeFee(uint256 amount, uint96 feePercentage, address receiver) private {
        uint256 feeAmount = (amount * feePercentage) / PERCENTAGE;

        (bool success, ) = payable(receiver).call{ value: feeAmount }("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Set default referral discount percentage in basis points.
     * @param _defaultReferralDiscount The default referral discount percentage in basis points.
     */
    function _setDefaultReferralDiscount(uint96 _defaultReferralDiscount) private {
        if (_defaultReferralDiscount > MAX_REFERRAL_DISCOUNT) revert ReferralDiscountExceeded();

        defaultReferralDiscount = _defaultReferralDiscount;
    }
}