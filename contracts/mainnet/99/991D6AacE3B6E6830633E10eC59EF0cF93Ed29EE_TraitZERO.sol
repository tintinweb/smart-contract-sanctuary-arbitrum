// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleRevoked} event.
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Versionable/IVersionable.sol";
import "./UsesGalaxisRegistry.sol";

contract CommunityRegistry is AccessControlEnumerable, UsesGalaxisRegistry, IVersionable  {

    function version() virtual external pure returns(uint256) {
        return 2024040401;
    }

    bytes32 public constant COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");

    uint32                      public  community_id;
    string                      public  community_name;
    

    mapping(bytes32 => address)         addresses;
    mapping(bytes32 => uint256)         uints;
    mapping(bytes32 => bool)            booleans;
    mapping(bytes32 => string)          strings;

    mapping (uint => string)    public  addressEntries;
    mapping (uint => string)    public  uintEntries;
    mapping (uint => string)    public  boolEntries;
    mapping (uint => string)    public  stringEntries;
    uint                        public  numberOfAddresses;
    uint                        public  numberOfUINTs;
    uint                        public  numberOfBooleans;
    uint                        public  numberOfStrings;

    bool                                initialised;

    bool                        public  independant;

    event IndependanceDay(bool gain_independance);

    modifier onlyAdmin() {
        require(
            isUserCommunityAdmin(COMMUNITY_REGISTRY_ADMIN,msg.sender)
            ,"CommunityRegistry : Unauthorised");
        _;
    }

    modifier onlyPropertyAdmin() {
        require(
            isUserCommunityAdmin(COMMUNITY_REGISTRY_ADMIN,msg.sender) ||
            hasRole(COMMUNITY_REGISTRY_ADMIN,msg.sender)
            ,"CommunityRegistry : Unauthorised");
        _;
    }



    function isUserCommunityAdmin(bytes32 role, address user) public view returns (bool) {
        if (hasRole(DEFAULT_ADMIN_ROLE,user) ) return true; // community_admin can do anything
        if (independant){        
            return(
                hasRole(role,user)
            );
        } else { // for Factories
           return(roleManager().hasRole(role,user));
        }
    }

    function roleManager() internal view returns (IAccessControlEnumerable) {
        address addr = galaxisRegistry.getRegistryAddress("ROLE_MANAGER"); // universal
        if (addr != address(0)) return IAccessControlEnumerable(addr);
        addr = galaxisRegistry.getRegistryAddress("MAINNET_CHAIN_IMPLEMENTER"); // mainnet
        if (addr != address(0)) return IAccessControlEnumerable(addr);
        addr = galaxisRegistry.getRegistryAddress("L2_RECEIVER"); // mainnet
        require(addr != address(0),"CommunityRegistry : no higher authority found");
        return IAccessControlEnumerable(addr);
    }

    function grantRole(bytes32 key, address user) public override(AccessControl,IAccessControl) onlyAdmin {
        _grantRole(key,user); // need to be able to grant it
    }


 
    constructor (
        address _galaxisRegistry,
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) UsesGalaxisRegistry(_galaxisRegistry){
        _init(_community_id,_community_admin,_community_name);
    }

    
    function init(
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) external {
        _init(_community_id,_community_admin,_community_name);
    }

    function _init(
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) internal {
        require(!initialised,"This can only be called once");
        initialised = true;
        community_id = _community_id;
        community_name  = _community_name;
        _setupRole(DEFAULT_ADMIN_ROLE, _community_admin); // default admin = launchpad
    }



    event AdminUpdated(address user, bool isAdmin);
    event AppAdminChanged(address app,address user,bool state);
    //===
    event AddressChanged(string key, address value);
    event UintChanged(string key, uint256 value);
    event BooleanChanged(string key, bool value);
    event StringChanged(string key, string value);

    function setIndependant(bool gain_independance) external onlyAdmin {
        if (independant != gain_independance) {
                independant = gain_independance;
                emit IndependanceDay(gain_independance);
        }
    }


    function setAdmin(address user,bool status ) external onlyAdmin {
        if (status)
            _grantRole(COMMUNITY_REGISTRY_ADMIN,user);
        else
            _revokeRole(COMMUNITY_REGISTRY_ADMIN,user);
    }

    function hash(string memory field) internal pure returns (bytes32) {
        return keccak256(abi.encode(field));
    }

    function setRegistryAddress(string memory fn, address value) external onlyPropertyAdmin {
        bytes32 hf = hash(fn);
        addresses[hf] = value;
        addressEntries[numberOfAddresses++] = fn;
        emit AddressChanged(fn,value);
    }

    function setRegistryBool(string memory fn, bool value) external onlyPropertyAdmin {
        bytes32 hf = hash(fn);
        booleans[hf] = value;
        boolEntries[numberOfBooleans++] = fn;
        emit BooleanChanged(fn,value);
    }

    function setRegistryString(string memory fn, string memory value) external onlyPropertyAdmin {
        bytes32 hf = hash(fn);
        strings[hf] = value;
        stringEntries[numberOfStrings++] = fn;
        emit StringChanged(fn,value);
    }

    function setRegistryUINT(string memory fn, uint value) external onlyPropertyAdmin {
        bytes32 hf = hash(fn);
        uints[hf] = value;
        uintEntries[numberOfUINTs++] = fn;
        emit UintChanged(fn,value);
    }

    function getRegistryAddress(string memory key) external view returns (address) {
        return addresses[hash(key)];
    }

    function getRegistryBool(string memory key) external view returns (bool) {
        return booleans[hash(key)];
    }

    function getRegistryUINT(string memory key) external view returns (uint256) {
        return uints[hash(key)];
    }

    function getRegistryString(string memory key) external view returns (string memory) {
        return strings[hash(key)];
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

interface IRegistry {
    function setRegistryAddress(string memory fn, address value) external ;
    function setRegistryBool(string memory fn, bool value) external ;
    function setRegistryUINT(string memory key) external returns (uint256) ;
    function setRegistryString(string memory fn, string memory value) external ;
    function setAdmin(address user,bool status ) external;
    function setAppAdmin(address app, address user, bool state) external;

    function getRegistryAddress(string memory key) external view returns (address) ;
    function getRegistryBool(string memory key) external view returns (bool);
    function getRegistryUINT(string memory key) external view returns (uint256) ;
    function getRegistryString(string memory key) external view returns (string memory) ;
    function isAdmin(address user) external view returns (bool) ;
    function isAppAdmin(address app, address user) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "./IRegistry.sol";

contract UsesGalaxisRegistry {

    IRegistry   immutable   public   galaxisRegistry;

    constructor(address _galaxisRegistry) {
        galaxisRegistry = IRegistry(_galaxisRegistry);
    }

}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.25;

/**
 * @title IVersionable
 * @dev Interface for versionable contracts.
 */
interface IVersionable {
    /**
     * @notice Get the current version of the contract.
     * @return The current version.
     */
    function version() external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.25;

interface IPaymentMatrix {
    function getDevIDAndAmountForTraitType(uint16 _traitType) external view returns(uint256 devId, uint256 amount);
    function getArtistIDAndAmountForCollection(uint32 _communityId, uint32 _collectionId) external view returns(uint256 artistId, uint256 amount);
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.25;

import "../../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../../../@galaxis/registries/contracts/UsesGalaxisRegistry.sol";

import "../../../PaymentMatrix/IPaymentMatrix.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGTRegistry {
    function addressCanModifyTrait(address, uint16) external view returns (bool);
    function getTraitControllerAccessData(address) external view returns (uint8[] memory);
    function myCommunityRegistry() external view returns (CommunityRegistry);
    function tokenNumber() external view returns (uint32);
    function TOKEN_KEY() external view returns (string memory);
}

enum FieldTypes {
    NONE,
    STORED_BOOL,
    STORED_UINT_8,
    STORED_UINT_16,
    STORED_UINT_32,
    STORED_UINT_64,
    STORED_UINT_128,
    STORED_UINT_256,       
    STORED_BYTES_32,       // bytes32 fixed
    STORED_STRING,         // bytes array
    STORED_BYTES,          // bytes array
    STORED_ADDRESS,
    LOGIC_BOOL,
    LOGIC_UINT_8,
    LOGIC_UINT_32,
    LOGIC_UINT_64,
    LOGIC_UINT_128,
    LOGIC_UINT_256,
    LOGIC_BYTES_32,
    LOGIC_ADDRESS
}

struct traitProperty {
    bytes32     _name;
    FieldTypes  _type;
    bytes4      _selector;
    bytes       _default;
    bool        _limited;
    uint256     _min;
    uint256     _max;
    bool        _reset_on_owner_change;
}

struct traitInfo {
    uint16 _id;
    uint16 _type;
    address _registry;
    uint256 _baseVersion;
    uint256 _version;
    traitProperty[] _schema;
    uint8   _propertyCount;
    bytes32 _app;
    traitConfig _traitConfig; 
}

struct traitConfig {
    bool inverted;
}

enum BitType {
    NONE,
    EXISTS,
    INITIALIZED
}

enum TraitStatus {
    NONE,
    // NOT_INITIALIZED,
    ACTIVE,
    DORMANT,
    SPENT
}

enum MovementPermission {
    NONE,
    OPEN,
    LOCKED,
    SOULBOUND,
    SOULBURN
}

enum ModifierMode {
    NONE,
    ADD,
    SET
}


contract GenericTrait is UsesGalaxisRegistry  {

    uint16      public     traitId;
    IGTRegistry public     GTRegistry;
    event tokenTraitChangeEvent(uint32 indexed _tokenId);

    function baseVersion() public pure returns (uint256) {
        return 2024052201;
    }

    function version() public pure virtual returns (uint256) {
        return baseVersion();
    }
    
    function TRAIT_TYPE() public pure virtual returns (uint16) {
        return 0;   // Physical redemption
    }

    function APP() public pure virtual returns (bytes32) {
        return "generic-trait";   // Physical redemption
    }

    constructor(address _galaxisRegistry) UsesGalaxisRegistry(_galaxisRegistry) {
        
    }


    function tellEverything() external view returns(traitInfo memory) {
        return traitInfo(
            traitId,
            TRAIT_TYPE(),
            address(GTRegistry),
            baseVersion(),
            version(),
            getSchema(),
            propertyCount,
            APP(),
            thisTraitConfig
        );
    }

    // constructor(
    //     address _registry,
    //     uint16 _traitId,
    //     bytes[] memory _defaultPropValues
    // ) {
    //     traitId = _traitId;
    //     GTRegistry = IGTRegistry(_registry);
    //     for(uint8 i = 0; i < _defaultPropValues.length; i++) {
    //         defaultPropValues[i] = _defaultPropValues[i];
    //     }
    // }

    // cannot store as bytes unless we only allow simple types, no string / array 

    /*
        Set Properties
        Name	            type	defaults	description
        Expiration  date	date	-	        Trait can't be used after expiration date passes
        Counter	            int	    -	        Trait can only be used this many times
        Cooldown	        int	    -	        current date + cooldonw = Activation Date
        Activation Date	    date	-	        If set, trait can't be used before this date
        Modifier Lock	    bool	FALSE	    if True, Value Modifier Traits can't modify limiters
        Burn If Spent	    bool	FALSE	    If trait's status ever becomes "spent", it gets burned.
        Movement Permission	status	OPEN	    See "movement permission"
        Royalty ID	        ID	    -	        ID of the entity who is entitled to the Usage Royalty
        Royalty Amount	    int	    0	        Royalty amount in GLX


        Discount Trait Properties
        Name	        type	defaults	    Description
        Discount Type	status	PERCENTAGE	    It can be either PERCENTAGE or a fix GLX AMOUNT
        Discount Amount	int	    -	            Either 0-100 or a GLX amount
        Acceptor Type	status	MARKETPLACE	    Acceptor Type, can't be blank. Check Discounts for list.
        Max	            int	    -	            max value possible (value modifier can't go beyond)
        Modifier Lock	bool	FALSE	        If true, Value Modifier Traits have no effect


        Digital Redeemable Trait Properties
        Name	        Type	defaults	description
        Vault	        ID	    -	        The target vault of the redeemable. Can not be empty.
        Luck	        0-100	0	        If greater than zero, the Luck Process is invoked.
        Redeem Mode	    ID	    RR	        See "Redeem Modes" in the Vault page.
        Modifier Lock	bool	FALSE	    If True, Value Modifiers can't apply to this trait.


        Physical Redeemable Trait Properties
        name	    type	description
        item name	ID	    name of the item that can be redeemed


        Value Modifier Trait Properties
        name	    type	defaults	description
        Trait Type	ID	    -	        What type of trait to modify (Digital Redeemable, etc)
        Property	ID	    -	        What property of that trait to modify
        Mode	    ID	    ADD	        ADD or SET
        Value	    int	    -	        By how much

    */

    bool public initialized = false;
    traitConfig thisTraitConfig;

    mapping(uint8 => traitProperty) property;
    uint8 propertyCount = 0;
    mapping(bytes32 => uint8) propertyNameToId;
    mapping(uint8 => uint8) propertyStorageMap;

    //      propId  => tokenId => ( index => value )
    mapping(uint8 => mapping( uint32 => bytes ) ) storageMapArray;
    //      tokenId => data ( except bytes / string which go into storageMapArray )
    mapping(uint32 => bytes ) storageData;

    //      propId  => tokenId => ( index => value )
    mapping(uint8 => bytes ) storageMapArrayDEFAULT;
    //      tokenId => data ( except bytes / string which go into storageMapArrayDEFAULT )

    bytes tokenDataDEFAULT;
    mapping(uint8 => bytes ) defaultPropValues;

    // we need an efficient way to activate traits at mint or by using dropper
    // to achieve this we set 1 bit per tokenId
    // 

    mapping(uint32 => uint8 )    public existsData;
    mapping(uint32 => uint8 )    initializedData;

    // indexed props
    bool    public modifier_lock;
    uint8   public movement_permission;

    bytes32 constant constant_royalty_id_key = hex"726f79616c74795f696400000000000000000000000000000000000000000000";
    bytes32 constant constant_royalty_amount_key = hex"726f79616c74795f616d6f756e74000000000000000000000000000000000000";
    bytes32 constant constant_owner_stored_key = hex"6f776e65725f73746f7265640000000000000000000000000000000000000000";

    // constructor() {
    //     init();
    // }

    function isLogicFieldType(FieldTypes _type) internal pure returns (bool) {
        if(_type == FieldTypes.LOGIC_BOOL) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_8) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_32) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_64) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_128) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_UINT_256) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_BYTES_32) {
            return true;
        }
        if(_type == FieldTypes.LOGIC_ADDRESS) {
            return true;
        }
        return false;
    }

    function _addProperty(bytes32 _name, FieldTypes _type, bytes4 _selector) internal {
        uint8 thisId = propertyCount;

        if(propertyNameToId[_name] > 0) {
            // no duplicates
            revert();
        } else {
            propertyNameToId[_name]     = thisId;
            traitProperty storage prop = property[thisId];
            prop._name = _name;
            prop._type = _type;
            prop._selector = _selector;
            prop._default = defaultPropValues[thisId]; // _default;
            propertyCount++;
        }
    }

    function addStoredProperty(bytes32 _name, FieldTypes _type) internal {
        _addProperty(_name, _type, bytes4(0));
    }

    function addLogicProperty(bytes32 _name, FieldTypes _type, bytes4 _selector) internal {
        _addProperty(_name, _type, _selector);
    }

    function addPropertyLimits(bytes32 _name, uint256 _min, uint256 _max) internal {
        uint8 _id = propertyNameToId[_name];
        traitProperty storage thisProp = property[_id];
        require(thisProp._selector == bytes4(hex"00000000"), "Trait: Cannot set limits on Logic property");
        thisProp._limited = true;
        thisProp._min = _min;
        thisProp._max = _max;
    }

    function setPropertyResetOnOwnerChange(bytes32 _name) internal {
        uint8 _id = propertyNameToId[_name];
        traitProperty storage thisProp = property[_id];
        thisProp._reset_on_owner_change = true;
    }

    function _initStandardProps() internal {
        require(!initialized, "Trait: already initialized!");

        addLogicProperty( bytes32("exists"),              FieldTypes.LOGIC_BOOL,        bytes4(keccak256("hasTrait(uint32)")));
        addLogicProperty( bytes32("initialized"),         FieldTypes.LOGIC_BOOL,        bytes4(keccak256("isInitialized(uint32)")));

        // required for soulbound
        addStoredProperty(bytes32("owner_stored"),        FieldTypes.STORED_ADDRESS);
        addLogicProperty( bytes32("owner_current"),       FieldTypes.LOGIC_ADDRESS,     bytes4(keccak256("currentTokenOwnerAddress(uint32)")));


        // if true, Value Modifier Traits can't modify limiters
        addStoredProperty(bytes32("modifier_lock"),       FieldTypes.STORED_BOOL);
        addStoredProperty(bytes32("movement_permission"), FieldTypes.STORED_UINT_8);
        addStoredProperty(bytes32("activation"),          FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("cooldown"),            FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("expiration"),          FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("counter"),             FieldTypes.STORED_UINT_8);

        addStoredProperty(bytes32("royalty_id"),          FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("royalty_amount"),      FieldTypes.STORED_UINT_256);

        addLogicProperty( bytes32("status"),              FieldTypes.LOGIC_UINT_8,      bytes4(keccak256("status(uint32)")));



        // setPropertySoulbound()
            // owner_stored
            // if(_name == hex"6f776e65725f73746f7265640000000000000000000000000000000000000000") {
            //     prop._soulbound = true;
            // }


        // status change on owner_current change
        // if movement_permission == MovementPermission.SOULBOUND
        // on addTrait / setProperty / setData set owner_stored
        // 
        

        // prop reset on owner_stored
        // _reset_on_owner_change
        // addStoredProperty(bytes32("points"),              FieldTypes.STORED_UINT_256);
        // setPropertyResetOnOwnerChange(bytes32("points"));
        // addStoredProperty(bytes32("points"),              FieldTypes.STORED_UINT_256);

        // addPropertyLimits(bytes32("cooldown"),      0,      3600 * 24);
        // addPropertyLimits(bytes32("counter"),       0,      100);
    }

    function setup(
        address _registry,
        uint16 _traitId,
        traitConfig memory _traitConfig,
        bytes[] memory _defaultPropValues
    ) virtual public {
        require(!initialized, "Trait: already initialized!");
        GTRegistry = IGTRegistry(_registry);
        traitId = _traitId;
        thisTraitConfig = _traitConfig;
        for(uint8 i = 0; i < _defaultPropValues.length; i++) {
            defaultPropValues[i] = _defaultPropValues[i];
        }        
    }

    

    function init() virtual public {
        _initStandardProps();
        // custom props
        afterInit();
    }

    function getRoyaltiesForThisTraitType() internal view returns (uint256, uint256) {
        IPaymentMatrix PaymentMatrix = IPaymentMatrix(
            galaxisRegistry.getRegistryAddress("PAYMENT_MATRIX")
        ); 
        
        require(address(PaymentMatrix) != address(0), "Trait: PAYMENT_MATRIX address cannot be 0");

        // if(initialized){} 
        return PaymentMatrix.getDevIDAndAmountForTraitType(TRAIT_TYPE());
    }

    function afterInit() internal {

        // overwrite royalty_id / royalty_amount
        (uint256 royalty_id, uint256 royalty_amount) = getRoyaltiesForThisTraitType();
        for(uint8 _id = 0; _id < propertyCount; _id++) {
            traitProperty memory thisProp = property[_id];
            if(thisProp._name == constant_royalty_id_key || thisProp._name == constant_royalty_amount_key) {
                bytes memory value;
                if(thisProp._name == constant_royalty_id_key) {
                    value = abi.encode(royalty_id);
                } else if(thisProp._name == constant_royalty_amount_key) {
                    value = abi.encode(royalty_amount);
                }
                defaultPropValues[_id] = value;
                property[_id]._default = value;
            } 

            // reset default owner in case deployer wrote a different address here
            if(thisProp._name == constant_owner_stored_key ) {
                property[_id]._default = abi.encode(address(0));
            }
        }

        // index for cheaper internal logic
        modifier_lock = (uint256(bytes32(getProperty("modifier_lock", 0))) > 0 );
        movement_permission = abi.decode(getProperty("movement_permission", 0), (uint8));
        // set defaults
        tokenDataDEFAULT = getDefaultTokenDataOutput();

        initialized = true;
    }


    function getSchema() public view returns (traitProperty[] memory) {
        traitProperty[] memory myProps = new traitProperty[](propertyCount);
        for(uint8 i = 0; i < propertyCount; i++) {
            myProps[i] = property[i];
        }
        return myProps;
    }

    // function _getFieldTypeByteLenght(uint8 _id) public view returns (uint16) {
    //     traitProperty storage thisProp = property[_id];
    //     if(thisProp._type == FieldTypes.LOGIC_BOOL || thisProp._type == FieldTypes.STORED_BOOL) {
    //         return 1;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_8) {
    //         return 1;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_16) {
    //         return 2;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_32) {
    //         return 4;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_64) {
    //         return 8;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_128) {
    //         return 16;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_UINT_256) {
    //         return 32;
    //     }
    //     else if(thisProp._type == FieldTypes.STORED_STRING || thisProp._type == FieldTypes.STORED_BYTES) {
    //         // array length for strings / bytes limited to uint16.
    //         return 2;
    //     }

    //     revert("Trait: FieldType Not Implemented");
    // }

    function getOutputBufferLength(uint32 _tokenId) public view returns(uint16, uint16) {
        // abi.encode style 32 byte blocks
        // with memory pointer at location for complex types
        // pointer to length followed by records
        uint16 propCount = propertyCount;
        uint16 _length = 32 * propCount;
        uint16 complexDataOutputPtr = _length;
        bytes memory tokenData = bytes(storageData[_tokenId]);
        
        for(uint8 _id = 0; _id < propertyCount; _id++) {
            FieldTypes thisPropType = property[_id]._type;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                uint16 offset = uint16(_id) * 32;
                // console.log("getOutputBufferLength", _id, offset);
                bytes memory arrayLenB = new bytes(2);
                if(tokenData.length > 0) {
                    arrayLenB[0] = bytes1(tokenData[offset + 30]);
                    arrayLenB[1] = bytes1(tokenData[offset + 31]);
                    // each complex type adds another 32 for length 
                    // and data 32 * ceil(length/32)
                    _length+= 32 + 32 + ( 32 * ( uint16(bytes2(arrayLenB)) / 32 ) );

                } else {
                    arrayLenB[0] = 0;
                    arrayLenB[1] = 0;
                    _length+= 32;
                }
            }
        }
        return (_length, complexDataOutputPtr);
    }

    function getData(uint32[] memory _tokenIds) public view returns(bytes[] memory) {
        bytes[] memory outputs = new bytes[](_tokenIds.length);
        for(uint32 i = 0; i < _tokenIds.length; i++) {
            outputs[i] = getData(_tokenIds[i]);
        }
        return outputs;
    }

    function getDefaultTokenDataOutput() public view returns(bytes memory) {
        uint32 _tokenId = 0;
        ( uint16 _length, uint16 complexDataOutputPtr) = getOutputBufferLength(_tokenId);
        bytes memory outputBuffer = new bytes(_length);
        uint256 outputPtr;
        uint256 complexDataOutputRealPtr;
        uint256 _start = 0;

        assembly {
            // jump over length 32 byte block
            outputPtr := add(outputBuffer, 32)
            complexDataOutputRealPtr := add(outputPtr, complexDataOutputPtr)
        }

        for(uint8 _id = 0; _id < propertyCount; _id++) {
            _start+=32;

            FieldTypes thisPropType = property[_id]._type;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                bytes memory value = storageMapArrayDEFAULT[_id];
                assembly {
                    // let readptr := add(tokenData, _start)
                    // store location of data in place
                    mstore(outputPtr, complexDataOutputPtr)

                    complexDataOutputPtr := add(complexDataOutputPtr, 32)
                    let byteLength := mload(value)
                    let itemBlocks := div(byteLength, 32)
                    if lt(mul(itemBlocks, 32), byteLength ) {
                        itemBlocks := add(itemBlocks, 1)
                    }
                    // store array length
                    mstore(complexDataOutputRealPtr, byteLength)
                    complexDataOutputRealPtr:= add(complexDataOutputRealPtr, 32)
                    for { let n := 0 } lt(n, itemBlocks) { n := add(n, 1) } {
                        // store array 32 byte blocks
                        mstore(
                            complexDataOutputRealPtr, 
                            mload(
                                add(value, mul(add(n,1), 32) ) 
                            )
                        )
                        complexDataOutputRealPtr:= add(complexDataOutputRealPtr, 32)
                    }
                    complexDataOutputPtr := add(complexDataOutputPtr, mul(itemBlocks, 32))
                }

            }
            else {
                bytes32 value = bytes32(property[_id]._default);
                assembly {
                    // store empty value in place
                    mstore(outputPtr, value)
                }
            }

            assembly {
                outputPtr := add(outputPtr, 32)
            }
        }
        return outputBuffer;

    }

    function getData(uint32 _tokenId) public view returns(bytes memory) {
        uint16 _length = 0;
        uint16 complexDataOutputPtr;
        ( _length, complexDataOutputPtr) = getOutputBufferLength(_tokenId);
        bytes memory outputBuffer = new bytes(_length);
        bytes memory tokenData = storageData[_tokenId];

        if(!isInitialized(_tokenId)) {
            tokenData = tokenDataDEFAULT;
        }

        // 32 byte block contains bytes array size / length
        if(tokenData.length == 0) {
            // could simply return empty outputBuffer here..;
            tokenData = new bytes(
                uint16(propertyCount) * 32
            );
        }

        uint256 outputPtr;
        uint256 complexDataOutputRealPtr;
        uint256 _start = 0;

        assembly {
            // jump over length 32 byte block
            outputPtr := add(outputBuffer, 32)
            complexDataOutputRealPtr := add(outputPtr, complexDataOutputPtr)
        }

        for(uint8 _id = 0; _id < propertyCount; _id++) {
            _start+=32;

            FieldTypes thisPropType = property[_id]._type;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                bytes memory value = storageMapArray[_id][_tokenId];
                assembly {
                    // let readptr := add(tokenData, _start)
                    // store location of data in place
                    mstore(outputPtr, complexDataOutputPtr)

                    complexDataOutputPtr := add(complexDataOutputPtr, 32)
                    let byteLength := mload(value)
                    let itemBlocks := div(byteLength, 32)
                    if lt(mul(itemBlocks, 32), byteLength ) {
                        itemBlocks := add(itemBlocks, 1)
                    }
                    // store array length
                    mstore(complexDataOutputRealPtr, byteLength)
                    complexDataOutputRealPtr:= add(complexDataOutputRealPtr, 32)
                    for { let n := 0 } lt(n, itemBlocks) { n := add(n, 1) } {
                        // store array 32 byte blocks
                        mstore(
                            complexDataOutputRealPtr, 
                            mload(
                                add(value, mul(add(n,1), 32) ) 
                            )
                        )
                        complexDataOutputRealPtr:= add(complexDataOutputRealPtr, 32)
                    }
                    complexDataOutputPtr := add(complexDataOutputPtr, mul(itemBlocks, 32))
                }

            }
            else if(isLogicFieldType(thisPropType)) {

                callMethodAndCopyToOutputPointer(
                    property[_id]._selector, 
                    _tokenId,
                    outputPtr
                );

            } else {
                assembly {
                    // store value in place
                    mstore(outputPtr, mload(
                        add(tokenData, _start)
                    ))
                }
            }

            assembly {
                outputPtr := add(outputPtr, 32)
            }
        }
        return outputBuffer;
    }

    function callMethodAndCopyToOutputPointer(bytes4 _selector, uint32 _tokenId, uint256 outputPtr ) internal view {
        (bool success, bytes memory callResult) = address(this).staticcall(
            abi.encodeWithSelector(_selector, _tokenId)
        );
        require(success, "Trait: internal method call failed");
        // console.logBytes(callResult);
        assembly {
            // store value in place  // shift by 32 so we just get the value
            mstore(outputPtr, mload(add(callResult, 32)))
        }
    }

    /*
        should remove, gives too much power
    */
    function setData(uint32 _tokenId, bytes memory _bytesData) public onlyAllowed {
        _setData(_tokenId, _bytesData);
        
        //
        _updateCurrentOwnerInStorage(_tokenId);
    }

    function _setData(uint32 _tokenId, bytes memory _bytesData) internal {
        
        if(!hasTrait(_tokenId)) {
            // if the trait does not exist
            setTraitExistance(_tokenId, true);
        }

        if(!isInitialized(_tokenId)) {
            // if the trait is not initialized
            _tokenSetBit(_tokenId, BitType.INITIALIZED, true);
        }

        uint16 _length = uint16(propertyCount) * 32;
        if(_bytesData.length < _length) {
            revert("Trait: Message not long enough");
        }

        bytes memory newTokenData = new bytes(_length);
        uint256 newTokenDataPtr;
        uint256 readPtr;
        assembly {
            // jump over length 32 byte block
            newTokenDataPtr := add(newTokenData, 32)
            readPtr := add(_bytesData, 32)
        }

        for(uint8 _id = 0; _id < propertyCount; _id++) {
            FieldTypes thisPropType = property[_id]._type;
            bytes32 fieldValue;
            assembly {
                fieldValue:= mload(readPtr)
            }

            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                // read length from offset stored in fieldValue
                bytes32 byteLength;
                uint256 complexDataPtr;
                assembly {
                    complexDataPtr:= add(
                        add(_bytesData, 32),
                        fieldValue
                    )

                    byteLength:= mload(complexDataPtr)
                    // store length
                    mstore(newTokenDataPtr, byteLength)
                }

                bytes memory propValue = new bytes(uint256(byteLength));

                assembly {
                
                    let propValuePtr := add(propValue, 32)
                    let itemBlocks := div(byteLength, 32)
                    if lt(mul(itemBlocks, 32), byteLength ) {
                        itemBlocks := add(itemBlocks, 1)
                    }

                    // store array 32 byte blocks
                    for { let n := 0 } lt(n, itemBlocks) { n := add(n, 1) } {
                        complexDataPtr:= add(complexDataPtr, 32)
                        mstore(
                            propValuePtr, 
                            mload(complexDataPtr)
                        )                        
                        propValuePtr:= add(propValuePtr, 32)
                    }

                }
                storageMapArray[_id][_tokenId] = propValue;
            
            } else if(isLogicFieldType(thisPropType)) {
                // do nothing
            } else {
                // just store fieldValue in newTokenData
                assembly {
                    mstore(newTokenDataPtr, fieldValue)
                }
            }

            assembly {
                newTokenDataPtr := add(newTokenDataPtr, 32)
                readPtr := add(readPtr, 32)
            }
        }
        storageData[_tokenId] = newTokenData;
        emit tokenTraitChangeEvent(_tokenId);
    }

    // function getPropertyOutputBufferLength(uint8 _id, FieldTypes _thisPropType, uint32 _tokenId) public view returns(uint16) {
    //     uint16 _length = 32;
    //     bytes memory tokenData = bytes(storageData[_tokenId]);
    //     if(_thisPropType == FieldTypes.STORED_STRING || _thisPropType == FieldTypes.STORED_BYTES) {
    //         uint16 offset = _id * 32;
    //         bytes memory arrayLenB = new bytes(2);
    //         if(tokenData.length > 0) {
    //             arrayLenB[0] = bytes1(tokenData[offset + 30]);
    //             arrayLenB[1] = bytes1(tokenData[offset +31]);
    //             // each complex type adds another 32 for length 
    //             // and data 32 * ceil(length/32)
    //             _length+= 32 + 32 + ( 32 * ( uint16(bytes2(arrayLenB)) / 32 ) );
    //         } else {
    //             arrayLenB[0] = 0;
    //             arrayLenB[1] = 0;
    //         }
    //     }
        
    //     return _length;
    // }

    function getProperties(uint32 _tokenId, bytes32[] memory _names) public  view returns(bytes[] memory) {
        bytes[] memory outputs = new bytes[](_names.length);
        for(uint32 i = 0; i < _names.length; i++) {
            outputs[i] = getProperty(_names[i], _tokenId);
        }
        return outputs;
    }

    function getProperty(bytes32 _name, uint32 _tokenId) public view returns (bytes memory) {
        uint8 _id = propertyNameToId[_name];
        FieldTypes thisPropType = property[_id]._type;
        if(!isInitialized(_tokenId) && !isLogicFieldType(thisPropType)) {
            // if the trait has not been initialized, and is not a method return, we return default stored data
            return property[_id]._default;
        } else {
            return _getProperty(_id, _tokenId);
        }
    }

    function _getProperty(uint8 _id, uint32 _tokenId) internal view returns (bytes memory) {
        FieldTypes thisPropType = property[_id]._type;
        bytes memory output = new bytes(32);
        uint256 outputPtr;
        assembly {
            outputPtr := add(output, 32)
        }
        if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
            output = storageMapArray[_id][_tokenId];
        }
        else if(isLogicFieldType(thisPropType)) {
            callMethodAndCopyToOutputPointer(
                property[_id]._selector, 
                _tokenId,
                outputPtr
            );
        }
        else {
            bytes memory tokenData = bytes(storageData[_tokenId]);
            // first 32 is tokenData length
            uint256 _start = 32 + 32 * uint16(_id);
            assembly {
                outputPtr := add(output, 32)
                // store value in place
                mstore(outputPtr, mload(
                        add(tokenData, _start)
                    )
                )
            }
        }
        return output; 
    }

    // function canUpdateTo(bytes32 _name, bytes memory newValue) public view returns (bool) {
    //     return true;

    //     uint8 _id = propertyNameToId[_name];
    //     traitProperty memory thisProp = property[_id];
        
    //     thisProp._limited;

    //     if(modifier_lock) {
    //         // if()
    //         return false;
    //     }
    //     return false;
    //     // 
    // }

    function setProperties(uint32 _tokenId, bytes32[] memory _names, bytes[] memory inputs) public onlyAllowed {
        _updateCurrentOwnerInStorage(_tokenId);

        for(uint8 i = 0; i < _names.length; i++) {
            bytes32 name = _names[i];
            if(name == constant_owner_stored_key) {
                revert("Trait: dissalowed! Cannot set owner_stored value!");
            }
            _setProperty(name, _tokenId, inputs[i]);
        }
    }


    function setProperty(bytes32 _name, uint32 _tokenId, bytes memory input) public onlyAllowed {
        if(_name == constant_owner_stored_key) {
            revert("Trait: dissalowed! Cannot set owner_stored value!");
        }
        _updateCurrentOwnerInStorage(_tokenId);
        _setProperty(_name, _tokenId, input);
    }

    function _updateCurrentOwnerInStorage(uint32 _tokenId) internal {
        if(movement_permission == uint8(MovementPermission.SOULBOUND)) {
            // if default address 0 value, then do the update
            if(
                // decoded stored value
                abi.decode(getProperty(constant_owner_stored_key, _tokenId), (address)) 
                == address(0)
            ) {
                _setProperty(
                    constant_owner_stored_key,
                    _tokenId, 
                    // abi encodePacked left shifts everything, but ethers.js cannot decode that properly!
                    abi.encode(currentTokenOwnerAddress(_tokenId))
                );
            }
            // else do nothing
        } else {
            _setProperty(
                constant_owner_stored_key,
                _tokenId, 
                // abi encodePacked left shifts everything, but ethers.js cannot decode that properly!
                abi.encode(currentTokenOwnerAddress(_tokenId))
            );
        }

    }

    function _setProperty(bytes32 _name, uint32 _tokenId, bytes memory input) internal {
        // if(!canUpdateTo(_name, input)) {
        //     revert("Trait: Cannot update values because modifier lock is true");
        // }

        if(!hasTrait(_tokenId)) {
            // if the trait does not exist
            setTraitExistance(_tokenId, true);
        }

        if(!isInitialized(_tokenId)) {
            // if the trait is not initialized
            _tokenSetBit(_tokenId, BitType.INITIALIZED, true);
            _setData(_tokenId, tokenDataDEFAULT);
        }

        uint8 _id = propertyNameToId[_name];
        FieldTypes thisPropType = property[_id]._type;

        if(isLogicFieldType(thisPropType)) {
            revert("Trait: Cannot set logic value!");
        } else {

            uint16 _length = uint16(propertyCount) * 32;
            bytes memory tokenData = bytes(storageData[_tokenId]);
            if(tokenData.length == 0) {
                tokenData = new bytes(_length);
                // init default tokenData.. empty for now
            }

            uint256 valuePtr;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                assembly {
                    valuePtr := input
                }
                storageMapArray[_id][_tokenId] = input;

            } else {
                assembly {
                    // load from pointer location
                    valuePtr := add(input, 32)
                }
            }

            assembly {
                // store incomming length value into value slot
                mstore(
                    add(
                        add(tokenData, 32),
                        mul(_id, 32) 
                    ),
                    mload(valuePtr)
                )
            }
            storageData[_tokenId] = tokenData;
        }
        
        emit tokenTraitChangeEvent(_tokenId);
    }

    function getByteAndBit(uint32 _offset) public pure returns (uint32 _byte, uint8 _bit) {
        // find byte storig our bit
        _byte = uint32(_offset / 8);
        _bit = uint8(_offset - _byte * 8);
    }

    function hasTrait(uint32 _tokenId) public view returns (bool result) {
        bool _hasTrait = _tokenHasBit(_tokenId, BitType.EXISTS);
        if(thisTraitConfig.inverted) {
            return !_hasTrait;
        }
        return _hasTrait;
    }

    function isInitialized(uint32 _tokenId) public view returns (bool result) {
        return _tokenHasBit(_tokenId, BitType.INITIALIZED);
    }

    function _tokenHasBit(uint32 _tokenId, BitType _bitType) internal view returns (bool result) {
        uint8 bitType = uint8(_bitType);
        (uint32 byteNum, uint8 bitPos) = getByteAndBit(_tokenId);
        if(bitType == 1) {
            return existsData[byteNum] & (0x01 * 2**bitPos) != 0;
        } else if(bitType == 2) {
            return initializedData[byteNum] & (0x01 * 2**bitPos) != 0;
        }
    }

    function status(uint32 _tokenId) public view returns ( uint8 ) {
        TraitStatus statusValue = TraitStatus.NONE;
        if(hasTrait(_tokenId)) {
            uint256 activation  = uint256(bytes32(getProperty("activation", _tokenId)));
            uint256 expiration  = uint256(bytes32(getProperty("expiration", _tokenId)));
            uint256 counter     = uint256(bytes32(getProperty("counter",    _tokenId)));

            if(expiration == 0) {
                // expiration 0 means never
                expiration = block.timestamp + 3600;
            }

            if(counter > 0) {
                if(activation <= block.timestamp && block.timestamp <= expiration) {

                    // SOULBOUND Check
                    if(movement_permission == uint8(MovementPermission.SOULBOUND)) {

                        address storedOwnerValue = abi.decode(getProperty(constant_owner_stored_key, _tokenId), (address));
                        address currentOwnerValue = currentTokenOwnerAddress(_tokenId);
                        
                        if(storedOwnerValue == currentOwnerValue) {
                            statusValue = TraitStatus.ACTIVE;
                        } else {
                            statusValue = TraitStatus.DORMANT;
                        }

                    } else {
                        statusValue = TraitStatus.ACTIVE;
                    }

                } else {
                    statusValue = TraitStatus.DORMANT;
                }
            } else {
                statusValue = TraitStatus.SPENT;
            }
        }
        return uint8(statusValue);
    }

    // marks token as having the trait
    function addTrait(uint32[] memory _tokenIds) public onlyAllowed {
        for(uint16 _id = 0; _id < _tokenIds.length; _id++) {
            if(!hasTrait(_tokenIds[_id])) {
                // if trait is soulbound we have to initialize it.. 
                if(movement_permission == uint8(MovementPermission.SOULBOUND)) {
                    _updateCurrentOwnerInStorage(_tokenIds[_id]);     
                } else {
                    setTraitExistance(_tokenIds[_id], true);
                    emit tokenTraitChangeEvent(_tokenIds[_id]);
                }
            } else {
                revert("Trait: Token already has trait!");
            }
        }
    }

    function setTraitExistance(uint32 _tokenId, bool _value) internal {
        if(thisTraitConfig.inverted) {
            _value = !_value;
        }
        _tokenSetBit(_tokenId, BitType.EXISTS, _value);
    }

    // util, sets bit in item in map at position as true / false
    function _tokenSetBit(uint32 _tokenId, BitType _bitType, bool _value) internal {
        (uint32 byteNum, uint8 bitPos) = getByteAndBit(_tokenId);
        if(_bitType == BitType.EXISTS) {
            if(_value) {
                existsData[byteNum] = uint8(existsData[byteNum] | 2**bitPos);
            } else {
                existsData[byteNum] = uint8(existsData[byteNum] & ~(2**bitPos));
            }
        } else if(_bitType == BitType.INITIALIZED) {
            if(_value) {
                initializedData[byteNum] = uint8(initializedData[byteNum] | 2**bitPos);
            } else {
                initializedData[byteNum] = uint8(initializedData[byteNum] & ~(2**bitPos));
            }
        }
    }

    function _removeTrait(uint32 _tokenId) internal returns (bool) {
        require(hasTrait(_tokenId), "Trait: Token does not have trait!");

        delete storageData[_tokenId];
        for(uint8 _id = 0; _id < propertyCount; _id++) {
            FieldTypes thisPropType = property[_id]._type;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                delete storageMapArray[_id][_tokenId];
            }
        }

        setTraitExistance(_tokenId, false);
        _tokenSetBit(_tokenId, BitType.INITIALIZED, false);

        emit tokenTraitChangeEvent(_tokenId);
        return true;
    }

    function removeTrait(uint32[] memory _tokenIds) public onlyAllowed returns (bool) {
        for(uint8 i = 0; i < _tokenIds.length; i++) {
            _removeTrait(_tokenIds[i]);
        }
        return true;
    }

    function incrementCounter(uint32 _tokenId) public onlyAllowed {
        uint256 counter     = uint256(bytes32(getProperty("counter", _tokenId))) + 1;
        require(counter < 256, "GenericTrait: counter exceeds max (255)");
        setProperty("counter", _tokenId, abi.encodePacked(counter));
    }

    function decrementCounter(uint32 _tokenId) public onlyAllowed {
        uint256 counter     = uint256(bytes32(getProperty("counter", _tokenId)));
        require(counter > 0, "GenericTrait: attempt to decrement zero counter");
        uint256 cooldown    = uint256(bytes32(getProperty("cooldown", _tokenId)));
        setProperty("counter", _tokenId, abi.encodePacked(counter - 1));
        setProperty("activation", _tokenId, abi.encodePacked(block.timestamp + cooldown));
    }


    function currentTokenOwnerAddress(uint32 _tokenId) public view returns (address) {
        return IERC721(
            (GTRegistry.myCommunityRegistry()).getRegistryAddress(
                GTRegistry.TOKEN_KEY()
            )
        ).ownerOf(_tokenId);
    }

    modifier onlyAllowed() {
        require(
            GTRegistry.addressCanModifyTrait(msg.sender, traitId) ||
            galaxisRegistry.getRegistryAddress("ACTION_HUB") == msg.sender, "Trait: Not authorized.");
        _;
    }

}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.25;

import "../Generic/GenericTrait.sol";

contract TraitZERO is GenericTrait {
    
    function version() public pure override returns (uint256) {
        return 2023101501;
    }

    function TRAIT_TYPE() public pure override returns (uint16) {
        return 1;
    }

    constructor(address _galaxisRegistry) GenericTrait(_galaxisRegistry) {
        
    }

    function init() virtual override public {
        _initStandardProps();
        afterInit();
    }

}