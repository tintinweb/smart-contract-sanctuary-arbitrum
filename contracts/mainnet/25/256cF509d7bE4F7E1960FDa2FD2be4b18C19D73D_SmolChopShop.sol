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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal onlyInitializing {
    }

    function __ERC1155Burnable_init_unchained() internal onlyInitializing {
    }
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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

interface IRandomizer {

    // Sets the number of blocks that must pass between increment the commitId and seeding the random
    // Admin
    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external;

    // Increments the commit id.
    // Admin
    function incrementCommitId() external;

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external;

    // Returns a request ID for a random number. This is unique.
    function requestRandomNumber() external returns(uint256);

    // Returns the random number for the given request ID. Will revert
    // if the random is not ready.
    function revealRandomNumber(uint256 _requestId) external view returns(uint256);

    // Returns if the random number for the given request ID is ready or not. Call
    // before calling revealRandomNumber.
    function isRandomReady(uint256 _requestId) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Smol Chop Shop Interface
/// @author Gearhart
/// @notice Interface and custom errors for SmolChopShop. 

interface ISmolChopShop {

    // -------------------------------------------------------------
    //                     Custom Errors
    // -------------------------------------------------------------
    
    error ContractsAreNotSet();
    error ArrayLengthMismatch();
    error TrophyExchangeValueNotSet();
    error CoconutIdNotSet();
    error InsufficientTrophies(uint256 _balance, uint256 _price);
    error InvalidTrophyExchangeValue(uint256 _value);
    error InvalidUpgradeSupply();
    error UpgradeIdDoesNotExist(uint256 _upgradeId);
    error UpgradeIdSoldOut(uint256 _upgradeId);
    error UpgradeNotCurrentlyForSale(uint256 _upgradeId);
    error UpgradeNotCompatibleWithSelectedVehicle(VehicleType _vehicleType, VehicleType _expectedVehicleType);
    error UpgradeIsNotTradable();
    error MustBeOwnerOfVehicle();
    error ValidSkinIdMustBeOfTypeSkin(uint256 _validSkinId);
    error UpgradeAlreadyUnlockedForVehicle(address _vehicleAddress, uint256 _vehicleId, uint256 _upgradeId);
    error UpgradeNotUnlockedForVehicle(address _vehicleAddress, uint256 _vehicleId, uint256 _upgradeId);
    error UpgradeNotCompatibleWithSelectedSkin(uint256 _selectedSkinId, uint256 _validSkinId);
    error VehicleCanOnlyOwnOneSkin();
    error MustOwnASkinToUnlockOtherUpgrades();
    error MustOwnRequiredSkinToUnlockUpgrade(address _vehicleAddress, uint256 _vehicleId, uint256 _requiredUpgradeId);
    error UpgradeNotOfRequiredType(uint256 _upgradeId, UpgradeType _expectedUpgradeType);
    error UpgradeNotPartOfSpecialEventClaim(uint32 _limitedOfferId, uint32 subgroupId); 
    error UpgradeNotAvailableForGlobalClaim(uint32 _limitedOfferId, uint32 subgroupId);
    error MustCallBuyExclusiveUpgrade(uint256 _upgradeId);
    error MustCallSpecialEventClaim(uint256 _upgradeId);
    error MustCallGlobalClaim(uint256 _upgradeId);
    error MerkleRootNotSet();
    error InvalidMerkleProof();
    error WhitelistAllocationExceeded();
    error InvalidLimitedOfferId();
    error InvalidVehicleAddress(address _vehicleAddress);
    error AlreadyClaimedFromThisGlobalDrop(address _vehicleAddress, uint256 _vehicleId, uint256 _limitedOfferId, uint256 _groupId);
    error AlreadyClaimedSpecialUpgradeFromThisGroup(address _user, address _vehicleAddress, uint256 _vehicleId, uint256 _upgradeId);

    // -------------------------------------------------------------
    //                      External Functions
    // -------------------------------------------------------------

    /// @notice Unlock individual upgrade for one vehicle.
    /// @dev Will revert if either limitedOfferId or subgroupId are > 0 for selected upgrade.
    /// @param _vehicleAddress Address of collection that vehicle token is from.
    /// @param _vehicleId Id number of selected vehicle token.
    /// @param _upgradeId Id number of specifiic upgrade.
    function buyUpgrade(
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) external;

    /// @notice Unlock individual upgrade for multiple vehicles or multiple upgrades for single vehicle. Can be any slot or even multiples of one slot type. 
    /// @dev Will revert if either limitedOfferId or subgroupId are > 0 for selected upgrade.
    /// @param _vehicleAddress Array of addresses for collections that vehicle tokens are from.
    /// @param _vehicleId Array of id numbers for selected vehicle tokens.
    /// @param _upgradeId Array of id numbers for selected upgrades.
    function buyUpgradeBatch(
        address[] calldata _vehicleAddress,
        uint256[] calldata _vehicleId,
        uint256[] calldata _upgradeId
    ) external;

    /// @notice Unlock upgrade that is gated by a merkle tree whitelist. Only unlockable with valid proof.
    /// @dev Will revert if either limitedOfferId or subgroupId are > 0 for selected upgrade.
    /// @param _proof Merkle proof to be checked against stored merkle root.
    /// @param _vehicleAddress Address of collection that vehicle token is from.
    /// @param _vehicleId Id number of selected vehicle token.
    /// @param _upgradeId Id number of specifiic upgrade.
    function buyExclusiveUpgrade(
        bytes32[] calldata _proof,
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) external;

    /// @notice Unlock a limited offer upgrade for a specific limited offer subgroup that is gated by a whitelist. Only unlockable with valid Merkle proof.
    /// @dev Will revert if upgrade has no Merkle root set, if upgrade is not apart of a limitedOfferId > 0 with valid subgroup, or if user has claimed any other upgrade from the same subgroup.
    /// @param _proof Merkle proof to be checked against stored Merkle root.
    /// @param _vehicleAddress Address of collection that vehicle token is from.
    /// @param _vehicleId Id number of selected vehicle token.
    /// @param _upgradeId Id number of specifiic upgrade.
    function specialEventClaim(
        bytes32[] calldata _proof,
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) external;

    /// @notice Unlock a limited offer upgrade for a specific limited offer group that is part of a global claim. One claim per vehicle.
    /// @dev Will revert if upgrade has no Merkle root set, if upgrade is not apart of a limitedOfferId = 0 with valid subgroup, or if user has claimed any other upgrade from the same subgroup.
    /// @param _vehicleAddress Address of collection that vehicle token is from.
    /// @param _vehicleId Id number of selected vehicle token.
    /// @param _upgradeId Id number of specifiic upgrade.
    function globalClaim(
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) external;

    /// @notice Equip sets of unlocked upgrades for vehicles. Or equip skin Id 0 to unequip all upgrades and return vehicle to initial state. Unequipped items are not lost.
    /// @param _vehicleAddress Array of addresses for collections that vehicle tokens are from.
    /// @param _vehicleId Array of id numbers for selected vehicle tokens.
    /// @param _upgradesToEquip Array of Vehicle structs with upgrade ids to be equipped to each vehicle.
    function equipUpgrades(
        address[] calldata _vehicleAddress,
        uint256[] calldata _vehicleId,
        Vehicle[] calldata _upgradesToEquip
    ) external;

    /// @notice Burns amount of trophies in exchange for equal value in Coconuts. One way exchange. No converting back to racingTrophies from Coconuts. Coconuts are only used to buy vehicle upgrades and exchange for Magic emissions. 
    /// @param _trophyIds Token Ids of trophy nfts to be burned.
    /// @param _amountsToBurn Amounts of each trophy id to be exchanged at current rate.
    function exchangeTrophiesBatch(
        uint256[] calldata _trophyIds, 
        uint256[] calldata _amountsToBurn
    ) external;

    // -------------------------------------------------------------
    //                      View Functions
    // -------------------------------------------------------------

    /// @notice Get currently equipped upgrades for a vehicle. 
    /// @param _vehicleAddress Address of collection that vehicle token is from.
    /// @param _vehicleId Id number of vehicle token.
    /// @return equippedUpgrades_ Vehicle struct containing ids of equipped Upgrades for a given vehicle.
    function getEquippedUpgrades(
        address _vehicleAddress,
        uint256 _vehicleId
    ) external view returns (Vehicle memory equippedUpgrades_);

    /// @notice Get all upgrades unlocked for a vehicle.
    /// @param _vehicleAddress Address of collection that vehicle token is from.
    /// @param _vehicleId Id number of vehicle token.
    /// @return unlockedUpgrades_ Array of all upgrade ids for a given type that have been unlocked for a vehicle.
    function getAllUnlockedUpgrades (
        address _vehicleAddress, 
        uint256 _vehicleId
    ) external view returns (uint256[] memory unlockedUpgrades_);

    /// @notice Check to see if a specific upgrade is unlocked for a given vehicle.
    /// @param _vehicleAddress Address of collection that vehicle token is from.
    /// @param _vehicleId Id number of vehicle token.
    /// @param _upgradeId Id number of specifiic upgrade.
    /// @return isOwnedByVehicle_ Bool indicating if upgrade is owned (true) or not (false).
    function getUpgradeOwnershipByVehicle(
        address _vehicleAddress, 
        uint256 _vehicleId,
        uint256 _upgradeId
    ) external view returns (bool isOwnedByVehicle_);

    /// @notice Check to see if a given vehicle has a skin unlocked.
    /// @param _vehicleAddress Address of collection that vehicle token is from.
    /// @param _vehicleId Id number of vehicle token.
    /// @return skinOwned_ Bool indicating if vehicle has unlocked a skin (true) or not (false).
    function skinOwnedByVehicle(
        address _vehicleAddress, 
        uint256 _vehicleId
    ) external view returns (bool skinOwned_);

    /// @notice Get all information about an upgrade by id.
    /// @param _upgradeId Id number of specifiic upgrade.
    /// @return Upgrade struct containing all information/metadata for a given upgrade Id. 
    function getUpgradeInfo ( 
        uint256 _upgradeId
    ) external view returns (Upgrade memory);

    /// @notice Check which id numbers of a specific upgrade type are currently for sale.
    /// @return upgradeTypeForSale_ Array of upgrade id numbers that can be bought/claimed for a specific upgrade type.
    function getUpgradesForSale(
        UpgradeType _upgradeType
    ) external view returns (uint256[] memory upgradeTypeForSale_);

    /// @notice Get upgrade ids that have been added to a specified subgroup for a given limited offer id.
    /// @dev All subgroups for each limitedOfferId > 0 represent seperate pools of upgrades available for a given special event. Each subgroup for limitedOfferId = 0 represents a seperate global claim.
    /// @param _limitedOfferId Number associated with the limitedOffer where trait subgroups were decided.
    /// @param _subgroupId Number associated with the subgroup array within limitedOfferId to be queried.
    /// @return subgroup_ Array of all upgrade ids for a given limitedOfferId and subgroupId.
    function getSubgroupFromLimitedOfferId(
        uint256 _limitedOfferId,
        uint256 _subgroupId
    ) external view returns(uint256[] memory subgroup_);

