// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import './interfaces/IDCNTSeries.sol';
import './interfaces/IFeeManager.sol';
import './extensions/ERC1155Hooks.sol';
import './utils/Splits.sol';
import './utils/OperatorFilterer.sol';
import './utils/Pausable.sol';
import './interfaces/ITokenWithBalance.sol';
import './utils/Version.sol';

/**
 * @title DCNTSeries
 * @author Zev Nevo. Will Kantaros.
 * @dev An implementation of the ERC1155 multi-token standard.
 */
contract DCNTSeries is
  IDCNTSeries,
  ERC1155Hooks,
  Initializable,
  Ownable,
  AccessControl,
  Pausable,
  Splits,
  OperatorFilterer,
  Version(1)
{
  /*
   * @dev The name of the ERC-1155 contract.
   */
  string private _name;

  /*
   * @dev The symbol of the ERC-1155 contract.
   */
  string private _symbol;

  /*
   * @dev The packed range of valid token IDs.
   */
  uint256 private _packedTokenRange;

  /*
   * @dev The base URI used to generate the URI for individual tokens.
   */
  string private _uri;

  /*
   * @dev The URI for the contract metadata.
   */
  string private _contractURI;

  /*
   * @dev The royalty fee in basis points (1/100th of a percent).
   */
  uint16 public royaltyBPS;

  /*
   * @dev The address that will receive payouts when withdrawing funds.
   * Use 0x0 to default to the contract owner.
   */
  address public payoutAddress;

  /*
   * @dev Whether the tokens are soulbound and cannot be transferred.
   */
  bool public isSoulbound;

  /*
   * @dev Whether the caps on token supplies are able to be increased.
   */
  bool public hasAdjustableCaps;

  /**
   * @dev Mapping of token IDs to drop IDs.
   */
  mapping(uint256 => uint256) public tokenDropIds;

  /**
   * @dev Mapping of drop IDs to drop configurations.
   */
  mapping(uint256 => Drop) private _drops;

  /*
   * @dev Mapping of token ID to the total number of tokens in circulation for that ID.
   */
  mapping(uint256 => uint256) public totalSupply;

  /*
   * @dev The address of the fee manager used to calculate minting fees and commissions.
   */
  address public feeManager;

  /*
   * @dev The address of the ChainLink price feed oracle to convert native currency to USD.
   */
  AggregatorV3Interface public currencyOracle;

  /**
   * @dev Checks whether the caller has the required minimum balance to pass through token gate.
   * @param tokenId The ID of the token to check.
   * @param isPresale A boolean indicating whether the sale type for is presale or primary sale.
   */
  modifier verifyTokenGate(uint256 tokenId, bool isPresale) {
    _verifyTokenGate(tokenId, isPresale);
    _;
  }

  /**
   * @dev Checks whether the caller has the required minimum balance to pass through token gate.
   * @param tokenId The ID of the token to check.
   * @param isPresale A boolean indicating whether the sale type for is presale or primary sale.
   */
  function _verifyTokenGate(uint tokenId, bool isPresale) internal {
    uint256 dropId = tokenDropIds[tokenId];
    TokenGateConfig memory tokenGate = _drops[dropId].tokenGate;
    if (
        tokenGate.tokenAddress != address(0)
        && (
          tokenGate.saleType == SaleType.ALL
          || (isPresale && tokenGate.saleType == SaleType.PRESALE)
          || (!isPresale && tokenGate.saleType == SaleType.PRIMARY)
        )
    ) {
      if ( ITokenWithBalance(tokenGate.tokenAddress).balanceOf(msg.sender) < tokenGate.minBalance ) {
        revert TokenGateDenied();
      }
    }
  }

  /**
   * @dev Checks if a given token ID is within the valid range for this contract.
   * @param tokenId The token ID to check.
  */
  modifier validTokenId(uint256 tokenId) {
    _checkValidTokenId(tokenId);
    _;
  }

  /**
   * @dev Checks if a given token ID is within the valid range for this contract.
   * @param tokenId The token ID to check.
  */
  function _checkValidTokenId(uint256 tokenId) internal view {
    (uint128 startTokenId, uint128 endTokenId) = _getUnpackedTokenRange();
    if ( startTokenId > tokenId || tokenId > endTokenId ) {
      revert NonexistentToken();
    }
  }

  /**
   * @dev Restricts access to only addresses with the DEFAULT_ADMIN_ROLE.
   */
  modifier onlyAdmin() {
    if ( ! hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ) {
      revert OnlyAdmin();
    }
    _;
  }

  /**
   * @dev Initializes the contract with the specified parameters.
   * @param _owner The owner of the contract.
   * @param _config The configuration for the contract.
   * @param _defaultDrop The default drop configuration for all tokens.
   * @param _dropOverrides Optional mapping of custom drop configurations.
   */
  function initialize(
    address _owner,
    SeriesConfig calldata _config,
    Drop calldata _defaultDrop,
    DropMap calldata _dropOverrides
  ) public initializer {
    _transferOwnership(_owner);
    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _name = _config.name;
    _symbol = _config.symbol;
    _uri = _config.metadataURI;
    _contractURI = _config.contractURI;
    _setRoyaltyBPS(_config.royaltyBPS);
    payoutAddress = _config.payoutAddress;
    hasAdjustableCaps = _config.hasAdjustableCaps;
    isSoulbound = _config.isSoulbound;
    feeManager = _config.feeManager;
    currencyOracle = AggregatorV3Interface(_config.currencyOracle);
    _setPackedTokenRange(_config.startTokenId, _config.endTokenId);
    _drops[0] = _defaultDrop;
    _setDropMap(_dropOverrides);
  }

  /**
   * @dev Returns the name of the contract.
   */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the contract.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the URI for a given token ID.
   * A single URI is returned for all token types as defined in EIP-1155's token type ID substitution mechanism.
   * Clients should replace `{id}` with the actual token type ID when calling the function.
   * @dev unused @param tokenId ID of the token to retrieve the URI for.
   */
  function uri(uint256) public view override(IDCNTSeries, ERC1155) returns (string memory) {
    return _uri;
  }

  /**
   * @dev Internal function to set the URI for all token IDs.
   * @param uri_ The URI for token all token IDs.
   */
  function _setURI(string memory uri_) private {
    _uri = uri_;
  }

  /**
   * @dev Set the URI for all token IDs.
   * @param uri_ The URI for token all token IDs.
   */
  function setURI(string memory uri_) external onlyAdmin {
    _uri = uri_;

    (uint128 startTokenId, uint128 endTokenId) = _getUnpackedTokenRange();
    unchecked {
      for (uint256 i = startTokenId; i <= endTokenId; i++) {
        emit URI(_uri, i);
      }
    }
  }

  /**
   * @dev Returns the URI of the contract metadata.
   */
  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Sets the URI of the contract metadata.
   * @param contractURI_ The URI of the contract metadata.
   */
  function setContractURI(string memory contractURI_) external onlyAdmin {
    _contractURI = contractURI_;
  }

  /**
   * @dev Returns the range of token IDs that are valid for this contract.
   * @return startTokenId The starting token ID for this contract.
   * @return endTokenId The ending token ID for this contract.
   */
  function tokenRange() external view returns (uint128 startTokenId, uint128 endTokenId) {
    return _getUnpackedTokenRange();
  }

  /**
   * @dev Sets the packed range of token IDs that are valid for this contract.
   * @param startTokenId The starting token ID for this contract.
   * @param endTokenId The ending token ID for this contract.
  */
  function _setPackedTokenRange(uint128 startTokenId, uint128 endTokenId) internal {
    if ( startTokenId > endTokenId ) {
      revert InvalidTokenRange();
    }

    _packedTokenRange = uint256(startTokenId) << 128 | uint256(endTokenId);
  }

  /**
   * @dev Returns the unpacked range of token IDs that are valid for this contract.
   * @return startTokenId The starting token ID for this contract.
   * @return endTokenId The ending token ID for this contract.
  */
  function _getUnpackedTokenRange() internal view returns (uint128, uint128) {
    uint128 endTokenId = uint128(_packedTokenRange & type(uint128).max);
    uint128 startTokenId = uint128(_packedTokenRange >> 128);
    return (startTokenId, endTokenId);
  }

  /**
   * @dev Sets the drop configurations for the specified token IDs.
   * @param dropMap A parameter object mapping token IDs, drop IDs, and drops.
   */
  function _setDropMap(DropMap calldata dropMap) internal {
    uint256 numberOfTokens = dropMap.tokenIds.length;
    uint256 numberOfDrops = dropMap.dropIds.length;

    if (
        numberOfTokens != dropMap.tokenIdDropIds.length
        || numberOfDrops != dropMap.drops.length
    ) {
      revert ArrayLengthMismatch();
    }

    unchecked {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        uint256 tokenId = dropMap.tokenIds[i];
        uint256 dropId = dropMap.tokenIdDropIds[i];
        _checkValidTokenId(tokenId);
        _checkValidTokenId(dropId);
        tokenDropIds[tokenId] = dropId;
      }

      for (uint256 i = 0; i < numberOfDrops; i++) {
        uint256 dropId = dropMap.dropIds[i];
        Drop calldata drop = dropMap.drops[i];
        _checkValidTokenId(dropId);
        _drops[dropId] = drop;
      }
    }
  }

  /**
   * @dev Returns the drop configuration for the specified token ID.
   * @param tokenId The ID of the token to retrieve the drop configuration for.
   * @return drop The drop configuration mapped to the specified token ID.
   */
  function tokenDrop(uint128 tokenId) external view returns (Drop memory) {
    return _drops[tokenDropIds[tokenId]];
  }

  /**
   * @dev Creates new tokens and updates drop configurations for specified token IDs.
   * @param newTokens Optional number of new token IDs to add to the existing token range.
   * @param dropMap Optional parameter object mapping token IDs, drop IDs, and drops.
   */
  function setTokenDrops(uint128 newTokens, DropMap calldata dropMap) external onlyAdmin {
    if ( newTokens > 0 ) {
      (uint128 startTokenId, uint128 endTokenId) = _getUnpackedTokenRange();
      _setPackedTokenRange(startTokenId, endTokenId + newTokens);
    }

    uint256 numberOfTokens = dropMap.tokenIds.length;
    uint256 numberOfDrops = dropMap.dropIds.length;

    if (
        numberOfTokens != dropMap.tokenIdDropIds.length
        || numberOfDrops != dropMap.drops.length
    ) {
      revert ArrayLengthMismatch();
    }

    unchecked {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        uint256 tokenId = dropMap.tokenIds[i];
        uint256 dropId = dropMap.tokenIdDropIds[i];
        _checkValidTokenId(tokenId);
        _checkValidTokenId(dropId);

        if ( totalSupply[tokenId] > _drops[dropId].maxTokens ) {
          revert CannotDecreaseCap();
        }

        tokenDropIds[tokenId] = dropId;
      }

      for (uint256 i = 0; i < numberOfDrops; i++) {
        uint256 dropId = dropMap.dropIds[i];

        if ( dropId != 0 ) {
          _checkValidTokenId(dropId);
        }

        Drop calldata _drop = dropMap.drops[i];
        Drop storage drop = _drops[dropId];

        if ( drop.maxTokens != _drop.maxTokens ) {
          if ( ! hasAdjustableCaps ) {
            revert CapsAreLocked();
          }
          if ( _drop.maxTokens < drop.maxTokens ) {
            revert CannotDecreaseCap();
          }
        }

        drop.maxTokens = _drop.maxTokens;
        drop.tokenPrice = _drop.tokenPrice;
        drop.maxTokensPerOwner = _drop.maxTokensPerOwner;
        drop.presaleMerkleRoot = _drop.presaleMerkleRoot;
        drop.presaleStart = _drop.presaleStart;
        drop.presaleEnd = _drop.presaleEnd;
        drop.saleStart = _drop.saleStart;
        drop.saleEnd = _drop.saleEnd;
      }
    }
  }

  /**
   * @dev Gets the current price for the specified token. If a currency oracle is set,
   * the price is calculated in native currency using the oracle exchange rate.
   * @param tokenId The ID of the token to get the price for.
   * @return The current price of the specified token.
   */
  function tokenPrice(uint256 tokenId) public view validTokenId(tokenId) returns (uint256) {
    if ( address(currencyOracle) != address(0) ) {
      uint256 decimals = currencyOracle.decimals();
      (
          /* uint80 roundID */,
          int price,
          /*uint startedAt*/,
          /*uint timeStamp*/,
          /*uint80 answeredInRound*/
      ) = currencyOracle.latestRoundData();

      uint256 exchangeRate = decimals <= 18
        ? uint256(price) * (10 ** (18 - decimals))
        : uint256(price) / (10 ** (decimals - 18));

      return uint256(_drops[tokenDropIds[tokenId]].tokenPrice) * (10 ** 18) / exchangeRate;
    }

    return _drops[tokenDropIds[tokenId]].tokenPrice;
  }

  /**
   * @dev Gets the current minting fee for the specified token.
   * @param tokenId The ID of the token to get the minting fee for.
   * @param quantity The quantity of tokens used to calculate the minting fee.
   * @return fee The current fee for minting the specified token.
   */
  function mintFee(uint256 tokenId, uint256 quantity) external view validTokenId(tokenId) returns (uint256 fee) {
    if ( feeManager != address(0) ) {
      (fee, ) = IFeeManager(feeManager).calculateFees(tokenPrice(tokenId), quantity);
    }
  }

  /**
   * @dev Mints a specified number of tokens to a specified address.
   * @param tokenId The ID of the token to mint.
   * @param to The address to which the minted tokens will be sent.
   * @param quantity The quantity of tokens to mint.
   */
  function mint(uint256 tokenId, address to, uint256 quantity)
    external
    payable
    verifyTokenGate(tokenId, false)
    whenNotPaused
  {
    _checkMintable(to, tokenId, quantity);
    uint256 price = tokenPrice(tokenId);
    uint256 fee;
    uint256 commission;

    if ( feeManager != address(0) ) {
      (fee, commission) = IFeeManager(feeManager).calculateFees(price, quantity);
    }

    uint256 totalPrice = (price * quantity) + fee;

    if ( msg.value < totalPrice ) {
      revert InsufficientFunds();
    }

    _mint(to, tokenId, quantity, '');
    totalSupply[tokenId] += quantity;
    _transferFees(fee + commission);
    _transferRefund(msg.value - totalPrice);
  }

  /**
   * @dev Mints a batch of tokens to a specified address.
   * @param tokenIds The IDs of the tokens to mint.
   * @param to The address to which the minted tokens will be sent.
   * @param quantities The quantities to mint of each token.
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
  )
    external
    payable
    whenNotPaused
  {
    uint256 totalPrice;
    uint256 totalQuantity;
    uint256 numberOfTokens = tokenIds.length;

    unchecked {
      for (uint256 i = 0; i < numberOfTokens; i++) {
        uint256 tokenId = tokenIds[i];
        uint256 quantity = quantities[i];
        _verifyTokenGate(tokenId, false);
        _checkMintable(to, tokenId, quantity);
        totalPrice += _drops[tokenDropIds[tokenId]].tokenPrice * quantity;
        totalQuantity += quantity;
        totalSupply[tokenId] += quantity;
      }
    }

    uint256 fee;
    uint256 commission;

    if ( feeManager != address(0) ) {
      (fee, commission) = IFeeManager(feeManager).calculateFees(totalPrice, totalQuantity);
      totalPrice += fee;
    }

    if ( msg.value < totalPrice ) {
      revert InsufficientFunds();
    }

    _batchMint(to, tokenIds, quantities, '');
    _transferFees(fee + commission);
    _transferRefund(msg.value - totalPrice);
  }

  /**
   * @dev Internal function to check if a drop can be minted.
   * @param to The address to which the minted tokens will be sent.
   * @param tokenId The ID of the token to mint.
   * @param quantity The quantity of tokens to mint.
   */
  function _checkMintable(
    address to,
    uint256 tokenId,
    uint256 quantity
  )
    internal
    view
  {
    _checkValidTokenId(tokenId);
    uint256 dropId = tokenDropIds[tokenId];
    Drop memory drop = _drops[dropId];
    uint256 supply = totalSupply[tokenId];

    if ( block.timestamp < drop.saleStart || block.timestamp > drop.saleEnd ) {
      revert SaleNotActive();
    }

    if ( supply + quantity > drop.maxTokens ) {
      revert MintExceedsMaxSupply();
    }

    if ( balanceOf[to][tokenId] + quantity > drop.maxTokensPerOwner ) {
      revert MintExceedsMaxTokensPerOwner();
    }
  }

  /**
   * @dev Internal function to transfer fees to the fee manager.
   * @param fees The amount of funds to transfer.
   */
  function _transferFees(uint256 fees) internal {
    if ( fees > 0 ) {
      (bool success, ) = payable(IFeeManager(feeManager).recipient()).call{value: fees}("");
      if ( ! success ) {
        revert FeeTransferFailed();
      }
    }
  }

  /**
   * @dev Internal function to transfer excess funds to the caller.
   * @param refund The amount of funds to transfer.
   */
  function _transferRefund(uint256 refund) internal {
    if ( refund > 0 ) {
      (bool success, ) = payable(msg.sender).call{value: refund}("");
      if ( ! success ) {
        revert RefundFailed();
      }
    }
  }

  /**
   * @dev Burns a specified quantity of tokens from the caller's account.
   * @param tokenId The ID of the token to burn.
   * @param quantity The quantity of tokens to burn.
   */
  function burn(uint256 tokenId, uint256 quantity) external {
    if ( balanceOf[msg.sender][tokenId] < quantity ) {
      revert BurnExceedsOwnedTokens();
    }
    _burn(msg.sender, tokenId, quantity);
    totalSupply[tokenId] -= quantity;
  }

  /**
   * @dev Mints a specified token to multiple recipients as part of an airdrop.
   * @param tokenId The ID of the token to mint.
   * @param recipients The list of addresses to receive the minted tokens.
   */
  function mintAirdrop(uint256 tokenId, address[] calldata recipients) external onlyAdmin validTokenId(tokenId) {
    uint256 airdrops = recipients.length;

    if ( totalSupply[tokenId] + airdrops > _drops[tokenDropIds[tokenId]].maxTokens ) {
      revert AirdropExceedsMaxSupply();
    }

    unchecked {
      for (uint i = 0; i < airdrops; i++) {
        address to = recipients[i];
        _mint(to, tokenId, 1, '');
      }
      totalSupply[tokenId] += airdrops;
    }
  }

  /**
   * @dev Mints a specified number of tokens to the presale buyer address.
   * @param tokenId The ID of the token to mint.
   * @param quantity The quantity of tokens to mint.
   * @param maxQuantity The maximum quantity of tokens that can be minted.
   * @param pricePerToken The price per token in wei.
   * @param merkleProof The Merkle proof verifying that the presale buyer is eligible to mint tokens.
   */
  function mintPresale(
    uint256 tokenId,
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  )
    external
    payable
    verifyTokenGate(tokenId, true)
    validTokenId(tokenId)
    whenNotPaused
  {
    _checkPresaleMintable(
      tokenId,
      quantity,
      maxQuantity,
      pricePerToken,
      merkleProof
    );

    uint256 fee;
    uint256 commission;

    if ( feeManager != address(0) ) {
      (fee, commission) = IFeeManager(feeManager).calculateFees(pricePerToken, quantity);
    }

    uint256 totalPrice = (pricePerToken * quantity) + fee;

    if ( msg.value < totalPrice ) {
      revert InsufficientFunds();
    }

    uint256 ownerBalance = balanceOf[msg.sender][tokenId];

    if ( ownerBalance + quantity > maxQuantity ) {
      revert MintExceedsMaxTokensPerOwner();
    }

    _mint(msg.sender, tokenId, quantity, '');
    _transferFees(fee + commission);
    _transferRefund(msg.value - totalPrice);
  }

  /**
   * @dev Internal function to check if a drop can be presale minted.
   * @param tokenId The ID of the token to mint.
   * @param quantity The quantity of tokens to mint.
   * @param maxQuantity The maximum quantity of tokens that can be minted.
   * @param pricePerToken The price per token in wei.
   * @param merkleProof The Merkle proof verifying that the presale buyer is eligible to mint tokens.
   */
  function _checkPresaleMintable(
    uint256 tokenId,
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  )
    internal
    view
  {
    Drop memory drop = _drops[tokenDropIds[tokenId]];

    if ( block.timestamp < drop.presaleStart || block.timestamp > drop.presaleEnd ) {
      revert PresaleNotActive();
    }

    if ( totalSupply[tokenId] + quantity > drop.maxTokens ) {
      revert MintExceedsMaxSupply();
    }

    bool presaleVerification = MerkleProof.verify(
      merkleProof,
      drop.presaleMerkleRoot,
      keccak256(
        abi.encodePacked(
          msg.sender,
          maxQuantity,
          pricePerToken
        )
      )
    );

    if ( ! presaleVerification ) {
      revert PresaleVerificationFailed();
    }
  }

  /**
   * @dev Pauses public minting.
   */
  function pause() external whenNotPaused onlyAdmin {
    _pause();
  }

  /**
   * @dev Unpauses public minting.
   */
  function unpause() external whenPaused onlyAdmin {
    _unpause();
  }

  /**
   * @dev Sets the payout address to the specified address.
   * Use 0x0 to default to the contract owner.
   * @param _payoutAddress The address to set as the payout address.
   */
  function setPayoutAddress(address _payoutAddress) external onlyAdmin {
    payoutAddress = _payoutAddress;
  }

  /**
   * @dev Withdraws the balance of the contract to the payout address or the contract owner.
  */
  function withdraw() external {
    if ( splitWallet != address(0) ) {
      revert SplitsAreActive();
    }
    address to = payoutAddress != address(0) ? payoutAddress : owner();
    (bool success, ) = payable(to).call{value: address(this).balance}("");
    if ( ! success ) {
      revert  WithdrawFailed();
    }
  }

  /**
   * @dev Internal function to set the royalty fee.
   * @param _royaltyBPS The royalty fee in basis points. (1/100th of a percent)
   */
  function _setRoyaltyBPS(uint16 _royaltyBPS) internal {
    if ( _royaltyBPS > 100_00 ) {
      revert InvalidBPS();
    }
    royaltyBPS = _royaltyBPS;
  }

  /**
   * @dev Sets the royalty fee (ERC-2981: NFT Royalty Standard).
   * @param _royaltyBPS The royalty fee in basis points. (1/100th of a percent)
   */
  function setRoyaltyBPS(uint16 _royaltyBPS) external onlyAdmin {
    _setRoyaltyBPS(_royaltyBPS);
  }

  /**
   * @dev Returns the royalty recipient and amount for a given sale price.
   * @param tokenId The ID of the token being sold.
   * @param salePrice The sale price of the token.
   * @return receiver The address of the royalty recipient.
   * @return royaltyAmount The amount to be paid to the royalty recipient.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
  {
    _checkValidTokenId(tokenId);

    if ( splitWallet != address(0) ) {
      receiver = splitWallet;
    } else if ( payoutAddress != address(0) ) {
      receiver = payoutAddress;
    } else {
      receiver = owner();
    }

    uint256 royaltyPayment = (salePrice * royaltyBPS) / 100_00;

    return (receiver, royaltyPayment);
  }

  /**
   * @dev Returns true if the contract supports the given interface (ERC2981 or ERC1155),
   * as specified by interfaceId, false otherwise.
   * @param interfaceId The interface identifier, as specified in ERC-165.
   * @return True if the contract supports interfaceId, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IDCNTSeries, ERC1155, AccessControl)
    returns (bool)
  {
    return
      interfaceId == 0x2a55205a || // ERC165 interface ID for ERC2981.
      AccessControl.supportsInterface(interfaceId) ||
      ERC1155.supportsInterface(interfaceId);
  }

  /**
   * @dev Updates the operator filter registry with the specified subscription.
   * @param enable If true, enables the operator filter, if false, disables it.
   * @param operatorFilter The address of the operator filter subscription.
   */
  function updateOperatorFilter(bool enable, address operatorFilter) external onlyAdmin {
    address self = address(this);
    if ( ! operatorFilterRegistry.isRegistered(self) && enable ) {
      operatorFilterRegistry.registerAndSubscribe(self, operatorFilter);
    } else if ( enable ) {
      operatorFilterRegistry.subscribe(self, operatorFilter);
    } else {
      operatorFilterRegistry.unsubscribe(self, false);
      operatorFilterRegistry.unregister(self);
    }
  }

  /**
   * @dev Hook that is called before any token transfer, including minting and burning.
   * It checks if the operator is allowed and enforces the "soulbound" rule if enabled.
   * @param from The address from which the tokens are being transferred (or 0x0 if minting).
   * @param to The address to which the tokens are being transferred (or 0x0 if burning).
   * @dev unused @param ids An array containing the identifiers of the tokens being transferred.
   * @dev unused @param amounts An array containing the amounts of tokens being transferred.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256[] memory,
    uint256[] memory
  ) internal virtual override onlyAllowedOperator(from) {
    if ( isSoulbound && from != address(0) && to != address(0) ) {
      revert CannotTransferSoulbound();
    }
  }

  /**
   * @dev Sets or revokes approval for a third party ("operator") to manage all of the caller's tokens.
   * @param operator The address of the operator to grant or revoke approval.
   * @param approved True to grant approval, false to revoke it.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override(IDCNTSeries, ERC1155) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'solmate/src/tokens/ERC1155.sol';

abstract contract ERC1155Hooks is ERC1155 {
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) public virtual override {
    _beforeTokenTransfers(from, to, _asSingletonArray(id), _asSingletonArray(amount));
    super.safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) public virtual override {
    _beforeTokenTransfers(from, to, ids, amounts);
    super.safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual override {
    _beforeTokenTransfers(address(0), to, _asSingletonArray(id), _asSingletonArray(amount));
    super._mint(to, id, amount, data);
  }

  function _batchMint(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    _beforeTokenTransfers(address(0), to, ids, amounts);
    super._batchMint(to, ids, amounts, data);
  }

  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual override {
    _beforeTokenTransfers(msg.sender, address(0), _asSingletonArray(id), _asSingletonArray(amount));
    super._burn(from, id, amount);
  }

  function _batchBurn(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual override {
    _beforeTokenTransfers(msg.sender, address(0), ids, amounts);
    super._batchBurn(from, ids, amounts);
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;
    return array;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '../extensions/ERC1155Hooks.sol';
import '../storage/TokenGateConfig.sol';

/**
 * @title IDCNTSeries
 * @author Zev Nevo. Will Kantaros.
 * @dev An implementation of the ERC1155 multi-token standard.
 */
