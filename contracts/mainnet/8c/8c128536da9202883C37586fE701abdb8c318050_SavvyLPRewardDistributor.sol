// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

/// @title Savvy LP Reward Distributor
/// @author Savvy DeFi
/// @dev manage rewards for Savvy LPers.

interface ISavvyLPRewardDistributor {
  struct AccountRewards {
    /// @notice The user earning rewards.
    address user;
    /// @notice The lp token the rewards are associated with.
    address lpToken;
    /// @notice The rewards the user can claim from this source.
    uint256 claimableRewards;
    /// @notice The rewards that have already been claimed.
    uint256 claimedRewards;
    /// @notice The last time this source was claimed.
    uint256 lastClaimed;
  }

  struct UpdatedRewards {
    /// @notice The user to update the rewards for.
    address user;
    /// @notice The lp token to update the rewards for.
    address lpToken;
    /// @notice The new rewards that will be added to the user's existing claimable balance.
    uint256 newRewards;
  }

  struct SourceRewards {
    /// @notice The lp token to get the rewards for.
    address lpToken;
    /// @notice The total rewards for the lp token.
    uint256 totalRewards;
    /// @notice Whether the lp token is a valid source of rewards.
    bool enabled;
  }

  /// @notice The last timestamp the rewards were updated.
  /// @return lastUpdatedTimestamp The last timestamp the rewards were updated.
  function lastUpdated() external view returns (uint256 lastUpdatedTimestamp);

  /// @notice Gets all the lp sources for the rewarder.
  /// @return lpSources_ The lp sources.
  function lpSources()
    external
    view
    returns (SourceRewards[] memory lpSources_);

  /// @notice sets whether an LP token is a valid source of rewards.
  /// @param _lpTokens The lp tokens to set the validity of.
  /// @param _enabled Whether the lp token is a valid source of rewards.
  function setLpSources(address[] calldata _lpTokens, bool _enabled) external;

  /// @notice Record new rewards for users.
  /// @dev will revert if the caller is not a keeper.
  /// @param _updatedRewards The updated rewards to record. This will add
  /// on to the existing rewards for the user and the source.
  function recordNewRewards(
    UpdatedRewards[] calldata _updatedRewards,
    uint256 timestamp
  ) external;

  /// @notice Gets the total claimable SVY rewards across all LP sources for the user.
  /// @param _user The user to get the total claimable rewards for.
  /// @return totalClaimableRewards The total claimable SVY rewards for the user.
  /// @return claimableRewardsBySource The claimable SVY rewards for the user by source.
  function getTotalClaimableRewards(
    address _user
  )
    external
    view
    returns (
      uint256 totalClaimableRewards,
      AccountRewards[] memory claimableRewardsBySource
    );

  /// @notice Gets the total claimable SVY rewards across all LP sources for the user.
  /// @param _user The user to get the total claimable rewards for.
  /// @param _lpTokens The lp tokens to get the total claimable rewards for.
  /// @return totalClaimableRewards The total claimable SVY rewards for the user.
  /// @return claimableRewardsBySource The claimable SVY rewards for the user by source.
  function getClaimableRewards(
    address _user,
    address[] calldata _lpTokens
  )
    external
    view
    returns (
      uint256 totalClaimableRewards,
      AccountRewards[] memory claimableRewardsBySource
    );

  /// @notice Gets the total claimable SVY rewards across all LP sources for the user.
  /// @dev This is equivalent to calling
  /// ```solidity
  /// claimRewards(_user, lpSources())
  /// ```
  /// @param _user The user to get the total claimable rewards for.
  /// @return rewardsClaimed The total claimed SVY rewards for the user.
  /// @return rewardsClaimedBySource The claimed SVY rewards for the user by source.
  function claimAllRewards(
    address _user
  )
    external
    returns (
      uint256 rewardsClaimed,
      AccountRewards[] memory rewardsClaimedBySource
    );

  /// @notice Gets the total claimable SVY rewards across all LP sources for the user.
  /// @param _user The user to get the total claimable rewards for.
  /// @param _lpTokens The lp sources to claim from.
  /// @return rewardsClaimed The total claimed SVY rewards for the user.
  /// @return rewardsClaimedBySource The claimed SVY rewards for the user by source.
  function claimRewards(
    address _user,
    address[] calldata _lpTokens
  )
    external
    returns (
      uint256 rewardsClaimed,
      AccountRewards[] memory rewardsClaimedBySource
    );

