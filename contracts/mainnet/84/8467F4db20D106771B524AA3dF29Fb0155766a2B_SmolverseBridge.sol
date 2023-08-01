// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// A base class for all contracts.
// Includes basic utility functions, access control, and the ability to pause the contract.
contract UtilitiesV2Upgradeable is Initializable, AccessControlEnumerableUpgradeable, PausableUpgradeable {

    bytes32 internal constant OWNER_ROLE = keccak256("OWNER");
    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 internal constant ROLE_GRANTER_ROLE = keccak256("ROLE_GRANTER");

    function __Utilities_init() internal onlyInitializing {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        PausableUpgradeable.__Pausable_init();

        __Utilities_init_unchained();
    }

    function __Utilities_init_unchained() internal onlyInitializing {
        _pause();

        _grantRole(OWNER_ROLE, msg.sender);
    }

    function setPause(bool _shouldPause) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function grantRole(bytes32 _role, address _account) public override requiresEitherRole(ROLE_GRANTER_ROLE, OWNER_ROLE) {
        require(_role != OWNER_ROLE, "Cannot change owner role through grantRole");
        _grantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) public override requiresEitherRole(ROLE_GRANTER_ROLE, OWNER_ROLE) {
        require(_role != OWNER_ROLE, "Cannot change owner role through grantRole");
        _revokeRole(_role, _account);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    modifier requiresRole(bytes32 _role) {
        require(hasRole(_role, msg.sender), "Does not have required role");
        _;
    }

    modifier requiresEitherRole(bytes32 _roleOption1, bytes32 _roleOption2) {
        require(hasRole(_roleOption1, msg.sender) || hasRole(_roleOption2, msg.sender), "Does not have required role");

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice DeFrag.fi Balance Sheet Interface 
/// @dev For checking ownership of loaned out assets.

interface IBalanceSheet {

    function isExistingUser(address _userAddress) external view returns (bool);
    
    function getTokenIds(address _userAddress) external view returns (uint256[] memory tokenIds);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Smolverse Bridge Interface
/// @author Gearhart
/// @notice Interface containing all events, public/external functions, and custom errors for the Smolverse Bridge.

interface ISmolverseBridge {
        
    // -------------------------------------------------------------
    //                          EVENTS
    // -------------------------------------------------------------

    /// @notice Emitted when stats are deposited.
    /// @param _collectionAddress The address of the NFT collection that the stats were deposited from.
    /// @param _tokenId The token ID that the stats were deposited from.
    /// @param _statId The stat ID that was deposited.
    /// @param _amount The amount of the stat that was deposited.
    event StatsDeposited(
        address indexed _collectionAddress,
        uint256 indexed _tokenId,
        uint256 indexed _statId,
        uint256 _amount
    );

    /// @notice Emitted when ERC20 tokens are deposited.
    /// @param _userAddress The address of the wallet that deposited the tokens.
    /// @param _tokenAddress The address of the ERC20 contract that the tokens were deposited from.
    /// @param _amount The amount of tokens that were deposited.
    event ERC20sDeposited(
        address indexed _userAddress,
        address indexed _tokenAddress,
        uint256 _amount
    );

    /// @notice Emitted when ERC 1155 NFTs are deposited.
    /// @param _userAddress The address of the wallet that deposited the NFTs.
    /// @param _collectionAddress The address of the NFT collection that the NFTs were deposited from.
    /// @param _tokenId The ID of the tokens that were deposited.
    /// @param _amount The amount of the tokens that were deposited.
    event ERC1155sDeposited(
        address indexed _userAddress,
        address indexed _collectionAddress,
        uint256 indexed _tokenId,
        uint256 _amount
    );

    /// @notice Emitted when a ERC 721 NFT is deposited.
    /// @param _userAddress The address of the wallet that deposited the NFT.
    /// @param _collectionAddress The address of the NFT collection that the NFT was deposited from.
    /// @param _tokenId The ID of the token that was deposited.
    event ERC721Deposited(
        address indexed _userAddress,
        address indexed _collectionAddress,
        uint256 indexed _tokenId
    );

    /// @notice Emitted when stats are withdrawn.
    /// @param _collectionAddress The address of the NFT collection that the stats were withdrawn back to.
    /// @param _tokenId The token ID that the stats were withdrawn to.
    /// @param _statId The stat ID that was withdrawn.
    /// @param _amount The amount of the stat that was withdrawn.
    event StatsWithdrawn(
        address indexed _collectionAddress,
        uint256 indexed _tokenId,
        uint256 indexed _statId,
        uint256 _amount
    );

    /// @notice Emitted when ERC20 tokens are withdrawn.
    /// @param _userAddress The address of the wallet that withdrew the tokens.
    /// @param _tokenAddress The address of the ERC20 contract that the tokens were from.
    /// @param _amount The amount of tokens that were withdrawn.
    event ERC20sWithdrawn(
        address indexed _userAddress,
        address indexed _tokenAddress,
        uint256 _amount
    );

    /// @notice Emitted when ERC 1155 NFTs are withdrawn.
    /// @param _userAddress The address of the wallet that withdrew the NFTs.
    /// @param _collectionAddress The address of the NFT collection that the NFTs were from.
    /// @param _tokenId The ID of the tokens that were withdrawn.
    /// @param _amount The amount of the tokens that were withdrawn.
    event ERC1155sWithdrawn(
        address indexed _userAddress,
        address indexed _collectionAddress,
        uint256 indexed _tokenId,
        uint256 _amount
    );

    /// @notice Emitted when a ERC 721 NFT is withdrawn.
    /// @param _userAddress The address of the wallet that withdrew the NFT.
    /// @param _collectionAddress The address of the NFT collection that the NFT was from.
    /// @param _tokenId The ID of the token that was withdrawn.
    event ERC721Withdrawn(
        address indexed _userAddress,
        address indexed _collectionAddress,
        uint256 indexed _tokenId
    );

    /// @notice Emitted when stats are spent.
    /// @param _landId The land ID that the stats were spent on.
    /// @param _userAddress The address of the wallet that spent the stats.
    /// @param _collectionAddress The address of the NFT collection that the spent stats were from.
    /// @param _tokenId The token ID that the spent stats were deposited by.
    /// @param _statId The stat ID that was spent.
    /// @param _amount The amount of statId that was spent.
    /// @param _message The description of what the stats were spent on. 
    event StatsSpent(
        uint256 indexed _landId,
        address indexed _userAddress,
        address indexed _collectionAddress,
        uint256 _tokenId,
        uint256 _statId,
        uint256 _amount,
        string _message
    );

    /// @notice Emitted when ERC20 tokens are spent.
    /// @param _landId The land ID that the ERC20s were spent on.
    /// @param _userAddress The address of the wallet that spent the tokens.
    /// @param _tokenAddress The address of the ERC20 contract that the spent tokens were from.
    /// @param _amount The amount of tokens that were spent.
    /// @param _message The description of what the tokens were spent on.
    event ERC20sSpent(
        uint256 indexed _landId,
        address indexed _userAddress,
        address indexed _tokenAddress,
        uint256 _amount,
        string _message
    );

    /// @notice Emitted when ERC 1155 NFT tokens are spent.
    /// @param _landId The land ID that the ERC 1155 NFTs were spent on.
    /// @param _userAddress The address of the wallet that spent the NFTs.
    /// @param _collectionAddress The address of the NFT collection that the spent ERC 1155s were from.
    /// @param _tokenId The token IDs that were spent.
    /// @param _amount The amount of each 1155 token that was spent.
    /// @param _message The description of what the ERC 1155 NFTs were spent on. 
    event ERC1155sSpent(
        uint256 indexed _landId,
        address indexed _userAddress,
        address indexed _collectionAddress,
        uint256 _tokenId,
        uint256 _amount,
        string _message
    );

    /// @notice Emitted when ERC 721 NFT tokens are spent.
    /// @param _landId The land ID that the ERC 721 NFT was spent on.
    /// @param _userAddress The address of the wallet that spent the NFT.
    /// @param _collectionAddress The address of the NFT collection that the spent ERC 721 was from.
    /// @param _tokenId The token ID that was spent.
    /// @param _message The description of what the ERC 721 NFT was spent on.
    event ERC721Spent(
        uint256 indexed _landId,
        address indexed _userAddress,
        address indexed _collectionAddress,
        uint256 _tokenId,
        string _message
    );

    /// @notice Emitted when a collection has it's stat deposit approval changed.
    /// @param _collectionAddress The address of the NFT collection that was approved for stat deposit.
    /// @param _approved True if the collection was approved.
    event CollectionStatDepositApprovalChanged(
        address indexed _collectionAddress,
        bool indexed _approved
    );

    /// @notice Emitted when a collection has it's ERC1155 deposit approval changed.
    /// @param _collectionAddress The address of the NFT collection that was approved for ERC1155 deposit.
    /// @param _approved True if the collection was approved.
    event CollectionERC1155DepositApprovalChanged(
        address indexed _collectionAddress,
        bool indexed _approved
    );

    /// @notice Emitted when a collection has it's ERC721 deposit approval changed.
    /// @param _collectionAddress The address of the NFT collection that was approved for ERC721 deposit.
    /// @param _approved True if the collection was approved.
    event CollectionERC721DepositApprovalChanged(
        address indexed _collectionAddress,
        bool indexed _approved
    );

    /// @notice Emitted when an ERC20 token has it's deposit approval changed.
    /// @param _tokenAddress The address of the ERC20 token that was approved for deposit.
    /// @param _approved True if the token was approved.
    event ERC20DepositApprovalChanged(
        address indexed _tokenAddress,
        bool indexed _approved
    );

    /// @notice Emitted when a Stat ID has it's deposit approval changed.
    /// @param _collectionAddress The address of the NFT collection that the stat is from.
    /// @param _statId The stat ID that was approved or revoked.
    /// @param _approved True if the stat was approved for deposit.
    event StatIdDepositApprovalChanged(
        address indexed _collectionAddress,
        uint256 indexed _statId,
        bool indexed _approved
    );

    /// @notice Emitted when a ERC1155 NFT ID has it's deposit approval changed.
    /// @param _collectionAddress The address of the NFT collection that the ERC1155 NFT is from.
    /// @param _tokenId The ERC1155 NFT ID that was approved or revoked.
    /// @param _approved True if the ERC1155 NFT was approved for deposit.
    event TokenIdDepositApprovalChanged(
        address indexed _collectionAddress,
        uint256 indexed _tokenId,
        bool indexed _approved
    );

    /// @notice Emitted when the contracts are set.
    /// @param _smolLandAddress The address of the SmolLand contract.
    /// @param _smolSchoolAddress The address of the SmolSchool contract.
    /// @param _smolBrainsAddress The address of the SmolBrains contract.
    /// @param _deFragAssetManagerAddress The address of the DeFrag Finance Asset Manager contract.
    /// @param _deFragBalanceSheetAddress The address of the DeFrag Finance Balance Sheet contract.
    event ContractsSet(
        address _smolLandAddress,
        address _smolSchoolAddress,
        address _smolBrainsAddress,
        address _deFragAssetManagerAddress,
        address _deFragBalanceSheetAddress
    );

    //-------------------------------------------------------------
    //                      VIEW FUNCTIONS
    //-------------------------------------------------------------

    /// @notice Gets array of stat IDs that are available for deposit from the given collection.
    /// @param _collectionAddress The address of the NFT collection to get available stat/token IDs for.
    /// @return Array of stat/token IDs that are available for deposit.
    function getIdsAvailableForDepositByCollection(
        address _collectionAddress
    ) external view returns(uint256[] memory);

    /// @notice Checks if the contracts are set.
    /// @return True if the contracts are set.
    function areContractsSet() external view returns (bool);

    // -------------------------------------------------------------
    //                    EXTERNAL FUNCTIONS
    // -------------------------------------------------------------

    /// @notice Deposits stats from an NFT into the bridge.
    /// @param _collections The addresses of the NFT collections that the stats are being deposited from.
    /// @param _tokenIds The token IDs that the stats are being deposited from.
    /// @param _statIds The stat IDs that are being deposited.
    /// @param _amounts The amount of each stat being deposited.
    function depositStats(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds, 
        uint256[] calldata _statIds, 
        uint256[] calldata _amounts
    ) external;

    /// @notice Deposits ERC20 tokens into the bridge.
    /// @param _tokenAddresses The addresses of the ERC20 tokens being deposited.
    /// @param _amounts The amount of each ERC20 token being deposited.
    function depositERC20s(
        address[] calldata _tokenAddresses, 
        uint256[] calldata _amounts
    ) external;

    /// @notice Deposits ERC1155 NFTs into the bridge.
    /// @param _collections The addresses of the NFT collections that the ERC1155 NFTs are from.
    /// @param _tokenIds The token IDs of the ERC1155 NFTs being deposited.
    /// @param _amounts The amount of each ERC1155 NFT ID being deposited.
    function depositERC1155s(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds, 
        uint256[] calldata _amounts
    ) external;

    /// @notice Deposits ERC721 NFTs into the bridge.
    /// @param _collections The addresses of the NFT collections that the ERC721 NFTs are from.
    /// @param _tokenIds The token IDs of the ERC721 NFTs being deposited.
    function depositERC721s(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds
    ) external;

    /// @notice Withdraws stats from the bridge.
    /// @param _collections The addresses of the NFT collections that the stats are being withdrawn to.
    /// @param _tokenIds The token IDs that the stats are being withdrawn to.
    /// @param _statIds The stat IDs that are being withdrawn.
    /// @param _amounts The amount of each stat being withdrawn.
    function withdrawStats(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds, 
        uint256[] calldata _statIds, 
        uint256[] calldata _amounts
    ) external;

    /// @notice Withdraws ERC20 tokens from the bridge.
    /// @param _tokenAddresses The addresses of the ERC20 tokens being withdrawn.
    /// @param _amounts The amount of each ERC20 token being withdrawn.
    function withdrawERC20s(
        address[] calldata _tokenAddresses, 
        uint256[] calldata _amounts
    ) external;

    /// @notice Withdraws ERC1155 NFTs from the bridge.
    /// @param _collections The addresses of the NFT collections that the ERC1155 NFTs are from.
    /// @param _tokenIds The token IDs of the ERC1155 NFTs being withdrawn.
    /// @param _amounts The amount of each ERC1155 NFT ID being withdrawn.
    function withdrawERC1155s(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds, 
        uint256[] calldata _amounts
    ) external;

    /// @notice Withdraws ERC721 NFTs from the bridge.
    /// @param _collections The addresses of the NFT collections that the ERC721 NFTs are from.
    /// @param _tokenIds The token IDs of the ERC721 NFTs being withdrawn.
    function withdrawERC721s(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds
    ) external;

    //-------------------------------------------------------------------------
    //                      ADMIN FUNCTIONS
    //-------------------------------------------------------------------------

    /// @notice Spends stats from an NFTs balance.
    /// @dev Can only be called by the AUTHORIZED_BALANCE_ADJUSTER_ROLE.
    /// @param _userAddress The address of the wallet that is spending the stats.
    /// @param _collectionAddress The address of the NFT collection that the stats are being spent from.
    /// @param _tokenId The token ID that the stats are being spent from.
    /// @param _statId The stat ID that is being spent.
    /// @param _amount The amount of the stat being spent.
    /// @param _landId The land ID that the stats are being spent on.
    /// @param _message The description of what the stats are being spent on.
    function spendStats(
        address _userAddress,
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _statId,
        uint256 _amount,
        uint256 _landId,
        string calldata _message
    ) external;

    /// @notice Spends ERC20 tokens from an users balance.
    /// @dev Can only be called by the AUTHORIZED_BALANCE_ADJUSTER_ROLE.
    /// @param _userAddress The address of the wallet that is spending the tokens.
    /// @param _tokenAddress The address of the ERC20 contract that the tokens are being spent from.
    /// @param _amount The amount of the ERC20 tokens being spent.
    /// @param _landId The land ID that the tokens are being spent on.
    /// @param _message The description of what the tokens are being spent on.
    function spendERC20s(
        address _userAddress,
        address _tokenAddress,
        uint256 _amount,
        uint256 _landId,
        string calldata _message
    ) external;

    /// @notice Spends ERC1155 NFTs from an users balance.
    /// @dev Can only be called by the AUTHORIZED_BALANCE_ADJUSTER_ROLE.
    /// @param _userAddress The address of the wallet that is spending the NFTs.
    /// @param _collectionAddress The address of the NFT collection that the NFTs are being spent from.
    /// @param _tokenId The token ID of the ERC1155 NFT being spent.
    /// @param _amount The amount of the ERC1155 NFT ID being spent.
    /// @param _landId The land ID that the NFTs are being spent on.
    /// @param _message The description of what the NFTs are being spent on.
    function spendERC1155s(
        address _userAddress,
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _landId,
        string calldata _message
    ) external;

    /// @notice Spends ERC721 NFTs from an users balance.
    /// @dev Can only be called by the AUTHORIZED_BALANCE_ADJUSTER_ROLE.
    /// @param _userAddress The address of the wallet that is spending the NFT.
    /// @param _collectionAddress The address of the NFT collection that the NFT is being spent from.
    /// @param _tokenId The token ID of the ERC721 NFT being spent.
    /// @param _landId The land ID that the NFT is being spent on.
    /// @param _message The description of what the NFT is being spent on.
    function spendERC721(
        address _userAddress,
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _landId,
        string calldata _message
    ) external;

    /// @notice Sets the approval for a collection to deposit stats.
    /// @dev Can only be called by the owner or admin.
    /// @param _collectionAddress The address of the NFT collection to set approval for.
    /// @param _approved True if the collection is being approved.
    function setCollectionStatDepositApproval(
        address _collectionAddress,
        bool _approved
    ) external;

    /// @notice Sets the approval for a ERC20 token to be deposited.
    /// @dev Can only be called by the owner or admin.
    /// @param _tokenAddress The address of the ERC20 token to set approval for.
    /// @param _approved True if the token is being approved.
    function setERC20DepositApproval(
        address _tokenAddress,
        bool _approved
    ) external;

    /// @notice Sets the approval for a collection to deposit ERC1155 NFTs.
    /// @dev Can only be called by the owner or admin.
    /// @param _collectionAddress The address of the NFT collection to set approval for.
    /// @param _approved True if the collection is being approved.
    function setCollectionERC1155DepositApproval(
        address _collectionAddress,
        bool _approved
    ) external;

    /// @notice Sets the approval for a collection to deposit ERC721 NFTs.
    /// @dev Can only be called by the owner or admin.
    /// @param _collectionAddress The address of the NFT collection to set approval for.
    /// @param _approved True if the collection is being approved.
    function setCollectionERC721DepositApproval(
        address _collectionAddress,
        bool _approved
    ) external;

    /// @notice Sets the approval for a stat ID to be deposited from a specific collection.
    /// @dev Can only be called by the owner or admin.
    /// @param _collectionAddress The address of the NFT collection that the stat is earned by.
    /// @param _statId The stat ID to set approval for.
    /// @param _approved True if the stat ID is being approved.
    function setStatIdDepositApproval(
        address _collectionAddress,
        uint256 _statId,
        bool _approved
    ) external;

    /// @notice Sets the approval for a ERC1155 NFT ID to be deposited from a specific collection.
    /// @dev Can only be called by the owner or admin.
    /// @param _collectionAddress The address of the NFT collection that the ERC1155 NFT is from.
    /// @param _tokenId The ERC1155 NFT ID to set approval for.
    /// @param _approved True if the ERC1155 NFT ID is being approved.
    function setERC1155TokenIdDepositApproval(
        address _collectionAddress,
        uint256 _tokenId,
        bool _approved
    ) external;

    /// @notice Sets the addresses of the necessary contracts.
    /// @dev Can only be called by the owner or admin.
    /// @param _smolLandAddress The address of the land NFT contract.
    /// @param _smolSchoolAddress The address of the smol school contract.
    /// @param _smolBrainsAddress The address of the smol brains contract.
    /// @param _deFragAssetManagerAddress The address of the DeFrag Finance Asset Manager contract.
    /// @param _deFragBalanceSheetAddress The address of the DeFrag Finance Balance Sheet contract.
    function setContracts(
        address _smolLandAddress,
        address _smolSchoolAddress,
        address _smolBrainsAddress,
        address _deFragAssetManagerAddress,
        address _deFragBalanceSheetAddress
    ) external;
    
    //-------------------------------------------------------------
    //                          ERRORS
    //-------------------------------------------------------------

    error ContractsNotSet();
    error ArrayLengthMismatch();
    error AmountMustBeGreaterThanZero();
    error AddressCanOnlyBeApprovedForOneTypeOfDeposit();

    error MustBeOwnerOfNFT(address _collectionAddress, uint256 _tokenId, address _userAddress, address ownerAddress);
    error StatDoesNotExist(address _collectionAddress, uint256 _statId);
    
    error InsufficientNFTBalance(address _collectionAddress, uint256 _nftId, uint256 _amountNeeded, uint256 _amountAvailable);
    error InsufficientStatBalance(address _collectionAddress, uint256 _tokenId, uint256 _statId, uint256 _amountNeeded, uint256 _amountAvailable);
    error InsufficientERC20Balance(address _tokenAddress, uint256 _amountNeeded, uint256 _amountAvailable);

    error IdNotApprovedForDeposit(address _collectionAddress, uint256 _statOrNftId);
    error AlreadyApprovedForDeposit(address _collectionAddress, uint256 _statOrNftId);
    error AddressNotApprovedForDeposit(address _collectionAddress);
    error AddressApprovalAlreadySet(address _collectionAddress, bool _approved);

    error DeFragOnlySupportedForSmolBrains(address _collectionAddress, address smolBrains);
    error UserHasNoTokensOnDeFrag(address _userAddress);
    error DeFragAssetManagerCannotBeUser();

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SmolverseBridgeAdmin.sol";

/// @title Smolverse Bridge
/// @author Gearhart
/// @notice Stores stats, ERC1155s, and ERC721s deposited from approved collections to be spent in Smolverse.

contract SmolverseBridge is Initializable, SmolverseBridgeAdmin {

    // -------------------------------------------------------------
    //                      EXTERNAL FUNCTIONS
    // -------------------------------------------------------------

    /// @inheritdoc ISmolverseBridge
    function depositStats(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds, 
        uint256[] calldata _statIds, 
        uint256[] calldata _amounts
    ) external nonReentrant whenNotPaused contractsAreSet{
        // check input lengths
        uint256 length = _collections.length;
        _checkLengths(length, _tokenIds.length);
        _checkLengths(length, _statIds.length);
        _checkLengths(length, _amounts.length);

        // loop through individual deposits
        for (uint256 i = 0; i < length; i++) {
            _depositStats(msg.sender, _collections[i], _tokenIds[i], _statIds[i], _amounts[i]);
        }
    }

    /// @inheritdoc ISmolverseBridge
    function depositERC20s(
        address[] calldata _tokens, 
        uint256[] calldata _amounts
    ) external nonReentrant whenNotPaused contractsAreSet{
        // check input lengths
        uint256 length = _tokens.length;
        _checkLengths(length, _amounts.length);

        // loop through individual deposits
        for (uint256 i = 0; i < length; i++) {
            _deposit20s(msg.sender, _tokens[i], _amounts[i]);
        }
    }

    /// @inheritdoc ISmolverseBridge
    function depositERC1155s(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds, 
        uint256[] calldata _amounts
    ) external nonReentrant whenNotPaused contractsAreSet{
        // check input lengths
        uint256 length = _collections.length;
        _checkLengths(length, _tokenIds.length);
        _checkLengths(length, _amounts.length);

        // loop through individual deposits
        for (uint256 i = 0; i < length; i++) {
            _deposit1155s(msg.sender, _collections[i], _tokenIds[i], _amounts[i]);
        }
    }

    /// @inheritdoc ISmolverseBridge
    function depositERC721s(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds
    ) external nonReentrant whenNotPaused contractsAreSet{
        // check input lengths
        uint256 length = _collections.length;
        _checkLengths(length, _tokenIds.length);

        // loop through individual deposits
        for (uint256 i = 0; i < length; i++) {
            _deposit721(msg.sender, _collections[i], _tokenIds[i]);
        }
    }

    /// @inheritdoc ISmolverseBridge
    function withdrawStats(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds, 
        uint256[] calldata _statIds, 
        uint256[] calldata _amounts
    ) external nonReentrant whenNotPaused contractsAreSet{
        // check input lengths
        uint256 length = _collections.length;
        _checkLengths(length, _tokenIds.length);
        _checkLengths(length, _statIds.length);
        _checkLengths(length, _amounts.length);

        // loop through individual withdrawals
        for (uint256 i = 0; i < length; i++) {
            _withdrawStats(msg.sender, _collections[i], _tokenIds[i], _statIds[i], _amounts[i]);
        }
    }

    /// @inheritdoc ISmolverseBridge
    function withdrawERC20s(
        address[] calldata _tokens, 
        uint256[] calldata _amounts
    ) external nonReentrant whenNotPaused contractsAreSet{
        // check input lengths
        uint256 length = _tokens.length;
        _checkLengths(length, _amounts.length);

        // loop through individual withdrawals
        for (uint256 i = 0; i < length; i++) {
            _withdraw20s(msg.sender, _tokens[i], _amounts[i]);
        }
    }

    /// @inheritdoc ISmolverseBridge
    function withdrawERC1155s(
        address[] calldata _collections, 
        uint256[] calldata _tokenIds, 
        uint256[] calldata _amounts
    ) external nonReentrant whenNotPaused contractsAreSet{
        // check input lengths
        uint256 length = _collections.length;
        _checkLengths(length, _tokenIds.length);
        _checkLengths(length, _amounts.length);

        // loop through individual withdrawals
        for (uint256 i = 0; i < length; i++) {
            _withdraw1155s(msg.sender, _collections[i], _tokenIds[i], _amounts[i]);
        }
    }

    /// @inheritdoc ISmolverseBridge
    function withdrawERC721s(
        address[] calldata _collections,
        uint256[] calldata _tokenIds
    ) external nonReentrant whenNotPaused contractsAreSet{
        // check input lengths
        uint256 length = _collections.length;
        _checkLengths(length, _tokenIds.length);

        // loop through individual withdrawals
        for (uint256 i = 0; i < length; i++) {
            _withdraw721(msg.sender, _collections[i], _tokenIds[i]);
        }
    }

    // -------------------------------------------------------------
    //                         INITIALIZER 
    // -------------------------------------------------------------

    function initialize() external initializer {
        SmolverseBridgeAdmin.__SmolverseBridgeAdmin_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SmolverseBridgeInternal.sol";

/// @title Smolverse Bridge Admin
/// @author Gearhart
/// @notice Admin functions for Smolverse Bridge gated by various roles.

abstract contract SmolverseBridgeAdmin is Initializable, SmolverseBridgeInternal {

    // -------------------------------------------------------------
    //                    EXTERNAL ADMIN FUNCTIONS
    // -------------------------------------------------------------

    /// @inheritdoc ISmolverseBridge
    function spendStats(
        address _userAddress,
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _statId,
        uint256 _amount,
        uint256 _landId,
        string calldata _message
    ) external whenNotPaused contractsAreSet requiresRole(AUTHORIZED_BALANCE_ADJUSTER_ROLE){
        // check amount > 0
        _checkAmounts(_amount);
        // check land ownership
        _check721Ownership(_userAddress, smolLand, _landId);
        // check ownership for NFT that has the stats being spent
        if (_userAddress == deFragAssetManager) revert DeFragAssetManagerCannotBeUser();
        _check721Ownership(_userAddress, _collectionAddress, _tokenId);
        // check if NFT has enough deposited stats
        _checkStatBridgeBalance(_collectionAddress, _tokenId, _statId, _amount);
        // remove stats from deposited balance
        collectionToStatBalance[_collectionAddress][_tokenId][_statId] -= _amount;

        emit StatsSpent(
            _landId,
            _userAddress,
            _collectionAddress,
            _tokenId,
            _statId, 
            _amount,
            _message
        );
    }

    /// @inheritdoc ISmolverseBridge
    function spendERC20s(
        address _userAddress,
        address _tokenAddress,
        uint256 _amount,
        uint256 _landId,
        string calldata _message
    ) external whenNotPaused contractsAreSet requiresRole(AUTHORIZED_BALANCE_ADJUSTER_ROLE){
        // check amount > 0
        _checkAmounts(_amount);
        // check land ownership
        _check721Ownership(_userAddress, smolLand, _landId);
        // check user has enough deposited
        _check20BridgeBalance(_userAddress, _tokenAddress, _amount);
        // decrement users deposited balance
        userToERC20Balance[_userAddress][_tokenAddress] -= _amount;
        // increment contracts available balance
        userToERC20Balance[address(this)][_tokenAddress] += _amount;

        emit ERC20sSpent(
            _landId,
            _userAddress,
            _tokenAddress,
            _amount,
            _message
        );
    }

    /// @inheritdoc ISmolverseBridge
    function spendERC1155s(
        address _userAddress,
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _landId,
        string calldata _message
    ) external whenNotPaused contractsAreSet requiresRole(AUTHORIZED_BALANCE_ADJUSTER_ROLE){
        // check amount > 0
        _checkAmounts(_amount);
        // check land ownership
        _check721Ownership(_userAddress, smolLand, _landId);
        // check user has enough deposited
        _check1155BridgeBalance(_userAddress, _collectionAddress, _tokenId, _amount);
        // decrement users deposited balance
        userToERC1155Balance[_userAddress][_collectionAddress][_tokenId] -= _amount;
        // increment contracts available balance
        userToERC1155Balance[address(this)][_collectionAddress][_tokenId] += _amount;

        emit ERC1155sSpent(
            _landId,
            _userAddress,
            _collectionAddress,
            _tokenId,
            _amount,
            _message
        );
    }

    /// @inheritdoc ISmolverseBridge
    function spendERC721(
        address _userAddress,
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _landId,
        string calldata _message
    ) external whenNotPaused contractsAreSet requiresRole(AUTHORIZED_BALANCE_ADJUSTER_ROLE){
        // check land ownership
        _check721Ownership(_userAddress, smolLand, _landId);
        // double check token has been deposited
        if (!userToDepositedERC721s[_userAddress][_collectionAddress][_tokenId]){
            revert InsufficientNFTBalance(_collectionAddress, _tokenId, 1, 0);
        }
        // remove ERC 721 NFT from users deposited balance
        userToDepositedERC721s[_userAddress][_collectionAddress][_tokenId] = false;
        // add ERC 721 NFT ID to contracts available balance
        userToDepositedERC721s[address(this)][_collectionAddress][_tokenId] = true;

        emit ERC721Spent(
            _landId,
            _userAddress,
            _collectionAddress,
            _tokenId,
            _message
        );
    }

    /// @inheritdoc ISmolverseBridge
    function setCollectionStatDepositApproval(
        address _collectionAddress,
        bool _approved
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        // check if collection approval is actually being changed
        if (collectionToStatDepositApproval[_collectionAddress] == _approved) {
            revert AddressApprovalAlreadySet(_collectionAddress, _approved);
        }
        if (collectionToERC1155DepositApproval[_collectionAddress] || collectionToERC721DepositApproval[_collectionAddress] || addressToERC20DepositApproval[_collectionAddress]) {
            revert AddressCanOnlyBeApprovedForOneTypeOfDeposit();
        }
        // change collection approval
        collectionToStatDepositApproval[_collectionAddress] = _approved;

        emit CollectionStatDepositApprovalChanged(
            _collectionAddress,
            _approved
        );
    }

    function setERC20DepositApproval(
        address _tokenAddress,
        bool _approved
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        // check if token approval is actually being changed
        if (addressToERC20DepositApproval[_tokenAddress] == _approved) {
            revert AddressApprovalAlreadySet(_tokenAddress, _approved);
        }
        if (collectionToERC1155DepositApproval[_tokenAddress] || collectionToERC721DepositApproval[_tokenAddress] || collectionToStatDepositApproval[_tokenAddress]) {
            revert AddressCanOnlyBeApprovedForOneTypeOfDeposit();
        }
        // change token approval
        addressToERC20DepositApproval[_tokenAddress] = _approved;

        emit ERC20DepositApprovalChanged(
            _tokenAddress,
            _approved
        );
    }

    /// @inheritdoc ISmolverseBridge
    function setCollectionERC1155DepositApproval(
        address _collectionAddress,
        bool _approved
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        // check if collection approval is actually being changed
        if (collectionToERC1155DepositApproval[_collectionAddress] == _approved) {
            revert AddressApprovalAlreadySet(_collectionAddress, _approved);
        }
        if (collectionToERC721DepositApproval[_collectionAddress] || collectionToStatDepositApproval[_collectionAddress] || addressToERC20DepositApproval[_collectionAddress]) {
            revert AddressCanOnlyBeApprovedForOneTypeOfDeposit();
        }
        // change collection approval
        collectionToERC1155DepositApproval[_collectionAddress] = _approved;

        emit CollectionERC1155DepositApprovalChanged(
            _collectionAddress,
            _approved
        );
    }
        
    /// @inheritdoc ISmolverseBridge
    function setCollectionERC721DepositApproval(
        address _collectionAddress,
        bool _approved
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {       
        // check if collection approval is actually being changed
        if (collectionToERC721DepositApproval[_collectionAddress] == _approved) {
            revert AddressApprovalAlreadySet(_collectionAddress, _approved);
        }
        if (collectionToStatDepositApproval[_collectionAddress] || collectionToERC1155DepositApproval[_collectionAddress] || addressToERC20DepositApproval[_collectionAddress]) {
            revert AddressCanOnlyBeApprovedForOneTypeOfDeposit();
        }
        // change collection approval
        collectionToERC721DepositApproval[_collectionAddress] = _approved;

        emit CollectionERC721DepositApprovalChanged(
            _collectionAddress,
            _approved
        );
    }

    /// @inheritdoc ISmolverseBridge
    function setStatIdDepositApproval(
        address _collectionAddress,
        uint256 _statId,
        bool _approved
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        // check if collection is approved for stat deposits
        if (!collectionToStatDepositApproval[_collectionAddress]){
            revert AddressNotApprovedForDeposit(_collectionAddress);
        }
        // if granting approval
        if(_approved) {
            // check if stat ID exists
            _checkStatExistence(_collectionAddress, _statId);
            _grantIdDepositApproval(_collectionAddress, _statId);
        }
        // if revoking approval
        else {
            _revokeIdDepositApproval(_collectionAddress, _statId);
        }

        emit StatIdDepositApprovalChanged(
            _collectionAddress, 
            _statId,
            _approved
        );
    }

    /// @inheritdoc ISmolverseBridge
    function setERC1155TokenIdDepositApproval(
        address _collectionAddress,
        uint256 _tokenId,
        bool _approved
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        // check if collection is approved for ERC1155 token deposits
        if (!collectionToERC1155DepositApproval[_collectionAddress]){
            revert AddressNotApprovedForDeposit(_collectionAddress);
        }
        // if granting approval
        if(_approved) {
            _grantIdDepositApproval(_collectionAddress, _tokenId);
        }
        // if revoking approval
        else {
            _revokeIdDepositApproval(_collectionAddress, _tokenId);
        }

        emit TokenIdDepositApprovalChanged(
            _collectionAddress, 
            _tokenId,
            _approved
        );
    }

    /// @inheritdoc ISmolverseBridge
    function setContracts(
        address _smolLandAddress,
        address _smolSchoolAddress,
        address _smolBrainsAddress,
        address _deFragAssetManagerAddress,
        address _deFragBalanceSheetAddress
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        smolLand = _smolLandAddress;
        smolSchool = ISchool(_smolSchoolAddress);
        smolBrains = _smolBrainsAddress;
        deFragAssetManager = _deFragAssetManagerAddress;
        deFragBalanceSheet = _deFragBalanceSheetAddress;
        
        emit ContractsSet(
            _smolLandAddress, 
            _smolSchoolAddress,
            _smolBrainsAddress,
            _deFragAssetManagerAddress,
            _deFragBalanceSheetAddress
        );
    }

    // -------------------------------------------------------------
    //                         INITIALIZER 
    // -------------------------------------------------------------

    function __SmolverseBridgeAdmin_init() internal initializer {
        SmolverseBridgeInternal.__SmolverseBridgeInternal_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SmolverseBridgeView.sol";

/// @title Smolverse Bridge Internal
/// @author Gearhart
/// @notice Internal helper functions for SmolverseBridge and SmolverseBridgeAdmin.

abstract contract SmolverseBridgeInternal is Initializable, SmolverseBridgeView {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // -------------------------------------------------------------
    //                  INTERNAL DEPOSIT FUNCTIONS
    // -------------------------------------------------------------

    /// @dev Deposits an NFTs stat balance into that NFTs account to be used on land.
    function _depositStats(
        address _userAddress,
        address _collectionAddress, 
        uint256 _tokenId, 
        uint256 _statId, 
        uint256 _amount
    ) internal {
        // checks
        _checkAmounts(_amount);
        // check if collection and stat ID are approved for stat deposits
        if (!collectionToStatDepositApproval[_collectionAddress]){
            revert AddressNotApprovedForDeposit(_collectionAddress);
        }
        _depositChecks(_collectionAddress, _statId);
        // check stat existence
        _checkStatExistence(_collectionAddress, _statId);
        // check NFT ownership
        _check721Ownership(_userAddress, _collectionAddress, _tokenId);
        // get stat balance from school
        TokenDetails memory tokenInfo = smolSchool.tokenDetails(
        _collectionAddress,
        uint64(_statId),
        _tokenId
        );
        // check stat balance
        if (uint256(tokenInfo.statAccrued) < _amount){
            revert InsufficientStatBalance(_collectionAddress, _tokenId, _statId, _amount, tokenInfo.statAccrued);
        }
        // call school to remove stats from NFT as allowed adjuster
        smolSchool.removeStatAsAllowedAdjuster(
            _collectionAddress, 
            uint64(_statId), 
            _tokenId, 
            uint128(_amount)
        );
        // add stats to token IDs deposited balance
        collectionToStatBalance[_collectionAddress][_tokenId][_statId] += _amount;
        
        emit StatsDeposited(
            _collectionAddress,
            _tokenId,
            _statId,
            _amount
        );
    }

    /// @dev Deposits ERC20s and updates that users balance.
    function _deposit20s(
        address _userAddress,
        address _tokenAddress, 
        uint256 _amount
    ) internal {
        // checks
        _checkAmounts(_amount);
        // check if token is approved for deposits
        if (!addressToERC20DepositApproval[_tokenAddress]){
            revert AddressNotApprovedForDeposit(_tokenAddress);
        }
        // check user balance
        uint256 bal = IERC20(_tokenAddress).balanceOf(_userAddress);
        if (bal < _amount){
            revert InsufficientERC20Balance(_tokenAddress, _amount, bal);
        }
        // send tokens to this contract from user
        IERC20(_tokenAddress).transferFrom(_userAddress, address(this), _amount);
        // add tokens to user balance
        userToERC20Balance[_userAddress][_tokenAddress] += _amount;

        emit ERC20sDeposited(
            _userAddress, 
            _tokenAddress, 
            _amount
        );
    }

    /// @dev Deposits ERC1155 NFTs and updates that users balance.
    function _deposit1155s(
        address _userAddress,
        address _collectionAddress, 
        uint256 _tokenId, 
        uint256 _amount
    ) internal {
        // checks
        _checkAmounts(_amount);
        _depositChecks(_collectionAddress, _tokenId);
        // check if collection is approved for 1155 deposits
        if (!collectionToERC1155DepositApproval[_collectionAddress]){
            revert AddressNotApprovedForDeposit(_collectionAddress);
        }
        // get users ERC 1155 token balance 
        uint256 bal = IERC1155(_collectionAddress).balanceOf(
            _userAddress, 
            _tokenId
        );
        //check if user has enough tokens to deposit
        if (bal < _amount){
            revert InsufficientNFTBalance(_collectionAddress, _tokenId, _amount, bal);
        }
        // send tokens to this contract from user
        IERC1155(_collectionAddress).safeTransferFrom(
            _userAddress, 
            address(this), 
            _tokenId, 
            _amount, 
            ""
        );
        // add nft amounts to user balance
        userToERC1155Balance[_userAddress][_collectionAddress][_tokenId] += _amount;
        
        emit ERC1155sDeposited(
            _userAddress, 
            _collectionAddress, 
            _tokenId, 
            _amount
        );
    }

    /// @dev Deposits ERC721 NFT and updates that users balance.
    function _deposit721(
        address _userAddress,
        address _collectionAddress, 
        uint256 _tokenId
    ) internal {
        // check if collection is approved for 721 deposits
        if (!collectionToERC721DepositApproval[_collectionAddress]){
            revert AddressNotApprovedForDeposit(_collectionAddress);
        }
        // check if user owns nft
        _check721Ownership(_userAddress, _collectionAddress, _tokenId);
        // send NFT to this contract from user
        IERC721(_collectionAddress).safeTransferFrom(
            _userAddress, 
            address(this), 
            _tokenId,
            ""
        );
        // add nft to user balance
        userToDepositedERC721s[_userAddress][_collectionAddress][_tokenId] = true;

        emit ERC721Deposited(
            _userAddress, 
            _collectionAddress, 
            _tokenId
        );
    }

    // -------------------------------------------------------------
    //                INTERNAL WITHDRAW FUNCTIONS
    // -------------------------------------------------------------
        
    /// @dev Withdraws an NFTs stat balance from that NFTs account.
    function _withdrawStats(
        address _userAddress,
        address _collectionAddress, 
        uint256 _tokenId, 
        uint256 _statId, 
        uint256 _amount
    ) internal {
        // checks
        _checkAmounts(_amount);
        // check if collection is approved for stat deposits
        if (!collectionToStatDepositApproval[_collectionAddress]){
            revert AddressNotApprovedForDeposit(_collectionAddress);
        }
        // check ownership of NFT
        _check721Ownership(_userAddress, _collectionAddress, _tokenId);
        // check if stat exists
        _checkStatExistence(_collectionAddress, _statId);
        // check deposited stat balance
        _checkStatBridgeBalance(_collectionAddress, _tokenId, _statId, _amount);
        // subtract stats from NFTs balance on this contract
        collectionToStatBalance[_collectionAddress][_tokenId][_statId] -= _amount;
        // call school to add stats to NFT as allowed adjuster
        smolSchool.addStatAsAllowedAdjuster(
            _collectionAddress, 
            uint64(_statId), 
            _tokenId, 
            uint128(_amount)
        );
        
        emit StatsWithdrawn(
            _collectionAddress, 
            _tokenId,
            _statId,
            _amount
        );
    }

    /// @dev Withdraws ERC20s from users balance.
    function _withdraw20s(
        address _userAddress,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        // checks
        _checkAmounts(_amount);
        // check if ERC20 address is approved for deposits
        if (!addressToERC20DepositApproval[_tokenAddress]){
            revert AddressNotApprovedForDeposit(_tokenAddress);
        }
        // check deposited ERC20 balance
        _check20BridgeBalance(_userAddress, _tokenAddress, _amount);
        // subtract tokens from user balance
        userToERC20Balance[_userAddress][_tokenAddress] -= _amount;
        // send tokens to user
        IERC20(_tokenAddress).transfer(_userAddress, _amount);

        emit ERC20sWithdrawn(
            _userAddress, 
            _tokenAddress, 
            _amount
        );
    }

    /// @dev Withdraws ERC1155 NFTs from users balance.
    function _withdraw1155s(
        address _userAddress,
        address _collectionAddress, 
        uint256 _tokenId, 
        uint256 _amount
    ) internal {
        // checks
        _checkAmounts(_amount);
        // check if collection is approved for 1155 deposits
        if (!collectionToERC1155DepositApproval[_collectionAddress]){
            revert AddressNotApprovedForDeposit(_collectionAddress);
        }
        // check deposited 1155 nft balance
        _check1155BridgeBalance(_userAddress, _collectionAddress, _tokenId, _amount);
        // subtract nft amounts from user balance
        userToERC1155Balance[_userAddress][_collectionAddress][_tokenId] -= _amount;
        // send tokens to user
        IERC1155(_collectionAddress).safeTransferFrom(
            address(this), 
            _userAddress, 
            _tokenId, 
            _amount, 
            ""
        );

        emit ERC1155sWithdrawn(
            _userAddress, 
            _collectionAddress, 
            _tokenId, 
            _amount
        );
    }

    /// @dev Withdraws ERC721 NFT from users balance.
    function _withdraw721(
        address _userAddress,
        address _collectionAddress, 
        uint256 _tokenId
    ) internal {
        // checks
        if (!collectionToERC721DepositApproval[_collectionAddress]){
            revert AddressNotApprovedForDeposit(_collectionAddress);
        }
        // check if user deposited NFT
        if (!userToDepositedERC721s[_userAddress][_collectionAddress][_tokenId]){
            revert InsufficientNFTBalance(_collectionAddress, _tokenId, 1, 0);
        }
        // remove nft from user balance
        userToDepositedERC721s[_userAddress][_collectionAddress][_tokenId] = false;
        // send NFT to user
        IERC721(_collectionAddress).safeTransferFrom(
            address(this), 
            _userAddress, 
            _tokenId,
            ""
        );

        emit ERC721Withdrawn(
            _userAddress, 
            _collectionAddress, 
            _tokenId
        );
    }

    // -------------------------------------------------------------
    //                  INTERNAL ADMIN FUNCTIONS
    // -------------------------------------------------------------

    /// @dev Approves a stat/token ID for deposit.
    function _grantIdDepositApproval(
        address _collectionAddress, 
        uint256 _statOrNftId
    ) internal requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        // make sure stat id has not already been approved
        if (collectionToApprovedIds[_collectionAddress].contains(_statOrNftId)) {
            revert AlreadyApprovedForDeposit(_collectionAddress, _statOrNftId);
        }
        // add stat id to array of approved stats for a collection
        collectionToApprovedIds[_collectionAddress].add(_statOrNftId);
    }

    /// @dev Revokes a stat/token IDs deposit approval.
    function _revokeIdDepositApproval(
        address _collectionAddress,
        uint256 _statOrNftId
    ) internal requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        // make sure id has already been approved
        if (!collectionToApprovedIds[_collectionAddress].contains(_statOrNftId)) {
            revert IdNotApprovedForDeposit(_collectionAddress, _statOrNftId);
        }
        // remove stat id from array of approved stats for a collection
        collectionToApprovedIds[_collectionAddress].remove(_statOrNftId);
    }

    // -------------------------------------------------------------
    //                         INITIALIZER 
    // -------------------------------------------------------------

    function __SmolverseBridgeInternal_init() internal initializer {
        SmolverseBridgeView.__SmolverseBridgeView_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../../shared/UtilitiesV2Upgradeable.sol";
import "../traitshop/SmolsOnChain/ISchool.sol";
import "./IBalanceSheet_DeFrag.sol";
import "./ISmolverseBridge.sol";

/// @title Smolverse Bridge State
/// @author Gearhart
/// @notice State variables, mappings, and interface support for Smolverse Bridge.

abstract contract SmolverseBridgeState is 
    Initializable, 
    UtilitiesV2Upgradeable, 
    ERC1155HolderUpgradeable, 
    ERC721HolderUpgradeable, 
    ReentrancyGuardUpgradeable, 
    ISmolverseBridge 
    {

    // -------------------------------------------------------------
    //                           VARIABLES
    // -------------------------------------------------------------

    ///@dev Land API role for spending assets on behalf of users. Grant with extreme caution.
    bytes32 internal constant AUTHORIZED_BALANCE_ADJUSTER_ROLE = keccak256("AUTHORIZED_BALANCE_ADJUSTER");

    /// @notice Instance of the SmolSchool contract.
    ISchool public smolSchool;
    
    /// @notice Address of SmolLand contract.
    address public smolLand;

    /// @notice Address of SmolBrains contract.
    address public smolBrains;

    /// @notice Address of DeFrag Finance Asset Manager contract for SmolBrains.
    address public deFragAssetManager;

    /// @notice Address of DeFrag Finance Balance Sheet contract for SmolBrains.
    address public deFragBalanceSheet;

    // -------------------------------------------------------------
    //                          USER MAPPINGS
    // -------------------------------------------------------------

    /// @notice NFT collection address, to token ID, to stat ID, to deposited balance.
    mapping (address => mapping (uint256 => mapping( uint256 => uint256))) public collectionToStatBalance;

    /// @notice User address to ERC20 token address to deposited balance.
    mapping (address => mapping ( address => uint256)) public userToERC20Balance;

    /// @notice User address to NFT collection address to token ID to deposited balance.
    mapping (address => mapping (address => mapping (uint256 => uint256))) public userToERC1155Balance;

    /// @notice User address to NFT collection address to token ID to bool indicating if token is currently deposited or not.
    mapping (address => mapping (address => mapping (uint256 => bool))) public userToDepositedERC721s;

    // -------------------------------------------------------------
    //                       COLLECTION MAPPINGS
    // -------------------------------------------------------------

    /// @notice ERC20 token address to bool indicating if the token is approved for ERC20 deposit.
    mapping (address => bool) public addressToERC20DepositApproval;

    /// @notice NFT collection address to bool indicating if the collection is approved for stat deposit.
    mapping (address => bool) public collectionToStatDepositApproval;

    /// @notice NFT collection address to bool indicating if the collection is approved for ERC1155 NFT deposit.
    mapping (address => bool) public collectionToERC1155DepositApproval;

    /// @notice NFT collection address to bool indicating if the collection is approved for ERC721 NFT deposit.
    mapping (address => bool) public collectionToERC721DepositApproval;

    /// @dev NFT collection address to EnumerableSet containing all stat/nft IDs available for deposit for that collection.
    mapping (address => EnumerableSetUpgradeable.UintSet) internal collectionToApprovedIds;

    // -------------------------------------------------------------
    //                     SUPPORTED INTERFACES
    // -------------------------------------------------------------
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155ReceiverUpgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId
        || interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId
        || interfaceId == type(IERC721ReceiverUpgradeable).interfaceId
        || super.supportsInterface(interfaceId);
    }

    // -------------------------------------------------------------
    //                         INITIALIZER
    // -------------------------------------------------------------

    function __SmolverseBridgeState_init() internal initializer {
            UtilitiesV2Upgradeable.__Utilities_init();
            ERC1155HolderUpgradeable.__ERC1155Holder_init();
            ERC721HolderUpgradeable.__ERC721Holder_init();
            ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SmolverseBridgeState.sol";

/// @title Land Stat Bank
/// @author Gearhart
/// @notice View functions and checks to be used by Smolverse Bridge.

abstract contract SmolverseBridgeView is Initializable, SmolverseBridgeState {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // -------------------------------------------------------------
    //                 EXTERNAL VIEW FUNCTIONS
    // -------------------------------------------------------------

    /// @inheritdoc ISmolverseBridge
    function getIdsAvailableForDepositByCollection(
        address _collectionAddress
    ) external view returns(uint256[] memory) {
        return collectionToApprovedIds[_collectionAddress].values();
    }

    /// @inheritdoc ISmolverseBridge
    function areContractsSet() public view returns (bool) {
        return address(smolLand) != address(0) 
        && address(smolSchool) != address(0)
        && smolBrains != address(0)
        && deFragAssetManager != address(0)
        && deFragBalanceSheet != address(0);
    }

    // -------------------------------------------------------------
    //                    INTERNAL VIEW FUNCTIONS
    // -------------------------------------------------------------

    /// @dev Checks for both deposit types
    function _depositChecks(
        address _collectionAddress,
        uint256 _statOrTokenId
    ) internal view {
        // check stat/token ID approval
        if (!collectionToApprovedIds[_collectionAddress].contains(_statOrTokenId)) {
            revert IdNotApprovedForDeposit(_collectionAddress, _statOrTokenId);
        }
    }

    /// @dev Checks if ERC721 NFT is owned by user.
    function _check721Ownership(
        address _userAddress,
        address _collectionAddress,
        uint256 _tokenId
    ) internal view {
        // verify NFT ownership
        address ownerAddress = IERC721(_collectionAddress).ownerOf(_tokenId);
        if (ownerAddress == _userAddress){
            return;
        }
        // DeFrag is only supported for SmolBrains
        else if (ownerAddress == deFragAssetManager && _collectionAddress == smolBrains) {
            _checkDeFragForSmolOwnership(_userAddress, _tokenId);
            return;
        }
        else {
            revert MustBeOwnerOfNFT(_collectionAddress, _tokenId, _userAddress, ownerAddress);
        }
    }

    /// @dev Checks if user has loaned out NFT with DeFrag.fi
    function _checkDeFragForSmolOwnership(
        address _userAddress,
        uint256 _tokenId
    ) internal view {
        // get full list of tokenIds deposited in DeFrag by user
        uint256[] memory tokenIdsHeldByDeFrag = IBalanceSheet(deFragBalanceSheet).getTokenIds(_userAddress);
        uint256 length = tokenIdsHeldByDeFrag.length;
        if (!IBalanceSheet(deFragBalanceSheet).isExistingUser(_userAddress) || length == 0) revert UserHasNoTokensOnDeFrag(_userAddress);
        // see if any of the tokens match _tokenId
        for (uint256 i = 0; i < length; i++) {
            // if so return
            if (tokenIdsHeldByDeFrag[i] == _tokenId){
                return;
            }
        }
        // if not revert
        revert MustBeOwnerOfNFT(smolBrains, _tokenId, _userAddress, deFragAssetManager);
    }

    /// @dev Checks if tokenId has enough deposited stats.
    function _checkStatBridgeBalance(
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _statId,
        uint256 _amount
    ) internal view {
        uint256 bal = collectionToStatBalance[_collectionAddress][_tokenId][_statId];
        if (bal < _amount) {
            revert InsufficientStatBalance(_collectionAddress, _tokenId, _statId, _amount, bal);
        }
    }

    /// @dev Checks if user has enough deposited ERC20s.
    function _check20BridgeBalance(
        address _userAddress,
        address _tokenAddress,
        uint256 _amount
    ) internal view {
        uint256 bal = userToERC20Balance[_userAddress][_tokenAddress];
        if (bal < _amount) {
            revert InsufficientERC20Balance(_tokenAddress, _amount, bal);
        }
    }

    /// @dev Checks if user has enough deposited ERC1155s.
    function _check1155BridgeBalance(
        address _userAddress,
        address _collectionAddress,
        uint256 _tokenId,
        uint256 _amount
    ) internal view {
        uint256 _bal = userToERC1155Balance[_userAddress][_collectionAddress][_tokenId];
        if (_bal < _amount){
            revert InsufficientNFTBalance(_collectionAddress, _tokenId, _amount, _bal);
        }
    }

    ///@dev Checks stat ID.
    function _checkStatExistence(
        address _collectionAddress, 
        uint256 _statId
    ) internal view {
        // check if stat ID exists on smol school contract
        StatDetails memory statInfo = smolSchool.statDetails(
            _collectionAddress,
            _statId
        );
        if (!statInfo.exists){
            revert StatDoesNotExist(_collectionAddress, _statId);
        }
    }

    ///@dev checks amounts
    function _checkAmounts(
        uint256 _amount
    ) internal pure {
        // check amount
        if (_amount <= 0){
            revert AmountMustBeGreaterThanZero();
        }
    }

    /// @dev Check array lengths.
    function _checkLengths(
        uint256 target,
        uint256 length
    ) internal pure {
        if (target != length) {
            revert ArrayLengthMismatch();
        }
    }

    // -------------------------------------------------------------
    //                           MODIFIER
    // -------------------------------------------------------------

    /// @dev Modifier to verify contracts are set.
    modifier contractsAreSet() {
        if(!areContractsSet()){
            revert ContractsNotSet();
        }
        _;
    }

    // -------------------------------------------------------------
    //                         INITIALIZER
    // -------------------------------------------------------------

    function __SmolverseBridgeView_init() internal initializer {
            SmolverseBridgeState.__SmolverseBridgeState_init();
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct TokenDetails {
    uint128 statAccrued;
    uint64 timestampJoined;
    bool joined;
}

struct StatDetails {
    uint128 globalStatAccrued;
    uint128 emissionRate;
    bool exists;
    bool joinable;
}

interface ISchool {
    function tokenDetails(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) external view returns (TokenDetails memory);

    function getPendingStatEmissions(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) external view returns (uint128);

    function statDetails(address _collectionAddress, uint256 _statId)
        external
        view
        returns (StatDetails memory);

    function totalStatsJoinedWithinCollection(
        address _collectionAddress,
        uint256 _tokenId
    ) external view returns (uint256);

    function getTotalStatPlusPendingEmissions(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) external view returns (uint128);

    function addStatAsAllowedAdjuster(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId,
        uint128 _amountOfStatToAdd
    ) external;

    function removeStatAsAllowedAdjuster(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId,
        uint128 _amountOfStatToRemove
    ) external;
}