interface IDCNTSeries {
  /*
   * @dev A parameter object used to set the initial configuration of a token series.
   */
  struct SeriesConfig {
    string name;
    string symbol;
    string contractURI;
    string metadataURI;
    uint128 startTokenId;
    uint128 endTokenId;
    uint16 royaltyBPS;
    address feeManager;
    address payoutAddress;
    address currencyOracle;
    bool isSoulbound;
    bool hasAdjustableCaps;
  }

  /*
   * @dev The configuration settings for individual tokens within the series
   */
  struct Drop {
    uint32 maxTokens;                  // Slot 1: XXXX---------------------------- 4  bytes (max: 4,294,967,295)
    uint32 maxTokensPerOwner;          // Slot 1: ----XXXX------------------------ 4  bytes (max: 4,294,967,295)
    uint32 presaleStart;               // Slot 1: --------XXXX-------------------- 4  bytes (max: Feburary 7th, 2106)
    uint32 presaleEnd;                 // Slot 1: ------------XXXX---------------- 4  bytes (max: Feburary 7th, 2106)
    uint32 saleStart;                  // Slot 1: ----------------XXXX------------ 4  bytes (max: Feburary 7th, 2106)
    uint32 saleEnd;                    // Slot 1: --------------------XXXX-------- 4  bytes (max: Feburary 7th, 2106)
    uint96 tokenPrice;                 // Slot 2: XXXXXXXXXXXX-------------------- 12  bytes (max: 79,228,162,514 ETH)
    bytes32 presaleMerkleRoot;         // Slot 3: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 32 bytes
    TokenGateConfig tokenGate;         // Slot 4: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX 32 bytes
  }

