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

/// @title Smol Trait Shop Interface
/// @author Gearhart
/// @notice Interface and custom errors for SmolTraitShop. 

interface ISmolTraitShop {

    // -------------------------------------------------------------
    //                     Custom Errors
    // -------------------------------------------------------------
    
    error ContractsAreNotSet();
    error ArrayLengthMismatch();
    error InsufficientBalance(uint _balance, uint _price);
    error InvalidTraitSupply();
    error TraitIdDoesNotExist(uint _traitId);
    error TraitIdSoldOut(uint _traitId);
    error TraitNotCurrentlyForSale(uint _traitId);
    error MustBeOwnerOfSmol();
    error TraitAlreadyUnlockedForSmol(uint _smolId, uint _traitId);
    error TraitNotUnlockedForSmol(uint _smolId, uint _traitId);
    error MustCallBuyExclusiveTrait(uint _traitId);
    error TraitNotPartOfSpecialEventClaim();
    error TraitNotAvailableForGlobalClaim(uint _limitedOfferId, uint _subgroupId);
    error MerkleRootNotSet();
    error MustCallSpecialEventClaim(uint _traitId);
    error MustCallGlobalClaim(uint _traitId);
    error InvalidLimitedOfferId();
    error AlreadyClaimedFromThisGlobalDrop(uint _smolId, uint _limitedOfferId, uint _subgroupId);
    error AlreadyClaimedSpecialTraitFromThisSubgroup(address _userAddress, uint _smolId, uint _traitId);
    error InvalidMerkleProof();
    error WhitelistAllocationExceeded();
    error TraitIsNotTradable();
    error TraitNotOfRequiredType(uint256 _traitId, TraitType _expectedTraitType);

    // -------------------------------------------------------------
    //                       Events
    // -------------------------------------------------------------

    /// @notice Event for when a new Trait added to a smols inventory.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitId Id number of specifiic trait.
    event TraitUnlocked(
        uint256 indexed _smolId,
        uint256 indexed _traitId
    );

    /// @notice Event for when a smol changes their equipped Traits.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _equippedTraits SmolBrain struct containing list of equipped traits for each slot.
    event UpdateSmolTraits(
        uint256 indexed _smolId,
        SmolBrain _equippedTraits
    );

    /// @notice Event for when a new Trait is added to the contract.
    /// @param _traitId Id number of newly added trait.
    /// @param _traitInfo Trait struct containing all info associated with specified trait.
    event TraitAddedToContract(
        uint256 indexed _traitId,
        Trait _traitInfo
    );

    /// @notice Event for when a Trait has been added to or removed from sale.
    /// @param _traitId Id number of specifiic trait.
    /// @param _added Boolian indicating if that trait was added (true), or if it was removed (false).
    event TraitSaleStateChanged(
        uint256 indexed _traitId,
        bool _added
    );

    // -------------------------------------------------------------
    //                      External Functions
    // -------------------------------------------------------------

    /// @notice Unlock individual trait for a Smol Brain.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitId Id number of specifiic trait.
    function buyTrait(
        uint256 _smolId,
        uint256 _traitId
    ) external;

    /// @notice Unlock individual trait for multiple Smols or multiple traits for single Smol. Can be any trait slot or even multiples of one trait type. 
    /// @param _smolIds Array of id numbers for selected Smol Brain tokens.
    /// @param _traitIds Array of id numbers for selected traits.
    function buyTraitBatch(
        uint256[] calldata _smolIds,
        uint256[] calldata _traitIds
    ) external;

    /// @notice Unlock trait that is gated by a whitelist. Only unlockable with valid Merkle proof.
    /// @dev Will revert if trait has no Merkle root set or if trait is marked special.
    /// @param _proof Merkle proof to be checked against stored Merkle root.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitId Id number of specifiic trait.
    function buyExclusiveTrait(
        bytes32[] calldata _proof,
        uint256 _smolId,
        uint256 _traitId
    ) external;

    /// @notice Unlock a limited offer trait for a specific limited offer group that is gated by a whitelist. Only unlockable with valid Merkle proof.
    /// @dev Will revert if trait has no Merkle root set, if trait is not apart of a limited offer with valid subgroup, if user has claimed any other trait in the same tier.
    /// @param _proof Merkle proof to be checked against stored Merkle root.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitId Id number of specifiic trait.
    function specialEventClaim(
        bytes32[] calldata _proof,
        uint256 _smolId,
        uint256 _traitId
    ) external;

    /// @notice Unlock a limited offer trait for a specific limited offer group that is part of a global claim. One claim per smol.
    /// @dev Will revert if trait has no Merkle root set, if trait is not apart of a limitedOfferId = 0 with valid subgroup, or if user has claimed any other trait from the same subgroup.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitId Id number of specifiic trait.
    function globalClaim(
        uint256 _smolId,
        uint256 _traitId
    ) external;

    /// @notice Equip sets of unlocked traits for any number of Smol Brains in one tx.
    /// @param _smolId Array of id numbers for selected Smol Brain tokens.
    /// @param _traitsToEquip Array of SmolBrain structs with trait ids to be equipped to each smol.
    function equipTraits(
        uint256[] calldata _smolId,
        SmolBrain[] calldata _traitsToEquip
    ) external;

    // -------------------------------------------------------------
    //                      View Functions
    // -------------------------------------------------------------

    /// @dev Returns base URI concatenated with trait ID + suffix.
    /// @param _traitId Id number of specifiic trait.
    /// @return URI string for trait id of trait type. 
    function traitURI(uint256 _traitId) external view returns (string memory);

    /// @notice Get all info for a specific trait.
    /// @param _traitId Id number of specifiic trait.
    /// @return Trait struct containing all info for a selected trait id.
    function getTraitInfo(
        uint256 _traitId
    ) external view returns (Trait memory);

    /// @notice Get all trait ids for a trait type that are currently owned by selected smol.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @return Array containing trait id numbers that have been unlocked for smol.
    function getTraitsOwnedBySmol(
        uint256 _smolId
    ) external view returns (uint256[] memory);