  /// @notice Stake all the claimable SVY rewards on behalf of the user.
  /// The user can then withdraw the staked rewards at any time using `veSVY`.
  /// @dev This is equivalent to calling
  /// ```solidity
  /// stakeRewards(_user, lpSources())
  /// ```
  /// @param _user The user to stake rewards on behalf of.
  /// @return rewardsStaked The total staked SVY rewards for the user.
  /// @return rewardsStakedBySource The staked SVY rewards for the user by source.
  function stakeAllRewards(
    address _user
  )
    external
    returns (
      uint256 rewardsStaked,
      AccountRewards[] memory rewardsStakedBySource
    );

  /// @notice Stake specific claimable SVY rewards based on source on behalf of the user.
  /// The user can then withdraw the staked rewards at any time using `veSVY`.
  /// @param _user The user to stake rewards on behalf of.
  /// @param _lpTokens The lp sources to stake rewards from.
  /// @return rewardsStaked The total staked SVY rewards for the user.
  /// @return rewardsStakedBySource The staked SVY rewards for the user by source.
  function stakeRewards(
    address _user,
    address[] calldata _lpTokens
  )
    external
    returns (
      uint256 rewardsStaked,
      AccountRewards[] memory rewardsStakedBySource
    );

  /// @notice Claim and stake specific sources for a user.
  /// Staked rewards can be withdrawn at any time using `veSVY`.
  /// @param _user The user to stake rewards on behalf of.
  /// @param _lpSourceToClaim The lp sources to claim rewards from.
  /// @param _lpSourceToStake The lp sources to stake rewards from.
  /// @return rewardsClaimed The total claimed SVY rewards for the user.
  /// @return rewardsClaimedBySource The claimed SVY rewards for the user by source.
  /// @return rewardsStaked The total staked SVY rewards for the user.
  /// @return rewardsStakedBySource The staked SVY rewards for the user by source.
  function claimAndStakeRewards(
    address _user,
    address[] calldata _lpSourceToClaim,
    address[] calldata _lpSourceToStake
  )
    external
    returns (
      uint256 rewardsClaimed,
      AccountRewards[] memory rewardsClaimedBySource,
      uint256 rewardsStaked,
      AccountRewards[] memory rewardsStakedBySource
    );

  event LpSourceUpdated(address indexed lpToken, bool enabled);

  event RewardsRecorded(
    address indexed user,
    address indexed lpToken,
    uint256 newRewards,
    uint256 totalRewards
  );

  event RewardsClaimed(
    address indexed user,
    address indexed lpToken,
    uint256 claimedRewards,
    bool indexed isClaimStaked
  );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IVeERC20.sol";

/**
 * @dev Interface of the VeSvy
 */
interface IVeSvy is IVeERC20 {
    function isUser(address _addr) external view returns (bool);

    function stake(uint256 _amount) external;

    function stakeFor(address _recipient, uint256 _amount) external;

    function claimable(address _addr) external view returns (uint256);

    function claim() external;

    function unstake(uint256 _amount) external;

    function getStakedSvy(address _addr) external view returns (uint256);

    function getVotes(address _account) external view returns (uint256);

    function getVeSVYEarnRatePerSec(
        address _addr
    ) external view returns (uint256);