  /**
   * @dev A parameter object mapping token IDs, drop IDs, and drops.
   */
  struct DropMap {
    uint256[] tokenIds;
    uint256[] tokenIdDropIds;
    uint256[] dropIds;
    Drop[] drops;
  }

  /*
   * @dev Only admins can perform this action.
   */
  error OnlyAdmin();

  /*
   * @dev The provided arrays have unequal lengths.
   */
  error ArrayLengthMismatch();

  /*
   * @dev The requested token does not exist.
   */
  error NonexistentToken();

  /*
   * @dev The provided token range is invalid.
   */
  error InvalidTokenRange();

  /*
   * @dev The token supply caps are locked and cannot be adjusted.
   */
  error CapsAreLocked();

  /*
   * @dev The token supply cap cannot be decreased.
   */
  error CannotDecreaseCap();

  /*
   * @dev Insufficient minimum balance for the token gate.
   */
  error TokenGateDenied();

  /*
   * @dev Sales for this drop are not currently active.
   */
  error SaleNotActive();

  /*
   * @dev The provided funds are insufficient to complete this transaction.
   */
  error InsufficientFunds();

  /*
   * @dev The requested mint exceeds the maximum supply for this drop.
   */
  error MintExceedsMaxSupply();

  /*
   * @dev The requested mint exceeds the maximum tokens per owner for this drop.
   */
  error MintExceedsMaxTokensPerOwner();