    /// @notice Check to see if a specific trait id is unlocked for a given smol.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitId Id number of specifiic trait.
    /// @return isOwnedBySmol_ Bool inicating if a trait is unlocked or not.
    function getTraitOwnershipBySmol( 
        uint256 _smolId,
        uint256 _traitId
    ) external view returns (bool isOwnedBySmol_);

    /// @notice Get all trait ids of a specific trait type(0-7) that are currently for sale / available for claim.
    /// @param _traitType Enum (0-7) that indicates which trait type to search for.
    /// @return traitTypeForSale_ Array containing trait id numbers that can currently be bought/claimed for that trait type.
    function getTraitsForSale(
        TraitType _traitType
    ) external view returns (uint256[] memory traitTypeForSale_);

    /// @notice Get trait ids that have been added to a specific subgroup for a given event number.
    /// @param _limitedOfferId Number associated with the event where trait subgroups were decided. (1 = smoloween)
    /// @param _subgroupId Subgroup within limitedOfferId to be returned
    function getSubgroupFromLimitedOfferId(
        uint256 _limitedOfferId,
        uint256 _subgroupId
    ) external view returns(uint256[] memory);

    // -------------------------------------------------------------
    //                      Admin Functions
    // -------------------------------------------------------------

    /// @notice Set new Trait struct info and save it to traitToInfo mapping. Leave URI as "" when setting trait info.
    /// @dev Price should be input as whole numbers, decimals are added during purchase. (ex: 200 magic => price = 200 NOT 200000000000000000000)
    /// @dev Trait ids are auto incremented and assigned. Ids are unique to each trait type.
    /// @param _traitInfo Array of Trait structs containing all information needed to add trait to contract.
    function setTraitInfo (
        CreateTraitArgs[] calldata _traitInfo
    ) external;

    /// @notice Set new base URI to be concatenated with trait Id + suffix.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @param _newBaseURI Portion of URI to come before trait Id + Suffix. 
    function changeBaseURI(
        TraitType _traitType, 
        string calldata _newBaseURI
    ) external;

    /// @notice Set new URI suffix to be added to the end of baseURI + trait Id.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @param _newSuffixURI Example suffix: ".json" for IPFS files
    function changeSuffixURI(
        TraitType _traitType, 
        string calldata _newSuffixURI
    ) external;

    /// @notice Change existing trait sale status.
    /// @dev Also adds and removes trait from for sale array.
    /// @param _traitId Id number of specifiic trait.
    /// @param _forSale New bool value to add(true)/remove(false) traits from sale.
    function changeTraitSaleStatus (
        uint256 _traitId,
        bool _forSale
    ) external;

    /// @notice Change stored merkle root attached to existing trait for whitelist.
    /// @dev Change to 0x0000000000000000000000000000000000000000000000000000000000000000 to remove whitelist.
    /// @param _traitId Id number of specifiic trait.
    /// @param _merkleRoot New merkle root for whitelist verification or empty root for normal sale.
    function changeTraitMerkleRoot (
        uint256 _traitId,
        bytes32 _merkleRoot
    ) external;

    /// @notice Change existing trait name.
    /// @param _traitId Id number of specifiic trait.
    /// @param _name New string to be set as trait name.
    function changeTraitName (
        uint256 _traitId,
        string calldata _name
    ) external;

    /// @notice Change existing trait price.
    /// @param _traitId Id number of specifiic trait.
    /// @param _price New price for trait in base units.
    function changeTraitPrice (
        uint256 _traitId,
        uint32 _price
    ) external;

    /// @notice Change max supply or remove supply cap for an existing trait. 
    /// @dev _maxSupply=0 : No supply cap | _maxSupply>0 : Supply cap is set to _maxSupply.
    /// @param _traitId Id number of specifiic trait.
    /// @param _maxSupply New max supply value for selected trait. Enter 0 to remove supply cap.
    function changeTraitSupply (
        uint256 _traitId,
        uint32 _maxSupply
    ) external;

    /// @notice Change existing trait limited offer id reference. Changing this value will affect claimability per grouping as well as exclusive vs special claims.
    /// @param _traitId Id number of specifiic trait.
    /// @param _limitedOfferId New number of limited offer to set subgroups for.
    /// @param _subgroupId Subgroup Id to differenciate between groups within limited offer id.
    function changeTraitSpecialStatus (
        uint256 _traitId,
        uint32 _limitedOfferId,
        uint8 _subgroupId
    ) external;

    /// @notice Change existing trait tradable status. Set as true to allow a trait to be tokenized and transfered.
    /// @param _traitId Id number of specifiic trait.
    /// @param _tradable New tradable status for a specific trait.
    function changeTraitTradableStatus (
        uint256 _traitId,
        bool _tradable
    ) external;

    /// @notice Add special traits to a subgroup for specialEventClaim.
    /// @param _limitedOfferId Number of limited offer to set subgroups for. Must not be greater than latestLimitedOffer.
    /// @param _subgroupId Subgroup Id to differenciate between groups within limited offer id.
    /// @param _traitIds Array of id numbers to be added to subgroup.
    function addTraitsToLimitedOfferGroup(
        uint256 _limitedOfferId,
        uint256 _subgroupId,
        uint256[] calldata _traitIds
    ) external;

    /// @notice Add special traits to a subgroup for specialEventClaim.
    /// @param _limitedOfferId Number of limited offer to set subgroups for. Must not be greater than latestLimitedOffer.
    /// @param _subgroupId Subgroup Id to differenciate between groups within limited offer id.
    /// @param _traitIds Array of id numbers to be removed from subgroup.
    function removeTraitsFromLimitedOfferGroup(
        uint256 _limitedOfferId,
        uint256 _subgroupId,
        uint256[] calldata _traitIds
    ) external;

    /// @notice Increment latestLimitedOfferId number by one to open up new subgroups for next special claim without erasing the last set of tiers.
    function incrementLimitedOfferId() external;

    /// @notice Withdraw all Magic from contract to treasury.
    function withdrawMagic() external;

    /// @notice Set contract and wallet addresses.
    /// @param _smolBrainsOnChain Address of Smol Brains NFT contract.
    /// @param _magicToken Address of Magic token contract.
    /// @param _treasuryAddress Address of treasury wallet for magic withdrawls 
    function setContracts(
        address _smolBrainsOnChain,
        address _magicToken,
        address _treasuryAddress
    ) external;