    /// @dev Returns base URI concatenated with upgrade ID + suffix.
    /// @param _upgradeId Id number of upgrade.
    /// @return uri_ Complete URI string for specific upgrade id. 
    function upgradeURI(
        uint256 _upgradeId
    ) external view returns (string memory uri_);

    /// @notice Verify necessary contract addresses have been set.
    function areContractsSet() external view returns(bool);

    // -------------------------------------------------------------
    //                      Admin Functions
    // -------------------------------------------------------------

    /// @notice Set new Upgrade struct info and save it to upgradeToInfo mapping.
    /// @dev Upgrade ids are auto incremented and assigned. Ids are unique to each upgrade type.
    /// @param _upgradeInfo Array of upgrade structs containing all information needed to add upgrade to contract.
    function setUpgradeInfo (
        CreateUpgradeArgs[] calldata _upgradeInfo
    ) external;

    /// @notice Edit Upgrade struct info and save it to upgradeToInfo mapping.
    /// @dev Cannot change UpgradeType after upgrade is added to contract.
    /// @param _upgradeId Array of upgrade ids to change info for.
    /// @param _newUpgradeInfo Array of upgrade structs containing all information to be saved to upgradeToInfo mapping.
    function changeUpgradeInfo(
        uint256[] calldata _upgradeId,
        CreateUpgradeArgs[] calldata _newUpgradeInfo
    ) external;

    /// @notice Set new base and suffix for URI to be concatenated with upgrade Id.
    /// @param _newBaseURI Portion of URI to come before upgrade Id + Suffix.
    /// @param _newSuffixURI Example suffix: ".json" for IPFS metadata or ".png" for IPFS images.
    function changeURI( 
        string calldata _newBaseURI,
        string calldata _newSuffixURI
    ) external;

    /// @notice Add limited offer upgrade ids to a subgroup within a limitedOfferId for specialEventClaim or globalClaim.
    /// @param _limitedOfferId Number of limited offer to set subgroups for. Must not be greater than latestLimitedOffer.
    /// @param _subgroupId Subgroup Id to differenciate between groups within limited offer id.
    /// @param _upgradeIds Array of id numbers to be added to a subgroup.
    function addUpgradeIdsToLimitedOfferGroup(
        uint256 _limitedOfferId,
        uint256 _subgroupId,
        uint256[] calldata _upgradeIds
    ) external;

    /// @notice Remove limited offer upgrade ids from a subgroup within a limitedOfferId to remove id from specialEventClaim or globalClaim.
    /// @param _limitedOfferId Number of limited offer to edit subgroups for. Must not be greater than latestLimitedOffer.
    /// @param _subgroupId Subgroup Id to differenciate between groups within limited offer id.
    /// @param _upgradeIds Upgrade id numbers to be removed from a subgroup within a limitedOfferId.
    function removeUpgradeIdsFromLimitedOfferGroup(
        uint256 _limitedOfferId,
        uint256 _subgroupId,
        uint256[] calldata _upgradeIds
    ) external;

    /// @notice Increment latestLimitedOfferId number by one to open up new subgroups for next special claim without erasing the last set.
    function incrementLimitedOfferId() external;

    /// @notice Set other trophy values in Coconuts for calculating exchange rate.
    /// @param _trophyId Array of trophy id numbers from the racing trophies contract.
    /// @param _trophyExchangeValue Array of trophy values (denominated in Coconuts) to be assigned to each given _trophyId.
    function setExchangeRates(
        uint256[] calldata _trophyId,
        uint256[] calldata _trophyExchangeValue
    ) external;

    /// @notice Set Id for 1155 token from racing trophy contract that will function as the chop shops payment currency.
    /// @dev Must be set to buy upgrades or exchange trophies.
    /// @param _coconutId Id number of Coconut NFT from the racing trophies contract.
    function setCoconutId(
        uint256 _coconutId
    ) external;

    /// @notice Set other contract addresses.
    function setContracts(
        address _smolCars,
        address _swolercycles,
        address _smolRacing,
        address _racingTrophies
    ) external;

    // -------------------------------------------------------------
    //                       Events
    // -------------------------------------------------------------

    /// @notice New upgrade has been unlocked for a vehicle.
    /// @param _vehicleAddress Address of collection that vehicle belongs to.
    /// @param _vehicleId Id number of vehicle that upgrade has been unlocked for.
    /// @param _upgradeId Id number of specifiic upgrade.
    /// @param _userAddress Address of vehicle owner.
    event UpgradeUnlocked(
        address indexed _vehicleAddress,
        uint256 indexed _vehicleId,
        uint256 indexed _upgradeId,
        address _userAddress
    );

    /// @notice New set of upgrades have been equipped to vehicle.
    /// @param _vehicleAddress Address of collection that vehicle belongs to.
    /// @param _vehicleId Id number of vehicle that upgrades have been applied to.
    /// @param _equippedUpgrades Vehicle struct that holds all currently equipped upgrades for a given vehicle.
    event UpgradesEquipped(
        address indexed _vehicleAddress,
        uint256 indexed _vehicleId,
        Vehicle _equippedUpgrades
    );

    /// @notice New upgrade has been added to contract.
    /// @param _upgradeId Id number of newly added upgrade.
    /// @param _upgradeInfo Upgrade struct holding all info/metadata for that upgrade.
    event UpgradeAddedToContract(
        uint256 indexed _upgradeId,
        Upgrade _upgradeInfo
    );

    /// @notice Upgrade has been added to or removed from sale.
    /// @dev forSale is a representation of if an item is currently claimable/buyable. It does not indicate if an upgrade is free or paid.
    /// @param _upgradeId Id number of upgrade that has been added/removed from sale.
    /// @param _added Bool indicating if an upgrade has been added to (true) or removed from (false) sale.
    event UpgradeSaleStateChanged(
        uint256 indexed _upgradeId,
        bool indexed _added
    );

    /// @notice Upgrade info has been changed
    /// @param _upgradeId Id number of upgrade that has had it's info/metadata changed.
    /// @param _upgradeInfo Upgrade struct holding all metadata for that upgrade.
    event UpgradeInfoChanged(
        uint256 indexed _upgradeId,
        Upgrade _upgradeInfo
    );

    // -------------------------------------------------------------
    //                       Enums
    // -------------------------------------------------------------

    // enum to control input, globaly unique id number generation, and upgrade application
    enum UpgradeType {
        Skin,
        Color,
        TopMod,
        FrontMod,
        SideMod,
        BackMod
    }

    // enum to control input and application by vehicle type
    enum VehicleType {
        Car,
        Cycle,
        Either
    }

    // -------------------------------------------------------------
    //                       Structs
    // -------------------------------------------------------------

    // struct for adding upgrades to contract to limit chance of admin error
    struct CreateUpgradeArgs {
        string name;
        uint32 price;
        uint32 maxSupply;
        uint32 limitedOfferId;                  // buy/buybatch = 0, exclusive = 0, specialEventClaim != 0, globalClaim = 0
        uint32 subgroupId;                      // buy/buybatch = 0, exclusive = 0, specialEventClaim != 0, globalClaim != 0
        bool forSale;
        bool tradable;
        UpgradeType upgradeType;
        uint32 validSkinId;
        VehicleType validVehicleType;
        bytes32 merkleRoot;
    }

    // struct to hold all relevant info needed for the purchase and application of upgrades
    // slot1:
    //    amountClaimed
    //    limitedOfferId
    //    maxSupply
    //    price
    //    subgroupId
    //    forSale
    //    tradable
    //    uncappedSupply
    //    upgradeType
    //    validSkinId
    //    validVehicleType
    //    {_gap} uint 24
    // slot2:
    //    name
    // slot3:
    //    uri
    // slot4:
    //    merkleRoot
    struct Upgrade {
        // ----- slot 1 -----
        uint32 amountClaimed;
        uint32 limitedOfferId;                  // buy/buybatch = 0, exclusive = 0, specialEventClaim != 0, globalClaim = 0
        uint32 maxSupply;
        uint32 price;
        uint32 subgroupId;                      // buy/buybatch = 0, exclusive = 0, specialEventClaim != 0, globalClaim != 0
        bool forSale;
        bool tradable;
        bool uncappedSupply;
        UpgradeType upgradeType;
        uint32 validSkinId;
        VehicleType validVehicleType;
        // ----- slot 2 -----
        string name;
        // ----- slot 3 -----
        string uri;
        // ----- slot 4 -----
        bytes32 merkleRoot;
    }