  /*
   * @dev The requested airdrop exceeds the maximum supply for this drop.
   */
  error AirdropExceedsMaxSupply();

  /*
   * @dev The requested burn exceeds the number of owned tokens.
   */
  error BurnExceedsOwnedTokens();

  /*
   * @dev The presale is not currently active.
   */
  error PresaleNotActive();

  /*
   * @dev Verification for the presale failed.
   */
  error PresaleVerificationFailed();

  /*
   * @dev Soulbound tokens cannot be transferred.
   */
  error CannotTransferSoulbound();

  /*
   * @dev Basis points may not exceed 100_00 (100 percent)
   */
  error InvalidBPS();

  /*
   * @dev Splits are currently active and withdrawals are disabled.
   */
  error SplitsAreActive();

  /*
   * @dev Transfer of fees failed.
   */
  error FeeTransferFailed();

  /*
   * @dev Refund of excess funds failed.
   */
  error RefundFailed();

  /*
   * @dev Withdrawal of funds failed.
   */
  error WithdrawFailed();

  /**
   * @dev Initializes the contract with the specified parameters.
   * param _owner The owner of the contract.
   * param _config The configuration for the contract.
   * param _drops The drop configurations for the initial tokens.
   */
  function initialize(
    address _owner,
    SeriesConfig calldata _config,
    Drop calldata _defaultDrop,
    DropMap calldata _dropOverrides
  ) external;