    // -------------------------------------------------------------
    //                       Enums
    // -------------------------------------------------------------

    // enum to control input and application
    // Because there are less than 255 values, this enum takes up uint8 storage capacity within a packable slot in a struct
    enum TraitType {
        Background,
        Body,
        Hair,
        Clothes,
        Glasses,
        Hat,
        Mouth,
        Costume
    }

    // -------------------------------------------------------------
    //                       Structs
    // -------------------------------------------------------------

    // struct to hold all relevant info needed for the purchase and application of a trait
    struct CreateTraitArgs {
        string name;
        uint32 price;
        uint32 maxSupply;
        uint32 limitedOfferId;
        bool forSale;
        bool tradable;
        TraitType traitType;
        uint32 subgroupId;
        bytes32 merkleRoot;
    }

    // struct to hold all relevant info needed for the purchase and application of a trait
    // slot1:
    //    amountClaimed
    //    limitedOfferId
    //    maxSupply
    //    price
    //    forSale
    //    tradable
    //    uncappedSupply
    //    traitType
    //    subgroupId
    //    {_gap} uint64
    // slot2:
    //    name
    // slot3:
    //    uri
    // slot4:
    //    merkleRoot
    struct Trait {
        // ----- slot 1 -----
        uint32 amountClaimed;
        // Whether or not this trait is associated to a Limited Offer
        uint32 limitedOfferId;
        uint32 maxSupply;
        uint32 price;
        bool forSale;
        bool tradable;
        bool uncappedSupply;
        TraitType traitType;
        uint32 subgroupId;
        // ----- slot 2 -----
        string name;
        // ----- slot 3 -----
        string uri;
        // ----- slot 4 -----
        // Whether or not a sale is allow listed vs open
        // This can encompass private sales as well as private claims (free sale)
        bytes32 merkleRoot;
    }
   
