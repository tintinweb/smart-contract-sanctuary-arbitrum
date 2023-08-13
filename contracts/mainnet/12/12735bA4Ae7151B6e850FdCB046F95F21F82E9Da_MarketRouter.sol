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
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
// OpenZeppelin Contracts (last updated v4.8.1) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../utils/SafeERC20.sol";
import "../../../interfaces/IERC4626.sol";
import "../../../utils/math/Math.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * CAUTION: When the vault is empty or nearly empty, deposits are at high risk of being stolen through frontrunning with
 * a "donation" to the vault that inflates the price of a share. This is variously known as a donation or inflation
 * attack and is essentially a problem of slippage. Vault deployers can protect against this attack by making an initial
 * deposit of a non-trivial amount of the asset, such that price manipulation becomes infeasible. Withdrawals may
 * similarly be affected by slippage. Users can protect against this attack as well unexpected slippage in general by
 * verifying the amount received is as expected, using a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626 is ERC20, IERC4626 {
    using Math for uint256;

    IERC20 private immutable _asset;
    uint8 private immutable _decimals;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    constructor(IERC20 asset_) {
        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(asset_);
        _decimals = success ? assetDecimals : super.decimals();
        _asset = asset_;
    }

    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    /**
     * @dev Decimals are read from the underlying asset in the constructor and cached. If this fails (e.g., the asset
     * has not been created yet), the cached value is set to a default obtained by `super.decimals()` (which depends on
     * inheritance but is most likely 18). Override this function in order to set a guaranteed hardcoded value.
     * See {IERC20Metadata-decimals}.
     */
    function decimals() public view virtual override(IERC20Metadata, ERC20) returns (uint8) {
        return _decimals;
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4626-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4626-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Up);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function _initialConvertToShares(
        uint256 assets,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 shares) {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToShares} when overriding it.
     */
    function _initialConvertToAssets(
        uint256 shares,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 assets) {
        return shares;
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /**
     * @dev Checks if vault is "healthy" in the sense of having assets backing the circulating shares.
     */
    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
    }
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
library SafeCast {
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AcUpgradable is AccessControl, Ownable, Initializable {
    // 0xcb58d6d985142a614029cdf01861b4fe094d5919a47e69b8310dc4093d9d6ad0
    bytes32 internal constant ROLE_CONTROLLER = keccak256("ROLE_CONTROLLER");
    // 0x241ecf16d79d0f8dbfb92cbc07fe17840425976cf0667f022fe9877caa831b08
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    // 0xfb248bbb6ca5a799a6bb9ba79f58aa5cdbe0e5979238a967315e7ffbfd119d1a
    bytes32 internal constant ROLE_POS_KEEPER = keccak256("ROLE_POS_KEEPER");
    //======================
    // 0x5d8e12c39142ff96d79d04d15d1ba1269e4fe57bb9d26f43523628b34ba108ec
    bytes32 internal constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    //======================
    // 0x8d1089725c0dc266707fa6207730fb801dcd03108bfed7a21099bd303651d2b7
    bytes32 internal constant MARKET_MGR_ROLE = keccak256("MARKET_MGR_ROLE");
    // 0x275a642cf55cb12407e505ec86398168f240e88df6e66d1649bd09de9071c5db
    bytes32 internal constant GLOBAL_MGR_ROLE = keccak256("GLOBAL_MGR_ROLE");

    // 0xcb6bc1c12dd43bca8d7dd46d975f913325437d0dcd5978e99d515e4ad39b9772
    bytes32 internal constant VAULT_MGR_ROLE = keccak256("VAULT_MGR_ROLE");
    
    // 0x92de27771f92d6942691d73358b3a4673e4880de8356f8f2cf452be87e02d363
    bytes32 internal constant FREEZER_ROLE = keccak256("FREEZER_ROLE");

    // 0x59c7a9ef9a56707d87d116a5d27496afee2604c70b902ac2c4dbdcb68f36f2ea
    bytes32 internal constant FEE_DISTRIBUTOR_ROLE =
        keccak256("FEE_DISTRIBUTOR_ROLE");
    // 0xf21b97e3e053faeacb5e76d16d9daf713b69d060518bccb2c9ee13a7f9cfc49f
    bytes32 internal constant FEE_MGR_ROLE = keccak256("FEE_MGR_ROLE");
    // 0xf7650eb8b2f3fb3c9b995a8ee2fc3c04ed07f1c4efe01998177b109698c67517
    bytes32 internal constant PRICE_UPDATE_ROLE =
        keccak256("PRICE_UPDATE_ROLE");

    // 0xde57aa0116fb656e0ab30962f03bb7a49dccfb8fac7bf6a5cf94d0d56d0e7337
    bytes32 internal constant MULTI_SIGN_ROLE = keccak256("MULTI_SIGN_ROLE");

    uint256 private initBlock;

    modifier onlyInitOr(bytes32 _role) {
        bool isDefaultAdmin = hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
        if (isDefaultAdmin) {
            if (block.timestamp - initBlock >= 3600 * 24)
                revert("ac time passed");
        } else {
            _checkRole(_role, _msgSender());
        }
        _;
    }

    function _initialize(address _f) internal {
        initBlock = block.timestamp;
        _transferOwnership(_msgSender());

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, _f);
    }

    function transferAdmin(address to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(DEFAULT_ADMIN_ROLE, to);
        _transferOwnership(to);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        _checkRole(MANAGER_ROLE);
        _;
    }

    modifier onlyFreezer() {
        _checkRole(FREEZER_ROLE);
        _;
    }

    modifier onlyPositionKeeper() {
        _checkRole(ROLE_POS_KEEPER);
        _;
    }

    modifier onlyController() {
        _checkRole(ROLE_CONTROLLER);
        _;
    }

    modifier onlyUpdater() {
        require(hasRole(PRICE_UPDATE_ROLE, msg.sender));
        _;
    }

    function grantControllerRoleByMarketManager(
        address _account
    ) external onlyRole(MARKET_MGR_ROLE) {
        require(supportMarketRoleGrantControllerRole());
        _grantRole(ROLE_CONTROLLER, _account);
    }

    function supportMarketRoleGrantControllerRole()
        internal
        pure
        virtual
        returns (bool)
    {
        return false;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {MarketDataTypes} from "../../market/MarketDataTypes.sol";
import {Position} from "../../position/PositionStruct.sol";

interface IFeeRouter {
    enum FeeType {
        OpenFee, // 0
        CloseFee, // 1
        FundFee, // 2
        ExecFee, // 3
        LiqFee, // 4
        BuyLpFee, // 5
        SellLpFee, // 6
        ExtraFee0,
        ExtraFee1,
        ExtraFee2,
        ExtraFee3,
        ExtraFee4,
        Counter
    }

    function feeVault() external view returns (address);

    function fundFee() external view returns (address);

    function FEE_RATE_PRECISION() external view returns (uint256);

    function feeAndRates(
        address market,
        uint8 kind
    ) external view returns (uint256);

    function initialize(address vault, address fundingFee) external;

    function setFeeAndRates(address market, uint256[] memory rates) external;

    function withdraw(address token, address to, uint256 amount) external;

    function getExecFee(address market) external view returns (uint256);

    function getFundingRate(
        address market,
        bool isLong
    ) external view returns (int256);

    function cumulativeFundingRates(
        address market,
        bool isLong
    ) external view returns (int256);

    function updateCumulativeFundingRate(
        address market,
        uint256 longSize,
        uint256 shortSize
    ) external;

    function getOrderFees(
        MarketDataTypes.UpdateOrderInputs memory params
    ) external view returns (int256 fees);

    function getFees(
        MarketDataTypes.UpdatePositionInputs memory params,
        Position.Props memory position
    ) external view returns (int256[] memory);

    function collectFees(
        address account,
        address token,
        int256[] memory fees
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

library GlobalDataTypes {
    struct ValidParams {
        address market;
        uint256 sizeDelta;
        bool isLong;
        uint256 globalLongSizes;
        uint256 globalShortSizes;
        uint256 userLongSizes;
        uint256 userShortSizes;
        uint256 marketLongSizes;
        uint256 marketShortSizes;
        uint256 aum;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../GlobalDataTypes.sol";

interface IGlobalValid {
    function BASIS_POINTS_DIVISOR() external view returns (uint256);

    function maxSizeLimit() external view returns (uint256);

    function maxNetSizeLimit() external view returns (uint256);

    function maxUserNetSizeLimit() external view returns (uint256);

    function maxMarketSizeLimit(address market) external view returns (uint256);

    function setMaxSizeLimit(uint256 limit) external;

    function setMaxNetSizeLimit(uint256 limit) external;

    function setMaxUserNetSizeLimit(uint256 limit) external;

    function setMaxMarketSizeLimit(address market, uint256 limit) external;

    function isIncreasePosition(
        GlobalDataTypes.ValidParams memory params
    ) external view returns (bool);

    function getMaxIncreasePositionSize(
        GlobalDataTypes.ValidParams memory params
    ) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;
import {IPositionBook} from "../../position/interfaces/IPositionBook.sol";
import {IFeeRouter} from "../../fee/interfaces/IFeeRouter.sol";
import {IOrderBook} from "../../order/interface/IOrderBook.sol";
import "../../order/OrderStruct.sol";
import {MarketDataTypes} from "../MarketDataTypes.sol";
import "./../../position/PositionStruct.sol";
import {IOrderStore} from "../../order/interface/IOrderStore.sol";

interface IMarketStorage {
    function marketValid() external view returns (address);

    function globalValid() external view returns (address);

    function indexToken() external view returns (address);

    function positionBook() external view returns (IPositionBook); // slot 2

    function collateralToken() external view returns (address);

    function orderBookLong() external view returns (IOrderBook); // slot 2

    function orderBookShort() external view returns (IOrderBook); // slot 2

    function feeRouter() external view returns (IFeeRouter); // slot 2

    function priceFeed() external view returns (address); // slot 2

    function positionStoreLong() external view returns (address); // slot 2

    function positionStoreShort() external view returns (address); // slot 2

    function vaultRouter() external view returns (address); // slot 2
}

interface IMarket is IMarketStorage {
    struct OrderExec {
        address market;
        address account;
        uint64 orderID;
        bool isIncrease;
        bool isLong;
    }

    //=============================
    //user actions
    //=============================
    function increasePositionWithOrders(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) external;

    function decreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _vars
    ) external;

    function updateOrder(
        MarketDataTypes.UpdateOrderInputs memory _vars
    ) external;

    function cancelOrderList(
        address _account,
        bool[] memory _isIncreaseList,
        uint256[] memory _orderIDList,
        bool[] memory _isLongList
    ) external;

    //=============================
    //sys actions
    //=============================
    function initialize(address[] calldata addrs, string memory _name) external;

    function execOrderKey(
        Order.Props memory exeOrder,
        MarketDataTypes.UpdatePositionInputs memory _params
    ) external;

    function execOrderByIndex(OrderExec memory order) external;

    function liquidatePositions(
        address[] memory accounts,
        bool _isLong
    ) external;

    //=============================
    //read-only
    //=============================
    function getPNL() external view returns (int256);

    function USDDecimals() external pure returns (uint8);

    function priceFeed() external view returns (address);

    function indexToken() external view returns (address);

    function getPositions(
        address account
    ) external view returns (Position.Props[] memory _poss);

    function orderStore(
        bool isLong,
        bool isOpen
    ) external view returns (IOrderStore);
}

library MarketAddressIndex {
    uint public constant ADDR_PB = 0;
    uint public constant ADDR_OBL = 1;
    uint public constant ADDR_OBS = 2;

    uint public constant ADDR_MV = 3;
    uint public constant ADDR_PF = 4;

    uint public constant ADDR_PM = 5;
    uint public constant ADDR_MI = 6;

    uint public constant ADDR_IT = 7;
    uint public constant ADDR_FR = 8;
    uint public constant ADDR_MR = 9;

    uint public constant ADDR_VR = 10;
    uint public constant ADDR_CT = 11;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../MarketDataTypes.sol";
import "../../position/PositionStruct.sol";

interface MarketCallBackIntl {
    struct Calls {
        bool updatePosition;
        bool updateOrder;
        bool deleteOrder;
    }

    function getHooksCalls() external pure returns (Calls memory);
}

interface MarketPositionCallBackIntl is MarketCallBackIntl {
    //=====================================
    //      UPDATE POSITION
    //=====================================
    struct UpdatePositionEvent {
        MarketDataTypes.UpdatePositionInputs inputs;
        Position.Props position;
        int256[] fees;
        address collateralToken;
        address indexToken;
        int256 collateralDeltaAfter;
    }

    function updatePositionCallback(UpdatePositionEvent memory _event) external;
}

interface MarketOrderCallBackIntl is MarketCallBackIntl {
    //=====================================
    //      UPDATE ORDER
    //=====================================
    function updateOrderCallback(
        MarketDataTypes.UpdateOrderInputs memory _event
    ) external;

    //=====================================
    //      DEL ORDER
    //=====================================
    struct DeleteOrderEvent {
        Order.Props order;
        MarketDataTypes.UpdatePositionInputs inputs;
        uint8 reason;
        string reasonStr;
        int256 dPNL;
    }
    function deleteOrderCallback(DeleteOrderEvent memory e) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {MarketDataTypes} from "../MarketDataTypes.sol";
import "../../position/PositionStruct.sol";
import "../../position/interfaces/IPositionBook.sol";
import "../../fee/interfaces/IFeeRouter.sol";

interface IMarketValidFuncs {
    function validPosition(
        MarketDataTypes.UpdatePositionInputs memory _params,
        Position.Props memory _position,
        int256[] memory _fees
    ) external view;

    function validIncreaseOrder(
        MarketDataTypes.UpdateOrderInputs memory _vars,
        int256 fees
    ) external view;

    function validLev(uint256 newSize, uint256 newCollateral) external view;

    function validSize(
        uint256 _size,
        uint256 _sizeDelta,
        bool _isIncrease
    ) external view;

    function validSlippagePrice(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) external view;

    function validDecreaseOrder(
        uint256 _collateral,
        uint256 _collateralDelta,
        uint256 _size,
        uint256 _sizeDelta,
        int256 fees,
        uint256 decrOrderCount
    ) external view;


    function validMarkPrice(
        bool _isLong,
        uint256 _price,
        bool _isIncrease,
        bool _isExec,
        uint256 markPrice
    ) external view;

    function setConf(
        uint256 _minSlippage,
        uint256 _maxSlippage,
        uint256 _minLeverage,
        uint256 _maxLeverage,
        uint256 _maxTradeAmount,
        uint256 _minPay,
        uint256 _minCollateral,
        bool _allowOpen,
        bool _allowClose,
        uint256 _tokenDigits
    ) external;

    function setConfData(uint256 _data) external;

    function validCollateralDelta(
        uint256 busType,
        uint256 _collateral,
        uint256 _collateralDelta,
        uint256 _size,
        uint256 _sizeDelta,
        int256 _fees
    ) external view;

    function validateLiquidation(
        int256 pnl, // 获取仓位的盈利状态, 盈利大小
        int256 fees, // 不含清算费,包含资金费+交易手续费+执行费
        int256 liquidateFee,
        int256 collateral,
        uint256 size,
        bool _raise
    ) external view returns (uint8);

    function validPay(uint256 _pay) external view;

    function isLiquidate(
        address _account,
        address _market,
        bool _isLong,
        IPositionBook positionBook,
        IFeeRouter feeRouter,
        uint256 markPrice
    ) external view returns (uint256 _state);

    function getDecreaseOrderValidation(
        uint256 decrOrderCount
    ) external view returns (bool isValid);
}

interface IMarketValid is IMarketValidFuncs {
    struct Props {
        // minSlippage; //0-11  // 16^3   
        // maxSlippage; //12-23 // 16^3
        // minLeverage; //24-35  // 1 2^16
        // maxLeverage; //36-47 // 2000 2^16
        // minPay; // 48-59 // 10 2^8
        // minCollateral; // 60-71 // 2^8
        // maxTradeAmount = 100001;// 64-95 // 2^32
        uint256 data;
    }

    function conf() external view returns (IMarketValid.Props memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
import {IMarketValid} from "./interfaces/IMarketValid.sol";

library MarketConfigStruct {
    using MarketConfigStruct for IMarketValid.Props;
    uint256 private constant MIN_SLIPPAGE_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000; // prettier-ignore
    uint256 private constant MAX_SLIPPAGE_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFF; // prettier-ignore
    uint256 private constant MIN_LEV_MASK =               0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFF; // prettier-ignore
    uint256 private constant MAX_LEV_MASK =               0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFF; // prettier-ignore
    uint256 private constant MIN_PAY_MASK =               0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFF; // prettier-ignore
    uint256 private constant MIN_COL_MASK =               0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFFFFFFFFFFFFF; // prettier-ignore
    uint256 private constant MAX_TRADE_AMOUNT_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000FFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 private constant ALLOW_CLOSE_MASK =           0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0ffffffffFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 private constant ALLOW_OPEN_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0fffffffffFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 private constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FfffffffffFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 private constant DECREASE_NUM_LIMIT_MASK =    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000FFFfffffffffFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 private constant VALID_DECREASE_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FFFFFFfffffffffFFFFFFFFFFFFFFFFFF; // prettier-ignore

    uint256 constant MAX_SLIPPAGE_BIT_POSITION = 3 * 4; // one digt = 0.5 byte = 4 bit
    uint256 constant MIN_LEV_BIT_POSITION = 3 * 4 * 2;
    uint256 constant MAX_LEV_BIT_POSITION = 3 * 4 * 3;
    uint256 constant MIN_PAY_BIT_POSITION = 3 * 4 * 4;
    uint256 constant MIN_COL_BIT_POSITION = 3 * 4 * 5;
    uint256 constant MAX_TRADE_AMOUNT_BIT_POSITION = 3 * 4 * 6;
    uint256 constant ALLOW_CLOSE_BIT_POSITION = 3 * 4 * 6 + 4 * 8;
    uint256 constant ALLOW_OPEN_BIT_POSITION = 3 * 4 * 6 + 4 * 8 + 4;
    uint256 constant DECIMALS_BIT_POSITION = 3 * 4 * 6 + 4 * 8 + 4 + 4;
    uint256 constant DECREASE_NUM_LIMIT_BIT_POSITION = 120;
    uint256 constant VALID_DECREASE_BIT_POSITION = 120 + 4;

    uint256 constant DENOMINATOR_SLIPPAGE = 10 ** 4; // 分母

    function setMinSlippage(
        IMarketValid.Props memory self,
        uint256 minSp
    ) internal pure {
        if (minSp > 16 ** 3) {
            revert("sp too big");
        }
        self.data = (self.data & MIN_SLIPPAGE_MASK) | minSp;
    }

    function getMinSlippage(
        IMarketValid.Props memory self
    ) internal pure returns (uint256) {
        return self.data & ~MIN_SLIPPAGE_MASK;
    }

    function setMaxSlippage(
        IMarketValid.Props memory self,
        uint256 minSp
    ) internal pure {
        if (minSp > 16 ** 3) {
            revert("ms too big");
        }
        self.data =
            (self.data & MAX_SLIPPAGE_MASK) |
            (minSp << MAX_SLIPPAGE_BIT_POSITION);
    }

    function getMaxSlippage(
        IMarketValid.Props memory self
    ) internal pure returns (uint256) {
        return (self.data & ~MAX_SLIPPAGE_MASK) >> MAX_SLIPPAGE_BIT_POSITION;
    }

    function setMinLev(
        // 已经检查
        IMarketValid.Props memory self,
        uint256 minSp
    ) internal pure {
        if (minSp > 16 ** 3) {
            revert("ml too big");
        }
        self.data =
            (self.data & MIN_LEV_MASK) |
            (minSp << MIN_LEV_BIT_POSITION);
    }

    function getMinLev(
        IMarketValid.Props memory self
    ) internal pure returns (uint256) {
        // return 2;
        return (self.data & ~MIN_LEV_MASK) >> MIN_LEV_BIT_POSITION;
    }

    function setMaxLev(
        // checked
        IMarketValid.Props memory self,
        uint256 minSp
    ) internal pure {
        if (minSp > 16 ** 3) {
            revert("ml too big");
        }
        self.data =
            (self.data & MAX_LEV_MASK) |
            (minSp << MAX_LEV_BIT_POSITION);
    }

    function getMaxLev(
        IMarketValid.Props memory self
    ) internal pure returns (uint256) {
        return (self.data & ~MAX_LEV_MASK) >> MAX_LEV_BIT_POSITION;
    }

    function setMinPay(
        //checked
        IMarketValid.Props memory self,
        uint256 minSp
    ) internal pure {
        if (minSp > 16 ** 3) {
            revert("mp too big");
        }

        self.data =
            (self.data & MIN_PAY_MASK) |
            (minSp << MIN_PAY_BIT_POSITION);
    }

    function getMinPay(
        IMarketValid.Props memory self
    ) internal pure returns (uint256) {
        return
            ((self.data & ~MIN_PAY_MASK) >> MIN_PAY_BIT_POSITION) *
            self.getDecimals();
    }

    function setMinCollateral(
        IMarketValid.Props memory self,
        uint256 minSp
    ) internal pure {
        if (minSp > 16 ** 3) {
            revert("mc too big");
        }
        self.data =
            (self.data & MIN_COL_MASK) |
            (minSp << MIN_COL_BIT_POSITION);
    }

    function getMinCollateral(
        IMarketValid.Props memory self
    ) internal pure returns (uint256) {
        return
            ((self.data & ~MIN_COL_MASK) >> MIN_COL_BIT_POSITION) *
            self.getDecimals();
    }

    function setDecrOrderLmt(
        IMarketValid.Props memory self,
        uint256 minSp
    ) internal pure {
        if (minSp > 16 ** 3) {
            revert("mc too big");
        }
        self.data =
            (self.data & DECREASE_NUM_LIMIT_MASK) |
            (minSp << DECREASE_NUM_LIMIT_BIT_POSITION);
    }

    function getDecrOrderLmt(
        IMarketValid.Props memory self
    ) internal pure returns (uint256 ret) {
        ret = ((self.data & ~DECREASE_NUM_LIMIT_MASK) >>
            DECREASE_NUM_LIMIT_BIT_POSITION);
        if (ret == 0) {
            ret = 10;
        }
    }

    function setMaxTradeAmount(
        IMarketValid.Props memory self,
        uint256 minSp
    ) internal pure {
        if (minSp > 16 ** 8) {
            revert("mta too big");
        }
        self.data =
            (self.data & MAX_TRADE_AMOUNT_MASK) |
            (minSp << MAX_TRADE_AMOUNT_BIT_POSITION);
    }

    function getMaxTradeAmount(
        IMarketValid.Props memory self
    ) internal pure returns (uint256) {
        return
            ((self.data & ~MAX_TRADE_AMOUNT_MASK) >>
                MAX_TRADE_AMOUNT_BIT_POSITION) * self.getDecimals();
    }

    function setAllowClose(
        IMarketValid.Props memory self,
        bool allow
    ) internal pure {
        // return;
        self.data =
            (self.data & ALLOW_CLOSE_MASK) |
            (uint256(allow ? 1 : 0) << ALLOW_CLOSE_BIT_POSITION);
    }

    function getEnableValidDecrease(
        IMarketValid.Props memory self
    ) internal pure returns (bool) {
        return (self.data & ~VALID_DECREASE_MASK) != 0;
    }

    function setEnableValidDecrease(
        IMarketValid.Props memory self,
        bool allow
    ) internal pure {
        self.data =
            (self.data & VALID_DECREASE_MASK) |
            (uint256(allow ? 1 : 0) << VALID_DECREASE_BIT_POSITION);
    }

    function getAllowClose(
        IMarketValid.Props memory self
    ) internal pure returns (bool) {
        // return true;
        return (self.data & ~ALLOW_CLOSE_MASK) != 0;
    }

    function setAllowOpen(
        IMarketValid.Props memory self,
        bool allow
    ) internal pure {
        // return;
        self.data =
            (self.data & ALLOW_OPEN_MASK) |
            (uint256(allow ? 1 : 0) << ALLOW_OPEN_BIT_POSITION);
    }

    function getAllowOpen(
        IMarketValid.Props memory self
    ) internal pure returns (bool) {
        // return true;
        return (self.data & ~ALLOW_OPEN_MASK) != 0;
    }

    function setDecimals(
        IMarketValid.Props memory self,
        uint256 _decimals
    ) internal pure {
        self.data =
            (self.data & DECIMALS_MASK) |
            (_decimals << DECIMALS_BIT_POSITION);
    }

    function getDecimals(
        IMarketValid.Props memory self
    ) internal pure returns (uint256) {
        return 10 ** ((self.data & ~DECIMALS_MASK) >> DECIMALS_BIT_POSITION);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import "../order/OrderLib.sol";
import {Order} from "../order/OrderStruct.sol";

library MarketDataTypes {
    using Order for Order.Props;

    struct UpdateOrderInputs {
        address _market;
        bool _isLong;
        uint256 _oraclePrice;
        bool isOpen;
        bool isCreate;
        //===========
        Order.Props _order;
        uint256[] inputs; // uint256 pay; bool isFromMarket; uint256 _slippage;
    }

    function isFromMarket(
        UpdateOrderInputs memory _params
    ) internal pure returns (bool) {
        return _params.inputs.length >= 2 && _params.inputs[1] > 0;
    }

    function setIsFromMarket(
        UpdateOrderInputs memory _params,
        bool _p
    ) internal pure {
        _params.inputs[1] = _p ? 1 : 0;
    }

    function slippage(
        UpdateOrderInputs memory _params
    ) internal pure returns (uint256) {
        return _params.inputs.length >= 3 ? _params.inputs[2] : 0;
    }

    function setSlippage(
        UpdateOrderInputs memory _params,
        uint256 _p
    ) internal pure {
        _params.inputs[2] = _p;
    }

    struct UpdatePositionInputs {
        address _market;
        bool _isLong;
        uint256 _oraclePrice;
        bool isOpen;
        //===========
        address _account;
        uint256 _sizeDelta;
        uint256 _price;
        uint256 _slippage;
        bool _isExec;
        uint8 liqState;
        uint64 _fromOrder;
        bytes32 _refCode;
        uint256 collateralDelta;
        uint8 execNum;
        uint256[] inputs; //0: tp, isKeepLev; 1: sl
    }

    //===============================
    function initialize(
        UpdateOrderInputs memory _params,
        bool isOpen
    ) internal pure {
        _params.inputs = new uint256[](3);
        _params.isOpen = isOpen;
    }

    function initialize(
        UpdatePositionInputs memory _params,
        bool isOpen
    ) internal pure {
        //tp,sl
        //isKeeplev
        _params.inputs = new uint256[](2);
        _params.isOpen = isOpen;
        // _params.collateralDeltaPositive = true;
    }

    function fromOrder(
        UpdatePositionInputs memory _vars,
        Order.Props memory _order,
        address market,
        bool isLong,
        bool isIncrease,
        bool isExec
    ) internal pure {
        _vars._market = market;
        _vars._isLong = isLong; //订单方向
        _vars._sizeDelta = _order.size; //订单数量
        _vars._price = _order.price; //订单价格
        _vars._refCode = _order.refCode; //订单返佣推荐码
        _vars._isExec = isExec;
        _vars._fromOrder = _order.orderID;
        _vars._account = _order.account; //订单所属账户
        _vars.collateralDelta = _order.collateral;
        if (isIncrease) {
            setTp(_vars, _order.getTakeprofit()); //止盈价
            setSl(_vars, _order.getStoploss()); //止损价
        } else {
            setIsKeepLev(_vars, _order.getIsKeepLev());
        }
    }

    //===============================
    //       tp & iskepp lev
    //===============================

    function tp(
        UpdatePositionInputs memory _params
    ) internal pure returns (uint256) {
        return _params.inputs.length >= 1 ? _params.inputs[0] : 0;
    }

    function setTp(
        UpdatePositionInputs memory _params,
        uint256 _tp
    ) internal pure {
        _params.inputs[0] = _tp;
    }

    function isKeepLev(
        UpdatePositionInputs memory _params
    ) internal pure returns (bool) {
        return _params.inputs.length >= 1 && _params.inputs[0] > 0;
    }

    function setIsKeepLev(
        UpdatePositionInputs memory _params,
        bool _is
    ) internal pure returns (uint256) {
        return _params.inputs[0] = _is ? 1 : 0;
    }

    //===============================
    //       sl
    //===============================

    function sl(
        UpdatePositionInputs memory _params
    ) internal pure returns (uint256) {
        return _params.inputs.length >= 2 ? _params.inputs[1] : 0;
    }

    function setSl(
        UpdatePositionInputs memory _params,
        uint256 _sl
    ) internal pure {
        _params.inputs[1] = _sl;
    }

    //===============================
    //       PAY
    //===============================
    function pay(
        UpdateOrderInputs memory _params
    ) internal pure returns (uint256) {
        return _params.inputs.length >= 1 ? _params.inputs[0] : 0;
    }

    function setPay(
        UpdateOrderInputs memory _params,
        uint256 _p
    ) internal pure {
        _params.inputs[0] = _p;
    }

    //===============================
    function isValid(
        UpdatePositionInputs memory /* _params */
    ) internal pure returns (bool) {
        // if (_params._account == address(0)) return false;
        // return true;
        // if (_params._account == address(0)) return false;
        // return _params.inputs.length == (_params.isOpen ? 2 : 1);
        return true;
    }

    function isValid(
        UpdateOrderInputs memory _params
    ) internal pure returns (bool) {
        // 长度
        // if (false == _params.isOpen) {
        //     if (_params.inputs.length != 0) return false;
        // } else {
        //     if (_params.inputs.length != 1) return false;
        // }

        if (_params._oraclePrice > 0) return false;

        // close order
        if (false == _params.isOpen) {
            if (_params.isCreate) {
                // from order
                if (_params._order.getFromOrder() > 0) return false;
                //close: order to order id
                if (_params._order.extra2 > 0) return false;
            }
        } else {
            // collateral
            // if (_params._order.collateral > 0) return false;
        }

        // // // empty or order-order-id

        return true;
    }

    function totoalFees(
        int256[] memory fees
    ) internal pure returns (int256 total) {
        for (uint i = 0; i < fees.length; i++) {
            total += fees[i];
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
import {MarketConfigStruct} from "./MarketConfigStruct.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {IVaultRouter} from "../vault/interfaces/IVaultRouter.sol";
import {IOrderBook} from "../order/interface/IOrderBook.sol";
import {IFeeRouter} from "../fee/interfaces/IFeeRouter.sol";
import {IPositionBook} from "../position/interfaces/IPositionBook.sol";
import {Order} from "../order/OrderStruct.sol";
import {MarketPositionCallBackIntl, MarketOrderCallBackIntl, MarketCallBackIntl} from "./interfaces/IMarketCallBackIntl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/TransferHelper.sol";
import "./MarketDataTypes.sol";

library MarketLib {
    /**
     * @dev Withdraws fees from the specified collateral address.
     * @param collAddr The address of the collateral token.
     * @param _account The address of the account to receive the fees.
     * @param fee The amount of fees to be withdrawn.
     * @param collateralTokenDigits The number of decimal places for the collateral token.
     * @param fr The address of the fee router.
     */
    function feeWithdraw(
        address collAddr,
        address _account,
        int256 fee,
        uint8 collateralTokenDigits,
        address fr
    ) internal {
        require(_account != address(0), "feeWithdraw:!userAccount");
        if (fee < 0) {
            IFeeRouter(fr).withdraw(
                collAddr,
                _account,
                TransferHelper.formatCollateral(
                    uint256(-fee),
                    collateralTokenDigits
                )
            );
        }
    }

    /**
     * @dev Withdraws profit and loss (PnL) from the vault.
     * @param _account The address of the account to receive the PnL.
     * @param pnl The amount of profit and loss to be withdrawn.
     * @param collateralTokenDigits The number of decimal places for the collateral token.
     * @param vr The address of the vault router.
     */
    function vaultWithdraw(
        address /* collAddr */,
        address _account,
        int256 pnl,
        uint8 collateralTokenDigits,
        address vr
    ) internal {
        require(_account != address(0), "vaultWithdraw:!userAccount");
        if (pnl > 0) {
            IVaultRouter(vr).transferFromVault(
                _account,
                TransferHelper.formatCollateral(
                    uint256(pnl),
                    collateralTokenDigits
                )
            );
        }
    }

    /**
     * @dev Calculates the delta collateral for decreasing a position.
     * @param isKeepLev Boolean flag indicating whether to keep leverage.
     * @param size Current size of the position.
     * @param dSize Delta size of the position.
     * @param collateral Current collateral amount.
     * @return deltaCollateral The calculated delta collateral.
     */
    function getDecreaseDeltaCollateral(
        bool isKeepLev,
        uint256 size,
        uint256 dSize,
        uint256 collateral
    ) internal pure returns (uint256 deltaCollateral) {
        if (isKeepLev) {
            deltaCollateral = (collateral * dSize) / size;
        } else {
            deltaCollateral = 0;
        }
    }

    /**
     * @dev Executes the necessary actions after updating a position.
     * @param _item The update position event data.
     * @param plugins The array of plugin addresses.
     * @param erc20Token The address of the ERC20 token.
     * @param market The address of the market.
     */
    function afterUpdatePosition(
        MarketPositionCallBackIntl.UpdatePositionEvent memory _item,
        uint256 /* gasLimit */,
        address[] memory plugins,
        address erc20Token,
        address market
    ) internal {
        uint256 balanceBefore = IERC20(erc20Token).balanceOf(market);
        for (uint256 i = 0; i < plugins.length; i++) {
            if (MarketCallBackIntl(plugins[i]).getHooksCalls().updatePosition) {
                try
                    MarketPositionCallBackIntl(plugins[i])
                        .updatePositionCallback(_item)
                {} catch {}
            }
            // plugins[i].call{gas: gasLimit}(
            //     abi.encodeWithSelector(SELECTOR_updatePositionCallback, _item)
            // );
        }
        uint256 balanceAfter = IERC20(erc20Token).balanceOf(market);
        require(balanceAfter == balanceBefore, "ERC20 token balance changed");
    }

    /**
     * @dev Executes the necessary actions after updating an order.
     * @param _item The update order inputs data.
     * @param plugins The array of plugin addresses.
     * @param collateralToken The address of the collateral token.
     * @param market The address of the market.
     */
    function afterUpdateOrder(
        MarketDataTypes.UpdateOrderInputs memory _item,
        uint256 /* gasLimit */,
        address[] memory plugins,
        address collateralToken,
        address market
    ) internal {
        uint256 balanceBefore = IERC20(collateralToken).balanceOf(market);
        for (uint256 i = 0; i < plugins.length; i++) {
            if (MarketCallBackIntl(plugins[i]).getHooksCalls().updateOrder) {
                try
                    MarketOrderCallBackIntl(plugins[i]).updateOrderCallback(
                        _item
                    )
                {} catch {}
            }
            // plugins[i].call{gas: gasLimit}(
            //     abi.encodeWithSelector(selector_updateOrderCallback, _item)
            // );
        }
        uint256 balanceAfter = IERC20(collateralToken).balanceOf(market);
        require(balanceAfter == balanceBefore, "ERC20 token balance changed");
    }

    /**
     * @dev Executes the necessary actions after deleting an order.
     * @param e The delete order event data.
     * @param plugins The array of plugin addresses.
     * @param erc20Token The address of the ERC20 token.
     * @param market The address of the market.
     */
    function afterDeleteOrder(
        MarketOrderCallBackIntl.DeleteOrderEvent memory e,
        uint256 /* gasLimit */,
        address[] memory plugins,
        address erc20Token,
        address market
    ) internal {
        uint256 balanceBefore = IERC20(erc20Token).balanceOf(market);
        for (uint256 i = 0; i < plugins.length; i++) {
            // TODO 确认是否有风险, 可能会存在gas预估错误
            // 确认memtamask唤起的时候是否能设置gaslimit & approve amount
            //TODO
            // (bool suc, bytes memory returnData) = plugins[i].call{
            //     gas: gasLimit
            // }(abi.encodeWithSelector(selector_afterDeleteOrder, e));
            // (, string memory errorMessage) = abi.decode(
            //     returnData,
            //     (bool, string)
            // );
            // require(suc, "call failed");
            if (MarketCallBackIntl(plugins[i]).getHooksCalls().deleteOrder) {
                try
                    MarketOrderCallBackIntl(plugins[i]).deleteOrderCallback(e)
                {} catch {}
            }
        }
        uint256 balanceAfter = IERC20(erc20Token).balanceOf(market);
        require(balanceAfter == balanceBefore, "ERC20 token balance changed");
    }

    /**
     * @dev Updates the cumulative funding rate for the market.
     * @param positionBook The address of the position book.
     * @param feeRouter The address of the fee router.
     */
    function _updateCumulativeFundingRate(
        IPositionBook positionBook,
        IFeeRouter feeRouter
    ) internal {
        (uint256 _longSize, uint256 _shortSize) = positionBook.getMarketSizes();

        feeRouter.updateCumulativeFundingRate(
            address(this),
            _longSize,
            _shortSize
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IMarket} from "./interfaces/IMarket.sol";
import {MarketCallBackIntl, MarketPositionCallBackIntl, MarketOrderCallBackIntl} from "./interfaces/IMarketCallBackIntl.sol";
import {MarketDataTypes} from "./MarketDataTypes.sol";

import {MarketLib} from "./MarketLib.sol";
import "../utils/EnumerableValues.sol";
import "../position/interfaces/IPositionBook.sol";
import "./interfaces/IGlobalValid.sol";
import "../vault/interfaces/IVaultRouter.sol";
import "../order/OrderLib.sol";
import "../order/OrderStruct.sol";
import {TransferHelper} from "./../utils/TransferHelper.sol";
import "../ac/AcUpgradable.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract MarketRouter is
    MarketPositionCallBackIntl,
    MarketOrderCallBackIntl,
    AcUpgradable,
    ReentrancyGuard
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableValues for EnumerableSet.AddressSet;
    using MarketDataTypes for MarketDataTypes.UpdateOrderInputs;
    using MarketDataTypes for MarketDataTypes.UpdatePositionInputs;
    using Order for Order.Props;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    mapping(address => address) pbs; // 用mkt来查找pb
    //mapping(address => address) mkts; // 用pb来查找mkt
    EnumerableSet.AddressSet internal positionBooks; // 用来遍历pb
    EnumerableSet.AddressSet internal markets; // 用来遍历pb
    address public gv;
    address public vaultRouter;
    bool public isEnableMarketConvertToOrder;

    function getMarkets() external view returns (address[] memory) {
        return markets.values();
    }

    //==============================
    // EVNET
    //==============================
    event UpdatePosition(
        address indexed account,
        uint256 collateralDelta,
        int256 collateralDeltaAfter,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        int256 pnl,
        int256[] fees,
        address market,
        address collateralToken,
        address indexToken,
        uint256 category, // maxcode size
        uint64 fromOrder
    );

    event UpdateOrder(
        address indexed account, //0
        bool isLong, //1
        bool isIncrease, //2 if false, trade type == "trigger", otherwise, type =="limit"
        uint256 orderID, //3
        address market, //4 -> market name
        // -------------------
        // address collateralToken, //TODO: fix me multi collateral token
        uint256 size, //5
        uint collateral, //6
        uint256 triggerPrice, //7
        bool triggerAbove, // 8TODO, set to bool
        uint tp, //9
        uint sl, //10
        uint128 fromOrder, //11, 区分trigger或者tp&sl, order
        bool isKeepLev, //12, 关仓的trigger单, 是否保持杠杆, order, 给orders使用
        MarketDataTypes.UpdateOrderInputs params
    );

    /**
     * 1. limit -> trigger(order的价格) 子图, order
     */
    event DeleteOrder(
        address indexed account,
        bool isLong,
        bool isIncrease,
        uint256 orderID,
        address market,
        uint8 reason,
        string reasonStr,
        uint256 price,
        int256 dPNL
    );

    function initialize(
        address _f,
        address _gv,
        address vr
    ) external initializer {
        AcUpgradable._initialize(_f);
        gv = _gv;
        vaultRouter = vr;
        isEnableMarketConvertToOrder = true;
    }

    //==============================
    // USER ACTIONS
    //==============================
    /**
     * @dev Validates the inputs for increasing a position.
     * @param _inputs Inputs required to update a position.
     *     - _market: The address of the market.
     *     - _isLong: Whether the position is long or short.
     *     - _oraclePrice: The current oracle price for the market.
     *     - isOpen: Whether the position is open or closed.
     *     - _account: The address of the account.
     *     - _sizeDelta: The change in position size.
     *     - _price: The price of the position.
     *     - _slippage: The allowed slippage for the trade.
     *     - _isExec: Whether the position is being executed.
     *     - liqState: The state of liquidation.
     *     - _fromOrder: The ID of the order the position was created from.
     *     - _refCode: The reference code of the position.
     *     - collateralDelta: The change in collateral.
     *     - execNum: The number of executions.
     *     - inputs: Array of additional inputs.
     */
    function validateIncreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) public view {
        IPositionBook ipb = IPositionBook(pbs[_inputs._market]);
        GlobalDataTypes.ValidParams memory params;
        params.market = _inputs._market;
        params.sizeDelta = _inputs._sizeDelta;
        params.isLong = _inputs._isLong;

        (params.globalLongSizes, params.globalShortSizes) = getGlobalSize();
        (params.userLongSizes, params.userShortSizes) = getAccountSize(
            _inputs._account
        );
        (params.marketLongSizes, params.marketShortSizes) = ipb
            .getMarketSizes();
        address _collateralToken = IMarket(_inputs._market).collateralToken();

        params.aum = TransferHelper.parseVaultAsset(
            IVaultRouter(vaultRouter).getAUM(),
            IERC20Metadata(_collateralToken).decimals()
        );

        require(IGlobalValid(gv).isIncreasePosition(params), "mr:gv");
    }

    /**
     * @notice Increases the size of a position on a market with the specified inputs
     * @param _inputs Inputs for updating the position
     *        _inputs._market Address of the market
     *        _inputs._isLong Whether the position is long (true) or short (false)
     *        _inputs._oraclePrice Price of the oracle for the market
     *        _inputs.isOpen Whether the position is open (true) or closed (false)
     *        _inputs._account Address of the account to increase position for
     *        _inputs._sizeDelta Amount to increase the size of the position by
     *        _inputs._price Price at which to increase the position
     *        _inputs._slippage Maximum amount of slippage allowed in the price
     *        _inputs._isExec Whether this is an execution of a previous order or not
     *        _inputs.liqState Liquidation state of the position
     *        _inputs._fromOrder ID of the order from which the position was executed
     *        _inputs._refCode Reference code for the position
     *        _inputs.collateralDelta Amount of collateral to add or remove from the position
     *        _inputs.execNum Execution number of the position
     *        _inputs.inputs Additional inputs for updating the position
     */
    function increasePosition(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) public nonReentrant {
        if (isEnableMarketConvertToOrder && _inputs._sizeDelta > 0) {
            _updateOrderFromPosition(_inputs);
        } else {
            require(markets.contains(_inputs._market), "MarketRouter:!market");
            require(_inputs.isValid(), "invalid params");
            IMarket im = IMarket(_inputs._market);
            //========================================
            //           转入钱
            //========================================
            address c = im.collateralToken();
            IERC20(c).safeTransferFrom(
                msg.sender,
                _inputs._market,
                calculateEquivalentCollateralAmount(c, _inputs.collateralDelta) // transfer in amount of collateral token
            );
            _inputs._account = msg.sender;
            //========================================
            //           全局验证
            //========================================
            validateIncreasePosition(_inputs);
            IMarket(_inputs._market).increasePositionWithOrders(_inputs);
        }
    }

    /**
     * @dev Create/Updates an order in a market.
     * @param _vars MarketDataTypes.UpdateOrderInputs memory containing the inputs required to update the order
     * _vars._market Address of the market
     * _vars._isLong Boolean indicating if the order is long
     * _vars._oraclePrice Price of the oracle
     * _vars.isOpen Boolean indicating if the order is open
     * _vars.isCreate Boolean indicating if the order is being created
     * _vars._order Order.Props containing the properties of the order to be updated
     * _vars.inputs Array of additional inputs required to update the order
     */
    function updateOrder(
        MarketDataTypes.UpdateOrderInputs memory _vars
    ) external nonReentrant {
        _updateOrder(_vars);
    }

    function _updateOrder(
        MarketDataTypes.UpdateOrderInputs memory _vars
    ) private {
        require(markets.contains(_vars._market), "invalid market");
        require(_vars.isValid(), "invalid params");
        _vars._order.account = msg.sender;
        _vars._order.setIsFromMarket(_vars.isOpen, _vars.isFromMarket());
        if (_vars.isOpen && _vars.isCreate) {
            address c = IMarket(_vars._market).collateralToken();
            IERC20(c).safeTransferFrom(
                msg.sender,
                _vars._market,
                calculateEquivalentCollateralAmount(c, _vars.pay()) // transfer in amount of collateral token
            );
        }
        IMarket(_vars._market).updateOrder(_vars);
    }

    function _updateOrderFromPosition(
        MarketDataTypes.UpdatePositionInputs memory _inputs
    ) internal {
        MarketDataTypes.UpdateOrderInputs memory _vars;
        _vars.initialize(_inputs.isOpen);
        _vars.setIsFromMarket(true);
        _vars.setSlippage(_inputs._slippage);
        _vars._market = _inputs._market;
        _vars._isLong = _inputs._isLong;
        _vars.isCreate = true;
        Order.Props memory _order;
        if (false == _inputs.isOpen) {
            _order.setIsKeepLev(_inputs.isKeepLev());
            // _vars.collateralDelta = _inputs.collateralDelta;
        } else {
            _vars.setPay(_inputs.collateralDelta);
            _order.setTakeprofit(_inputs.tp());
            _order.setStoploss(_inputs.sl());
        }
        _order.collateral = _inputs.collateralDelta.toUint128();
        _order.account = _inputs._account;
        _order.size = _inputs._sizeDelta.toUint128();
        _order.price = _inputs._price.toUint128();
        _order.refCode = _inputs._refCode;
        _vars._order = _order;
        _updateOrder(_vars);
    }

    /**
     * @dev Function to decrease the position in the market
     * @param _vars Struct containing the inputs to update the position
     *  _vars._market Address of the market
     *  _vars._isLong Boolean indicating the direction of the position
     *  _vars._oraclePrice Price of the oracle used for the market
     *  _vars.isOpen Boolean indicating if the position is open or not
     *  _vars._account Address of the account associated with the position
     *  _vars._sizeDelta Change in size of the position
     *  _vars._price Price of the position
     *  _vars._slippage Maximum price slippage allowed
     *  _vars._isExec Boolean indicating if the order has been executed
     *  _vars.liqState Liquidation state of the position
     *  _vars._fromOrder Order ID from which the position is being decreased
     *  _vars._refCode Reference code associated with the position
     *  _vars.collateralDelta Change in the collateral associated with the position
     *  _vars.execNum Number of times the order has been executed
     *  _vars.inputs Array of additional inputs
     */
    function decreasePosition(
        MarketDataTypes.UpdatePositionInputs memory _vars
    ) external nonReentrant {
        if (isEnableMarketConvertToOrder && _vars._sizeDelta > 0) {
            _updateOrderFromPosition(_vars);
        } else {
            require(markets.contains(_vars._market), "invalid market");
            require(_vars.isValid(), "invalid params");
            _vars._account = msg.sender;
            IMarket(_vars._market).decreasePosition(_vars);
        }
    }

    /**
     * @dev Function to cancel a list of orders in a market
     * @param _markets Addresses of the market
     * @param _isIncreaseList Array of boolean values indicating if the orders are increase orders or not
     * @param _orderIDList Array of order IDs to be canceled
     * @param _isLongList Array of boolean values indicating the direction of the orders
     */
    function cancelOrderList(
        address[] memory _markets,
        bool[] memory _isIncreaseList,
        uint256[] memory _orderIDList,
        bool[] memory _isLongList
    ) external nonReentrant {
        require(
            _markets.length == _isIncreaseList.length &&
                _isIncreaseList.length == _orderIDList.length &&
                _orderIDList.length == _isLongList.length,
            "Array lengths do not match"
        );

        bool[] memory ppp = new bool[](1);
        uint256[] memory ppp2 = new uint256[](1);
        bool[] memory ppp3 = new bool[](1);

        for (uint i = 0; i < _markets.length; i++) {
            require(markets.contains(_markets[i]), "invalid market");
            // Check if any pair of values in the four arrays is the same
            for (uint j = i + 1; j < _markets.length; j++) {
                if (
                    _markets[i] == _markets[j] &&
                    _isIncreaseList[i] == _isIncreaseList[j] &&
                    _orderIDList[i] == _orderIDList[j] &&
                    _isLongList[i] == _isLongList[j]
                ) {
                    revert("Duplicate order found");
                }
            }
            ppp[0] = _isIncreaseList[i];
            ppp2[0] = _orderIDList[i];
            ppp3[0] = _isLongList[i];
            IMarket(_markets[i]).cancelOrderList(msg.sender, ppp, ppp2, ppp3);
        }
    }

    /**
     * @dev Calculates the equivalent collateral amount in USDei based on the collateral token amount.
     * @param _collateralToken Address of the collateral token used for the calculation.
     * @param _collateralAmount The amount of the collateral token used for the calculation.
     * @return The equivalent collateral amount in USDei.
     */
    function calculateEquivalentCollateralAmount(
        address _collateralToken,
        uint256 _collateralAmount
    ) private view returns (uint256) {
        uint8 d = IERC20Metadata(_collateralToken).decimals();
        return TransferHelper.formatCollateral(_collateralAmount, d);
    }

    /**
     * @dev Function to get the global profit and loss across all markets
     * @return pnl Total profit and loss across all markets
     */
    function getGlobalPNL() external view returns (int256 pnl) {
        for (uint i = 0; i < markets.values().length; i++) {
            address m = markets.at(i);
            int256 a = IMarket(m).getPNL();
            pnl += a;
        }
    }

    /**
     * @dev Function to get the global sizes of long and short positions in all position books
     * @return sizesLong Total size of long positions
     * @return sizesShort Total size of short positions
     */
    function getGlobalSize()
        public
        view
        returns (uint256 sizesLong, uint256 sizesShort)
    {
        for (uint i = 0; i < positionBooks.values().length; i++) {
            address pb = positionBooks.at(i);
            (uint256 l, uint256 s) = IPositionBook(pb).getMarketSizes();
            sizesLong += l;
            sizesShort += s;
        }
    }

    /**
     * @dev Function to get the sizes of long and short positions for the caller across all position books
     * @return sizesL Total size of long positions
     * @return sizesS Total size of short positions
     */
    function getAccountSize(
        address account
    ) public view returns (uint256 sizesL, uint256 sizesS) {
        for (uint i = 0; i < positionBooks.values().length; i++) {
            address pb = positionBooks.at(i);
            (uint256 l, uint256 s) = IPositionBook(pb).getAccountSize(account);
            sizesL += l;
            sizesS += s;
        }
    }

    //==============================
    // INIT & SETTER
    //==============================

    function updatePositionBook(
        address newA
    ) external onlyRole(MARKET_MGR_ROLE) {
        require(newA != address(0));
        address _market = msg.sender;
        require(markets.contains(msg.sender), "invalid market");
        positionBooks.remove(address(IMarket(_market).positionBook()));

        address _positionBook = address(IMarket(_market).positionBook());
        positionBooks.remove(_positionBook);
        require(positionBooks.add(newA));
        pbs[_market] = newA;
    }

    function setIsEnableMarketConvertToOrder(
        bool _isEnableMarketConvertToOrder
    ) external onlyRole(MARKET_MGR_ROLE) {
        isEnableMarketConvertToOrder = _isEnableMarketConvertToOrder;
    }

    // 在market初始化之后再被调用
    function addMarket(
        address _market,
        address /* vault */
    ) external onlyInitOr(MARKET_MGR_ROLE) {
        require(_market != address(0));
        address _positionBook = address(IMarket(_market).positionBook());

        require(markets.add(_market));
        require(positionBooks.add(_positionBook));
        pbs[_market] = _positionBook;

        // 2023/7/28日开会的时候 vc 说最后一步必须手工确认
        // IVaultRouter(vaultRouter).setMarket(_market, vault);
    }

    function removeMarket(address _market) external onlyRole(MARKET_MGR_ROLE) {
        address _positionBook = address(IMarket(_market).positionBook());

        markets.remove(_market);
        positionBooks.remove(_positionBook);
        pbs[_market] = address(0);
    }

    // ====================================
    // CALLBACK
    // ====================================
    function updatePositionCallback(
        MarketPositionCallBackIntl.UpdatePositionEvent memory _event
    ) external override {
        require(_event.inputs._market == msg.sender, "invalid sender");
        require(markets.contains(msg.sender), "invalid market");

        uint8 category = 1;
        if (_event.inputs.isOpen) {
            if (_event.inputs._sizeDelta == 0) {
                category = 2;
            } else {
                category = 0;
            }
        } else if (_event.inputs.liqState == 1) category = 4;
        else if (_event.inputs.liqState == 2) category = 5;
        else if (_event.inputs._sizeDelta == 0) category = 3;

        emit UpdatePosition(
            _event.inputs._account,
            _event.inputs.collateralDelta,
            _event.collateralDeltaAfter,
            _event.inputs._sizeDelta,
            _event.inputs._isLong,
            _event.inputs._oraclePrice,
            _event.position.realisedPnl,
            _event.fees, //todo
            _event.inputs._market,
            _event.collateralToken,
            _event.indexToken,
            category,
            _event.inputs._fromOrder
        );
    }

    function updateOrderCallback(
        MarketDataTypes.UpdateOrderInputs memory _event
    ) external override {
        require(_event._market == msg.sender, "invalid sender");
        require(markets.contains(msg.sender), "invalid market");
        emit UpdateOrder(
            _event._order.account,
            _event._isLong,
            _event.isOpen, // if false, trade type == "trigger", otherwise, type =="limit"
            _event._order.orderID,
            _event._market, // -> market name
            // -------------------
            // address collateralToken, //TODO: fix me multi collateral token
            _event._order.size,
            _event._order.collateral,
            _event._order.price,
            _event._order.getTriggerAbove(), // TODO, set to bool
            _event.isOpen ? _event._order.getTakeprofit() : 0,
            _event.isOpen ? _event._order.getStoploss() : 0,
            _event.isOpen ? 0 : uint128(_event._order.getFromOrder()),
            _event._order.getIsKeepLev(),
            _event
        );
    }

    function deleteOrderCallback(DeleteOrderEvent memory e) external override {
        require(e.inputs._market == msg.sender, "invalid sender");
        require(markets.contains(msg.sender), "invalid market");
        emit DeleteOrder(
            e.order.account,
            e.inputs._isLong,
            e.inputs.isOpen,
            e.order.orderID,
            e.inputs._market,
            e.reason,
            e.reasonStr,
            e.inputs._oraclePrice,
            e.dPNL
        );
    }

    function getHooksCalls()
        external
        pure
        override
        returns (MarketCallBackIntl.Calls memory)
    {
        return
            MarketCallBackIntl.Calls({
                updatePosition: true,
                updateOrder: true,
                deleteOrder: true
            });
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;
import "../OrderStruct.sol";
import {IOrderStore} from "./IOrderStore.sol";
import {OrderLib} from "../OrderLib.sol";
import "../../market/MarketDataTypes.sol";

interface IOrderBook {
    function initialize(
        bool _isLong,
        address _openStore,
        address _closeStore
    ) external;

    function add(
        MarketDataTypes.UpdateOrderInputs[] memory _vars
    ) external returns (Order.Props[] memory _orders);

    function update(
        MarketDataTypes.UpdateOrderInputs memory _vars
    ) external returns (Order.Props memory);

    function removeByAccount(
        bool isOpen,
        address account
    ) external returns (Order.Props[] memory _orders);

    function remove(
        address account,
        uint256 orderID,
        bool isOpen
    ) external returns (Order.Props[] memory _orders);

    function remove(
        bytes32 key,
        bool isOpen
    ) external returns (Order.Props[] memory _orders);

    //=============================
    function openStore() external view returns (IOrderStore);

    function closeStore() external view returns (IOrderStore);

    function getExecutableOrdersByPrice(
        uint256 start,
        uint256 end,
        bool isOpen,
        uint256 _oraclePrice
    ) external view returns (Order.Props[] memory _orders);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;
import "../OrderStruct.sol";

interface IOrderStore {
    function initialize(bool _isLong) external;

    function add(Order.Props memory order) external;

    function set(Order.Props memory order) external;

    function remove(bytes32 key) external returns (Order.Props memory order);

    function delByAccount(
        address account
    ) external returns (Order.Props[] memory _orders);

    function generateID(address _acc) external returns (uint256);

    function setOrderBook(address _ob) external;

    //============================
    function orders(bytes32 key) external view returns (Order.Props memory);

    function getOrderByAccount(
        address account
    ) external view returns (Order.Props[] memory _orders);

    function getKey(uint256 _index) external view returns (bytes32);

    function getKeys(
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory);

    function containsKey(bytes32 key) external view returns (bool);

    function isLong() external view returns (bool);

    // function orderTotalSize(address) external view returns (uint256) ;
    function getCount() external view returns (uint256);

    function orderNum(address _a) external view returns (uint256); // 用户的order数量
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;
import "../order/OrderStruct.sol";

library OrderLib {
    function getKey(
        address account,
        uint64 orderID
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, orderID));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./OrderLib.sol";

library Order {
    using SafeCast for uint256;
    using Order for Props;

    uint8 public constant STRUCT_VERSION = 0x01;

    struct Props {
        uint8 version;
        uint32 updatedAtBlock;
        uint8 triggerAbove;
        address account;
        uint48 extra3; // close: isKeepLev
        uint128 collateral;
        // open:pay; close:collateralDelta

        uint128 size;
        uint128 price;
        uint128 extra1; // open:tp
        uint64 orderID;
        uint64 extra2; //close: order to order id
        uint128 extra0; // open:sl; close:from order
        bytes32 refCode; //160
        //96 todo uint96 extra4;
    }

    function setIsFromMarket(
        Props memory order,
        bool isIncrease,
        bool _isFromMarket
    ) internal pure {
        if (isIncrease) order.extra3 = uint48(_isFromMarket ? 1 : 0);
        else order.extra1 = uint128(_isFromMarket ? 1 : 0);
    }

    function isFromMarket(
        Props memory order,
        bool isIncrease
    ) internal pure returns (bool) {
        if (isIncrease) return order.extra3 > 0;
        return order.extra1 > 0;
    }

    function setSize(Props memory order, uint256 size) internal pure {
        order.size = size.toUint128();
    }

    function setTriggerAbove(
        Props memory order,
        bool triggerAbove
    ) internal pure {
        order.triggerAbove = triggerAbove ? 1 : 2;
    }

    function getTriggerAbove(Props memory order) internal pure returns (bool) {
        if (order.triggerAbove == 1) {
            return true;
        }
        if (order.triggerAbove == 2) {
            return false;
        }
        revert("invalid order trigger above");
    }

    function isMarkPriceValid(
        Props memory order,
        uint256 markPrice
    ) internal pure returns (bool) {
        if (order.getTriggerAbove()) return markPrice >= uint256(order.price);
        else return markPrice <= uint256(order.price);
    }

    function setPrice(Props memory order, uint256 _p) internal pure {
        order.price = _p.toUint128();
    }

    //========================================
    //        extra0
    //========================================

    function setFromOrder(Props memory order, uint64 orderID) internal pure {
        order.extra0 = uint128(orderID);
    }

    function getFromOrder(Props memory order) internal pure returns (uint256) {
        return uint256(order.extra0);
    }

    function setStoploss(Props memory order, uint256 stoploss) internal pure {
        order.extra0 = stoploss.toUint128();
    }

    function getStoploss(Props memory order) internal pure returns (uint256) {
        return uint256(order.extra0);
    }

    //========================================
    //        extra1
    //========================================

    function setTakeprofit(Props memory order, uint256 tp) internal pure {
        order.extra1 = tp.toUint128();
    }

    function getTakeprofit(Props memory order) internal pure returns (uint256) {
        return order.extra1;
    }

    //========================================
    //        extra2
    //========================================

    function setPairKey(Props memory order, uint64 orderID) internal pure {
        order.extra2 = orderID;
    }

    function getPairKey(Props memory order) internal pure returns (bytes32) {
        return OrderLib.getKey(order.account, order.extra2);
    }

    //========================================
    //        extra3
    //========================================

    function setIsKeepLev(Props memory order, bool isKeepLev) internal pure {
        order.extra3 = isKeepLev ? 1 : 0;
    }

    function getIsKeepLev(Props memory order) internal pure returns (bool) {
        return order.extra3 > 0;
    }

    //========================================

    function validTPSL(Props memory _order, bool _isLong) internal pure {
        if (_order.getTakeprofit() > 0) {
            require(
                _order.getTakeprofit() > _order.price == _isLong,
                "OrderBook:tp<price"
            );
        }
        if (_order.getStoploss() > 0) {
            require(
                _order.price > _order.getStoploss() == _isLong,
                "OrderBook:sl>price"
            );
        }
    }

    function getKey(Props memory order) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(order.account, order.orderID));
    }

    function updateTime(Order.Props memory _order) internal view {
        _order.updatedAtBlock = uint32(block.timestamp);
    }

    function validOrderAccountAndID(Order.Props memory order) internal pure {
        require(order.account != address(0), "invalid order key");
        require(order.orderID != 0, "invalid order key");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "../PositionStruct.sol";

interface IPositionBook {
    function market() external view returns (address);

    function longStore() external view returns (address);

    function shortStore() external view returns (address);

    function initialize(address market) external;

    function getMarketSizes() external view returns (uint256, uint256);

    function getAccountSize(
        address account
    ) external view returns (uint256, uint256);

    function getPosition(
        address account,
        uint256 markPrice,
        bool isLong
    ) external view returns (Position.Props memory);

    function getPositions(
        address account
    ) external view returns (Position.Props[] memory);

    function getPositionKeys(
        uint256 start,
        uint256 end,
        bool isLong
    ) external view returns (address[] memory);

    function getPositionCount(bool isLong) external view returns (uint256);

    function getPNL(
        address account,
        uint256 sizeDelta,
        uint256 markPrice,
        bool isLong
    ) external view returns (int256);

    function getMarketPNL(uint256 longPrice, uint256 shortPrice) external view returns (int256);

    function increasePosition(
        address account,
        int256 collateralDelta,
        uint256 sizeDelta,
        uint256 markPrice,
        int256 fundingRate,
        bool isLong
    ) external returns (Position.Props memory result);

    function decreasePosition(
        address account,
        uint256 collateralDelta,
        uint256 sizeDelta,
        int256 fundingRate,
        bool isLong
    ) external returns (Position.Props memory result);

    function decreaseCollateralFromCancelInvalidOrder(
        address account,
        uint256 collateralDelta,
        bool isLong
    ) external returns (uint256);

    function liquidatePosition(
        address account,
        uint256 markPrice,
        bool isLong
    ) external returns (Position.Props memory result);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

library Position {
    struct Props {
        address market;
        bool isLong;
        uint32 lastTime;
        uint216 extra3;
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        int256 entryFundingRate;
        int256 realisedPnl;
        uint256 extra0;
        uint256 extra1;
        uint256 extra2;
    }

    function calAveragePrice(
        Props memory position,
        uint256 sizeDelta,
        uint256 markPrice,
        uint256 pnl,
        bool hasProfit
    ) internal pure returns (uint256) {
        uint256 _size = position.size + sizeDelta;
        uint256 _netSize;

        if (position.isLong) {
            _netSize = hasProfit ? _size + pnl : _size - pnl;
        } else {
            _netSize = hasProfit ? _size - pnl : _size + pnl;
        }
        return (markPrice * _size) / _netSize;
    }

    function getLeverage(
        Props memory position
    ) internal pure returns (uint256) {
        return position.size / position.collateral;
    }

    function getPNL(
        Props memory position,
        uint256 price
    ) internal pure returns (bool, uint256) {
        uint256 _priceDelta = position.averagePrice > price
            ? position.averagePrice - price
            : price - position.averagePrice;
        uint256 _pnl = (position.size * _priceDelta) / position.averagePrice;

        bool _hasProfit;

        if (position.isLong) {
            _hasProfit = price > position.averagePrice;
        } else {
            _hasProfit = position.averagePrice > price;
        }

        return (_hasProfit, _pnl);
    }

    function isExist(Props memory position) internal pure returns (bool) {
        return (position.size > 0);
    }

    function isValid(Props memory position) internal pure returns (bool) {
        if (position.size == 0) {
            return false;
        }
        if (position.size < position.collateral) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library EnumerableValues {
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    function valuesAt(
        EnumerableSet.Bytes32Set storage set,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        uint256 max = set.length();
        if (end > max) {
            end = max;
        }

        bytes32[] memory items = new bytes32[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }

    function valuesAt(
        EnumerableSet.AddressSet storage set,
        uint256 start,
        uint256 end
    ) internal view returns (address[] memory) {
        uint256 max = set.length();
        if (end > max) {
            end = max;
        }

        address[] memory items = new address[](end - start);
        for (uint256 i = start; i < end; i++) {
            items[i - start] = set.at(i);
        }

        return items;
    }

    function valuesAt(
        EnumerableSet.UintSet storage set,
        uint256 start,
        uint256 end
    ) internal view returns (uint256[] memory) {
        uint256 max = set.length();
        if (end > max) {
            end = max;
        }

        uint256[] memory items = new uint256[](end - start);
        for (uint256 i = start; i < end; ) {
            items[i - start] = set.at(i);
            unchecked {
                ++i;
            }
        }

        return items;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

library Precision {
    // 价格精度 = 30
    // 率精度(资金费率, vault APR精度, 手续费率, global valid)
    uint256 public constant BASIS_POINTS_DIVISOR = 100000000;
    uint256 public constant FEE_RATE_PRECISION_DECIMALS = 8;
    uint256 public constant FEE_RATE_PRECISION = 10**FEE_RATE_PRECISION_DECIMALS;

    // function calRate(uint256 fenmu) external{
    //     return fenmu / BASIS_POINTS_DIVISOR;
    // }
}

library TransferHelper {
    uint8 public constant usdDecimals = 18; //数量精度

    using SafeERC20 for IERC20;

    function getUSDDecimals() internal pure returns (uint8) {
        return usdDecimals;
    }

    function formatCollateral(
        uint256 amount,
        uint8 collateralTokenDigits
    ) internal pure returns (uint256) {
        return
            (amount * (10 ** uint256(collateralTokenDigits))) /
            (10 ** usdDecimals);
    }

    function parseVaultAsset(
        uint256 amount,
        uint8 originDigits
    ) internal pure returns (uint256) {
        return
            (amount * (10 ** uint256(usdDecimals))) /
            (10 ** originDigits);
    }

    /**
     * @dev This library contains utility functions for transferring assets.
     * @param amount The amount of assets to transfer in integer format with decimal precision.
     * @param collateralTokenDigits The decimal precision of the collateral token.
     * @return The transferred asset amount converted to integer with decimal precision for the USD stablecoin.
     * This function is internal and can only be accessed within the current contract or library.
     */
    function parseVaultAssetSigned(
        int256 amount,
        uint8 collateralTokenDigits
    ) internal pure returns (int256) {
        return
            (amount * int256(10 ** uint256(collateralTokenDigits))) /
            int256(10 ** uint256(usdDecimals));
    }

    //=======================================

    function transferIn(
        address tokenAddress,
        address _from,
        address _to,
        uint256 _tokenAmount
    ) internal {
        if (_tokenAmount == 0) return;
        IERC20 coll = IERC20(tokenAddress);
        coll.safeTransferFrom(
            _from,
            _to,
            formatCollateral(
                _tokenAmount,
                IERC20Decimals(tokenAddress).decimals()
            )
        );
    }

    function transferOut(
        address tokenAddress,
        address _to,
        uint256 _tokenAmount
    ) internal {
        if (_tokenAmount == 0) return;
        IERC20 coll = IERC20(tokenAddress);
        _tokenAmount = formatCollateral(
            _tokenAmount,
            IERC20Decimals(tokenAddress).decimals()
        );
        coll.safeTransfer(_to, _tokenAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

interface ICoreVault is IERC4626 {
    function setVaultRouter(address vaultRouter) external;

    function setLpFee(bool isBuy, uint256 fee) external;

    function sellLpFee() external view returns (uint256);

    function buyLpFee() external view returns (uint256);

    function setCooldownDuration(uint256 duration) external;

    function computationalCosts(
        bool isBuy,
        uint256 amount
    ) external view returns (uint256);

    function transferOutAssets(address to, uint256 amount) external;

    function getLPFee(bool isBuy) external view returns (uint256);

    function setIsFreeze(bool f) external;

    /* function initialize(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _vaultRouter,
        address
    ) external; */
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import {IERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "./ICoreVault.sol";
import {IFeeRouter} from "../../fee/interfaces/IFeeRouter.sol";

interface IVaultRouter {
    function totalFundsUsed() external view returns (uint256);

    function feeRouter() external view returns (IFeeRouter);

    function initialize(address _coreVault, address _feeRouter) external;

    function setMarket(address market, address vault) external;

    function borrowFromVault(uint256 amount) external;

    function repayToVault(uint256 amount) external;

    function transferToVault(address account, uint256 amount) external;

    function transferFromVault(address to, uint256 amount) external;

    function getAUM() external view returns (uint256);

    function getGlobalPnl() external view returns (int256);

    function getLPPrice(address coreVault) external view returns (uint256);

    function getUSDBalance() external view returns (uint256);

    function priceDecimals() external view returns (uint256);

    function buyLpFee(ICoreVault vault) external view returns (uint256);

    function sellLpFee(ICoreVault vault) external view returns (uint256);

    function sell(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minAssetsOut
    ) external returns (uint256 assetsOut);

    function buy(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external returns (uint256 sharesOut);

    function transFeeTofeeVault(
        address account,
        address asset,
        uint256 fee, // assets decimals
        bool isBuy
    ) external;
}