   // struct to act as inventory slots for attaching upgrades to vehicles
    struct Vehicle {
        uint32 skin;
        uint32 color;
        uint32 topMod;
        uint32 frontMod;
        uint32 sideMod;
        uint32 backMod;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SmolChopShopInternal.sol";

/// @title Smol Chop Shop
/// @author Gearhart
/// @notice Store front for users to purchase and equip vehicle upgrades.

contract SmolChopShop is Initializable, SmolChopShopInternal {

    // -------------------------------------------------------------
    //                      Buy Upgrades
    // -------------------------------------------------------------

    // Unlock individual upgrade for single vehicle.
    /// @inheritdoc ISmolChopShop
    function buyUpgrade(
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) external contractsAreSet whenNotPaused {
        _checkPurchaseType(_upgradeId);
        _buy(msg.sender, _vehicleAddress, _vehicleId, _upgradeId);
    }

    // Unlock individual upgrade for multiple vehicles or multiple upgrades for single vehicle. Can be any slot or even multiples of one slot type.
    /// @inheritdoc ISmolChopShop
    function buyUpgradeBatch(
        address[] calldata _vehicleAddress,
        uint256[] calldata _vehicleId,
        uint256[] calldata _upgradeId
    ) external contractsAreSet whenNotPaused {
        uint256 amount = _upgradeId.length;
        _checkLengths(amount, _vehicleId.length); 
        _checkLengths(amount, _vehicleAddress.length);
        for (uint256 i = 0; i < amount; i++) {
            _checkPurchaseType(_upgradeId[i]);
            _buy(msg.sender, _vehicleAddress[i], _vehicleId[i], _upgradeId[i]);
        }
    }

    // Unlcok upgrade that is gated by a merkle tree whitelist. Only unlockable with valid proof.
    /// @inheritdoc ISmolChopShop
    function buyExclusiveUpgrade(
        bytes32[] calldata _proof,
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) external contractsAreSet whenNotPaused {
        _checkPurchaseType(_upgradeId);
        if (userAllocationClaimed[msg.sender][_upgradeId]) revert WhitelistAllocationExceeded();
        userAllocationClaimed[msg.sender][_upgradeId] = true;
        _buyMerkle(msg.sender, _proof, _vehicleAddress, _vehicleId, _upgradeId, 0, 0);
    }

    // Unlock a limited offer upgrade for a specific sub group that is gated by a whitelist. One claim per address.
    /// @inheritdoc ISmolChopShop
    function specialEventClaim(
        bytes32[] calldata _proof,
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) external contractsAreSet whenNotPaused {
        (uint32 _limitedOfferId, uint32 _groupId) = _getLimitedOfferIdAndGroupForUpgrade(_upgradeId);
        if (_limitedOfferId == 0 || _groupId == 0) revert UpgradeNotPartOfSpecialEventClaim(_limitedOfferId, _groupId);
        if (userLimitedOfferAllocationClaimed[msg.sender][_limitedOfferId][_groupId] 
            || vehicleLimitedOfferAllocationClaimed[_vehicleAddress][_vehicleId][_limitedOfferId][_groupId])
        {
            revert AlreadyClaimedSpecialUpgradeFromThisGroup(msg.sender, _vehicleAddress, _vehicleId, _upgradeId);
        }
        userLimitedOfferAllocationClaimed[msg.sender][_limitedOfferId][_groupId] = true;
        vehicleLimitedOfferAllocationClaimed[_vehicleAddress][_vehicleId][_limitedOfferId][_groupId] = true;
        _buyMerkle(msg.sender, _proof, _vehicleAddress, _vehicleId, _upgradeId, _limitedOfferId, _groupId);
    }

    // Unlock a limited offer upgrade for a specific subgroup that is part of a global claim. One claim per vehicle.
    /// @inheritdoc ISmolChopShop
    function globalClaim(
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) external contractsAreSet whenNotPaused {
        (uint32 _limitedOfferId, uint32 _groupId) = _getLimitedOfferIdAndGroupForUpgrade(_upgradeId);
        if (_limitedOfferId != 0 || _groupId == 0) revert UpgradeNotAvailableForGlobalClaim(_limitedOfferId, _groupId);
        if (vehicleLimitedOfferAllocationClaimed[_vehicleAddress][_vehicleId][_limitedOfferId][_groupId]) {
            revert AlreadyClaimedFromThisGlobalDrop(_vehicleAddress, _vehicleId, _limitedOfferId, _groupId);
        }
        vehicleLimitedOfferAllocationClaimed[_vehicleAddress][_vehicleId][_limitedOfferId][_groupId] = true;
        _buy(msg.sender, _vehicleAddress, _vehicleId, _upgradeId);
    }

    // -------------------------------------------------------------
    //                   Equip/Unequip Upgrades
    // -------------------------------------------------------------

    // Equip sets of unlocked upgrades for vehicles. Or equip skin Id 0 to unequip all upgrades and return vehicle to initial state. Unequipped items are not lost.
    /// @inheritdoc ISmolChopShop
    function equipUpgrades(
        address[] calldata _vehicleAddress,
        uint256[] calldata _vehicleId,
        Vehicle[] calldata _upgradesToEquip
    ) external contractsAreSet whenNotPaused {
        uint256 amount = _vehicleId.length;
        _checkLengths(amount, _vehicleAddress.length);
        _checkLengths(amount, _upgradesToEquip.length);
        for (uint256 i = 0; i < amount; i++) {
            _equip(msg.sender, _vehicleAddress[i], _vehicleId[i], _upgradesToEquip[i]);
        }
    }

    // -------------------------------------------------------------
    //                     Exchange Trophies
    // -------------------------------------------------------------

    // Burns amount of each trophy in exchange for equal value in Coconuts. Coconuts are only used to buy vehicle upgrades and exchange for magic emissions. 
    // One way exchange. No converting back to racingTrophies from Coconuts.
    /// @inheritdoc ISmolChopShop
    function exchangeTrophiesBatch(
        uint256[] calldata _trophyIds, 
        uint256[] calldata _amountsToBurn
    ) external contractsAreSet whenNotPaused {
        uint256 length = _trophyIds.length;
        uint256 amountToReceive;
        _checkLengths(length, _amountsToBurn.length);
        for (uint256 i = 0; i < length; i++) {
            if (trophyExchangeValue[_trophyIds[i]] == 0) revert TrophyExchangeValueNotSet();
            _checkTrophyBalance(msg.sender, _trophyIds[i], _amountsToBurn[i]);
            amountToReceive += _amountsToBurn[i] * trophyExchangeValue[_trophyIds[i]];
        }
        require (amountToReceive > 0);
        racingTrophies.burnBatch(msg.sender, _trophyIds, _amountsToBurn);
        racingTrophies.mint(msg.sender, coconutId, amountToReceive);
    }

    // -------------------------------------------------------------
    //                       Initializer
    // -------------------------------------------------------------

    function initialize() external initializer {
        SmolChopShopInternal.__SmolChopShopInternal_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SmolChopShopView.sol";

/// @title Smol Chop Shop Admin Controls
/// @author Gearhart
/// @notice Admin control functions for SmolChopShop.

abstract contract SmolChopShopAdmin is Initializable, SmolChopShopView {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // -------------------------------------------------------------
    //               External Admin/Owner Functions
    // -------------------------------------------------------------

    // Set new Upgrade struct info and save it to upgradeToInfo mapping.
    /// @inheritdoc ISmolChopShop
    function setUpgradeInfo (
        CreateUpgradeArgs[] calldata _upgradeInfo
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        uint256 amount = _upgradeInfo.length;
        for (uint256 i = 0; i < amount; i++) {
            UpgradeType upgradeType = _upgradeInfo[i].upgradeType;
            if (_upgradeInfo[i].validSkinId != 0) {
                _checkUpgradeId(_upgradeInfo[i].validSkinId);
                if (!_isUpgradeInType(UpgradeType.Skin, _upgradeInfo[i].validSkinId)) revert ValidSkinIdMustBeOfTypeSkin(_upgradeInfo[i].validSkinId);
            }
            Upgrade memory upgrade = Upgrade ({
                name: _upgradeInfo[i].name,
                price: _upgradeInfo[i].price,
                maxSupply: _upgradeInfo[i].maxSupply,
                limitedOfferId: _upgradeInfo[i].limitedOfferId,
                subgroupId: _upgradeInfo[i].subgroupId,
                forSale: _upgradeInfo[i].forSale,
                tradable: _upgradeInfo[i].tradable,
                upgradeType: _upgradeInfo[i].upgradeType,
                validSkinId: _upgradeInfo[i].validSkinId,
                validVehicleType: _upgradeInfo[i].validVehicleType,
                merkleRoot: _upgradeInfo[i].merkleRoot,
                amountClaimed: 0,
                uncappedSupply: _upgradeInfo[i].maxSupply == 0,
                uri: ""
            });
            // gas optimization on sread ops
            uint256 upgradeTypeId = upgradeTypeToLastId[upgradeType] + 1;
            uint256 id = upgradeTypeId + (uint256(upgradeType) * UPGRADE_TYPE_OFFSET);
            upgradeTypeToLastId[upgradeType] = upgradeTypeId;
            upgradeToInfo[id] = upgrade;
            // add concatenated URI to upgrade for event emission but do not need to save to storage
            upgrade.uri = upgradeURI(id);
            emit UpgradeAddedToContract(
                id, 
                upgrade
            );
            // Keep after UpgradeAddedToContract for clean event ordering
            //  UpgradeAddedToContract -> UpgradeAddedToSale
            if (upgrade.forSale){
                _addUpgradeToSale(id);
            }
        }
    }

    // Edit Upgrade struct info and save it to upgradeToInfo mapping.
    /// @inheritdoc ISmolChopShop
    function changeUpgradeInfo(
        uint256[] calldata _upgradeId,
        CreateUpgradeArgs[] calldata _newUpgradeInfo
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        uint256 amount = _upgradeId.length;
        _checkLengths(amount, _newUpgradeInfo.length);
        for (uint256 i = 0; i < amount; i++) {
            uint256 id = _upgradeId[i];
            _checkUpgradeId(id);
            CreateUpgradeArgs calldata _newInfo = _newUpgradeInfo[i];
            Upgrade memory upgrade = upgradeToInfo[id];
            if (_newInfo.validSkinId != 0) {
                _checkUpgradeId(_newInfo.validSkinId);
                if (!_isUpgradeInType(UpgradeType.Skin, _newInfo.validSkinId)) revert ValidSkinIdMustBeOfTypeSkin(_newInfo.validSkinId);
            }
            if (upgrade.maxSupply != _newInfo.maxSupply) {
                if (_newInfo.maxSupply != 0) {
                    if (_newInfo.maxSupply < upgrade.amountClaimed) revert InvalidUpgradeSupply();
                }
                upgrade.maxSupply = _newInfo.maxSupply;
                upgrade.uncappedSupply = _newInfo.maxSupply == 0;
            }
            if (upgrade.forSale != _newInfo.forSale){
                if (upgrade.forSale && !_newInfo.forSale){
                    _removeUpgradeFromSale(id);
                }
                else{
                    _addUpgradeToSale(id);
                }
                upgrade.forSale = _newInfo.forSale;
            }
            upgrade.name = _newInfo.name;
            upgrade.price = _newInfo.price;
            upgrade.limitedOfferId = _newInfo.limitedOfferId;
            upgrade.subgroupId = _newInfo.subgroupId;
            upgrade.tradable = _newInfo.tradable;
            upgrade.validSkinId = _newInfo.validSkinId;
            upgrade.validVehicleType = _newInfo.validVehicleType;
            upgrade.merkleRoot = _newInfo.merkleRoot;
            upgradeToInfo[id] = upgrade;
            // add concatenated URI to upgrade for event emission but do not save to storage
            upgrade.uri = upgradeURI(id);
            emit UpgradeInfoChanged(
                id,
                upgrade
            );
        }
    }

    // Set new base and suffix for URI to be concatenated with upgrade Id.
    /// @inheritdoc ISmolChopShop
    function changeURI(string calldata _newBaseURI, string calldata _newSuffixURI) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE){
        baseURI = _newBaseURI;
        suffixURI = _newSuffixURI;
    }

    // Add limited offer upgrade ids to a subgroup within a limitedOfferId for specialEventClaim or globalClaim.
    /// @inheritdoc ISmolChopShop
    function addUpgradeIdsToLimitedOfferGroup(
        uint256 _limitedOfferId,
        uint256 _subgroupId,
        uint256[] calldata _upgradeIds
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        if (_limitedOfferId > latestLimitedOffer) revert InvalidLimitedOfferId();
        uint256 length = _upgradeIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 id = _upgradeIds[i];
            _checkUpgradeId(id);
            limitedOfferToGroupToIds[_limitedOfferId][_subgroupId].add(id);
        }
    }

    // Remove limited offer upgrade ids from a subgroup within a limitedOfferId to remove id from specialEventClaim or globalClaim.
    /// @inheritdoc ISmolChopShop
    function removeUpgradeIdsFromLimitedOfferGroup(
        uint256 _limitedOfferId,
        uint256 _subgroupId,
        uint256[] calldata _upgradeIds
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        uint256 length = _upgradeIds.length;
        for (uint256 i = 0; i < length; i++) {
            limitedOfferToGroupToIds[_limitedOfferId][_subgroupId].remove(_upgradeIds[i]);
        }
    }

    /// @inheritdoc ISmolChopShop
    function incrementLimitedOfferId() external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE){
        latestLimitedOffer ++;
    }