  /**
   * @dev Returns the name of the contract.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the contract.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the URI for a given token ID.
   * A single URI is returned for all token types as defined in EIP-1155's token type ID substitution mechanism.
   * Clients should replace `{id}` with the actual token type ID when calling the function.
   * @dev unused @param tokenId ID of the token to retrieve the URI for.
   */
  function uri(uint256) external view returns (string memory);

  /**
   * @dev Set the URI for all token IDs.
   * @param uri_ The URI for token all token IDs.
   */
  function setURI(string memory uri_) external;

  /**
   * @dev Returns the URI of the contract metadata.
   */
  function contractURI() external view returns (string memory);

  /**
   * @dev Sets the URI of the contract metadata.
   * @param contractURI_ The URI of the contract metadata.
   */
  function setContractURI(string memory contractURI_) external;


  /**
   * @dev Returns the range of token IDs that are valid for this contract.
   * @return startTokenId The starting token ID for this contract.
   * @return endTokenId The ending token ID for this contract.
   */
  function tokenRange() external view returns (uint128 startTokenId, uint128 endTokenId);

  /**
   * @dev Returns the drop configuration for the specified token ID.
   * @param tokenId The ID of the token to retrieve the drop configuration for.
   * @return drop The drop configuration mapped to the specified token ID.
   */
  function tokenDrop(uint128 tokenId) external view returns (Drop memory);

