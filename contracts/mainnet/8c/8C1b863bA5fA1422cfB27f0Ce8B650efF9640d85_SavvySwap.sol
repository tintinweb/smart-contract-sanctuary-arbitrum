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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice An error used to indicate that an argument passed to a function is illegal or
///         inappropriate.
///
/// @param message The error message.
error IllegalArgumentWithReason(string message);

/// @notice An error used to indicate that a function has encountered an unrecoverable state.
///
/// @param message The error message.
error IllegalStateWithReason(string message);

/// @notice An error used to indicate that an operation is unsupported.
///
/// @param message The error message.
error UnsupportedOperationWithReason(string message);

/// @notice An error used to indicate that a message sender tried to execute a privileged function.
///
/// @param message The error message.
error UnauthorizedWithReason(string message);

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../base/Errors.sol";
import "../libraries/Sets.sol";

/// @title  Allowlist
/// @author Savvy DeFi
interface IAllowlist {
    /// @dev Emitted when a contract is added to the allowlist.
    ///
    /// @param account The account that was added to the allowlist.
    event AccountAdded(address account);

    /// @dev Emitted when a contract is removed from the allowlist.
    ///
    /// @param account The account that was removed from the allowlist.
    event AccountRemoved(address account);

    /// @dev Emitted when the allowlist is deactivated.
    event AllowlistDisabled();

    /// @dev Returns the list of addresses that are allowlisted for the given contract address.
    ///
    /// @return addresses The addresses that are allowlisted to interact with the given contract.
    function getAddresses() external view returns (address[] memory addresses);

    /// @dev Returns the disabled status of a given allowlist.
    ///
    /// @return disabled A flag denoting if the given allowlist is disabled.
    function disabled() external view returns (bool);

    /// @dev Adds an contract to the allowlist.
    ///
    /// @param caller The address to add to the allowlist.
    function add(address caller) external;

    /// @dev Adds a contract to the allowlist.
    ///
    /// @param caller The address to remove from the allowlist.
    function remove(address caller) external;

    /// @dev Disables the allowlist of the target allowlisted contract.
    ///
    /// This can only occur once. Once the allowlist is disabled, then it cannot be reenabled.
    function disable() external;

