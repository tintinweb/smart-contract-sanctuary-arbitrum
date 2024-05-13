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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
import "./Versionable/IVersionable.sol";

contract CommunityList is AccessControlEnumerable, IVersionable { 

    function version() external pure returns (uint256) {
        return 2024040301;
    }

    bytes32 public constant CONTRACT_ADMIN = keccak256("CONTRACT_ADMIN");


    uint256                              public numberOfEntries;

    struct community_entry {
        string      name;
        address     registry;
        uint32      id;
    }
    
    mapping(uint32 => community_entry)  public communities;   // community_id => record
    mapping(uint256 => uint32)           public index;         // entryNumber => community_id for enumeration

    event CommunityAdded(uint256 pos, string community_name, address community_registry, uint32 community_id);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN,msg.sender);
    }

    function addCommunity(uint32 community_id, string memory community_name, address community_registry) external onlyRole(CONTRACT_ADMIN) {
        uint256 pos = numberOfEntries++;
        index[pos]  = community_id;
        communities[community_id] = community_entry(community_name, community_registry, community_id);
        emit CommunityAdded(pos, community_name, community_registry, community_id);
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.25;

import "./UsesGalaxisRegistry.sol";

// EIP 1167 MinimalProxy Contract
contract NewProxy  is UsesGalaxisRegistry {
    error FailedCreateClone();

    constructor(address _galaxisRegistry) UsesGalaxisRegistry(_galaxisRegistry) {
    }

    function newProxy(string memory golden) public payable returns (address result) {
        address target = galaxisRegistry.getRegistryAddress(golden);
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
        if (result == address(0)) {
            revert FailedCreateClone();
        }
    }


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

interface IRNG_multi_requestor {
    function multi_process(uint256[] memory randomWords, uint256 _requestId) external;
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.25;

interface IRNG_single_requestor {
    function process(uint256 rand, uint256 requestId) external;
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.25;

interface IRNG2 {
    function requestRandomNumber( ) external returns (uint256);
    function requestRandomNumberWithCallback( ) external returns (uint256);
    function isRequestComplete(uint256 requestId) external view returns (bool isCompleted);
    function randomNumber(uint256 requestId) external view returns (uint256 randomNum);
    function requestRandomWords(uint32 numberOfWords, uint speed) external returns (uint256);
    function requestRandomWordsAdvanced(uint32 numberOfWords, uint speed , uint32 _callbackGasLimit, uint16 _requestConfirmations) external returns (uint256) ;
    function requestRandomWordsWithCallback(uint32 numberOfWords, uint speed) external returns (uint256);
    function requestRandomWordsAdvancedWithCallback(uint32 numberOfWords, uint speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) external returns (uint256) ;

}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../@galaxis/registries/contracts/CommunityList.sol";
import "../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../@galaxis/registries/contracts/NewProxy.sol";

import "./UserRandom.sol";
import "./VRFCoordinatorV2Interface.sol";

// https://docs.chain.link/vrf/v2/subscription/examples/programmatic-subscription

// change - 20231010
//          protect the cancel subscription function
//          allow checking old subscription manager and finding it

struct SubscriptionStatus {
    uint256     created;
    bool        active;
    address     random;
}

interface ISubscriptionManager {
    function createSubscription(uint32 community_id) external;
    function communitySubscriptions(uint32) external view returns (uint64);
    function subscriptionStatuses(uint64) external view returns (SubscriptionStatus memory);
}


contract SubscriptionManager is BlackHolePrevention, NewProxy {
    using Strings for uint256;

    function version() virtual external view returns(uint256) {
        return 2024040401;
    }

    VRFCoordinatorV2Interface            public immutable vrf;
    
    mapping(uint32 => uint64)             public communitySubscriptions;
    mapping(uint64 => SubscriptionStatus) public subscriptionStatuses;

    uint32                                public callbackGasLimit;
    uint16                                public requestConfirmations;
    uint256                               public defaultSpeedSetting;
    bytes32[]                                    __keys;
    ISubscriptionManager                         oldSubManager;


    // community_id (uint32) => vrf_subscription_id (uint64)

    event  SubscriptionCreated(uint32 community_id,uint64 sub_id);
    event  SubscriptionCancelled(uint32 community_id,uint64 sub_id);
    event  ConsumerAdded(uint32 community_id, uint64 sub_id, address consumer);
    event  ConsumerRemoved(uint32 community_id, uint64 sub_id, address consumer);
    event  RandomDeployed(uint32 community_id,address random);

    event DefaultGasLimitChanged(address admin,uint32 newLimit);
    event DefaultGasPriceChanged(address admin,uint256 newPrice);
    event DefaultConfsChanged(address admin,uint16 newConfs);


    error AccountAlreadyHasRandom(uint32 community_id,address random);
    error SubscriptionNotActive(uint32 community_id);
    error GoldenRandomNotRegistered();
    error LookupNotRegistered();


    constructor(
        address _galaxisRegistry,
        VRFCoordinatorV2Interface _vrf, 
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint256 _defaultSpeedSetting,
        bytes32[] memory _keys,
        address _oldSubManager
    ) NewProxy(_galaxisRegistry){
        vrf  = _vrf;
        callbackGasLimit = _callbackGasLimit;
        defaultSpeedSetting = _defaultSpeedSetting;
        requestConfirmations = _requestConfirmations;
        __keys = _keys;
        oldSubManager = ISubscriptionManager(_oldSubManager);
    }

    function createSubscription(uint32 community_id) external onlyCommunityAdmin(community_id) {
        require(galaxisRegistry.getRegistryAddress("SUBSCRIPTION_MANAGER")==address(this),"SubscriptionManager : not current contract");
        require(!getSubscriptionStatus(community_id).active , "SubscriptionManager : You already have a current subscription"  );
        uint64 sub_id = vrf.createSubscription();
        communitySubscriptions[community_id] = sub_id;
        subscriptionStatuses[sub_id] = SubscriptionStatus(block.timestamp,true,address(0));
        address rand = deployRandomisation(community_id);
        _addConsumer(community_id,rand);
        addCommunityRegistryValues(community_id,rand);
        emit SubscriptionCreated(community_id,sub_id);
    }

    function getSubscriptionID(uint32 community_id) public view returns (uint64 sub) {
        sub = communitySubscriptions[community_id];
        if (sub != 0) return sub;
        if (address(oldSubManager) == address(0)) return 0;
        return oldSubManager.communitySubscriptions(community_id);
    }

    function getSubscriptionStatus(uint32 community_id) public view returns (SubscriptionStatus memory status) {
        uint64 sub = communitySubscriptions[community_id];
        if (sub != 0) return subscriptionStatuses[sub];
        if (address(oldSubManager) == address(0)) return status;
        return oldSubManager.subscriptionStatuses(oldSubManager.communitySubscriptions(community_id));
    }

    function findSubscriptionManager(uint32 community_id) public view returns (address) {
        if (communitySubscriptions[community_id] != 0) return address(this);
        if (address(oldSubManager) == address(0)) return address(0);
        if (oldSubManager.communitySubscriptions(community_id) != 0) return address(oldSubManager);
        return address(0);
    }

    function cancelSubscription(uint32 community_id) external onlyCommunityDefaultAdmin(community_id) {
        require (communitySubscriptions[community_id] != 0,"SubscriptionManager : subscription not found in this contract");
        require(subscriptionStatuses[community_id].active,"SubscriptionManager : subscription not active in this contract");
        uint64 sub_id = communitySubscriptions[community_id];
        vrf.cancelSubscription(sub_id,msg.sender);
        addCommunityRegistryValues(community_id,address(0));
        subscriptionStatuses[sub_id].active = false;
        emit SubscriptionCancelled(community_id,sub_id);
    }

    function communityRegistry(uint32 community_id) internal view returns (CommunityRegistry ca) {
        address community_list_address = galaxisRegistry.getRegistryAddress("COMMUNITY_LIST");
        CommunityList cl = CommunityList(community_list_address);
        (,address _ca,) = cl.communities(community_id);
        return CommunityRegistry(_ca);
    }

    function addConsumer(uint32 community_id, address consumer) external onlyCommunityAdmin(community_id) {
        _addConsumer(community_id,consumer);
    }

    function _addConsumer(uint32 community_id, address consumer) internal {
         uint64 sub_id = communitySubscriptions[community_id];
         require(sub_id != 0,"SubscriptionManager : subscription not found in this contract" );
         vrf.addConsumer(sub_id,consumer);
         emit ConsumerAdded(community_id, sub_id, consumer);
    }

    function removeConsumer(uint32 community_id,address consumer) external  onlyCommunityAdmin(community_id){
        uint64 sub_id = communitySubscriptions[community_id];
         require(sub_id != 0,"SubscriptionManager : subscription not found in this contract" );
        vrf.removeConsumer(sub_id,consumer);
        addCommunityRegistryValues(community_id,address(0));
        emit ConsumerRemoved(community_id, sub_id, consumer);
    }

    function subscriptionBalance(uint32 community_id) external view returns (uint256 balance) {
        uint64 sub_id = communitySubscriptions[community_id];
        (balance,,,) = vrf.getSubscription(sub_id);
    }

    function getConsumers(uint32 community_id) external view returns (address[] memory consumers) {
        uint64 sub_id = communitySubscriptions[community_id];
        (,,,consumers) = vrf.getSubscription(sub_id);
    }

    // ADMIN FUNCTIONS

    function setGasLimit(uint32 newLimit) external onlyTopLevelCommunityRegistryAdmin {
        callbackGasLimit = newLimit;
        emit DefaultGasLimitChanged(msg.sender,newLimit);
    }

    function setGasPrice(uint256 newValue) external onlyTopLevelCommunityRegistryAdmin {
        require(newValue < __keys.length,"Invalid value");
        defaultSpeedSetting = newValue;
        emit DefaultGasPriceChanged(msg.sender,newValue);
    }

    function setRequestConfirmations(uint16 newConfs) external onlyTopLevelCommunityRegistryAdmin {
        requestConfirmations = newConfs;
        emit DefaultConfsChanged(msg.sender,newConfs);
    }

    function replaceGasLanes(bytes32[] calldata gasLanes) external onlyTopLevelCommunityRegistryAdmin {
        __keys = gasLanes;
    }

    function addCommunityRegistryValues(uint32 communityId, address random) internal {
        CommunityRegistry cr = communityRegistry(communityId);
        cr.setRegistryAddress("USER_RANDOM",random);
    }

    function deployRandomisation(
        uint32 community_id
    ) internal returns (address) {
        UserRandom rand = UserRandom(newProxy("GOLDEN_USER_RANDOM"));
        subscriptionStatuses[community_id].random = address(rand);
        rand.init(
            community_id, 
            communitySubscriptions[community_id],
            callbackGasLimit,
            requestConfirmations,
            defaultSpeedSetting,
            __keys
        );
        emit RandomDeployed(community_id,address(rand));
        return address(rand);
    }

    function keys() external view returns (bytes32[] memory _keys) {
        uint256 len = __keys.length;
        _keys = new bytes32[](len);
        for (uint pos = 0; pos < len; pos++) {
            _keys[pos] = __keys[pos];
        }
    }

    modifier onlyCommunityAdmin(uint32 communityId) {
        CommunityRegistry cr = communityRegistry(communityId);
        require(cr.isUserCommunityAdmin(cr.COMMUNITY_REGISTRY_ADMIN(), msg.sender),
                string.concat("SubscriptionManager : unauthorised by community ",(uint256(communityId)).toString())
        );
        _;
    }

    modifier onlyCommunityDefaultAdmin(uint32 communityId) {
        CommunityRegistry cr = communityRegistry(communityId);
        require(cr.isUserCommunityAdmin(cr.DEFAULT_ADMIN_ROLE(), msg.sender),
                string.concat("SubscriptionManager : unauthorised by community ",(uint256(communityId)).toString())
        );
        _;
    }


    modifier onlyTopLevelCommunityRegistryAdmin() {
        CommunityRegistry cr = CommunityRegistry(galaxisRegistry.getRegistryAddress("GOLDEN_COMMUNITY_REGISTRY"));
        require(
            AccessControlEnumerable(galaxisRegistry.getRegistryAddress("ROLE_MANAGER")).hasRole(cr.COMMUNITY_REGISTRY_ADMIN(),msg.sender),
            "SubscriptionManager : unauthorised (global)"
        );
        _;
    }
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.25;

import "./VRFCoordinatorV2Interface.sol";

import "../@galaxis/registries/contracts/CommunityList.sol";
import "../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../@galaxis/registries/contracts/UsesGalaxisRegistry.sol";


import "../Traits/extras/recovery/BlackHolePrevention.sol";
import "./IRNG_single_requestor.sol";
import "./IRNG_multi_requestor.sol";
import "./IRNG2.sol";


interface sManager {
    function keys() external view returns (bytes32[] memory _keys);
    function callbackGasLimit() external view returns (uint32);
    function requestConfirmations() external view returns (uint16);
    function defaultSpeedSetting() external view returns (uint256);
}

// update 27 April 2023
// variable for default speed

contract UserRandom is Ownable, IRNG2, UsesGalaxisRegistry { 

    function version() virtual external view returns(uint256) {
        return 2024040401;
    }

    bytes32                     public constant RANDOM_CONSUMER = keccak256("RANDOM_CONSUMER");

    // Your subscription ID.
    uint64                      public subscriptionId;
    uint32                      public communityId;

    bytes32[]                   public keys;

    uint32                      public callbackGasLimit = 2000000;
    uint16                      public requestConfirmations = 3;
    uint256                     public defaultSpeedSetting = 0;

    bool                               initialised;

    mapping(uint256 => uint256) public repeats;
    mapping(uint256=>uint256[]) public multiword_responses;
    mapping(uint256=>bool)      public responded;
    mapping(uint256=>address)   public callbacks;
    mapping(uint256=>address)   public multiword_callbacks;

    uint256[]                   public requestIDs; 
    mapping(uint256 => uint32)         numberOfWordsRequested;

  
    event Request(address requestor, uint256 RequestID);
    event MultiWordRequest(address requestor,uint256 numberOfWords,uint256 speed,uint256 requestID);
    event RandomsReceived(uint256 requestId, uint256[] randomNumbers);
    event AuthChanged(address user,bool auth);
    event AdminChanged(address user,bool auth);


    event DefaultGasLimitChanged(address admin,uint32 newLimit);
    event DefaultGasPriceChanged(address admin,uint256 newPrice);
    event DefaultConfsChanged(address admin,uint16 newConfs);
    event DuplicateReply(uint256 ActualRequestId, uint256 OriginalRequestId);

    error OnlyCoordinatorCanFulfill(address have, address want);


    constructor(
        address _galaxisRegistry,
        uint32 _communityId,
        uint64 _subscriptionId,
        bytes32[] memory _keys
    )  UsesGalaxisRegistry(_galaxisRegistry){
        _init(_communityId,_subscriptionId);
        keys = _keys;
    }

    function _init(uint32 _communityId,uint64 _subscriptionId) internal {
        require(!initialised,"Already initialised");
        subscriptionId = _subscriptionId;
        communityId = _communityId;
        initialised = true;
    }

    function init(
        uint32 _communityId,
        uint64 _subscriptionId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint256 _defaultSpeedSetting,
        bytes32[] calldata _keys
        ) external {
        _init(_communityId,_subscriptionId);
        callbackGasLimit = _callbackGasLimit;
        defaultSpeedSetting = _defaultSpeedSetting;
        requestConfirmations = _requestConfirmations;
        keys = _keys;
    }

    // The core function to process randoms received - from VRFConsmerBaseV2

    function fulfillRandomWords(
        uint256 _requestId, /* requestId */
        uint256[] memory randomWords
    ) internal  {
        uint256 requestId;
        // is this a repeat response, if so - replace with original
        uint256 rv =  repeats[_requestId];
        if (rv == 0) {
          requestId = _requestId;
        } else {
          requestId = rv;
        }
        // is it already fulfilled ? if so, simply return
        if (responded[requestId]) {
          emit DuplicateReply(_requestId,requestId);
          return;
        }
        //
        multiword_responses[requestId] = randomWords;
        responded[requestId] = true;
        if (callbacks[requestId]!= address(0)) {
            IRNG_single_requestor(callbacks[requestId]).process(randomWords[0], requestId);
        }
        if (multiword_callbacks[requestId]!= address(0)) {
            IRNG_multi_requestor(multiword_callbacks[requestId]).multi_process(randomWords, requestId); 
        }
        emit RandomsReceived(requestId, randomWords);
    }

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != vrfCoordinator()) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator());
        }
        fulfillRandomWords(requestId, randomWords);
    }

    // 

    function vrfCoordinator() internal view returns (address) {
        return galaxisRegistry.getRegistryAddress("VRF_COORDINATOR");
    }

    function COORDINATOR() internal view returns (VRFCoordinatorV2Interface) {
        return VRFCoordinatorV2Interface(vrfCoordinator());
    }

    function requestCount() external view returns (uint256) {
        return requestIDs.length;
    }

    // Request single numbers

    function requestRandomNumber( ) public onlyRandomConsumer override returns (uint256) {
       uint256 requestId = _requestRandomWords(1, defaultSpeedSetting, callbackGasLimit, requestConfirmations);
       emit Request(msg.sender, requestId);
       return (requestId);
    }

    function requestRandomNumberWithCallback( ) public onlyRandomConsumer override returns (uint256) {
       uint256 requestId = _requestRandomWords(1, defaultSpeedSetting, callbackGasLimit, requestConfirmations);
       callbacks[requestId] = msg.sender;
       emit Request(msg.sender, requestId);
       return requestId;
    }

    // request multiple numbers

    function requestRandomWords(uint32 numberOfWords, uint speed) external override onlyRandomConsumer  returns (uint256) {
        // Will revert if subscription is not set and funded.
        return _requestRandomWords(numberOfWords, speed,callbackGasLimit, requestConfirmations);
    }

    function requestRandomWordsAdvanced(uint32 numberOfWords, uint speed , uint32 _callbackGasLimit, uint16 _requestConfirmations) external override onlyRandomConsumer  returns (uint256) {
        // Will revert if subscription is not set and funded.
        return _requestRandomWords(numberOfWords, speed,_callbackGasLimit, _requestConfirmations);
    }

    function requestRandomWordsWithCallback(uint32 numberOfWords, uint speed) external onlyRandomConsumer override returns (uint256) {
        // Will revert if subscription is not set and funded.
        return _requestRandomWordsAdvancedWithCallback(numberOfWords, speed,callbackGasLimit, requestConfirmations);
    }
  
    function requestRandomWordsAdvancedWithCallback(uint32 numberOfWords, uint speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) external onlyRandomConsumer override returns (uint256) {
        return _requestRandomWordsAdvancedWithCallback(numberOfWords, speed,_callbackGasLimit, _requestConfirmations);
    }

    function _requestRandomWordsAdvancedWithCallback(uint32 numberOfWords, uint speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) internal returns (uint256) {
        uint256 requestID =  _requestRandomWords(numberOfWords, speed,_callbackGasLimit, _requestConfirmations);
        multiword_callbacks[requestID] = msg.sender;
        emit MultiWordRequest(msg.sender,numberOfWords,speed,requestID);
        return requestID;
    }

    // BASE INTERNAL CALL

    function _requestRandomWords(uint32 numberOfWords, uint speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) internal returns (uint256){
        require(speed < keys.length,"Invalid speed");
        bytes32 keyHash = keys[speed];
        uint256 reply = COORDINATOR().requestRandomWords(
            keyHash,
            subscriptionId,
            _requestConfirmations,
            _callbackGasLimit,
            numberOfWords
        );
        requestIDs.push(reply);
        numberOfWordsRequested[reply] = numberOfWords;
        return reply;
    }

    // STATUS

    function isRequestComplete(uint256 requestId) external view override returns (bool isCompleted) {
        return responded[requestId];
    } 

    function randomNumber(uint256 requestId) external view override returns (uint256 randomNum) {
        require(this.isRequestComplete(requestId), "Not ready");
        return multiword_responses[requestId][0];
    }

    // ADMIN FUNCTIONS

    function setGasLimit(uint32 newLimit) external onlyCommunityAdmin {
        callbackGasLimit = newLimit;
        emit DefaultGasLimitChanged(msg.sender,newLimit);
    }

    function setGasPrice(uint256 newValue) external onlyCommunityAdmin {
        require(newValue < keys.length,"Invalid value");
        defaultSpeedSetting = newValue;
        emit DefaultGasPriceChanged(msg.sender,newValue);
    }

    function setRequestConfirmations(uint16 newConfs) external onlyCommunityAdmin {
        requestConfirmations = newConfs;
        emit DefaultConfsChanged(msg.sender,newConfs);
    }

    function replaceGasLanes(bytes32[] calldata gasLanes) external onlyCommunityAdmin {
        keys = gasLanes;
    }

    // REPEAT if original gets dropped

    function requestRepeatFor(uint256 requestId, uint _speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) external onlyCommunityAdmin {
        require(repeats[requestId] == 0,"This is not a root request");
        require(numberOfWordsRequested[requestId] > 0,"No previous request with this ID");
        require( _speed < keys.length,"Invalid Speed setting");
        uint256 req = _requestRandomWords( numberOfWordsRequested[requestId], _speed,  _callbackGasLimit, _requestConfirmations);
        repeats[req] = requestId;
    }

    // MODIFIERS

    function getCommunityRegistry() internal view returns (CommunityRegistry) {
        address community_list_address = galaxisRegistry.getRegistryAddress("COMMUNITY_LIST");
        (,address _communityRegistry,) = CommunityList(community_list_address).communities(communityId);
        return CommunityRegistry(_communityRegistry);
    }

    function updateDefaults() external onlyCommunityAdmin {
        sManager s = sManager(galaxisRegistry.getRegistryAddress("SUBSCRIPTION_MANAGER"));
        keys                 = s.keys();
        callbackGasLimit     = s.callbackGasLimit();
        requestConfirmations = s.requestConfirmations();
        defaultSpeedSetting  = s.defaultSpeedSetting();
    }

    modifier onlyCommunityAdmin() {
        CommunityRegistry communityRegistry = getCommunityRegistry();
        bytes32 COMMUNITY_REGISTRY_ADMIN = communityRegistry.COMMUNITY_REGISTRY_ADMIN();
        require(
            communityRegistry.isUserCommunityAdmin(COMMUNITY_REGISTRY_ADMIN, msg.sender) ||
            communityRegistry.hasRole(COMMUNITY_REGISTRY_ADMIN, msg.sender),
                "subscriptionManager : unauthorised"
        );
        _;
    }

    modifier onlyRandomConsumer() {
        CommunityRegistry communityRegistry = getCommunityRegistry();
        require(
            communityRegistry.isUserCommunityAdmin(RANDOM_CONSUMER, msg.sender) ||
            communityRegistry.hasRole(RANDOM_CONSUMER, msg.sender),
                "subscriptionManager : unauthorised"
        );
        _;

    }
 
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.25;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlackHolePrevention is Ownable {
    // blackhole prevention methods
    function retrieveETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}