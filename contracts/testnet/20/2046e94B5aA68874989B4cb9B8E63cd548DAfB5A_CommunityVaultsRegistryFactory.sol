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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
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
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract CommunityList is AccessControlEnumerable { 

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
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

interface IOwnable {
    function owner() external view returns (address);
}

contract CommunityRegistry is AccessControlEnumerable  {

    bytes32 public constant COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");


    uint32                      public  community_id;
    string                      public  community_name;
    address                     public  community_admin;

    mapping(bytes32 => address)         addresses;
    mapping(bytes32 => uint256)         uints;
    mapping(bytes32 => bool)            booleans;
    mapping(bytes32 => string)          strings;

   // mapping(address => bool)    public  admins;

    mapping(address => mapping(address => bool)) public app_admins;

    mapping (uint => string)    public  addressEntries;
    mapping (uint => string)    public  uintEntries;
    mapping (uint => string)    public  boolEntries;
    mapping (uint => string)    public  stringEntries;
    uint                        public  numberOfAddresses;
    uint                        public  numberOfUINTs;
    uint                        public  numberOfBooleans;
    uint                        public  numberOfStrings;

    uint                        public  nextAdmin;
    mapping(address => bool)    public  adminHas;
    mapping(uint256 => address) public  adminEntries;
    mapping(address => uint256) public  appAdminCounter;
    mapping(address =>mapping(uint256 =>address)) public appAdminEntries;

    address                     public  owner;

    bool                                initialised;

    bool                        public  independant;

    event IndependanceDay(bool gain_independance);

    modifier onlyAdmin() {
        require(isCommunityAdmin(COMMUNITY_REGISTRY_ADMIN),"CommunityRegistry : Unauthorised");
        _;
    }

    // function isCommunityAdmin(bytes32 role) public view returns (bool) {
    //     if (independant){        
    //         return(
    //             msg.sender == owner ||
    //             admins[msg.sender]
    //         );
    //     } else {            
    //        IAccessControlEnumerable ac = IAccessControlEnumerable(owner);   
    //        return(
    //             msg.sender == owner || 
    //             hasRole(DEFAULT_ADMIN_ROLE,msg.sender) ||
    //             ac.hasRole(role,msg.sender));
    //     }
    // }

    function isCommunityAdmin(bytes32 role) internal view returns (bool) {
        return isUserCommunityAdmin( role, msg.sender);
    }

    function isUserCommunityAdmin(bytes32 role, address user) public view returns (bool) {
        if (user == owner || hasRole(DEFAULT_ADMIN_ROLE,user) ) return true;
        if (independant){        
            return(
                hasRole(role,user)
            );
        } else {            
           IAccessControlEnumerable ac = IAccessControlEnumerable(owner);   
           return(
                ac.hasRole(role,user));
        }
    }

    function grantRole(bytes32 key, address user) public override(AccessControl,IAccessControl) onlyAdmin {
        _grantRole(key,user);
    }
 
    constructor (
        uint32  _community_id, 
        address _community_admin, 
        string memory _community_name
    ) {
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
        community_admin = _community_admin;
        _setupRole(DEFAULT_ADMIN_ROLE, community_admin); // default admin = launchpad
        owner = msg.sender;
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

    function setRegistryAddress(string memory fn, address value) external onlyAdmin {
        bytes32 hf = hash(fn);
        addresses[hf] = value;
        addressEntries[numberOfAddresses++] = fn;
        emit AddressChanged(fn,value);
    }

    function setRegistryBool(string memory fn, bool value) external onlyAdmin {
        bytes32 hf = hash(fn);
        booleans[hf] = value;
        boolEntries[numberOfBooleans++] = fn;
        emit BooleanChanged(fn,value);
    }

    function setRegistryString(string memory fn, string memory value) external onlyAdmin {
        bytes32 hf = hash(fn);
        strings[hf] = value;
        stringEntries[numberOfStrings++] = fn;
        emit StringChanged(fn,value);
    }

    function setRegistryUINT(string memory fn, uint value) external onlyAdmin {
        bytes32 hf = hash(fn);
        uints[hf] = value;
        uintEntries[numberOfUINTs++] = fn;
        emit UintChanged(fn,value);
    }

    function setAppAdmin(address app, address user, bool state) external {
        require(
            msg.sender == IOwnable(app).owner() ||
            app_admins[app][msg.sender],
            "You do not have access permission"
        );
        app_admins[app][user] = state;
        if (state)
            appAdminEntries[app][appAdminCounter[app]++] = user;
        emit AppAdminChanged(app,user,state);
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

 

    function isAppAdmin(address app, address user) external view returns (bool) {
        return 
            user == IOwnable(app).owner() ||
            app_admins[app][user];
    }
    
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IPaymentMatrix {
    function getDevIDAndAmountForTraitType(uint16 _traitType) external view returns(uint256 devId, uint256 amount);
    function getArtistIDAndAmountForCollection(uint32 _communityId, uint32 _collectionId) external view returns(uint256 artistId, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

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

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;
import "../Generic/GenericTrait.sol";

contract DigitalRedeem is GenericTrait {
    uint256 public vaultID;
    uint256 public redeemMode;

    function version() public pure override returns (uint256) {
        return 2023082701;
    }

    function TRAIT_TYPE() public pure override returns (uint16) {
        return 6;
    }

    function init() virtual override public {
        _initStandardProps();

        addStoredProperty(bytes32("vault_id"),                  FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("tokens_amount"),             FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("pseudo_random_interval"),    FieldTypes.STORED_UINT_256);
        addStoredProperty(bytes32("coin_token_address"),        FieldTypes.STORED_ADDRESS);
        addStoredProperty(bytes32("luck"),                      FieldTypes.STORED_UINT_8);
        addStoredProperty(bytes32("redeem_mode"),               FieldTypes.STORED_UINT_8);

        afterInit();

        vaultID = uint256(bytes32(getProperty("vault_id", 0)));
        redeemMode = uint256(bytes32(getProperty("redeem_mode", 0)));
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../../interfaces/IRegistryConsumer.sol";
import "../../../PaymentMatrix/IPaymentMatrix.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "hardhat/console.sol";

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


contract GenericTrait {

    IRegistryConsumer               GalaxisRegistry          = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

    uint16      public     traitId;
    IGTRegistry public     GTRegistry;
    event tokenTraitChangeEvent(uint32 indexed _tokenId);

    function baseVersion() public pure returns (uint256) {
        return 2023092801;
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

    function tellEverything() external view returns(traitInfo memory) {
        return traitInfo(
            traitId,
            TRAIT_TYPE(),
            address(GTRegistry),
            baseVersion(),
            version(),
            getSchema(),
            propertyCount,
            APP()
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

    bool initialized = false;

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
        bytes[] memory _defaultPropValues
    ) virtual public {
        traitId = _traitId;
        GTRegistry = IGTRegistry(_registry);
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
            IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F).getRegistryAddress("PAYMENT_MATRIX")
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
            _tokenSetBit(_tokenId, BitType.EXISTS, true);
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
            _tokenSetBit(_tokenId, BitType.EXISTS, true);
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
        return _tokenHasBit(_tokenId, BitType.EXISTS);
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
                    _tokenSetBit(_tokenIds[_id], BitType.EXISTS, true);
                    emit tokenTraitChangeEvent(_tokenIds[_id]);
                }
            } else {
                revert("Trait: Token already has trait!");
            }
        }
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
        delete storageData[_tokenId];
        for(uint8 _id = 0; _id < propertyCount; _id++) {
            FieldTypes thisPropType = property[_id]._type;
            if(thisPropType == FieldTypes.STORED_STRING || thisPropType == FieldTypes.STORED_BYTES) {
                delete storageMapArray[_id][_tokenId];
            }
        }
        _tokenSetBit(_tokenId, BitType.EXISTS, false);
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
        uint256 counter     = uint256(bytes32(getProperty("counter",    _tokenId))) + 1;
        require(counter < 256,"GenericTrait : counter exceeds max (255)");
        setProperty("counter",_tokenId,abi.encodePacked(counter));
    }

    function decrementCounter(uint32 _tokenId) public onlyAllowed {
        uint256 counter     = uint256(bytes32(getProperty("counter",    _tokenId)));
        require(counter > 0,"GenericTrait : attempt to decrement zero counter");
        setProperty("counter",_tokenId,abi.encodePacked(counter-1));
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
            GalaxisRegistry.getRegistryAddress("ACTION_HUB") == msg.sender, "Trait: Not authorized.");
        _;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRegistryConsumer {

    function getRegistryAddress(string memory key) external view returns (address) ;

    function getRegistryBool(string memory key) external view returns (bool);

    function getRegistryUINT(string memory key) external view returns (uint256) ;

    function getRegistryString(string memory key) external view returns (string memory) ;

    function isAdmin(address user) external view returns (bool) ;

    function isAppAdmin(address app, address user) external view returns (bool);

}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Create2.sol";

import "../Traits/interfaces/IRegistryConsumer.sol";
import "./interfaces/ICommunityVaultsRegistry.sol";
import "./interfaces/ICoinsVault.sol";
import "./interfaces/INFTVault.sol";

import "../@galaxis/registries/contracts/CommunityList.sol";
import "../@galaxis/registries/contracts/CommunityRegistry.sol";

contract CommunityVaultsRegistry is ICommunityVaultsRegistry {
    string public constant NFT_VAULT_IMPL_KEY = "GOLDEN_NFT_VAULT";
    string public constant COINS_VAULT_IMPL_KEY = "GOLDEN_COINS_VAULT";

    bytes32 public constant VAULTS_REGISTRY_ADMIN = keccak256("VAULTS_REGISTRY_ADMIN");

    IRegistryConsumer public galaxisRegistry;
    CommunityRegistry public communityRegistry;

    uint32 public communityId;
    uint256 public totalVaultsCount;

    mapping (uint8 => uint256) public vaultTypeNonces;

    // vault id => vault info
    mapping (uint256 => BaseVaultInfo) internal _vaultsInfo;

    modifier onlyVaultsRegistryAdmin() {
        _onlyVaultsRegistryAdmin();
        _;
    }

    constructor(uint32 communityId_, address galaxisRegistry_) {
        galaxisRegistry = IRegistryConsumer(galaxisRegistry_);

        CommunityList communityList_ = CommunityList(galaxisRegistry.getRegistryAddress("COMMUNITY_LIST"));

        (,address crAddr_,) = communityList_.communities(communityId_);

        if (crAddr_ == address(0)) {
            revert CommunityVaultsRegistryInvalidCommunityId(communityId_);
        }

        communityRegistry = CommunityRegistry(crAddr_);

        communityId = communityId_;
    }

    function createNFTVault(
        string calldata vaultName_,
        INFTVault.BuyNftSettings calldata buyNFTSettings_,
        IGenericVault.ReceivablesWhitelistEntry[] calldata whitelistedEntries_,
        IGenericVault.RedeemModesUpdateEntry[] calldata redeemModesUpdateEntries_
    ) external override onlyVaultsRegistryAdmin returns (address) {
        INFTVault newNFTVault_ = INFTVault(_deployVault(
            galaxisRegistry.getRegistryAddress(NFT_VAULT_IMPL_KEY),
            VaultTypes.NFTVault,
            vaultName_
        ));

        newNFTVault_.__NFTVault_init(
            galaxisRegistry,
            communityRegistry,
            buyNFTSettings_,
            whitelistedEntries_,
            redeemModesUpdateEntries_
        );

        return address(newNFTVault_);
    }

    function createCoinsVault(
        string calldata vaultName_,
        IGenericVault.ReceivablesWhitelistEntry[] calldata whitelistedEntries_,
        IGenericVault.RedeemModesUpdateEntry[] calldata redeemModesUpdateEntries_
    ) external override onlyVaultsRegistryAdmin returns (address) {
        ICoinsVault newCoinsVault_ = ICoinsVault(_deployVault(
            galaxisRegistry.getRegistryAddress(COINS_VAULT_IMPL_KEY),
            VaultTypes.CoinsVault,
            vaultName_
        ));

        newCoinsVault_.__CoinsVault_init(
            galaxisRegistry,
            communityRegistry,
            whitelistedEntries_,
            redeemModesUpdateEntries_
        );

        return address(newCoinsVault_);
    }

    function getVaultAddress(
        VaultTypes vaultType_,
        uint256 vaultTypeNonce_
    ) external view override returns (address) {
        address communityVaultsImpl_ = vaultType_ == VaultTypes.NFTVault
            ? galaxisRegistry.getRegistryAddress(NFT_VAULT_IMPL_KEY)
            : galaxisRegistry.getRegistryAddress(COINS_VAULT_IMPL_KEY);

        return getVaultAddress(communityVaultsImpl_, vaultType_, vaultTypeNonce_);
    }

    function getVaultAddress(
        address implementation_,
        VaultTypes vaultType_,
        uint256 vaultTypeNonce_
    ) public view override returns (address) {
        bytes32 bytecodeHash_ = keccak256(_creationCode(implementation_, vaultType_, vaultTypeNonce_));

        return Create2.computeAddress(bytes32(0), bytecodeHash_);
    }

    function getVaultAddressById(uint256 vaultId_) external view override returns (address) {
        return _vaultsInfo[vaultId_].vaultAddr;
    }

    function getVaultsInfo(
        uint256[] calldata vaultIds_
    ) external view override returns (VaultInfo[] memory resultArr_) {
        resultArr_ = new VaultInfo[](vaultIds_.length);

        for (uint256 i = 0; i < vaultIds_.length; i++) {
            VaultInfo memory currentVaultInfo_ = VaultInfo(
                _vaultsInfo[vaultIds_[i]],
                INFTVault.BuyNftSettings(0, IGenericVault.RedeemModes.RANDOM_REDEEM, false, "")
            );

            if (currentVaultInfo_.baseVaultInfo.vaultType == VaultTypes.NFTVault) {
                currentVaultInfo_.buyNFTSettings = INFTVault(currentVaultInfo_.baseVaultInfo.vaultAddr).getBuyNftSettings();
            }

            resultArr_[i] = currentVaultInfo_;
        }
    }

    function hasVaultsRegistryAdminRole(address userAddr_) public view override returns (bool) {
        return _hasRole(VAULTS_REGISTRY_ADMIN, userAddr_);
    }

    function _deployVault(
        address implementation_,
        VaultTypes vaultType_,
        string calldata vaultName_
    ) internal returns (address) {
        if (implementation_ == address(0)) {
            revert CommunityVaultsRegistryZeroVaultsGolden();
        }

        if (bytes(vaultName_).length == 0) {
            revert CommunityVaultsRegistryInvalidVaultName();
        }

        uint256 currentVaultTypeNonce_ = vaultTypeNonces[uint8(vaultType_)]++;

        bytes memory creationCode_ = _creationCode(implementation_, vaultType_, currentVaultTypeNonce_);

        address vaultAddr_ = Create2.deploy(0, 0, creationCode_);

        if (vaultAddr_ == address(0)) {
            revert CommunityVaultsRegistryVaultCreationFailed();
        }

        uint256 vaultId_ = totalVaultsCount++;

        _vaultsInfo[vaultId_] = BaseVaultInfo(
            vaultAddr_,
            vaultType_,
            currentVaultTypeNonce_,
            vaultName_
        );

        emit VaultCreated(vaultId_, vaultAddr_, vaultType_, currentVaultTypeNonce_);

        return vaultAddr_;
    }

    function _hasRole(bytes32 roleKey_, address userAddr_) internal view returns (bool) {
        return communityRegistry.hasRole(roleKey_, userAddr_);
    }

    function _onlyVaultsRegistryAdmin() internal view {
        if (!hasVaultsRegistryAdminRole(msg.sender)) {
            revert CommunityVaultsRegistryUnauthorized();
        }
    }

    function _creationCode(
        address implementation_,
        VaultTypes vaultType_,
        uint256 vaultTypeNonce_
    ) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation_,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(communityId, vaultType_, vaultTypeNonce_)
            );
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "../@galaxis/registries/contracts/CommunityList.sol";
import "../@galaxis/registries/contracts/CommunityRegistry.sol";

import "../Traits/extras/recovery/BlackHolePrevention.sol";
import "../Traits/interfaces/IRegistryConsumer.sol";
import "../vaults/CommunityVaultsRegistry.sol";

contract CommunityVaultsRegistryFactory is BlackHolePrevention {
    using Strings  for uint32; 

    uint256     public constant     version                  = 20230814;

    address     public constant     GALAXIS_REGISTRY         = 0x1e8150050A7a4715aad42b905C08df76883f396F;
    string      public constant     REGISTRY_KEY_FACTORY     = "COMMUNITY_VAULTS_REGISTRY_FACTORY";
    string      public constant     VAULTS_REGISTRY_KEY      = "COMMUNITY_VAULTS_REGISTRY";
    bytes32     public constant     COMMUNITY_REGISTRY_ADMIN = keccak256("COMMUNITY_REGISTRY_ADMIN");
    bytes32     public constant     VAULTS_REGISTRY_ADMIN = keccak256("VAULTS_REGISTRY_ADMIN");
    bytes32     public constant     VAULTS_ADMIN = keccak256("VAULTS_ADMIN");

    // Errors
    error CommunityVaultsRegistryFactoryNotCurrent(address);
    error CommunityVaultsRegistryFactoryInvalidCommunityId(uint32);
    error CommunityVaultsRegistryFactoryAlreadyExistingVaultRegistry(uint32);
    error CommunityVaultsRegistryFactoryUnauthorized();

    event CommunityVaultsRegistryDeployed(uint32 communityId, address communityVaultsRegistry);

    function deploy(
        uint32 communityId_
    ) external returns (address) {
        IRegistryConsumer galaxisRegistry_ = IRegistryConsumer(GALAXIS_REGISTRY);

        if(galaxisRegistry_.getRegistryAddress(REGISTRY_KEY_FACTORY) != address(this)) {
            revert CommunityVaultsRegistryFactoryNotCurrent(address(this));
        }

        CommunityList communityList_ = CommunityList(galaxisRegistry_.getRegistryAddress("COMMUNITY_LIST"));

        (,address crAddr_,) = communityList_.communities(communityId_);

        if(crAddr_ == address(0)) {
            revert CommunityVaultsRegistryFactoryInvalidCommunityId(communityId_);
        }

        CommunityRegistry communityRegistry_ = CommunityRegistry(crAddr_);

        if(communityRegistry_.getRegistryAddress(VAULTS_REGISTRY_KEY) != address(0)) {
            revert CommunityVaultsRegistryFactoryAlreadyExistingVaultRegistry(communityId_);
        }

        if(!communityRegistry_.isUserCommunityAdmin(COMMUNITY_REGISTRY_ADMIN, msg.sender)) {
            revert CommunityVaultsRegistryFactoryUnauthorized();
        }

        CommunityVaultsRegistry newCommunityVaultsRegistry_ = new CommunityVaultsRegistry(communityId_, GALAXIS_REGISTRY);

        communityRegistry_.setRegistryAddress(VAULTS_REGISTRY_KEY, address(newCommunityVaultsRegistry_));

        communityRegistry_.grantRole(VAULTS_REGISTRY_ADMIN, msg.sender);
        communityRegistry_.grantRole(VAULTS_ADMIN, msg.sender);
        
        emit CommunityVaultsRegistryDeployed(communityId_, address(newCommunityVaultsRegistry_));

        return address(newCommunityVaultsRegistry_);
    }
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "./IGenericVault.sol";

interface ICoinsVault is IGenericVault {
    /**
     * @dev Error emitted when there's an attempt to redeem coins with invalid data
     * @param _address Address of coin token
     * @param _value Amount of tokens
     */
    error CoinsVaultInvalidCoinsRedeemData(address _address, uint256 _value);

    /**
     * @dev Initializes the coins vault with the given parameters
     * @param galaxisRegistry_ An address of the galaxis registry
     * @param communityVaultsRegistry_ An address of the community vaults registry
     * @param whitelistEntries_ An array of whitelist tokens for the vault
     * @param redeemModesUpdateEntries_ An array of able redeem modes for the vault
     */
    function __CoinsVault_init(
        IRegistryConsumer galaxisRegistry_,
        CommunityRegistry communityVaultsRegistry_,
        ReceivablesWhitelistEntry[] calldata whitelistEntries_,
        RedeemModesUpdateEntry[] calldata redeemModesUpdateEntries_
    ) external;
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "./INFTVault.sol";

/**
 * @title ICommunityVaultsRegistry
 * @dev Interface that represents a registry for community vaults
 */
interface ICommunityVaultsRegistry {
    /**
     * @dev Enum representing the different types of vaults
     */
    enum VaultTypes {
        NFTVault,
        CoinsVault
    }

    /**
     * @dev Base structure for holding basic information about vaults
     */
    struct BaseVaultInfo {
        address vaultAddr;
        VaultTypes vaultType;
        uint256 vaultTypeNonce;
        string vaultName;
    }

    /**
     * @dev Structure for holding detailed information about vault including buy NFT settings
     */
    struct VaultInfo {
        BaseVaultInfo baseVaultInfo;
        INFTVault.BuyNftSettings buyNFTSettings;
    }

    /**
     * @dev Emitted when a new vault is created
     * @param vaultId The ID of the created vault
     * @param vaultAddr The address of the created vault
     * @param vaultType The type of the created vault
     * @param vaultTypeNonce The nonce of the vault
     */
    event VaultCreated(uint256 vaultId, address vaultAddr, VaultTypes vaultType, uint256 vaultTypeNonce);

    /* 
     * @dev Indicates that the provided vault name is empty
     */
    error CommunityVaultsRegistryInvalidVaultName();

    /* 
     * @dev Indicates that the caller does not have the required permissions for the operation
     */
    error CommunityVaultsRegistryUnauthorized();

    /* 
     * @dev Indicates that there are zero golden vaults
     */
    error CommunityVaultsRegistryZeroVaultsGolden();

    /* 
     * @dev Indicates a failure during the creation of a vault
     */
    error CommunityVaultsRegistryVaultCreationFailed();

    /* 
     * @dev Indicates that the provided community ID doesn't exists
     */
    error CommunityVaultsRegistryInvalidCommunityId(uint32 communityId);

    /* 
     * @dev Indicates that the provided vault ID doesn't exists
     */
    error CommunityVaultsRegistryInvalidVaultId(uint256 vaultId);

    /**
     * @dev Creates a new NFT vault
     * @param vaultName_ Name of the vault
     * @param buyNFTSettings_ NFT buying settings
     * @param whitelistedEntries_ List of whitelisted tokens
     * @param redeemModesUpdateEntries_ List of redeem modes that are able
     * @return Address of the newly created NFT vault
     */
    function createNFTVault(
        string calldata vaultName_,
        INFTVault.BuyNftSettings calldata buyNFTSettings_,
        IGenericVault.ReceivablesWhitelistEntry[] calldata whitelistedEntries_,
        IGenericVault.RedeemModesUpdateEntry[] calldata redeemModesUpdateEntries_
    ) external returns (address);

    /**
     * @dev Creates a new coins vault
     * @param vaultName_ Name of the vault
     * @param whitelistedEntries_ List of whitelisted tokens
     * @param redeemModesUpdateEntries_ List of redeem modes that are able
     * @return Address of the newly created coins vault
     */
    function createCoinsVault(
        string calldata vaultName_,
        IGenericVault.ReceivablesWhitelistEntry[] calldata whitelistedEntries_,
        IGenericVault.RedeemModesUpdateEntry[] calldata redeemModesUpdateEntries_
    ) external returns (address);

    /**
     * @dev Retrieves the address of a vault by its type and nonce
     * @param vaultType_ Type of the vault
     * @param vaultTypeNonce_ Nonce of the vault
     * @return Address of the vault
     */
    function getVaultAddress(
        VaultTypes vaultType_,
        uint256 vaultTypeNonce_
    ) external view returns (address);

    /**
     * @dev Retrieves the address of a vault by its implementation, type, and nonce
     * @param implementation_ Address of the implementation
     * @param vaultType_ Type of the vault
     * @param vaultTypeNonce_ Nonce of the vault
     * @return Address of the vault
     */
    function getVaultAddress(
        address implementation_,
        VaultTypes vaultType_,
        uint256 vaultTypeNonce_
    ) external view returns (address);

    /**
     * @dev Retrieves the address of a vault by its ID
     * @param vaultId_ ID of the vault
     * @return Address of the vault
     */
    function getVaultAddressById(uint256 vaultId_) external view returns (address);

    /**
     * @dev Retrieves detailed information about multiple vaults by their IDs.
     * @param vaultIds_ List of vault IDs
     * @return resultArr_ Array of vault information
     */
    function getVaultsInfo(
        uint256[] calldata vaultIds_
    ) external view returns (VaultInfo[] memory resultArr_);

    /**
     * @dev Checks if an address has admin permissions for the vaults registry
     * @param userAddr_ Address to check
     * @return True if the address has admin permissions, false otherwise
     */
    function hasVaultsRegistryAdminRole(address userAddr_) external view returns (bool);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import {CommunityRegistry} from "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import {IRegistryConsumer} from "../../Traits/interfaces/IRegistryConsumer.sol";
import {DigitalRedeem} from "../../Traits/Implementers/DigitalRedeem/DigitalRedeem.sol";
import {ICommunityVaultsRegistry} from "./ICommunityVaultsRegistry.sol";

/**
 * @title IGenericVault
 * @dev Interface for generic vault operations
 */
interface IGenericVault {

    /**
     * @dev Enum representing the different types of tokens supported by the vault
     */
    enum TokenTypes {
        ERC20,
        ERC721,
        ERC1155
    }

    /**
     * @dev Enum representing the different redeem modes supported by the vault
     */
    enum RedeemModes {
        RANDOM_REDEEM,
        SEQUENTIAL_REDEEM,
        DIRECT_SELECT,
        DET_PSEUDO_RANDOM,
        COINS_REDEEM
    }

    /**
     * @dev Structure for whitelisting receivable tokens
     */
    struct ReceivablesWhitelistEntry {
        address tokenAddr;
        TokenTypes tokenType;
        bool isAdding;
    }

    /**
     * @dev Structure for updating supported redeem modes
     */
    struct RedeemModesUpdateEntry {
        RedeemModes redeemMode;
        bool isAdding;
    }

    /**
     * @dev Structure holding info about whitelisted tokens
     */
    struct WhitelistedTokenInfo {
        address tokenAddr;
        TokenTypes tokenType;
    }

    /**
     * @dev Parameters required for withdrawal of tokens
     */
    struct WithdrawParams {
        address tokenAddr;
        address tokenRecipient;
        uint256 tokenId;
        uint256 tokensAmount;
        TokenTypes tokenType;
    }

    /**
     * @dev Parameters required for withdrawal of traits
     */
    struct TraitWithdrawParams {
        DigitalRedeem trait;
        uint32 tokenId;
        bytes redeemData;
    }

    /**
     * @dev Raised when provided token is not valid for receivables whitelist
     */
    error GenericVaultInvalidReceivablesWhitelistToken(address tokenAddr);

    /**
     * @dev Raised when a provided redeem mode is unsupported
     */
    error GenericVaultUnsupportedRedeemMode(RedeemModes redeemMode);

    /**
     * @dev Raised when a trait is unactive
     */
    error GenericVaultUnactiveTrait(address trait, uint32 tokenId);

    /**
     * @dev Raised when an invalid type is used for withdrawal
     */
    error GenericVaultInvalidWithdrawType();

    /**
     * @dev Raised when a token is not present in the receivables whitelist
     */
    error GenericVaultNotInAReceivablesWhitelist(address tokenAddr);

    /**
     * @dev Raised when provided token type is invalid for the vault type
     */
    error GenericVaultInvalidTokenType(ICommunityVaultsRegistry.VaultTypes vaultType, TokenTypes tokenType);

    /**
     * @dev Raised when an unsupported interface is used
     */
    error GenericVaultUnsupportedInterface(bytes4 interfaceId, address tokenAddr);

    /**
     * @dev Raised when a user is unauthorized for a particular role
     */
    error GenericVaultUnauthorized(bytes32 role, address userAddr);

    /**
     * @notice Updates the whitelist for receivable tokens
     * @param entriesToUpdate_ List of tokens to be updated
     */
    function updateReceivablesWhitelist(ReceivablesWhitelistEntry[] calldata entriesToUpdate_) external;

    /**
     * @notice Updates the supported redeem modes for the vault
     * @param entriesToUpdate_ List of redeem modes to be updated
     */
    function updateSupportedRedeemModes(RedeemModesUpdateEntry[] calldata entriesToUpdate_) external;

    /**
     * @notice Allows the withdrawal of tokens from the vault
     * @param withdrawParams_ Parameters required for withdrawal
     */
    function withdraw(WithdrawParams memory withdrawParams_) external;

    /**
     * @notice Allows batch withdrawal of tokens from the vault
     * @param withdrawParamsArr_ Array of parameters required for withdrawals
     */
    function withdrawBatch(WithdrawParams[] memory withdrawParamsArr_) external;

    /**
     * @notice Allows withdrawal by traits from the vault
     * @param traitWithdrawParams_ Parameters required for trait withdrawal
     */
    function traitWithdraw(TraitWithdrawParams memory traitWithdrawParams_) external;

    /**
     * @notice Fetches information about the vault
     * @return communityId_ ID of the community associated with the vault
     * @return vaultType_ Type of the vault
     * @return vaultTypeNonce_ Nonce of the vault
     */
    function getVaultInfo()
        external
        view 
        returns (
            uint32 communityId_,
            uint8 vaultType_,
            uint256 vaultTypeNonce_
        );
    
    /**
     * @notice Fetches the whitelist of receivable tokens
     * @return An array of addresses representing the whitelist
     */
    function getReceivablesWhitelist() external view returns (address[] memory);

    /**
     * @notice Fetches the supported redeem modes
     * @return An array of supported redeem modes
     */
    function getSupportedRedeemModes() external view returns (RedeemModes[] memory);

    /**
     * @notice Fetches information about whitelisted tokens
     * @return An array of WhitelistedTokenInfo structures
     */
    function getReceivablesWhitelistInfo() external view returns (WhitelistedTokenInfo[] memory);

    /**
     * @notice Fetches the type of a whitelisted token
     * @param whitelistedToken_ The address of the whitelisted token
     * @return The type of the whitelisted token
     */
    function getWhitelistedTokenType(address whitelistedToken_) external view returns (TokenTypes);

    /**
     * @notice Checks if a token is in the receivables whitelist
     * @param tokenAddr_ The address of the token to check
     * @return True if the token is in the whitelist, false otherwise
     */
    function isInReceivablesWhitelist(address tokenAddr_) external view returns (bool);

    /**
     * @notice Checks if a redeem mode is supported by the vault
     * @param redeemMode_ The redeem mode to check
     * @return True if the redeem mode is supported, false otherwise
     */
    function isRedeemModeSupported(RedeemModes redeemMode_) external view returns (bool);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import {CommunityRegistry} from "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import {IRegistryConsumer} from "../../Traits/interfaces/IRegistryConsumer.sol";
import {GenericTrait} from "../../Traits/Implementers/Generic/GenericTrait.sol";
import {IGenericVault} from "./IGenericVault.sol";

/**
 * @title INFTVault
 * @dev Interface defining operations and data structures for the NFTVault
 */
interface INFTVault is IGenericVault {

    /**
     * @dev Represents settings for purchasing NFTs
     */
    struct BuyNftSettings {
        uint256 buyNFTPrice;           // Price to buy the NFT
        RedeemModes redeemMode;        // Mode of redeeming
        bool isNFTBuyable;             // Whether the NFT is buyable or not
        bytes specialRedeemData;      // Additional data for special redeem operations
    }

    /**
     * @dev Contains details about a token
     */
    struct TokenInfo {
        address tokenAddr;             // Address of the token
        uint256 tokenId;               // ID of the token
        TokenTypes tokenType;          // Type of the token
    }

    /**
     * @dev Contains data for random redeem
     */
    struct RandomRedeemData {
        address recipientAddr;         // Recipient address
        TokenInfo tokenInfo;           // Information about the token
        uint256 randomNumber;          // Generated random number
        uint8 luck;                    // Luck metric in persent
    }

    /**
     * @dev Contains data for direct selection of tokens
     */
    struct DirectSelectData {
        address recipient;             // Recipient address
        TokenInfo tokenInfo;           // Information about the token is wanted to be selected
    }  
    
    /**
     * @dev Thrown when the special redeem data is not valid for the redeem mode
     */
    error NFTVaultInvalidSpecialRedeemData(RedeemModes, bytes);

    /**
     * @dev Thrown when provided NFT buy data is invalid
     */
    error NFTVaultInvalidNFTBuyData(address nftAddr, uint256 tokenId);

    /**
     * @dev Thrown when either the payment token address is invalid or the sender address is zero
     */
    error NFTVaultInvalidPaymentTokenOrSender(address tokenAddr);

    /**
     * @dev Thrown when the user balance is lower than NFT price
     */
    error NFTVaultNotEnoughTokensToBuy(uint256 userBalance, uint256 tokenPrice);

    /**
     * @dev Thrown when the request ID is not exists
     */
    error NFTVaultInvalidRequestId(uint256 requestId);

    /**
     * @dev Thrown when the request ID has already been processed
     */
    error NFTVaultRequestIdHasAlreadyBeenProcessed(uint256 requestId);

    /**
    * @dev Triggered when the total NFT supply amount is not enough
    */
    error NFTVaultInvalidTotalNFTSupplyAmount();

    /**
    * @dev Triggered when NFTs is not buyable
    */
    error NFTVaultUnableToBuyNFTs();

    /**
    * @dev Triggered when an address used is the zero address
    */
    error NFTVaultZeroAddress();

    /**
    * @dev Triggered when the pseudo-random equals to 0
    */
    error NFTVaultInvalidPseudoRandomInterval();

    /**
    * @dev Triggered when there's an issue with the sequential data used
    */
    error NFTVaultInvalidSequentialData();

    /**
     * @dev Emitted when an NFT has been successfully sold
     */
    event NFTSold(address nftRecipient, address indexed nftAddr, uint256 tokenId, uint256 paymentTokensAmount);

    /**
    * @dev Initializes the NFTVault with necessary settings and configurations
    * @param galaxisRegistry_ The address of the Galaxis registry
    * @param communityVaultsRegistry_ The address of the community vaults registry
    * @param newBuyNFTSettings_ Settings related to buying NFTs
    * @param whitelistEntries_ List of entries to be whitelisted
    * @param redeemModesUpdateEntries_ List of able redeem modes
    */
    function __NFTVault_init(
        IRegistryConsumer galaxisRegistry_,
        CommunityRegistry communityVaultsRegistry_,
        BuyNftSettings calldata newBuyNFTSettings_,
        ReceivablesWhitelistEntry[] calldata whitelistEntries_,
        RedeemModesUpdateEntry[] calldata redeemModesUpdateEntries_
    ) external;

    /**
    * @dev Updates the settings related to purchasing NFTs
    * @param newBuyNFTSettings_ new NFT buy settings
    */
    function updateBuyNFTSettings(
        BuyNftSettings calldata newBuyNFTSettings_
    ) external;

    function buyTokens(bytes calldata userData_) external;

    /**
    * @dev Returns the total supply amount of the NFTVault
    * @return Total NFT supply amount
    */
    function totalNFTVaultSupplyAmount() external view returns (uint256);

    /**
    * @dev Gets the number of pending NFTs (for random withdraw)
    * @return Amount of pending NFTs
    */
    function pendingNFTsAmount() external view returns (uint256);

    /**
    * @dev Returns the settings related to purchasing NFTs
    * @return BuyNftSettings structure containing purchase settings
    */
    function getBuyNftSettings() external view returns (BuyNftSettings memory);

    /**
    * @dev Retrieves the random redeem data associated with a specific request ID
    * @param requestId_ The ID of the request to fetch data for
    * @return RandomRedeemData structure containing details of the redeem request associated with the given ID
    */
    function getRandomRedeemData(uint256 requestId_) external view returns (RandomRedeemData memory);

    /**
    * @dev Fetches the last random request ID for a specific trait and token ID
    * @param trait_ Address of the given trait
    * @param tokenId_ The community token ID
    * @return Last random request ID
    */
    function getLastRandomRequestIdForTrait(
        GenericTrait trait_,
        uint32 tokenId_
    ) external view returns (uint256);

    /**
    * @dev Fetches the last random request ID associated with a user address (for buy)
    * @param userAddr_ Address of the user
    * @return Last random request ID
    */
    function getLastRandomRequestIdForUser(
        address userAddr_
    ) external view returns (uint256);

    /**
    * @dev Fetches all random request IDs associated with a specific trait and community token ID
    * @param trait_ The given trait
    * @param tokenId_ The token ID
    * @return Array containing all random request IDs for the trait and community token ID
    */
    function getAllRandomRequestIdsForTrait(
        GenericTrait trait_,
        uint32 tokenId_
    ) external view returns (uint256[] memory);

    /**
    * @dev Retrieves all random request IDs associated with a user address
    * @param userAddr_ Address of the user
    * @return Array containing all random request IDs for the user address
    */
    function getAllRandomRequestIdsForUser(
        address userAddr_
    ) external view returns (uint256[] memory);

    /**
    * @dev Obtains token information for a pseudo-random process based on a trait and token ID
    * @param trait_ The given trait
    * @param tokenId_ Specific token ID
    * @return TokenInfo structure containing details of the token for the trait and token ID
    */
    function getTokenInfoForPseudoRandomForTrait(
        GenericTrait trait_,
        uint32 tokenId_
    ) external view returns (TokenInfo memory);

    /**
    * @dev Retrieves token information for a pseudo-random process based on a buyer's address
    * @param buyer_ Address of the buyer
    * @return TokenInfo structure containing details of the token for the buyer
    */
    function getTokenInfoForPseudoRandomForBuy(
        address buyer_
    ) external view returns (TokenInfo memory);

    /**
    * @dev Obtains token information based on a given random number
    * @param randomNumber_ The random number to search by
    * @return tokenInfo_ TokenInfo structure related to the provided random number
    */
    function getTokenInfoByRandomNumber(uint256 randomNumber_) external view returns (TokenInfo memory tokenInfo_);

    /**
    * @dev Determines the amount of NFTs that are available (without pending one) 
    * @return Amount of free NFTs available
    */
    function getFreeNFTSupplyAmount() external view returns (uint256);

    /**
    * @dev Determines the account key based on a trait and token ID
    * @param trait_ Address of the given trait
    * @param tokenId_ Specific token ID
    * @return Account key derived from trait and token ID
    */
    function getTraitAccountKey(address trait_, uint32 tokenId_) external view returns (bytes32);

    /**
    * @dev Determines the account key for a specific user address
    * @param userAddr_ Address of the user
    * @return Account key for the user
    */
    function getAccountKey(address userAddr_) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS =
        0x000000000000000000636F6e736F6c652e6c6f67;

    function _sendLogPayloadImplementation(bytes memory payload) internal view {
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            pop(
                staticcall(
                    gas(),
                    consoleAddress,
                    add(payload, 32),
                    mload(payload),
                    0,
                    0
                )
            )
        }
    }

    function _castToPure(
      function(bytes memory) internal view fnIn
    ) internal pure returns (function(bytes memory) pure fnOut) {
        assembly {
            fnOut := fnIn
        }
    }

    function _sendLogPayload(bytes memory payload) internal pure {
        _castToPure(_sendLogPayloadImplementation)(payload);
    }

    function log() internal pure {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }
    function logInt(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}