   // struct to act as inventory slots for equipping traits to smols
    struct SmolBrain {
        uint32 background;
        uint32 body;
        uint32 hair;
        uint32 clothes;
        uint32 glasses;
        uint32 hat;
        uint32 mouth;
        uint32 costume;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SmolTraitShopInternal.sol";

/// @title Smol Trait Shop
/// @author Gearhart
/// @notice Store front for users to purchase and equip traits for Smol Brains.

contract SmolTraitShop is Initializable, SmolTraitShopInternal {

    // -------------------------------------------------------------
    //                     Buy / Claim Traits
    // -------------------------------------------------------------

    // Unlock individual trait for a Smol Brain.
    /// @inheritdoc ISmolTraitShop
    function buyTrait(
        uint256 _smolId,
        uint256 _traitId
    ) external contractsAreSet whenNotPaused {
        _checkPurchaseType(_traitId);
        _buy(msg.sender, _smolId, _traitId);
    }

    // Unlock individual trait for multiple Smols or multiple traits for single Smol. Can be any trait slot or even multiples of one trait type. 
    /// @inheritdoc ISmolTraitShop
    function buyTraitBatch(
        uint256[] calldata _smolIds,
        uint256[] calldata _traitIds
    ) external contractsAreSet whenNotPaused {
        uint256 amount = _smolIds.length;
        _checkLengths(amount, _traitIds.length);
        for (uint256 i = 0; i < amount; i++) {
            _checkPurchaseType(_traitIds[i]);
            _buy(msg.sender, _smolIds[i], _traitIds[i]);
        }
    }

    // Unlock trait that is gated by a whitelist. Only unlockable with valid Merkle proof.
    /// @inheritdoc ISmolTraitShop
    function buyExclusiveTrait(
        bytes32[] calldata _proof,
        uint256 _smolId,
        uint256 _traitId
    ) external contractsAreSet whenNotPaused {
        _checkPurchaseType(_traitId);
        if (userAllocationClaimed[msg.sender][_traitId]) revert WhitelistAllocationExceeded();
        userAllocationClaimed[msg.sender][_traitId] = true;
        _buyMerkle(msg.sender, _proof, _smolId, _traitId, 0, 0);
    }

    // Unlock a limited offer trait for a specific limited offer group that is gated by a whitelist. Only unlockable with valid Merkle proof.
    /// @inheritdoc ISmolTraitShop
    function specialEventClaim(
        bytes32[] calldata _proof,
        uint256 _smolId,
        uint256 _traitId
    ) external contractsAreSet whenNotPaused {
        (uint32 _limitedOfferId, uint32 _subgroupId) = _getLimitedOfferIdAndGroupForTrait(_traitId);
        if (_limitedOfferId == 0 || _subgroupId == 0) revert TraitNotPartOfSpecialEventClaim();
        if (userLimitedOfferAllocationClaimed[msg.sender][_limitedOfferId][_subgroupId] 
            || smolLimitedOfferAllocationClaimed[_smolId][_limitedOfferId][_subgroupId])
        {
            revert AlreadyClaimedSpecialTraitFromThisSubgroup(msg.sender, _smolId, _traitId);
        }
        userLimitedOfferAllocationClaimed[msg.sender][_limitedOfferId][_subgroupId] = true;
        smolLimitedOfferAllocationClaimed[_smolId][_limitedOfferId][_subgroupId] = true;
        _buyMerkle(msg.sender, _proof, _smolId, _traitId, _limitedOfferId, _subgroupId);
    }

    //Unlock a limited offer trait for a specific limited offer group that is part of a global claim. One claim per smol.
    /// @inheritdoc ISmolTraitShop
    function globalClaim(
        uint256 _smolId,
        uint256 _traitId
    ) external contractsAreSet whenNotPaused {
        (uint32 _limitedOfferId, uint32 _subgroupId) = _getLimitedOfferIdAndGroupForTrait(_traitId);
        if (_limitedOfferId != 0 || _subgroupId == 0) revert TraitNotAvailableForGlobalClaim(_limitedOfferId, _subgroupId);
        if (smolLimitedOfferAllocationClaimed[_smolId][_limitedOfferId][_subgroupId]) {
            revert AlreadyClaimedFromThisGlobalDrop(_smolId, _limitedOfferId, _subgroupId);
        }
        smolLimitedOfferAllocationClaimed[_smolId][_limitedOfferId][_subgroupId] = true;
        _buy(msg.sender, _smolId, _traitId);
    }

    // -------------------------------------------------------------
    //                      Equip / Remove Traits
    // -------------------------------------------------------------

    // Equip sets of unlocked traits for any number of Smol Brains in one tx.
    /// @inheritdoc ISmolTraitShop
    function equipTraits(
        uint256[] calldata _smolId,
        SmolBrain[] calldata _traitsToEquip
    ) external contractsAreSet whenNotPaused {
        uint256 amount = _smolId.length;
        _checkLengths(amount, _traitsToEquip.length);
        for (uint256 i = 0; i < amount; i++) {
            _equipSet(msg.sender, _smolId[i], _traitsToEquip[i]);
        }
    }

    // -------------------------------------------------------------
    //                       Initializer
    // -------------------------------------------------------------

    function initialize() external initializer {
        SmolTraitShopInternal.__SmolTraitShopInternal_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SmolTraitShopState.sol";

/// @title Smol Trait Shop Admin Controls
/// @author Gearhart
/// @notice Admin control functions for SmolTraitShop.

abstract contract SmolTraitShopAdmin is Initializable, SmolTraitShopState {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using StringsUpgradeable for uint256;

// -------------------------------------------------------------
//               External Admin/Owner Functions
// -------------------------------------------------------------

    // Set new Trait struct info and save it to traitToInfo mapping.
    /// @inheritdoc ISmolTraitShop
    function setTraitInfo (
        CreateTraitArgs[] calldata _traitInfo
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        uint256 amount = _traitInfo.length;
        for (uint256 i = 0; i < amount; i++) {
            TraitType traitType = _traitInfo[i].traitType;
            Trait memory trait = Trait({
                name: _traitInfo[i].name,
                price: _traitInfo[i].price,
                maxSupply: _traitInfo[i].maxSupply,
                limitedOfferId: _traitInfo[i].limitedOfferId,
                forSale: _traitInfo[i].forSale,
                tradable: _traitInfo[i].tradable,
                traitType: _traitInfo[i].traitType,
                subgroupId: _traitInfo[i].subgroupId,
                merkleRoot: _traitInfo[i].merkleRoot,
                amountClaimed: 0,
                uncappedSupply: _traitInfo[i].maxSupply == 0,
                uri: ""
            });
            // gas optimization on sread ops
            uint256 traitTypeId = traitTypeToLastId[traitType] + 1;
            uint256 id = traitTypeId + (uint256(traitType) * TRAIT_TYPE_OFFSET);
            traitTypeToLastId[traitType] = traitTypeId;
            traitToInfo[id] = trait;
            // add concatenated URI to trait for event emission but do not save to storage
            trait.uri = traitURI(id);
            emit TraitAddedToContract(
                id, 
                trait
            );
            // Keep after TraitAddedToContract for clean event ordering
            //  TraitAddedToContract -> TraitAddedToSale
            if (trait.forSale){
                _addTraitToSale(id);
            }
        }
    }

    //Set new base URI to be concatenated with trait Id + suffix.
    /// @inheritdoc ISmolTraitShop
    function changeBaseURI(TraitType _traitType, string calldata _newBaseURI) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE){
        baseURI[_traitType] = _newBaseURI;
    }

    // Set new URI suffix to be added to the end of baseURI + trait Id.
    /// @inheritdoc ISmolTraitShop
    function changeSuffixURI(TraitType _traitType, string calldata _newSuffixURI) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE){
        suffixURI[_traitType] = _newSuffixURI;
    }

    // Change existing trait sale status.
    /// @inheritdoc ISmolTraitShop
    function changeTraitSaleStatus (
        uint256 _traitId,
        bool _forSale
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        require (traitToInfo[_traitId].forSale != _forSale);
        _checkTraitId(_traitId);
        if (traitToInfo[_traitId].forSale && !_forSale){
            _removeTraitFromSale(_traitId);
            traitToInfo[_traitId].forSale = false;
        }
        else{
            _addTraitToSale(_traitId);
            traitToInfo[_traitId].forSale = true;
        }
    }

    // Change stored merkle root attached to existing trait for whitelist.
    /// @inheritdoc ISmolTraitShop
    function changeTraitMerkleRoot (
        uint256 _traitId,
        bytes32 _merkleRoot
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        _checkTraitId(_traitId);
        traitToInfo[_traitId].merkleRoot = _merkleRoot;
    }

    // Change existing trait name.
    /// @inheritdoc ISmolTraitShop
    function changeTraitName (
        uint256 _traitId,
        string calldata _name
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        _checkTraitId(_traitId);
        traitToInfo[_traitId].name = _name;
    }

    // Change existing trait price.
    /// @inheritdoc ISmolTraitShop
    function changeTraitPrice (
        uint256 _traitId,
        uint32 _price
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        _checkTraitId(_traitId);
        traitToInfo[_traitId].price = _price;
    }

    // Change max supply or remove supply cap for an existing trait. 
    /// @inheritdoc ISmolTraitShop
    function changeTraitSupply (
        uint256 _traitId,
        uint32 _maxSupply
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        _checkTraitId(_traitId);
        if (_maxSupply != 0) {
            if (_maxSupply < traitToInfo[_traitId].amountClaimed) revert InvalidTraitSupply();
            traitToInfo[_traitId].maxSupply = _maxSupply;
            traitToInfo[_traitId].uncappedSupply = false;
        }
        else {
            traitToInfo[_traitId].maxSupply = 0;
            traitToInfo[_traitId].uncappedSupply = true;
        }
    }

    // Change existing trait limited offer id reference. Changing this value will affect claimability per grouping as well as exclusive vs special claims.
    /// @inheritdoc ISmolTraitShop
    function changeTraitSpecialStatus (
        uint256 _traitId,
        uint32 _limitedOfferId,
        uint8 _subgroupId
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        if (_limitedOfferId > latestLimitedOffer) revert InvalidLimitedOfferId();
        _checkTraitId(_traitId);
        traitToInfo[_traitId].limitedOfferId = _limitedOfferId;
        traitToInfo[_traitId].subgroupId = _subgroupId;
    }

    // Change existing trait tradable status. Set as true to allow a trait to be tokenized and transfered.
    /// @inheritdoc ISmolTraitShop
    function changeTraitTradableStatus (
        uint256 _traitId,
        bool _tradable
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        _checkTraitId(_traitId);
        traitToInfo[_traitId].tradable = _tradable;
    }

    // Add special traits to a subgroup for specialEventClaim.
    /// @inheritdoc ISmolTraitShop
    function addTraitsToLimitedOfferGroup(
        uint256 _limitedOfferId,
        uint256 _subgroupId,
        uint256[] calldata _traitIds
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        if (_limitedOfferId > latestLimitedOffer) revert InvalidLimitedOfferId();
        uint256 length = _traitIds.length;
        for (uint256 i = 0; i < length; i++) {
            uint256 id = _traitIds[i];
            _checkTraitId(id);
            limitedOfferToGroupToIds[_limitedOfferId][_subgroupId].add(id);
        }
    }

    // Add special traits to a subgroup for specialEventClaim.
    /// @inheritdoc ISmolTraitShop
    function removeTraitsFromLimitedOfferGroup(
        uint256 _limitedOfferId,
        uint256 _subgroupId,
        uint256[] calldata _traitIds
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        uint256 length = _traitIds.length;
        for (uint256 i = 0; i < length; i++) {
            limitedOfferToGroupToIds[_limitedOfferId][_subgroupId].remove(_traitIds[i]);
        }
    }

    // Increment latestLimitedOfferId by one.
    /// @inheritdoc ISmolTraitShop
    function incrementLimitedOfferId() external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE){
        latestLimitedOffer ++;
    }

