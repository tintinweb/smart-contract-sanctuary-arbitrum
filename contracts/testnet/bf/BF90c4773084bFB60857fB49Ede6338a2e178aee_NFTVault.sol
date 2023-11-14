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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {StringSet} from "../data-structures/StringSet.sol";

/**
 * @notice A simple library to work with sets
 */
library SetHelper {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using StringSet for StringSet.Set;

    /**
     * @notice The function to insert an array of elements into the set
     * @param set the set to insert the elements into
     * @param array_ the elements to be inserted
     */
    function add(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    function add(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    function add(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the set
     * @param set the set to remove the elements from
     * @param array_ the elements to be removed
     */
    function remove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    function remove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    function remove(StringSet.Set storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice ## Usage example:
 *
 * ```
 * using StringSet for StringSet.Set;
 *
 * StringSet.Set internal set;
 * ```
 */
library StringSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    /**
     * @notice The function add value to set
     * @param set the set object
     * @param value_ the value to add
     */
    function add(Set storage set, string memory value_) internal returns (bool) {
        if (!contains(set, value_)) {
            set._values.push(value_);
            set._indexes[value_] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function remove value to set
     * @param set the set object
     * @param value_ the value to remove
     */
    function remove(Set storage set, string memory value_) internal returns (bool) {
        uint256 valueIndex_ = set._indexes[value_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                string memory lastValue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastValue_;
                set._indexes[lastValue_] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[value_];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice The function returns true if value in the set
     * @param set the set object
     * @param value_ the value to search in set
     * @return true if value is in the set, false otherwise
     */
    function contains(Set storage set, string memory value_) internal view returns (bool) {
        return set._indexes[value_] != 0;
    }

    /**
     * @notice The function returns length of set
     * @param set the set object
     * @return the the number of elements in the set
     */
    function length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @notice The function returns value from set by index
     * @param set the set object
     * @param index_ the index of slot in set
     * @return the value at index
     */
    function at(Set storage set, uint256 index_) internal view returns (string memory) {
        return set._values[index_];
    }

    /**
     * @notice The function that returns values the set stores, can be very expensive to call
     * @param set the set object
     * @return the memory array of values
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return set._values;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155 {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(
        uint256 id
    ) external view returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(
        address account
    ) external view returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

interface IERC677Receiver {
    function onTokenTransfer(
        address from_,
        uint256 amount_,
        bytes calldata data_
    ) external returns (bool success_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRandomNumberProvider {
    function requestRandomNumber() external returns (uint256 requestId);
    function requestRandomNumberWithCallback() external returns (uint256);
    function isRequestComplete(uint256 requestId) external view returns (bool isCompleted);
    function randomNumber(uint256 requestId) external view returns (uint256 randomNum);
    function setAuth(address user, bool grant) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRandomNumberRequester {
    function process(uint256 rand, uint256 requestId) external;
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

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

import "@solarity/solidity-lib/libs/arrays/SetHelper.sol";

import "../@galaxis/registries/contracts/CommunityRegistry.sol";

import "./interfaces/ICommunityVaultsRegistry.sol";
import "./interfaces/IGenericVault.sol";
import "../Traits/interfaces/IRegistryConsumer.sol";
import "../Traits/Implementers/Generic/GenericTrait.sol";

abstract contract GenericVault is IGenericVault, Initializable {
    using EnumerableSet for *;
    using SetHelper for *;

    bytes32 public constant VAULTS_REGISTRY_ADMIN = keccak256("VAULTS_REGISTRY_ADMIN");
    bytes32 public constant VAULTS_ADMIN = keccak256("VAULTS_ADMIN");
    bytes32 public constant TRAIT_CONSUMER = keccak256("TRAIT_CONSUMER");

    IRegistryConsumer public galaxisRegistry;
    CommunityRegistry public communityRegistry;

    ICommunityVaultsRegistry.VaultTypes public vaultType;

    EnumerableSet.AddressSet internal _receivablesWhitelist;
    EnumerableSet.UintSet internal _supportedRedeemModes;

    mapping (address => TokenTypes) internal _whitelistedTokensToTokenType;

    modifier onlyRole(bytes32 role_) {
        _checkRole(role_, msg.sender);
        _;
    }

    modifier onlyReceivablesWhitelist() {
        _checkReceivablesWhitelist(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __GenericVault_init(
        IRegistryConsumer galaxisRegistry_,
        CommunityRegistry communityRegistry_,
        ICommunityVaultsRegistry.VaultTypes vaultType_,
        ReceivablesWhitelistEntry[] calldata whitelistEntries_,
        RedeemModesUpdateEntry[] calldata redeemModesUpdateEntries_
    ) internal onlyInitializing {
        galaxisRegistry = galaxisRegistry_;
        communityRegistry = communityRegistry_;

        vaultType = vaultType_;

        _updateReceivablesWhitelist(whitelistEntries_);
        _updateRedeemModes(redeemModesUpdateEntries_);
    }

    function updateReceivablesWhitelist(
        ReceivablesWhitelistEntry[] calldata entriesToUpdate_
    ) external override onlyRole(VAULTS_REGISTRY_ADMIN) {
        _updateReceivablesWhitelist(entriesToUpdate_);
    }

    function updateSupportedRedeemModes(
        RedeemModesUpdateEntry[] calldata entriesToUpdate_
    ) external override onlyRole(VAULTS_REGISTRY_ADMIN) {
        _updateRedeemModes(entriesToUpdate_);
    }

    function withdraw(
        WithdrawParams memory withdrawParams_
    ) external virtual override onlyRole(VAULTS_ADMIN) {
        _withdraw(withdrawParams_);
    }

    function withdrawBatch(
        WithdrawParams[] memory withdrawParamsArr_
    ) external virtual override onlyRole(VAULTS_ADMIN) {
        for (uint256 i = 0; i < withdrawParamsArr_.length; i++) {
            _withdraw(withdrawParamsArr_[i]);
        }
    }

    function traitWithdraw(
        TraitWithdrawParams memory traitWithdrawParams_
    ) external onlyRole(TRAIT_CONSUMER) {
        _traitWithdraw(traitWithdrawParams_);
    }

    function getVaultInfo()
        external
        view
        override
        returns (
            uint32 communityId_,
            uint8 vaultType_,
            uint256 vaultTypeNonce_
        )
    {
        bytes memory data_ = new bytes(0x60);

        assembly {
            extcodecopy(address(), add(data_, 0x20), 0x2d, 0x60)
        }

        return abi.decode(data_, (uint32, uint8, uint256));
    }

    function getReceivablesWhitelist() external view returns (address[] memory) {
        return _receivablesWhitelist.values();
    }

    function getSupportedRedeemModes() external view returns (RedeemModes[] memory resultArr_) {
        resultArr_ = new RedeemModes[](_supportedRedeemModes.length());

        for (uint256 i = 0; i < resultArr_.length; i++) {
            resultArr_[i] = RedeemModes(_supportedRedeemModes.at(i));
        }
    }

    function getReceivablesWhitelistInfo()
        external
        view
        override
        returns (WhitelistedTokenInfo[] memory resultArr_)
    {
        address[] memory whitelistedTokensArr_ = _receivablesWhitelist.values();

        resultArr_ = new WhitelistedTokenInfo[](whitelistedTokensArr_.length);

        for (uint256 i = 0; i < whitelistedTokensArr_.length; i++) {
            resultArr_[i] = WhitelistedTokenInfo(
                whitelistedTokensArr_[i],
                _whitelistedTokensToTokenType[whitelistedTokensArr_[i]]
            );
        }
    }

    function getWhitelistedTokenType(address whitelistedToken_)
        external
        view
        override
        returns (TokenTypes)
    {
        return _whitelistedTokensToTokenType[whitelistedToken_];
    }

    function isInReceivablesWhitelist(address tokenAddr_) public view returns (bool) {
        return _receivablesWhitelist.contains(tokenAddr_);
    }

    function isRedeemModeSupported(RedeemModes redeemMode_) public view returns (bool) {
        return _supportedRedeemModes.contains(uint256(redeemMode_));
    }

    function _updateReceivablesWhitelist(
        ReceivablesWhitelistEntry[] calldata entriesToUpdate_
    ) internal {
        for (uint256 i = 0; i < entriesToUpdate_.length; i++) {
            ReceivablesWhitelistEntry calldata currentEntry_ = entriesToUpdate_[i];

            if (currentEntry_.isAdding) {
                _validateReceivablesWhitelistToken(ERC165(currentEntry_.tokenAddr), currentEntry_.tokenType);

                _receivablesWhitelist.add(currentEntry_.tokenAddr);
                _whitelistedTokensToTokenType[currentEntry_.tokenAddr] = currentEntry_.tokenType;
            } else {
                _receivablesWhitelist.remove(currentEntry_.tokenAddr);
                delete _whitelistedTokensToTokenType[currentEntry_.tokenAddr];
            }
        }
    }

    function _updateRedeemModes(
        RedeemModesUpdateEntry[] calldata entriesToUpdate_
    ) internal {
        for (uint256 i = 0; i < entriesToUpdate_.length; i++) {
            RedeemModesUpdateEntry calldata currentEntry_ = entriesToUpdate_[i];

            if (currentEntry_.isAdding) {
                _supportedRedeemModes.add(uint256(currentEntry_.redeemMode));
            } else {
                _supportedRedeemModes.remove(uint256(currentEntry_.redeemMode));
            }
        }
    }

    function _traitWithdraw(TraitWithdrawParams memory traitWithdrawParams_) internal virtual {
        if (traitWithdrawParams_.trait.status(traitWithdrawParams_.tokenId) != uint8(TraitStatus.ACTIVE)) {
            revert GenericVaultUnactiveTrait(address(traitWithdrawParams_.trait), traitWithdrawParams_.tokenId);
        }
    }

    function _withdraw(WithdrawParams memory withdrawParams_) internal virtual;

    function _checkSupportsInterface(address tokenAddr_, bytes4 interfaceId_) internal view {
        if (!IERC165(tokenAddr_).supportsInterface(interfaceId_)) {
            revert GenericVaultUnsupportedInterface(interfaceId_, tokenAddr_);
        }
    }

    function _checkReceivablesWhitelist(address tokenAddr_) internal view virtual {
        if (!isInReceivablesWhitelist(tokenAddr_)) {
            revert GenericVaultNotInAReceivablesWhitelist(tokenAddr_);
        }
    }

    function _onlySupportedRedeemMode(RedeemModes redeemMode_) internal view virtual {
        if (!isRedeemModeSupported(redeemMode_)) {
            revert GenericVaultUnsupportedRedeemMode(redeemMode_);
        }
    }

    function _checkRole(bytes32 role_, address userAddr_) internal view {
        if (!_hasRole(role_, userAddr_)) {
            revert GenericVaultUnauthorized(role_, userAddr_);
        }
    }

    function _hasRole(bytes32 roleKey_, address userAddr_) internal view returns (bool) {
        return communityRegistry.hasRole(roleKey_, userAddr_);
    }

    function _validateReceivablesWhitelistToken(IERC165 token_, TokenTypes tokenType_) internal view virtual;
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

//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import "../@galaxis/registries/contracts/CommunityRegistry.sol";

import "../Traits/interfaces/IERC1155Enumerable.sol";
import "../Traits/interfaces/IRegistryConsumer.sol";
import "../Traits/interfaces/IERC677Receiver.sol";
import "../Traits/interfaces/IRandomNumberProvider.sol";
import "../Traits/interfaces/IRandomNumberRequester.sol";
import "./interfaces/INFTVault.sol";
import "./interfaces/ICommunityVaultsRegistry.sol";

import "./GenericVault.sol";

contract NFTVault is
    INFTVault,
    IERC721Receiver,
    IRandomNumberRequester,
    GenericVault,
    ERC1155Receiver
{
    using EnumerableSet for *;
    using SetHelper for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    string public constant REGISTRY_KEY_RANDOM_CONTRACT = "RANDOMV2_SSP_TRAIT_DROPPER";

    IERC20 public GLXTokenContract;

    uint256 public override totalNFTVaultSupplyAmount;
    uint256 public override pendingNFTsAmount;

    BuyNftSettings internal _buyNFTSettings;

    mapping (uint256 => RandomRedeemData) internal _randomRedeemsData;
    mapping (bytes32 => EnumerableSet.UintSet) internal _accountsRequestIds;

    function __NFTVault_init(
        IRegistryConsumer galaxisRegistry_,
        CommunityRegistry communityRegistry_,
        BuyNftSettings calldata buyNFTSettings_,
        ReceivablesWhitelistEntry[] calldata whitelistEntries_,
        RedeemModesUpdateEntry[] calldata redeemModesUpdateEntries_
    ) external initializer {
        __GenericVault_init(
            galaxisRegistry_,
            communityRegistry_,
            ICommunityVaultsRegistry.VaultTypes.NFTVault,
            whitelistEntries_,
            redeemModesUpdateEntries_
        );

        GLXTokenContract = IERC20(galaxisRegistry.getRegistryAddress("GLX"));

        _validateBuyNftSettings(buyNFTSettings_);

        _buyNFTSettings = buyNFTSettings_;
    }

    function updateBuyNFTSettings(
        BuyNftSettings calldata newBuyNFTSettings_
    ) external override onlyRole(VAULTS_REGISTRY_ADMIN) {
        _validateBuyNftSettings(newBuyNFTSettings_);

        _buyNFTSettings = newBuyNFTSettings_;
    }

    function process(uint256 random_, uint256 requestId_) external {
        if (msg.sender != galaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)) {
            revert GenericVaultUnauthorized("", msg.sender);
        }

        RandomRedeemData storage _redeemData = _randomRedeemsData[requestId_];

        if (_redeemData.recipientAddr == address(0)) {
            revert NFTVaultInvalidRequestId(requestId_);
        }

        if (_redeemData.randomNumber != 0) {
            revert NFTVaultRequestIdHasAlreadyBeenProcessed(requestId_);
        }

        _changePendingNFTsAmount(1, false);

        if (_redeemData.luck > 0 && random_ % 100 <= _redeemData.luck) {
            _directSelectRedeem(DirectSelectData(_redeemData.recipientAddr, _redeemData.tokenInfo));
        } else {
            TokenInfo memory tokenInfo_ = _withdrawByRandomNumber(
                random_,
                _redeemData.recipientAddr
            );

            _redeemData.tokenInfo = tokenInfo_;
        }

        _redeemData.randomNumber = random_;
    }

    function buyTokens(bytes calldata userData_) external override {
        if (!_buyNFTSettings.isNFTBuyable) {
            revert NFTVaultUnableToBuyNFTs();
        }

        uint256 userBalance_ = GLXTokenContract.balanceOf(msg.sender);

        if (userBalance_ < _buyNFTSettings.buyNFTPrice) {
            revert NFTVaultNotEnoughTokensToBuy(userBalance_, _buyNFTSettings.buyNFTPrice);
        }

        GLXTokenContract.safeTransferFrom(msg.sender, address(this), _buyNFTSettings.buyNFTPrice);

        _buyToken(msg.sender, _buyNFTSettings.redeemMode, userData_);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    )
        public
        override
        onlyReceivablesWhitelist
        returns (bytes4)
    {
        _changeTotalNFTVaultSupplyAmount(1, true);

        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256 amount_,
        bytes memory
    )
        public
        override
        onlyReceivablesWhitelist
        returns (bytes4)
    {
        _changeTotalNFTVaultSupplyAmount(amount_, true);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory amounts_,
        bytes memory
    )
        public
        override
        onlyReceivablesWhitelist
        returns (bytes4)
    {
        uint256 amountToAdd_;

        for (uint256 i = 0; i < amounts_.length; i++) {
            amountToAdd_ += amounts_[i];
        }

        _changeTotalNFTVaultSupplyAmount(amountToAdd_, true);

        return this.onERC1155BatchReceived.selector;
    }

    function getBuyNftSettings() external view override returns (BuyNftSettings memory) {
        return _buyNFTSettings;
    }

    function getRandomRedeemData(uint256 requestId_) external view override returns (RandomRedeemData memory) {
        return _randomRedeemsData[requestId_];
    }

    function getLastRandomRequestIdForTrait(
        GenericTrait trait_,
        uint32 tokenId_
    ) external view override returns (uint256) {
        return _getLastRandomRequestForAccount(getTraitAccountKey(address(trait_), tokenId_));
    }

    function getLastRandomRequestIdForUser(
        address userAddr_
    ) external view override returns (uint256) {
        return _getLastRandomRequestForAccount(getAccountKey(userAddr_));
    }

    function getAllRandomRequestIdsForTrait(
        GenericTrait trait_,
        uint32 tokenId_
    ) external view override returns (uint256[] memory) {
        return _getAccountRequestIds(getTraitAccountKey(address(trait_), tokenId_));
    }

    function getAllRandomRequestIdsForUser(
        address userAddr_
    ) external view override returns (uint256[] memory) {
        return _getAccountRequestIds(getAccountKey(userAddr_));
    }

    function getTokenInfoForPseudoRandomForTrait(
        GenericTrait trait_,
        uint32 tokenId_
    ) external view override returns (TokenInfo memory) {
        uint256 pseudoRandomInterval_ = uint256(bytes32(
            trait_.getProperty("pseudo_random_interval", tokenId_)
        ));
        bytes32 accountSalt_ = keccak256(abi.encodePacked(tokenId_));

        return getTokenInfoByRandomNumber(_getPseudoRandomNumber(pseudoRandomInterval_, accountSalt_));
    }

    function getTokenInfoForPseudoRandomForBuy(
        address buyer_
    ) external view override returns (TokenInfo memory) {
        uint256 pseudoRandomInterval_ = abi.decode(_buyNFTSettings.specialRedeemData, (uint256));
        bytes32 accountSalt_ = keccak256(abi.encodePacked(buyer_));

        return getTokenInfoByRandomNumber(_getPseudoRandomNumber(pseudoRandomInterval_, accountSalt_));
    }

    function getTokenInfoByRandomNumber(uint256 randomNumber_) public view override returns (TokenInfo memory tokenInfo_) {
        uint256 freeNFTSupplyAmount_ = getFreeNFTSupplyAmount();

        if (freeNFTSupplyAmount_ == 0) {
            return tokenInfo_;
        }

        uint256 whitelistLength_ = _receivablesWhitelist.length();
        uint256 tokenPosition_ = randomNumber_ % freeNFTSupplyAmount_ + 1;

        for (uint256 i = 0; i < whitelistLength_; i++) {
            address currentTokenAddr_ = _receivablesWhitelist.at(i);
            TokenTypes currentTokenType_ = _whitelistedTokensToTokenType[currentTokenAddr_];

            if (currentTokenType_ == TokenTypes.ERC721) {
                uint256 tokenBalance_ = IERC721Enumerable(currentTokenAddr_).balanceOf(address(this));

                if (tokenBalance_ >= tokenPosition_) {
                    tokenInfo_ = TokenInfo(
                        currentTokenAddr_,
                        IERC721Enumerable(currentTokenAddr_).tokenOfOwnerByIndex(
                            address(this),
                            tokenPosition_ - 1
                        ),
                        currentTokenType_
                    );
                    break;
                } else {
                    tokenPosition_ -= tokenBalance_;
                }
            } else {
                IERC1155Enumerable currentToken_ = IERC1155Enumerable(currentTokenAddr_);
                uint256[] memory tokenIDs_ = currentToken_.tokensByAccount(address(this));

                for (uint256 j = 0; j < tokenIDs_.length; j++) {
                    uint256 tokenBalance_ = currentToken_.balanceOf(address(this), tokenIDs_[j]);

                    if (tokenBalance_ >= tokenPosition_) {
                        tokenInfo_ = TokenInfo(
                            currentTokenAddr_,
                            tokenIDs_[j],
                            currentTokenType_
                        );
                        break;
                    } else {
                        tokenPosition_ -= tokenBalance_;
                    }
                }
            }
        }
    }

    function getFreeNFTSupplyAmount() public view override returns (uint256) {
        return totalNFTVaultSupplyAmount - pendingNFTsAmount;
    }

    function getTraitAccountKey(address trait_, uint32 tokenId_) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(trait_, tokenId_));
    }

    function getAccountKey(address userAddr_) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(userAddr_));
    }

    // Buy Token function

    function _buyToken(
        address recipient_,
        RedeemModes buyRedeemMode_,
        bytes calldata userBuyData_
    ) internal {
        if (buyRedeemMode_ == RedeemModes.RANDOM_REDEEM) {
            uint256 luck_ = abi.decode(_buyNFTSettings.specialRedeemData, (uint256));
            TokenInfo memory tokenInfo_;

            if (luck_ > 0) {
                tokenInfo_ = abi.decode(userBuyData_, (TokenInfo));
            }

            _randomRedeem(
                getAccountKey(recipient_),
                recipient_,
                tokenInfo_,
                uint8(luck_)
            );
        } else if (buyRedeemMode_ == RedeemModes.SEQUENTIAL_REDEEM) {
            uint256 tokensToWithdraw_ = abi.decode(_buyNFTSettings.specialRedeemData, (uint256));

            _sequentialWithdraw(tokensToWithdraw_, recipient_);
        } else if (buyRedeemMode_ == RedeemModes.DIRECT_SELECT) {
            TokenInfo memory tokenInfo_ = abi.decode(userBuyData_, (TokenInfo));

            _directSelectRedeem(DirectSelectData(recipient_, tokenInfo_));
        } else if (buyRedeemMode_ == RedeemModes.DET_PSEUDO_RANDOM) {
            uint256 pseudoRandomInterval_ = abi.decode(_buyNFTSettings.specialRedeemData, (uint256));
            bytes32 accountKey_ = getAccountKey(recipient_);

            _detPseudoRandomRedeem(recipient_, pseudoRandomInterval_, accountKey_);
        } else {
            revert GenericVaultUnsupportedRedeemMode(buyRedeemMode_);
        }
    }

    // Trait withdraw functions

    function _traitWithdraw(
        TraitWithdrawParams memory traitWithdrawParams_
    ) internal virtual override {
        super._traitWithdraw(traitWithdrawParams_);

        RedeemModes redeemMode_ = RedeemModes(traitWithdrawParams_.trait.redeemMode());

        _onlySupportedRedeemMode(redeemMode_);

        if (redeemMode_ == RedeemModes.RANDOM_REDEEM) {
            _randomRedeemTrait(traitWithdrawParams_);
        } else if (redeemMode_ == RedeemModes.SEQUENTIAL_REDEEM) {
            _sequentialRedeemTrait(traitWithdrawParams_);
        } else if (redeemMode_ == RedeemModes.DIRECT_SELECT) {
            DirectSelectData memory directSelectData_ = abi.decode(
                traitWithdrawParams_.redeemData,
                (DirectSelectData)
            );

            _directSelectRedeem(directSelectData_);
        } else if (redeemMode_ == RedeemModes.DET_PSEUDO_RANDOM) {
            _detPseudoRandomRedeemTrait(traitWithdrawParams_);
        } else {
            revert GenericVaultUnsupportedRedeemMode(redeemMode_);
        }
    }

    function _randomRedeemTrait(
        TraitWithdrawParams memory traitWithdrawParams_
    ) internal {
        uint8 luck_ = uint8(uint256(bytes32(
            traitWithdrawParams_.trait.getProperty("luck", traitWithdrawParams_.tokenId)
        )));

        address recipient_;
        TokenInfo memory tokenInfo_;

        if (luck_ > 0) {
            (recipient_, tokenInfo_) = abi.decode(traitWithdrawParams_.redeemData, (address, TokenInfo));
        } else {
            recipient_ = abi.decode(traitWithdrawParams_.redeemData, (address));
        }

        _randomRedeem(
            getTraitAccountKey(address(traitWithdrawParams_.trait), traitWithdrawParams_.tokenId),
            recipient_,
            tokenInfo_,
            luck_
        );
    }

    function _sequentialRedeemTrait(
        TraitWithdrawParams memory traitWithdrawParams_
    ) internal {
        uint256 withdrawTokensCount_ = uint256(bytes32(
            traitWithdrawParams_.trait.getProperty("tokens_amount", traitWithdrawParams_.tokenId
        )));

        if (withdrawTokensCount_ == 0) {
            revert NFTVaultInvalidSequentialData();
        }

        address recipientAddr_ = abi.decode(traitWithdrawParams_.redeemData, (address));

        _sequentialWithdraw(
            withdrawTokensCount_,
            recipientAddr_
        );
    }

    function _detPseudoRandomRedeemTrait(
        TraitWithdrawParams memory traitWithdrawParams_
    ) internal {
        uint256 pseudoRandomInterval_ = uint256(bytes32(
            traitWithdrawParams_.trait.getProperty("pseudo_random_interval", traitWithdrawParams_.tokenId)
        ));
        address recipientAddr_ = abi.decode(traitWithdrawParams_.redeemData, (address));
        bytes32 traitAccountKey_ = getTraitAccountKey(address(traitWithdrawParams_.trait), traitWithdrawParams_.tokenId);

        _detPseudoRandomRedeem(recipientAddr_, pseudoRandomInterval_, traitAccountKey_);
    }

    // General withdraw functions

    function _randomRedeem(
        bytes32 accountKey_,
        address recipient_,
        TokenInfo memory tokenInfo_,
        uint8 luck_
    ) internal {
        if (recipient_ == address(0)) {
            revert NFTVaultZeroAddress();
        }

        uint256 requestId_ = IRandomNumberProvider(
            galaxisRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)
        ).requestRandomNumberWithCallback();

        RandomRedeemData storage _redeemData = _randomRedeemsData[requestId_];

        if (luck_ > 0) {
            _redeemData.recipientAddr = recipient_;
            _redeemData.tokenInfo = tokenInfo_;
            _redeemData.luck = luck_;
        } else {
            _redeemData.recipientAddr = recipient_;
        }

        _accountsRequestIds[accountKey_].add(requestId_);

        _changePendingNFTsAmount(1, true);
    }

    function _directSelectRedeem(
        DirectSelectData memory directSelectData_
    ) internal {
        IGenericVault.WithdrawParams memory withdrawParams_ = IGenericVault.WithdrawParams(
            directSelectData_.tokenInfo.tokenAddr,
            directSelectData_.recipient,
            directSelectData_.tokenInfo.tokenId,
            1,
            directSelectData_.tokenInfo.tokenType
        );

        _withdraw(withdrawParams_);
    }

    function _detPseudoRandomRedeem(
        address recipient_,
        uint256 pseudoRandomInterval_,
        bytes32 accountKey_
    ) internal {
        uint256 pseudoRandNumber_ = _getPseudoRandomNumber(pseudoRandomInterval_, accountKey_);

        _withdrawByRandomNumber(pseudoRandNumber_, recipient_);
    }

    function _getPseudoRandomNumber(
        uint256 pseudoRandomInterval_,
        bytes32 accountSalt_
    ) internal view returns (uint256) {
        if (pseudoRandomInterval_ == 0) {
            revert NFTVaultInvalidPseudoRandomInterval();
        }

        uint256 intervalSalt_ = uint256(keccak256(abi.encodePacked(block.timestamp / pseudoRandomInterval_)));

        return uint256(keccak256(abi.encodePacked(accountSalt_, intervalSalt_)));
    }

    function _withdrawByRandomNumber(
        uint256 randomNumber_,
        address tokenRecipient_
    ) internal returns (TokenInfo memory tokenInfo_) {
        if (getFreeNFTSupplyAmount() == 0) {
            revert NFTVaultInvalidTotalNFTSupplyAmount();
        }

        tokenInfo_ = getTokenInfoByRandomNumber(randomNumber_);

        _directSelectRedeem(DirectSelectData(tokenRecipient_, tokenInfo_));
    }

    function _sequentialWithdraw(
        uint256 withdrawTokensAmount_,
        address tokenRecipient_
    ) internal {
        uint256 freeNFTSupplyAmount_ = getFreeNFTSupplyAmount();

        if (freeNFTSupplyAmount_ == 0) {
            revert NFTVaultInvalidTotalNFTSupplyAmount();
        }

        withdrawTokensAmount_ = Math.min(withdrawTokensAmount_, freeNFTSupplyAmount_);

        uint256 whitelistLength_ = _receivablesWhitelist.length();

        for (uint256 i = 0; i < whitelistLength_; i++) {
            address currentTokenAddr_ = _receivablesWhitelist.at(i);
            TokenTypes currentTokenType_ = _whitelistedTokensToTokenType[currentTokenAddr_];

            if (currentTokenType_ == TokenTypes.ERC721) {
                uint256 tokenBalance_ = IERC721Enumerable(currentTokenAddr_).balanceOf(address(this));
                uint256 amountToWithdraw_ = Math.min(withdrawTokensAmount_, tokenBalance_);

                _sendERC721TokensBatch(IERC721Enumerable(currentTokenAddr_), tokenRecipient_, amountToWithdraw_);

                withdrawTokensAmount_ -= amountToWithdraw_;
            } else {
                IERC1155Enumerable currentToken_ = IERC1155Enumerable(currentTokenAddr_);

                uint256[] memory tokenIDs_ = currentToken_.tokensByAccount(address(this));

                for (uint256 j = 0; j < tokenIDs_.length; j++) {
                    uint256 tokenBalance_ = currentToken_.balanceOf(address(this), tokenIDs_[j]);
                    uint256 amountToWithdraw_ = Math.min(withdrawTokensAmount_, tokenBalance_);

                    WithdrawParams memory withdrawParams_ = WithdrawParams(
                        currentTokenAddr_,
                        tokenRecipient_,
                        tokenIDs_[j],
                        amountToWithdraw_,
                        currentTokenType_
                    );

                    _sendERC1155Tokens(withdrawParams_);

                    withdrawTokensAmount_ -= amountToWithdraw_;

                    if (withdrawTokensAmount_ == 0) {
                        break;
                    }
                }
            }

            if (withdrawTokensAmount_ == 0) {
                break;
            }
        }
    }

    // Simple withdraw and transfer functions

    function _withdraw(WithdrawParams memory withdrawParams_) internal virtual override {
        _checkReceivablesWhitelist(address(withdrawParams_.tokenAddr));

        if (withdrawParams_.tokenType == TokenTypes.ERC721) {
            _sendERC721Tokens(withdrawParams_);
        } else if (withdrawParams_.tokenType == TokenTypes.ERC1155) {
            _sendERC1155Tokens(withdrawParams_);
        } else {
            revert GenericVaultInvalidWithdrawType();
        }
    }
 
    function _sendERC721Tokens(WithdrawParams memory withdrawParams_) internal {
        IERC721(withdrawParams_.tokenAddr).safeTransferFrom(
            address(this),
            withdrawParams_.tokenRecipient,
            withdrawParams_.tokenId
        );

        _changeTotalNFTVaultSupplyAmount(1, false);
    }

    function _sendERC721TokensBatch(IERC721Enumerable nftToken_, address recipient_, uint256 tokensCountToSend_) internal {
        _checkReceivablesWhitelist(address(nftToken_));

        uint256 vaultBalance_ = nftToken_.balanceOf(address(this));

        tokensCountToSend_ = tokensCountToSend_ > vaultBalance_ ? vaultBalance_ : tokensCountToSend_;

        uint256[] memory ids_ = _getFirstTokenIdsByIndex(nftToken_, tokensCountToSend_);

        for (uint256 i = 0; i < tokensCountToSend_; i++) {
            nftToken_.safeTransferFrom(
                address(this),
                recipient_,
                ids_[i]
            );
        }

        _changeTotalNFTVaultSupplyAmount(tokensCountToSend_, false);
    }

    function _sendERC1155Tokens(WithdrawParams memory withdrawParams_) internal {
        IERC1155(withdrawParams_.tokenAddr).safeTransferFrom(
            address(this),
            withdrawParams_.tokenRecipient,
            withdrawParams_.tokenId,
            withdrawParams_.tokensAmount,
            ""
        );

        _changeTotalNFTVaultSupplyAmount(withdrawParams_.tokensAmount, false);
    }

    function _changeTotalNFTVaultSupplyAmount(uint256 amountToChange_, bool isAdding_) internal {
        totalNFTVaultSupplyAmount = _getNewSupplyAmount(totalNFTVaultSupplyAmount, amountToChange_, isAdding_);
    }

    function _changePendingNFTsAmount(uint256 amountToChange_, bool isAdding_) internal {
        pendingNFTsAmount = _getNewSupplyAmount(pendingNFTsAmount, amountToChange_, isAdding_);
    }

    // Validate functions

    function _validateReceivablesWhitelistToken(IERC165 token_, TokenTypes tokenType_) internal view override {
        if (tokenType_ != TokenTypes.ERC721 && tokenType_ != TokenTypes.ERC1155) {
            revert GenericVaultInvalidReceivablesWhitelistToken(address(token_));
        }

        if (!token_.supportsInterface(type(IERC721Enumerable).interfaceId) &&
            !token_.supportsInterface(type(IERC1155Enumerable).interfaceId)
        ) {
            revert GenericVaultInvalidReceivablesWhitelistToken(address(token_));
        }
    }

    function _validateBuyNftSettings(BuyNftSettings calldata buyNFTSettings_) internal view {
        _onlySupportedRedeemMode(buyNFTSettings_.redeemMode);

        uint256 redeemDataNumber_ = abi.decode(buyNFTSettings_.specialRedeemData, (uint256));

        if (
            (buyNFTSettings_.redeemMode == RedeemModes.SEQUENTIAL_REDEEM ||
            buyNFTSettings_.redeemMode == RedeemModes.DET_PSEUDO_RANDOM) &&
            redeemDataNumber_ == 0
        ) {
            revert NFTVaultInvalidSpecialRedeemData(
                buyNFTSettings_.redeemMode,
                buyNFTSettings_.specialRedeemData
            );
        } else if (
            buyNFTSettings_.redeemMode == RedeemModes.RANDOM_REDEEM &&
            redeemDataNumber_ > 100
        ) {
            revert NFTVaultInvalidSpecialRedeemData(
                buyNFTSettings_.redeemMode,
                buyNFTSettings_.specialRedeemData
            );
        }
    }

    // Helper functions

    function _getLastRandomRequestForAccount(
        bytes32 accountKey_
    ) internal view returns (uint256) {
        EnumerableSet.UintSet storage _accountRequsts = _accountsRequestIds[accountKey_];

        if (_accountRequsts.length() == 0) {
            return 0;
        }

        return _accountRequsts.at(_accountRequsts.length() - 1);
    }

    function _getAccountRequestIds(bytes32 accountKey_) internal view returns (uint256[] memory) {
        return _accountsRequestIds[accountKey_].values();
    }

    function _getFirstTokenIdsByIndex(IERC721Enumerable nftToken_, uint256 tokensAmount_) internal view returns (uint256[] memory ) {
        uint256[] memory ids_ = new uint256[](tokensAmount_);
        for (uint256 i = 0; i < tokensAmount_; i++) {
            ids_[i] = nftToken_.tokenOfOwnerByIndex(address(this), i);
        }
        return ids_;
    }
    
    function _getNewSupplyAmount(
        uint256 currentAmount_,
        uint256 amountToChange_,
        bool isAdding_
    ) internal pure returns (uint256) {
        if (isAdding_) {
            currentAmount_ += amountToChange_;
        } else {
            amountToChange_ = currentAmount_ >= amountToChange_ ? amountToChange_ : 0;

            currentAmount_ -= amountToChange_;
        }

        return currentAmount_;
    }
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