    function getMaxVeSVYEarnable(address _addr) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

import "../interfaces/savvy/ISavvyErrors.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IERC20Mintable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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
        SafeERC20.safeTransfer(IERC20(token), recipient, amount);
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
        SafeERC20.safeIncreaseAllowance(IERC20(token), spender, value);
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
        SafeERC20.safeTransferFrom(IERC20(token), owner, recipient, amount);
        uint256 balanceAfter = IERC20Minimal(token).balanceOf(recipient);

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
pragma solidity 0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./libraries/TokenUtils.sol";
import "./interfaces/ISavvyLPRewardDistributor.sol";
import "./interfaces/IVeSvy.sol";
import "./base/ErrorMessages.sol";

/// @title SavvyLPRewardDistributor
contract SavvyLPRewardDistributor is
  ISavvyLPRewardDistributor,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable
{
  /// @notice The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN = keccak256("ADMIN");

  /// @notice The identifier of the keeper role.
  bytes32 public constant KEEPER = keccak256("KEEPER");

  /// @notice The storage pointer of last updated reward time
  uint256 _lastUpdated;

  /// @notice The array of LP tokens
  address[] public lpTokenList;

  /// @notice The pointer to VeSvy smart contract
  IVeSvy public veSVY;

  /// @notice The smart contract address of SVY token
  address public SVY;

  /// @notice The mapping of lpToken address to SourceRewards.
  mapping(address => SourceRewards) sourceRewards;

  /// @notice The mapping of the lpToken to user to AccountRewards.
  ///     lp source => user => AccountRewards
  mapping(address => mapping(address => AccountRewards)) _accountRewards;

  /// @dev check if user is _msgSender()
  modifier isMsgSender(address _user) {
    require(_user == _msgSender(), "Invalid Caller");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(
    address admin,
    address keeper,
    address svy,
    address veSvy
  ) external initializer {
    __ReentrancyGuard_init();

    _grantRole(ADMIN, admin);
    _grantRole(KEEPER, keeper);
    _grantRole(DEFAULT_ADMIN_ROLE, admin);

    _setRoleAdmin(KEEPER, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(ADMIN, DEFAULT_ADMIN_ROLE);

    SVY = svy;
    veSVY = IVeSvy(veSvy);
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function lpSources()
    external
    view
    returns (SourceRewards[] memory lpSources_)
  {
    uint256 length = lpTokenList.length;
    address[] memory lpTokens = new address[](length);
    lpTokens = lpTokenList;
    lpSources_ = new SourceRewards[](length);

    for (uint256 i; i < length; ++i) {
      lpSources_[i] = sourceRewards[lpTokens[i]];
    }
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function setLpSources(
    address[] calldata _lpTokens,
    bool _enabled
  ) external onlyRole(ADMIN) {
    uint256 length = _lpTokens.length;
    address lpToken;

    SourceRewards memory sourceReward;

    for (uint256 i; i < length; ++i) {
      lpToken = _lpTokens[i];

      if (lpToken == address(0)) {
        revert IllegalArgumentWithReason("Zero LP token address");
      }
      sourceReward = sourceRewards[lpToken];

      if (sourceReward.lpToken == address(0)) {
        lpTokenList.push(lpToken);
        sourceRewards[lpToken] = SourceRewards(lpToken, 0, _enabled);
      } else {
        sourceRewards[lpToken].enabled = _enabled;
      }
      emit LpSourceUpdated(lpToken, _enabled);
    }
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function recordNewRewards(
    UpdatedRewards[] calldata _updatedRewards,
    uint256 timestamp
  ) external onlyRole(KEEPER) nonReentrant {
    uint256 totalAmount;
    uint256 rewardsLength = _updatedRewards.length;

    UpdatedRewards memory updatedRewards;
    AccountRewards storage accountRewards;

    for (uint256 i; i < rewardsLength; ++i) {
      updatedRewards = _updatedRewards[i];

      if (!sourceRewards[updatedRewards.lpToken].enabled) {
        revert IllegalArgumentWithReason("Disabled source included");
      }

      accountRewards = _accountRewards[updatedRewards.lpToken][
        updatedRewards.user
      ];

      if (accountRewards.user == address(0)) {
        accountRewards.user = updatedRewards.user;
        accountRewards.lpToken = updatedRewards.lpToken;
      }

      accountRewards.claimableRewards += updatedRewards.newRewards;
      totalAmount += updatedRewards.newRewards;

      emit RewardsRecorded(
        updatedRewards.user,
        updatedRewards.lpToken,
        updatedRewards.newRewards,
        _accountRewards[updatedRewards.lpToken][updatedRewards.user]
          .claimableRewards
      );
    }

    TokenUtils.safeTransferFrom(SVY, _msgSender(), address(this), totalAmount);

    if (timestamp == 0) _lastUpdated = block.timestamp;
    else _lastUpdated = timestamp;
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function lastUpdated() external view returns (uint256 lastUpdatedTimestamp) {
    lastUpdatedTimestamp = _lastUpdated;
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function getClaimableRewards(
    address _user,
    address[] calldata _lpTokens
  )
    external
    view
    returns (
      uint256 totalClaimableRewards,
      AccountRewards[] memory claimableRewardsBySource
    )
  {
    return _getClaimableRewards(_user, _lpTokens);
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function getTotalClaimableRewards(
    address _user
  )
    external
    view
    returns (
      uint256 totalClaimableRewards,
      AccountRewards[] memory claimableRewardsBySource
    )
  {
    return _getClaimableRewards(_user, lpTokenList);
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function claimRewards(
    address _user,
    address[] calldata _lpTokens
  )
    external
    isMsgSender(_user)
    returns (
      uint256 rewardsClaimed,
      AccountRewards[] memory claimedRewardsBySource
    )
  {
    return _claim(_user, _lpTokens);
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function claimAllRewards(
    address _user
  )
    external
    isMsgSender(_user)
    returns (
      uint256 rewardsClaimed,
      AccountRewards[] memory claimedRewardsBySource
    )
  {
    return _claim(_user, lpTokenList);
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function stakeRewards(
    address _user,
    address[] calldata _lpTokens
  )
    external
    isMsgSender(_user)
    returns (
      uint256 rewardsStaked,
      AccountRewards[] memory rewardsStakedBySource
    )
  {
    return _stake(_user, _lpTokens);
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function stakeAllRewards(
    address _user
  )
    external
    isMsgSender(_user)
    returns (
      uint256 rewardsStaked,
      AccountRewards[] memory rewardsStakedBySource
    )
  {
    return _stake(_user, lpTokenList);
  }

  /// @inheritdoc ISavvyLPRewardDistributor
  function claimAndStakeRewards(
    address _user,
    address[] calldata _lpSourceToClaim,
    address[] calldata _lpSourceToStake
  )
    external
    isMsgSender(_user)
    returns (
      uint256 rewardsClaimed,
      AccountRewards[] memory rewardsClaimedBySource,
      uint256 rewardsStaked,
      AccountRewards[] memory rewardsStakedBySource
    )
  {
    // claimable rewards to claim
    (rewardsClaimed, rewardsClaimedBySource) = _claim(_user, _lpSourceToClaim);

    // stake rewards to stake
    (rewardsStaked, rewardsStakedBySource) = _stake(_user, _lpSourceToStake);
  }

  function _getClaimableReward(
    address _user,
    address _lpToken
  ) private view returns (AccountRewards memory claimableReward) {
    claimableReward = _accountRewards[_lpToken][_user];
    if (claimableReward.user == address(0)) {
      claimableReward.user = _user;
      claimableReward.lpToken = _lpToken;
    }
  }

  function _getClaimableRewards(
    address _user,
    address[] memory _lpTokens
  )
    private
    view
    returns (
      uint256 totalClaimableRewards,
      AccountRewards[] memory claimableRewards
    )
  {
    uint256 length = _lpTokens.length;
    claimableRewards = new AccountRewards[](length);

    for (uint256 i; i < length; ++i) {
      claimableRewards[i] = _getClaimableReward(_user, _lpTokens[i]);
      totalClaimableRewards += claimableRewards[i].claimableRewards;
    }
  }

  /**
   * @dev This will update the claimed and claimable trackers for the account.
   * **NOTE** This will not transfer SVY so the caller will need to send or stake the SVY on behalf of the user.
   **/
  function _updateClaimableRewards(
    address _user,
    address[] memory _lpTokens,
    bool willClaimBeStaked
  )
    private
    returns (uint256 rewards, AccountRewards[] memory claimedRewardsBySource)
  {
    claimedRewardsBySource = new AccountRewards[](_lpTokens.length);

    uint256 amount;
    address lpToken;
    uint256 length = _lpTokens.length;
    AccountRewards storage accountRewards_;

    for (uint256 i; i < length; ++i) {
      lpToken = _lpTokens[i];
      accountRewards_ = _accountRewards[lpToken][_user];
      require(
        accountRewards_.lastClaimed < block.timestamp,
        "Cannot claim rewards for LP token twice."
      );
      amount = (_getClaimableReward(_user, lpToken)).claimableRewards;
      rewards += amount;

      if (amount > 0) {
        accountRewards_.lastClaimed = block.timestamp;

        accountRewards_.claimedRewards += amount;
        accountRewards_.claimableRewards -= amount;

        emit RewardsClaimed(_user, lpToken, amount, willClaimBeStaked);
      }
    }
  }

  function _claim(
    address _user,
    address[] memory _lpTokens
  )
    private
    returns (
      uint256 rewardsClaimed,
      AccountRewards[] memory claimedRewardsBySource
    )
  {
    (rewardsClaimed, claimedRewardsBySource) = _updateClaimableRewards(
      _user,
      _lpTokens,
      false
    );

    if (rewardsClaimed == 0) {
      revert UnsupportedOperationWithReason("Nothing available to claim");
    }
    TokenUtils.safeTransfer(SVY, _user, rewardsClaimed);
  }

  function _stake(
    address _user,
    address[] memory _lpTokens
  )
    private
    returns (
      uint256 rewardsStaked,
      AccountRewards[] memory rewardsStakedByAccount
    )
  {
    (rewardsStaked, rewardsStakedByAccount) = _updateClaimableRewards(
      _user,
      _lpTokens,
      true
    );

    if (rewardsStaked == 0) {
      revert UnsupportedOperationWithReason("Nothing available to stake");
    }

    TokenUtils.safeApprove(SVY, address(veSVY), rewardsStaked);
    veSVY.stakeFor(_user, rewardsStaked);
  }

  uint256[100] private __gap;
}