    // Withdraw all Magic.
    /// @inheritdoc ISmolTraitShop
    function withdrawMagic() external contractsAreSet requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        uint256 contractBalance = magicToken.balanceOf(address(this));
        magicToken.transfer(treasuryAddress, contractBalance);
    }

    // Returns base URI concatenated with trait ID + suffix.
    /// @inheritdoc ISmolTraitShop
    function traitURI(uint256 _traitId) public view returns (string memory) {
        _checkTraitId(_traitId);
        TraitType _traitType = _getTypeForTrait(_traitId);
        uint256 id = _traitId - (uint256(_traitType) * TRAIT_TYPE_OFFSET); 
        string memory URI = baseURI[_traitType];
        string memory suffix = suffixURI[_traitType];
        return bytes(URI).length > 0 ? string(abi.encodePacked(URI, id.toString(), suffix)) : "";
    } 

// -------------------------------------------------------------
//                   Internal Functions
// -------------------------------------------------------------

    /// @dev Adds trait id to sale array for that trait type.
    function _addTraitToSale (
        uint256 _traitId
    ) internal {
        traitIdsForSale.add(_traitId);
        emit TraitSaleStateChanged(
            _traitId, 
            true
        );
    }

    /// @dev Removes trait id from sale array for that trait type.
    function _removeTraitFromSale (
        uint256 _traitId
    ) internal {
        traitIdsForSale.remove(_traitId);
        emit TraitSaleStateChanged(
            _traitId, 
            false
        );
    }

    /// @dev Check to verify _traitId is within range of valid trait ids.
    function _checkTraitId (
        uint256 _traitId
    ) internal view {
        TraitType _traitType = _getTypeForTrait(_traitId);
        if (_traitId == 0 || traitTypeToLastId[_traitType] < _traitId - (uint256(_traitType) * TRAIT_TYPE_OFFSET)) revert TraitIdDoesNotExist(_traitId);
    }

    /// @dev Check to verify array lengths of input arrays are equal
    function _checkLengths(
        uint256 target,
        uint256 length
    ) internal pure {
        if (target != length) revert ArrayLengthMismatch();
    }

// -------------------------------------------------------------
//                 Essential Setter Functions
// -------------------------------------------------------------

    // Set necessary addresses.
    /// @inheritdoc ISmolTraitShop
    function setContracts(
        address _smolsAddressRegistry,
        address _magicToken,
        address _treasuryAddress
    ) external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        smolsAddressRegistry = ISmolsAddressRegistry(_smolsAddressRegistry);
        magicToken = IERC20Upgradeable(_magicToken);
        treasuryAddress = _treasuryAddress;
    }

// -------------------------------------------------------------
//                       Modifier
// -------------------------------------------------------------
    
    modifier contractsAreSet() {
        if(!areContractsSet()) revert ContractsAreNotSet();
        _;
    }

    /// @notice Verify necessary contract addresses have been set.
    function areContractsSet() public view returns(bool) {
        return address(smolsAddressRegistry) != address(0)
        && address(magicToken) != address(0)
        && address(treasuryAddress) != address(0);
    }

