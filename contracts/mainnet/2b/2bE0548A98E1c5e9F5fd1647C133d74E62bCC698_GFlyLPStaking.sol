// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
                        StringsUpgradeable.toHexString(account),
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
interface IERC20PermitUpgradeable {
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
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
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

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

pragma solidity ^0.8.8;

/**
 * @title Map implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableMap {
    error EnumerableMap__IndexOutOfBounds();
    error EnumerableMap__NonExistentKey();

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        MapEntry[] _entries;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct AddressToAddressMap {
        Map _inner;
    }

    struct UintToAddressMap {
        Map _inner;
    }

    function at(AddressToAddressMap storage map, uint256 index)
        internal
        view
        returns (address, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);

        return (
            address(uint160(uint256(key))),
            address(uint160(uint256(value)))
        );
    }

    function at(UintToAddressMap storage map, uint256 index)
        internal
        view
        returns (uint256, address)
    {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    function contains(AddressToAddressMap storage map, address key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(uint256(uint160(key))));
    }

    function contains(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return _contains(map._inner, bytes32(key));
    }

    function length(AddressToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function length(UintToAddressMap storage map)
        internal
        view
        returns (uint256)
    {
        return _length(map._inner);
    }

    function get(AddressToAddressMap storage map, address key)
        internal
        view
        returns (address)
    {
        return
            address(
                uint160(
                    uint256(_get(map._inner, bytes32(uint256(uint160(key)))))
                )
            );
    }

    function get(UintToAddressMap storage map, uint256 key)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    function set(
        AddressToAddressMap storage map,
        address key,
        address value
    ) internal returns (bool) {
        return
            _set(
                map._inner,
                bytes32(uint256(uint160(key))),
                bytes32(uint256(uint160(value)))
            );
    }

    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    function remove(AddressToAddressMap storage map, address key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(uint256(uint160(key))));
    }

    function remove(UintToAddressMap storage map, uint256 key)
        internal
        returns (bool)
    {
        return _remove(map._inner, bytes32(key));
    }

    function toArray(AddressToAddressMap storage map)
        internal
        view
        returns (address[] memory keys, address[] memory values)
    {
        uint256 len = map._inner._entries.length;
        keys = new address[](len);
        values = new address[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                keys[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
                values[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function toArray(UintToAddressMap storage map)
        internal
        view
        returns (uint256[] memory keys, address[] memory values)
    {
        uint256 len = map._inner._entries.length;
        keys = new uint256[](len);
        values = new address[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                keys[i] = uint256(map._inner._entries[i]._key);
                values[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function keys(AddressToAddressMap storage map)
        internal
        view
        returns (address[] memory keys)
    {
        uint256 len = map._inner._entries.length;
        keys = new address[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keys[i] = address(
                    uint160(uint256(map._inner._entries[i]._key))
                );
            }
        }
    }

    function keys(UintToAddressMap storage map)
        internal
        view
        returns (uint256[] memory keys)
    {
        uint256 len = map._inner._entries.length;
        keys = new uint256[](len);

        unchecked {
            for (uint256 i; i < len; ++i) {
                keys[i] = uint256(map._inner._entries[i]._key);
            }
        }
    }

    function values(AddressToAddressMap storage map)
        internal
        view
        returns (address[] memory values)
    {
        uint256 len = map._inner._entries.length;
        values = new address[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                values[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function values(UintToAddressMap storage map)
        internal
        view
        returns (address[] memory values)
    {
        uint256 len = map._inner._entries.length;
        values = new address[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                values[i] = address(
                    uint160(uint256(map._inner._entries[i]._value))
                );
            }
        }
    }

    function _at(Map storage map, uint256 index)
        private
        view
        returns (bytes32, bytes32)
    {
        if (index >= map._entries.length)
            revert EnumerableMap__IndexOutOfBounds();

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    function _contains(Map storage map, bytes32 key)
        private
        view
        returns (bool)
    {
        return map._indexes[key] != 0;
    }

    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) revert EnumerableMap__NonExistentKey();
        unchecked {
            return map._entries[keyIndex - 1]._value;
        }
    }

    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            unchecked {
                map._entries[keyIndex - 1]._value = value;
            }
            return false;
        }
    }

    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            unchecked {
                MapEntry storage last = map._entries[map._entries.length - 1];

                // move last entry to now-vacant index
                map._entries[keyIndex - 1] = last;
                map._indexes[last._key] = keyIndex;
            }

            // clear last index
            map._entries.pop();
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = _length(set._inner);
        bytes32[] memory arr = new bytes32[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = _length(set._inner);
        address[] memory arr = new address[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 len = _length(set._inner);
        uint256[] memory arr = new uint256[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Receiver } from '../../../interfaces/IERC721Receiver.sol';
import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';
import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';
import { ERC721BaseStorage } from './ERC721BaseStorage.sol';

/**
 * @title Base ERC721 internal functions
 */
abstract contract ERC721BaseInternal is IERC721BaseInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;
    using AddressUtils for address;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using EnumerableSet for EnumerableSet.UintSet;

    function _balanceOf(address account)
        internal
        view
        virtual
        returns (uint256)
    {
        if (account == address(0)) revert ERC721Base__BalanceQueryZeroAddress();
        return ERC721BaseStorage.layout().holderTokens[account].length();
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = ERC721BaseStorage.layout().tokenOwners.get(tokenId);
        if (owner == address(0)) revert ERC721Base__InvalidOwner();
        return owner;
    }

    function _getApproved(uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        if (!l.exists(tokenId)) revert ERC721Base__NonExistentToken();

        return l.tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address account, address operator)
        internal
        view
        virtual
        returns (bool)
    {
        return ERC721BaseStorage.layout().operatorApprovals[account][operator];
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        if (!ERC721BaseStorage.layout().exists(tokenId))
            revert ERC721Base__NonExistentToken();

        address owner = _ownerOf(tokenId);

        return (spender == owner ||
            _getApproved(tokenId) == spender ||
            _isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ERC721Base__MintToZeroAddress();

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();

        if (l.exists(tokenId)) revert ERC721Base__TokenAlreadyMinted();

        _beforeTokenTransfer(address(0), to, tokenId);

        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[owner].remove(tokenId);
        l.tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (_ownerOf(tokenId) != from) revert ERC721Base__NotTokenOwner();
        if (to == address(0)) revert ERC721Base__TransferToZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        ERC721BaseStorage.Layout storage l = ERC721BaseStorage.layout();
        l.holderTokens[from].remove(tokenId);
        l.holderTokens[to].add(tokenId);
        l.tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721Base__ERC721ReceiverNotImplemented();
    }

    function _approve(address operator, uint256 tokenId) internal virtual {
        ERC721BaseStorage.layout().tokenApprovals[tokenId] = operator;
        emit Approval(_ownerOf(tokenId), operator, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        bytes memory returnData = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                msg.sender,
                from,
                tokenId,
                data
            ),
            'ERC721: transfer to non ERC721Receiver implementer'
        );

        bytes4 returnValue = abi.decode(returnData, (bytes4));
        return returnValue == type(IERC721Receiver).interfaceId;
    }

    /**
     * @notice ERC721 hook, called before externally called approvals for processing of included message value
     * @param operator beneficiary of approval
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleApproveMessageValue(
        address operator,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before externally called transfers for processing of included message value
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     * @param value message value
     */
    function _handleTransferMessageValue(
        address from,
        address to,
        uint256 tokenId,
        uint256 value
    ) internal virtual {}

    /**
     * @notice ERC721 hook, called before all transfers including mint and burn
     * @dev function should be overridden and new implementation must call super
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId id of transferred token
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { EnumerableMap } from '../../../data/EnumerableMap.sol';
import { EnumerableSet } from '../../../data/EnumerableSet.sol';

library ERC721BaseStorage {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Base');

    struct Layout {
        EnumerableMap.UintToAddressMap tokenOwners;
        mapping(address => EnumerableSet.UintSet) holderTokens;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(Layout storage l, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return l.tokenOwners.contains(tokenId);
    }

    function totalSupply(Layout storage l) internal view returns (uint256) {
        return l.tokenOwners.length();
    }

    function tokenOfOwnerByIndex(
        Layout storage l,
        address owner,
        uint256 index
    ) internal view returns (uint256) {
        return l.holderTokens[owner].at(index);
    }

    function tokenByIndex(Layout storage l, uint256 index)
        internal
        view
        returns (uint256)
    {
        (uint256 tokenId, ) = l.tokenOwners.at(index);
        return tokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721BaseInternal, IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721BaseInternal is IERC721Internal {
    error ERC721Base__NotOwnerOrApproved();
    error ERC721Base__SelfApproval();
    error ERC721Base__BalanceQueryZeroAddress();
    error ERC721Base__ERC721ReceiverNotImplemented();
    error ERC721Base__InvalidOwner();
    error ERC721Base__MintToZeroAddress();
    error ERC721Base__NonExistentToken();
    error ERC721Base__NotTokenOwner();
    error ERC721Base__TokenAlreadyMinted();
    error ERC721Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ERC721BaseStorage } from '../base/ERC721BaseStorage.sol';

abstract contract ERC721EnumerableInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    /**
     * @notice TODO
     */
    function _totalSupply() internal view returns (uint256) {
        return ERC721BaseStorage.layout().totalSupply();
    }

    /**
     * @notice TODO
     */
    function _tokenOfOwnerByIndex(address owner, uint256 index)
        internal
        view
        returns (uint256)
    {
        return ERC721BaseStorage.layout().tokenOfOwnerByIndex(owner, index);
    }