  /**
   * @dev Creates new tokens and updates drop configurations for specified token IDs.
   * @param newTokens Optional number of new token IDs to add to the existing token range.
   * @param dropMap Optional parameter object mapping token IDs, drop IDs, and drops.
   */
  function setTokenDrops(uint128 newTokens, DropMap calldata dropMap) external;

  /**
   * @dev Gets the current price for the specified token. If a currency oracle is set,
   * the price is calculated in native currency using the oracle exchange rate.
   * @param tokenId The ID of the token to get the price for.
   * @return The current price of the specified token.
   */
  function tokenPrice(uint256 tokenId) external view returns (uint256);

  /**
   * @dev Gets the current minting fee for the specified token.
   * @param tokenId The ID of the token to get the minting fee for.
   * @param quantity The quantity of tokens used to calculate the minting fee.
   * @return The current fee for minting the specified token.
   */
  function mintFee(uint256 tokenId, uint256 quantity) external view returns (uint256);

  /**
   * @dev Mints a specified number of tokens to a specified address.
   * @param tokenId The ID of the token to mint.
   * @param to The address to which the minted tokens will be sent.
   * @param quantity The quantity of tokens to mint.
   */
  function mint(uint256 tokenId, address to, uint256 quantity) external payable;

  /**
   * @dev Mints a batch of tokens to a specified address.
   * @param tokenIds The IDs of the tokens to mint.
   * @param to The address to which the minted tokens will be sent.
   * @param quantities The quantities to mint of each token.
   */
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata quantities
  ) external payable;

  /**
   * @dev Burns a specified quantity of tokens from the caller's account.
   * @param tokenId The ID of the token to burn.
   * @param quantity The quantity of tokens to burn.
   */
  function burn(uint256 tokenId, uint256 quantity) external;

  /**
   * @dev Mints a specified token to multiple recipients as part of an airdrop.
   * @param tokenId The ID of the token to mint.
   * @param recipients The list of addresses to receive the minted tokens.
   */
  function mintAirdrop(uint256 tokenId, address[] calldata recipients) external;

  /**
   * @dev Mints a specified number of tokens to the presale buyer address.
   * @param tokenId The ID of the token to mint.
   * @param quantity The quantity of tokens to mint.
   * @param maxQuantity The maximum quantity of tokens that can be minted.
   * @param pricePerToken The price per token in wei.
   * @param merkleProof The Merkle proof verifying that the presale buyer is eligible to mint tokens.
   */
  function mintPresale(
    uint256 tokenId,
    uint256 quantity,
    uint256 maxQuantity,
    uint256 pricePerToken,
    bytes32[] calldata merkleProof
  ) external payable;

  /**
   * @dev Pauses public minting.
   */
  function pause() external;

  /**
   * @dev Unpauses public minting.
   */
  function unpause() external;

  /**
   * @dev Sets the payout address to the specified address.
   * Use 0x0 to default to the contract owner.
   * @param _payoutAddress The address to set as the payout address.
   */
  function setPayoutAddress(address _payoutAddress) external;

  /**
   * @dev Withdraws the balance of the contract to the payout address or the contract owner.
  */
  function withdraw() external;

  /**
   * @dev Sets the royalty fee (ERC-2981: NFT Royalty Standard).
   * @param _royaltyBPS The royalty fee in basis points. (1/100th of a percent)
   */
  function setRoyaltyBPS(uint16 _royaltyBPS) external;

  /**
   * @dev Returns the royalty recipient and amount for a given sale price.
   * @param tokenId The ID of the token being sold.
   * @param salePrice The sale price of the token.
   * @return receiver The address of the royalty recipient.
   * @return royaltyAmount The amount to be paid to the royalty recipient.
   */
  function royaltyInfo(uint256 tokenId, uint256 salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);

  /**
   * @dev Returns true if the contract supports the given interface (ERC2981 or ERC1155),
   * as specified by interfaceId, false otherwise.
   * @param interfaceId The interface identifier, as specified in ERC-165.
   * @return True if the contract supports interfaceId, false otherwise.
   */
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);

  /**
   * @dev Updates the operator filter registry with the specified subscription.
   * @param enable If true, enables the operator filter, if false, disables it.
   * @param operatorFilter The address of the operator filter subscription.
   */
  function updateOperatorFilter(bool enable, address operatorFilter) external;

  /**
   * @dev Sets or revokes approval for a third party ("operator") to manage all of the caller's tokens.
   * @param operator The address of the operator to grant or revoke approval.
   * @param approved True to grant approval, false to revoke it.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IFeeManager {

  error SplitsAreActive();

  error WithdrawFailed();

  function setFees(uint256 _fee, uint256 _commissionBPS) external;

  function calculateFees(uint256 salePrice, uint256 quantity) external view returns (uint256 fee, uint256 commission);

  function recipient() external view returns (address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenWithBalance {
  function balanceOf(address owner) external
    returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

/**
 * @title ISplitMain
 * @author 0xSplits <[email protected]>
 */