    // -------------------------------------------------------------
    //                   Internal Functions
    // -------------------------------------------------------------

    /// @dev Adds upgrade id to for sale array.
    function _addUpgradeToSale (
        uint256 _upgradeId
    ) internal {
        upgradeIdsForSale.add(_upgradeId);
        emit UpgradeSaleStateChanged(
            _upgradeId,
            true
        );
    }

    /// @dev Removes upgrade id from for sale array.
    function _removeUpgradeFromSale (
        uint256 _upgradeId
    ) internal {
        upgradeIdsForSale.remove(_upgradeId);
        emit UpgradeSaleStateChanged(
            _upgradeId,
            false
        );
    }

    // -------------------------------------------------------------
    //                 Essential Setter Functions
    // -------------------------------------------------------------

    // Set exchange rate for 1155 trophy ids from racing trophy contract denominated in Coconuts.
    /// @inheritdoc ISmolChopShop
    function setExchangeRates(
        uint256[] calldata _trophyId,
        uint256[] calldata _trophyExchangeValue
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        uint256 amount = _trophyId.length;
        _checkLengths(amount, _trophyExchangeValue.length);
        for(uint256 i = 0; i < amount; i++) {
            if (_trophyExchangeValue[i] == 0) revert InvalidTrophyExchangeValue(_trophyExchangeValue[i]);
            trophyExchangeValue[_trophyId[i]] = _trophyExchangeValue[i];
        }
    }

    // Set Id for 1155 token from racing trophy contract that will function as the chop shops payment currency.
    /// @inheritdoc ISmolChopShop
    function setCoconutId(
        uint256 _coconutId
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        coconutId = _coconutId;
    }

    // Set other contract addresses.
    /// @inheritdoc ISmolChopShop
    function setContracts(
        address _smolCars,
        address _swolercycles,
        address _smolRacing,
        address _racingTrophies
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        smolCars = IERC721(_smolCars);
        swolercycles = IERC721(_swolercycles);
        smolRacing = SmolRacing(_smolRacing);
        racingTrophies = ISmolRacingTrophies(_racingTrophies);
    }

    // -------------------------------------------------------------
    //                       Modifier
    // -------------------------------------------------------------
    
    modifier contractsAreSet() {
        if(!areContractsSet()) revert ContractsAreNotSet();
        _;
    }

    // Verify necessary contract addresses have been set.
    /// @inheritdoc ISmolChopShop
    function areContractsSet() public view returns(bool) {
        return address(smolCars) != address(0)
            && address(swolercycles) != address(0)
            && address(smolRacing) != address(0)
            && address(racingTrophies) != address(0);
    }

    // -------------------------------------------------------------
    //                       Initializer
    // -------------------------------------------------------------