    /**
     * @notice TODO
     */
    function _tokenByIndex(uint256 index) internal view returns (uint256) {
        return ERC721BaseStorage.layout().tokenByIndex(index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(uint256 index)
        external
        view
        returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Base } from './base/IERC721Base.sol';
import { IERC721Enumerable } from './enumerable/IERC721Enumerable.sol';
import { IERC721Metadata } from './metadata/IERC721Metadata.sol';

interface ISolidStateERC721 is IERC721Base, IERC721Enumerable, IERC721Metadata {
    error SolidStateERC721__PayableApproveNotSupported();
    error SolidStateERC721__PayableTransferNotSupported();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ERC721MetadataStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC721Metadata');

    struct Layout {
        string name;
        string symbol;
        string baseURI;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721MetadataInternal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721BaseInternal } from '../base/IERC721BaseInternal.sol';

/**
 * @title ERC721Metadata internal interface
 */
interface IERC721MetadataInternal is IERC721BaseInternal {
    error ERC721Metadata__NonExistentToken();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x4) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IAtlasMine.sol";
import "./interfaces/IBattleflyAtlasStakerV02.sol";
import "./interfaces/IVault.sol";
import "./libraries/BattleflyAtlasStakerUtils.sol";
import "./interfaces/vaults/IBattleflyTreasuryFlywheelVault.sol";
import "./interfaces/IBattleflyHarvesterEmissions.sol";
import "./interfaces/IFlywheelEmissions.sol";

/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract BattleflyAtlasStakerV02 is
    IBattleflyAtlasStakerV02,
    Initializable,
    OwnableUpgradeable,
    ERC1155HolderUpgradeable,
    ERC721HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using AddressUpgradeable for address;
    using SafeCastUpgradeable for uint256;
    using SafeCastUpgradeable for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // ========== CONSTANTS ==========

    uint96 public constant override FEE_DENOMINATOR = 10000;
    uint256 public constant ONE = 1e28;
    address public BATTLEFLY_BOT;

    IERC20Upgradeable public override MAGIC;
    IAtlasMine public ATLAS_MINE;
    IBattleflyTreasuryFlywheelVault public TREASURY_VAULT;

    IAtlasMine.Lock[] public LOCKS;
    IAtlasMine.Lock[] public allowedLocks;

    // ========== Operator States ==========
    uint256 public override currentDepositId;
    uint64 public override currentEpoch;
    uint256 public override pausedUntil;
    uint256 public nextExecution;

    /**
     * @dev active positionIds in AtlasMine for this contract.
     *
     */
    EnumerableSetUpgradeable.UintSet private activePositionIds;

    /**
     * @dev Total emissions harvested from Atlas Mine for a particular lock period and epoch
     *      { lock } => { epoch } => { emissions }
     */
    mapping(IAtlasMine.Lock => mapping(uint64 => uint256)) public totalEmissionsAtEpochForLock;

    /**
     * @dev Total amount of magic staked in Atlas Mine for a particular lock period and epoch
     *      { lock } => { epoch } => { magic }
     */
    mapping(IAtlasMine.Lock => mapping(uint64 => uint256)) public override totalStakedAtEpochForLock;

    /**
     * @dev Total amount of emissions per share in magic for a particular lock period and epoch
     *      { lock } => { epoch } => { emissionsPerShare }
     */
    mapping(IAtlasMine.Lock => mapping(uint64 => uint256)) public override totalPerShareAtEpochForLock;

    /**
     * @dev Total amount of unstaked Magic at a particular epoch
     *      { epoch } => { unstaked magic }
     */
    mapping(uint64 => uint256) public unstakeAmountAtEpoch;

    /**
     * @dev Legion ERC721 NFT stakers data
     *      { tokenId } => { depositor }
     */
    mapping(uint256 => address) public legionStakers;

    /**
     * @dev TREASURE ERC1155 NFT stakers data
     *      { tokenId } => { depositor } => { deposit amount }
     */
    mapping(uint256 => mapping(address => uint256)) public treasureStakers;

    /**
     * @dev Vaultstakes per depositId
     *      { depositId } => { VaultStake }
     */
    mapping(uint256 => VaultStake) public vaultStakes;

    /**
     * @dev Vaults' all deposits
     *      { address } => { depositId }
     */
    mapping(address => EnumerableSetUpgradeable.UintSet) private depositIdByVault;

    /**
     * @dev Magic amount that is not staked to AtlasMine
     *      { Lock } => { unstaked amount }
     */
    mapping(IAtlasMine.Lock => uint256) public unstakedAmount;

    // ========== Access Control States ==========
    mapping(address => bool) public superAdmins;

    /**
     * @dev Whitelisted vaults
     *      { vault address } => { Vault }
     */
    mapping(address => Vault) public vaults;

    // ========== CONTRACT UPGRADE FOR BATCHED HARVESTING (ArbGas limit) ======= //

    uint256 public accruedEpochEmission;
    EnumerableSetUpgradeable.UintSet private atlasPositionsToRemove;

    // ========== CONTRACT UPGRADE FOR HARVESTER EMISSIONS ======= //

    IBattleflyHarvesterEmissions public HARVESTER_EMISSION;

    // ========== CONTRACT UPGRADE FOR GFLY DYNAMICS ======= //

    uint64 public override transitionEpoch;
    IFlywheelEmissions public FLYWHEEL_EMISSIONS;

    // ========== CONTRACT UPGRADE FOR FLYWHEEL 3.0 MIGRATION ======= //

    uint256 public withdrawnForMigration;
    uint256 public constant TOTAL_MAGIC_FOR_MIGRATION = 3178561320000000000000000;

    // Disable initializer to save contract space

    /* function initialize(
        address _magic,
        address _atlasMine,
        address _treasury,
        address _battleflyBot,
        IAtlasMine.Lock[] memory _allowedLocks
    ) external initializer {
        __ERC1155Holder_init();
        __ERC721Holder_init();
        __Ownable_init();
        __ReentrancyGuard_init();

        require(_magic != address(0), "BattleflyAtlasStaker: invalid address");
        require(_atlasMine != address(0), "BattleflyAtlasStaker: invalid address");
        MAGIC = IERC20Upgradeable(_magic);
        ATLAS_MINE = IAtlasMine(_atlasMine);

        superAdmins[msg.sender] = true;
        LOCKS = [
            IAtlasMine.Lock.twoWeeks,
            IAtlasMine.Lock.oneMonth,
            IAtlasMine.Lock.threeMonths,
            IAtlasMine.Lock.sixMonths,
            IAtlasMine.Lock.twelveMonths
        ];

        nextExecution = block.timestamp;

        setTreasury(_treasury);
        setBattleflyBot(_battleflyBot);
        setAllowedLocks(_allowedLocks);

        approveLegion(true);
        approveTreasure(true);
    }*/

    // ============================== Vault Operations ==============================

    /**
     * @dev deposit an amount of MAGIC in the AtlasStaker for a particular lock period
     */
    function deposit(
        uint256 _amount,
        IAtlasMine.Lock _lock
    ) external override onlyWhitelistedVaults nonReentrant whenNotPaused onlyAvailableLock(_lock) returns (uint256) {
        require(_amount > 0, "BattflyAtlasStaker: cannot deposit 0");
        // Transfer MAGIC from Vault
        MAGIC.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 newDepositId = ++currentDepositId;
        _deposit(newDepositId, _amount, _lock);
        return newDepositId;
    }

    /**
     * @dev withdraw a vaultstake from the AtlasStaker with a specific depositId
     */
    function withdraw(uint256 _depositId) public override nonReentrant whenNotPaused returns (uint256 amount) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        require(vaultStake.vault == msg.sender, "BattleflyAtlasStaker: caller is not a correct vault");
        // withdraw can only happen if the retention period has passed.
        require(canWithdraw(_depositId), "BattleflyAtlasStaker: position is locked");

        amount = vaultStake.amount;
        // Withdraw MAGIC to user
        MAGIC.safeTransfer(msg.sender, amount);

        // claim remaining emissions
        (uint256 emission, ) = getClaimableEmission(_depositId);
        if (emission > 0) {
            amount += _claim(_depositId);
        }

        // Reset vault stake data
        delete vaultStakes[_depositId];
        depositIdByVault[msg.sender].remove(_depositId);
        emit WithdrawPosition(msg.sender, amount, _depositId);
    }

    /**
     * @dev Claim emissions from a vaultstake in the AtlasStaker with a specific depositId
     */
    function claim(uint256 _depositId) public override nonReentrant whenNotPaused returns (uint256 amount) {
        amount = _claim(_depositId);
    }

    /**
     * @dev Request a withdrawal for a specific depositId. This is required because the vaultStake will be restaked in blocks of 2 weeks after the unlock period has passed.
     * This function is used to notify the AtlasStaker that it should not restake the vaultStake on the next iteration and the initial stake becomes unlocked.
     */
    function requestWithdrawal(uint256 _depositId) public override nonReentrant whenNotPaused returns (uint64) {
        VaultStake storage vaultStake = vaultStakes[_depositId];
        require(vaultStake.vault == msg.sender, "BattleflyAtlasStaker: caller is not a correct vault");
        require(vaultStake.retentionUnlock == 0, "BattleflyAtlasStaker: withdrawal already requested");
        // Every epoch is 1 day; We can start requesting for a withdrawal 14 days before the unlock period.
        require(currentEpoch >= (vaultStake.unlockAt - 14), "BattleflyAtlasStaker: position not yet unlockable");

        // We set the retention period before the withdrawal can happen to the nearest epoch in the future
        uint64 retentionUnlock = currentEpoch < vaultStake.unlockAt
            ? vaultStake.unlockAt
            : currentEpoch + (14 - ((currentEpoch - vaultStake.unlockAt) % 14));
        vaultStake.retentionUnlock = retentionUnlock - 1 == currentEpoch ? retentionUnlock + 14 : retentionUnlock;
        unstakeAmountAtEpoch[vaultStake.retentionUnlock - 1] += vaultStake.amount;
        emit RequestWithdrawal(msg.sender, vaultStake.retentionUnlock, _depositId);
        return vaultStake.retentionUnlock;
    }

    // ============================== Super Admin Operations ==============================

    /**
     * @dev Execute the daily cron job to deposit funds to AtlasMine & claim emissions from AtlasMine
     *      The Battlefly CRON BOT will use this function to execute deposit/claim.
     */
    function startHarvestAndDistribute() external onlyBattleflyBot {
        //require(block.timestamp >= nextExecution, "BattleflyAtlasStaker: Executed less than 24h ago");
        // set to 24 hours - 5 minutes to take blockchain tx delays into account.
        nextExecution = block.timestamp + 86100;
        accruedEpochEmission = 0;
    }

    /**
     * @dev Execute the daily cron job to harvest all emissions from AtlasMine
     */
    function executeHarvestAll(uint256 _position, uint256 _batchSize) external onlyBattleflyBot {
        uint256 endPosition = activePositionIds.length() < (_position + _batchSize)
            ? activePositionIds.length()
            : (_position + _batchSize);
        uint256 pendingHarvest = _updateEmissionsForEpoch(_position, endPosition);
        uint256 preHarvest = MAGIC.balanceOf(address(this));
        for (uint256 i = _position; i < endPosition; i++) {
            ATLAS_MINE.harvestPosition(activePositionIds.at(i));
        }
        uint256 harvested = MAGIC.balanceOf(address(this)) - preHarvest;
        require(pendingHarvest == harvested, "BattleflyAtlasStaker: pending harvest and actual harvest are not equal");
        if (currentEpoch >= transitionEpoch) {
            MAGIC.safeApprove(address(FLYWHEEL_EMISSIONS), harvested);
            FLYWHEEL_EMISSIONS.topupFlywheelEmissions(harvested);
        }
    }

    /**
     * @dev Execute the daily cron job to update emissions
     */
    function executeUpdateEmissions() external onlyBattleflyBot {
        // Calculate the accrued emissions per share by (accruedEmissionForLock * 1e18) / totalStaked
        // Set the total emissions to the accrued emissions of the current epoch + the previous epochs
        for (uint256 k = 0; k < LOCKS.length; k++) {
            uint256 totalStaked = totalStakedAtEpochForLock[LOCKS[k]][currentEpoch];
            if (totalStaked > 0 && currentEpoch < transitionEpoch) {
                uint256 accruedEmissionForLock = currentEpoch > 0
                    ? totalEmissionsAtEpochForLock[LOCKS[k]][currentEpoch] -
                        totalEmissionsAtEpochForLock[LOCKS[k]][currentEpoch - 1]
                    : 0;
                uint256 accruedRewardsPerShare = (accruedEmissionForLock * ONE) / totalStaked;
                totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch] = currentEpoch > 0
                    ? totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch - 1] + accruedRewardsPerShare
                    : accruedRewardsPerShare;
            } else {
                totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch] = currentEpoch > 0
                    ? totalPerShareAtEpochForLock[LOCKS[k]][currentEpoch - 1]
                    : 0;
            }
        }
    }

    /**
     * @dev Execute the daily cron job to withdraw all positions from AtlasMine
     */
    function executeWithdrawAll(uint256 _position, uint256 _batchSize) external onlyBattleflyBot {
        uint256[] memory depositIds = activePositionIds.values();
        uint256 endPosition = depositIds.length < (_position + _batchSize)
            ? depositIds.length
            : (_position + _batchSize);
        for (uint256 i = _position; i < endPosition; i++) {
            (uint256 amount, , , uint256 lockedUntil, , , IAtlasMine.Lock lock) = ATLAS_MINE.userInfo(
                address(this),
                depositIds[i]
            );
            uint256 totalLockedPeriod = lockedUntil + ATLAS_MINE.getVestingTime(lock);

            // If the position is available to withdraw
            if (totalLockedPeriod <= block.timestamp) {
                ATLAS_MINE.withdrawPosition(depositIds[i], type(uint256).max);
                atlasPositionsToRemove.add(depositIds[i]);
                // Directly register for restaking, unless a withdrawal is requested (we correct this in executeDepositAll())
                unstakedAmount[IAtlasMine.Lock.twoWeeks] += uint256(amount);
            }
        }
    }

    /**
     * @dev Execute the daily cron job to deposit all to AtlasMine
     */
    function executeDepositAll() external onlyBattleflyBot {
        // Increment the epoch
        currentEpoch++;
        // Possibly correct the amount to be deposited due to users withdrawing their stake.
        if (unstakedAmount[IAtlasMine.Lock.twoWeeks] >= unstakeAmountAtEpoch[currentEpoch]) {
            unstakedAmount[IAtlasMine.Lock.twoWeeks] -= unstakeAmountAtEpoch[currentEpoch];
        } else {
            //If not enough withdrawals available from current epoch, request more from the next epoch
            unstakeAmountAtEpoch[currentEpoch + 1] += (unstakeAmountAtEpoch[currentEpoch] -
                unstakedAmount[IAtlasMine.Lock.twoWeeks]);
            unstakedAmount[IAtlasMine.Lock.twoWeeks] = 0;
        }

        uint256 unstaked;
        // Disable deposits to AtlasMine to get everything liquid to migrate to flywheel 3.0
        /*  for (uint256 i = 0; i < LOCKS.length; i++) {
            uint256 amount = unstakedAmount[LOCKS[i]];
            if (amount > 0) {
                unstaked += amount;
                MAGIC.safeApprove(address(ATLAS_MINE), amount);
                ATLAS_MINE.deposit(amount, LOCKS[i]);
                activePositionIds.add(ATLAS_MINE.currentId(address(this)));
                unstakedAmount[LOCKS[i]] = 0;
            }
        }*/
        emit DepositedAllToMine(unstaked);
    }

    /**
     * @dev Finish the daily cron job to deposit funds to AtlasMine & claim emissions from AtlasMine
     *      The Battlefly CRON BOT will use this function to execute deposit/claim.
     */
    function finishHarvestAndDistribute() external onlyBattleflyBot {
        uint256[] memory toRemove = atlasPositionsToRemove.values();
        for (uint256 i = 0; i < toRemove.length; i++) {
            activePositionIds.remove(toRemove[i]);
            atlasPositionsToRemove.remove(toRemove[i]);
        }
    }

    /**
     * @dev
     * Withdraw the liquid amount for the migration once available and transfer to owner (from where it will be distributed)
     */
    function withdrawLiquidAmountForMigration(uint256 amount) external override onlyOwner {
        require(unstakedAmount[IAtlasMine.Lock.twoWeeks] >= amount, "BattleflyAtlasStaker: Not enough liquid amount");
        require(
            amount + withdrawnForMigration <= TOTAL_MAGIC_FOR_MIGRATION,
            "BattleflyAtlasStaker: Amount execeeds amount withdrawable for migration"
        );
        withdrawnForMigration += amount;
        unstakedAmount[IAtlasMine.Lock.twoWeeks] -= amount;
        MAGIC.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev
     * Deposit liquid amount of magic into this contract.
     */
    function depositLiquidAmount(uint256 amount) external override {
        unstakedAmount[IAtlasMine.Lock.twoWeeks] += amount;
        MAGIC.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Approve TREASURE ERC1155 NFT transfer to deposit into AtlasMine contract
     */
    function approveTreasure(bool _approve) public onlySuperAdmin {
        getTREASURE().setApprovalForAll(address(ATLAS_MINE), _approve);
    }

    /**
     * @dev Approve LEGION ERC721 NFT transfer to deposit into AtlasMine contract
     */
    function approveLegion(bool _approve) public onlySuperAdmin {
        getLEGION().setApprovalForAll(address(ATLAS_MINE), _approve);
    }

    /**
     * @dev Stake TREASURE ERC1155 NFT
     */
    /*function stakeTreasure(uint256 _tokenId, uint256 _amount) external onlySuperAdmin nonReentrant {
        require(_amount > 0, "BattleflyAtlasStaker: Invalid TREASURE amount");

        // Caller's balance check already implemented in _safeTransferFrom() in ERC1155Upgradeable contract
        getTREASURE().safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        treasureStakers[_tokenId][msg.sender] += _amount;

        // Token Approval is already done in constructor
        ATLAS_MINE.stakeTreasure(_tokenId, _amount);
        emit StakedTreasure(msg.sender, _tokenId, _amount);
    }*/

    /**
     * @dev Unstake TREASURE ERC1155 NFT
     */
    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external onlySuperAdmin nonReentrant {
        require(_amount > 0, "BattleflyAtlasStaker: Invalid TREASURE amount");
        require(treasureStakers[_tokenId][msg.sender] >= _amount, "BattleflyAtlasStaker: Invalid TREASURE amount");
        // Unstake TREASURE from AtlasMine
        ATLAS_MINE.unstakeTreasure(_tokenId, _amount);

        // Transfer TREASURE to the staker
        getTREASURE().safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
        treasureStakers[_tokenId][msg.sender] -= _amount;
        emit UnstakedTreasure(msg.sender, _tokenId, _amount);
    }

    /**
     * @dev Stake LEGION ERC721 NFT
     */
    /*  function stakeLegion(uint256 _tokenId) external onlySuperAdmin nonReentrant {
        // TokenId ownership validation is already implemented in safeTransferFrom function
        getLEGION().safeTransferFrom(msg.sender, address(this), _tokenId, "");
        legionStakers[_tokenId] = msg.sender;

        // Token Approval is already done in constructor
        ATLAS_MINE.stakeLegion(_tokenId);
        emit StakedLegion(msg.sender, _tokenId);
    }*/

    /**
     * @dev Unstake LEGION ERC721 NFT
     */
    function unstakeLegion(uint256 _tokenId) external onlySuperAdmin nonReentrant {
        require(legionStakers[_tokenId] == msg.sender, "BattleflyAtlasStaker: Invalid staker");
        // Unstake LEGION from AtlasMine
        ATLAS_MINE.unstakeLegion(_tokenId);

        // Transfer LEGION to the staker
        getLEGION().safeTransferFrom(address(this), msg.sender, _tokenId, "");
        legionStakers[_tokenId] = address(0);
        emit UnstakedLegion(msg.sender, _tokenId);
    }

    // ============================== Owner Operations ==============================

    /**
     * @dev Add super admin permission
     */
    function addSuperAdmin(address _admin) public onlyOwner {
        require(!superAdmins[_admin], "BattleflyAtlasStaker: admin already exists");
        superAdmins[_admin] = true;
        emit AddedSuperAdmin(_admin);
    }

    /**
     * @dev Batch adding super admin permission
     */
    function addSuperAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            addSuperAdmin(_admins[i]);
        }
    }

    /**
     * @dev Remove super admin permission
     */
    function removeSuperAdmin(address _admin) public onlyOwner {
        require(superAdmins[_admin], "BattleflyAtlasStaker: admin does not exist");
        superAdmins[_admin] = false;
        emit RemovedSuperAdmin(_admin);
    }

    /**
     * @dev Batch removing super admin permission
     */
    function removeSuperAdmins(address[] calldata _admins) external onlyOwner {
        for (uint256 i = 0; i < _admins.length; i++) {
            removeSuperAdmin(_admins[i]);
        }
    }

    /**
     * @dev Add vault address
     */
    function addVault(address _vault, Vault calldata _vaultData) public onlyOwner {
        require(!vaults[_vault].enabled, "BattleflyAtlasStaker: vault is already added");
        require(_vaultData.fee + _vaultData.claimRate == FEE_DENOMINATOR, "BattleflyAtlasStaker: invalid vault info");

        Vault storage vault = vaults[_vault];
        vault.fee = _vaultData.fee;
        vault.claimRate = _vaultData.claimRate;
        vault.enabled = true;
        emit AddedVault(_vault, vault.fee, vault.claimRate);
    }

    /**
     * @dev Remove vault address
     */
    function removeVault(address _vault) public onlyOwner {
        Vault storage vault = vaults[_vault];
        require(vault.enabled, "BattleflyAtlasStaker: vault does not exist");
        vault.enabled = false;
        emit RemovedVault(_vault);
    }

    /**
     * @dev Set allowed locks
     */
    function setAllowedLocks(IAtlasMine.Lock[] memory _locks) public onlyOwner {
        allowedLocks = _locks;
    }

    /**
     * @dev Set treasury wallet address
     */
    /* function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "BattleflyAtlasStaker: invalid address");
        TREASURY_VAULT = IBattleflyTreasuryFlywheelVault(_treasury);
        emit SetTreasury(_treasury);
    }*/

    /**
     * @dev Set daily bot address
     */
    function setBattleflyBot(address _battleflyBot) public onlyOwner {
        require(_battleflyBot != address(0), "BattleflyAtlasStaker: invalid address");
        BATTLEFLY_BOT = _battleflyBot;
        emit SetBattleflyBot(_battleflyBot);
    }

    function setPause(bool _paused) external override onlyOwner {
        pausedUntil = _paused ? block.timestamp + 48 hours : 0;
        emit SetPause(_paused);
    }

    /**
     * @dev Set harvester emissions contract
     */
    /* function setHarvesterEmission(address _harvesterEmission) public onlyOwner {
        require(_harvesterEmission != address(0), "BattleflyAtlasStaker: invalid address");
        HARVESTER_EMISSION = IBattleflyHarvesterEmissions(_harvesterEmission);
    }*/

    /**
     * @dev Set Flywheel emissions contract
     */
    function setFlywheelEmissions(address flywheelEmissions_) public onlyOwner {
        require(flywheelEmissions_ != address(0), "BattleflyAtlasStaker: invalid address");
        FLYWHEEL_EMISSIONS = IFlywheelEmissions(flywheelEmissions_);
    }

    /**
     * @dev Set transition epoch
     */
    function setTransitionEpoch(uint64 transitionEpoch_) public onlyOwner {
        require(transitionEpoch_ >= currentEpoch, "BattleflyAtlasStaker: invalid transition epoch");
        transitionEpoch = transitionEpoch_;
    }

    /**
     * @dev Set vault details
     */
    function setVault(address _vault, uint16 _fee, uint16 _claimRate, bool _enabled) public onlyOwner {
        require(_vault != address(0), "BattleflyAtlasStaker: invalid address");
        vaults[_vault].fee = _fee;
        vaults[_vault].claimRate = _claimRate;
        vaults[_vault].enabled = _enabled;
    }

    // ============================== VIEW ==============================

    /**
     * @dev Validate the lock period
     */
    function isValidLock(IAtlasMine.Lock _lock) public view returns (bool) {
        for (uint256 i = 0; i < allowedLocks.length; i++) {
            if (allowedLocks[i] == _lock) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Get AtlasMine TREASURE ERC1155 NFT address
     */
    function getTREASURE() public view returns (IERC1155Upgradeable) {
        return IERC1155Upgradeable(ATLAS_MINE.treasure());
    }

    /**
     * @dev Get AtlasMine LEGION ERC721 NFT address
     */
    function getLEGION() public view returns (IERC721Upgradeable) {
        return IERC721Upgradeable(ATLAS_MINE.legion());
    }

    /**
     * @dev Get Unstaked MAGIC amount
     */
    function getUnstakedAmount() public view returns (uint256 amount) {
        IAtlasMine.Lock[] memory locks = LOCKS;
        for (uint256 i = 0; i < locks.length; i++) {
            amount += unstakedAmount[locks[i]];
        }
    }

    /**
     * @dev Get claimable MAGIC emission.
     * Emissions are:
     *      Emissions from normal lock period +
     *      Emissions from retention period -
     *      Already received emissions
     */
    function getClaimableEmission(uint256 _depositId) public view override returns (uint256 emission, uint256 fee) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        if (currentEpoch > 0) {
            uint64 retentionLock = vaultStake.retentionUnlock == 0 ? currentEpoch + 1 : vaultStake.retentionUnlock - 1;
            uint64 x = vaultStake.retentionUnlock == 0 || vaultStake.retentionUnlock != vaultStake.unlockAt ? 0 : 1;
            uint256 totalEmission = _getEmissionsForPeriod(
                vaultStake.amount,
                vaultStake.lockAt,
                vaultStake.unlockAt - x,
                vaultStake.lock
            ) + _getEmissionsForPeriod(vaultStake.amount, vaultStake.unlockAt, retentionLock, vaultStake.lock);
            emission = totalEmission >= vaultStake.paidEmission ? totalEmission - vaultStake.paidEmission : 0;
        }
        Vault memory vault = vaults[vaultStake.vault];
        fee = (emission * vault.fee) / FEE_DENOMINATOR;
        emission -= fee;
    }

    /**
     * @dev Get total claimable MAGIC emission.
     * This includes atlasmine and harvester emissions
     */
    function getTotalClaimableEmission(
        uint256 _depositId
    ) public view override returns (uint256 emission, uint256 fee) {
        (uint256 emissionAtlas, uint256 feeAtlas) = getClaimableEmission(_depositId);
        (uint256 emissionHarvester, uint256 feeHarvester) = HARVESTER_EMISSION.getClaimableEmission(_depositId);
        emission = emissionAtlas + emissionHarvester;
        fee = feeAtlas + feeHarvester;
    }

    /**
     * @dev Get staked amount
     */
    function getDepositedAmount(uint256[] memory _depositIds) public view returns (uint256 amount) {
        for (uint256 i = 0; i < _depositIds.length; i++) {
            amount += vaultStakes[_depositIds[i]].amount;
        }
    }

    /**
     * @dev Get allowed locks
     */
    function getAllowedLocks() public view override returns (IAtlasMine.Lock[] memory) {
        return allowedLocks;
    }

    /**
     * @dev Get vault staked data
     */
    function getVaultStake(uint256 _depositId) public view override returns (VaultStake memory) {
        return vaultStakes[_depositId];
    }

    /**
     * @dev Gets the lock period in epochs
     */
    function getLockPeriod(IAtlasMine.Lock _lock) external view override returns (uint64 epoch) {
        return BattleflyAtlasStakerUtils.getLockPeriod(_lock, ATLAS_MINE) / 1 days;
    }

    /**
     * @dev Check if a vaultStake can be withdrawn
     */
    function canWithdraw(uint256 _depositId) public view override returns (bool withdrawable) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        withdrawable = (vaultStake.retentionUnlock > 0) && (vaultStake.retentionUnlock <= currentEpoch);
    }

    /**
     * @dev Check if a vaultStake can request a withdrawal
     */
    function canRequestWithdrawal(uint256 _depositId) public view override returns (bool requestable) {
        VaultStake memory vaultStake = vaultStakes[_depositId];
        requestable = (vaultStake.retentionUnlock == 0) && (currentEpoch >= (vaultStake.unlockAt - 14));
    }

    /**
     * @dev Get the depositIds of a user
     */
    function depositIdsOfVault(address vault) public view override returns (uint256[] memory depositIds) {
        return depositIdByVault[vault].values();
    }

    /**
     * @dev Get the number of active AtlasMine positions
     */
    function activeAtlasPositionSize() public view override returns (uint256) {
        return activePositionIds.length();
    }

    /**
     * @dev Get the a vault object belonging to a vault address
     */
    function getVault(address _vault) public view override returns (Vault memory) {
        return vaults[_vault];
    }

    /**
     * @dev Get APY for epoch
     */
    function getApyAtEpochIn1000(uint64 epoch) public view override returns (uint256) {
        if (epoch == 0) {
            return 0;
        }
        uint256 totalPerShare = totalPerShareAtEpochForLock[IAtlasMine.Lock.twoWeeks][epoch] -
            totalPerShareAtEpochForLock[IAtlasMine.Lock.twoWeeks][epoch - 1];
        return ((totalPerShare * 365 * 100 * 1000) / 1e28) + HARVESTER_EMISSION.getApyAtEpochIn1000(epoch);
    }

    /**
     * @dev Get active atlasmine position IDs
     */
    function getActivePositionIds() public view override returns (uint256[] memory) {
        return activePositionIds.values();
    }

    // ============================== Internal ==============================

    /**
     * @dev recalculate and update the emissions per share per lock period and per epoch
     *      1 share is 1 wei of Magic.
     */
    function _updateEmissionsForEpoch(uint256 position, uint256 endPosition) private returns (uint256 totalEmission) {
        uint256[] memory positionIds = activePositionIds.values();

        // Total emissions of the current epoch are at least as much as the total emissions of the previous epoch
        if (position == 0) {
            for (uint256 i = 0; i < LOCKS.length; i++) {
                totalEmissionsAtEpochForLock[LOCKS[i]][currentEpoch] = currentEpoch > 0
                    ? totalEmissionsAtEpochForLock[LOCKS[i]][currentEpoch - 1]
                    : 0;
            }
        }

        // Calculate the total amount of pending emissions and the total deposited amount for each lock period in the current epoch
        for (uint256 j = position; j < endPosition; j++) {
            uint256 pendingRewards = ATLAS_MINE.pendingRewardsPosition(address(this), positionIds[j]);
            (, uint256 currentAmount, , , , , IAtlasMine.Lock _lock) = ATLAS_MINE.userInfo(
                address(this),
                positionIds[j]
            );
            totalEmission += pendingRewards;
            accruedEpochEmission += pendingRewards;
            totalEmissionsAtEpochForLock[_lock][currentEpoch] += pendingRewards;
            totalStakedAtEpochForLock[_lock][currentEpoch] += currentAmount;
        }
    }

    /**
     * @dev get the total amount of emissions of a certain period between two epochs.
     */
    function _getEmissionsForPeriod(
        uint256 amount,
        uint64 startEpoch,
        uint64 stopEpoch,
        IAtlasMine.Lock lock
    ) private view returns (uint256 emissions) {
        if (stopEpoch >= startEpoch && currentEpoch >= startEpoch) {
            uint256 totalEmissions = (amount * totalPerShareAtEpochForLock[lock][currentEpoch - 1]);
            uint256 emissionsTillExclusion = (amount * totalPerShareAtEpochForLock[lock][stopEpoch - 1]);
            uint256 emissionsTillInclusion = (amount * totalPerShareAtEpochForLock[lock][startEpoch - 1]);
            uint256 emissionsFromExclusion = emissionsTillExclusion > 0 ? (totalEmissions - emissionsTillExclusion) : 0;
            emissions = (totalEmissions - emissionsFromExclusion - emissionsTillInclusion) / ONE;
        }
    }

    /**
     * @dev Deposit MAGIC to AtlasMine
     */
    function _deposit(uint256 _depositId, uint256 _amount, IAtlasMine.Lock _lock) private returns (uint256) {
        // We only deposit to AtlasMine in the next epoch. We can unlock after the lock period has passed.
        uint64 lockAt = currentEpoch + 1;
        uint64 unlockAt = currentEpoch + 1 + (BattleflyAtlasStakerUtils.getLockPeriod(_lock, ATLAS_MINE) / 1 days);

        vaultStakes[_depositId] = VaultStake(lockAt, unlockAt, 0, _amount, 0, msg.sender, _lock);
        // Updated unstaked MAGIC amount
        unstakedAmount[_lock] += _amount;
        depositIdByVault[msg.sender].add(_depositId);
        emit NewDeposit(msg.sender, _amount, unlockAt, _depositId);
        return unlockAt;
    }

    /**
     * @dev Claim emissions for a depositId
     */
    function _claim(uint256 _depositId) internal returns (uint256) {
        VaultStake storage vaultStake = vaultStakes[_depositId];
        require(vaultStake.vault == msg.sender, "BattleflyAtlasStaker: caller is not a correct vault");
        uint256 harvesterClaim = HARVESTER_EMISSION.claim(_depositId);
        (uint256 emission, uint256 fee) = getClaimableEmission(_depositId);
        if (emission > 0) {
            MAGIC.safeTransfer(msg.sender, emission);
            if (fee > 0) {
                MAGIC.approve(address(TREASURY_VAULT), fee);
                TREASURY_VAULT.topupMagic(fee);
            }
            uint256 amount = emission + fee;
            vaultStake.paidEmission += amount;
            emit ClaimEmission(msg.sender, emission + harvesterClaim, _depositId);
        }
        emission += harvesterClaim;
        return emission;
    }

    // ============================== Modifiers ==============================

    modifier onlySuperAdmin() {
        require(superAdmins[msg.sender], "BattleflyAtlasStaker: caller is not a super admin");
        _;
    }

    modifier onlyWhitelistedVaults() {
        require(vaults[msg.sender].enabled, "BattleflyAtlasStaker: caller is not whitelisted");
        _;
    }

    modifier onlyAvailableLock(IAtlasMine.Lock _lock) {
        require(isValidLock(_lock), "BattleflyAtlasStaker: invalid lock period");
        _;
    }

    modifier onlyBattleflyBot() {
        require(msg.sender == BATTLEFLY_BOT, "BattleflyAtlasStaker: caller is not a battlefly bot");
        _;
    }

    modifier whenNotPaused() {
        require(block.timestamp > pausedUntil, "BattleflyAtlasStaker: contract paused");
        _;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/IBattlefly.sol";
import "./interfaces/ISpecialNFT.sol";
import "./interfaces/IItem.sol";
import "./wastelands/interfaces/IWastelands.sol";

contract BattleflyGameV2 is OwnableUpgradeable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    mapping(address => bool) private adminAccess;
    IBattlefly private BattleflyContract;
    ISpecialNFT private SpecialNFTContract;
    IERC20Upgradeable private MagicToken;
    IItem private ItemContract;

    mapping(uint256 => bool) public ProcessedTransactions;
    uint8 constant TRANSACTION_TYPE_WITHDRAW_BATTLEFLY = 0;
    uint8 constant TRANSACTION_TYPE_WITHDRAW_MAGIC = 1;
    uint8 constant TRANSACTION_TYPE_WITHDRAW_ITEM = 2;

    event DepositBattlefly(uint256 indexed tokenId, address indexed user, uint256 timestamp);
    event WithdrawBattlefly(uint256 indexed tokenId, address indexed receiver, uint256 timestamp);

    event DepositItems(uint256 indexed tokenId, address indexed user, uint256 amount, uint256 timestamp);
    event WithdrawItems(uint256 indexed tokenId, address indexed receiver, uint256 amount, uint256 timestamp);

    event DepositMagic(uint256 amount, address indexed user, uint256 timestamp);
    event WithdrawMagic(uint256 amount, address indexed receiver, uint256 timestamp, uint256 walletTransactionId);

    event MintBattlefly(address indexed receiver, uint256 tokenId, uint256 battleflyType);
    event MintBattleflies(address[] receivers, uint256[] tokenIds, uint256[] battleflyTypes);

    event MintSpecialNFT(address indexed receiver, uint256 tokenId, uint256 specialNFTType);
    event MintSpecialNFTs(address[] receivers, uint256[] tokenIds, uint256[] specialNFTTypes);

    event SetAdminAccess(address indexed user, bool access);
    event MintItems(uint256 indexed itemId, address indexed receiver, uint256 amount);

    mapping(address => uint256) public usersLastWithdrawal;

    // Upgrade for Wastelands rewards

    IWastelands public WASTELANDS;

    event WastelandsRewardsToppedUp(address indexed user, uint256 amount);

    function initialize(
        address battleflyContractAddress,
        address specialNFTContractAddress,
        address magicTokenAddress
    ) public initializer {
        __Ownable_init();
        BattleflyContract = IBattlefly(battleflyContractAddress);
        SpecialNFTContract = ISpecialNFT(specialNFTContractAddress);
        MagicToken = IERC20Upgradeable(magicTokenAddress);
    }

    function initializeUpgrade(address itemContractAddress) external onlyOwner {
        ItemContract = IItem(itemContractAddress);
    }

    function setMagic(address magicAddress) external onlyOwner {
        MagicToken = IERC20Upgradeable(magicAddress);
    }

    function getBattlefliesOfOwner(address user) external view returns (uint256[] memory) {
        uint256 balance = BattleflyContract.balanceOf(user);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = BattleflyContract.tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    function getSpecialNFTsOfOwner(address user) external view returns (uint256[] memory) {
        uint256 balance = SpecialNFTContract.balanceOf(user);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = SpecialNFTContract.tokenOfOwnerByIndex(user, i);
        }
        return tokenIds;
    }

    // ADMIN
    function setAdminAccess(address user, bool access) external onlyOwner {
        adminAccess[user] = access;
        emit SetAdminAccess(user, access);
    }

    function mintSpecialNFT(address receiver, uint256 specialNFTType) external onlyAdminAccess returns (uint256) {
        uint256 tokenId = SpecialNFTContract.mintSpecialNFT(receiver, specialNFTType);
        emit MintSpecialNFT(receiver, tokenId, specialNFTType);
        return tokenId;
    }

    function mintSpecialNFTs(
        address receiver,
        uint256 specialNFTType,
        uint256 amount
    ) external onlyAdminAccess returns (uint256[] memory) {
        uint256[] memory tokenIds = SpecialNFTContract.mintSpecialNFTs(receiver, specialNFTType, amount);
        for (uint256 i = 0; i < amount; i++) {
            emit MintSpecialNFT(receiver, tokenIds[i], specialNFTType);
        }
        return tokenIds;
    }

    function mintItems(uint256 itemId, address receiver, uint256 amount) external onlyAdminAccess {
        ItemContract.mintItems(itemId, receiver, amount, "");
        emit MintItems(itemId, receiver, amount);
    }

    function mintBattlefly(address receiver, uint256 battleflyType) external onlyAdminAccess returns (uint256) {
        uint256 tokenId = BattleflyContract.mintBattlefly(receiver, battleflyType);
        emit MintBattlefly(receiver, tokenId, battleflyType);
        return tokenId;
    }

    function mintBattleflies(
        address receiver,
        uint256 battleflyType,
        uint256 amount
    ) external onlyAdminAccess returns (uint256[] memory) {
        uint256[] memory tokenIds = BattleflyContract.mintBattleflies(receiver, battleflyType, amount);
        for (uint256 i = 0; i < amount; i++) {
            emit MintBattlefly(receiver, tokenIds[i], battleflyType);
        }
        return tokenIds;
    }

    // Battlefly
    function bulkDepositBattlefly(uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            depositBattlefly(tokenIds[i]);
        }
    }

    function depositBattlefly(uint256 tokenId) public {
        BattleflyContract.safeTransferFrom(_msgSender(), address(this), tokenId);
        emit DepositBattlefly(tokenId, _msgSender(), block.timestamp);
    }

    function withdrawBattlefly(uint256 tokenId, address receiver) external onlyAdminAccess {
        BattleflyContract.safeTransferFrom(address(this), receiver, tokenId);
        emit WithdrawBattlefly(tokenId, receiver, block.timestamp);
    }

    function claimWithdrawBattleflies(
        uint256[] memory tokenIds,
        uint256 transactionId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(ProcessedTransactions[transactionId] == false, "Transaction have been processed");
        ProcessedTransactions[transactionId] = true;
        bytes32 payloadHash = keccak256(
            abi.encodePacked(_msgSender(), tokenIds, transactionId, TRANSACTION_TYPE_WITHDRAW_BATTLEFLY)
        );
        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        (address admin, ECDSAUpgradeable.RecoverError result) = ECDSAUpgradeable.tryRecover(messageHash, v, r, s);
        require(result == ECDSAUpgradeable.RecoverError.NoError && adminAccess[admin], "Require admin access");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            BattleflyContract.safeTransferFrom(address(this), _msgSender(), tokenIds[i]);
            emit WithdrawBattlefly(tokenIds[i], _msgSender(), block.timestamp);
        }
    }

    //Magic token
    function depositMagic(uint256 amount) external {
        MagicToken.safeTransferFrom(_msgSender(), address(this), amount);
        emit DepositMagic(amount, _msgSender(), block.timestamp);
    }

    function claimWithdrawMagic(
        uint256 amount,
        uint256 transactionId,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(ProcessedTransactions[transactionId] == false, "Transaction has already been processed");
        ProcessedTransactions[transactionId] = true;

        bytes32 payloadHash = keccak256(
            abi.encodePacked(_msgSender(), amount, transactionId, expiry, TRANSACTION_TYPE_WITHDRAW_MAGIC)
        );

        require(block.timestamp > usersLastWithdrawal[_msgSender()] + 15 minutes, "Withdrawal cooldown");
        require(block.timestamp < expiry, "Withdrawal expired");

        bytes32 messageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));

        (address admin, ECDSAUpgradeable.RecoverError result) = ECDSAUpgradeable.tryRecover(messageHash, v, r, s);

        require(
            result == ECDSAUpgradeable.RecoverError.NoError && adminAccess[admin],
            "Signature not generated by admin or other signature error"
        );

        MagicToken.safeTransfer(_msgSender(), amount);

        usersLastWithdrawal[_msgSender()] = block.timestamp;

        emit WithdrawMagic(amount, _msgSender(), block.timestamp, transactionId);
    }

    function topupWastelandsRewards(uint256 amount) external onlyAdminAccess {
        require(MagicToken.balanceOf(address(this)) >= amount, "Not enough Magic available");
        MagicToken.safeApprove(address(WASTELANDS), amount);
        WASTELANDS.topupMagicRewards(amount);
        emit WastelandsRewardsToppedUp(msg.sender, amount);
    }

    function setWastelandsContract(address wastelands) external onlyOwner {
        require(wastelands != address(0), "Invalid address");
        WASTELANDS = IWastelands(wastelands);
    }

    //Item
    function depositItems(uint256 itemId, uint256 amount) external {
        // Unused and removed
    }

    function withdrawItems(uint256 itemId, uint256 amount, address receiver) external onlyAdminAccess {
        // Unused and removed
    }

    function claimWithdrawItems(
        uint256 itemId,
        uint256 amount,
        uint256 transactionId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Unused and removed
    }

    //modifier
    modifier onlyAdminAccess() {
        require(adminAccess[_msgSender()] == true || _msgSender() == owner(), "Require admin access");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/gFly/IGFly.sol";
import "../interfaces/gFly/IVestedGFly.sol";

//MMMMWKl.                                            .:0WMMMM//
//MMMWk,                                                .dNMMM//
//MMNd.                                                  .lXMM//
//MWd.    .','''....                         .........    .lXM//
//Wk.     ';......'''''.                ..............     .dW//
//K;     .;,         ..,'.            ..'..         ...     'O//
//d.     .;;.           .''.        ..'.            .'.      c//
//:       .','.           .''.    ..'..           ....       '//
//'         .';.            .''...'..           ....         .//
//.           ';.             .''..             ..           .//
//.            ';.                             ...           .//
//,            .,,.                           .'.            .//
//c             .;.                           '.             ;//
//k.            .;.             .             '.            .d//
//Nl.           .;.           .;;'            '.            :K//
//MK:           .;.          .,,',.           '.           'OW//
//MM0;          .,,..       .''  .,.       ...'.          'kWM//
//MMMK:.          ..'''.....'..   .'..........           ,OWMM//
//MMMMXo.             ..'...        ......             .cKMMMM//
//MMMMMWO:.                                          .,kNMMMMM//
//MMMMMMMNk:.                                      .,xXMMMMMMM//
//MMMMMMMMMNOl'.                                 .ckXMMMMMMMMM//

contract GFly is AccessControl, ERC20, IGFly {
    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    /// @dev The identifier of the role which allows accounts to mint tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    uint256 public constant override MAX_SUPPLY = 1e7 * 1 ether;

    IVestedGFly public vestedGFly;

    constructor(address dao, address vestedGFly_) ERC20("gFLY", "GFLY") {
        require(dao != address(0), "GFly:INVALID_ADDRESS");
        require(vestedGFly_ != address(0), "GFly:INVALID_ADDRESS");

        vestedGFly = IVestedGFly(vestedGFly_);

        _setupRole(MINTER_ROLE, dao);
        _setupRole(ADMIN_ROLE, dao);
        _setupRole(ADMIN_ROLE, msg.sender); // This will be surrendered after deployment
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "GFly:MINT_DENIED");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFly:ACCESS_DENIED");
        _;
    }

    function mint(address account, uint256 amount) external override onlyMinter {
        require(
            vestedGFly.unminted() + vestedGFly.totalSupply() + totalSupply() + amount <= MAX_SUPPLY,
            "GFly:SUPPLY_OVERFLOW"
        );
        _mint(account, amount);
    }

    function burn(uint256 amount) external override onlyAdmin {
        _burn(msg.sender, amount);
    }

    function addMinter(address minter) external onlyAdmin {
        grantRole(MINTER_ROLE, minter);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "../interfaces/gFly/IGFlyStaking.sol";

//MMMMWKl.                                            .:0WMMMM//
//MMMWk,                                                .dNMMM//
//MMNd.                                                  .lXMM//
//MWd.    .','''....                         .........    .lXM//
//Wk.     ';......'''''.                ..............     .dW//
//K;     .;,         ..,'.            ..'..         ...     'O//
//d.     .;;.           .''.        ..'.            .'.      c//
//:       .','.           .''.    ..'..           ....       '//
//'         .';.            .''...'..           ....         .//
//.           ';.             .''..             ..           .//
//.            ';.                             ...           .//
//,            .,,.                           .'.            .//
//c             .;.                           '.             ;//
//k.            .;.             .             '.            .d//
//Nl.           .;.           .;;'            '.            :K//
//MK:           .;.          .,,',.           '.           'OW//
//MM0;          .,,..       .''  .,.       ...'.          'kWM//
//MMMK:.          ..'''.....'..   .'..........           ,OWMM//
//MMMMXo.             ..'...        ......             .cKMMMM//
//MMMMMWO:.                                          .,kNMMMMM//
//MMMMMMMNk:.                                      .,xXMMMMMMM//
//MMMMMMMMMNOl'.                                 .ckXMMMMMMMMM//

contract GFlyLPStaking is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IGFlyStaking {
    using ABDKMath64x64 for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    /// @dev The identifier of the role which allows accounts to run cron jobs.
    bytes32 public constant BATTLEFLY_BOT_ROLE = keccak256("BATTLEFLY_BOT");

    int128 public COEFFICIENT_A;
    int128 public COEFFICIENT_B;
    int128 public COEFFICIENT_C;

    bool public pause;
    uint16 public currentEpoch;
    uint256 public currentStakeId;
    uint256 public nextCron;
    uint256[36] public emissionsAtMonth;
    mapping(uint256 => bool) public cronExecuted;

    IGFly public gFly;
    IERC20Upgradeable public gFlyLP;

    mapping(uint16 => uint256) public unlockableAtEpoch;
    mapping(uint16 => uint256) public miningPowerAtEpoch;
    mapping(uint256 => GFlyStake) public stakeById;
    mapping(address => EnumerableSetUpgradeable.UintSet) private stakeIdsByAddress;

    // Extension for non-multisig guardians
    mapping(address => bool) public guardian;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address gFly_, address dao, address battleflyBot, uint256 nextCron_) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        require(gFly_ != address(0), "GFlyLPStaking:INVALID_ADDRESS");
        require(dao != address(0), "GFlyLPStaking:INVALID_ADDRESS");
        require(battleflyBot != address(0), "GFlyLPStaking:INVALID_ADDRESS");

        _setupRole(ADMIN_ROLE, dao);
        _setupRole(ADMIN_ROLE, msg.sender); // This will be surrendered after deployment
        _setupRole(BATTLEFLY_BOT_ROLE, battleflyBot);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BATTLEFLY_BOT_ROLE, ADMIN_ROLE);

        gFly = IGFly(gFly_);

        currentEpoch = 1;
        pause = true;
        nextCron = nextCron_;
        COEFFICIENT_A = 13019407595946985322971; //  705.7835 in signed 64.64-bit fixed point number.
        COEFFICIENT_B = 55340232221128654; //  0.003 in signed 64.64-bit fixed point number.
        COEFFICIENT_C = 5771986220663718700; //  0.3129 in signed 64.64-bit fixed point number.

        _setEmissions();
    }

    modifier whenNotPaused() {
        require(!pause, "GFlyLPStaking:PAUSED");
        _;
    }

    modifier onlyAvailableLock(uint16 lock) {
        require(lock >= 1 && lock <= 365, "GFlyLPStaking:UNALLOWED_LOCK");
        _;
    }

    modifier onlyStakeOwner(uint256 stakeId) {
        require(stakeById[stakeId].owner == msg.sender, "GFlyLPStaking:NOT_STAKE_OWNER");
        _;
    }

    modifier onlyGuardian() {
        require(guardian[msg.sender], "GFlyLPStaking:NOT_GUARDIAN");
        _;
    }

    /**
     * @dev Stake an amount of gFlyLP for a lock period.
     */
    function stake(
        uint256 amount,
        uint16 lock
    ) external override nonReentrant whenNotPaused onlyAvailableLock(lock) returns (uint256) {
        require(amount > 0, "GFlyLPStaking:CANNOT_STAKE_0");
        gFlyLP.safeTransferFrom(msg.sender, address(this), amount);
        ++currentStakeId;
        stakeById[currentStakeId] = GFlyStake(msg.sender, amount, lock, currentEpoch + lock, 0, currentEpoch);
        stakeIdsByAddress[msg.sender].add(currentStakeId);
        unlockableAtEpoch[currentEpoch + lock] += amount;
        emit Staked(msg.sender, currentStakeId, amount, lock, currentEpoch + lock);
        return currentStakeId;
    }

    /**
     * @dev Add gFlyLP to an existing stake
     */
    function addToStake(
        uint256 amount,
        uint256 stakeId
    ) external override nonReentrant whenNotPaused onlyStakeOwner(stakeId) {
        require(amount > 0, "GFlyLPStaking:CANNOT_STAKE_0");
        gFlyLP.safeTransferFrom(msg.sender, address(this), amount);
        stakeById[stakeId].pendingRewards = claimableById(stakeId);
        stakeById[stakeId].lastProcessEpoch = currentEpoch;
        stakeById[stakeId].amount += amount;
        unlockableAtEpoch[stakeById[stakeId].unlockEpoch] += amount;
        emit Staked(msg.sender, stakeId, amount, stakeById[stakeId].lock, stakeById[stakeId].unlockEpoch);
    }

    /**
     * @dev Unstake an existing and unlocked gFlyLP stake.
     */
    function unStake(uint256 stakeId) external override nonReentrant whenNotPaused onlyStakeOwner(stakeId) {
        require(currentEpoch >= stakeById[stakeId].unlockEpoch, "GFlyLPStaking:STAKE_LOCKED");
        _claim(stakeId);
        gFlyLP.safeTransfer(msg.sender, stakeById[stakeId].amount);
        unlockableAtEpoch[stakeById[stakeId].unlockEpoch] -= stakeById[stakeId].amount;
        emit UnStaked(msg.sender, stakeId, stakeById[stakeId].amount);
        delete stakeById[stakeId];
        stakeIdsByAddress[msg.sender].remove(stakeId);
    }

    /**
     * @dev Unstake all gFlyLP stakes of an account.
     */
    function unStakeAll() external override nonReentrant whenNotPaused {
        uint256 totalAmount = 0;
        uint256[] memory stakeIds = stakeIdsByAddress[msg.sender].values();
        for (uint256 i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            uint16 unlockEpoch = stakeById[stakeId].unlockEpoch;
            if (currentEpoch >= unlockEpoch) {
                _claim(stakeId);
                uint256 stakeAmount = stakeById[stakeId].amount;
                totalAmount += stakeAmount;
                unlockableAtEpoch[unlockEpoch] -= stakeAmount;
                emit UnStaked(msg.sender, stakeId, stakeAmount);
                delete stakeById[stakeId];
                stakeIdsByAddress[msg.sender].remove(stakeId);
            }
        }
        if (totalAmount > 0) {
            gFlyLP.safeTransfer(msg.sender, totalAmount);
        }
    }

    /**
     * @dev Claim the emissions of a gFlyLP stake
     */
    function claim(uint256 stakeId) external override nonReentrant whenNotPaused onlyStakeOwner(stakeId) {
        _claim(stakeId);
    }

    /**
     * @dev Claim all the gFly emissions of the caller
     */
    function claimAll() external override nonReentrant whenNotPaused {
        for (uint256 i = 0; i < stakeIdsByAddress[msg.sender].values().length; i++) {
            _claim(stakeIdsByAddress[msg.sender].at(i));
        }
    }

    /**
     * @dev Extend the lock period of a give stake.
     */
    function extendLockPeriod(
        uint256 stakeId,
        uint16 lock
    ) external override whenNotPaused onlyStakeOwner(stakeId) onlyAvailableLock(lock) {
        _extendLockPeriod(stakeId, lock);
    }

    /**
     * @dev Extend the lock period of all stakes of the sender
     */
    function extendLockPeriodOfAllStakes(uint16 lock) external override whenNotPaused onlyAvailableLock(lock) {
        for (uint256 i = 0; i < stakeIdsByAddress[msg.sender].values().length; i++) {
            _extendLockPeriod(stakeIdsByAddress[msg.sender].at(i), lock);
        }
    }

    /**
     * @dev Get the claimable gFly emissions of a stake
     */
    function claimableById(uint256 stakeId) public view override returns (uint256 total) {
        total = stakeById[stakeId].pendingRewards;
        for (uint16 i = stakeById[stakeId].lastProcessEpoch; i < currentEpoch; i++) {
            uint256 totalMiningPower = uint256(miningPowerAtEpoch[i]);
            uint16 lockEpochsRemaining = i <= stakeById[stakeId].unlockEpoch ? stakeById[stakeId].unlockEpoch - i : 0;
            uint256 individualMiningPower = uint256((stakeById[stakeId].amount * lockEpochsRemaining) / 365);
            uint256 month = (i / 30) + 1;
            if (month < 37) {
                total += uint256((emissionsAtMonth[month - 1] * individualMiningPower) / totalMiningPower);
            }
        }
    }

    /**
     * @dev Get the claimable gFly emissions of an account
     */
    function claimableByAddress(address account) external view override returns (uint256 total) {
        for (uint256 i = 0; i < stakeIdsByAddress[account].values().length; i++) {
            total += claimableById(stakeIdsByAddress[account].at(i));
        }
    }

    /**
     * @dev Get the stakeIds of an address
     */
    function getStakesOfAddress(address account) external view override returns (uint256[] memory) {
        return stakeIdsByAddress[account].values();
    }

    /**
     * @dev Get a stake object given the stakeId
     */
    function getStake(uint256 stakeId) external view override returns (GFlyStake memory) {
        return stakeById[stakeId];
    }

    /**
     * @dev Distribute emissions for the current epoch and setting the total mining power with the following formula:
     *      MP = gFLY * (DaysRemaining/365)
     */
    function distributeEmissions() external override whenNotPaused {
        require(hasRole(BATTLEFLY_BOT_ROLE, msg.sender), "GFlyLPStaking:ACCESS_DENIED");
        require(block.timestamp >= (nextCron - 600) && !cronExecuted[nextCron], "GFlyLPStaking:NOT_IN_TIME_WINDOW");
        uint256 totalMiningPower;
        for (uint16 i = currentEpoch; i <= currentEpoch + 365; i++) {
            totalMiningPower += (unlockableAtEpoch[i] * uint256(i - currentEpoch)) / 365;
        }
        miningPowerAtEpoch[currentEpoch] = totalMiningPower;
        currentEpoch++;
        cronExecuted[nextCron] = true;
        nextCron += 86400;
        emit EmissionsDistributed(totalMiningPower, currentEpoch);
    }

    /**
     * @dev Pause the staking contract
     */
    function setPause(bool state) external override onlyGuardian {
        pause = state;
        emit Paused(state);
    }

    /**
     * @dev Set the next cron
     */
    function setNextCron(uint256 nextCron_) external override {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFlyStaking:ACCESS_DENIED");
        nextCron = nextCron_;
    }

    /**
     * @dev Correct the pending emissions of a stake
     */
    function setPendingEmissionsOfStake(uint256 stakeId, uint256 pendingRewards) external override {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFlyLPStaking:ACCESS_DENIED");
        stakeById[stakeId].pendingRewards = pendingRewards;
    }

    /**
     * @dev Set the GFlyLP pair
     */
    function setGFlyLP(address gFlyLP_) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFlyStaking:ACCESS_DENIED");
        require(gFlyLP_ != address(0), "GFlyLPStaking:INVALID_ADDRESS");
        gFlyLP = IERC20Upgradeable(gFlyLP_);
    }

    /**
     * @dev Set the guardians
     */
    function setGuardian(address guardian_, bool state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFlyStaking:ACCESS_DENIED");
        guardian[guardian_] = state;
    }

    function _extendLockPeriod(uint256 stakeId, uint16 lock) internal {
        stakeById[stakeId].pendingRewards = claimableById(stakeId);
        stakeById[stakeId].lastProcessEpoch = currentEpoch;
        uint16 unlockedAt = stakeById[stakeId].unlockEpoch;
        if (stakeById[stakeId].unlockEpoch < currentEpoch) {
            unlockedAt = currentEpoch;
        }
        uint16 newUnlockEpoch = (unlockedAt - currentEpoch) + lock > 365 ? currentEpoch + 365 : unlockedAt + lock;
        unlockableAtEpoch[newUnlockEpoch] += stakeById[stakeId].amount;
        unlockableAtEpoch[stakeById[stakeId].unlockEpoch] -= stakeById[stakeId].amount;
        stakeById[stakeId].unlockEpoch = newUnlockEpoch;
        stakeById[stakeId].lock = newUnlockEpoch - currentEpoch;
        emit LockExtended(msg.sender, stakeId, lock, newUnlockEpoch);
    }

    function _claim(uint256 stakeId) internal returns (uint256 claimable) {
        claimable = claimableById(stakeId);
        gFly.mint(stakeById[stakeId].owner, claimable);
        stakeById[stakeId].pendingRewards = 0;
        stakeById[stakeId].lastProcessEpoch = currentEpoch;
        emit Claimed(stakeById[stakeId].owner, stakeId, claimable);
    }

    /**
     * @dev Set the emissions per day for every month. Equation for total amount of gFly per day:
     *      gFLY/day = a*(1-((b*e^(c*x))/((b*e^(c*x))+1))) (see Charlie's sheet) where:
     *      a = 705.926245973992
     *      b = 0.003
     *      c = 0.312962
     */
    function _setEmissions() internal {
        for (uint256 i = 0; i < 36; i++) {
            int128 curve = ABDKMath64x64.mul(
                COEFFICIENT_B,
                ABDKMath64x64.exp(ABDKMath64x64.mul(COEFFICIENT_C, ABDKMath64x64.fromUInt(i + 1)))
            );
            emissionsAtMonth[i] = uint256(
                ABDKMath64x64.mulu(
                    ABDKMath64x64.mul(
                        COEFFICIENT_A,
                        ABDKMath64x64.sub(
                            ABDKMath64x64.fromUInt(1),
                            ABDKMath64x64.div(curve, ABDKMath64x64.add(curve, ABDKMath64x64.fromUInt(1)))
                        )
                    ),
                    1e18
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../interfaces/gFly/IGFlyStaking.sol";
import "../interfaces/gFly/IGFly.sol";

//MMMMWKl.                                            .:0WMMMM//
//MMMWk,                                                .dNMMM//
//MMNd.                                                  .lXMM//
//MWd.    .','''....                         .........    .lXM//
//Wk.     ';......'''''.                ..............     .dW//
//K;     .;,         ..,'.            ..'..         ...     'O//
//d.     .;;.           .''.        ..'.            .'.      c//
//:       .','.           .''.    ..'..           ....       '//
//'         .';.            .''...'..           ....         .//
//.           ';.             .''..             ..           .//
//.            ';.                             ...           .//
//,            .,,.                           .'.            .//
//c             .;.                           '.             ;//
//k.            .;.             .             '.            .d//
//Nl.           .;.           .;;'            '.            :K//
//MK:           .;.          .,,',.           '.           'OW//
//MM0;          .,,..       .''  .,.       ...'.          'kWM//
//MMMK:.          ..'''.....'..   .'..........           ,OWMM//
//MMMMXo.             ..'...        ......             .cKMMMM//
//MMMMMWO:.                                          .,kNMMMMM//
//MMMMMMMNk:.                                      .,xXMMMMMMM//
//MMMMMMMMMNOl'.                                 .ckXMMMMMMMMM//

contract GFlyStaking is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, IGFlyStaking {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    /// @dev The identifier of the role which allows accounts to run cron jobs.
    bytes32 public constant BATTLEFLY_BOT_ROLE = keccak256("BATTLEFLY_BOT");
    /// @dev The identifier of the role which allows accounts to manage vestings.
    bytes32 public constant VESTING_MANAGER_ROLE = keccak256("VESTING_MANAGER");

    bool public pause;
    uint16 public currentEpoch;
    uint256 public currentStakeId;
    uint256 public nextCron;
    uint256[36] public emissionsAtMonth;

    IGFly public gFly;

    mapping(uint16 => uint256) public unlockableAtEpoch;
    mapping(uint16 => uint256) public miningPowerAtEpoch;
    mapping(uint256 => GFlyStake) public stakeById;
    mapping(address => EnumerableSetUpgradeable.UintSet) private stakeIdsByAddress;
    mapping(uint256 => bool) public cronExecuted;

    // Extension for non-multisig guardians
    mapping(address => bool) public guardian;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address gFly_, address dao, address battleflyBot, uint256 nextCron_) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        require(gFly_ != address(0), "GFlyStaking:INVALID_ADDRESS");
        require(dao != address(0), "GFlyStaking:INVALID_ADDRESS");
        require(battleflyBot != address(0), "GFlyStaking:INVALID_ADDRESS");

        _setupRole(ADMIN_ROLE, dao);
        _setupRole(ADMIN_ROLE, msg.sender); // This will be surrendered after deployment
        _setupRole(BATTLEFLY_BOT_ROLE, battleflyBot);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BATTLEFLY_BOT_ROLE, ADMIN_ROLE);
        _setRoleAdmin(VESTING_MANAGER_ROLE, ADMIN_ROLE);

        gFly = IGFly(gFly_);

        currentEpoch = 1;
        pause = true;
        nextCron = nextCron_;
        _setEmissions();
    }

    modifier whenNotPaused() {
        require(!pause, "GFlyStaking:PAUSED");
        _;
    }

    modifier onlyAvailableLock(uint256 lock) {
        require(lock >= 1 && lock <= 365, "GFlyStaking:UNALLOWED_LOCK");
        _;
    }

    modifier onlyStakeOwner(uint256 stakeId) {
        require(stakeById[stakeId].owner == msg.sender, "GFlyStaking:NOT_STAKE_OWNER");
        _;
    }

    modifier onlyVestingManager() {
        require(hasRole(VESTING_MANAGER_ROLE, msg.sender), "GFlyStaking:ACCESS_DENIED");
        _;
    }

    modifier onlyGuardian() {
        require(guardian[msg.sender], "GFlyStaking:NOT_GUARDIAN");
        _;
    }

    /**
     * @dev Stake an amount of gFly for a lock period.
     */
    function stake(
        uint256 amount,
        uint16 lock
    ) external override nonReentrant whenNotPaused onlyAvailableLock(lock) returns (uint256) {
        require(amount > 0, "GFlyStaking:CANNOT_STAKE_0");
        gFly.transferFrom(msg.sender, address(this), amount);
        ++currentStakeId;
        stakeById[currentStakeId] = GFlyStake(msg.sender, amount, lock, currentEpoch + lock, 0, currentEpoch);
        stakeIdsByAddress[msg.sender].add(currentStakeId);
        unlockableAtEpoch[currentEpoch + lock] += amount;
        emit Staked(msg.sender, currentStakeId, amount, lock, currentEpoch + lock);
        return currentStakeId;
    }

    /**
     * @dev Add gFly to an existing stake
     */
    function addToStake(
        uint256 amount,
        uint256 stakeId
    ) external override nonReentrant whenNotPaused onlyStakeOwner(stakeId) {
        require(amount > 0, "GFlyStaking:CANNOT_STAKE_0");
        gFly.transferFrom(msg.sender, address(this), amount);
        stakeById[stakeId].pendingRewards = claimableById(stakeId);
        stakeById[stakeId].lastProcessEpoch = currentEpoch;
        stakeById[stakeId].amount += amount;
        unlockableAtEpoch[stakeById[stakeId].unlockEpoch] += amount;
        emit Staked(msg.sender, stakeId, amount, stakeById[stakeId].lock, stakeById[stakeId].unlockEpoch);
    }

    /**
     * @dev Unstake an existing and unlocked gFly stake.
     */
    function unStake(uint256 stakeId) external override nonReentrant whenNotPaused onlyStakeOwner(stakeId) {
        require(currentEpoch >= stakeById[stakeId].unlockEpoch, "GFlyStaking:STAKE_LOCKED");
        _claim(stakeId);
        gFly.transfer(msg.sender, stakeById[stakeId].amount);
        unlockableAtEpoch[stakeById[stakeId].unlockEpoch] -= stakeById[stakeId].amount;
        emit UnStaked(msg.sender, stakeId, stakeById[stakeId].amount);
        delete stakeById[stakeId];
        stakeIdsByAddress[msg.sender].remove(stakeId);
    }

    /**
     * @dev Unstake all gFly stakes of an account.
     */
    function unStakeAll() external override nonReentrant whenNotPaused {
        uint256 totalAmount = 0;
        uint256[] memory stakeIds = stakeIdsByAddress[msg.sender].values();
        for (uint256 i = 0; i < stakeIds.length; i++) {
            uint256 stakeId = stakeIds[i];
            uint16 unlockEpoch = stakeById[stakeId].unlockEpoch;
            if (currentEpoch >= unlockEpoch) {
                _claim(stakeId);
                uint256 stakeAmount = stakeById[stakeId].amount;
                totalAmount += stakeAmount;
                unlockableAtEpoch[unlockEpoch] -= stakeAmount;
                emit UnStaked(msg.sender, stakeId, stakeAmount);
                delete stakeById[stakeId];
                stakeIdsByAddress[msg.sender].remove(stakeId);
            }
        }
        if (totalAmount > 0) {
            gFly.transfer(msg.sender, totalAmount);
        }
    }

    /**
     * @dev Function to transfer a stake position for a specified amount to a new owner.
     * This function is created to facilitate the setup of an OTC market for staked positions.
     * The new staking position will follow the emissions schedule of the old position.
     */
    function transferStake(
        uint256 stakeId,
        uint256 amount,
        address newOwner
    ) external whenNotPaused onlyVestingManager {
        require(amount > 0, "GFlyStaking:CANNOT_TRANSFER_0");
        require(stakeById[stakeId].amount >= amount, "GFlyStaking:STAKE_AMOUNT_NOT_SUFFICIENT_FOR_TRANSFER");
        _claim(stakeId);
        ++currentStakeId;
        stakeById[currentStakeId] = GFlyStake(
            newOwner,
            amount,
            stakeById[stakeId].lock,
            stakeById[stakeId].unlockEpoch,
            0,
            currentEpoch
        );
        stakeIdsByAddress[newOwner].add(currentStakeId);
        stakeById[stakeId].amount -= amount;
        emit StakeTransfered(stakeById[stakeId].owner, stakeId, newOwner, currentStakeId, amount);
        if (stakeById[stakeId].amount == 0) {
            stakeIdsByAddress[stakeById[stakeId].owner].remove(stakeId);
            delete stakeById[stakeId];
        }
    }

    /**
     * @dev Claim the emissions of a gFly stake
     */
    function claim(uint256 stakeId) external override nonReentrant whenNotPaused onlyStakeOwner(stakeId) {
        _claim(stakeId);
    }

    /**
     * @dev Claim all the gFly emissions of the caller
     */
    function claimAll() external override nonReentrant whenNotPaused {
        for (uint256 i = 0; i < stakeIdsByAddress[msg.sender].values().length; i++) {
            _claim(stakeIdsByAddress[msg.sender].at(i));
        }
    }

    /**
     * @dev Claim the gFly emissions of a stake and restake it in 1 go.
     */
    function claimAndRestake(uint256 stakeId) external nonReentrant whenNotPaused onlyStakeOwner(stakeId) {
        _claimAndRestake(stakeId);
    }

    /**
     * @dev Claim all the gFly emissions of the caller and restake them in 1 go.
     */
    function claimAndRestakeAll() external nonReentrant whenNotPaused {
        for (uint256 i = 0; i < stakeIdsByAddress[msg.sender].values().length; i++) {
            _claimAndRestake(stakeIdsByAddress[msg.sender].at(i));
        }
    }

    /**
     * @dev Extend the lock period of a given stake.
     */
    function extendLockPeriod(
        uint256 stakeId,
        uint16 lock
    ) external override whenNotPaused onlyStakeOwner(stakeId) onlyAvailableLock(lock) {
        _extendLockPeriod(stakeId, lock);
    }

    /**
     * @dev Extend the lock period of all stakes of the sender
     */
    function extendLockPeriodOfAllStakes(uint16 lock) external override whenNotPaused onlyAvailableLock(lock) {
        for (uint256 i = 0; i < stakeIdsByAddress[msg.sender].values().length; i++) {
            _extendLockPeriod(stakeIdsByAddress[msg.sender].at(i), lock);
        }
    }

    /**
     * @dev Get the claimable gFly emissions of a stake
     */
    function claimableById(uint256 stakeId) public view override returns (uint256 total) {
        total = stakeById[stakeId].pendingRewards;
        for (uint16 i = stakeById[stakeId].lastProcessEpoch; i < currentEpoch; i++) {
            uint256 totalMiningPower = uint256(miningPowerAtEpoch[i]);
            uint16 lockEpochsRemaining = i <= stakeById[stakeId].unlockEpoch ? stakeById[stakeId].unlockEpoch - i : 0;
            uint256 individualMiningPower = uint256(stakeById[stakeId].amount * lockEpochsRemaining) / 365;
            uint256 month = (i / 30) + 1;
            if (month < 37) {
                total += uint256((emissionsAtMonth[month - 1] * individualMiningPower) / totalMiningPower);
            }
        }
    }

    /**
     * @dev Get the claimable gFly emissions of an account
     */
    function claimableByAddress(address account) external view override returns (uint256 total) {
        for (uint256 i = 0; i < stakeIdsByAddress[account].values().length; i++) {
            total += claimableById(stakeIdsByAddress[account].at(i));
        }
    }

    /**
     * @dev Get the stakeIds of an address
     */
    function getStakesOfAddress(address account) external view override returns (uint256[] memory) {
        return stakeIdsByAddress[account].values();
    }

    /**
     * @dev Get a stake object given the stakeId
     */
    function getStake(uint256 stakeId) external view override returns (GFlyStake memory) {
        return stakeById[stakeId];
    }

    /**
     * @dev Distribute emissions for the current epoch and setting the total mining power with the following formula:
     *      MP = gFLY * (DaysRemaining/365)
     */
    function distributeEmissions() external override whenNotPaused {
        require(hasRole(BATTLEFLY_BOT_ROLE, msg.sender), "GFlyStaking:ACCESS_DENIED");
        require(block.timestamp >= (nextCron - 600) && !cronExecuted[nextCron], "GFlyStaking:NOT_IN_TIME_WINDOW");
        uint256 totalMiningPower;
        for (uint16 i = currentEpoch; i <= currentEpoch + 365; i++) {
            totalMiningPower += (unlockableAtEpoch[i] * uint256(i - currentEpoch)) / 365;
        }
        miningPowerAtEpoch[currentEpoch] = totalMiningPower;
        currentEpoch++;
        cronExecuted[nextCron] = true;
        nextCron += 86400;
        emit EmissionsDistributed(totalMiningPower, currentEpoch);
    }

    /**
     * @dev Pause the staking contract
     */
    function setPause(bool state) external override onlyGuardian {
        pause = state;
        emit Paused(state);
    }

    /**
     * @dev Correct the pending emissions of a stake
     */
    function setPendingEmissionsOfStake(uint256 stakeId, uint256 pendingRewards) external override {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFlyStaking:ACCESS_DENIED");
        stakeById[stakeId].pendingRewards = pendingRewards;
    }

    /**
     * @dev Set the next cron
     */
    function setNextCron(uint256 nextCron_) external override {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFlyStaking:ACCESS_DENIED");
        nextCron = nextCron_;
    }

    /**
     * @dev Set the guardians
     */
    function setGuardian(address guardian_, bool state) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "GFlyStaking:ACCESS_DENIED");
        guardian[guardian_] = state;
    }

    function _extendLockPeriod(uint256 stakeId, uint16 lock) internal {
        stakeById[stakeId].pendingRewards = claimableById(stakeId);
        stakeById[stakeId].lastProcessEpoch = currentEpoch;
        uint16 unlockedAt = stakeById[stakeId].unlockEpoch;
        if (unlockedAt < currentEpoch) {
            unlockedAt = currentEpoch;
        }
        uint16 newUnlockEpoch = (unlockedAt - currentEpoch) + lock > 365 ? currentEpoch + 365 : unlockedAt + lock;
        unlockableAtEpoch[newUnlockEpoch] += stakeById[stakeId].amount;
        unlockableAtEpoch[stakeById[stakeId].unlockEpoch] -= stakeById[stakeId].amount;
        stakeById[stakeId].unlockEpoch = newUnlockEpoch;
        stakeById[stakeId].lock = newUnlockEpoch - currentEpoch;
        emit LockExtended(msg.sender, stakeId, lock, newUnlockEpoch);
    }

    function _claim(uint256 stakeId) internal returns (uint256 claimable) {
        claimable = claimableById(stakeId);
        gFly.mint(stakeById[stakeId].owner, claimable);
        stakeById[stakeId].pendingRewards = 0;
        stakeById[stakeId].lastProcessEpoch = currentEpoch;
        emit Claimed(stakeById[stakeId].owner, stakeId, claimable);
    }

    function _claimAndRestake(uint256 stakeId) internal returns (uint256 claimable) {
        claimable = claimableById(stakeId);
        gFly.mint(address(this), claimable);
        stakeById[stakeId].pendingRewards = 0;
        stakeById[stakeId].lastProcessEpoch = currentEpoch;
        stakeById[stakeId].amount += claimable;
        unlockableAtEpoch[stakeById[stakeId].unlockEpoch] += claimable;
        emit ClaimedAndRestaked(stakeById[stakeId].owner, stakeId, claimable);
    }

    /**
     * @dev Set the emissions per day for every month. Equation for total amount of gFly per day:
     *      gFly/day = mx+b (see Charlie's sheet) where:
     *      m = -3.23809353590736
     *      x = month
     *      b = 768.23802833095200
     */
    function _setEmissions() internal {
        for (uint256 i = 0; i < 36; i++) {
            emissionsAtMonth[i] = uint256(-3238093535907360000 * int256(i + 1) + 768238028330952000000);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGFly is IERC20 {
    function MAX_SUPPLY() external returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../gFly/GFly.sol";

interface IGFlyStaking {
    struct GFlyStake {
        address owner;
        uint256 amount;
        uint16 lock;
        uint16 unlockEpoch;
        uint256 pendingRewards;
        uint16 lastProcessEpoch;
    }

    event Staked(address indexed account, uint256 indexed stakeId, uint256 amount, uint16 lock, uint16 unlockEpoch);
    event UnStaked(address indexed account, uint256 indexed stakeId, uint256 amount);
    event StakeTransfered(
        address indexed owner,
        uint256 indexed stakeId,
        address indexed newOwner,
        uint256 newStakeId,
        uint256 amount
    );
    event LockExtended(address indexed account, uint256 indexed stakeId, uint16 lock, uint16 unlockEpoch);
    event Claimed(address indexed account, uint256 indexed stakeId, uint256 amount);
    event ClaimedAndRestaked(address indexed account, uint256 indexed stakeId, uint256 amount);
    event Paused(bool state);
    event EmissionsDistributed(uint256 totalMiningPower, uint16 currentEpoch);

    function distributeEmissions() external;

    function stake(uint256 amount, uint16 lock) external returns (uint256);

    function addToStake(uint256 amount, uint256 stakeId) external;

    function unStake(uint256 stakeId) external;

    function unStakeAll() external;

    function claim(uint256 stakeId) external;

    function claimAll() external;

    function extendLockPeriod(uint256 stakeId, uint16 lock) external;

    function extendLockPeriodOfAllStakes(uint16 lock) external;

    function claimableById(uint256 stakeId) external view returns (uint256 total);

    function claimableByAddress(address account) external view returns (uint256 total);

    function getStakesOfAddress(address account) external view returns (uint256[] memory);

    function getStake(uint256 stakeId) external view returns (GFlyStake memory);

    function setPause(bool state) external;

    function setNextCron(uint256 nextCron_) external;

    function setPendingEmissionsOfStake(uint256 stakeId, uint256 pendingRewards) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVestedGFly is IERC20 {
    struct VestingPosition {
        bool burnable;
        bool minted;
        address owner;
        uint256 startTime;
        uint256 lastBurnTime;
        uint256 employmentTimestamp;
        uint256 remainingAllocation;
        uint256 initialAllocation;
        uint256 initialUnlockable;
        uint256 burnt;
        uint256 vestedAtLastBurn;
        uint256 employeeBurnt;
    }

    function addVestingPosition(
        address owner,
        uint256 amount,
        bool burnable,
        uint256 initialUnlockable,
        uint256 employmentTimestamp
    ) external;

    function mint() external;

    function burn(uint256 vestingId, uint256 amount) external;

    function burnAll(uint256 vestingId) external;

    function transferVestingPosition(uint256 vestingId, uint256 amount, address newOwner) external;

    function claimAllGFly() external;

    function claimGFly(uint256 vestingId) external;

    function totalVestedOf(address account) external view returns (uint256 total);

    function vestedOf(uint256 vestingId) external view returns (uint256);

    function totalClaimableOf(address account) external view returns (uint256 total);

    function claimableOf(uint256 vestingId) external view returns (uint256);

    function totalClaimedOf(address account) external view returns (uint256 total);

    function claimedOf(uint256 vestingId) external view returns (uint256);

    function totalBalance(address account) external view returns (uint256 total);

    function balanceOfVesting(uint256 vestingId) external view returns (uint256);

    function getVestingIdsOfAddress(address account) external view returns (uint256[] memory);

    function maxBurnable(uint256 vestingId) external view returns (uint256 burnable);

    function claimableOfAtTimestamp(uint256 vestingId, uint256 timestamp) external view returns (uint256);

    function unminted() external returns (uint256);

    event VestingPositionAdded(
        address indexed owner,
        uint256 indexed vestingId,
        uint256 amount,
        bool burnable,
        uint256 initialUnlockable,
        uint256 startTime
    );
    event Minted(address indexed owner, uint256 indexed vestingId, uint256 amount);
    event Burned(address indexed owner, uint256 indexed vestingId, uint256 amount);
    event GFlyClaimed(address indexed owner, uint256 indexed vestingId, uint256 amount);
    event VestingPositionTransfered(
        address indexed owner,
        uint256 indexed vestingId,
        address indexed newOwner,
        uint256 newVestingId,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IAtlasMine {
    enum Lock {
        twoWeeks,
        oneMonth,
        threeMonths,
        sixMonths,
        twelveMonths
    }
    struct UserInfo {
        uint256 originalDepositAmount;
        uint256 depositAmount;
        uint256 lpAmount;
        uint256 lockedUntil;
        uint256 vestingLastUpdate;
        int256 rewardDebt;
        Lock lock;
    }

    function treasure() external view returns (address);

    function legion() external view returns (address);

    function unlockAll() external view returns (bool);

    function boosts(address user) external view returns (uint256);

    function userInfo(
        address user,
        uint256 depositId
    )
        external
        view
        returns (
            uint256 originalDepositAmount,
            uint256 depositAmount,
            uint256 lpAmount,
            uint256 lockedUntil,
            uint256 vestingLastUpdate,
            int256 rewardDebt,
            Lock lock
        );

    function getLockBoost(Lock _lock) external pure returns (uint256 boost, uint256 timelock);

    function getVestingTime(Lock _lock) external pure returns (uint256 vestingTime);

    function stakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function unstakeTreasure(uint256 _tokenId, uint256 _amount) external;

    function stakeLegion(uint256 _tokenId) external;

    function unstakeLegion(uint256 _tokenId) external;

    function withdrawPosition(uint256 _depositId, uint256 _amount) external returns (bool);

    function withdrawAll() external;

    function pendingRewardsAll(address _user) external view returns (uint256 pending);

    function deposit(uint256 _amount, Lock _lock) external;

    function harvestAll() external;

    function harvestPosition(uint256 _depositId) external;

    function currentId(address _user) external view returns (uint256);

    function pendingRewardsPosition(address _user, uint256 _depositId) external view returns (uint256);

    function getAllUserDepositIds(address) external view returns (uint256[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IBattlefly is IERC721EnumerableUpgradeable {
    function mintBattlefly(address receiver, uint256 battleflyType) external returns (uint256);

    function mintBattleflies(
        address receiver,
        uint256 _battleflyType,
        uint256 amount
    ) external returns (uint256[] memory);

    function getBattleflyType(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IAtlasMine.sol";

interface IBattleflyAtlasStakerV02 {
    struct Vault {
        uint16 fee;
        uint16 claimRate;
        bool enabled;
    }

    struct VaultStake {
        uint64 lockAt;
        uint64 unlockAt;
        uint64 retentionUnlock;
        uint256 amount;
        uint256 paidEmission;
        address vault;
        IAtlasMine.Lock lock;
    }

    function MAGIC() external returns (IERC20Upgradeable);

    function deposit(uint256, IAtlasMine.Lock) external returns (uint256);

    function withdraw(uint256) external returns (uint256);

    function claim(uint256) external returns (uint256);

    function withdrawLiquidAmountForMigration(uint256 amount) external;

    function depositLiquidAmount(uint256 amount) external;

    function requestWithdrawal(uint256) external returns (uint64);

    function currentDepositId() external view returns (uint256);

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getVaultStake(uint256) external view returns (VaultStake memory);

    function getClaimableEmission(uint256) external view returns (uint256, uint256);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function currentEpoch() external view returns (uint64 epoch);

    function transitionEpoch() external view returns (uint64 epoch);

    function getLockPeriod(IAtlasMine.Lock) external view returns (uint64 epoch);

    function setPause(bool _paused) external;

    function depositIdsOfVault(address vault) external view returns (uint256[] memory depositIds);

    function activeAtlasPositionSize() external view returns (uint256);

    function totalStakedAtEpochForLock(IAtlasMine.Lock lock, uint64 epoch) external view returns (uint256);

    function totalPerShareAtEpochForLock(IAtlasMine.Lock lock, uint64 epoch) external view returns (uint256);

    function FEE_DENOMINATOR() external pure returns (uint96);

    function pausedUntil() external view returns (uint256);

    function getVault(address _vault) external view returns (Vault memory);

    function getTotalClaimableEmission(uint256 _depositId) external view returns (uint256 emission, uint256 fee);

    function getApyAtEpochIn1000(uint64 epoch) external view returns (uint256);

    function getActivePositionIds() external view returns (uint256[] memory);

    // ========== Events ==========
    event AddedSuperAdmin(address who);
    event RemovedSuperAdmin(address who);

    event AddedVault(address indexed vault, uint16 fee, uint16 claimRate);
    event RemovedVault(address indexed vault);

    event StakedTreasure(address staker, uint256 tokenId, uint256 amount);
    event UnstakedTreasure(address staker, uint256 tokenId, uint256 amount);

    event StakedLegion(address staker, uint256 tokenId);
    event UnstakedLegion(address staker, uint256 tokenId);

    event SetTreasury(address treasury);
    event SetBattleflyBot(address bot);

    event NewDeposit(address indexed vault, uint256 amount, uint256 unlockedAt, uint256 indexed depositId);
    event WithdrawPosition(address indexed vault, uint256 amount, uint256 indexed depositId);
    event ClaimEmission(address indexed vault, uint256 amount, uint256 indexed depositId);
    event RequestWithdrawal(address indexed vault, uint64 withdrawalEpoch, uint256 indexed depositId);

    event DepositedAllToMine(uint256 amount);

    event SetPause(bool paused);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import "./IAtlasMine.sol";

interface IBattleflyHarvesterEmissions {
    struct HarvesterEmission {
        uint256 amount;
        uint256 harvesterMagic;
        uint256 additionalFlywheelMagic;
    }

    function topupHarvesterEmissions(
        uint256 _amount,
        uint256 _harvesterMagic,
        uint256 _additionalFlywheelMagic
    ) external;

    function setVaultHarvesterStake(uint256 _amount, address _vault) external;

    function getClaimableEmission(uint256 _depositId) external view returns (uint256 emission, uint256 fee);

    function getClaimableEmission(address _vault) external view returns (uint256 emission, uint256 fee);

    function claim(uint256 _depositId) external returns (uint256);

    function claim(address _vault) external returns (uint256);

    function claimVault(address _vault) external returns (uint256);

    function getApyAtEpochIn1000(uint64 epoch) external view returns (uint256);

    // ========== Events ==========
    event topupHarvesterMagic(uint256 amount, uint256 harvesterMagic, uint256 additionalFlywheelMagic, uint64 epoch);
    event ClaimHarvesterEmission(address user, uint256 emission, uint256 depositId);
    event ClaimHarvesterEmissionFromVault(address user, uint256 emission, address vault);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFlywheelEmissions {
    struct HarvesterEmission {
        uint256 amount;
        uint256 harvesterMagic;
        uint256 additionalFlywheelMagic;
    }

    struct ContractAddresses {
        address magic;
        address gFly;
        address gFlyStaking;
        address atlasStaker;
        address treasuryVault;
        address opex;
        address vault1;
        address vault2;
        address cheese;
        address digi;
        address battleflyBot;
        address dao;
    }

    function setGFlyGameAddress(address vault, address gFlyGameAddress) external;

    function setGFlyMagicSwap(address gFlyMagicSwap) external;

    function setTreasury(address treasury2, address treasury3) external;

    function topupHarvesterEmissions(uint256 amount, uint256 harvesterMagic, uint256 additionalFlywheelMagic) external;

    function topupFlywheelEmissions(uint256 amount) external;

    function setVaultHarvesterStake(uint256 _amount, address _vault) external;

    function claim(
        uint256 index,
        uint256 epoch,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount,
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 individualMiningPower,
        uint256 totalMiningPower,
        bytes32[] calldata merkleProof
    ) external;

    function setMerkleRoot(bytes32 root) external;

    function getClaimableFor(
        address account,
        uint256 cumulativeFlywheelAmount,
        uint256 cumulativeHarvesterAmount
    ) external view returns (uint256 claimable);

    function getClaimedFor(address account) external view returns (uint256);

    function getApyInBPS(
        uint256 flywheelClaimableAtEpoch,
        uint256 harvesterClaimableAtEpoch,
        uint256 totalStaked
    ) external pure returns (uint256 apyInBPS);

    function getActivatedRewardsInBPS() external view returns (uint256 rewardsActivated);

    // ========== Events ==========
    event GFlyGameAddressSet(address indexed vault, address indexed gFlyGameAddress);
    event HarvesterEmissionsToppedUp(
        uint256 amount,
        uint256 harvesterMagic,
        uint256 additionalFlywheelMagic,
        uint256 v1VaultHarvesterStake,
        uint256 v2vaultHarvesterStake,
        uint256 cheeseHarvesterStake,
        uint256 digiHarvesterStake,
        uint64 indexed epoch,
        uint256 activatedRewardsInBPS
    );
    event FlywheelEmissionsToppedUp(uint64 indexed epoch, uint256 amount);
    event Claimed(address indexed account, uint256 claimable, uint256 indexed epoch);
    event MerkleRootSet(bytes32 root, uint256 indexed emissionsEpoch);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IItem is IERC1155Upgradeable {
    function mintItems(uint256 itemId, address receiver, uint256 amount, bytes memory data) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IMod is IERC721EnumerableUpgradeable {
    function mintMod(address receiver) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import "./IMod.sol";

interface ISpecialNFT is IERC721EnumerableUpgradeable {
    function mintSpecialNFT(address receiver, uint256 specialNFTType) external returns (uint256);

    function mintSpecialNFTs(
        address receiver,
        uint256 _specialNFTType,
        uint256 amount
    ) external returns (uint256[] memory);

    function getSpecialNFTType(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IVault {
    function isAutoCompounded(uint256) external view returns (bool);

    function updatePosition(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
import "../IAtlasMine.sol";

interface IBattleflyTreasuryFlywheelVault {
    struct UserStake {
        uint64 lockAt;
        uint256 amount;
        address owner;
        IAtlasMine.Lock lock;
    }

    function deposit(uint128 _amount) external returns (uint256 atlasStakerDepositId);

    function withdraw(uint256[] memory _depositIds, address user) external returns (uint256 amount);

    function withdrawAll(address user) external returns (uint256 amount);

    function requestWithdrawal(uint256[] memory _depositIds) external;

    function claim(uint256 _depositId, address user) external returns (uint256 emission);

    function claimAll(address user) external returns (uint256 amount);

    function claimAllAndRestake() external returns (uint256 amount);

    function topupMagic(uint256 amount) external;

    function withdrawLiquidAmount(uint256 amount) external;

    function setRestake(bool restake_) external;

    function getAllowedLocks() external view returns (IAtlasMine.Lock[] memory);

    function getClaimableEmission(uint256) external view returns (uint256);

    function canRequestWithdrawal(uint256 _depositId) external view returns (bool requestable);

    function canWithdraw(uint256 _depositId) external view returns (bool withdrawable);

    function initialUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function retentionUnlock(uint256 _depositId) external view returns (uint64 epoch);

    function getCurrentEpoch() external view returns (uint64 epoch);

    function getDepositIds() external view returns (uint256[] memory ids);

    function getName() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IAtlasMine.sol";

library BattleflyAtlasStakerUtils {
    /**
     * @dev Get lock period
     *      Need to consider about adding 1 more day to lock period regarding the daily cron job
     */
    function getLockPeriod(IAtlasMine.Lock _lock, IAtlasMine ATLAS_MINE) external pure returns (uint64) {
        if (_lock == IAtlasMine.Lock.twoWeeks) {
            return 14 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.oneMonth) {
            return 30 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.threeMonths) {
            return 90 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.sixMonths) {
            return 180 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }
        if (_lock == IAtlasMine.Lock.twelveMonths) {
            return 365 days + 1 days + uint64(ATLAS_MINE.getVestingTime(_lock));
        }

        revert("BattleflyAtlasStaker: Invalid Lock");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Contract imports
import { ERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol";
import { ERC721EnumerableInternal } from "@solidstate/contracts/token/ERC721/enumerable/ERC721EnumerableInternal.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";

// Storage imports
import { WithModifiers } from "../libraries/LibStorage.sol";
import { Errors } from "../helpers/Errors.sol";
import "../helpers/Constants.sol";

// Library imports
import { LibMagicRewardsUtils } from "../libraries/LibMagicRewardsUtils.sol";

//interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WLMagicRewardsFacet is WithModifiers, ERC721BaseInternal, ERC721EnumerableInternal, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event MagicRewardsToppedUp(address indexed account, uint256 amount);
    event MagicRewardsClaimed(address indexed account, uint256 indexed landId, uint256 claimable);

    /**
     * @dev Topup Magic rewards which will be divided over all Wastelands
     */
    function topupMagicRewards(uint256 amount) external {
        IERC20(ws().magic).safeTransferFrom(msg.sender, address(this), amount);
        ws().magicRewardsPerLand += amount / MAX_CAP_LAND;
        emit MagicRewardsToppedUp(msg.sender, amount);
    }

    /**
     * @dev Claim outstanding Magic rewards for a Wasteland
     */
    function claimMagicReward(uint256 landId) external notPaused nonReentrant {
        if (_ownerOf(landId) != msg.sender) revert Errors.NotOwnerOfLand();
        uint256 claimableReward = LibMagicRewardsUtils.claimableMagicReward(landId);
        if (claimableReward > 0) {
            ws().rewardsWithdrawnPerLand[landId] += claimableReward;
            IERC20(ws().magic).safeTransfer(msg.sender, claimableReward);
            emit MagicRewardsClaimed(msg.sender, landId, claimableReward);
        }
    }

    /**
     * @dev Claim all outstanding Magic rewards of the caller.
     */
    function claimAllMagicRewards() external notPaused nonReentrant {
        uint256 balance = _balanceOf(msg.sender);
        uint256 claimableReward;
        for (uint256 i = 0; i < balance; i++) {
            uint256 landId = _tokenOfOwnerByIndex(msg.sender, i);
            uint256 claimableForLand = LibMagicRewardsUtils.claimableMagicReward(landId);
            ws().rewardsWithdrawnPerLand[landId] += claimableForLand;
            claimableReward += claimableForLand;
            if (claimableForLand > 0) {
                emit MagicRewardsClaimed(msg.sender, landId, claimableForLand);
            }
        }
        if (claimableReward > 0) {
            IERC20(ws().magic).safeTransfer(msg.sender, claimableReward);
        }
    }

    /**
     * @dev Get the total claimable Magic rewards of the provided account
     */
    function totalClaimable(address account) external view returns (uint256 claimableReward) {
        uint256 balance = _balanceOf(account);
        for (uint256 i = 0; i < balance; i++) {
            uint256 landId = _tokenOfOwnerByIndex(account, i);
            uint256 claimableForLand = LibMagicRewardsUtils.claimableMagicReward(landId);
            claimableReward += claimableForLand;
        }
    }

    /**
     * @dev Get the claimable Magic rewards of the provided Wasteland
     */
    function claimable(uint256 landId) external view returns (uint256) {
        return LibMagicRewardsUtils.claimableMagicReward(landId);
    }

    /**
     * @dev Get the amount of claimed Magic for the provided Wasteland
     */
    function claimed(uint256 landId) external view returns (uint256) {
        return ws().rewardsWithdrawnPerLand[landId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Contract imports
import { ERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol";
import { ERC721EnumerableInternal } from "@solidstate/contracts/token/ERC721/enumerable/ERC721EnumerableInternal.sol";

// Storage imports
import { WithModifiers } from "../libraries/LibStorage.sol";
import { Errors } from "../helpers/Errors.sol";
import "../helpers/Constants.sol";

// Library imports
import { LibLandUtils } from "../libraries/LibLandUtils.sol";

contract WLMintingFacet is WithModifiers, ERC721BaseInternal, ERC721EnumerableInternal {
    /**
     * @dev Mint wastelands provided a valid claim.
     */
    function mintWhitelist(
        uint256 index,
        uint256[] calldata tokens,
        bytes32[] calldata merkleProof
    ) external notPaused {
        LibLandUtils.verifyProof(index, msg.sender, tokens, merkleProof);
        uint256 amount = tokens.length;
        if (_totalSupply() + amount > MAX_CAP_LAND) revert Errors.MaxLandCapReached();
        ws().wastelandsWhitelistMinted[msg.sender] = true;
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, tokens[i]);
        }
    }

    /**
     * @dev Check if the provided account has minted its assigned whitelists yet.
     */
    function hasMintedFromWhitelist(address account) external view returns (bool) {
        return ws().wastelandsWhitelistMinted[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

uint256 constant MAX_CAP_LAND = 200;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Errors {
    error NotGuardian();
    error WastelandsPaused();
    error WastelandsAlreadyPaused();
    error WastelandsAlreadyUnPaused();
    error TokenDoesNotExist();
    error WastelandsAlreadyMinted();
    error InvalidSignature();
    error NotOwnerOfLand();
    error MaxLandCapReached();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import { ISolidStateERC721 } from "@solidstate/contracts/token/ERC721/ISolidStateERC721.sol";

interface IWastelands is ISolidStateERC721 {
    // WLLandFacet
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function contractURI() external view returns (string memory);

    //WLMagicRewardsFacet
    function topupMagicRewards(uint256 amount) external;

    function claimMagicReward(uint256 landId) external;

    function claimAllMagicRewards() external;

    function totalClaimable(address account) external view returns (uint256 claimableReward);

    function claimable(uint256 landId) external view returns (uint256);

    function claimed(uint256 landId) external view returns (uint256);

    //WLMintingFacet
    function mintWhitelist(uint256 index, uint256[] calldata tokens, bytes32[] calldata merkleProof) external;

    function hasMintedFromWhitelist(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// Library imports
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Storage imports
import { LibStorage, WastelandStorage } from "./LibStorage.sol";
import { Errors } from "../helpers/Errors.sol";
import { ERC721BaseStorage } from "@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol";

library LibLandUtils {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    function ws() internal pure returns (WastelandStorage storage) {
        return LibStorage.wastelandStorage();
    }

    function verifyProof(
        uint256 index,
        address account,
        uint256[] memory tokens,
        bytes32[] memory merkleProof
    ) internal view {
        if (ws().wastelandsWhitelistMinted[account]) revert Errors.WastelandsAlreadyMinted();
        if (!_verifyMerkleProof(_leaf(index, account, tokens), merkleProof)) revert Errors.InvalidSignature();
    }

    function _leaf(uint256 index, address account, uint256[] memory tokens) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(index, account, tokens));
    }

    function _verifyMerkleProof(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, ws().mintMerkleRoot, leaf);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// Library imports
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Storage imports
import { LibStorage, WastelandStorage } from "./LibStorage.sol";
import { ERC721BaseStorage } from "@solidstate/contracts/token/ERC721/base/ERC721BaseStorage.sol";

library LibMagicRewardsUtils {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    error WastelandsAlreadyMinted();
    error InvalidSignature();

    function ws() internal pure returns (WastelandStorage storage) {
        return LibStorage.wastelandStorage();
    }

    function claimableMagicReward(uint256 landId) internal view returns (uint256) {
        return ws().magicRewardsPerLand - ws().rewardsWithdrawnPerLand[landId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibDiamond } from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import { Errors } from "../helpers/Errors.sol";

struct WastelandStorage {
    bool paused;
    uint256 magicRewardsPerLand;
    bytes32 mintMerkleRoot;
    address diamondAddress;
    address magic;
    string landMetadataExtension;
    string landContractURI;
    mapping(address => bool) guardian;
    mapping(address => bool) wastelandsWhitelistMinted;
    mapping(uint256 => uint256) rewardsWithdrawnPerLand;
}

/**
 * All of Battlefly's wastelands storage is stored in a single WastelandStorage struct.
 *
 * The Diamond Storage pattern (https://dev.to/mudgen/how-diamond-storage-works-90e)
 * is used to set the struct at a specific place in contract storage. The pattern
 * recommends that the hash of a specific namespace (e.g. "battlefly.storage.wasteland")
 * be used as the slot to store the struct.
 *
 * Additionally, the Diamond Storage pattern can be used to access and change state inside
 * of Library contract code (https://dev.to/mudgen/solidity-libraries-can-t-have-state-variables-oh-yes-they-can-3ke9).
 * Instead of using `LibStorage.wastelandStorage()` directly, a Library will probably
 * define a convenience function to accessing state, similar to the `gs()` function provided
 * in the `WithStorage` base contract below.
 *
 * This pattern was chosen over the AppStorage pattern (https://dev.to/mudgen/appstorage-pattern-for-state-variables-in-solidity-3lki)
 * because AppStorage seems to indicate it doesn't support additional state in contracts.
 * This becomes a problem when using base contracts that manage their own state internally.
 *
 * There are a few caveats to this approach:
 * 1. State must always be loaded through a function (`LibStorage.wastelandStorage()`)
 *    instead of accessing it as a variable directly. The `WithStorage` base contract
 *    below provides convenience functions, such as `gs()`, for accessing storage.
 * 2. Although inherited contracts can have their own state, top level contracts must
 *    ONLY use the Diamond Storage. This seems to be due to how contract inheritance
 *    calculates contract storage layout.
 * 3. The same namespace can't be used for multiple structs. However, new namespaces can
 *    be added to the contract to add additional storage structs.
 * 4. If a contract is deployed using the Diamond Storage, you must ONLY ADD fields to the
 *    very end of the struct during upgrades. During an upgrade, if any fields get added,
 *    removed, or changed at the beginning or middle of the existing struct, the
 *    entire layout of the storage will be broken.
 * 5. Avoid structs within the Diamond Storage struct, as these nested structs cannot be
 *    changed during upgrades without breaking the layout of storage. Structs inside of
 *    mappings are fine because their storage layout is different. Consider creating a new
 *    Diamond storage for each struct.
 *
 * More information on Solidity contract storage layout is available at:
 * https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html
 *
 * Nick Mudge, the author of the Diamond Pattern and creator of Diamond Storage pattern,
 * wrote about the benefits of the Diamond Storage pattern over other storage patterns at
 * https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb#bfc1
 */
library LibStorage {
    // Storage are structs where the data gets updated throughout the lifespan of Wastelands
    bytes32 constant WASTELAND_STORAGE_POSITION = keccak256("battlefly.storage.wasteland");

    function wastelandStorage() internal pure returns (WastelandStorage storage gs) {
        bytes32 position = WASTELAND_STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
}

/**
 * The `WithStorage` contract provides a base contract for Facet contracts to inherit.
 *
 * It mainly provides internal helpers to access the storage structs, which reduces
 * calls like `LibStorage.wastelandStorage()` to just `ws()`.
 *
 * To understand why the storage structs must be accessed using a function instead of a
 * state variable, please refer to the documentation above `LibStorage` in this file.
 */
contract WithStorage {
    function ws() internal pure returns (WastelandStorage storage) {
        return LibStorage.wastelandStorage();
    }
}

contract WithModifiers is WithStorage {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyGuardian() {
        if (!ws().guardian[msg.sender]) revert Errors.NotGuardian();
        _;
    }

    modifier notPaused() {
        if (ws().paused) revert Errors.WastelandsPaused();
        _;
    }
}

// SPDX-License-Identifier: MIT
/**
 * Customized version of DiamondInit.sol
 *
 * Vendored on November 16, 2021 from:
 * https://github.com/mudgen/diamond-3-hardhat/blob/7feb995/contracts/upgradeInitializers/DiamondInit.sol
 */
pragma solidity ^0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

// It is expected that this contract is customized in order to deploy a diamond with data
// from a deployment script. The init function is used to initialize state variables
// of the diamond. Add parameters to the init function if you need to.

// Interface imports
import { IDiamondLoupe } from "hardhat-deploy/solc_0.8/diamond/interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "hardhat-deploy/solc_0.8/diamond/interfaces/IDiamondCut.sol";
import { IERC173 } from "hardhat-deploy/solc_0.8/diamond/interfaces/IERC173.sol";
import { IERC165 } from "@solidstate/contracts/interfaces/IERC165.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { IERC721Metadata } from "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";
import { IERC721Enumerable } from "@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol";

// Inherited storage
import { ERC721MetadataStorage } from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";

// Library imports
import { LibDiamond } from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import { WithModifiers } from "./libraries/LibStorage.sol";

// Errors
import { Errors } from "./helpers/Errors.sol";

// Type imports
struct InitArgs {
    string landMetadataExtension;
    string landContractURI;
    string landName;
    string landSymbol;
    string landMetadataBaseURI;
    address guardian;
    address magic;
}

contract WLInit is WithModifiers {
    using ERC721MetadataStorage for ERC721MetadataStorage.Layout;

    address private immutable _facetAddress = address(this);

    event Initialized();

    // You can add parameters to this function in order to pass in
    // data to set initialize state variables
    function init(InitArgs memory initArgs) external onlyOwner {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Enumerable).interfaceId] = true;

        // Setup the ERC721 metadata
        ERC721MetadataStorage.layout().name = initArgs.landName;
        ERC721MetadataStorage.layout().symbol = initArgs.landSymbol;
        ERC721MetadataStorage.layout().baseURI = initArgs.landMetadataBaseURI;

        ws().diamondAddress = address(this);

        ws().landContractURI = initArgs.landContractURI;
        ws().landMetadataExtension = initArgs.landMetadataExtension;
        ws().guardian[initArgs.guardian] = true;
        ws().magic = initArgs.magic;
        ws().paused = true;

        // Self remove init facet
        LibDiamond.removeFunction(ds, _facetAddress, WLInit.init.selector);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}