interface ISplitMain {
  /**
   * FUNCTIONS
   */

  function walletImplementation() external returns (address);

  function createSplit(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address controller
  ) external returns (address);

  function predictImmutableSplitAddress(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external view returns (address);

  function updateSplit(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) external;

  function transferControl(address split, address newController) external;

  function cancelControlTransfer(address split) external;

  function acceptControl(address split) external;

  function makeSplitImmutable(address split) external;

  function distributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeETH(
    address split,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function distributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function updateAndDistributeERC20(
    address split,
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) external;

  function withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] calldata tokens
  ) external;

  /**
   * EVENTS
   */

  /** @notice emitted after each successful split creation
   *  @param split Address of the created split
   */
  event CreateSplit(address indexed split);

  /** @notice emitted after each successful split update
   *  @param split Address of the updated split
   */
  event UpdateSplit(address indexed split);

  /** @notice emitted after each initiated split control transfer
   *  @param split Address of the split control transfer was initiated for
   *  @param newPotentialController Address of the split's new potential controller
   */
  event InitiateControlTransfer(
    address indexed split,
    address indexed newPotentialController
  );

  /** @notice emitted after each canceled split control transfer
   *  @param split Address of the split control transfer was canceled for
   */
  event CancelControlTransfer(address indexed split);