    /// @dev Checks that the `msg.sender` is allowlisted when it is not an EOA.
    ///
    /// @param account The account to check.
    ///
    /// @return allowlisted A flag denoting if the given account is allowlisted.
    function isAllowed(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./IERC20Minimal.sol";

/// @title  IERC20Burnable
/// @author Savvy DeFi
interface IERC20Burnable is IERC20Minimal {
    /// @notice Burns `amount` tokens from the balance of `msg.sender`.
    ///
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burn(uint256 amount) external returns (bool);

    /// @notice Burns `amount` tokens from `owner`'s balance.
    ///
    /// @param owner  The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burnFrom(address owner, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  IERC20Metadata
/// @author Savvy DeFi
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  IERC20Minimal
/// @author Savvy DeFi
interface IERC20Minimal {
    /// @notice An event which is emitted when tokens are transferred between two parties.
    ///
    /// @param owner     The owner of the tokens from which the tokens were transferred.
    /// @param recipient The recipient of the tokens to which the tokens were transferred.
    /// @param amount    The amount of tokens which were transferred.
    event Transfer(
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );

    /// @notice An event which is emitted when an approval is made.
    ///
    /// @param owner   The address which made the approval.
    /// @param spender The address which is allowed to transfer tokens on behalf of `owner`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Gets the current total supply of tokens.
    ///
    /// @return The total supply.
    function totalSupply() external view returns (uint256);

    /// @notice Gets the balance of tokens that an account holds.
    ///
    /// @param account The account address.
    ///
    /// @return The balance of the account.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Gets the allowance that an owner has allotted for a spender.
    ///
    /// @param owner   The owner address.
    /// @param spender The spender address.
    ///
    /// @return The number of tokens that `spender` is allowed to transfer on behalf of `owner`.
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
    ///
    /// @notice Emits a {Transfer} event.
    ///
    /// @param recipient The address which will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Approves `spender` to transfer `amount` tokens on behalf of `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    ///
    /// @param spender The address which is allowed to transfer tokens on behalf of `msg.sender`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    ///
    /// @return If the approval was successful.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `owner` to `recipient` using an approval that `owner` gave to `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    /// @notice Emits a {Transfer} event.
    ///
    /// @param owner     The address to transfer tokens from.
    /// @param recipient The address that will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transferFrom(
        address owner,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./IERC20Minimal.sol";

/// @title  IERC20Mintable
/// @author Savvy DeFi
interface IERC20Mintable is IERC20Minimal {
    /// @notice Mints `amount` tokens to `recipient`.
    ///
    /// @param recipient The address which will receive the minted tokens.
    /// @param amount    The amount of tokens to mint.
    ///
    /// @return If minting the tokens was successful.
    function mint(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  IERC20TokenReceiver
/// @author Savvy DeFi
interface IERC20TokenReceiver {
    /// @notice Informs implementors of this interface that an ERC20 token has been transferred.
    ///
    /// @param token The token that was transferred.
    /// @param value The amount of the token that was transferred.
    function onERC20Received(address token, uint256 value) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./savvy/ISavvyActions.sol";
import "./savvy/ISavvyAdminActions.sol";
import "./savvy/ISavvyErrors.sol";
import "./savvy/ISavvyImmutables.sol";
import "./savvy/ISavvyEvents.sol";
import "./savvy/ISavvyState.sol";

/// @title  ISavvyPositionManager
/// @author Savvy DeFi
interface ISavvyPositionManager is
    ISavvyActions,
    ISavvyAdminActions,
    ISavvyErrors,
    ISavvyImmutables,
    ISavvyEvents,
    ISavvyState
{

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./savvy/ISavvyTokenParams.sol";
import "./savvy/ISavvyErrors.sol";
import "./savvy/ISavvyEvents.sol";
import "./savvy/ISavvyAdminActions.sol";
import "./savvy/IYieldStrategyManagerStates.sol";
import "./savvy/IYieldStrategyManagerActions.sol";
import "../libraries/Limiters.sol";

/// @title  IYieldStrategyManager
/// @author Savvy DeFi
interface IYieldStrategyManager is
    ISavvyTokenParams,
    ISavvyErrors,
    ISavvyEvents,
    IYieldStrategyManagerStates,
    IYieldStrategyManagerActions
{

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyActions
/// @author Savvy DeFi
///
/// @notice Specifies user actions.
interface ISavvyActions {
    /// @notice Approve `spender` to borrow `amount` debt tokens.
    ///
    /// **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @param spender The address that will be approved to borrow.
    /// @param amount  The amount of tokens that `spender` will be allowed to borrow.
    function approveBorrow(address spender, uint256 amount) external;

    /// @notice Approve `spender` to withdraw `amount` shares of `yieldToken`.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @param spender    The address that will be approved to withdraw.
    /// @param yieldToken The address of the yield token that `spender` will be allowed to withdraw.
    /// @param shares     The amount of shares that `spender` will be allowed to withdraw.
    function approveWithdraw(
        address spender,
        address yieldToken,
        uint256 shares
    ) external;

    /// @notice Synchronizes the state of the account owned by `owner`.
    ///
    /// @param owner The owner of the account to synchronize.
    function syncAccount(address owner) external;

    /// @notice Deposit an base token into the account of `recipient` as `yieldToken`.
    ///
    /// @notice An approval must be set for the base token of `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    /// @notice **_NOTE:_** When depositing, the `SavvyPositionManager` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **baseToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amount = 50000;
    /// @notice SavvyPositionManager(savvyAddress).depositBaseToken(mooAaveDAI, amount, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to wrap the base tokens into.
    /// @param amount           The amount of the base token to deposit.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of yield tokens that are expected to be deposited to `recipient`.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function depositBaseToken(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesIssued);

    /// @notice Deposit a yield token into a user's account.
    ///
    /// @notice An approval must be set for `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` base token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **_NOTE:_** When depositing, the `SavvyPositionManager` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **yieldToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amount = 50000;
    /// @notice IERC20(mooAaveDAI).approve(savvyAddress, amount);
    /// @notice SavvyPositionManager(savvyAddress).depositYieldToken(mooAaveDAI, amount, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The yield-token to deposit.
    /// @param amount     The amount of yield tokens to deposit.
    /// @param recipient  The owner of the account that will receive the resulting shares.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function depositYieldToken(
        address yieldToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 sharesIssued);

    /// @notice Withdraw amount yield tokens to recipient The number of yield tokens withdrawn to `recipient` will depend on the value of shares for that yield token at the time of the call.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 pps = SavvyPositionManager(savvyAddress).getYieldTokensPerShare(mooAaveDAI);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice SavvyPositionManager(savvyAddress).withdrawYieldToken(mooAaveDAI, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdrawYieldToken(
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw yield tokens to `recipient` by burning `share` shares from the account of `owner`
    ///
    /// @notice `owner` must have an withdrawal allowance which is greater than `amount` for this call to succeed.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 pps = SavvyPositionManager(savvyAddress).getYieldTokensPerShare(mooAaveDAI);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice SavvyPositionManager(savvyAddress).withdrawFrom(msg.sender, mooAaveDAI, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param owner      The address of the account owner to withdraw from.
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdrawYieldTokenFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw base tokens to `recipient` by burning `share` shares and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    /// @notice **_NOTE:_** The caller of `withdrawYieldTokenFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 pps = SavvyPositionManager(savvyAddress).getBaseTokensPerShare(mooAaveDAI);
    /// @notice uint256 amountBaseTokens = 5000;
    /// @notice SavvyPositionManager(savvyAddress).withdrawUnderlying(mooAaveDAI, amountBaseTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of base tokens that were withdrawn to `recipient`.
    function withdrawBaseToken(
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw base tokens to `recipient` by burning `share` shares from the account of `owner` and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    /// @notice **_NOTE:_** The caller of `withdrawYieldTokenFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 pps = SavvyPositionManager(savvyAddress).getBaseTokensPerShare(mooAaveDAI);
    /// @notice uint256 amtBaseTokens = 5000 * 10**mooAaveDAI.decimals();
    /// @notice SavvyPositionManager(savvyAddress).withdrawUnderlying(msg.sender, mooAaveDAI, amtBaseTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param owner            The address of the account owner to withdraw from.
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of base tokens that were withdrawn to `recipient`.
    function withdrawBaseTokenFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice borrow `amount` debt tokens to recipient.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Borrow} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice SavvyPositionManager(savvyAddress).borrowCredit(amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to borrow.
    /// @param recipient The address of the recipient.
    function borrowCredit(uint256 amount, address recipient) external;

    /// @notice Borrow `amount` debt tokens from the account owned by `owner` to `recipient`.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Borrow} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    /// @notice **_NOTE:_** The caller of `borrowFrom()` must have **borrowAllowance()** to borrow debt from the `Account` controlled by **owner** for at least the amount of **yieldTokens** that **shares** will be converted to.  This can be done via the `approveBorrow()` or `permitBorrow()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice SavvyPositionManager(savvyAddress).borrowFrom(msg.sender, amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param owner     The address of the owner of the account to borrow from.
    /// @param amount    The amount of tokens to borrow.
    /// @param recipient The address of the recipient.
    function borrowCreditFrom(
        address owner,
        uint256 amount,
        address recipient
    ) external;

    /// @notice Burn `amount` debt tokens to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must have non-zero debt or this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Burn} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtBurn = 5000;
    /// @notice SavvyPositionManager(savvyAddress).repayWithDebtToken(amtBurn, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to burn.
    /// @param recipient The address of the recipient.
    ///
    /// @return amountBurned The amount of tokens that were burned.
    function repayWithDebtToken(
        uint256 amount,
        address recipient
    ) external returns (uint256 amountBurned);

    /// @notice Repay `amount` debt using `baseToken` to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `baseToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `amount` must be less than or equal to the current available repay limit or this call will revert with a {ReplayLimitExceeded} error.
    ///
    /// @notice Emits a {Repay} event.
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address dai = 0x6b175474e89094c44da98b954eedeac495271d0f;
    /// @notice uint256 amtRepay = 5000;
    /// @notice SavvyPositionManager(savvyAddress).repayWithBaseToken(dai, amtRepay, msg.sender);
    /// @notice ```
    ///
    /// @param baseToken The address of the base token to repay.
    /// @param amount          The amount of the base token to repay.
    /// @param recipient       The address of the recipient which will receive credit.
    ///
    /// @return amountRepaid The amount of tokens that were repaid.
    function repayWithBaseToken(
        address baseToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 amountRepaid);

    /// @notice
    ///
    /// @notice `shares` will be limited up to an equal amount of debt that `recipient` currently holds.
    ///
    /// @notice `shares` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` base token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    /// @notice `amount` must be less than or equal to the current available repayWithCollateral limit or this call will revert with a {RepayWithCollateralLimitExceeded} error.
    ///
    /// @notice Emits a {RepayWithCollateral} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amtRepayWithCollateral = 5000 * 10**mooAaveDAI.decimals();
    /// @notice SavvyPositionManager(savvyAddress).repayWithCollateral(mooAaveDAI, amtRepayWithCollateral, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to repayWithCollateral.
    /// @param shares           The number of shares to burn for credit.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be repaidWithCollateral.
    ///
    /// @return sharesRepaidWithCollateral The amount of shares that were repaidWithCollateral.
    function repayWithCollateral(
        address yieldToken,
        uint256 shares,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesRepaidWithCollateral);

    /// @notice Burns `amount` debt tokens to credit accounts which have deposited `yieldToken`.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {Donate} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amtRepayWithCollateral = 5000;
    /// @notice SavvyPositionManager(savvyAddress).repayWithCollateral(dai, amtRepayWithCollateral, 1);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to credit accounts for.
    /// @param amount     The amount of debt tokens to burn.
    function donate(address yieldToken, uint256 amount) external;

    /// @notice Harvests outstanding yield that a yield token has accumulated and distributes it as credit to holders.
    ///
    /// @notice `msg.sender` must be a keeper or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The amount being harvested must be greater than zero or else this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Harvest} event.
    ///
    /// @param yieldToken       The address of the yield token to harvest.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be withdrawn to `recipient`.
    function harvest(address yieldToken, uint256 minimumAmountOut) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyAdminActions
/// @author Savvy DeFi
///
/// @notice Specifies admin and/or sentinel actions.
/// @notice Used by SavvyPositionManager
interface ISavvyAdminActions {
    /// @notice Contract initialization parameters.
    struct InitializationParams {
        // The initial admin account.
        address admin;
        // The ERC20 token used to represent debt.
        address debtToken;
        // The initial savvySage or savvySage buffer.
        address savvySage;
        // The address of giving rewards to users.
        address svyBooster;
        // The address of SavvyPriceFeed contract.
        address svyPriceFeed;
        // The redlist is active.
        bool redlistActive;
        // The address of Redlist contract.
        address savvyRedlist;
        // The address of YieldStrategyManager contract.
        address yieldStrategyManager;
        // The minimum collateralization ratio that an account must maintain.
        uint256 minimumCollateralization;
        // The percentage fee taken from each harvest measured in units of basis points.
        uint256 protocolFee;
        // The address that receives protocol fees.
        address protocolFeeReceiver;
        // A limit used to prevent administrators from making borrowing functionality inoperable.
        uint256 borrowingLimitMinimum;
        // The maximum number of tokens that can be borrowed per period of time.
        uint256 borrowingLimitMaximum;
        // The number of blocks that it takes for the borrowing limit to be refreshed.
        uint256 borrowingLimitBlocks;
        // The address of the allowlist.
        address allowlist;
        // Base base token to calculate token price.
        address baseToken;
        /// The address of WrapTokenGateway contract.
        address wrapTokenGateway;
    }

    /// @notice Configuration parameters for an base token.
    struct BaseTokenConfig {
        // A limit used to prevent administrators from making repayment functionality inoperable.
        uint256 repayLimitMinimum;
        // The maximum number of base tokens that can be repaid per period of time.
        uint256 repayLimitMaximum;
        // The number of blocks that it takes for the repayment limit to be refreshed.
        uint256 repayLimitBlocks;
        // A limit used to prevent administrators from making repayWithCollateral functionality inoperable.
        uint256 repayWithCollateralLimitMinimum;
        // The maximum number of base tokens that can be repaidWithCollateral per period of time.
        uint256 repayWithCollateralLimitMaximum;
        // The number of blocks that it takes for the repayWithCollateral limit to be refreshed.
        uint256 repayWithCollateralLimitBlocks;
    }

    /// @notice Configuration parameters of a yield token.
    struct YieldTokenConfig {
        // The adapter used by the system to interop with the token.
        address adapter;
        // The maximum percent loss in expected value that can occur before certain actions are disabled.
        // Measured in units of basis points.
        uint256 maximumLoss;
        // The maximum value that can be held by the system before certain actions are disabled.
        //  measured in the base token.
        uint256 maximumExpectedValue;
        // The number of blocks that credit will be distributed over to depositors.
        uint256 creditUnlockBlocks;
    }

    /// @notice Initialize the contract.
    ///
    /// @notice `params.protocolFee` must be in range or this call will with an {IllegalArgument} error.
    /// @notice The borrowing growth limiter parameters must be valid or this will revert with an {IllegalArgument} error. For more information, see the {Limiters} library.
    ///
    /// @notice Emits an {AdminUpdated} event.
    /// @notice Emits a {SavvySageUpdated} event.
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    /// @notice Emits a {ProtocolFeeUpdated} event.
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    /// @notice Emits a {BorrowingLimitUpdated} event.
    ///
    /// @param params The contract initialization parameters.
    function initialize(InitializationParams calldata params) external;

    /// @notice Sets the pending administrator.
    ///
    /// @notice `msg.sender` must be the pending admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {PendingAdminUpdated} event.
    ///
    /// @dev This is the first step in the two-step process of setting a new administrator. After this function is called, the pending administrator will then need to call {acceptAdmin} to complete the process.
    ///
    /// @param value the address to set the pending admin to.
    function setPendingAdmin(address value) external;

    /// @notice Allows for `msg.sender` to accepts the role of administrator.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice The current pending administrator must be non-zero or this call will revert with an {IllegalState} error.
    ///
    /// @dev This is the second step in the two-step process of setting a new administrator. After this function is successfully called, this pending administrator will be reset and the new administrator will be set.
    ///
    /// @notice Emits a {AdminUpdated} event.
    /// @notice Emits a {PendingAdminUpdated} event.
    function acceptAdmin() external;

    /// @notice Sets an address as a sentinel.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param sentinel The address to set or unset as a sentinel.
    /// @param flag     A flag indicating of the address should be set or unset as a sentinel.
    function setSentinel(address sentinel, bool flag) external;

    /// @notice Sets an address as a keeper.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param keeper The address to set or unset as a keeper.
    /// @param flag   A flag indicating of the address should be set or unset as a keeper.
    function setKeeper(address keeper, bool flag) external;

    /// @notice Sets the redlist to active or not.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param flag A flag indicating if the redlist should be active or not.
    function setRedlistActive(bool flag) external;

    /// @notice Sets the requiring protocol token active or not.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param flag A flag indicating if the protocolTokenRequired should be active or not.
    function setProtocolTokenRequiredActive(bool flag) external;

    /// @notice Adds an base token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param baseToken The address of the base token to add.
    /// @param config          The initial base token configuration.
    function addBaseToken(
        address baseToken,
        BaseTokenConfig calldata config
    ) external;

    /// @notice Adds a yield token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {AddYieldToken} event.
    /// @notice Emits a {TokenAdapterUpdated} event.
    /// @notice Emits a {MaximumLossUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to add.
    /// @param config     The initial yield token configuration.
    function addYieldToken(
        address yieldToken,
        YieldTokenConfig calldata config
    ) external;

    /// @notice Sets an base token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `baseToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits an {BaseTokenEnabled} event.
    ///
    /// @param baseToken The address of the base token to enable or disable.
    /// @param enabled         If the base token should be enabled or disabled.
    function setBaseTokenEnabled(address baseToken, bool enabled) external;

    /// @notice Sets a yield token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {YieldTokenEnabled} event.
    ///
    /// @param yieldToken The address of the yield token to enable or disable.
    /// @param enabled    If the base token should be enabled or disabled.
    function setYieldTokenEnabled(address yieldToken, bool enabled) external;

    /// @notice Configures the the repay limit of `baseToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `baseToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {ReplayLimitUpdated} event.
    ///
    /// @param baseToken The address of the base token to configure the repay limit of.
    /// @param maximum         The maximum repay limit.
    /// @param blocks          The number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    function configureRepayLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configure the repayWithCollateral limiter of `baseToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `baseToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {RepayWithCollateralLimitUpdated} event.
    ///
    /// @param baseToken The address of the base token to configure the repayWithCollateral limit of.
    /// @param maximum         The maximum repayWithCollateral limit.
    /// @param blocks          The number of blocks it will take for the maximum repayWithCollateral limit to be replenished when it is completely exhausted.
    function configureRepayWithCollateralLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Set the address of the savvySage.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {SavvySageUpdated} event.
    ///
    /// @param savvySage The address of the savvySage.
    function setSavvySage(address savvySage) external;

    /// @notice Set the minimum collateralization ratio.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    ///
    /// @param value The new minimum collateralization ratio.
    function setMinimumCollateralization(uint256 value) external;

    /// @notice Sets the fee that the protocol will take from harvests.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be in range or this call will with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeUpdated} event.
    ///
    /// @param value The value to set the protocol fee to measured in basis points.
    function setProtocolFee(uint256 value) external;

    /// @notice Sets the address which will receive protocol fees.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    ///
    /// @param value The address to set the protocol fee receiver to.
    function setProtocolFeeReceiver(address value) external;

    /// @notice Configures the borrowing limiter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {BorrowingLimitUpdated} event.
    ///
    /// @param maximum The maximum borrowing limit.
    /// @param blocks  The number of blocks it will take for the maximum borrowing limit to be replenished when it is completely exhausted.
    function configureBorrowingLimit(uint256 maximum, uint256 blocks) external;

    /// @notice Sets the rate at which credit will be completely available to depositors after it is harvested.
    ///
    /// @notice Emits a {CreditUnlockRateUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the credit unlock rate for.
    /// @param blocks     The number of blocks that it will take before the credit will be unlocked.
    function configureCreditUnlockRate(
        address yieldToken,
        uint256 blocks
    ) external;

    /// @notice Sets the token adapter of a yield token.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The token that `adapter` supports must be `yieldToken` or this call will revert with a {IllegalState} error.
    ///
    /// @notice Emits a {TokenAdapterUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the adapter for.
    /// @param adapter    The address to set the token adapter to.
    function setTokenAdapter(address yieldToken, address adapter) external;

    /// @notice Sets the maximum expected value of a yield token that the system can hold.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param yieldToken The address of the yield token to set the maximum expected value for.
    /// @param value      The maximum expected value of the yield token denoted measured in its base token.
    function setMaximumExpectedValue(
        address yieldToken,
        uint256 value
    ) external;

    /// @notice Sets the maximum loss that a yield bearing token will permit before restricting certain actions.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev There are two types of loss of value for yield bearing tokens: temporary or permanent. The system will automatically restrict actions which are sensitive to both forms of loss when detected. For example, deposits must be restricted when an excessive loss is encountered to prevent users from having their collateral harvested from them. While the user would receive credit, which then could be exchanged for value equal to the collateral that was harvested from them, it is seen as a negative user experience because the value of their collateral should have been higher than what was originally recorded when they made their deposit.
    ///
    /// @param yieldToken The address of the yield bearing token to set the maximum loss for.
    /// @param value      The value to set the maximum loss to. This is in units of basis points.
    function setMaximumLoss(address yieldToken, uint256 value) external;

    /// @notice Snap the expected value `yieldToken` to the current value.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev This function should only be used in the event of a loss in the target yield-token. For example, say a third-party protocol experiences a fifty percent loss. The expected value (amount of base tokens) of the yield tokens being held by the system would be two times the real value that those yield tokens could be redeemed for. This function gives governance a way to realize those losses so that users can continue using the token as normal.
    ///
    /// @param yieldToken The address of the yield token to snap.
    function snap(address yieldToken) external;

    /// @notice Sweep all of 'rewardtoken' from the savvy into the admin.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `rewardToken` must not be a yield or base token or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param rewardToken The address of the reward token to snap.
    /// @param amount The amount of 'rewardToken' to sweep to the admin.
    function sweepTokens(address rewardToken, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyErrors
/// @author Savvy DeFi
///
/// @notice Specifies errors.
interface ISavvyErrors {
    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that the system did not recognize.
    ///
    /// @param token The address of the token.
    error UnsupportedToken(address token);

    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that has been disabled.
    ///
    /// @param token The address of the token.
    error TokenDisabled(address token);

    /// @notice An error which is used to indicate that an operation failed because an account became undercollateralized.
    error Undercollateralized();

    /// @notice An error which is used to indicate that an operation failed because the expected value of a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param expectedValue        The expected value measured in units of the base token.
    /// @param maximumExpectedValue The maximum expected value permitted measured in units of the base token.
    error ExpectedValueExceeded(
        address yieldToken,
        uint256 expectedValue,
        uint256 maximumExpectedValue
    );

    /// @notice An error which is used to indicate that an operation failed because the loss that a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param loss        The amount of loss measured in basis points.
    /// @param maximumLoss The maximum amount of loss permitted measured in basis points.
    error LossExceeded(address yieldToken, uint256 loss, uint256 maximumLoss);

    /// @notice An error which is used to indicate that a borrowing operation failed because the borrowing limit has been exceeded.
    ///
    /// @param amount    The amount of debt tokens that were requested to be borrowed.
    /// @param available The amount of debt tokens which are available to borrow.
    error BorrowingLimitExceeded(uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the repay limit for an base token has been exceeded.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of base tokens that were requested to be repaid.
    /// @param available       The amount of base tokens that are available to be repaid.
    error RepayLimitExceeded(
        address baseToken,
        uint256 amount,
        uint256 available
    );

    /// @notice An error which is used to indicate that an repay operation failed because the repayWithCollateral limit for an base token has been exceeded.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of base tokens that were requested to be repaidWithCollateral.
    /// @param available       The amount of base tokens that are available to be repaidWithCollateral.
    error RepayWithCollateralLimitExceeded(
        address baseToken,
        uint256 amount,
        uint256 available
    );

    /// @notice An error which is used to indicate that the slippage of a wrap or unwrap operation was exceeded.
    ///
    /// @param amount           The amount of underlying or yield tokens returned by the operation.
    /// @param minimumAmountOut The minimum amount of the underlying or yield token that was expected when performing
    ///                         the operation.
    error SlippageExceeded(uint256 amount, uint256 minimumAmountOut);
}

library Errors {
    // TokenUtils
    string internal constant ERC20CALLFAILED_EXPECTDECIMALS = "SVY101";
    string internal constant ERC20CALLFAILED_SAFEBALANCEOF = "SVY102";
    string internal constant ERC20CALLFAILED_SAFETRANSFER = "SVY103";
    string internal constant ERC20CALLFAILED_SAFEAPPROVE = "SVY104";
    string internal constant ERC20CALLFAILED_SAFETRANSFERFROM = "SVY105";
    string internal constant ERC20CALLFAILED_SAFEMINT = "SVY106";
    string internal constant ERC20CALLFAILED_SAFEBURN = "SVY107";
    string internal constant ERC20CALLFAILED_SAFEBURNFROM = "SVY108";

    // SavvyPositionManager
    string internal constant SPM_FEE_EXCEEDS_BPS = "SVY201"; // protocol fee exceeds BPS
    string internal constant SPM_ZERO_ADMIN_ADDRESS = "SVY202"; // zero pending admin address
    string internal constant SPM_UNAUTHORIZED_PENDING_ADMIN = "SVY203"; // Unauthorized pending admin
    string internal constant SPM_ZERO_SAVVY_SAGE_ADDRESS = "SVY204"; // zero savvy sage address
    string internal constant SPM_ZERO_PROTOCOL_FEE_RECEIVER_ADDRESS = "SVY205"; // zero protocol fee receiver address
    string internal constant SPM_ZERO_RECIPIENT_ADDRESS = "SVY206"; // zero recipient address
    string internal constant SPM_ZERO_TOKEN_AMOUNT = "SVY207"; // zero token amount
    string internal constant SPM_INVALID_DEBT_AMOUNT = "SVY208"; // invalid debt amount
    string internal constant SPM_ZERO_COLLATERAL_AMOUNT = "SVY209"; // zero collateral amount
    string internal constant SPM_INVALID_UNREALIZED_DEBT_AMOUNT = "SVY210"; // invalid unrealized debt amount
    string internal constant SPM_UNAUTHORIZED_ADMIN = "SVY211"; // Unauthorized admin
    string internal constant SPM_UNAUTHORIZED_REDLIST = "SVY212"; // Unauthorized redlist
    string internal constant SPM_UNAUTHORIZED_SENTINEL_OR_ADMIN = "SVY213"; // Unauthorized sentinel or admin
    string internal constant SPM_UNAUTHORIZED_KEEPER = "SVY214"; // Unauthorized keeper
    string internal constant SPM_BORROWING_LIMIT_EXCEEDED = "SVY215"; // Borrowing limit exceeded
    string internal constant SPM_INVALID_TOKEN_AMOUNT = "SVY216"; // invalid token amount
    string internal constant SPM_EXPECTED_VALUE_EXCEEDED = "SVY217"; // Expected Value exceeded
    string internal constant SPM_SLIPPAGE_EXCEEDED = "SVY218"; // Slippage exceeded
    string internal constant SPM_UNDERCOLLATERALIZED = "SVY219"; // Undercollateralized
    string internal constant SPM_UNAUTHORIZED_NOT_ALLOWLISTED = "SVY220"; // Unathorized, not allowlisted
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyEvents
/// @author Savvy DeFi
interface ISavvyEvents {
    /// @notice Emitted when the pending admin is updated.
    ///
    /// @param pendingAdmin The address of the pending admin.
    event PendingAdminUpdated(address pendingAdmin);

    /// @notice Emitted when the redlist mode is updated.
    ///
    /// @param flag A flag indicating if the redlist is active.
    event RedlistActiveUpdated(bool flag);

    /// @notice Emitted when the protocolTokenRequire mode is updated.
    ///
    /// @param flag A flag indicating if the protocolTokenRequire is active.
    event ProtocolTokenRequiredActiveUpdated(bool flag);

    /// @notice Emitted when the administrator is updated.
    ///
    /// @param admin The address of the administrator.
    event AdminUpdated(address admin);

    /// @notice Emitted when an address is set or unset as a sentinel.
    ///
    /// @param sentinel The address of the sentinel.
    /// @param flag     A flag indicating if `sentinel` was set or unset as a sentinel.
    event SentinelSet(address sentinel, bool flag);

    /// @notice Emitted when an address is set or unset as a keeper.
    ///
    /// @param sentinel The address of the keeper.
    /// @param flag     A flag indicating if `keeper` was set or unset as a sentinel.
    event KeeperSet(address sentinel, bool flag);

    /// @notice Emitted when an base token is added.
    ///
    /// @param baseToken The address of the base token that was added.
    event AddBaseToken(address indexed baseToken);

    /// @notice Emitted when a yield token is added.
    ///
    /// @param yieldToken The address of the yield token that was added.
    event AddYieldToken(address indexed yieldToken);

    /// @notice Emitted when an base token is enabled or disabled.
    ///
    /// @param baseToken The address of the base token that was enabled or disabled.
    /// @param enabled         A flag indicating if the base token was enabled or disabled.
    event BaseTokenEnabled(address indexed baseToken, bool enabled);

    /// @notice Emitted when an yield token is enabled or disabled.
    ///
    /// @param yieldToken The address of the yield token that was enabled or disabled.
    /// @param enabled    A flag indicating if the yield token was enabled or disabled.
    event YieldTokenEnabled(address indexed yieldToken, bool enabled);

    /// @notice Emitted when the repay limit of an base token is updated.
    ///
    /// @param baseToken The address of the base token.
    /// @param maximum         The updated maximum repay limit.
    /// @param blocks          The updated number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    event RepayLimitUpdated(
        address indexed baseToken,
        uint256 maximum,
        uint256 blocks
    );

    /// @notice Emitted when the repayWithCollateral limit of an base token is updated.
    ///
    /// @param baseToken The address of the base token.
    /// @param maximum         The updated maximum repayWithCollateral limit.
    /// @param blocks          The updated number of blocks it will take for the maximum repayWithCollateral limit to be replenished when it is completely exhausted.
    event RepayWithCollateralLimitUpdated(
        address indexed baseToken,
        uint256 maximum,
        uint256 blocks
    );

    /// @notice Emitted when the savvySage is updated.
    ///
    /// @param savvySage The updated address of the savvySage.
    event SavvySageUpdated(address savvySage);

    /// @notice Emitted when the minimum collateralization is updated.
    ///
    /// @param minimumCollateralization The updated minimum collateralization.
    event MinimumCollateralizationUpdated(uint256 minimumCollateralization);

    /// @notice Emitted when the protocol fee is updated.
    ///
    /// @param protocolFee The updated protocol fee.
    event ProtocolFeeUpdated(uint256 protocolFee);

    /// @notice Emitted when the protocol fee receiver is updated.
    ///
    /// @param protocolFeeReceiver The updated address of the protocol fee receiver.
    event ProtocolFeeReceiverUpdated(address protocolFeeReceiver);

    /// @notice Emitted when the borrowing limit is updated.
    ///
    /// @param maximum The updated maximum borrowing limit.
    /// @param blocks  The updated number of blocks it will take for the maximum borrowing limit to be replenished when it is completely exhausted.
    event BorrowingLimitUpdated(uint256 maximum, uint256 blocks);

    /// @notice Emitted when the credit unlock rate is updated.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param blocks     The number of blocks that distributed credit will unlock over.
    event CreditUnlockRateUpdated(address yieldToken, uint256 blocks);

    /// @notice Emitted when the adapter of a yield token is updated.
    ///
    /// @param yieldToken   The address of the yield token.
    /// @param tokenAdapter The updated address of the token adapter.
    event TokenAdapterUpdated(address yieldToken, address tokenAdapter);

    /// @notice Emitted when the maximum expected value of a yield token is updated.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param maximumExpectedValue The updated maximum expected value.
    event MaximumExpectedValueUpdated(
        address indexed yieldToken,
        uint256 maximumExpectedValue
    );

    /// @notice Emitted when the maximum loss of a yield token is updated.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param maximumLoss The updated maximum loss.
    event MaximumLossUpdated(address indexed yieldToken, uint256 maximumLoss);

    /// @notice Emitted when the expected value of a yield token is snapped to its current value.
    ///
    /// @param yieldToken    The address of the yield token.
    /// @param expectedValue The updated expected value measured in the yield token's base token.
    event Snap(address indexed yieldToken, uint256 expectedValue);

    /// @notice Emitted when a the admin sweeps all of one reward token from the Savvy
    ///
    /// @param rewardToken The address of the reward token.
    /// @param amount      The amount of 'rewardToken' swept into the admin.
    event SweepTokens(address indexed rewardToken, uint256 amount);

    /// @notice Emitted when `owner` grants `spender` the ability to borrow debt tokens on its behalf.
    ///
    /// @param owner   The address of the account owner.
    /// @param spender The address which is being permitted to borrow tokens on the behalf of `owner`.
    /// @param amount  The amount of debt tokens that `spender` is allowed to borrow.
    event ApproveBorrow(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Emitted when `owner` grants `spender` the ability to withdraw `yieldToken` from its account.
    ///
    /// @param owner      The address of the account owner.
    /// @param spender    The address which is being permitted to borrow tokens on the behalf of `owner`.
    /// @param yieldToken The address of the yield token that `spender` is allowed to withdraw.
    /// @param amount     The amount of shares of `yieldToken` that `spender` is allowed to withdraw.
    event ApproveWithdraw(
        address indexed owner,
        address indexed spender,
        address indexed yieldToken,
        uint256 amount
    );

    /// @notice Emitted when a user deposits `amount of `yieldToken` to `recipient`.
    ///
    /// @notice This event does not imply that `sender` directly deposited yield tokens. It is possible that the
    ///         base tokens were wrapped.
    ///
    /// @param sender       The address of the user which deposited funds.
    /// @param yieldToken   The address of the yield token that was deposited.
    /// @param amount       The amount of yield tokens that were deposited.
    /// @param recipient    The address that received the deposited funds.
    event DepositYieldToken(
        address indexed sender,
        address indexed yieldToken,
        uint256 amount,
        address recipient
    );

    /// @notice Emitted when `shares` shares of `yieldToken` are burned to withdraw `yieldToken` from the account owned
    ///         by `owner` to `recipient`.
    ///
    /// @notice This event does not imply that `recipient` received yield tokens. It is possible that the yield tokens
    ///         were unwrapped.
    ///
    /// @param owner      The address of the account owner.
    /// @param yieldToken The address of the yield token that was withdrawn.
    /// @param shares     The amount of shares that were burned.
    /// @param recipient  The address that received the withdrawn funds.
    event WithdrawYieldToken(
        address indexed owner,
        address indexed yieldToken,
        uint256 shares,
        address recipient
    );

    /// @notice Emitted when `amount` debt tokens are borrowed to `recipient` using the account owned by `owner`.
    ///
    /// @param owner     The address of the account owner.
    /// @param amount    The amount of tokens that were borrowed.
    /// @param recipient The recipient of the borrowed tokens.
    event Borrow(address indexed owner, uint256 amount, address recipient);

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to `recipient`.
    ///
    /// @param sender    The address which is burning tokens.
    /// @param amount    The amount of tokens that were burned.
    /// @param recipient The address that received credit for the burned tokens.
    event RepayWithDebtToken(
        address indexed sender,
        uint256 amount,
        address recipient
    );

    /// @notice Emitted when `amount` of `baseToken` are repaid to grant credit to `recipient`.
    ///
    /// @param sender          The address which is repaying tokens.
    /// @param baseToken The address of the base token that was used to repay debt.
    /// @param amount          The amount of the base token that was used to repay debt.
    /// @param recipient       The address that received credit for the repaid tokens.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event RepayWithBaseToken(
        address indexed sender,
        address indexed baseToken,
        uint256 amount,
        address recipient,
        uint256 credit
    );

    /// @notice Emitted when `sender` repayWithCollateral `share` shares of `yieldToken`.
    ///
    /// @param owner           The address of the account owner repaying with collateral.
    /// @param yieldToken      The address of the yield token.
    /// @param baseToken The address of the base token.
    /// @param shares          The amount of the shares of `yieldToken` that were repaidWithCollateral.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event RepayWithCollateral(
        address indexed owner,
        address indexed yieldToken,
        address indexed baseToken,
        uint256 shares,
        uint256 credit
    );

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to users who have deposited `yieldToken`.
    ///
    /// @param sender     The address which burned debt tokens.
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of debt tokens which were burned.
    event Donate(
        address indexed sender,
        address indexed yieldToken,
        uint256 amount
    );

    /// @notice Emitted when `yieldToken` is harvested.
    ///
    /// @param yieldToken     The address of the yield token that was harvested.
    /// @param minimumAmountOut    The maximum amount of loss that is acceptable when unwrapping the base tokens into yield tokens, measured in basis points.
    /// @param totalHarvested The total amount of base tokens harvested.
    /// @param credit           The total amount of debt repaid to depositors of `yieldToken`.
    event Harvest(
        address indexed yieldToken,
        uint256 minimumAmountOut,
        uint256 totalHarvested,
        uint256 credit
    );

    /// @notice Emitted when the offset as baseToken exceeds to limit.
    ///
    /// @param yieldToken      The address of the yield token that was harvested.
    /// @param currentValue    Current value as baseToken.
    /// @param expectedValue   Limit offset value.
    event HarvestExceedsOffset(
        address indexed yieldToken,
        uint256 currentValue,
        uint256 expectedValue
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyImmutables
/// @author Savvy DeFi
interface ISavvyImmutables {
    /// @notice Returns the version of the savvy.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Returns the address of the debt token used by the system.
    ///
    /// @return The address of the debt token.
    function debtToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "./ISavvyTokenParams.sol";
import "../IYieldStrategyManager.sol";
import "../../libraries/Sets.sol";

/// @title  ISavvyState
/// @author Savvy DeFi
interface ISavvyState is ISavvyTokenParams {
    /// @notice A user account.
    struct Account {
        // A signed value which represents the current amount of debt or credit that the account has accrued.
        // Positive values indicate debt, negative values indicate credit.
        int256 debt;
        // The share balances for each yield token.
        mapping(address => uint256) balances;
        // The last values recorded for accrued weights for each yield token.
        mapping(address => uint256) lastAccruedWeights;
        // The set of yield tokens that the account has deposited into the system.
        Sets.AddressSet depositedTokens;
        // The allowances for borrows.
        mapping(address => uint256) borrowAllowances;
        // The allowances for withdrawals.
        mapping(address => mapping(address => uint256)) withdrawAllowances;
        // The harvested base token amount per yield token.
        mapping(address => uint256) harvestedYield;
    }

    /// @notice Gets the address of the admin.
    ///
    /// @return admin The admin address.
    function admin() external view returns (address admin);

    /// @notice The total number of debt token.
    /// @return totalDebt Total debt amount.
    function totalDebt() external view returns (int256 totalDebt);

    /// @notice Gets the address of the pending administrator.
    ///
    /// @return pendingAdmin The pending administrator address.
    function pendingAdmin() external view returns (address pendingAdmin);

    /// @notice Gets if an address is a sentinel.
    ///
    /// @param sentinel The address to check.
    ///
    /// @return isSentinel If the address is a sentinel.
    function sentinels(
        address sentinel
    ) external view returns (bool isSentinel);

    /// @notice Gets if an address is a keeper.
    ///
    /// @param keeper The address to check.
    ///
    /// @return isKeeper If the address is a keeper
    function keepers(address keeper) external view returns (bool isKeeper);

    /// @notice Gets the address of the savvySage.
    ///
    /// @return savvySage The savvySage address.
    function savvySage() external view returns (address savvySage);

    /// @notice Gets the address of the svyBooster.
    ///
    /// @return svyBooster The svyBooster address.
    function svyBooster() external view returns (address svyBooster);

    /// @notice Gets the minimum collateralization.
    ///
    /// @notice Collateralization is determined by taking the total value of collateral that a user has deposited into their account and dividing it their debt.
    ///
    /// @dev The value returned is a 18 decimal fixed point integer.
    ///
    /// @return minimumCollateralization The minimum collateralization.
    function minimumCollateralization()
        external
        view
        returns (uint256 minimumCollateralization);

    /// @notice Gets the protocol fee.
    ///
    /// @return protocolFee The protocol fee.
    function protocolFee() external view returns (uint256 protocolFee);

    /// @notice Gets the protocol fee receiver.
    ///
    /// @return protocolFeeReceiver The protocol fee receiver.
    function protocolFeeReceiver()
        external
        view
        returns (address protocolFeeReceiver);

    /// @notice Gets the address of the allowlist contract.
    ///
    /// @return allowlist The address of the allowlist contract.
    function allowlist() external view returns (address allowlist);

    /// @notice Gets value to present redlist is active or not.
    ///
    /// @return redlistActive The redlist is active.
    function redlistActive() external view returns (bool redlistActive);

    /// @notice Gets value to present protocolTokenRequire is active or not.
    ///
    /// @return protocolTokenRequired The protocolTokenRequired is active.
    function protocolTokenRequired()
        external
        view
        returns (bool protocolTokenRequired);

    /// @notice The address of WrapTokenGateway contract.
    ///
    /// @return wrapTokenGateway The address of WrapTokenGateway contract.
    function wrapTokenGateway()
        external
        view
        returns (address wrapTokenGateway);

    /// @notice Gets information about the account owned by `owner`.
    ///
    /// @param owner The address that owns the account.
    ///
    /// @return debt            The unrealized amount of debt that the account had incurred.
    /// @return depositedTokens The yield tokens that the owner has deposited.
    function accounts(
        address owner
    ) external view returns (int256 debt, address[] memory depositedTokens);

    /// @notice Gets information about a yield token position for the account owned by `owner`.
    ///
    /// @param owner      The address that owns the account.
    /// @param yieldToken The address of the yield token to get the position of.
    ///
    /// @return shares            The amount of shares of that `owner` owns of the yield token.
    /// @return harvestedYield    The amount of harvested yield.
    /// @return lastAccruedWeight The last recorded accrued weight of the yield token.
    function positions(
        address owner,
        address yieldToken
    )
        external
        view
        returns (
            uint256 shares,
            uint256 harvestedYield,
            uint256 lastAccruedWeight
        );

    /// @notice Gets the amount of debt tokens `spender` is allowed to borrow on behalf of `owner`.
    ///
    /// @param owner   The owner of the account.
    /// @param spender The address which is allowed to borrow on behalf of `owner`.
    ///
    /// @return allowance The amount of debt tokens that `spender` can borrow on behalf of `owner`.
    function borrowAllowance(
        address owner,
        address spender
    ) external view returns (uint256 allowance);

    /// @notice Gets the amount of shares of `yieldToken` that `spender` is allowed to withdraw on behalf of `owner`.
    ///
    /// @param owner      The owner of the account.
    /// @param spender    The address which is allowed to withdraw on behalf of `owner`.
    /// @param yieldToken The address of the yield token.
    ///
    /// @return allowance The amount of shares that `spender` can withdraw on behalf of `owner`.
    function withdrawAllowance(
        address owner,
        address spender,
        address yieldToken
    ) external view returns (uint256 allowance);

    /// @notice Get YieldStrategyManager contract handle.
    /// @return returns YieldStrategyManager contract handle.
    function yieldStrategyManager()
        external
        view
        returns (IYieldStrategyManager);

    /// @notice Check interfaceId is supported by SavvyPositionManager.
    /// @param interfaceId The Id of interface to check.
    /// @return SavvyPositionMananger supports this interfaceId or not. true/false.
    function supportInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  ISavvyTokenParams
/// @author Savvy DeFi
interface ISavvyTokenParams {
    /// @notice Defines base token parameters.
    struct BaseTokenParams {
        // A coefficient used to normalize the token to a value comparable to the debt token. For example, if the
        // base token is 8 decimals and the debt token is 18 decimals then the conversion factor will be
        // 10^10. One unit of the base token will be comparably equal to one unit of the debt token.
        uint256 conversionFactor;
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }

    /// @notice Defines yield token parameters.
    struct YieldTokenParams {
        // The maximum percentage loss that is acceptable before disabling certain actions.
        uint256 maximumLoss;
        // The maximum value of yield tokens that the system can hold, measured in units of the base token.
        uint256 maximumExpectedValue;
        // The percent of credit that will be unlocked per block. The representation of this value is a 18  decimal
        // fixed point integer.
        uint256 creditUnlockRate;
        // The current balance of yield tokens which are held by users.
        uint256 activeBalance;
        // The current balance of yield tokens which are earmarked to be harvested by the system at a later time.
        uint256 harvestableBalance;
        // The total number of shares that have been borrowed for this token.
        uint256 totalShares;
        // The expected value of the tokens measured in base tokens. This value controls how much of the token
        // can be harvested. When users deposit yield tokens, it increases the expected value by how much the tokens
        // are exchangeable for in the base token. When users withdraw yield tokens, it decreases the expected
        // value by how much the tokens are exchangeable for in the base token.
        uint256 expectedValue;
        // The current amount of credit which is will be distributed over time to depositors.
        uint256 pendingCredit;
        // The amount of the pending credit that has been distributed.
        uint256 distributedCredit;
        // The block number which the last credit distribution occurred.
        uint256 lastDistributionBlock;
        // The total accrued weight. This is used to calculate how much credit a user has been granted over time. The
        // representation of this value is a 18 decimal fixed point integer.
        uint256 accruedWeight;
        // The associated base token that can be redeemed for the yield-token.
        address baseToken;
        // The adapter used by the system to wrap, unwrap, and lookup the conversion rate of this token into its
        // base token.
        address adapter;
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../libraries/Limiters.sol";
import "./ISavvyAdminActions.sol";
import "./ISavvyTokenParams.sol";

/// @title  IYieldStrategyManagerActions
/// @author Savvy DeFi
interface IYieldStrategyManagerActions is ISavvyTokenParams {
    /// @dev Unwraps `amount` of `yieldToken` into its base token.
    ///
    /// @param yieldToken       The address of the yield token to unwrap.
    /// @param amount           The amount of the yield token to wrap.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be received from the
    ///                         operation.
    ///
    /// @return The amount of base tokens that resulted from the operation.
    function unwrap(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256);

    /// @notice Burns `amount` debt tokens to credit accounts which have deposited `yieldToken`.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {Donate} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amtRepayWithCollateral = 5000;
    /// @notice SavvyPositionManager(savvyAddress).repayWithCollateral(dai, amtRepayWithCollateral, 1);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to credit accounts for.
    /// @param amount     The amount of debt tokens to burn.
    /// @param shares     The amount of share left in savvy.
    function donate(
        address yieldToken,
        uint256 amount,
        uint256 shares
    ) external returns (uint256);

    /// @notice Harvests outstanding yield that a yield token has accumulated and distributes it as credit to holders.
    ///
    /// @notice `msg.sender` must be a keeper or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The amount being harvested must be greater than zero or else this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Harvest} event.
    ///
    /// @param yieldToken       The address of the yield token to harvest.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be withdrawn to `recipient`.
    /// @param protocolFee      The rate of protocol fee.
    /// @return baseToken           The address of base token.
    /// @return amountBaseTokens    The amount of base token.
    /// @return feeAmount           The amount of protocol fee.
    /// @return distributeAmount    The amount of distribute
    /// @return credit              The amount of debt.
    function harvest(
        address yieldToken,
        uint256 minimumAmountOut,
        uint256 protocolFee
    )
        external
        returns (
            address baseToken,
            uint256 amountBaseTokens,
            uint256 feeAmount,
            uint256 distributeAmount,
            uint256 credit
        );

    /// @notice Synchronizes the active balance and expected value of `yieldToken`.
    /// @param yieldToken       The address of yield token.
    /// @param amount           The amount to add or subtract from the debt.
    /// @param addOperation     Present for add or sub.
    /// @return                 The config of yield token.
    function syncYieldToken(
        address yieldToken,
        uint256 amount,
        bool addOperation
    ) external returns (YieldTokenParams memory);

    /// @dev Burns `share` shares of `yieldToken` from the account owned by `owner`.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares to burn.
    function burnShares(address yieldToken, uint256 shares) external;

    /// @dev Issues shares of `yieldToken` for `amount` of its base token to `recipient`.
    ///
    /// IMPORTANT: `amount` must never be 0.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield token.
    /// @return shares    The amount of shars.
    function issueSharesForAmount(
        address yieldToken,
        uint256 amount
    ) external returns (uint256 shares);

    /// @notice Update repay limiters and returns debt amount and actual amount of base token.
    /// @param baseToken The address of base token.
    /// @return Return debt amount same worth as `amount` of base token.
    /// @return Return actual amount of base token for repay debt.
    function repayWithBaseToken(
        address baseToken,
        uint256 amount,
        int256 debt
    ) external view returns (uint256, uint256);

    /// @notice Check if had condition to do repayWithCollateral.
    /// @notice checkSupportedYieldToken(), checkTokenEnabled(), checkLoss()
    /// @param yieldToken The address of yield token.
    /// @return baseToken The address of base token.
    function repayWithCollateralCheck(
        address yieldToken
    ) external view returns (address baseToken);

    /// @dev Distributes unlocked credit of `yieldToken` to all depositors.
    ///
    /// @param yieldToken The address of the yield token to distribute unlocked credit for.
    function distributeUnlockedCredit(address yieldToken) external;

    /// @dev Preemptively harvests `yieldToken`.
    ///
    /// @dev This will earmark yield tokens to be harvested at a future time when the current value of the token is
    ///      greater than the expected value. The purpose of this function is to synchronize the balance of the yield
    ///      token which is held by users versus tokens which will be seized by the protocol.
    ///
    /// @param yieldToken The address of the yield token to preemptively harvest.
    function preemptivelyHarvest(address yieldToken) external;

    /// @notice Snap the expected value `yieldToken` to the current value.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev This function should only be used in the event of a loss in the target yield-token. For example, say a third-party protocol experiences a fifty percent loss. The expected value (amount of base tokens) of the yield tokens being held by the system would be two times the real value that those yield tokens could be redeemed for. This function gives governance a way to realize those losses so that users can continue using the token as normal.
    ///
    /// @param yieldToken The address of the yield token to snap.
    function snap(address yieldToken) external returns (uint256);

    /// @notice Do pre actions for deposit.
    /// @notice checkTokenEnabled(), checkLoss(), preemptivelyHarvest()
    /// @param yieldToken The address of yield token.
    /// @return yieldTokenParam The config of yield token.
    function depositPrepare(
        address yieldToken
    )
        external
        returns (YieldTokenParams memory yieldTokenParam);

    /// @notice `shares` will be limited up to an equal amount of debt that `recipient` currently holds.
    /// @dev Explain to a developer any extra details
    /// @param yieldToken       The address of the yield token to repayWithCollateral.
    /// @param recipient        The address of user that will derease debt.
    /// @param shares           The number of shares to burn for credit.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be repaidWithCollateral.
    /// @param unrealizedDebt   The amount of the debt unrealized.
    /// @return The amount of base token.
    /// @return The amount of yield token.
    /// @return The amount of shares that used actually to decrease debt.
    function repayWithCollateral(
        address yieldToken,
        address recipient,
        uint256 shares,
        uint256 minimumAmountOut,
        int256 unrealizedDebt
    ) external returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../../libraries/Limiters.sol";
import "./ISavvyAdminActions.sol";
import "./ISavvyTokenParams.sol";

/// @title  IYieldStrategyManagerState
/// @author Savvy DeFi
interface IYieldStrategyManagerStates is ISavvyTokenParams {
    /// @notice Configures the the repay limit of `baseToken`.
    /// @param baseToken The address of the base token to configure the repay limit of.
    /// @param maximum         The maximum repay limit.
    /// @param blocks          The number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    function configureRepayLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configure the repayWithCollateral limiter of `baseToken`.
    /// @param baseToken The address of the base token to configure the repayWithCollateral limit of.
    /// @param maximum         The maximum repayWithCollateral limit.
    /// @param blocks          The number of blocks it will take for the maximum repayWithCollateral limit to be replenished when it is completely exhausted.
    function configureRepayWithCollateralLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configures the borrowing limiter.
    ///
    /// @param maximum The maximum borrowing limit.
    /// @param rate  The number of blocks it will take for the maximum borrowing limit to be replenished when it is completely exhausted.
    function configureBorrowingLimit(uint256 maximum, uint256 rate) external;

    /// @notice Sets the rate at which credit will be completely available to depositors after it is harvested.
    /// @param yieldToken The address of the yield token to set the credit unlock rate for.
    /// @param blocks     The number of blocks that it will take before the credit will be unlocked.
    function configureCreditUnlockRate(
        address yieldToken,
        uint256 blocks
    ) external;

    /// @notice Sets the maximum expected value of a yield token that the system can hold.
    ///
    /// @param yieldToken The address of the yield token to set the maximum expected value for.
    /// @param value      The maximum expected value of the yield token denoted measured in its base token.
    function setMaximumExpectedValue(
        address yieldToken,
        uint256 value
    ) external;

    /// @notice Sets the maximum loss that a yield bearing token will permit before restricting certain actions.
    /// @param yieldToken The address of the yield bearing token to set the maximum loss for.
    /// @param value      The value to set the maximum loss to. This is in units of basis points.
    function setMaximumLoss(address yieldToken, uint256 value) external;

    /// @notice Sets the token adapter of a yield token.
    /// @param yieldToken The address of the yield token to set the adapter for.
    /// @param adapter    The address to set the token adapter to.
    function setTokenAdapter(address yieldToken, address adapter) external;

    /// @notice Set the borrowing limiter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {BorrowingLimitUpdated} event.
    ///
    /// @param borrowingLimiter Limit information for borrowing.
    function setBorrowingLimiter(
        Limiters.LinearGrowthLimiter calldata borrowingLimiter
    ) external;

    /// @notice Set savvyPositionManager address.
    /// @dev Only owner can call this function.
    /// @param savvyPositionManager The address of savvyPositionManager.
    function setSavvyPositionManager(address savvyPositionManager) external;

    /// @notice Gets the conversion rate of base tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of base tokens per share.
    function getBaseTokensPerShare(
        address yieldToken
    ) external view returns (uint256 rate);

    /// @notice Gets the conversion rate of yield tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of yield tokens per share.
    function getYieldTokensPerShare(
        address yieldToken
    ) external view returns (uint256 rate);

    /// @notice Gets the supported base tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported base tokens.
    function getSupportedBaseTokens()
        external
        view
        returns (address[] memory tokens);

    /// @notice Gets the supported yield tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported yield tokens.
    function getSupportedYieldTokens()
        external
        view
        returns (address[] memory tokens);

    /// @notice Gets if an base token is supported.
    ///
    /// @param baseToken The address of the base token to check.
    ///
    /// @return isSupported If the base token is supported.
    function isSupportedBaseToken(
        address baseToken
    ) external view returns (bool isSupported);

    /// @notice Gets if a yield token is supported.
    ///
    /// @param yieldToken The address of the yield token to check.
    ///
    /// @return isSupported If the yield token is supported.
    function isSupportedYieldToken(
        address yieldToken
    ) external view returns (bool isSupported);

    /// @notice Gets the parameters of an base token.
    ///
    /// @param baseToken The address of the base token.
    ///
    /// @return params The base token parameters.
    function getBaseTokenParameters(
        address baseToken
    ) external view returns (BaseTokenParams memory params);

    /// @notice Get the parameters and state of a yield-token.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return params The yield token parameters.
    function getYieldTokenParameters(
        address yieldToken
    ) external view returns (YieldTokenParams memory params);

    /// @notice Gets current limit, maximum, and rate of the borrowing limiter.
    ///
    /// @return currentLimit The current amount of debt tokens that can be borrowed.
    /// @return rate         The maximum possible amount of tokens that can be repaidWithCollateral at a time.
    /// @return maximum      The highest possible maximum amount of debt tokens that can be borrowed at a time.
    function getBorrowLimitInfo()
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum);

    /// @notice Gets current limit, maximum, and rate of a repay limiter for `baseToken`.
    ///
    /// @param baseToken The address of the base token.
    ///
    /// @return currentLimit The current amount of base tokens that can be repaid.
    /// @return rate         The rate at which the the current limit increases back to its maximum in tokens per block.
    /// @return maximum      The maximum possible amount of tokens that can be repaid at a time.
    function getRepayLimitInfo(
        address baseToken
    )
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum);

    /// @notice Gets current limit, maximum, and rate of the repayWithCollateral limiter for `baseToken`.
    ///
    /// @param baseToken The address of the base token.
    ///
    /// @return currentLimit The current amount of base tokens that can be repaid with Collateral.
    /// @return rate         The rate at which the function increases back to its maximum limit (tokens / block).
    /// @return maximum      The highest possible maximum amount of debt tokens that can be repaidWithCollateral at a time.
    function getRepayWithCollateralLimitInfo(
        address baseToken
    )
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum);

    /// @dev Gets the amount of shares that `amount` of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield tokens.
    ///
    /// @return The number of shares.
    function convertYieldTokensToShares(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of shares of `yieldToken` that `amount` of its base token is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of base tokens.
    ///
    /// @return The amount of shares.
    function convertBaseTokensToShares(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of yield tokens that `shares` shares of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares.
    ///
    /// @return The amount of yield tokens.
    function convertSharesToYieldTokens(
        address yieldToken,
        uint256 shares
    ) external view returns (uint256);

    /// @dev Gets the amount of an base token that `amount` of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield tokens.
    ///
    /// @return The amount of base tokens.
    function convertYieldTokensToBaseToken(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of `yieldToken` that `amount` of its base token is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of base tokens.
    ///
    /// @return The amount of yield tokens.
    function convertBaseTokensToYieldToken(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of base tokens that `shares` shares of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares.
    ///
    /// @return baseToken           The address of base token.
    /// @return amountBaseTokens    The amount of base tokens.
    function convertSharesToBaseTokens(
        address yieldToken,
        uint256 shares
    ) external view returns (address baseToken, uint256 amountBaseTokens);

    /// @dev Calculates the amount of unlocked credit for `yieldToken` that is available for distribution.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return currentAccruedWeight The current total accrued weight.
    /// @return unlockedCredit The amount of unlocked credit available.
    function calculateUnlockedCredit(
        address yieldToken
    )
        external
        view
        returns (uint256 currentAccruedWeight, uint256 unlockedCredit);

    /// @dev Gets the virtual active balance of `yieldToken`.
    ///
    /// @dev The virtual active balance is the active balance minus any harvestable tokens which have yet to be realized.
    ///
    /// @param yieldToken The address of the yield token to get the virtual active balance of.
    ///
    /// @return The virtual active balance.
    function calculateUnrealizedActiveBalance(
        address yieldToken
    ) external view returns (uint256);

    /// @notice Check token is supported by Savvy.
    /// @dev The token should not be yield token or base token that savvy contains.
    /// @dev If token is yield token or base token, reverts UnsupportedToken.
    /// @param rewardToken The address of token to check.
    function checkSupportTokens(address rewardToken) external view;

    /// @dev Checks if an address is a supported yield token.
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    /// @param yieldToken The address to check.
    function checkSupportedYieldToken(address yieldToken) external view;

    /// @dev Checks if an address is a supported base token.
    ///
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    ///
    /// @param baseToken The address to check.
    function checkSupportedBaseToken(address baseToken) external view;

    /// @notice Get repay limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return Repay limit information of baseToken.
    function repayLimiters(
        address baseToken
    ) external view returns (Limiters.LinearGrowthLimiter memory);

    /// @notice Get currnet borrow limit information.
    /// @return Current borrowing limit information.
    function currentBorrowingLimiter() external view returns (uint256);

    /// @notice Get current repay limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return Current repay limit information of baseToken.
    function currentRepayWithBaseTokenLimit(
        address baseToken
    ) external view returns (uint256);

    /// @notice Get current repayWithCollateral limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return Current repayWithCollateral limit information of baseToken.
    function currentRepayWithCollateralLimit(
        address baseToken
    ) external view returns (uint256);

    /// @notice Get repayWithCollateral limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return RepayWithCollateral limit information of baseToken.
    function repayWithCollateralLimiters(
        address baseToken
    ) external view returns (Limiters.LinearGrowthLimiter memory);

    /// @notice Get yield token parameter of yield token.
    /// @param yieldToken The address of yield token.
    /// @return The parameter of yield token.
    function getYieldTokenParams(
        address yieldToken
    ) external view returns (YieldTokenParams memory);

    /// @notice Check yield token loss is exceeds max loss.
    /// @dev If it's exceeds to max loss, revert `LossExceed(yieldToken, currentLoss, maximumLoss)`.
    /// @param yieldToken The address of yield token.
    function checkLoss(address yieldToken) external view;

    /// @notice Adds an base token to the system.
    /// @param debtToken The address of debt Token.
    /// @param baseToken The address of the base token to add.
    /// @param config          The initial base token configuration.
    function addBaseToken(
        address debtToken,
        address baseToken,
        ISavvyAdminActions.BaseTokenConfig calldata config
    ) external;

    /// @notice Adds a yield token to the system.
    /// @param yieldToken The address of the yield token to add.
    /// @param config     The initial yield token configuration.
    function addYieldToken(
        address yieldToken,
        ISavvyAdminActions.YieldTokenConfig calldata config
    ) external;

    /// @notice Sets an base token as either enabled or disabled.
    /// @param baseToken The address of the base token to enable or disable.
    /// @param enabled         If the base token should be enabled or disabled.
    function setBaseTokenEnabled(address baseToken, bool enabled) external;

    /// @notice Sets a yield token as either enabled or disabled.
    /// @param yieldToken The address of the yield token to enable or disable.
    /// @param enabled    If the base token should be enabled or disabled.
    function setYieldTokenEnabled(address yieldToken, bool enabled) external;

    /// @notice Get base token parameter of base token.
    /// @param baseToken The address of base token.
    /// @return The parameter of base token.
    function getBaseTokenParams(
        address baseToken
    ) external view returns (BaseTokenParams memory);

    /// @notice Get borrow limit information.
    /// @return Borrowing limit information.
    function borrowingLimiter()
        external
        view
        returns (Limiters.LinearGrowthLimiter memory);

    /// @notice Decrease borrowing limiter.
    /// @param amount The amount of borrowing to decrease.
    function decreaseBorrowingLimiter(uint256 amount) external;

    /// @notice Increase borrowing limiter.
    /// @param amount The amount of borrowing to increase.
    function increaseBorrowingLimiter(uint256 amount) external;

    /// @notice Decrease repayWithCollateral limiter.
    /// @param amount The amount of repayWithCollateral to decrease.
    function decreaseRepayWithCollateralLimiter(
        address baseToken,
        uint256 amount
    ) external;

    /// @notice Decrease base token repay limiter.
    /// @param amount The amount of base token repay to decrease.
    function decreaseRepayWithBaseTokenLimiter(
        address baseToken,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./ISavvySwap.sol";
import "../ISavvyPositionManager.sol";
import "../IERC20TokenReceiver.sol";

/// @title  ISavvySage
/// @author Savvy DeFi
interface ISavvySage is IERC20TokenReceiver {
    /// @notice Parameters used to define a given weighting schema.
    ///
    /// Weighting schemas can be used to generally weight tokens in relation to an action or actions that will be taken.
    /// In the SavvySage, there are 2 actions that require weighting schemas: `burnCredit` and `depositFunds`.
    ///
    /// `burnCredit` uses a weighting schema that determines which yield-tokens are targeted when burning credit from
    /// the `Account` controlled by the SavvySage, via the `Savvy.donate` function.
    ///
    /// `depositFunds` uses a weighting schema that determines which yield-tokens are targeted when depositing
    /// base tokens into the Savvy.
    struct Weighting {
        // The weights of the tokens used by the schema.
        mapping(address => uint256) weights;
        // The tokens used by the schema.
        address[] tokens;
        // The total weight of the schema (sum of the token weights).
        uint256 totalWeight;
    }

    /// @notice Emitted when the savvy is set.
    ///
    /// @param savvy The address of the savvy.
    event SetSavvy(address savvy);

    /// @notice Emitted when the slippage is set.
    event SlippageRateSet(uint16 _slippageRate);

    /// @notice Emitted when the amo is set.
    ///
    /// @param baseToken The address of the base token.
    /// @param amo             The address of the amo.
    event SetAmo(address baseToken, address amo);

    /// @notice Emitted when the the status of diverting to the amo is set for a given base token.
    ///
    /// @param baseToken The address of the base token.
    /// @param divert          Whether or not to divert funds to the amo.
    event SetDivertToAmo(address baseToken, bool divert);

    /// @notice Emitted when an base token is registered.
    ///
    /// @param baseToken The address of the base token.
    /// @param savvySwap      The address of the savvySwap for the base token.
    event RegisterToken(address baseToken, address savvySwap);

    /// @param baseToken The address of the base token.
    /// @param savvySwap      The address of the savvySwap for the base token.
    event UnregisterToken(address baseToken, address savvySwap);

    /// @notice Emitted when an base token's flow rate is updated.
    ///
    /// @param baseToken The base token.
    /// @param flowRate        The flow rate for the base token.
    event SetFlowRate(address baseToken, uint256 flowRate);

    /// @notice Emitted when the strategies are refreshed.
    event RefreshStrategies();

    /// @notice Emitted when a source is set.
    event SetSource(address source, bool flag);

    /// @notice Emitted when a savvySwap is updated.
    event SetSavvySwap(address baseToken, address savvySwap);

    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the total credit held by the SavvySage.
    ///
    /// @return The total credit.
    function getTotalCredit() external view returns (uint256);

    /// @notice Gets registered base token addresses.
    function getRegisteredBaseTokens() external view returns (address[] memory);

    /// @notice Gets the total amount of base token that the SavvySage controls in the Savvy.
    ///
    /// @param baseToken The base token to query.
    ///
    /// @return totalBuffered The total buffered.
    function getTotalUnderlyingBuffered(
        address baseToken
    ) external view returns (uint256 totalBuffered);

    /// @notice Gets the total available flow for the base token
    ///
    /// The total available flow will be the lesser of `flowAvailable[token]` and `getTotalUnderlyingBuffered`.
    ///
    /// @param baseToken The base token to query.
    ///
    /// @return availableFlow The available flow.
    function getAvailableFlow(
        address baseToken
    ) external view returns (uint256 availableFlow);

    /// @notice Gets the weight of the given weight type and token
    ///
    /// @param weightToken The type of weight to query.
    /// @param token       The weighted token.
    ///
    /// @return weight The weight of the token for the given weight type.
    function getWeight(
        address weightToken,
        address token
    ) external view returns (uint256 weight);

    /// @notice Set a source of funds.
    ///
    /// @param source The target source.
    /// @param flag   The status to set for the target source.
    function setSource(address source, bool flag) external;

    /// @notice Set savvySwap by admin.
    ///
    /// This function reverts if the caller is not the current admin.
    ///
    /// @param baseToken The target base token to update.
    /// @param newSavvySwap   The new savvySwap for the target `baseToken`.
    function setSavvySwap(address baseToken, address newSavvySwap) external;

    /// @notice Set savvy by admin.
    ///
    /// This function reverts if the caller is not the current admin.
    ///
    /// @param savvy The new savvy whose funds we are handling.
    function setSavvy(address savvy) external;

    /// @notice Set allow slippage rate.
    ///
    /// This function reverts if the caller is not the current admin.
    /// This function also reverts if slippage rate is too big. over 30%
    /// @param slippageRate The slippage percent rate.
    function setSlippageRate(uint16 slippageRate) external;

    /// @notice Set the address of the amo for a target base token.
    ///
    /// @param baseToken The address of the base token to set.
    /// @param amo The address of the base token's new amo.
    function setAmo(address baseToken, address amo) external;

    /// @notice Set whether or not to divert funds to the amo.
    ///
    /// @param baseToken The address of the base token to set.
    /// @param divert          Whether or not to divert base token to the amo.
    function setDivertToAmo(address baseToken, bool divert) external;

    /// @notice Refresh the yield-tokens in the SavvySage.
    ///
    /// This requires a call anytime governance adds a new yield token to the savvy.
    function refreshStrategies() external;

    /// @notice Register an base token.
    ///
    /// This function reverts if the caller is not the current admin.
    ///
    /// @param baseToken The base token being registered.
    /// @param savvySwap      The savvySwap for the base token.
    function registerToken(address baseToken, address savvySwap) external;

    /// @notice Unregister an base token.
    ///
    /// This function reverts if the caller is not the current admin.
    ///
    /// @param baseToken The base token being unregistered.
    function unregisterToken(address baseToken, address savvySwap) external;

    /// @notice Set flow rate of an base token.
    ///
    /// This function reverts if the caller is not the current admin.
    ///
    /// @param baseToken The base token getting the flow rate set.
    /// @param flowRate        The new flow rate.
    function setFlowRate(address baseToken, uint256 flowRate) external;

    /// @notice Sets up a weighting schema.
    ///
    /// @param weightToken The name of the weighting schema.
    /// @param tokens      The yield-tokens to weight.
    /// @param weights     The weights of the yield tokens.
    function setWeights(
        address weightToken,
        address[] memory tokens,
        uint256[] memory weights
    ) external;

    /// @notice Swaps any available flow into the SavvySwap.
    ///
    /// This function is a way for the keeper to force funds to be swapped into the SavvySwap.
    ///
    /// This function will revert if called by any account that is not a keeper. If there is not enough local balance of
    /// `baseToken` held by the SavvySage any additional funds will be withdrawn from the Savvy by
    /// unwrapping `yieldToken`.
    ///
    /// @param baseToken The address of the base token to swap.
    function swap(address baseToken) external;

    /// @notice Flushes funds to the amo.
    ///
    /// @param baseToken The base token to flush.
    /// @param amount          The amount to flush.
    function flushToAmo(address baseToken, uint256 amount) external;

    /// @notice Burns available credit in the savvy.
    function burnCredit() external;

    /// @notice Deposits local collateral into the savvy
    ///
    /// @param baseToken The collateral to deposit.
    /// @param amount          The amount to deposit.
    function depositFunds(address baseToken, uint256 amount) external;

    /// @notice Withdraws collateral from the savvy
    ///
    /// This function reverts if:
    /// - The caller is not the savvySwap.
    /// - There is not enough flow available to fulfill the request.
    /// - There is not enough underlying collateral in the savvy controlled by the buffer to fulfil the request.
    ///
    /// @param baseToken The base token to withdraw.
    /// @param amount          The amount to withdraw.
    /// @param recipient       The account receiving the withdrawn funds.
    function withdraw(
        address baseToken,
        uint256 amount,
        address recipient
    ) external;

    /// @notice Withdraws collateral from the savvy
    ///
    /// @param yieldToken       The yield token to withdraw.
    /// @param shares           The amount of Savvy shares to withdraw.
    /// @param minimumAmountOut The minimum amount of base tokens needed to be recieved as a result of unwrapping the yield tokens.
    function withdrawFromSavvy(
        address yieldToken,
        uint256 shares,
        uint256 minimumAmountOut
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title ISavvySwap
/// @author Savvy DeFi
interface ISavvySwap {
    /// @notice Emitted when the admin address is updated.
    ///
    /// @param admin The new admin address.
    event AdminUpdated(address admin);

    /// @notice Emitted when the pending admin address is updated.
    ///
    /// @param pendingAdmin The new pending admin address.
    event PendingAdminUpdated(address pendingAdmin);

    /// @notice Emitted when the system is paused or unpaused.
    ///
    /// @param flag `true` if the system has been paused, `false` otherwise.
    event Paused(bool flag);

    /// @dev Emitted when a deposit is performed.
    ///
    /// @param sender The address of the depositor.
    /// @param owner  The address of the account that received the deposit.
    /// @param amount The amount of tokens deposited.
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 amount
    );

    /// @dev Emitted when a withdraw is performed.
    ///
    /// @param sender    The address of the `msg.sender` executing the withdraw.
    /// @param recipient The address of the account that received the withdrawn tokens.
    /// @param amount    The amount of tokens withdrawn.
    event Withdraw(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    /// @dev Emitted when a claim is performed.
    ///
    /// @param sender    The address of the claimer / account owner.
    /// @param recipient The address of the account that received the claimed tokens.
    /// @param amount    The amount of tokens claimed.
    event Claim(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    /// @dev Emitted when an swap is performed.
    ///
    /// @param sender The address that called `swap()`.
    /// @param amount The amount of tokens swapped.
    event Swap(address indexed sender, uint256 amount);

    /// @notice Gets the version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @dev Gets the synthetic token.
    ///
    /// @return The synthetic token.
    function syntheticToken() external view returns (address);

    /// @dev Gets the supported base token.
    ///
    /// @return The base token.
    function baseToken() external view returns (address);

    /// @notice Gets the address of the allowlist contract.
    ///
    /// @return allowlist The address of the allowlist contract.
    function allowlist() external view returns (address allowlist);

    /// @dev Gets the unswapped balance of an account.
    ///
    /// @param owner The address of the account owner.
    ///
    /// @return The unswapped balance.
    function getUnswappedBalance(address owner) external view returns (uint256);

    /// @dev Gets the swapped balance of an account, in units of `debtToken`.
    ///
    /// @param owner The address of the account owner.
    ///
    /// @return The swapped balance.
    function getSwappedBalance(address owner) external view returns (uint256);

    /// @dev Gets the claimable balance of an account, in units of `baseToken`.
    ///
    /// @param owner The address of the account owner.
    ///
    /// @return The claimable balance.
    function getClaimableBalance(address owner) external view returns (uint256);

    /// @dev The conversion factor used to convert between base token amounts and debt token amounts.
    ///
    /// @return The coversion factor.
    function conversionFactor() external view returns (uint256);

    /// @dev Deposits tokens to be swapped into an account.
    ///
    /// @param amount The amount of tokens to deposit.
    /// @param owner  The owner of the account to deposit the tokens into.
    function deposit(uint256 amount, address owner) external;

    /// @dev Withdraws tokens from the caller's account that were previously deposited to be swapped.
    ///
    /// @param amount    The amount of tokens to withdraw.
    /// @param recipient The address which will receive the withdrawn tokens.
    function withdraw(uint256 amount, address recipient) external;

    /// @dev Claims swapped tokens.
    ///
    /// @param amount    The amount of tokens to claim.
    /// @param recipient The address which will receive the claimed tokens.
    function claim(uint256 amount, address recipient) external;

    /// @dev Swap `amount` base tokens for `amount` synthetic tokens staked in the system.
    ///
    /// @param amount The amount of tokens to swap.
    function swap(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../base/ErrorMessages.sol";

// a library for validating conditions.

library Checker {
    /// @dev Checks an expression and reverts with an {IllegalArgument} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkArgument(
        bool expression,
        string memory message
    ) internal pure {
        require(expression, message);
    }

    /// @dev Checks an expression and reverts with an {IllegalState} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkState(bool expression, string memory message) internal pure {
        require(expression, message);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/**
 * @notice A library which implements fixed point decimal math.
 */
library FixedPointMath {
    /** @dev This will give approximately 60 bits of precision */
    uint256 public constant DECIMALS = 18;
    uint256 public constant ONE = 10 ** DECIMALS;

    /**
     * @notice A struct representing a fixed point decimal.
     */
    struct Number {
        uint256 n;
    }

    /**
     * @notice Encodes a unsigned 256-bit integer into a fixed point decimal.
     *
     * @param value The value to encode.
     * @return      The fixed point decimal representation.
     */
    function encode(uint256 value) internal pure returns (Number memory) {
        return Number(FixedPointMath.encodeRaw(value));
    }

    /**
     * @notice Encodes a unsigned 256-bit integer into a uint256 representation of a
     *         fixed point decimal.
     *
     * @param value The value to encode.
     * @return      The fixed point decimal representation.
     */
    function encodeRaw(uint256 value) internal pure returns (uint256) {
        return value * ONE;
    }

    /**
     * @notice Creates a rational fraction as a Number from two uint256 values
     *
     * @param n The numerator.
     * @param d The denominator.
     * @return  The fixed point decimal representation.
     */
    function rational(
        uint256 n,
        uint256 d
    ) internal pure returns (Number memory) {
        Number memory numerator = encode(n);
        return FixedPointMath.div(numerator, d);
    }

    /**
     * @notice Adds two fixed point decimal numbers together.
     *
     * @param self  The left hand operand.
     * @param value The right hand operand.
     * @return      The result.
     */
    function add(
        Number memory self,
        Number memory value
    ) internal pure returns (Number memory) {
        return Number(self.n + value.n);
    }

    /**
     * @notice Subtract a fixed point decimal from another.
     *
     * @param self  The left hand operand.
     * @param value The right hand operand.
     * @return      The result.
     */
    function sub(
        Number memory self,
        Number memory value
    ) internal pure returns (Number memory) {
        return Number(self.n - value.n);
    }

    /**
     * @notice Multiplies a fixed point decimal by an unsigned 256-bit integer.
     *
     * @param self  The fixed point decimal to multiply.
     * @param value The unsigned 256-bit integer to multiply by.
     * @return      The result.
     */
    function mul(
        Number memory self,
        uint256 value
    ) internal pure returns (Number memory) {
        return Number(self.n * value);
    }

    /**
     * @notice Divides a fixed point decimal by an unsigned 256-bit integer.
     *
     * @param self  The fixed point decimal to multiply by.
     * @param value The unsigned 256-bit integer to divide by.
     * @return      The result.
     */
    function div(
        Number memory self,
        uint256 value
    ) internal pure returns (Number memory) {
        return Number(self.n / value);
    }

    /**
     * @notice Truncates a fixed point decimal into an unsigned 256-bit integer.
     *
     * @return The integer portion of the fixed point decimal.
     */
    function truncate(Number memory self) internal pure returns (uint256) {
        return self.n / ONE;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IllegalArgument} from "../base/Errors.sol";
import "./Checker.sol";

/// @title  Functions
/// @author Savvy DeFi
library Limiters {
    using Limiters for LinearGrowthLimiter;

    /// @dev A maximum cooldown to avoid malicious governance bricking the contract.
    /// @dev 1 day @ 12 sec / block
    uint256 public constant MAX_COOLDOWN_BLOCKS = 7200;

    /// @dev The scalar used to convert integral types to fixed point numbers.
    uint256 public constant FIXED_POINT_SCALAR = 1e18;

    /// @dev The configuration and state of a linear growth function (LGF).
    struct LinearGrowthLimiter {
        uint256 maximum; /// The maximum limit of the function.
        uint256 rate; /// The rate at which the function increases back to its maximum.
        uint256 lastValue; /// The most recently saved value of the function.
        uint256 lastBlock; /// The block that `lastValue` was recorded.
        uint256 minLimit; /// A minimum limit to avoid malicious governance bricking the contract
    }

    /// @dev Instantiates a new linear growth function.
    ///
    /// @param maximum The maximum value for the LGF.
    /// @param blocks  The number of blocks that determins the rate of the LGF.
    ///
    /// @return The LGF struct.
    function createLinearGrowthLimiter(
        uint256 maximum,
        uint256 blocks,
        uint256 _minLimit
    ) internal view returns (LinearGrowthLimiter memory) {
        Checker.checkArgument(blocks <= MAX_COOLDOWN_BLOCKS, "invalid blocks");
        Checker.checkArgument(maximum >= _minLimit, "invalid minLimit");

        return
            LinearGrowthLimiter({
                maximum: maximum,
                rate: (maximum * FIXED_POINT_SCALAR) / blocks,
                lastValue: maximum,
                lastBlock: block.number,
                minLimit: _minLimit
            });
    }

    /// @dev Configure an LGF.
    ///
    /// @param self    The LGF to configure.
    /// @param maximum The maximum value of the LFG.
    /// @param blocks  The number of recovery blocks of the LGF.
    function configure(
        LinearGrowthLimiter storage self,
        uint256 maximum,
        uint256 blocks
    ) internal {
        Checker.checkArgument(blocks <= MAX_COOLDOWN_BLOCKS, "invalid blocks");
        Checker.checkArgument(maximum >= self.minLimit, "invalid minLimit");

        if (self.lastValue > maximum) {
            self.lastValue = maximum;
        }

        self.maximum = maximum;
        self.rate = (maximum * FIXED_POINT_SCALAR) / blocks;
    }

    /// @dev Updates the state of an LGF by updating `lastValue` and `lastBlock`.
    ///
    /// @param self the LGF to update.
    function update(LinearGrowthLimiter storage self) internal {
        self.lastValue = self.get();
        self.lastBlock = block.number;
    }

    /// @dev Increase the value of the linear growth limiter.
    ///
    /// @param self   The linear growth limiter.
    /// @param amount The amount to decrease `lastValue`.
    function increase(
        LinearGrowthLimiter storage self,
        uint256 amount
    ) internal {
        uint256 value = self.get();
        self.lastValue = value + amount;
        self.lastBlock = block.number;
    }

    /// @dev Decrease the value of the linear growth limiter.
    ///
    /// @param self   The linear growth limiter.
    /// @param amount The amount to decrease `lastValue`.
    function decrease(
        LinearGrowthLimiter storage self,
        uint256 amount
    ) internal {
        uint256 value = self.get();
        self.lastValue = value - amount;
        self.lastBlock = block.number;
    }

    /// @dev Get the current value of the linear growth limiter.
    ///
    /// @return The current value.
    function get(
        LinearGrowthLimiter storage self
    ) internal view returns (uint256) {
        uint256 elapsed = block.number - self.lastBlock;
        if (elapsed == 0) {
            return self.lastValue;
        }
        uint256 delta = (elapsed * self.rate) / FIXED_POINT_SCALAR;
        uint256 value = self.lastValue + delta;
        return value > self.maximum ? self.maximum : value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IllegalArgument} from "../base/Errors.sol";

import {FixedPointMath} from "./FixedPointMath.sol";

/// @title  LiquidityMath
/// @author Savvy DeFi
library LiquidityMath {
    using FixedPointMath for FixedPointMath.Number;

    /// @dev Adds a signed delta to an unsigned integer.
    ///
    /// @param  x The unsigned value to add the delta to.
    /// @param  y The signed delta value to add.
    /// @return z The result.
    function addDelta(uint256 x, int256 y) internal pure returns (uint256 z) {
        if (y < 0) {
            require((z = x - uint256(-y)) < x, "IllegalArgument");
        } else {
            require((z = x + uint256(y)) >= x, "IllegalArgument");
        }
    }

    /// @dev Calculate a uint256 representation of x * y using FixedPointMath
    ///
    /// @param  x The first factor
    /// @param  y The second factor (fixed point)
    /// @return z The resulting product, after truncation
    function calculateProduct(
        uint256 x,
        FixedPointMath.Number memory y
    ) internal pure returns (uint256 z) {
        z = y.mul(x).truncate();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IllegalArgument} from "../base/Errors.sol";

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < (1 << 255), "IllegalArgument");
        z = int256(y);
    }

    /// @notice Cast a int256 to a uint256, revert on underflow
    /// @param y The int256 to be casted
    /// @return z The casted integer, now type uint256
    function toUint256(int256 y) internal pure returns (uint256 z) {
        require(y >= 0, "IllegalArgument");
        z = uint256(y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title  Sets
/// @author Savvy DeFi
library Sets {
    using Sets for AddressSet;

    /// @notice A data structure holding an array of values with an index mapping for O(1) lookup.
    struct AddressSet {
        address[] values;
        mapping(address => uint256) indexes;
    }

    /// @dev Add a value to a Set
    ///
    /// @param self  The Set.
    /// @param value The value to add.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value is already contained in the Set)
    function add(
        AddressSet storage self,
        address value
    ) internal returns (bool) {
        if (self.contains(value)) {
            return false;
        }
        self.values.push(value);
        self.indexes[value] = self.values.length;
        return true;
    }

    /// @dev Remove a value from a Set
    ///
    /// @param self  The Set.
    /// @param value The value to remove.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value was not contained in the Set)
    function remove(
        AddressSet storage self,
        address value
    ) internal returns (bool) {
        uint256 index = self.indexes[value];
        if (index == 0) {
            return false;
        }

        // Normalize the index since we know that the element is in the set.
        index--;

        uint256 lastIndex = self.values.length - 1;

        if (index != lastIndex) {
            address lastValue = self.values[lastIndex];
            self.values[index] = lastValue;
            self.indexes[lastValue] = index + 1;
        }

        self.values.pop();

        delete self.indexes[value];

        return true;
    }

    /// @dev Returns true if the value exists in the Set
    ///
    /// @param self  The Set.
    /// @param value The value to check.
    ///
    /// @return True if the value is contained in the Set, False if it is not.
    function contains(
        AddressSet storage self,
        address value
    ) internal view returns (bool) {
        return self.indexes[value] != 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {FixedPointMath} from "./FixedPointMath.sol";

library Tick {
    using FixedPointMath for FixedPointMath.Number;

    struct Info {
        // The total number of unexchanged tokens that have been associated with this tick
        uint256 totalBalance;
        // The accumulated weight of the tick which is the sum of the previous ticks accumulated weight plus the weight
        // that added at the time that this tick was created
        FixedPointMath.Number accumulatedWeight;
        // The previous active node. When this value is zero then there is no predecessor
        uint256 prev;
        // The next active node. When this value is zero then there is no successor
        uint256 next;
    }

    struct Cache {
        // The mapping which specifies the ticks in the buffer
        mapping(uint256 => Info) values;
        // The current tick which is being written to
        uint256 position;
        // The first tick which will be examined when iterating through the queue
        uint256 head;
        // The last tick which new nodes will be appended after
        uint256 tail;
    }

    /// @dev Gets the next tick in the buffer.
    ///
    /// This increments the position in the buffer.
    ///
    /// @return The next tick.
    function next(
        Tick.Cache storage self
    ) internal returns (Tick.Info storage) {
        self.position++;
        return self.values[self.position];
    }

    /// @dev Gets the current tick being written to.
    ///
    /// @return The current tick.
    function current(
        Tick.Cache storage self
    ) internal view returns (Tick.Info storage) {
        return self.values[self.position];
    }

    /// @dev Gets the nth tick in the buffer.
    ///
    /// @param self The reference to the buffer.
    /// @param n    The nth tick to get.
    function get(
        Tick.Cache storage self,
        uint256 n
    ) internal view returns (Tick.Info storage) {
        return self.values[n];
    }

    function getWeight(
        Tick.Cache storage self,
        uint256 from,
        uint256 to
    ) internal view returns (FixedPointMath.Number memory) {
        Tick.Info storage startingTick = self.values[from];
        Tick.Info storage endingTick = self.values[to];

        FixedPointMath.Number memory startingAccumulatedWeight = startingTick
            .accumulatedWeight;
        FixedPointMath.Number memory endingAccumulatedWeight = endingTick
            .accumulatedWeight;

        return endingAccumulatedWeight.sub(startingAccumulatedWeight);
    }

    function addLast(Tick.Cache storage self, uint256 id) internal {
        if (self.head == 0) {
            self.head = self.tail = id;
            return;
        }

        // Don't add the tick if it is already the tail. This has to occur after the check if the head
        // is null since the tail may not be updated once the queue is made empty.
        if (self.tail == id) {
            return;
        }

        Tick.Info storage tick = self.values[id];
        Tick.Info storage tail = self.values[self.tail];

        tick.prev = self.tail;
        tail.next = id;
        self.tail = id;
    }

    function remove(Tick.Cache storage self, uint256 id) internal {
        Tick.Info storage tick = self.values[id];

        // Update the head if it is the tick we are removing.
        if (self.head == id) {
            self.head = tick.next;
        }

        // Update the tail if it is the tick we are removing.
        if (self.tail == id) {
            self.tail = tick.prev;
        }

        // Unlink the previously occupied tick from the next tick in the list.
        if (tick.prev != 0) {
            self.values[tick.prev].next = tick.next;
        }

        // Unlink the previously occupied tick from the next tick in the list.
        if (tick.next != 0) {
            self.values[tick.next].prev = tick.prev;
        }

        // Zero out the pointers.
        // NOTE(nomad): This fixes the bug where the current accrued weight would get erased.
        self.values[id].next = 0;
        self.values[id].prev = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "../interfaces/savvy/ISavvyErrors.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IERC20Mintable.sol";

/// @title  TokenUtils
/// @author Savvy DeFi
library TokenUtils {
    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        require(success, Errors.ERC20CALLFAILED_EXPECTDECIMALS);

        return abi.decode(data, (uint8));
    }

    /// @dev Gets the balance of tokens held by an account.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token   The token to check the balance of.
    /// @param account The address of the token holder.
    ///
    /// @return The balance of the tokens held by an account.
    function safeBalanceOf(
        address token,
        address account
    ) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, account)
        );
        require(success, Errors.ERC20CALLFAILED_SAFEBALANCEOF);

        return abi.decode(data, (uint256));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.transfer.selector,
                recipient,
                amount
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFETRANSFER);
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.approve.selector,
                spender,
                value
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFEAPPROVE);
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(
        address token,
        address owner,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balanceBefore = IERC20Minimal(token).balanceOf(recipient);
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.transferFrom.selector,
                owner,
                recipient,
                amount
            )
        );
        uint256 balanceAfter = IERC20Minimal(token).balanceOf(recipient);

        require(success, Errors.ERC20CALLFAILED_SAFETRANSFERFROM);

        return (balanceAfter - balanceBefore);
    }

    /// @dev Mints tokens to an address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.
    ///
    /// @param token     The token to mint.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to mint.
    function safeMint(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Mintable.mint.selector,
                recipient,
                amount
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFEMINT);
    }

    /// @dev Burns tokens.
    ///
    /// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param amount The amount of tokens to burn.
    function safeBurn(address token, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burn.selector, amount)
        );

        require(success, Errors.ERC20CALLFAILED_SAFEBURN);
    }

    /// @dev Burns tokens from its total supply.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param owner  The owner of the tokens.
    /// @param amount The amount of tokens to burn.
    function safeBurnFrom(
        address token,
        address owner,
        uint256 amount
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Burnable.burnFrom.selector,
                owner,
                amount
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFEBURNFROM);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./base/Errors.sol";

import "./interfaces/IAllowlist.sol";

import "./interfaces/savvySwap/ISavvySwap.sol";
import "./interfaces/savvySwap/ISavvySage.sol";

import "./libraries/FixedPointMath.sol";
import "./libraries/LiquidityMath.sol";
import "./libraries/SafeCast.sol";
import "./libraries/Tick.sol";
import "./libraries/TokenUtils.sol";
import "./libraries/Checker.sol";

/// @title SavvySwap
///
/// @notice A contract which facilitates the swap of synthetic tokens for their base token.
//  @notice This contract guarantees that synthetic tokens are swapped exactly 1:1 for the base token.
contract SavvySwap is
    ISavvySwap,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    using FixedPointMath for FixedPointMath.Number;
    using Tick for Tick.Cache;

    struct Account {
        // The total number of unswapped tokens that an account has deposited into the system
        uint256 unswappedBalance;
        // The total number of swapped tokens that an account has had credited
        uint256 swappedBalance;
        // The tick that the account has had their deposit associated in
        uint256 occupiedTick;
    }

    struct UpdateAccountParams {
        // The owner address whose account will be modified
        address owner;
        // The amount to change the account's unswapped balance by
        int256 unswappedDelta;
        // The amount to change the account's swapped balance by
        int256 swappedDelta;
    }

    struct SwapCache {
        // The total number of unswapped tokens that exist at the start of the swap call
        uint256 totalUnswapped;
        // The tick which has been satisfied up to at the start of the swap call
        uint256 satisfiedTick;
        // The head of the active ticks queue at the start of the swap call
        uint256 ticksHead;
    }

    struct SwapState {
        // The position in the buffer of current tick which is being examined
        uint256 examineTick;
        // The total number of unswapped tokens that currently exist in the system for the current distribution step
        uint256 totalUnswapped;
        // The tick which has been satisfied up to, inclusive
        uint256 satisfiedTick;
        // The amount of tokens to distribute for the current step
        uint256 distributeAmount;
        // The accumulated weight to write at the new tick after the swap is completed
        FixedPointMath.Number accumulatedWeight;
        // Reserved for the maximum weight of the current distribution step
        FixedPointMath.Number maximumWeight;
        // Reserved for the dusted weight of the current distribution step
        FixedPointMath.Number dustedWeight;
    }

    struct UpdateAccountCache {
        // The total number of unswapped tokens that the account held at the start of the update call
        uint256 unswappedBalance;
        // The total number of swapped tokens that the account held at the start of the update call
        uint256 swappedBalance;
        // The tick that the account's deposit occupies at the start of the update call
        uint256 occupiedTick;
        // The total number of unswapped tokens that exist at the start of the update call
        uint256 totalUnswapped;
        // The current tick that is being written to
        uint256 currentTick;
    }

    struct UpdateAccountState {
        // The updated unswapped balance of the account being updated
        uint256 unswappedBalance;
        // The updated swapped balance of the account being updated
        uint256 swappedBalance;
        // The updated total unswapped balance
        uint256 totalUnswapped;
    }

    address public constant ZERO_ADDRESS = address(0);

    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN = keccak256("ADMIN");

    /// @dev The identitifer of the sentinel role
    bytes32 public constant SENTINEL = keccak256("SENTINEL");

    /// @inheritdoc ISavvySwap
    string public constant override version = "1.0.0";

    /// @dev the synthetic token to be savvy swapped
    address public override syntheticToken;

    /// @dev the base token to be received
    address public override baseToken;

    /// @dev The total amount of unswapped tokens which are held by all accounts.
    uint256 public totalUnswapped;

    /// @dev The total amount of tokens which are in the auxiliary buffer.
    uint256 public totalBuffered;

    /// @dev A mapping specifying all of the accounts.
    mapping(address => Account) private accounts;

    // @dev The tick buffer which stores all of the tick information along with the tick that is
    //      currently being written to. The "current" tick is the tick at the buffer write position.
    Tick.Cache private ticks;

    // The tick which has been satisfied up to, inclusive.
    uint256 private satisfiedTick;

    /// @dev contract pause state
    bool public isPaused;

    /// @dev the source of the swapped collateral
    address public buffer;

    /// @dev The address of the external allowlist contract.
    address public override allowlist;

    /// @dev The amount of decimal places needed to normalize collateral to debtToken
    uint256 public override conversionFactor;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _syntheticToken,
        address _baseToken,
        address _buffer,
        address _allowlist
    ) external initializer {
        __ReentrancyGuard_init_unchained();
        __AccessControl_init_unchained();

        _grantRole(ADMIN, msg.sender);
        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(SENTINEL, ADMIN);

        syntheticToken = _syntheticToken;
        baseToken = _baseToken;
        uint8 debtTokenDecimals = TokenUtils.expectDecimals(syntheticToken);
        uint8 baseTokenDecimals = TokenUtils.expectDecimals(baseToken);
        conversionFactor = 10 ** (debtTokenDecimals - baseTokenDecimals);
        buffer = _buffer;
        // Push a blank tick to function as a sentinel value in the active ticks queue.
        ticks.next();

        isPaused = false;
        allowlist = _allowlist;
    }

    /// @dev A modifier which checks if caller is an savvy.
    modifier onlySage() {
        require(msg.sender == buffer, "Unauthorized savvySage");
        _;
    }

    /// @dev A modifier which checks if caller is a sentinel or admin.
    modifier onlySentinelOrAdmin() {
        require(
            hasRole(SENTINEL, msg.sender) || hasRole(ADMIN, msg.sender),
            "Unauthorized sentinel or admin"
        );
        _;
    }

    /// @dev A modifier which checks if contract is a paused.
    modifier notPaused() {
        Checker.checkState(!isPaused, "paused");
        _;
    }

    function _onlyAdmin() internal view {
        require(hasRole(ADMIN, msg.sender), "Unauthorized admin");
    }

    function setCollateralSource(address _newCollateralSource) external {
        _onlyAdmin();
        buffer = _newCollateralSource;
    }

    function setPause(bool pauseState) external onlySentinelOrAdmin {
        isPaused = pauseState;
        emit Paused(isPaused);
    }

    /// @inheritdoc ISavvySwap
    function deposit(
        uint256 amount,
        address owner
    ) external override nonReentrant notPaused {
        _onlyAllowlisted();
        amount = TokenUtils.safeTransferFrom(
            syntheticToken,
            msg.sender,
            address(this),
            amount
        );
        _updateAccount(
            UpdateAccountParams({
                owner: owner,
                unswappedDelta: SafeCast.toInt256(amount),
                swappedDelta: 0
            })
        );
        emit Deposit(msg.sender, owner, amount);
    }

    /// @inheritdoc ISavvySwap
    function withdraw(
        uint256 amount,
        address recipient
    ) external override nonReentrant {
        _onlyAllowlisted();
        _updateAccount(
            UpdateAccountParams({
                owner: msg.sender,
                unswappedDelta: -SafeCast.toInt256(amount),
                swappedDelta: 0
            })
        );
        TokenUtils.safeTransfer(syntheticToken, recipient, amount);
        emit Withdraw(msg.sender, recipient, amount);
    }

    /// @inheritdoc ISavvySwap
    function claim(
        uint256 amount,
        address recipient
    ) external override nonReentrant {
        _onlyAllowlisted();

        uint256 debtAmount = _normalizeBaseTokensToDebt(amount);
        _updateAccount(
            UpdateAccountParams({
                owner: msg.sender,
                unswappedDelta: 0,
                swappedDelta: -SafeCast.toInt256(debtAmount)
            })
        );
        TokenUtils.safeBurn(syntheticToken, debtAmount);
        ISavvySage(buffer).withdraw(baseToken, amount, recipient);
        emit Claim(msg.sender, recipient, amount);
    }

    /// @inheritdoc ISavvySwap
    function swap(
        uint256 amount
    ) external override nonReentrant onlySage notPaused {
        uint256 normalizedAmount = _normalizeBaseTokensToDebt(amount);

        if (totalUnswapped == 0) {
            totalBuffered += normalizedAmount;
            emit Swap(msg.sender, amount);
            return;
        }

        // Push a storage reference to the current tick.
        Tick.Info storage current = ticks.current();

        SwapCache memory cache = SwapCache({
            totalUnswapped: totalUnswapped,
            satisfiedTick: satisfiedTick,
            ticksHead: ticks.head
        });

        SwapState memory state = SwapState({
            examineTick: cache.ticksHead,
            totalUnswapped: cache.totalUnswapped,
            satisfiedTick: cache.satisfiedTick,
            distributeAmount: normalizedAmount,
            accumulatedWeight: current.accumulatedWeight,
            maximumWeight: FixedPointMath.encode(0),
            dustedWeight: FixedPointMath.encode(0)
        });

        // Distribute the buffered tokens as part of the swap.
        state.distributeAmount += totalBuffered;
        totalBuffered = 0;

        // Push a storage reference to the next tick to write to.
        Tick.Info storage next = ticks.next();

        // Only iterate through the active ticks queue when it is not empty.
        while (state.examineTick != 0) {
            // Check if there is anything left to distribute.
            if (state.distributeAmount == 0) {
                break;
            }

            Tick.Info storage examineTickData = ticks.get(state.examineTick);

            // Add the weight for the distribution step to the accumulated weight.
            state.accumulatedWeight = state.accumulatedWeight.add(
                FixedPointMath.rational(
                    state.distributeAmount,
                    state.totalUnswapped
                )
            );

            // Clear the distribute amount.
            state.distributeAmount = 0;

            // Calculate the current maximum weight in the system.
            state.maximumWeight = state.accumulatedWeight.sub(
                examineTickData.accumulatedWeight
            );

            // Check if there exists at least one account which is completely satisfied..
            if (state.maximumWeight.n < FixedPointMath.ONE) {
                break;
            }

            // Calculate how much weight of the distributed weight is dust.
            state.dustedWeight = FixedPointMath.Number(
                state.maximumWeight.n - FixedPointMath.ONE
            );

            // Calculate how many tokens to distribute in the next step. These are tokens from any tokens which
            // were over allocated to accounts occupying the tick with the maximum weight.
            state.distributeAmount = LiquidityMath.calculateProduct(
                examineTickData.totalBalance,
                state.dustedWeight
            );

            // Remove the tokens which were completely swapped from the total unswapped balance.
            state.totalUnswapped -= examineTickData.totalBalance;

            // Write that all ticks up to and including the examined tick have been satisfied.
            state.satisfiedTick = state.examineTick;

            // Visit the next active tick. This is equivalent to popping the head of the active ticks queue.
            state.examineTick = examineTickData.next;
        }

        // Write the accumulated weight to the next tick.
        next.accumulatedWeight = state.accumulatedWeight;

        if (cache.totalUnswapped != state.totalUnswapped) {
            totalUnswapped = state.totalUnswapped;
        }

        if (cache.satisfiedTick != state.satisfiedTick) {
            satisfiedTick = state.satisfiedTick;
        }

        if (cache.ticksHead != state.examineTick) {
            ticks.head = state.examineTick;
        }

        if (state.distributeAmount > 0) {
            totalBuffered += state.distributeAmount;
        }

        emit Swap(msg.sender, amount);
    }

    /// @inheritdoc ISavvySwap
    function getUnswappedBalance(
        address owner
    ) external view override returns (uint256 unswappedBalance) {
        Account storage account = accounts[owner];

        if (account.occupiedTick <= satisfiedTick) {
            return 0;
        }

        unswappedBalance = account.unswappedBalance;

        uint256 swapped = LiquidityMath.calculateProduct(
            unswappedBalance,
            ticks.getWeight(account.occupiedTick, ticks.position)
        );

        unswappedBalance -= swapped;

        return unswappedBalance;
    }

    /// @inheritdoc ISavvySwap
    function getSwappedBalance(
        address owner
    ) external view override returns (uint256 swappedBalance) {
        return _getswappedBalance(owner);
    }

    function getClaimableBalance(
        address owner
    ) external view override returns (uint256 claimableBalance) {
        return _normalizeDebtTokensToUnderlying(_getswappedBalance(owner));
    }

    /// @dev Updates an account.
    ///
    /// @param params The call parameters.
    function _updateAccount(UpdateAccountParams memory params) internal {
        Account storage account = accounts[params.owner];

        UpdateAccountCache memory cache = UpdateAccountCache({
            unswappedBalance: account.unswappedBalance,
            swappedBalance: account.swappedBalance,
            occupiedTick: account.occupiedTick,
            totalUnswapped: totalUnswapped,
            currentTick: ticks.position
        });

        UpdateAccountState memory state = UpdateAccountState({
            unswappedBalance: cache.unswappedBalance,
            swappedBalance: cache.swappedBalance,
            totalUnswapped: cache.totalUnswapped
        });

        // Updating an account is broken down into five steps:
        // 1). Synchronize the account if it previously occupied a satisfied tick
        // 2). Update the account balances to account for swapped tokens, if any
        // 3). Apply the deltas to the account balances
        // 4). Update the previously occupied and/or current tick's liquidity
        // 5). Commit changes to the account and global state when needed

        // Step one:
        // ---------
        // Check if the tick that the account was occupying previously was satisfied. If it was, we acknowledge
        // that all of the tokens were swapped.
        if (state.unswappedBalance > 0 && satisfiedTick >= cache.occupiedTick) {
            state.unswappedBalance = 0;
            state.swappedBalance += cache.unswappedBalance;
        }

        // Step Two:
        // ---------
        // Calculate how many tokens were swapped since the last update.
        if (state.unswappedBalance > 0) {
            uint256 swapped = LiquidityMath.calculateProduct(
                state.unswappedBalance,
                ticks.getWeight(cache.occupiedTick, cache.currentTick)
            );

            state.totalUnswapped -= swapped;
            state.unswappedBalance -= swapped;
            state.swappedBalance += swapped;
        }

        // Step Three:
        // -----------
        // Apply the unswapped and swapped deltas to the state.
        state.totalUnswapped = LiquidityMath.addDelta(
            state.totalUnswapped,
            params.unswappedDelta
        );
        state.unswappedBalance = LiquidityMath.addDelta(
            state.unswappedBalance,
            params.unswappedDelta
        );
        state.swappedBalance = LiquidityMath.addDelta(
            state.swappedBalance,
            params.swappedDelta
        );

        // Step Four:
        // ----------
        // The following is a truth table relating various values which in combinations specify which logic branches
        // need to be executed in order to update liquidity in the previously occupied and/or current tick.
        //
        // Some states are not obtainable and are just discarded by setting all the branches to false.
        //
        // | P | C | M | Modify Liquidity | Add Liquidity | Subtract Liquidity |
        // |---|---|---|------------------|---------------|--------------------|
        // | F | F | F | F                | F             | F                  |
        // | F | F | T | F                | F             | F                  |
        // | F | T | F | F                | T             | F                  |
        // | F | T | T | F                | T             | F                  |
        // | T | F | F | F                | F             | T                  |
        // | T | F | T | F                | F             | T                  |
        // | T | T | F | T                | F             | F                  |
        // | T | T | T | F                | T             | T                  |
        //
        // | Branch             | Reduction |
        // |--------------------|-----------|
        // | Modify Liquidity   | PCM'      |
        // | Add Liquidity      | P'C + CM  |
        // | Subtract Liquidity | PC' + PM  |

        bool previouslyActive = cache.unswappedBalance > 0;
        bool currentlyActive = state.unswappedBalance > 0;
        bool migrate = cache.occupiedTick != cache.currentTick;

        bool modifyLiquidity = previouslyActive && currentlyActive && !migrate;

        if (modifyLiquidity) {
            Tick.Info storage tick = ticks.get(cache.occupiedTick);

            // Consolidate writes to save gas.
            uint256 totalBalance = tick.totalBalance;
            totalBalance -= cache.unswappedBalance;
            totalBalance += state.unswappedBalance;
            tick.totalBalance = totalBalance;
        } else {
            bool addLiquidity = (!previouslyActive && currentlyActive) ||
                (currentlyActive && migrate);
            bool subLiquidity = (previouslyActive && !currentlyActive) ||
                (previouslyActive && migrate);

            if (addLiquidity) {
                Tick.Info storage tick = ticks.get(cache.currentTick);

                if (tick.totalBalance == 0) {
                    ticks.addLast(cache.currentTick);
                }

                tick.totalBalance += state.unswappedBalance;
            }

            if (subLiquidity) {
                Tick.Info storage tick = ticks.get(cache.occupiedTick);
                tick.totalBalance -= cache.unswappedBalance;

                if (tick.totalBalance == 0) {
                    ticks.remove(cache.occupiedTick);
                }
            }
        }

        // Step Five:
        // ----------
        // Commit the changes to the account.
        if (cache.unswappedBalance != state.unswappedBalance) {
            account.unswappedBalance = state.unswappedBalance;
        }

        if (cache.swappedBalance != state.swappedBalance) {
            account.swappedBalance = state.swappedBalance;
        }

        if (cache.totalUnswapped != state.totalUnswapped) {
            totalUnswapped = state.totalUnswapped;
        }

        if (cache.occupiedTick != cache.currentTick) {
            account.occupiedTick = cache.currentTick;
        }
    }

    /// @dev Checks the allowlist for msg.sender.
    ///
    /// @notice Reverts if msg.sender is not in the allowlist.
    function _onlyAllowlisted() internal view {
        // Check if the message sender is an EOA. In the future, this potentially may break. It is important that
        // functions which rely on the allowlist not be explicitly vulnerable in the situation where this no longer
        // holds true.
        address sender = msg.sender;
        require(
            tx.origin == sender || IAllowlist(allowlist).isAllowed(sender),
            "Unauthorized collateral source"
        );
    }

    /// @dev Normalize `amount` of `baseToken` to a value which is comparable to units of the debt token.
    ///
    /// @param amount          The amount of the debt token.
    ///
    /// @return The normalized amount.
    function _normalizeBaseTokensToDebt(
        uint256 amount
    ) internal view returns (uint256) {
        return amount * conversionFactor;
    }

    /// @dev Normalize `amount` of the debt token to a value which is comparable to units of `baseToken`.
    ///
    /// @dev This operation will result in truncation of some of the least significant digits of `amount`. This
    ///      truncation amount will be the least significant N digits where N is the difference in decimals between
    ///      the debt token and the base token.
    ///
    /// @param amount          The amount of the debt token.
    ///
    /// @return The normalized amount.
    function _normalizeDebtTokensToUnderlying(
        uint256 amount
    ) internal view returns (uint256) {
        return amount / conversionFactor;
    }

    function _getswappedBalance(
        address owner
    ) internal view returns (uint256 swappedBalance) {
        Account storage account = accounts[owner];

        if (account.occupiedTick <= satisfiedTick) {
            swappedBalance = account.swappedBalance;
            swappedBalance += account.unswappedBalance;
            return swappedBalance;
        }

        swappedBalance = account.swappedBalance;

        uint256 swapped = LiquidityMath.calculateProduct(
            account.unswappedBalance,
            ticks.getWeight(account.occupiedTick, ticks.position)
        );

        swappedBalance += swapped;

        return swappedBalance;
    }

    uint256[100] private __gap;
}