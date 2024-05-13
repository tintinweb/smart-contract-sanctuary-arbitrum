// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {ERC165Upgradeable} from "../utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControl, ERC165Upgradeable {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;


    /// @custom:storage-location erc7201:openzeppelin.storage.AccessControl
    struct AccessControlStorage {
        mapping(bytes32 role => RoleData) _roles;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.AccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant AccessControlStorageLocation = 0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800;

    function _getAccessControlStorage() private pure returns (AccessControlStorage storage $) {
        assembly {
            $.slot := AccessControlStorageLocation
        }
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].hasRole[account];
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        return $._roles[role].adminRole;
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        bytes32 previousAdminRole = getRoleAdmin(role);
        $._roles[role].adminRole = adminRole;
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (!hasRole(role, account)) {
            $._roles[role].hasRole[account] = true;
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
        AccessControlStorage storage $ = _getAccessControlStorage();
        if (hasRole(role, account)) {
            $._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165 {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
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
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event InitializedContractData(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        uint16 totalPools,
        uint16 totalBandLevels
    );

    event PoolSet(uint16 indexed poolId, uint32 distributionPercentage);

    event BandLevelSet(
        uint16 indexed bandLevel,
        uint256 price,
        uint16[] accessiblePools
    );

    event SharesInMonthSet(uint48[] totalSharesInMonth);

    event UsdtTokenSet(IERC20 token);

    event UsdcTokenSet(IERC20 token);

    event WowTokenSet(IERC20 token);

    event TotalBandLevelsAmountSet(uint16 newTotalBandsAmount);

    event TotalPoolAmountSet(uint16 newTotalPoolAmount);

    event BandUpgradeStatusSet(bool enabled);

    event DistributionStatusSet(bool inProgress);

    event TokensWithdrawn(IERC20 token, address receiver, uint256 amount);

    event DistributionCreated(
        IERC20 token,
        uint256 amount,
        uint16 totalPools,
        uint16 totalBandLevels,
        uint256 totalStakers,
        uint256 distributionTimestamp
    );

    event RewardsDistributed(IERC20 token);

    event SharesSyncTriggered();

    event Staked(
        address user,
        uint16 bandLevel,
        uint256 bandId,
        uint8 fixedMonths,
        IStaking.StakingTypes stakingType,
        bool areTokensVested
    );

    event Unstaked(address user, uint256 bandId, bool areTokensVested);

    event VestingUserDeleted(address user);

    event BandUpgraded(
        address user,
        uint256 bandId,
        uint16 oldBandLevel,
        uint16 newBandLevel,
        uint256 newPurchasePrice
    );

    event BandDowngraded(
        address user,
        uint256 bandId,
        uint16 oldBandLevel,
        uint16 newBandLevel,
        uint256 newPurchasePrice
    );

    event RewardsClaimed(address user, IERC20 token, uint256 totalRewards);
}

interface IStaking is IStakingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum StakingTypes {
        FIX,
        FLEXI
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct StakerBand {
        uint256 purchasePrice; // The price in WOW tokens at the time of purchase (stake/downgrade/upgrade) the band
        address owner; // staker who owns the band
        uint32 stakingStartDate; // timestamp for initial band creation
        uint16 bandLevel; // band levels (1-9)
        uint8 fixedMonths; // 0 for flexi, 1-24 for fix
        StakingTypes stakingType; // FLEXI or FIX
        bool areTokensVested; // true if tokens from which the band was created are vested
    }

    struct StakerReward {
        uint256 unclaimedAmount; // amount of tokens that can be claimed
        uint256 claimedAmount; // amount of tokens that have been claimed
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 usdtToken,
        IERC20 usdcToken,
        IERC20 wowToken,
        address vesting,
        address gelato,
        uint16 totalPools,
        uint16 totalBandLevels
    ) external;

    function setPoolDistributionPercentage(
        uint16 poolId,
        uint32 distributionPercentage
    ) external;

    function setBandLevel(
        uint16 bandLevel,
        uint256 price,
        uint16[] calldata accessiblePools
    ) external;

    function setSharesInMonth(uint48[] calldata totalSharesInMonth) external;

    function setUsdtToken(IERC20 token) external;

    function setUsdcToken(IERC20 token) external;

    function setWowToken(IERC20 token) external;

    function setTotalBandLevelsAmount(uint16 newTotalBandsAmount) external;

    function setTotalPoolAmount(uint16 newTotalPoolAmount) external;

    function setBandUpgradesEnabled(bool enabled) external;

    function setDistributionInProgress(bool inProgress) external;

    function withdrawTokens(IERC20 token, uint256 amount) external;

    function createDistribution(IERC20 token, uint256 amount) external;

    function distributeRewards(
        IERC20 token,
        address[] memory stakers,
        uint256[] memory rewards
    ) external;

    function triggerSharesSync() external;

    function stake(
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    ) external;

    function unstake(uint256 bandId) external;

    function stakeVested(
        address user,
        StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month
    ) external returns (uint256 bandId);

    function unstakeVested(address user, uint256 bandId) external;

    function deleteVestingUser(address user) external;

    function upgradeBand(uint256 bandId, uint16 newBandLevel) external;

    function downgradeBand(uint256 bandId, uint16 newBandLevel) external;

    function claimRewards(IERC20 token) external;

    function getTokenUSDT() external view returns (IERC20);

    function getTokenUSDC() external view returns (IERC20);

    function getTokenWOW() external view returns (IERC20);

    function getTotalPools() external view returns (uint16);

    function getTotalBandLevels() external view returns (uint16);

    function getNextBandId() external view returns (uint256);

    function getSharesInMonthArray() external view returns (uint48[] memory);

    function getSharesInMonth(
        uint256 index
    ) external view returns (uint48 shares);

    function getPoolDistributionPercentage(
        uint16 poolId
    ) external view returns (uint32 distributionPercentage);

    function getBandLevel(
        uint16 bandLevel
    ) external view returns (uint256 price);

    function getStakerBand(
        uint256 bandId
    )
        external
        view
        returns (
            uint256 purchasePrice,
            address owner,
            uint32 stakingStartDate,
            uint16 bandLevel,
            uint8 fixedMonths,
            StakingTypes stakingType,
            bool areTokensVested
        );

    function getStakerReward(
        address staker,
        IERC20 token
    ) external view returns (uint256 unclaimedAmount, uint256 claimedAmount);

    function getStakerBandIds(
        address staker
    ) external view returns (uint256[] memory bandIds);

    function getUser(uint256 index) external view returns (address user);

    function getTotalUsers() external view returns (uint256 usersAmount);

    function areBandUpgradesEnabled() external view returns (bool enabled);

    function isDistributionInProgress() external view returns (bool inProgress);

    function getPeriodDuration() external pure returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";

interface IVestingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event AllTokensClaimed(address indexed user, uint256 tokenAmount);

    event VestingPoolAdded(
        uint16 indexed poolIndex,
        uint256 totalPoolTokenAmount
    );

    event BeneficiaryAdded(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 addedTokenAmount
    );

    event BeneficiaryRemoved(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 availableAmount
    );

    event ListingDateChanged(uint32 oldDate, uint32 newDate);

    event ContractTokensWithdrawn(
        IERC20 indexed customToken,
        address indexed recipient,
        uint256 tokenAmount
    );

    event StakingContractSet(IStaking indexed newContract);

    event TokensClaimed(
        uint16 indexed poolIndex,
        address indexed user,
        uint256 tokenAmount
    );

    event VestedTokensStaked(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 amount,
        uint256 bandId
    );

    event VestedTokensUnstaked(
        uint16 indexed poolIndex,
        address indexed beneficiary,
        uint256 amount,
        uint256 bandId
    );
}

interface IVesting is IVestingEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                       ENUMS
    //////////////////////////////////////////////////////////////////////////*/

    enum UnlockTypes {
        DAILY,
        MONTHLY
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct Beneficiary {
        uint256 totalTokenAmount;
        uint256 listingTokenAmount;
        uint256 cliffTokenAmount;
        uint256 vestedTokenAmount;
        uint256 stakedTokenAmount;
        uint256 claimedTokenAmount;
    }

    struct Pool {
        string name;
        uint16 listingPercentageDividend;
        uint16 listingPercentageDivisor;
        uint16 cliffInDays;
        uint32 cliffEndDate;
        uint16 cliffPercentageDividend;
        uint16 cliffPercentageDivisor;
        uint16 vestingDurationInMonths;
        uint16 vestingDurationInDays;
        uint32 vestingEndDate;
        UnlockTypes unlockType;
        mapping(address => Beneficiary) beneficiaries;
        uint256 totalPoolTokenAmount;
        uint256 dedicatedPoolTokenAmount;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(
        IERC20 token,
        IStaking stakingContract,
        uint32 listingDate
    ) external;

    function addVestingPool(
        string calldata name,
        uint16 listingPercentageDividend,
        uint16 listingPercentageDivisor,
        uint16 cliffInDays,
        uint16 cliffPercentageDividend,
        uint16 cliffPercentageDivisor,
        uint16 vestingDurationInMonths,
        UnlockTypes unlockType,
        uint256 totalPoolTokenAmount
    ) external;

    function addBeneficiary(
        uint16 pid,
        address beneficiary,
        uint256 tokenAmount
    ) external;

    function addMultipleBeneficiaries(
        uint16 pid,
        address[] calldata beneficiaries,
        uint256[] calldata tokenAmounts
    ) external;

    function removeBeneficiary(uint16 pid, address beneficiary) external;

    function changeListingDate(uint32 newListingDate) external;

    function setStakingContract(IStaking newStaking) external;

    function claimTokens(uint16 pid) external;

    function claimAllTokens() external;

    function stakeVestedTokens(
        IStaking.StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month,
        uint16 pid
    ) external;

    function unstakeVestedTokens(uint256 bandId) external;

    function getBeneficiary(
        uint16 pid,
        address user
    ) external view returns (Beneficiary memory);

    function getListingDate() external view returns (uint32);

    function getPoolCount() external view returns (uint16);

    function getToken() external view returns (IERC20);

    function getStakingContract() external view returns (IStaking);

    function getGeneralPoolData(
        uint16 pid
    ) external view returns (string memory, UnlockTypes, uint256, uint256);

    function getPoolListingData(
        uint16 pid
    ) external view returns (uint16, uint16);

    function getPoolCliffData(
        uint16 pid
    ) external view returns (uint32, uint16, uint16, uint16);

    function getPoolVestingData(
        uint16 pid
    ) external view returns (uint32, uint16, uint16);

    function getUnlockedTokenAmount(
        uint16 pid,
        address beneficiary
    ) external view returns (uint256 unlockedAmount);

    function getVestingPeriodsPassed(
        uint16 pid
    ) external view returns (uint16 periodsPassed, uint16 duration);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library Errors {
    error Vesting__ArraySizeMismatch();
    error Vesting__CanNotWithdrawVestedTokens();
    error Vesting__InvalidBand();
    error Vesting__ListingDateNotInFuture();
    error Vesting__ListingAndCliffPercentageOverflow();
    error Vesting__NotEnoughVestedTokensForStaking();
    error Vesting__NotBeneficiary();
    error Vesting__NoTokensUnlocked();
    error Vesting__NotEnoughStakedTokens();
    error Vesting__PercentageDivisorZero();
    error Vesting__PoolDoesNotExist();
    error Vesting__PoolWithThisNameExists();
    error Vesting__StakedTokensCanNotBeClaimed();
    error Vesting__TokenAmountExeedsTotalPoolAmount();
    error Vesting__TokenAmountZero();
    error Vesting__VestingDurationZero();
    error Vesting__UnstakingTooManyTokens();
    error Vesting__ZeroAddress();
    error Vesting__EmptyName();
    error Vesting__BeneficiaryDoesNotExist();
    error Vesting__InsufficientBalance();
    error Vesting__NotEnoughTokens();
    error Vesting__ListingDateNotChanged();
    error Vesting__NotEnoughStakedTokensForUnstaking();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IStaking} from "@wealth-of-wisdom/staking/contracts/interfaces/IStaking.sol";
import {IVesting} from "./interfaces/IVesting.sol";
import {Errors} from "./libraries/Errors.sol";

contract Vesting is IVesting, Initializable, AccessControlUpgradeable {
    /*//////////////////////////////////////////////////////////////////////////
                                    LIBRARIES  
    //////////////////////////////////////////////////////////////////////////*/

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 public constant BENEFICIARIES_MANAGER_ROLE =
        keccak256("BENEFICIARIES_MANAGER_ROLE");

    uint32 public constant DAY = 1 days;
    uint32 public constant MONTH = 30 days;

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */

    IERC20 internal s_token;

    IStaking internal s_staking;

    mapping(uint16 => Pool) internal s_vestingPools;

    mapping(uint256 bandId => uint16 poolId) internal s_stakedPools;

    uint32 internal s_listingDate;

    uint16 internal s_poolCount;

    /* solhint-enable */

    /*//////////////////////////////////////////////////////////////////////////
                                    MODIFIERS   
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks whether the address is not zero.
     */
    modifier mAddressNotZero(address addr) {
        if (addr == address(0)) {
            revert Errors.Vesting__ZeroAddress();
        }
        _;
    }

    /**
     * @notice Checks whether the address is user of the pool.
     */
    modifier mOnlyBeneficiary(uint16 pid) {
        if (!_isBeneficiaryAdded(pid, msg.sender)) {
            revert Errors.Vesting__NotBeneficiary();
        }
        _;
    }

    /**
     * @notice Checks whether the beneficiary is added to the pool.
     */
    modifier mBeneficiaryExists(uint16 pid, address beneficiary) {
        if (!_isBeneficiaryAdded(pid, beneficiary)) {
            revert Errors.Vesting__BeneficiaryDoesNotExist();
        }
        _;
    }

    /**
     * @notice Checks whether the editable vesting pool exists.
     */
    modifier mPoolExists(uint16 pid) {
        if (s_vestingPools[pid].cliffPercentageDivisor == 0) {
            revert Errors.Vesting__PoolDoesNotExist();
        }
        _;
    }

    /**
     * @notice Checks whether token amount > 0.
     */
    modifier mAmountNotZero(uint256 tokenAmount) {
        if (tokenAmount == 0) {
            revert Errors.Vesting__TokenAmountZero();
        }
        _;
    }

    /**
     * @notice Checks whether the listing date is not in the past.
     */
    modifier mValidListingDate(uint32 listingDate) {
        if (listingDate == s_listingDate) {
            revert Errors.Vesting__ListingDateNotChanged();
        }

        if (listingDate < block.timestamp) {
            revert Errors.Vesting__ListingDateNotInFuture();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract.
     * @param token ERC20 token address.
     * @param stakingContract Staking contract address (can be zero address if not set yet)
     * @param listingDate Listing date in epoch timestamp format.
     */
    function initialize(
        IERC20 token,
        IStaking stakingContract,
        uint32 listingDate
    )
        external
        initializer
        mAddressNotZero(address(token))
        mValidListingDate(listingDate)
    {
        /// @dev no validation for stakingContract is needed,
        /// @dev because if it is zero, the contract will limit some functionality

        // Effects: Initialize AccessControl
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BENEFICIARIES_MANAGER_ROLE, msg.sender);

        // Effects: Initialize storage variables
        s_token = token;
        s_staking = stakingContract;
        s_listingDate = listingDate;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          ADMIN-FACING STATE CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds new vesting pool.
     * @param name Vesting pool name.
     * @param listingPercentageDividend Percentage fractional form dividend part.
     * @param listingPercentageDivisor Percentage fractional form divisor part.
     * @param cliffInDays Period of the first lock (cliff) in days.
     * @param cliffPercentageDividend Percentage fractional form dividend part.
     * @param cliffPercentageDivisor Percentage fractional form divisor part.
     * @param vestingDurationInMonths Duration of the vesting period.
     */
    function addVestingPool(
        string calldata name,
        uint16 listingPercentageDividend,
        uint16 listingPercentageDivisor,
        uint16 cliffInDays,
        uint16 cliffPercentageDividend,
        uint16 cliffPercentageDivisor,
        uint16 vestingDurationInMonths,
        UnlockTypes unlockType,
        uint256 totalPoolTokenAmount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mAmountNotZero(totalPoolTokenAmount)
    {
        // Checks: Validate pool data before adding new vesting pool
        _validatePoolData(
            name,
            listingPercentageDivisor,
            cliffPercentageDivisor,
            listingPercentageDividend,
            cliffPercentageDividend,
            vestingDurationInMonths
        );

        uint16 pid = s_poolCount;
        Pool storage pool = s_vestingPools[pid];

        // Effects: Initialize pool variables with provided data
        // We cannot use `pool = Pool(...)` because struct contains mapping
        pool.name = name;
        pool.listingPercentageDividend = listingPercentageDividend;
        pool.listingPercentageDivisor = listingPercentageDivisor;

        pool.cliffInDays = cliffInDays;
        pool.cliffEndDate = s_listingDate + (cliffInDays * DAY);
        pool.cliffPercentageDividend = cliffPercentageDividend;
        pool.cliffPercentageDivisor = cliffPercentageDivisor;

        pool.vestingDurationInDays = vestingDurationInMonths * 30;
        pool.vestingDurationInMonths = vestingDurationInMonths;
        pool.vestingEndDate =
            pool.cliffEndDate +
            (pool.vestingDurationInDays * DAY);

        pool.unlockType = unlockType;
        pool.totalPoolTokenAmount = totalPoolTokenAmount;

        // Effects: Increment pool count
        s_poolCount++;

        // Interactions: Transfer tokens to the contract
        s_token.safeTransferFrom(
            msg.sender,
            address(this),
            totalPoolTokenAmount
        );

        // Effects: Emit event
        emit VestingPoolAdded(pid, totalPoolTokenAmount);
    }

    /**
     * @notice Adds user with token amount to vesting pool.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiary Address of the user wallet.
     * @param tokenAmount Purchased token absolute amount (with included decimals).
     */
    /* solhint-disable ordering */
    function addBeneficiary(
        uint16 pid,
        address beneficiary,
        uint256 tokenAmount
    )
        public
        onlyRole(BENEFICIARIES_MANAGER_ROLE)
        mPoolExists(pid)
        mAddressNotZero(beneficiary)
        mAmountNotZero(tokenAmount)
    {
        Pool storage pool = s_vestingPools[pid];

        // Effects: Increase locked pool token amount
        pool.dedicatedPoolTokenAmount += tokenAmount;

        // Checks: User token amount should not exceed total pool amount
        if (pool.totalPoolTokenAmount < pool.dedicatedPoolTokenAmount) {
            revert Errors.Vesting__TokenAmountExeedsTotalPoolAmount();
        }

        // Effects: update user token amounts
        Beneficiary storage user = pool.beneficiaries[beneficiary];
        user.totalTokenAmount += tokenAmount;
        user.listingTokenAmount = _getTokensByPercentage(
            user.totalTokenAmount,
            pool.listingPercentageDividend,
            pool.listingPercentageDivisor
        );
        user.cliffTokenAmount = _getTokensByPercentage(
            user.totalTokenAmount,
            pool.cliffPercentageDividend,
            pool.cliffPercentageDivisor
        );
        user.vestedTokenAmount =
            user.totalTokenAmount -
            user.listingTokenAmount -
            user.cliffTokenAmount;

        // Effects: Emit event
        emit BeneficiaryAdded(pid, beneficiary, tokenAmount);
    }

    /* solhint-enable */

    /**
     * @notice Adds addresses with purchased token amount to the user list.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiaries List of whitelisted addresses.
     * @param tokenAmounts Purchased token absolute amount (with included decimals).
     * @dev Example of parameters: ["address1","address2"], ["address1Amount", "address2Amount"].
     */
    function addMultipleBeneficiaries(
        uint16 pid,
        address[] calldata beneficiaries,
        uint256[] calldata tokenAmounts
    ) external onlyRole(BENEFICIARIES_MANAGER_ROLE) mPoolExists(pid) {
        uint256 beneficiaryCount = beneficiaries.length;

        // Checks: Array lengths should be equal
        if (beneficiaryCount != tokenAmounts.length) {
            revert Errors.Vesting__ArraySizeMismatch();
        }

        // Effects: Add users to the pool
        for (uint16 i; i < beneficiaryCount; i++) {
            addBeneficiary(pid, beneficiaries[i], tokenAmounts[i]);
        }
    }

    /**
     * @notice Removes user from the pool.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiary Address of the user wallet.
     */
    function removeBeneficiary(
        uint16 pid,
        address beneficiary
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        mPoolExists(pid)
        mBeneficiaryExists(pid, beneficiary)
    {
        Pool storage pool = s_vestingPools[pid];
        Beneficiary storage user = pool.beneficiaries[beneficiary];

        // Get unlocked amount that will be transferred to the user
        // We don't need to check whether the user has staked tokens
        // because we are unstaking all staked tokens, which means it will be 0
        uint256 availableAmount = user.totalTokenAmount -
            user.claimedTokenAmount;

        if (availableAmount > 0) {
            // Effects: Update pool dedicated token amount
            pool.dedicatedPoolTokenAmount -= availableAmount;
        }

        // Effects: Delete user from the pool
        delete pool.beneficiaries[beneficiary];

        // Interactions: delete user data from staking contract
        s_staking.deleteVestingUser(beneficiary);

        // Effects: Emit event
        emit BeneficiaryRemoved(pid, beneficiary, availableAmount);
    }

    /**
     * @notice Sets new listing date and recalculates cliff and vesting end dates for all pools.
     * @param newListingDate new listing date.
     */
    function changeListingDate(
        uint32 newListingDate
    ) external onlyRole(DEFAULT_ADMIN_ROLE) mValidListingDate(newListingDate) {
        uint32 oldListingDate = s_listingDate;
        uint16 poolCount = s_poolCount;

        // Effects: Update listing date
        s_listingDate = newListingDate;

        // Effects: update cliff and vesting end dates for all pools
        for (uint16 i; i < poolCount; i++) {
            Pool storage pool = s_vestingPools[i];
            pool.cliffEndDate = newListingDate + (pool.cliffInDays * DAY);
            pool.vestingEndDate =
                pool.cliffEndDate +
                (pool.vestingDurationInDays * DAY);
        }

        // Effects: Emit event
        emit ListingDateChanged(oldListingDate, newListingDate);
    }

    /**
     * @notice Allows admin to set new staking contract address.
     * @param newStaking Address of the new staking contract.
     */
    function setStakingContract(
        IStaking newStaking
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Effects: Set new staking contract address
        s_staking = newStaking;

        // Effects: Emit event
        emit StakingContractSet(newStaking);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS FOR BENEFICIARIES
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Function lets caller claim unlocked tokens from specified vesting pool.
     * @notice if the vesting period has ended - user is transferred all unclaimed tokens.
     * @param pid Index that refers to vesting pool object.
     */
    function claimTokens(
        uint16 pid
    ) external mPoolExists(pid) mOnlyBeneficiary(pid) {
        uint256 unlockedTokens = getUnlockedTokenAmount(pid, msg.sender);

        // Checks: At least some tokens are unlocked
        if (unlockedTokens == 0) {
            revert Errors.Vesting__NoTokensUnlocked();
        }

        // Checks: Enough tokens in the contract
        if (unlockedTokens > s_token.balanceOf(address(this))) {
            revert Errors.Vesting__NotEnoughTokens();
        }

        Pool storage pool = s_vestingPools[pid];
        Beneficiary storage user = pool.beneficiaries[msg.sender];

        // Available tokens are the maximum amount that user should be able claim
        // if all tokens are unlocked for the user,
        uint256 availableTokens = user.totalTokenAmount -
            user.claimedTokenAmount -
            user.stakedTokenAmount;

        // Checks: Unlocked tokens are not withdrawing from staked token pool
        if (unlockedTokens > availableTokens) {
            revert Errors.Vesting__StakedTokensCanNotBeClaimed();
        }

        // Effects: Update user claimed token amount
        user.claimedTokenAmount += unlockedTokens;

        // Interactions: Transfer tokens to the user
        s_token.safeTransfer(msg.sender, unlockedTokens);

        // Effects: Emit event
        emit TokensClaimed(pid, msg.sender, unlockedTokens);
    }

    /**
     * @notice Function lets caller claim all unlocked tokens from all vested pools.
     * @notice if the vesting period has ended - user is transferred all unclaimed tokens.
     */
    function claimAllTokens() external {
        uint256 allTokensToClaim;

        // Cache pool count to use in loop
        uint16 poolCount = s_poolCount;

        for (uint16 i; i < poolCount; i++) {
            uint256 unlockedTokens = getUnlockedTokenAmount(i, msg.sender);

            // Checks: At least some tokens are unlocked
            // if none - continue to other pool
            if (unlockedTokens == 0) {
                continue;
            }

            Pool storage pool = s_vestingPools[i];
            Beneficiary storage user = pool.beneficiaries[msg.sender];

            // Available tokens are the maximum amount that user should be able claim
            // if all tokens are unlocked for the user,
            uint256 availableTokens = user.totalTokenAmount -
                user.claimedTokenAmount -
                user.stakedTokenAmount;

            // Checks: Unlocked tokens are not withdrawing from staked token pool
            // if withdrawn - continue to other pool
            if (unlockedTokens > availableTokens) {
                continue;
            }

            // Effects: Update user claimed token amount
            user.claimedTokenAmount += unlockedTokens;

            allTokensToClaim += unlockedTokens;

            // Effects: Emit event
            emit TokensClaimed(i, msg.sender, unlockedTokens);
        }

        // Checks: At least some tokens are unlocked
        if (allTokensToClaim == 0) {
            revert Errors.Vesting__NoTokensUnlocked();
        }

        // Interactions: Transfer tokens to the user
        s_token.safeTransfer(msg.sender, allTokensToClaim);

        // Effects: Emit event
        emit AllTokensClaimed(msg.sender, allTokensToClaim);
    }

    /**
     * @notice Stakes vested tokesns via vesting contract in staking contract
     * @param stakingType  enumerable type for flexi or fixed staking
     * @param bandLevel  band level number (1-9)
     * @param pid Index that refers to vesting pool object.
     */
    function stakeVestedTokens(
        IStaking.StakingTypes stakingType,
        uint16 bandLevel,
        uint8 month,
        uint16 pid
    ) external mPoolExists(pid) mOnlyBeneficiary(pid) {
        Beneficiary storage user = s_vestingPools[pid].beneficiaries[
            msg.sender
        ];

        // Cache staking contract
        IStaking staking = s_staking;

        uint256 bandPrice = staking.getBandLevel(bandLevel);

        // Checks: Enough unstaked tokens in the contract
        if (
            bandPrice >
            user.totalTokenAmount -
                user.stakedTokenAmount -
                user.claimedTokenAmount
        ) {
            revert Errors.Vesting__NotEnoughVestedTokensForStaking();
        }

        // Effects: Stake tokens
        user.stakedTokenAmount += bandPrice;

        // Interactions: Stake tokens in staking contract
        uint256 bandId = staking.stakeVested(
            msg.sender,
            stakingType,
            bandLevel,
            month
        );

        // Effects: Update staked pool id
        s_stakedPools[bandId] = pid;

        // Effects: Emit event
        emit VestedTokensStaked(pid, msg.sender, bandPrice, bandId);
    }

    /**
     * @notice Unstakes vested tokesns via vesting contract in staking contract
     * @param bandId  Id of the band (0-max uint)
     */
    function unstakeVestedTokens(
        uint256 bandId
    ) external mBeneficiaryExists(s_stakedPools[bandId], msg.sender) {
        uint16 pid = s_stakedPools[bandId];

        // Cache staking contract
        IStaking staking = s_staking;

        Pool storage pool = s_vestingPools[pid];
        Beneficiary storage user = pool.beneficiaries[msg.sender];

        (uint256 purchasePrice, , , , , , ) = staking.getStakerBand(bandId);

        // Checks: Enough staked tokens in the contract
        if (purchasePrice > user.stakedTokenAmount) {
            revert Errors.Vesting__NotEnoughStakedTokensForUnstaking();
        }

        // Effects: Unstake tokens
        user.stakedTokenAmount -= purchasePrice;

        // Effects: Delete staked info
        delete s_stakedPools[bandId];

        // Interactions: Unstake tokens in staking contract
        staking.unstakeVested(msg.sender, bandId);

        // Effects: Emit event
        emit VestedTokensUnstaked(pid, msg.sender, purchasePrice, bandId);
    }

    /*//////////////////////////////////////////////////////////////////////////
                          EXTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Get user details for pool.
     * @param pid Index that refers to vesting pool object.
     * @param user Address of the beneficiary wallet.
     * @return Beneficiary structure information.
     */
    function getBeneficiary(
        uint16 pid,
        address user
    ) external view returns (Beneficiary memory) {
        return s_vestingPools[pid].beneficiaries[user];
    }

    /**
     * @notice Return global listing date value (in epoch timestamp format).
     * @return listing date.
     */
    function getListingDate() external view returns (uint32) {
        return s_listingDate;
    }

    /**
     * @notice Return number of pools in contract.
     * @return pool count.
     */
    function getPoolCount() external view returns (uint16) {
        return s_poolCount;
    }

    /**
     * @notice Return claimable token address
     * @return IERC20 token.
     */
    function getToken() external view returns (IERC20) {
        return s_token;
    }

    /**
     * @notice Return staking contract address
     * @return staking contract address.
     */
    function getStakingContract() external view returns (IStaking) {
        return s_staking;
    }

    /**
     * @notice Return pool data.
     * @param pid Index that refers to vesting pool object.
     * @return Pool name
     * @return Unlock type
     * @return Total pool token amount
     * @return Locked pool token amount
     */
    function getGeneralPoolData(
        uint16 pid
    ) external view returns (string memory, UnlockTypes, uint256, uint256) {
        Pool storage pool = s_vestingPools[pid];
        return (
            pool.name,
            pool.unlockType,
            pool.totalPoolTokenAmount,
            pool.dedicatedPoolTokenAmount
        );
    }

    /**
     * @notice Return pool listing data.
     * @param pid Index that refers to vesting pool object.
     * @return listing percentage dividend
     * @return listing percentage divisor
     */
    function getPoolListingData(
        uint16 pid
    ) external view returns (uint16, uint16) {
        Pool storage pool = s_vestingPools[pid];
        return (pool.listingPercentageDividend, pool.listingPercentageDivisor);
    }

    /**
     * @notice Return pool cliff data.
     * @param pid Index that refers to vesting pool object.
     * @return cliff end date
     * @return cliff in days
     * @return cliff percentage dividend
     * @return cliff percentage divisor
     */
    function getPoolCliffData(
        uint16 pid
    ) external view returns (uint32, uint16, uint16, uint16) {
        Pool storage pool = s_vestingPools[pid];
        return (
            pool.cliffEndDate,
            pool.cliffInDays,
            pool.cliffPercentageDividend,
            pool.cliffPercentageDivisor
        );
    }

    /**
     * @notice Return pool vesting data.
     * @param pid Index that refers to vesting pool object.
     * @return vesting end date
     * @return vesting duration in months
     * @return vesting duration in days
     */
    function getPoolVestingData(
        uint16 pid
    ) external view returns (uint32, uint16, uint16) {
        Pool storage pool = s_vestingPools[pid];
        return (
            pool.vestingEndDate,
            pool.vestingDurationInMonths,
            pool.vestingDurationInDays
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates unlocked and unclaimed tokens based on the days passed.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiary Address of the user wallet.
     * @return unlockedAmount total unlocked and unclaimed tokens.
     */
    function getUnlockedTokenAmount(
        uint16 pid,
        address beneficiary
    ) public view returns (uint256 unlockedAmount) {
        if (!_isBeneficiaryAdded(pid, beneficiary)) {
            return 0;
        }

        Pool storage pool = s_vestingPools[pid];
        Beneficiary storage user = pool.beneficiaries[beneficiary];

        if (block.timestamp >= s_listingDate) {
            if (block.timestamp < pool.cliffEndDate) {
                // Cliff period has not ended yet. Unlocked listing tokens.
                unlockedAmount =
                    user.listingTokenAmount -
                    user.claimedTokenAmount;
            } else if (block.timestamp < pool.vestingEndDate) {
                // Cliff period has ended. Calculate vested tokens.
                (
                    uint16 periodsPassed,
                    uint16 duration
                ) = getVestingPeriodsPassed(pid);

                // Listing + Cliff + Vested - Claimed
                unlockedAmount =
                    user.listingTokenAmount +
                    user.cliffTokenAmount +
                    ((user.vestedTokenAmount * periodsPassed) / duration) -
                    user.claimedTokenAmount;
            } else {
                // Vesting period has ended. Unlocked all tokens.
                unlockedAmount =
                    user.totalTokenAmount -
                    user.claimedTokenAmount;
            }
        }
        // Else: Listing date has not come yet. unlockedAmount is 0 by default.
    }

    /**
     * @notice Calculates how many full days or months have passed since the cliff end.
     * @param pid Index that refers to vesting pool object.
     * @return periodsPassed If unlock type is daily: number of days passed, else: number of months passed.
     * @return duration If unlock type is daily: vesting duration in days, else: in months.
     */

    function getVestingPeriodsPassed(
        uint16 pid
    ) public view returns (uint16 periodsPassed, uint16 duration) {
        Pool storage pool = s_vestingPools[pid];

        // Default value for duration is vesting duration in months
        duration = pool.unlockType == UnlockTypes.DAILY
            ? pool.vestingDurationInDays
            : pool.vestingDurationInMonths;

        if (block.timestamp >= pool.cliffEndDate) {
            periodsPassed = uint16(
                (block.timestamp - pool.cliffEndDate) /
                    (pool.unlockType == UnlockTypes.DAILY ? DAY : MONTH)
            );
        }

        // periodsPassed by default is 0 if cliff has not ended yet
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INTERNAL VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Validates pool data before adding new vesting pool.
     * @param name Vesting pool name.
     * @param listingPercentageDivisor Percentage fractional form divisor part.
     * @param cliffPercentageDivisor Percentage fractional form divisor part.
     * @param listingPercentageDividend Percentage fractional form dividend part.
     * @param cliffPercentageDividend Percentage fractional form dividend part.
     */
    function _validatePoolData(
        string calldata name,
        uint16 listingPercentageDivisor,
        uint16 cliffPercentageDivisor,
        uint16 listingPercentageDividend,
        uint16 cliffPercentageDividend,
        uint16 vestingDurationInMonths
    ) internal view {
        if (bytes(name).length == 0) {
            revert Errors.Vesting__EmptyName();
        }

        uint16 poolCount = s_poolCount;
        bytes32 nameHash = keccak256(abi.encodePacked(name));

        for (uint16 i; i < poolCount; i++) {
            if (
                keccak256(abi.encodePacked(s_vestingPools[i].name)) == nameHash
            ) {
                revert Errors.Vesting__PoolWithThisNameExists();
            }
        }

        if (listingPercentageDivisor == 0 || cliffPercentageDivisor == 0) {
            revert Errors.Vesting__PercentageDivisorZero();
        }

        if (
            (listingPercentageDividend * cliffPercentageDivisor) +
                (cliffPercentageDividend * listingPercentageDivisor) >
            (listingPercentageDivisor * cliffPercentageDivisor)
        ) {
            revert Errors.Vesting__ListingAndCliffPercentageOverflow();
        }

        if (vestingDurationInMonths == 0) {
            revert Errors.Vesting__VestingDurationZero();
        }
    }

    /**
     * @notice Checks whether the beneficiary exists in the pool.
     * @param pid Index that refers to vesting pool object.
     * @param beneficiary Address of the user wallet.
     * @return true if beneficiary exists in the pool, else false.
     */
    function _isBeneficiaryAdded(
        uint16 pid,
        address beneficiary
    ) internal view returns (bool) {
        return
            s_vestingPools[pid].beneficiaries[beneficiary].totalTokenAmount !=
            0;
    }

    /**
     * @notice Calculate token amount based on the provided prcentage.
     * @param totalAmount Token amount which will be used for percentage calculation.
     * @param dividend The number from which total amount will be multiplied.
     * @param divisor The number from which total amount will be divided.
     */
    function _getTokensByPercentage(
        uint256 totalAmount,
        uint16 dividend,
        uint16 divisor
    ) internal pure returns (uint256) {
        if (divisor == 0) {
            revert Errors.Vesting__PercentageDivisorZero();
        }

        return (totalAmount * dividend) / divisor;
    }
}