  /** @notice emitted after each successful split control transfer
   *  @param split Address of the split control was transferred for
   *  @param previousController Address of the split's previous controller
   *  @param newController Address of the split's new controller
   */
  event ControlTransfer(
    address indexed split,
    address indexed previousController,
    address indexed newController
  );

  /** @notice emitted after each successful ETH balance split
   *  @param split Address of the split that distributed its balance
   *  @param amount Amount of ETH distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeETH(
    address indexed split,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful ERC20 balance split
   *  @param split Address of the split that distributed its balance
   *  @param token Address of ERC20 distributed
   *  @param amount Amount of ERC20 distributed
   *  @param distributorAddress Address to credit distributor fee to
   */
  event DistributeERC20(
    address indexed split,
    ERC20 indexed token,
    uint256 amount,
    address indexed distributorAddress
  );

  /** @notice emitted after each successful withdrawal
   *  @param account Address that funds were withdrawn to
   *  @param ethAmount Amount of ETH withdrawn
   *  @param tokens Addresses of ERC20s withdrawn
   *  @param tokenAmounts Amounts of corresponding ERC20s withdrawn
   */
  event Withdrawal(
    address indexed account,
    uint256 ethAmount,
    ERC20[] tokens,
    uint256[] tokenAmounts
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum SaleType {
  ALL,
  PRESALE,
  PRIMARY
}

struct TokenGateConfig {
  address tokenAddress; 
  uint88 minBalance;
  SaleType saleType;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *     registrant's entries in the OperatorFilterRegistry.
 * @dev  This smart contract is meant to be inherited by token contracts so they can use the following:
 *     - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *     - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
  error OperatorNotAllowed(address operator);

  IOperatorFilterRegistry public constant operatorFilterRegistry =
    IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

  modifier onlyAllowedOperator(address from) virtual {
    // Allow spending tokens from addresses with balance
    // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
    // from an EOA.
    if (from != msg.sender) {
      _checkFilterOperator(msg.sender);
    }
    _;
  }

  modifier onlyAllowedOperatorApproval(address operator) virtual {
    _checkFilterOperator(operator);
    _;
  }

  function _checkFilterOperator(address operator) internal view virtual {
    // Check registry code length to facilitate testing in environments without a deployed registry.
    if (address(operatorFilterRegistry).code.length > 0) {
      if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
        revert OperatorNotAllowed(operator);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Indicates whether the contract is currently paused or not.
     */
    bool private _paused;

    /**
     * @dev Error thrown when the contract is paused and an operation is attempted.
     */
    error Paused();

    /**
     * @dev Error thrown when the contract is not paused and an operation is attempted.
     */
    error NotPaused();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if ( paused() ) revert Paused();
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if ( ! paused() ) revert NotPaused();
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
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import "../splits/interfaces/ISplitMain.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Splits is Ownable {

  address public splitMain;
  address public splitWallet;

  function createSplit(
    address _splitMain,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee
  ) public virtual onlyOwner {
    require(splitWallet == address(0), "Split already created");
    splitMain = _splitMain;
    splitWallet = ISplitMain(splitMain).createSplit(
      accounts,
      percentAllocations,
      distributorFee,
      msg.sender
    );
  }

  function distributeETH(
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) public virtual requireSplit {
    _transferETHToSplit();
    ISplitMain(splitMain).distributeETH(
      splitWallet,
      accounts,
      percentAllocations,
      distributorFee,
      distributorAddress
    );
  }

  function distributeERC20(
    ERC20 token,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) public virtual requireSplit {
    _transferERC20ToSplit(token);
    ISplitMain(splitMain).distributeERC20(
      splitWallet,
      token,
      accounts,
      percentAllocations,
      distributorFee,
      distributorAddress
    );
  }

  function distributeAndWithdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] memory tokens,
    address[] calldata accounts,
    uint32[] calldata percentAllocations,
    uint32 distributorFee,
    address distributorAddress
  ) public virtual requireSplit {
    if (withdrawETH != 0) {
      distributeETH(
        accounts,
        percentAllocations,
        distributorFee,
        distributorAddress
      );
    }

    for (uint256 i = 0; i < tokens.length; ++i) {
      distributeERC20(
        tokens[i],
        accounts,
        percentAllocations,
        distributorFee,
        distributorAddress
      );
    }

    _withdraw(account, withdrawETH, tokens);
  }

  function transferToSplit(uint256 transferETH, ERC20[] memory tokens)
    public
    virtual
    requireSplit
  {
    if (transferETH != 0) {
      _transferETHToSplit();
    }

    for (uint256 i = 0; i < tokens.length; ++i) {
      _transferERC20ToSplit(tokens[i]);
    }
  }

  function _transferETHToSplit() internal virtual {
    (bool success, ) = splitWallet.call{value: address(this).balance}("");
    require(success, "Could not transfer ETH to split");
  }

  function _transferERC20ToSplit(ERC20 token) internal virtual {
    uint256 balance = token.balanceOf(address(this));
    token.transfer(splitWallet, balance);
  }

  function _withdraw(
    address account,
    uint256 withdrawETH,
    ERC20[] memory tokens
  ) internal virtual {
    ISplitMain(splitMain).withdraw(
      account,
      withdrawETH,
      tokens
    );
  }

  modifier requireSplit() {
    require(splitWallet != address(0), "Split not created yet");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Version {
  uint32 private immutable _version;

  /// @notice The version of the contract
  /// @return The version ID of this contract implementation
  function contractVersion() external view returns (uint32) {
      return _version;
  }

  constructor(uint32 version) {
    _version = version;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}