    function __SmolChopShopAdmin_init() internal initializer {
        SmolChopShopView.__SmolChopShopView_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SmolChopShopAdmin.sol";

/// @title Smol Chop Shop Internal
/// @author Gearhart
/// @notice Internal functions used to purchase and equip vehicle upgrades.

abstract contract SmolChopShopInternal is Initializable, SmolChopShopAdmin {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // -------------------------------------------------------------
    //                   Buy Internal Functions
    // -------------------------------------------------------------

    /// @dev Used by all buy functions except for upgrades that require merkle proof verification.
    function _buy(
        address _userAddress,
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) internal {
        if (upgradeToInfo[_upgradeId].merkleRoot != bytes32(0)) revert MustCallBuyExclusiveUpgrade(_upgradeId);
        uint256 price = _checkBeforePurchase(_userAddress, _vehicleAddress, _vehicleId, _upgradeId);
        _unlockUpgrade(_userAddress, price, _vehicleAddress, _vehicleId, _upgradeId);
    }

    /// @dev Used for buy/claim functions that require merkle proof verification. 
    function _buyMerkle(
        address _userAddress,
        bytes32[] calldata _proof,
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId,
        uint256 _limitedOfferId,
        uint256 _groupId
    ) internal {
        if (upgradeToInfo[_upgradeId].merkleRoot == bytes32(0)) revert MerkleRootNotSet();
        _checkWhitelistStatus(_userAddress, _proof, _upgradeId, _limitedOfferId, _groupId);
        uint256 price_ = _checkBeforePurchase(_userAddress, _vehicleAddress, _vehicleId, _upgradeId);
        _unlockUpgrade(_userAddress, price_, _vehicleAddress, _vehicleId, _upgradeId);
    }

    /// @dev Internal helper function that unlocks an upgrade for specified vehicle and emits UpgradeUnlocked event.
    function _unlockUpgrade(
        address _userAddress,
        uint256 _price,
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) internal {
        if (_price != 0){
            racingTrophies.burn(_userAddress, coconutId, _price);
        }
        upgradeToInfo[_upgradeId].amountClaimed ++;
        // If item is sold out; remove that item from sale.
        if (upgradeToInfo[_upgradeId].amountClaimed == upgradeToInfo[_upgradeId].maxSupply) {
            _removeUpgradeFromSale(_upgradeId);
            upgradeToInfo[_upgradeId].forSale = false;
        }
        upgradeIdsUnlockedForVehicle[_vehicleAddress][_vehicleId].add(_upgradeId);
        userToTotalAmountSpent[_userAddress] += _price;
        emit UpgradeUnlocked(
        _vehicleAddress,
        _vehicleId,
        _upgradeId,
        _userAddress
        );
    }

    // -------------------------------------------------------------
    //                  Equip Internal Functions
    // -------------------------------------------------------------
    
    /// @dev Equip a set of unlocked upgrades for single vehicle.
    function _equip(
        address _userAddress,
        address _vehicleAddress,
        uint256 _vehicleId,
        Vehicle calldata _upgradesToEquip
    ) internal {
        _checkVehicleOwnership(_userAddress, _vehicleAddress, _vehicleId);
        Vehicle memory vehicle;
        if (_upgradesToEquip.skin != 0) {
            _checkBeforeEquip(_vehicleAddress, _vehicleId, _upgradesToEquip.skin, 0, UpgradeType.Skin);
            _checkBeforeEquip(_vehicleAddress, _vehicleId, _upgradesToEquip.color, _upgradesToEquip.skin, UpgradeType.Color);
            _checkBeforeEquip(_vehicleAddress, _vehicleId, _upgradesToEquip.topMod, _upgradesToEquip.skin, UpgradeType.TopMod);
            _checkBeforeEquip(_vehicleAddress, _vehicleId, _upgradesToEquip.frontMod, _upgradesToEquip.skin, UpgradeType.FrontMod);
            _checkBeforeEquip(_vehicleAddress, _vehicleId, _upgradesToEquip.sideMod, _upgradesToEquip.skin, UpgradeType.SideMod);
            _checkBeforeEquip(_vehicleAddress, _vehicleId, _upgradesToEquip.backMod, _upgradesToEquip.skin, UpgradeType.BackMod);
            vehicle = _upgradesToEquip;
        }
        vehicleToEquippedUpgrades[_vehicleAddress][_vehicleId] = vehicle;
        emit UpgradesEquipped(
            _vehicleAddress,
            _vehicleId,
            vehicle
        );
    }

    // -------------------------------------------------------------
    //                       Initializer
    // -------------------------------------------------------------

    function __SmolChopShopInternal_init() internal initializer {
        SmolChopShopAdmin.__SmolChopShopAdmin_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "./ISmolChopShop.sol";
import "../../shared/UtilitiesV2Upgradeable.sol";
import "../racingtrophy/ISmolRacingTrophies.sol";
import "../racing/SmolRacing.sol";

/// @title Smol Chop Shop State
/// @author Gearhart
/// @notice Shared storage layout for SmolChopShop.

abstract contract SmolChopShopState is Initializable, UtilitiesV2Upgradeable, ISmolChopShop {

    // -------------------------------------------------------------
    //                   Mappings & Variables
    // -------------------------------------------------------------

    uint256 internal constant UPGRADE_TYPE_OFFSET = 1_000_000;
    uint256 internal constant UPGRADE_LIMITED_OFFER_ID_BIT_OFFSET = 32;
    uint256 internal constant UPGRADE_GROUP_ID_BIT_OFFSET = 128;
    uint256 internal constant UPGRADE_UPGRADE_TYPE_BIT_OFFSET = 184;
    uint256 internal constant UPGRADE_VALID_SKIN_BIT_OFFSET = 192;

    /// @notice smolRacing contract for ownership checks while staking/racing
    SmolRacing public smolRacing;

    /// @notice smolRacingTrophies ERC1155 NFT contract
    ISmolRacingTrophies public racingTrophies;

    /// @notice smolCars ERC721 NFT contract
    IERC721 public smolCars;

    /// @notice swolercycle ERC721 NFT contract
    IERC721 public swolercycles;

    // -------------------------------------------------------------
    //                   Trophy Metadata
    // -------------------------------------------------------------

    /// @notice Id number of ERC1155 token from racing trophies contract that is used for upgrade payment and exchange
    /// @dev used to set values for other trophies and must be set for contract to function
    uint256 public coconutId;

    /// @notice Value associated with each trophy id denominated in Coconuts.
    /// @dev must be set before trophies can be exchanged
    mapping (uint256 => uint256) 
        public trophyExchangeValue;

    /// @notice Mapping for keeping track of how many Coconuts user spent in total.
    /// @dev user address => total amount spent at smolChopShop
    mapping (address => uint256) 
        public userToTotalAmountSpent;

    // -------------------------------------------------------------
    //                   Merkle Verifications
    // -------------------------------------------------------------

    /// @notice mapping for keeping track of user WL allocation during buyExclusiveUpgrade. 
    /// @dev user address => upgrade Id => WL spot claimed or not
    mapping (address => mapping(uint256 => bool))
        public userAllocationClaimed;

    /// @notice Mapping for keeping track of user WL allocation for a subgroup within a limited offer.
    /// @dev user address => limitedOffer id => subgroup id => WL spot claimed or not
    mapping (address => mapping (uint256 => mapping(uint256 => bool)))
        public userLimitedOfferAllocationClaimed;

    /// @notice Mapping for keeping track of vehicle WL allocation for global claim and special event claim.
    /// @dev vehicle address => vehicle id => limitedOffer id => subgroup id => WL spot claimed or not
    mapping (address => mapping(uint256 => mapping (uint256 => mapping(uint256 => bool))))
        public vehicleLimitedOfferAllocationClaimed;

    // -------------------------------------------------------------
    //                   Limited Offers
    // -------------------------------------------------------------

    /// @notice number for keeping track of current limited offer and opening a new level of subgroups (without erasing the last) for specialEventClaim (when incremented)
    /// @dev used when creating a new special event with subgroups. LimitedOfferId = 0 is reserved for globalClaims ONLY. 
    uint256 public latestLimitedOffer;

    // Used to track the pool of available upgrades to choose from for specialEventClaim and globalClaim
    // All subgroups for each limitedOfferId > 0 represent seperate pools of upgrades available for a given special event.
    // Each subgroup for limitedOfferId = 0 represents a seperate global claim.
    // limitedOffer id => subgroup id => ids that are within that group
    mapping (uint256 => mapping (uint256 => EnumerableSetUpgradeable.UintSet))
        internal limitedOfferToGroupToIds;

    // -------------------------------------------------------------
    //                   UpgradeType Metadata
    // -------------------------------------------------------------


    /// @notice Base URI to be concatenated with Upgrade ID + suffix
    /// @dev could also hold individual URIs or SVGs in upgrade struct but having IPFS folders is cheaper. dev has option of using either method
    string public baseURI;

    /// @notice Suffix URI to be concatenated with base + Upgrade ID
    /// @dev ex: ".png" or ".json"
    string public suffixURI;

    /// @notice Highest id number currently in use for each Upgrade type
    /// @dev used to keep track of how many upgrades of each type have been created
    mapping (UpgradeType => uint256) 
        public upgradeTypeToLastId;

    // -------------------------------------------------------------
    //                   Upgrade Metadata
    // -------------------------------------------------------------

    // mapping that holds a struct containing Upgrade info for each id
    // Upgrade id => Upgrade struct 
    mapping (uint256 => Upgrade) 
        internal upgradeToInfo;

    // Set of all Upgrades currently for sale/claim
    EnumerableSetUpgradeable.UintSet internal upgradeIdsForSale;

    // -------------------------------------------------------------
    //                   Vehicle Metadata
    // -------------------------------------------------------------

    // mapping to array of all upgrades that have been unlocked for a given vehicle
    // vehicle collection address => vehicle id => Enumerable Uint Set of all unlocked upgrades
    mapping (address => mapping (uint256 => EnumerableSetUpgradeable.UintSet))
        internal upgradeIdsUnlockedForVehicle;

    // mapping to struct holding ids of currently equiped upgrades for a given vehicle
    // vehicle collection address => vehichle id => Vehicle struct
    mapping (address => mapping (uint256 => Vehicle))
        internal vehicleToEquippedUpgrades;

    // -------------------------------------------------------------
    //                         Internal
    // -------------------------------------------------------------

    /* solhint-disable no-inline-assembly */
    function _getLimitedOfferIdAndGroupForUpgrade(uint256 _upgradeId) internal view returns(uint32 limitedOfferId_, uint8 groupId_){
        uint256 _mask32 = type(uint32).max;
        assembly {
            mstore(0, _upgradeId)
            mstore(32, upgradeToInfo.slot)
            let slot := keccak256(0, 64)

            let upgradeSlot1 := sload(slot)
            // Get the limitedOfferId from the Upgrade struct by offsetting the first 32 bits (amountClaimed value)
            // And only getting the first 32 bits of that part of the slot (for limitedOfferId)
            // shr will delete the least significant 32 bits of the slot data, which is the value of Upgrade.amountClaimed
            // and with the full value of a 32 bit uint will only save the data from the remaining slot that overlaps
            //  the mask with the actual stored value
            limitedOfferId_ := and(shr(UPGRADE_LIMITED_OFFER_ID_BIT_OFFSET, upgradeSlot1), _mask32)
            groupId_ := and(shr(UPGRADE_GROUP_ID_BIT_OFFSET, upgradeSlot1), _mask32)
        }
    }

    function _getTypeForUpgrade(uint256 _upgradeId) internal view returns(UpgradeType upgradeType_){
        uint256 _mask8 = type(uint8).max;
        uint8 upgradeAsUint;
        bytes32 upgradeSlot1;
        assembly {
            mstore(0, _upgradeId)
            mstore(32, upgradeToInfo.slot)
            let slot := keccak256(0, 64)

            upgradeSlot1 := sload(slot)
            // Get the upgradeType from the Upgrade struct by grabbing only the necessary 8 bits from the packed struct
            upgradeAsUint := and(shr(UPGRADE_UPGRADE_TYPE_BIT_OFFSET, upgradeSlot1), _mask8)
        }
        upgradeType_ = UpgradeType(upgradeAsUint);
    }

    function _getValidSkinIdForUpgrade(uint256 _upgradeId) internal view returns(uint32 validSkinId_){
        uint256 _mask32 = type(uint32).max;
        bytes32 upgradeSlot1;
        assembly {
            mstore(0, _upgradeId)
            mstore(32, upgradeToInfo.slot)
            let slot := keccak256(0, 64)

            upgradeSlot1 := sload(slot)
            validSkinId_ := and(shr(UPGRADE_VALID_SKIN_BIT_OFFSET, upgradeSlot1), _mask32)
        }
    }

    // -------------------------------------------------------------
    //                       Initializer
    // -------------------------------------------------------------

    function __SmolChopShopState_init() internal initializer {
        UtilitiesV2Upgradeable.__Utilities_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SmolChopShopState.sol";

/// @title Smol Chop Shop View Functions
/// @author Gearhart
/// @notice External and internal view functions used by SmolChopShop.

abstract contract SmolChopShopView is Initializable, SmolChopShopState {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using StringsUpgradeable for uint256;

    // -------------------------------------------------------------
    //                    External View Functions
    // -------------------------------------------------------------

    // Get currently equipped upgrades for a vehicle. 
    /// @inheritdoc ISmolChopShop
    function getEquippedUpgrades(
        address _vehicleAddress,
        uint256 _vehicleId
    ) external view returns (Vehicle memory equippedUpgrades_) {
        equippedUpgrades_ = vehicleToEquippedUpgrades[_vehicleAddress][_vehicleId];
    }

    // Get all upgrades unlocked for a vehicle.
    /// @inheritdoc ISmolChopShop
    function getAllUnlockedUpgrades(
        address _vehicleAddress, 
        uint256 _vehicleId
    ) external view returns (uint256[] memory unlockedUpgrades_) {
        unlockedUpgrades_ = upgradeIdsUnlockedForVehicle[_vehicleAddress][_vehicleId].values();
    }

    // Check to see if a specific upgrade is unlocked for a given vehicle.
    /// @inheritdoc ISmolChopShop
    function getUpgradeOwnershipByVehicle(
        address _vehicleAddress, 
        uint256 _vehicleId,
        uint256 _upgradeId
    ) public view returns (bool isOwnedByVehicle_) {
        isOwnedByVehicle_ = upgradeIdsUnlockedForVehicle[_vehicleAddress][_vehicleId].contains(_upgradeId);
    }

    // Check to see if a given vehicle has a skin unlocked.
    /// @inheritdoc ISmolChopShop
    function skinOwnedByVehicle(
        address _vehicleAddress, 
        uint256 _vehicleId
    ) public view returns (bool skinOwned_) {
        uint256 length = upgradeIdsUnlockedForVehicle[_vehicleAddress][_vehicleId].length();
        for (uint256 i = 0; i < length; i++) {
            if (_isUpgradeInType(UpgradeType.Skin, upgradeIdsUnlockedForVehicle[_vehicleAddress][_vehicleId].at(i))) {
                return true;
            }
        }
        return false;
    }

    // Get all information about an upgrade by id.
    /// @inheritdoc ISmolChopShop
    function getUpgradeInfo( 
        uint256 _upgradeId
    ) external view returns (Upgrade memory) {
        Upgrade memory upgrade = upgradeToInfo[_upgradeId];
        upgrade.uri = upgradeURI(_upgradeId);
        return upgrade;
    }

    // Check which id numbers of a specific upgrade type are currently for sale.
    /// @inheritdoc ISmolChopShop
    function getUpgradesForSale(
        UpgradeType _upgradeType
    ) external view returns (uint256[] memory upgradeTypeForSale_) {
        uint256 forSaleAllLenth = upgradeIdsForSale.length();
        uint256 countForSaleByUpgrade;
        for (uint256 i = 0; i < forSaleAllLenth; i++) {
            if(!_isUpgradeInType(_upgradeType, upgradeIdsForSale.at(i))) {
                continue;
            }
            countForSaleByUpgrade++;
        }
        upgradeTypeForSale_ = new uint256[](countForSaleByUpgrade);
        uint256 upgradeCountCur;
        for (uint256 i = 0; i < forSaleAllLenth; i++) {
            if(!_isUpgradeInType(_upgradeType, upgradeIdsForSale.at(i))) {
                continue;
            }
            upgradeTypeForSale_[upgradeCountCur++] = upgradeIdsForSale.at(i);
        }
    }

    // Get upgrade ids that have been added to a specified subgroup for a given limited offer id.
    // All subgroups for each limitedOfferId > 0 represent seperate pools of upgrades available for a given special event.
    // Each subgroup for limitedOfferId = 0 represents a seperate global claim.
    /// @inheritdoc ISmolChopShop
    function getSubgroupFromLimitedOfferId(
        uint256 _limitedOfferId,
        uint256 _subgroupId
    ) external view returns(uint256[] memory subgroup_){
        subgroup_ = limitedOfferToGroupToIds[_limitedOfferId][_subgroupId].values();

    }

    // Get full URI for _upgradeId.
    /// @inheritdoc ISmolChopShop
    function upgradeURI(uint256 _upgradeId) public view returns (string memory uri_) {
        _checkUpgradeId(_upgradeId);
        string memory URI = baseURI;
        uri_ = bytes(URI).length > 0 ? string(abi.encodePacked(URI, _upgradeId.toString(), suffixURI)) : "";
    } 

    // -------------------------------------------------------------
    //                  Internal View Functions
    // -------------------------------------------------------------

    /// @dev Various checks that must be made before any upgrade purchase.
    function _checkBeforePurchase(
        address _userAddress,
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId
    ) internal view returns(uint256 price_){
        _checkUpgradeId(_upgradeId);
        _checkVehicleOwnership(_userAddress, _vehicleAddress, _vehicleId);
        Upgrade memory upgrade = upgradeToInfo[_upgradeId];
        if (getUpgradeOwnershipByVehicle(_vehicleAddress, _vehicleId, _upgradeId)) 
        {
            revert UpgradeAlreadyUnlockedForVehicle(_vehicleAddress, _vehicleId, _upgradeId);
        }
        if (!upgrade.forSale) revert UpgradeNotCurrentlyForSale(_upgradeId);
        if (!upgrade.uncappedSupply) {
            if (upgrade.amountClaimed + 1 > upgrade.maxSupply) revert UpgradeIdSoldOut(_upgradeId);
        }
        if (upgrade.upgradeType == UpgradeType.Skin) {
            if (skinOwnedByVehicle(_vehicleAddress, _vehicleId)) {
                revert VehicleCanOnlyOwnOneSkin();
            }
        }
        if (upgrade.upgradeType != UpgradeType.Skin) {
            if (!skinOwnedByVehicle(_vehicleAddress, _vehicleId)) {
                revert MustOwnASkinToUnlockOtherUpgrades();
            }
            uint32 requiredSkinId = upgrade.validSkinId;
            if (requiredSkinId != 0 && !getUpgradeOwnershipByVehicle(_vehicleAddress, _vehicleId, requiredSkinId))
            {
                revert MustOwnRequiredSkinToUnlockUpgrade(_vehicleAddress, _vehicleId, requiredSkinId);
            }
        }
        _checkCompatibility(_vehicleAddress, upgrade.validVehicleType);
        price_ = upgrade.price;
        if (price_ != 0){
            _checkTrophyBalance(_userAddress, coconutId, price_);
        }
    }

    /// @dev Verify _userAddress is vehicle owner and throw if _vehicleAddress is neither car nor cycle.
    function _checkVehicleOwnership(
        address _userAddress,
        address _vehicleAddress,
        uint256 _vehicleId
    ) internal view {
        if (_vehicleAddress == address(smolCars)){
            if (smolCars.ownerOf(_vehicleId) != _userAddress 
                && !smolRacing.ownsVehicle(_vehicleAddress, _userAddress, _vehicleId)) 
            {
                revert MustBeOwnerOfVehicle();
            }
        }
        else if (_vehicleAddress == address(swolercycles)){
            if (swolercycles.ownerOf(_vehicleId) != _userAddress 
                && !smolRacing.ownsVehicle(_vehicleAddress, _userAddress, _vehicleId)) 
            {
                revert MustBeOwnerOfVehicle();
            }
        }
        else{
            revert InvalidVehicleAddress(_vehicleAddress);
        }
    }

    /// @dev Verify upgrade is compatible with selected vehicle and throw if _vehicleAddress is neither car nor cycle.
    function _checkCompatibility(
        address _vehicleAddress,
        VehicleType _validVehicleType
    ) internal view {
        if (_vehicleAddress == address(smolCars)){
            if (_validVehicleType == VehicleType.Cycle) revert UpgradeNotCompatibleWithSelectedVehicle(VehicleType.Car, _validVehicleType);
        }
        else if (_vehicleAddress == address(swolercycles)){
            if (_validVehicleType == VehicleType.Car) revert UpgradeNotCompatibleWithSelectedVehicle(VehicleType.Cycle, _validVehicleType);
        }
        else{
            revert InvalidVehicleAddress(_vehicleAddress);
        }
    }

    /// @dev Check balance of trophyId for _userAddress.
    function _checkTrophyBalance(
        address _userAddress,
        uint256 _trophyId,
        uint256 _amount
    ) internal view {
        if (coconutId == 0) revert CoconutIdNotSet();
        uint256 bal = racingTrophies.balanceOf(_userAddress, _trophyId);
        if (bal < _amount) revert InsufficientTrophies(bal, _amount);
    }

    /// @dev Verify merkle proof for user.
    function _checkWhitelistStatus(
        address _userAddress,
        bytes32[] calldata _proof,
        uint256 _upgradeId,
        uint256 _limitedOfferId,
        uint256 _groupId
    ) internal view {
        bytes32 leaf = keccak256(abi.encodePacked(_userAddress, _limitedOfferId, _groupId));
        if (!MerkleProofUpgradeable.verify(_proof, upgradeToInfo[_upgradeId].merkleRoot, leaf)) revert InvalidMerkleProof();
    }

    /// @dev Check used for ownership and validity when equipping upgrades.
    function _checkBeforeEquip (
        address _vehicleAddress,
        uint256 _vehicleId,
        uint256 _upgradeId,
        uint256 _skinId,
        UpgradeType _expectedUpgradeType
    ) internal view {
        if (_upgradeId != 0) {
            _checkCompatibility(_vehicleAddress, upgradeToInfo[_upgradeId].validVehicleType);
            if (!getUpgradeOwnershipByVehicle(_vehicleAddress, _vehicleId, _upgradeId)) 
            {
                revert UpgradeNotUnlockedForVehicle(_vehicleAddress, _vehicleId, _upgradeId);
            }
            if (!_isUpgradeInType(_expectedUpgradeType, _upgradeId)) revert UpgradeNotOfRequiredType(_upgradeId, _expectedUpgradeType);
            if (_skinId != 0){
                uint256 validSkinId = _getValidSkinIdForUpgrade(_upgradeId);
                if (validSkinId != 0 && validSkinId != _skinId) revert UpgradeNotCompatibleWithSelectedSkin(_skinId, validSkinId);
            }
        }
    }

    /// @dev Checking that buyUpgrade, buyUpgradeBatch, and buyExclusiveUpgrade purchases are going through the correct function for that upgrade.
    function _checkPurchaseType (
        uint256 _upgradeId
    ) internal view {
        (uint32 _limitedOfferId, uint32 _groupId) = _getLimitedOfferIdAndGroupForUpgrade(_upgradeId);
        if (_limitedOfferId != 0) revert MustCallSpecialEventClaim(_upgradeId);
        if (_groupId != 0) revert MustCallGlobalClaim(_upgradeId);
    }

    /// @dev Check to verify array lengths of input arrays are equal
    function _checkLengths(
        uint256 target,
        uint256 length
    ) internal pure {
        if (target != length) revert ArrayLengthMismatch();
    }

    /// @dev Check to verify _upgradeId is within range of valid upgrade ids.
    function _checkUpgradeId (
        uint256 _upgradeId
    ) internal view{
        UpgradeType _upgradeType = _getTypeForUpgrade(_upgradeId);
        if (_upgradeId <= 0 
            || upgradeTypeToLastId[_upgradeType] < _upgradeId - (uint256(_upgradeType) * UPGRADE_TYPE_OFFSET)) 
        {
            revert UpgradeIdDoesNotExist(_upgradeId);
        }
    }

    /// @dev  If the id is in a upgrade type that is not what we are looking for return false
    // ex: _upgradeType == _upgradeType.Color, skip when the id is < the first id in Colors (1 * UPGRADE_TYPE_OFFSET) or >= UpgradeType.TopMod
    function _isUpgradeInType(UpgradeType _upgradeType, uint256 _upgradeId) internal pure returns(bool isInType_) {
        uint256 nextUpgradeTypeOffset = (uint256(_upgradeType) + 1) * UPGRADE_TYPE_OFFSET;
        // The value of the current upgrade type offset for id 1
        uint256 thisUpgradeTypeOffset = (uint256(_upgradeType)) * UPGRADE_TYPE_OFFSET;
        isInType_ = _upgradeId < nextUpgradeTypeOffset && _upgradeId >= thisUpgradeTypeOffset;
    }

    // -------------------------------------------------------------
    //                       Initializer
    // -------------------------------------------------------------

    function __SmolChopShopView_init() internal initializer {
        SmolChopShopState.__SmolChopShopState_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ISmolRacing {
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./ISmolRacing.sol";
import "./SmolRacingAdmin.sol";

contract SmolRacing is Initializable, ISmolRacing, ReentrancyGuardUpgradeable, SmolRacingAdmin {

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // -------------------------------------------------------------
    //                         Initializer
    // -------------------------------------------------------------

    function initialize() external initializer {
        SmolRacingAdmin.__SmolRacingAdmin_init();
    }

    // -------------------------------------------------------------
    //                      External functions
    // -------------------------------------------------------------

    function stakeVehicles(
        SmolCar[] calldata _cars,
        Swolercycle[] calldata _cycles)
    external
    nonReentrant
    contractsAreSet
    whenNotPaused
    {
        require(endEmissionTime == 0 || endEmissionTime > block.timestamp, "Cannot stake");
        require(_cars.length > 0 || _cycles.length > 0, "no tokens given");
        for(uint256 i = 0; i < _cars.length; i++) {
            SmolCar calldata car = _cars[i];
            require(car.numDrivers > 0, "no car drivers given");
            // validation occurs in _stakeVehicleStart
            _stakeVehicle(smolBrains, address(smolCars), Vehicle({
                driverIds: car.driverIds,
                vehicleId: car.carId,
                numRaces: car.numRaces,
                numDrivers: car.numDrivers,
                boostTreasureIds: car.boostTreasureIds,
                boostTreasureQuantities: car.boostTreasureQuantities
            }));
        }
        for(uint256 i = 0; i < _cycles.length; i++) {
            Swolercycle calldata cycle = _cycles[i];
            require(cycle.numDrivers > 0, "no cycle drivers given");
            // validation occurs in _stakeVehicleStart
            uint64[4] memory drivers;
            drivers[0] = cycle.driverIds[0];
            drivers[1] = cycle.driverIds[1];
            _stakeVehicle(smolBodies, address(swolercycles), Vehicle({
                driverIds: drivers,
                vehicleId: cycle.cycleId,
                numRaces: cycle.numRaces,
                numDrivers: cycle.numDrivers,
                boostTreasureIds: cycle.boostTreasureIds,
                boostTreasureQuantities: cycle.boostTreasureQuantities
            }));
        }
    }

    function unstakeVehicles(
        uint256[] calldata _carTokens,
        uint256[] calldata _cycleTokens)
    external
    nonReentrant
    contractsAreSet
    whenNotPaused
    {
        require(_carTokens.length > 0 || _cycleTokens.length > 0, "no tokens given");
        for(uint256 i = 0; i < _carTokens.length; i++) {
            _unstakeVehicle(smolBrains, address(smolCars), _carTokens[i]);
        }
        for(uint256 i = 0; i < _cycleTokens.length; i++) {
            _unstakeVehicle(smolBodies, address(swolercycles), _cycleTokens[i]);
        }
    }

    function restakeVehicles(
        uint256[] calldata _carTokens,
        uint256[] calldata _cycleTokens)
    external
    nonReentrant
    contractsAreSet
    whenNotPaused
    {
        require(endEmissionTime == 0 || endEmissionTime > block.timestamp, "Cannot restake");
        require(_carTokens.length > 0 || _cycleTokens.length > 0, "no tokens given");
        for(uint256 i = 0; i < _carTokens.length; i++) {
           _restakeVehicle(address(smolCars), _carTokens[i]);
        }
        for(uint256 i = 0; i < _cycleTokens.length; i++) {
           _restakeVehicle(address(swolercycles), _cycleTokens[i]);
        }
    }

    function claimRewardsForVehicles(
        uint256[] calldata _carTokens,
        uint256[] calldata _cycleTokens)
    external
    nonReentrant
    contractsAreSet
    whenNotPaused
    {
        require(_carTokens.length > 0 || _cycleTokens.length > 0, "no tokens given");
        for(uint256 i = 0; i < _carTokens.length; i++) {
           _claimRewardsForVehicle(address(smolCars), _carTokens[i]);
        }
        for(uint256 i = 0; i < _cycleTokens.length; i++) {
           _claimRewardsForVehicle(address(swolercycles), _cycleTokens[i]);
        }
    }

    function ownsVehicle(address _collection, address _owner, uint256 _tokenId) external view returns (bool) {
        return userToVehiclesStaked[_collection][_owner].contains(_tokenId);
    }

    function vehiclesOfOwner(address _collection, address _owner) external view returns (uint256[] memory) { 
        return userToVehiclesStaked[_collection][_owner].values();
    }

    // Gassy, do not call from other contracts
    function smolsOfOwner(address _collection, address _owner) external view returns (uint256[] memory) { 
        uint256[] memory vehicles = userToVehiclesStaked[_collection][_owner].values();
        uint256 numDrivers;
        for (uint i = 0; i < vehicles.length; i++) {
            uint256 vehicleId = vehicles[i];
            numDrivers += vehicleIdToVehicleInfo[_collection][vehicleId].numDrivers;
        }

        uint256[] memory retVal = new uint256[](numDrivers);
        for (uint i = 0; i < vehicles.length; i++) {
            Vehicle memory vehicleInfo = vehicleIdToVehicleInfo[_collection][vehicles[i]];
            // numDrivers may be < 4 if the vehicle isn't full of smols
            for (uint j = 0; j < vehicleInfo.numDrivers; j++) {
                uint256 driverCur = vehicleInfo.driverIds[j];
                if(driverCur == 0) {
                    continue;
                }
                retVal[i + j] = driverCur;
            }
        }
        return retVal;
    }

    //Will return 0 if vehicle isnt staked or there are no races to claim
    function numberOfRacesToClaim(address _vehicleAddress, uint256 _tokenId) public view returns(uint256) {
        uint64 curTime = (endEmissionTime == 0 || block.timestamp < endEmissionTime)
            ? uint64(block.timestamp) : uint64(endEmissionTime);

        RacingInfo memory _info = vehicleIdToRacingInfo[_vehicleAddress][_tokenId];

        // Not staked, otherwise this would be the timestamp that the user was staked at
        if(_info.lastClaimed == 0) {
            return 0;
        }

        uint8 maxAvailable = _info.totalRaces - _info.racesCompleted;
        uint256 uncappedPending = (curTime < _info.lastClaimed ? 0
            : curTime - _info.lastClaimed) / timeForReward;

        if(uncappedPending > maxAvailable) {
            return maxAvailable;
        }
        return uncappedPending;
    }

    //Will return 0 if vehicle isnt staked or there are no races to claim
    function vehicleOddsBoost(address _vehicleAddress, uint256 _tokenId) public view returns(uint256) {
        return vehicleIdToRacingInfo[_vehicleAddress][_tokenId].boostedOdds;
    }

    //Will return 0 if vehicle isnt staked or there are no races to claim
    function vehicleRacingInfo(address _vehicleAddress, uint256 _tokenId) external view returns(RacingInfo memory) {
        return vehicleIdToRacingInfo[_vehicleAddress][_tokenId];
    }

    // -------------------------------------------------------------
    //                       Private functions
    // -------------------------------------------------------------

    function _stakeVehicle(IERC721 _smol, address _vehicleAddress, Vehicle memory _vehicle) private {
        require(_vehicle.driverIds.length > 0, "No drivers");

        userToVehiclesStaked[_vehicleAddress][msg.sender].add(_vehicle.vehicleId);
        vehicleIdToVehicleInfo[_vehicleAddress][_vehicle.vehicleId] = _vehicle;
        uint64 curTime = uint64(block.timestamp);
        vehicleIdToRacingInfo[_vehicleAddress][_vehicle.vehicleId] = RacingInfo({
            racingStartTime: curTime,
            totalRaces: _vehicle.numRaces,
            racesCompleted: 0,
            lastClaimed: curTime,
            boostedOdds: _calculateBoostOdds(_vehicleAddress, _vehicle)
        });

        uint256 numDrivers;
        for (uint i = 0; i < _vehicle.driverIds.length; i++) {
            // Doesn't have to have a full vehicle
            if(_vehicle.driverIds[i] == 0) {
                break;
            }
            numDrivers += 1;
            // will revert if does not own
            _smol.safeTransferFrom(msg.sender, address(this), _vehicle.driverIds[i]);
            emit SmolStaked(msg.sender, address(_smol), _vehicle.driverIds[i], curTime);
        }

        // Verify that the given number of drivers match the array.
        // This info is needed to not have to loop for every claim
        require(numDrivers == _vehicle.numDrivers, "incorrect number of drivers given");

        // will revert if does not own
        IERC721(_vehicleAddress).safeTransferFrom(msg.sender, address(this), _vehicle.vehicleId);

        uint256 _requestId = randomizer.requestRandomNumber();
        // always set this, as it will re-set any previous request ids
        //  to get new randoms when staking/unstaking
        tokenIdToRequestId[_vehicleAddress][_vehicle.vehicleId] = _requestId;

        emit StartRacing(
            msg.sender,
            _vehicleAddress,
            _vehicle.vehicleId,
            curTime,
            _vehicle.numRaces,
            _vehicle.driverIds,
            _requestId
        );
    }

    function _restakeVehicle(address _vehicleAddress, uint256 _tokenId) private {
        require(userToVehiclesStaked[_vehicleAddress][msg.sender].contains(_tokenId), "token not staked");

        // store needed state in memory
        Vehicle memory vehicleInfo = vehicleIdToVehicleInfo[_vehicleAddress][_tokenId];
        RacingInfo memory racingInfo = vehicleIdToRacingInfo[_vehicleAddress][_tokenId];
        uint256 pendingRaceRewards = numberOfRacesToClaim(_vehicleAddress, _tokenId);

        // Must finish their racing circuit before returning
        require(racingInfo.racesCompleted + pendingRaceRewards >= racingInfo.totalRaces, "not done racing");

        // claim any rewards pending
        if(pendingRaceRewards > 0) {
            _claimRewards(pendingRaceRewards, _vehicleAddress, _tokenId, racingInfo);
        }
        
        uint64 curTime = uint64(block.timestamp);
        
        // remove vehicle boosts when re-racing 
        vehicleIdToVehicleInfo[_vehicleAddress][_tokenId] = Vehicle({
            driverIds: vehicleInfo.driverIds,
            vehicleId: vehicleInfo.vehicleId,
            numRaces: vehicleInfo.numRaces,
            numDrivers: vehicleInfo.numDrivers,
            boostTreasureIds: new uint64[](0),
            boostTreasureQuantities: new uint32[](0)
        });

        vehicleIdToRacingInfo[_vehicleAddress][_tokenId] = RacingInfo({
            racingStartTime: curTime,
            totalRaces: vehicleInfo.numRaces,
            racesCompleted: 0,
            lastClaimed: curTime,
            boostedOdds: _calculateBoostOdds(_vehicleAddress, vehicleIdToVehicleInfo[_vehicleAddress][_tokenId]) // Must pull from storage
        });

        uint256 _requestId = randomizer.requestRandomNumber();
        // always set this, as it will re-set any previous request ids
        //  to get new randoms when staking/unstaking
        tokenIdToRequestId[_vehicleAddress][vehicleInfo.vehicleId] = _requestId;

        emit RestartRacing(
            msg.sender,
            _vehicleAddress,
            vehicleInfo.vehicleId,
            curTime,
            vehicleInfo.numRaces,
            vehicleInfo.driverIds,
            _requestId
        );
    }

    function _unstakeVehicle(IERC721 _smol, address _vehicleAddress, uint256 _tokenId) private {
        require(userToVehiclesStaked[_vehicleAddress][msg.sender].contains(_tokenId), "token not staked");

        // store needed state in memory
        Vehicle memory vehicleInfo = vehicleIdToVehicleInfo[_vehicleAddress][_tokenId];
        RacingInfo memory racingInfo = vehicleIdToRacingInfo[_vehicleAddress][_tokenId];
        uint256 pendingRaceRewards = numberOfRacesToClaim(_vehicleAddress, _tokenId);

        // Must finish their racing circuit before returning
        if(endEmissionTime == 0 || block.timestamp < endEmissionTime) {
            require(racingInfo.racesCompleted + pendingRaceRewards >= racingInfo.totalRaces, "not done racing");
        }
        else {
            // Assume the last race will not be able to be completed
            require(racingInfo.racesCompleted + pendingRaceRewards >= racingInfo.totalRaces - 1, "not done racing");
        }

        // remove state
        delete vehicleIdToVehicleInfo[_vehicleAddress][_tokenId];
        delete vehicleIdToRacingInfo[_vehicleAddress][_tokenId];
        userToVehiclesStaked[_vehicleAddress][msg.sender].remove(_tokenId);

        // claim any rewards pending
        if(pendingRaceRewards > 0) {
            _claimRewards(pendingRaceRewards, _vehicleAddress, _tokenId, racingInfo);
        }

        // unstake all
        uint64 curTime = uint64(block.timestamp);
        for (uint i = 0; i < vehicleInfo.driverIds.length; i++) {
            // Doesn't have to have a full vehicle
            if(vehicleInfo.driverIds[i] == 0) {
                break;
            }
            _smol.safeTransferFrom(address(this), msg.sender, vehicleInfo.driverIds[i]);
            emit SmolUnstaked(msg.sender, address(_smol), vehicleInfo.driverIds[i]);
        }

        IERC721(_vehicleAddress).safeTransferFrom(address(this), msg.sender, vehicleInfo.vehicleId);

        emit StopRacing(
            msg.sender,
            _vehicleAddress,
            vehicleInfo.vehicleId,
            curTime,
            vehicleInfo.numRaces
        );
    }

    function _claimRewardsForVehicle(address _vehicleAddress, uint256 _tokenId) private {
        require(userToVehiclesStaked[_vehicleAddress][msg.sender].contains(_tokenId), "not vehicle owner");

        uint256 count = numberOfRacesToClaim(_vehicleAddress, _tokenId);
        require(count > 0, "nothing to claim");

        RacingInfo memory racingInfo = vehicleIdToRacingInfo[_vehicleAddress][_tokenId];
        racingInfo.lastClaimed += uint64(count * timeForReward);

        _claimRewards(count, _vehicleAddress, _tokenId, racingInfo);
        
        racingInfo.racesCompleted += uint8(count);

        vehicleIdToRacingInfo[_vehicleAddress][_tokenId] = racingInfo;
    }

    function _claimRewards(uint256 numRewards, address _vehicleAddress, uint256 _tokenId, RacingInfo memory _info) private {
        uint256 seed = _getRandomSeedForVehicle(_vehicleAddress, _tokenId);
        for (uint i = 0; i < numRewards; i++) {
            uint256 curRace = _info.racesCompleted + i + 1;
            uint256 random = uint256(keccak256(abi.encode(seed, curRace)));
            _claimReward(_vehicleAddress, _tokenId, _info.boostedOdds, random);
        }
    }

    function _claimReward(address _vehicleAddress, uint256 _tokenId, uint32 _boostedOdds, uint256 _randomNumber) private {
        uint256 _rewardResult = (_randomNumber % ODDS_DENOMINATOR) + _boostedOdds;
        if(_rewardResult >= ODDS_DENOMINATOR) {
            _rewardResult = ODDS_DENOMINATOR - 1; // This is the 0 based max value for modulus
        }

        uint256 _topRange = 0;
        uint256 _claimedRewardId = 0;
        for(uint256 i = 0; i < rewardOptions.length; i++) {
            uint256 _rewardId = rewardOptions[i];
            _topRange += rewardIdToOdds[_rewardId];
            if(_rewardResult < _topRange) {
                // _rewardId of 0 denotes that a reward should not be minted (bad luck roll)
                if(_rewardId != 0) {
                    _claimedRewardId = _rewardId;

                    // Each driver earns a reward
                    racingTrophies.mint(msg.sender, _claimedRewardId, 1);
                }
                break; // always break to avoid walking the array
            }
        }
        if(_claimedRewardId > 0) {
            emit RewardClaimed(msg.sender, _vehicleAddress, _tokenId, _claimedRewardId, 1);
        }
        else {
            emit NoRewardEarned(msg.sender, _vehicleAddress, _tokenId);
        }
    }

    function _calculateBoostOdds(address _vehicleAddress, Vehicle memory _vehicle) private returns (uint32 boostOdds_) {
        // Additional driver boosts
        if(_vehicleAddress == address(smolCars)) {
            boostOdds_ += ((_vehicle.numDrivers - 1) * additionalSmolBrainBoost); 
        }
        else if(_vehicleAddress == address(swolercycles)) {
            if(_vehicle.numDrivers == 2) {
                boostOdds_ += additionalSmolBodyBoost; 
            }
        }

        // Treasure boosts
        uint256 numBoostItems = _vehicle.boostTreasureIds.length;
        require(numBoostItems == _vehicle.boostTreasureQuantities.length, "Number of treasures much match quantities");
        for (uint i = 0; i < numBoostItems; i++) {
            // burn vs burnBatch because we are already looping which batch would also do
            treasures.burn(msg.sender, _vehicle.boostTreasureIds[i], _vehicle.boostTreasureQuantities[i]);
            
            uint32 boostPerItem = smolTreasureIdToOddsBoost[_vehicle.boostTreasureIds[i]];
            boostOdds_ += boostPerItem * _vehicle.boostTreasureQuantities[i];
        }
        if(boostOdds_ > maxOddsBoostAllowed) {
            // Cannot exceed the max amount of boosted odds
            boostOdds_ = maxOddsBoostAllowed;
        }
    }

    function _getRandomSeedForVehicle(address _vehicleAddress, uint256 _tokenId) private view returns (uint256) {
        uint256 _requestId = tokenIdToRequestId[_vehicleAddress][_tokenId];
        // No need to do sanity checks as they already happen inside of the randomizer
        return randomizer.revealRandomNumber(_requestId);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./SmolRacingState.sol";

abstract contract SmolRacingAdmin is Initializable, SmolRacingState {

    // -------------------------------------------------------------
    //                         Initializer
    // -------------------------------------------------------------

    function __SmolRacingAdmin_init() internal initializer {
        SmolRacingState.__SmolRacingState_init();
    }

    // -------------------------------------------------------------
    //                      External functions
    // -------------------------------------------------------------

    function setContracts(
        address _treasures,
        address _smolBrains,
        address _smolBodies,
        address _smolCars,
        address _swolercycles,
        address _racingTrophies,
        address _randomizer)
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE)
    {
        treasures = ISmolTreasures(_treasures);
        smolBrains = IERC721(_smolBrains);
        smolBodies = IERC721(_smolBodies);
        smolCars = IERC721(_smolCars);
        swolercycles = IERC721(_swolercycles);
        racingTrophies = ISmolRacingTrophies(_racingTrophies);
        randomizer = IRandomizer(_randomizer);
    }

    function setRewards(
        uint256[] calldata _rewardIds,
        uint32[] calldata _rewardOdds)
    external
    requiresEitherRole(ADMIN_ROLE, OWNER_ROLE)
    {
        require(_rewardIds.length == _rewardOdds.length, "Bad lengths");

        delete rewardOptions;

        uint32 _totalOdds;
        for(uint256 i = 0; i < _rewardIds.length; i++) {
            _totalOdds += _rewardOdds[i];

            rewardOptions.push(_rewardIds[i]);
            rewardIdToOdds[_rewardIds[i]] = _rewardOdds[i];
        }

        require(_totalOdds == ODDS_DENOMINATOR, "Bad total odds");
    }

    function setTimeForReward(uint256 _rewardTime) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        timeForReward = _rewardTime;
    }

    function setEndTimeForEmissions(uint256 _endTime) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        endEmissionTime = _endTime;
    }

    // -------------------------------------------------------------
    //                           Modifiers
    // -------------------------------------------------------------

    modifier contractsAreSet() {
        require(areContractsSet(), "Contracts aren't set");
        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(treasures) != address(0)
            && address(randomizer) != address(0)
            && address(smolBrains) != address(0)
            && address(smolBodies) != address(0)
            && address(smolCars) != address(0)
            && address(swolercycles) != address(0)
            && address(racingTrophies) != address(0);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../shared/UtilitiesV2Upgradeable.sol";
import "../../shared/randomizer/IRandomizer.sol";
import "../treasures/ISmolTreasures.sol";
import "../racingtrophy/ISmolRacingTrophies.sol";

abstract contract SmolRacingState is
    Initializable,
    UtilitiesV2Upgradeable,
    ERC721HolderUpgradeable
{
    event SmolStaked(
        address indexed _owner,
        address indexed _smolAddress,
        uint256 indexed _tokenId,
        uint64 _stakeTime
    );
    event StartRacing(
        address indexed _owner,
        address indexed _vehicleAddress,
        uint256 indexed _tokenId,
        uint64 _stakeTime,
        uint8 _totalRaces,
        uint64[4] _driverIds,
        uint256 _requestId
    );
    event RestartRacing(
        address indexed _owner,
        address indexed _vehicleAddress,
        uint256 indexed _tokenId,
        uint64 _stakeTime,
        uint8 _totalRaces,
        uint64[4] _driverIds,
        uint256 _requestId
    );
    event StopRacing(
        address indexed _owner,
        address indexed _vehicleAddress,
        uint256 indexed _tokenId,
        uint64 _stakeTime,
        uint8 _totalRaces
    );
    event SmolUnstaked(
        address indexed _owner,
        address indexed _smolAddress,
        uint256 indexed _tokenId
    );
    event RewardClaimed(
        address indexed _owner,
        address indexed _vehicleAddress,
        uint256 indexed _tokenId,
        uint256 _claimedRewardId,
        uint256 _amount
    );
    event NoRewardEarned(
        address indexed _owner,
        address indexed _vehicleAddress,
        uint256 indexed _tokenId
    );

    ISmolRacingTrophies public racingTrophies;
    ISmolTreasures public treasures;

    IRandomizer public randomizer;

    IERC721 public smolBrains;
    IERC721 public smolBodies;
    IERC721 public smolCars;
    IERC721 public swolercycles;

    // collection address -> user address -> tokens staked for collection
    // collection address can be either SmolCars or Swolercycles
    // token staked is the tokenId of the SmolCar or Swolercycle
    // data for staked smols is in the following mapping
    mapping(address => mapping(address => EnumerableSetUpgradeable.UintSet))
        internal userToVehiclesStaked;

    // collection address => tokenId => Vehicle
    // collection address can be either SmolCars or Swolercycles
    // tokenId is the id of the SmolCar or Swolercycle
    // Vehicle contains ids of who is inside the vehicle and other racing info
    // It is assumed that SmolCars have SmolBrains in them, and Swolercycles have SmolBodies in them
    mapping(address => mapping(uint256 => Vehicle))
        internal vehicleIdToVehicleInfo;

    // collection address => tokenId => Vehicle
    // collection address can be either SmolCars or Swolercycles
    // tokenId is the id of the SmolCar or Swolercycle
    // RacingInfo contains metadata for calculating rewards and determining unstake-ability
    mapping(address => mapping(uint256 => RacingInfo))
        internal vehicleIdToRacingInfo;

    // collection address -> tokenId -> info
    // collection address can be either SmolCars or Swolercycles
    // tokenId is the id of the SmolCar or Swolercycle
    mapping(address => mapping(uint256 => uint256)) public tokenIdToRequestId;

    mapping(address => mapping(uint256 => uint256))
        public tokenIdToStakeStartTime;
    mapping(address => mapping(uint256 => uint256))
        public tokenIdToRewardsClaimed;
    mapping(address => mapping(uint256 => uint256))
        public tokenIdToRewardsInProgress;

    mapping(uint256 => uint32) public smolTreasureIdToOddsBoost;

    uint32 public constant ODDS_DENOMINATOR = 100_000_000;
    uint32 public maxOddsBoostAllowed;
    uint32 public additionalSmolBrainBoost;
    uint32 public additionalSmolBodyBoost;

    uint256[] public rewardOptions;
    // Odds out of 100,000,000
    // treasureTokenId -> Odds of getting reward
    mapping(uint256 => uint32) public rewardIdToOdds;

    uint256 public timeForReward;

    uint256 public endEmissionTime;

    function __SmolRacingState_init() internal initializer {
        UtilitiesV2Upgradeable.__Utilities_init();
        ERC721HolderUpgradeable.__ERC721Holder_init();

        timeForReward = 1 days;

        // Odds are calculated out of 100,000,000 (100 million). This is to obtain the 6 digit precision needed for treasure boost amounts
        // .667% increase per smol after the first one (since the max in a car is 4, caps at 2.001%)
        additionalSmolBrainBoost = 667_000;
        // Having a second body on a cycle increases odds by 1%
        additionalSmolBodyBoost = 1_000_000; // 1 million out of 100 million is 1%
        maxOddsBoostAllowed = 2_500_000; // 2.5% max boost

        uint256 moonrockId = 1;
        uint256 stardustId = 2;
        uint256 cometShardId = 3;
        uint256 lunarGoldId = 4;

        smolTreasureIdToOddsBoost[moonrockId] = 2;     // 0.000002% increase per moonrock
        smolTreasureIdToOddsBoost[stardustId] = 5;     // 0.000005% increase per stardust
        smolTreasureIdToOddsBoost[cometShardId] = 12;  // 0.000012% increase per comet shard
        smolTreasureIdToOddsBoost[lunarGoldId] = 27;   // 0.000027% increase per lunar gold

        // rewards setup after initialization
    }

    struct BoostItem {
        uint64 treasureId;
        uint64 quantity;
    }

    struct BoostItemOdds {
        uint64 quantityNeededForBoost;
        uint32 oddsBoostPerQuantity;
    }

    struct SmolCar {
        uint64[4] driverIds;
        uint64 carId;
        uint8 numRaces;
        uint8 numDrivers;
        uint64[] boostTreasureIds;
        uint32[] boostTreasureQuantities;
    }

    struct Swolercycle {
        uint64[2] driverIds;
        uint64 cycleId;
        uint8 numRaces;
        uint8 numDrivers;
        uint64[] boostTreasureIds;
        uint32[] boostTreasureQuantities;
    }

    struct Vehicle {
        uint64[4] driverIds;
        uint64 vehicleId;
        uint8 numRaces;
        uint8 numDrivers;
        uint64[] boostTreasureIds;
        uint32[] boostTreasureQuantities;
    }

    struct RacingInfo {
        uint64 racingStartTime;
        uint8 totalRaces;
        uint8 racesCompleted;
        uint64 lastClaimed;
        uint32 boostedOdds; // out of 100,000,000 (6 digit precision)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ISmolRacingTrophies is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;

    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ISmolTreasures is IERC1155Upgradeable {

    function mint(address _to, uint256 _id, uint256 _amount) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;

    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}