// -------------------------------------------------------------
//                       Initializer
// -------------------------------------------------------------

    function __SmolTraitShopAdmin_init() internal initializer {
        SmolTraitShopState.__SmolTraitShopState_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SmolTraitShopView.sol";

/// @title Smol Trait Shop Internal
/// @author Gearhart
/// @notice Internal functions used to purchase and equip traits for Smol Brains.

abstract contract SmolTraitShopInternal is Initializable, SmolTraitShopView {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // -------------------------------------------------------------
    //                   Buy Internal Functions
    // -------------------------------------------------------------

    /// @dev Used by all buy functions except for traits that require merkle proof verification.
    function _buy(
        address _userAddress,
        uint256 _smolId,
        uint256 _traitId
    ) internal {
        if (traitToInfo[_traitId].merkleRoot != bytes32(0)) revert MustCallBuyExclusiveTrait(_traitId);
        uint256 price_ = _checkBeforePurchase(_userAddress, _smolId, _traitId);
        _unlockTrait(_userAddress, price_, _smolId, _traitId);
    }

    /// @dev Used for buy/claim functions that require merkle proof verification. 
    function _buyMerkle(
        address _userAddress,
        bytes32[] calldata _proof,
        uint256 _smolId,
        uint256 _traitId,
        uint256 _limitedOfferId,
        uint256 _groupId
    ) internal {
        if (traitToInfo[_traitId].merkleRoot == bytes32(0)) revert MerkleRootNotSet();
        _checkWhitelistStatus(_userAddress, _proof, _traitId, _limitedOfferId, _groupId);
        uint256 price_ = _checkBeforePurchase(_userAddress, _smolId, _traitId);
        _unlockTrait(_userAddress, price_, _smolId, _traitId);
    }

    /// @dev Internal helper function that unlocks an upgrade for specified vehicle and emits UpgradeUnlocked event.
    function _unlockTrait(
        address _userAddress,
        uint256 _price,
        uint256 _smolId,
        uint256 _traitId
    ) internal {
        if (_price != 0){
            magicToken.transferFrom(_userAddress, address(this), _price);
        }
        traitToInfo[_traitId].amountClaimed ++;
        // If item is sold out; remove that item from sale.
        if (traitToInfo[_traitId].amountClaimed == traitToInfo[_traitId].maxSupply) {
            _removeTraitFromSale(_traitId);
            traitToInfo[_traitId].forSale = false;
        }
        traitIdsOwnedBySmol[_smolId].add(_traitId);
        emit TraitUnlocked(
            _smolId,
            _traitId
        );
    } 

    // -------------------------------------------------------------
    //                  Equip Internal Functions
    // -------------------------------------------------------------

    /// @dev Equip a set of unlocked traits for single Smol Brain.
    function _equipSet(
        address _userAddress,
        uint256 _smolId,
        SmolBrain calldata _traitsToEquip
    ) internal {
        _checkSmolOwnership(_userAddress, _smolId);

        address smolStateAddress = smolsAddressRegistry.getAddress(SmolAddressEnum.SMOLSSTATEADDRESS);
        ISmolsState smolState = ISmolsState(smolStateAddress);

        _checkBeforeEquip(_smolId, _traitsToEquip.background, TraitType.Background);
        smolState.setBackground(_smolId, uint24(_traitsToEquip.background));
        _checkBeforeEquip(_smolId, _traitsToEquip.body, TraitType.Body);
        smolState.setBody(_smolId, uint24(_traitsToEquip.body));
        _checkBeforeEquip(_smolId, _traitsToEquip.hair, TraitType.Hair);
        smolState.setHair(_smolId, uint24(_traitsToEquip.hair));
        _checkBeforeEquip(_smolId, _traitsToEquip.clothes, TraitType.Clothes);
        smolState.setClothes(_smolId, uint24(_traitsToEquip.clothes));
        _checkBeforeEquip(_smolId, _traitsToEquip.glasses, TraitType.Glasses);
        smolState.setGlasses(_smolId, uint24(_traitsToEquip.glasses));
        _checkBeforeEquip(_smolId, _traitsToEquip.hat, TraitType.Hat);
        smolState.setHat(_smolId, uint24(_traitsToEquip.hat));
        _checkBeforeEquip(_smolId, _traitsToEquip.mouth, TraitType.Mouth);
        smolState.setMouth(_smolId, uint24(_traitsToEquip.mouth));
        _checkBeforeEquip(_smolId, _traitsToEquip.costume, TraitType.Costume);
        smolState.setSkin(_smolId, uint24(_traitsToEquip.costume));
        
        emit UpdateSmolTraits(
            _smolId, 
            _traitsToEquip
        );
    }

    // -------------------------------------------------------------
    //                       Initializer
    // -------------------------------------------------------------

    function __SmolTraitShopInternal_init() internal initializer {
        SmolTraitShopView.__SmolTraitShopView_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../../shared/UtilitiesV2Upgradeable.sol";
import "./SmolsOnChain/ISmolsState.sol";
import "./SmolsOnChain/ISmolsAddressRegistry.sol";
import "./ISmolTraitShop.sol";

/// @title Smol Trait Shop State
/// @author Gearhart
/// @notice Shared storage layout for SmolTraitShop.

abstract contract SmolTraitShopState is Initializable, UtilitiesV2Upgradeable, ISmolTraitShop {

// -------------------------------------------------------------
//                   Mappings & Variables
// -------------------------------------------------------------
    uint256 internal constant TRAIT_LIMITED_OFFER_ID_BIT_OFFSET = 32;
    uint256 internal constant TRAIT_TRAIT_TYPE_BIT_OFFSET = 152;
    uint256 internal constant TRAIT_TYPE_OFFSET = 1_000_000;
    uint256 internal constant TRAIT_GROUP_ID_BIT_OFFSET = 160;

    IERC721 public smolBrains;
    IERC20Upgradeable public magicToken;

    // team wallet address for magic withdraw
    address public treasuryAddress;

// -------------------------------------------------------------
//                   Merkle Verifications
// -------------------------------------------------------------

    // mapping for keeping track of user WL allocation if merkleroot is assigned to a trait
    // user address => trait Id => WL spot claimed or not
    mapping (address => mapping(uint256 => bool)) 
        public userAllocationClaimed;

    // mapping for keeping track of user WL allocation if merkleroot is assigned to a limited offer
    // user address => special event id => sub group => WL spot claimed or not
    mapping (address => mapping (uint256 => mapping(uint256 => bool)))
        public userLimitedOfferAllocationClaimed;

    // smol brain id => special event id => sub group => WL spot claimed or not
    mapping (uint256 => mapping (uint256 => mapping(uint256 => bool)))
        public smolLimitedOfferAllocationClaimed;
    
    // -------------------------------------------------------------
    //                   Limited Offers
    // -------------------------------------------------------------

    // event number => subgroupId => ids of that are within that subgroup
    // Used to track the pool of available traits to choose from
    mapping (uint256 => mapping (uint256 => EnumerableSetUpgradeable.UintSet))
        internal limitedOfferToGroupToIds;

    // number for keeping track of current event and opening a new level of subgroups (without erasing the last) for special claim (when incremented)
    // used when creating a new special event
    uint256 public latestLimitedOffer;

    // -------------------------------------------------------------
    //                   TraitType Metadata
    // -------------------------------------------------------------
    

    // base URI for a specific trait type to be concatenated with trait ID + suffix
    mapping (TraitType => string)
        public baseURI;
    // suffix URI for a specific trait type to be concatenated with base + trait ID
    mapping (TraitType => string)
        public suffixURI;
    // highest id number currently in use for each trait type
    mapping (TraitType => uint256) 
        public traitTypeToLastId;

    // -------------------------------------------------------------
    //                   Trait Metadata
    // -------------------------------------------------------------

    // mapping that holds struct containing trait info by trait id
    // trait id => Trait struct 
    mapping (uint256 => Trait) 
        internal traitToInfo;

    // Set of all traits currently for sale
    EnumerableSetUpgradeable.UintSet internal traitIdsForSale;

    // -------------------------------------------------------------
    //                   SmolTrait Metadata
    // -------------------------------------------------------------

    // smol id => Enumerable Uint Set of all unlocked traits
    mapping (uint256 => EnumerableSetUpgradeable.UintSet)
        internal traitIdsOwnedBySmol;
    
    // mapping to struct holding ids of currently equiped traits for a given smol
    // smol id => SmolBrain struct
    // DEPRECIATED AND NO LONGER IN USE: STATE NOW STORED ON SMOLS ON CHAIN CONTRACT
    mapping (uint256 => SmolBrain) 
        internal smolToEquippedTraits;

    // -------------------------------------------------------------
    //                   State Added After Initial Deploy
    // -------------------------------------------------------------

    ISmolsAddressRegistry public smolsAddressRegistry;

    // -------------------------------------------------------------
    //                         Internal
    // -------------------------------------------------------------

    /* solhint-disable no-inline-assembly */
    function _getLimitedOfferIdAndGroupForTrait(uint256 _traitId) internal view returns(uint32 limitedOfferId_, uint8 groupId_){
        uint256 _mask32 = type(uint32).max;
        assembly {
            mstore(0, _traitId)
            mstore(32, traitToInfo.slot)
            let slot := keccak256(0, 64)

            let traitSlot1 := sload(slot)
            // Get the limitedOfferId from the Trait struct by offsetting the first 32 bits (amountClaimed value)
            // And only getting the first 32 bits of that part of the slot (for limitedOfferId)
            // shr will delete the least significant 32 bits of the slot data, which is the value of Trait.amountClaimed
            // and with the full value of a 32 bit uint will only save the data from the remaining slot that overlaps
            //  the mask with the actual stored value
            limitedOfferId_ := and(shr(TRAIT_LIMITED_OFFER_ID_BIT_OFFSET, traitSlot1), _mask32)
            groupId_ := and(shr(TRAIT_GROUP_ID_BIT_OFFSET, traitSlot1), _mask32)
        }
    }

    function _getTypeForTrait(uint256 _traitId) internal view returns(TraitType traitType_){
        uint256 _mask8 = type(uint8).max;
        uint8 traitAsUint;
        bytes32 traitSlot1;
        assembly {
            mstore(0, _traitId)
            mstore(32, traitToInfo.slot)
            let slot := keccak256(0, 64)

            traitSlot1 := sload(slot)
            // Get the limitedOfferId from the Trait struct by offsetting the first 32 bits (amountClaimed value)
            // And only getting the first 32 bits of that part of the slot (for limitedOfferId)
            // shr will delete the least significant 32 bits of the slot data, which is the value of Trait.amountClaimed
            // and with the full value of a 32 bit uint will only save the data from the remaining slot that overlaps
            //  the mask with the actual stored value
            traitAsUint := and(shr(TRAIT_TRAIT_TYPE_BIT_OFFSET, traitSlot1), _mask8)
        }
        traitType_ = TraitType(traitAsUint);
    }

    // -------------------------------------------------------------
    //                       Initializer
    // -------------------------------------------------------------

    function __SmolTraitShopState_init() internal initializer {
        UtilitiesV2Upgradeable.__Utilities_init();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./SmolTraitShopAdmin.sol";

/// @title Smol Trait Shop View Functions
/// @author Gearhart
/// @notice External and internal view functions used by SmolTraitShop.

abstract contract SmolTraitShopView is Initializable, SmolTraitShopAdmin {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // -------------------------------------------------------------
    //                  External View Functions
    // -------------------------------------------------------------

    // Get all info for a specific trait.
    /// @inheritdoc ISmolTraitShop
    function getTraitInfo(
        uint256 _traitId
    ) external view returns (Trait memory) {
        Trait memory trait = traitToInfo[_traitId];
        trait.uri = traitURI(_traitId);
        return trait;
    }

    // Get all trait ids for a trait type that are currently owned by selected smol.
    /// @inheritdoc ISmolTraitShop
    function getTraitsOwnedBySmol(
        uint256 _smolId
    ) external view returns (uint256[] memory) {
        return traitIdsOwnedBySmol[_smolId].values();
    }

    // Check to see if a specific trait id is unlocked for a given smol.
    /// @inheritdoc ISmolTraitShop
    function getTraitOwnershipBySmol( 
        uint256 _smolId,
        uint256 _traitId
    ) public view returns (bool isOwnedBySmol_) {
        isOwnedBySmol_ = traitIdsOwnedBySmol[_smolId].contains(_traitId);
    }

    // Get all trait ids of a specific trait type(0-7) that are currently for sale / available for claim.
    /// @inheritdoc ISmolTraitShop
    function getTraitsForSale(
        TraitType _traitType
    ) external view returns (uint256[] memory traitTypeForSale_) {
        uint256 forSaleAllLenth = traitIdsForSale.length();
        uint256 countForSaleByTrait;
        for (uint256 i = 0; i < forSaleAllLenth; i++) {
            if(!_isTraitInType(_traitType, traitIdsForSale.at(i))) {
                continue;
            }
            countForSaleByTrait++;
        }
        traitTypeForSale_ = new uint256[](countForSaleByTrait);
        uint256 traitCountCur;
        for (uint256 i = 0; i < forSaleAllLenth; i++) {
            if(!_isTraitInType(_traitType, traitIdsForSale.at(i))) {
                continue;
            }
            traitTypeForSale_[traitCountCur++] = traitIdsForSale.at(i);
        }
    }

    // Get trait ids that have been added to a specific subgroup for a given event number.
    /// @inheritdoc ISmolTraitShop
    function getSubgroupFromLimitedOfferId(
        uint256 _limitedOfferId,
        uint256 _subgroupId
    ) external view returns(uint256[] memory){
        return limitedOfferToGroupToIds[_limitedOfferId][_subgroupId].values();
    }

    // -------------------------------------------------------------
    //                  Internal View Functions
    // -------------------------------------------------------------

    /// @dev Various checks that must be made before any trait purchase.
    function _checkBeforePurchase(
        address _userAddress,
        uint256 _smolId,
        uint256 _traitId
    ) internal view returns(uint256 price_){
        _checkTraitId(_traitId);
        _checkSmolOwnership(_userAddress, _smolId);
        Trait memory trait = traitToInfo[_traitId];
        if (getTraitOwnershipBySmol(_smolId, _traitId)) revert TraitAlreadyUnlockedForSmol(_smolId, _traitId);
        if (!trait.forSale) revert TraitNotCurrentlyForSale(_traitId);
        if (!trait.uncappedSupply) {
            if (trait.amountClaimed + 1 > trait.maxSupply) revert TraitIdSoldOut(_traitId);
        }
        price_ = (uint256(trait.price) * 10**18);
        if (price_ != 0){
            _checkMagicBalance(_userAddress, price_);
        }
    }

    /// @dev Verify user is owner of smol.
    function _checkSmolOwnership(
        address _userAddress,
        uint256 _smolId
    ) internal view {
        address smolBrainsAddress = smolsAddressRegistry.getAddress(SmolAddressEnum.SMOLSADDRESS);
        if (IERC721(smolBrainsAddress).ownerOf(_smolId) != _userAddress) revert MustBeOwnerOfSmol();
    }

    /// @dev Check balance of magic for user.
    function _checkMagicBalance(
        address _userAddress,
        uint256 _amount
    ) internal view {
        uint256 bal = magicToken.balanceOf(_userAddress);
        if (bal < _amount) revert InsufficientBalance(bal, _amount);
    }

    /// @dev Verify merkle proof for user and check if allocation has been claimed.
    function _checkWhitelistStatus(
        address _userAddress,
        bytes32[] calldata _proof,
        uint256 _traitId,
        uint256 _limitedOfferId,
        uint256 _groupId
    ) internal view {
        bytes32 leaf = keccak256(abi.encodePacked(_userAddress, _limitedOfferId, _groupId));
        if (!MerkleProofUpgradeable.verify(_proof, traitToInfo[_traitId].merkleRoot, leaf)) revert InvalidMerkleProof();
    }

    /// @dev Check used for ownership when equipping upgrades.
    function _checkBeforeEquip (
        uint256 _smolId,
        uint256 _traitId,
        TraitType _expectedTraitType
    ) internal view {
        if (_traitId != 0) {
            if (!getTraitOwnershipBySmol(_smolId, _traitId)) revert TraitNotUnlockedForSmol(_smolId, _traitId);
            if (!_isTraitInType(_expectedTraitType, _traitId)) revert TraitNotOfRequiredType(_traitId, _expectedTraitType);
        }
    }

    /// @dev Checking that buyTrait, buyTraitBatch, and buyExclusiveTrait purchases are going through the correct function for that trait.
    function _checkPurchaseType (
        uint256 _traitId
    ) internal view {
        (uint32 _limitedOfferId, uint32 _subgroupId) = _getLimitedOfferIdAndGroupForTrait(_traitId);
        if (_limitedOfferId != 0) revert MustCallSpecialEventClaim(_traitId);
        if (_subgroupId != 0) revert MustCallGlobalClaim(_traitId);
    }

    // If the id is in a trait type that is not what we are looking for return false
    // ex: _traitType == _traitType.Clothes, skip when the id is < the first id in Clothes (1 * TRAIT_TYPE_OFFSET) or >= TraitType.Glasses
    function _isTraitInType(TraitType _traitType, uint256 _traitId) internal pure returns(bool isInType_) {
        uint256 nextTraitTypeOffset = (uint256(_traitType) + 1) * TRAIT_TYPE_OFFSET;
        // The value of the current trait type offset for id 1
        uint256 thisTraitTypeOffset = (uint256(_traitType)) * TRAIT_TYPE_OFFSET;
        isInType_ = _traitId < nextTraitTypeOffset && _traitId >= thisTraitTypeOffset;
    }

    // -------------------------------------------------------------
    //                       Initializer
    // -------------------------------------------------------------

    function __SmolTraitShopView_init() internal initializer {
        SmolTraitShopAdmin.__SmolTraitShopAdmin_init();
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

enum SmolAddressEnum {
    OLDSMOLSADDRESS,
    SMOLSADDRESS,

    SMOLSSTATEADDRESS,
    SCHOOLADDRESS,

    SMOLSTRAITSTORAGEADDRESS,

    SMOLSRENDERERADDRESS,
    TRANSFERBLOCKERADDRESS
}

interface ISmolsAddressRegistry{
    function getAddress(SmolAddressEnum) external view returns(address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SmolsLibrary.sol";

interface ISmolsState {
    function getSmol(uint256 tokenId) external view returns (Smol memory);

    function getInitialSmol(uint256 tokenId) external view returns (Smol memory);

    function setSmol(uint256 tokenId, Smol memory) external;

    function setInitialSmol(uint256 tokenId, Smol memory) external;

    function setBackground(uint256 _tokenId, uint24 _traitId) external;

    function setBody(uint256 _tokenId, uint24 _traitId) external;

    function setClothes(uint256 _tokenId, uint24 _traitId) external;

    function setMouth(uint256 _tokenId, uint24 _traitId) external;

    function setGlasses(uint256 _tokenId, uint24 _traitId) external;

    function setHat(uint256 _tokenId, uint24 _traitId) external;

    function setHair(uint256 _tokenId, uint24 _traitId) external;

    function setSkin(uint256 _tokenId, uint24 _traitId) external;

    function setGender(uint256 _tokenId, uint8 _gender) external;

    function setHeadSize(uint256 _tokenId, uint8 _headSize) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



struct PngImage {
    bytes male;
    bytes female;
}

struct Trait {
    uint8 gender;
    uint24 traitId;
    bytes traitName;
    bytes traitType;
    PngImage pngImage;
}

struct Smol {
    uint24 background;
    uint24 body;
    uint24 clothes;
    uint24 mouth;
    uint24 glasses;
    uint24 hat;
    uint24 hair;
    uint24 skin;
    uint8 gender;
    //0 - Unset
    //1 - Male
    //2 - Female
    uint8 headSize;
}



library SmolsLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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
}