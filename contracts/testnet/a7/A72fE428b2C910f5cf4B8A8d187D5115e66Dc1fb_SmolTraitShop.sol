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
    
    error ContractsAreNotSet();
    error ArrayLengthMismatch();
    error TreasuryAddressNotSet();
    error InsufficientBalance(uint256 _balance, uint256 _price);
    error InvalidTraitSupply();
    error TraitIdDoesNotExist(uint256 _traitType, uint256 _traitId);
    error TraitIdSoldOut(uint256 _traitType, uint256 _traitId);
    error TraitNotCurrentlyForSale(uint256 _traitType, uint256 _traitId);
    error MustBeOwnerOfSmol();
    error NoCostumeEquipped();
    error SmolIsNotWearingACostume();
    error SmolAlreadyWearingCostume();
    error TraitAlreadyUnlockedForSmol(uint256 _smolId, uint256 _traitType, uint256 _traitId);
    error MustUnequipCostumeToEquiipTraits(uint256 _tokenId);
    error TraitNotUnlockedForSmol(uint256 _smolId, uint256 _traitType, uint256 _traitId);
    error MustCallBuyExclusiveTrait(uint256 _traitType, uint256 _traitId);
    error MerkleRootNotSet(uint256 _traitType, uint256 _traitId);
    error InvalidMerkleProof();
    error WhitelistAllocationExceeded();
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
//                      Buy Traits
// -------------------------------------------------------------

    /// @notice Unlock individual trait for one Smol Brain.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @param _traitId Id number of specifiic trait.
    function buyTrait(
        uint256 _smolId,
        TraitType _traitType,
        uint256 _traitId)
    external contractsAreSet whenNotPaused {
        _buy(_smolId, _traitType, _traitId);
    }

    /// @notice Unlock individual trait for multiple Smols or multiple traits for single Smol. Can be any trait slot or even multiples of one trait type. 
    /// @param _smolId Array of id numbers for selected Smol Brain tokens.
    /// @param _traitType Array of enums(0-7) representing which type of trait is being referenced.
    /// @param _traitId Array of id numbers for selected traits.
    function buyTraitBatch(
        uint256[] calldata _smolId,
        TraitType[] calldata _traitType,
        uint256[] calldata _traitId)
    external contractsAreSet whenNotPaused {
        uint256 amount = _smolId.length;
        _checkLengths(amount, _traitType.length);
        _checkLengths(amount, _traitId.length);
        for (uint256 i = 0; i < amount; i = _uncheckedIncrement(i)) {
            _buy(_smolId[i], _traitType[i], _traitId[i]);
        }
    }

    /// @notice Unlcok trait that is gated by a whitelist. Only unlockable with valid Merkle proof.
    /// @dev Will revert if trait has no Merkle root set.
    /// @param _proof Merkle proof to be checked against stored Merkle root.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @param _traitId Id number of specifiic trait.
    function buyExclusiveTrait(
        bytes32[] calldata _proof,
        uint256 _smolId,
        TraitType _traitType,
        uint256 _traitId)
    external contractsAreSet whenNotPaused {
        if (traitToInfo[_traitType][_traitId].merkleRoot == bytes32(0)) revert MerkleRootNotSet(uint(_traitType), _traitId);
        _checkWhitelistStatus(_traitType, _traitId, _proof);
        uint256 price = _checkBeforePurchase(_smolId, _traitType, _traitId);
        userAllocationClaimed[msg.sender][_traitType][_traitId] = true;
        _unlockTrait(price, _smolId, _traitType, _traitId);
    }

// -------------------------------------------------------------
//                      Equip / Remove Traits
// -------------------------------------------------------------

    /// @notice Equip a set of unlocked traits for a Smol Brain.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitsToEquip SmolBrain struct with trait ids to be equipped to smol.
    function equipTraits(
        uint256 _smolId,
        SmolBrain calldata _traitsToEquip) 
    external contractsAreSet whenNotPaused {
        _equipSet(_smolId, _traitsToEquip);
    }

    /// @notice Equip sets of unlocked traits for multiple Smol Brains in one tx.
    /// @param _smolId Array of id numbers for selected Smol Brain tokens.
    /// @param _traitsToEquip Array of SmolBrain structs with trait ids to be equipped to each smol.
    function equipTraitsBatch(
        uint256[] calldata _smolId,
        SmolBrain[] calldata _traitsToEquip) 
    external contractsAreSet whenNotPaused {
        uint256 amount = _smolId.length;
        _checkLengths(amount, _traitsToEquip.length);
        for (uint256 i = 0; i < amount; i = _uncheckedIncrement(i)) {
            _equipSet(_smolId[i], _traitsToEquip[i]);
        }
    }

    /// @notice Equip an unlocked costume for a Smol Brain.
    /// @param _smolId Id number of selected Smol Brain token.
    function putOnCostume(
        uint256 _smolId) 
    external contractsAreSet whenNotPaused {
        _checkSmolOwnership(_smolId);
        if (smolToEquippedTraits[_smolId].costume == 0) revert NoCostumeEquipped();
        if (smolToEquippedTraits[_smolId].isWearingCostume) revert SmolAlreadyWearingCostume();
        smolToEquippedTraits[_smolId].isWearingCostume = true;
        emit UpdateSmolTraits(
            _smolId,
            smolToEquippedTraits[_smolId]
        );
    }

    /// @notice Take off an equipped costume to switch back to equipped traits.
    /// @param _smolId Id number of selected Smol Brain token.
    function takeOffCostume(
        uint256 _smolId) 
    external contractsAreSet whenNotPaused {
        _checkSmolOwnership(_smolId);
        if (!smolToEquippedTraits[_smolId].isWearingCostume) revert SmolIsNotWearingACostume();
        smolToEquippedTraits[_smolId].isWearingCostume = false;
        emit UpdateSmolTraits(
            _smolId,
            smolToEquippedTraits[_smolId]
        );
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

// -------------------------------------------------------------
//               External Admin/Owner Functions
// -------------------------------------------------------------

    /// @notice Set new Trait struct info and save it to traitToInfo mapping.
    /// @dev Trait ids are auto incremented and assigned. Ids are unique to each trait type.
    /// @param _traitType Array of enums(0-7) representing which type of trait is being referenced.
    /// @param _traitInfo Array of Trait structs containing all information needed to add trait to contract.
    function setTraitInfo (
        TraitType[] calldata _traitType,
        Trait[] calldata _traitInfo) 
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        uint256 amount = _traitType.length;
        _checkLengths(amount, _traitInfo.length);
        for (uint256 i = 0; i < amount; i = _uncheckedIncrement(i)) {
            TraitType traitType = _traitType[i];
            Trait memory trait = _traitInfo[i];
            traitTypeToLastId[traitType] ++;
            uint256 id = traitTypeToLastId[traitType];
            if (trait.maxSupply > 0) {
                trait.uncappedSupply = false;
            }
            else {
                trait.maxSupply = 0;
                trait.uncappedSupply = true;
            }
            trait.amountClaimed = 0;
            traitToInfo[traitType][id] = trait;
            emit TraitAddedToContract(
                traitType,
                id,
                trait
            );
            if (trait.forSale){
                _addTraitToSale(traitType, id);
            }
        }
    }

    /// @notice Change existing trait sale status.
    /// @dev Also adds and removes trait from for sale array.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @param _traitId Id number of specifiic trait.
    /// @param _forSale New bool value to add(true)/remove(false) traits from sale.
    function changeTraitSaleStatus (
        TraitType _traitType,
        uint256 _traitId,
        bool _forSale) 
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        require (traitToInfo[_traitType][_traitId].forSale != _forSale);
        _checkTraitId(_traitType, _traitId);
        if (traitToInfo[_traitType][_traitId].forSale && !_forSale){
            _removeTraitFromSale(_traitType, _traitId);
            }
        else{
            _addTraitToSale(_traitType, _traitId);
            traitToInfo[_traitType][_traitId].forSale = true;
        }
    }

    /// @notice Change stored merkle root attached to existing trait for whitelist.
    /// @dev Change to 0x0000000000000000000000000000000000000000000000000000000000000000 to remove whitelist.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @param _traitId Id number of specifiic trait.
    /// @param _merkleRoot New merkle root for whitelist verification or empty root for normal sale.
    function changeTraitMerkleRoot (
        TraitType _traitType,
        uint256 _traitId,
        bytes32 _merkleRoot) 
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        _checkTraitId(_traitType, _traitId);
        traitToInfo[_traitType][_traitId].merkleRoot = _merkleRoot;
    }

    /// @notice Change existing trait name.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @param _traitId Id number of specifiic trait.
    /// @param _name New string to be set as trait name.
    function changeTraitName (
        TraitType _traitType,
        uint256 _traitId,
        string calldata _name) 
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        _checkTraitId(_traitType, _traitId);
        traitToInfo[_traitType][_traitId].name = _name;
    }

    /// @notice Change existing trait price.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @param _traitId Id number of specifiic trait.
    /// @param _price New price for trait in base units.
    function changeTraitPrice (
        TraitType _traitType,
        uint256 _traitId,
        uint32 _price) 
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        _checkTraitId(_traitType, _traitId);
        traitToInfo[_traitType][_traitId].price = _price;
    }

    /// @notice Change max supply or remove supply cap for an existing trait. 
    /// @dev _maxSupply=0 : No supply cap | _maxSupply>0 : Supply cap is set to _maxSupply.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @param _traitId Id number of specifiic trait.
    /// @param _maxSupply New max supply value for selected trait. Enter 0 to remove supply cap.
    function changeTraitSupply (
        TraitType _traitType,
        uint256 _traitId,
        uint32 _maxSupply)
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        _checkTraitId(_traitType, _traitId);
        if (_maxSupply != 0) {
            if (_maxSupply < traitToInfo[_traitType][_traitId].amountClaimed) revert InvalidTraitSupply();
            traitToInfo[_traitType][_traitId].maxSupply = _maxSupply;
            traitToInfo[_traitType][_traitId].uncappedSupply = false;
        }
        else {
            traitToInfo[_traitType][_traitId].maxSupply = 0;
            traitToInfo[_traitType][_traitId].uncappedSupply = true;
        }
    }

// would the team prefer this to be only owner or only admin or both?
    /// @notice Withdraw all Magic from contract.
    function withdrawMagic() external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        if (treasuryAddress == address(0)) revert TreasuryAddressNotSet();
        uint256 contractBalance = magicToken.balanceOf(address(this));
        magicToken.transfer(treasuryAddress, contractBalance);
    }

// -------------------------------------------------------------
//                   Internal Functions
// -------------------------------------------------------------

    /// @dev Adds trait id to sale array for that trait type.
    function _addTraitToSale (
        TraitType _traitType,
        uint256 _traitId) 
    internal {
        traitIdsForSale[_traitType].add(_traitId);
        emit TraitSaleStateChanged(
            _traitType, 
            _traitId,
            true
        );
    }

    /// @dev Removes trait id from sale array for that trait type.
    function _removeTraitFromSale (
        TraitType _traitType,
        uint256 _traitId) 
    internal {
        traitIdsForSale[_traitType].remove(_traitId);
        traitToInfo[_traitType][_traitId].forSale = false;
        emit TraitSaleStateChanged(
            _traitType, 
            _traitId,
            false
        );
    }

    /// @dev Check to verify _traitId is within range of valid trait ids.
    function _checkTraitId (
        TraitType _traitType,
        uint256 _traitId)
    internal view{
        if (_traitId <= 0) revert TraitIdDoesNotExist(uint(_traitType), _traitId);
        if (traitTypeToLastId[_traitType] < _traitId) revert TraitIdDoesNotExist(uint(_traitType), _traitId);
    }

    /// @dev Check to verify array lengths of input arrays are equal
    function _checkLengths(
        uint256 target,
        uint256 length)
    internal pure {
        if (target != length) revert ArrayLengthMismatch();
    }
    
    /// @dev Increment uint unchecked for small gas savings across functions with loops
    function _uncheckedIncrement (
        uint x)
    internal pure returns(uint) {
        unchecked {return x + 1;}
    }

// -------------------------------------------------------------
//                 Essential Setter Functions
// -------------------------------------------------------------

    /// @notice Set wallet address to withdraw Magic to.
    function setTreasuryAddress(
        address _treasuryAddress)
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        treasuryAddress = _treasuryAddress;
    }

    /// @notice Set other contract addresses.
    function setContracts(
        address _smolBrains,
        address _magicToken)
    external requiresEitherRole(ADMIN_ROLE, OWNER_ROLE) {
        smolBrains = IERC721(_smolBrains);
        magicToken = IERC20Upgradeable(_magicToken);
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
        return address(smolBrains) != address(0)
        && address(magicToken) != address(0);
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

contract SmolTraitShopInternal is Initializable, SmolTraitShopView {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

// -------------------------------------------------------------
//                   Buy Internal Functions
// -------------------------------------------------------------

    /// @dev Used by all buy functions except for traits that require merkle proof verification.
    function _buy(
        uint256 _smolId,
        TraitType _traitType,
        uint256 _traitId)
    internal {
        if (traitToInfo[_traitType][_traitId].merkleRoot != bytes32(0)) revert MustCallBuyExclusiveTrait(uint(_traitType), _traitId);
        uint256 price = _checkBeforePurchase(_smolId, _traitType, _traitId);
        _unlockTrait(price, _smolId, _traitType, _traitId);
    }

    /// @dev Internal helper function that unlocks an upgrade for specified vehicle and emits UpgradeUnlocked event.
    function _unlockTrait(
        uint256 _price,
        uint256 _smolId,
        TraitType _traitType,
        uint256 _traitId)
    internal {
        if (_price != 0){
            magicToken.transferFrom(msg.sender, address(this), _price);
        }
        traitToInfo[_traitType][_traitId].amountClaimed ++;
        // If item is sold out; remove that item from sale.
        if (traitToInfo[_traitType][_traitId].amountClaimed == traitToInfo[_traitType][_traitId].maxSupply) {
            _removeTraitFromSale(_traitType, _traitId);
        }
        traitIdsOwnedBySmol[_smolId][_traitType].add(_traitId);
        emit TraitUnlocked(
        _smolId,
        _traitType,
        _traitId
        );
    } 

// -------------------------------------------------------------
//                  Equip Internal Functions
// -------------------------------------------------------------

    /// @dev Equip a set of unlocked traits for single Smol Brain.
    function _equipSet(
        uint256 _smolId,
        SmolBrain calldata _traitsToEquip) 
    internal {
        _checkSmolOwnership(_smolId);
        if (_traitsToEquip.background > 0) {
            _checkBeforeEquip(_smolId, TraitType.Background, _traitsToEquip.background);
        }
        if (_traitsToEquip.body > 0) {
            _checkBeforeEquip(_smolId, TraitType.Body, _traitsToEquip.body);
        }
        if (_traitsToEquip.hair > 0) {
           _checkBeforeEquip(_smolId, TraitType.Hair, _traitsToEquip.hair);
        }
        if (_traitsToEquip.clothes > 0) {
            _checkBeforeEquip(_smolId, TraitType.Clothes, _traitsToEquip.clothes);
        }           
        if (_traitsToEquip.glasses > 0) {
            _checkBeforeEquip(_smolId, TraitType.Glasses, _traitsToEquip.glasses);
        }    
        if (_traitsToEquip.hat > 0) {
            _checkBeforeEquip(_smolId, TraitType.Hat, _traitsToEquip.hat);
        }   
        if (_traitsToEquip.mouth > 0) {
            _checkBeforeEquip(_smolId, TraitType.Mouth, _traitsToEquip.mouth);
        }
        if (_traitsToEquip.costume > 0) {
            _checkBeforeEquip(_smolId, TraitType.Costume, _traitsToEquip.costume);
        }
        smolToEquippedTraits[_smolId] = _traitsToEquip;
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
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../../shared/UtilitiesV2Upgradeable.sol";
import "./ISmolTraitShop.sol";

/// @title Smol Trait Shop State
/// @author Gearhart
/// @notice Shared storage layout for SmolTraitShop.

abstract contract SmolTraitShopState is Initializable, UtilitiesV2Upgradeable, ISmolTraitShop {

// -------------------------------------------------------------
//                       Events
// -------------------------------------------------------------

    // new Trait added to a smols inventory
    event TraitUnlocked(
        uint256 indexed _smolId,
        TraitType _traitType,
        uint256 _traitId
    );

    // new set of Traits equipped to smol
    event UpdateSmolTraits(
        uint256 indexed _smolId,
        SmolBrain _equippedTraits
    );

    // Trait has been added to contract
    event TraitAddedToContract(
        TraitType indexed _traitType,
        uint256 _traitId,
        Trait _traitInfo
    );

    // Trait has been added to or removed from sale
    event TraitSaleStateChanged(
        TraitType indexed _traitType,
        uint256 _traitId,
        bool _added
    );

// -------------------------------------------------------------
//                   Mappings & Variables
// -------------------------------------------------------------

    IERC721 public smolBrains;
    IERC20Upgradeable public magicToken;

    // team wallet address for magic withdraw
    address public treasuryAddress;

    // mapping for keeping track of user WL allocation if merkleroot is assigned to a trait
    // user address => enum (TraitType) => trait Id => WL spot claimed or not
    mapping (address => mapping (TraitType => mapping(uint256 => bool))) 
        public userAllocationClaimed;

    // mapping that holds struct containing trait info by trait type for each id
    // enum (TraitType) => trait id => Trait struct 
    mapping (TraitType => mapping(uint256 => Trait)) 
        public traitToInfo;

    // highest id number currently in use for each trait type
    mapping (TraitType => uint256) 
        public traitTypeToLastId;

    // mapping to struct holding ids of currently equiped traits for a given smol
    // smol id => SmolBrain struct
    mapping (uint256 => SmolBrain) 
        public smolToEquippedTraits;

    // enum (TraitType) => Enumerable Uint Set of all traits currently for sale
    mapping (TraitType => EnumerableSetUpgradeable.UintSet) 
        internal traitIdsForSale;

    // smol id => Enumerable Uint Set of all unlocked traits
    mapping (uint256 => mapping (TraitType => EnumerableSetUpgradeable.UintSet))
        internal traitIdsOwnedBySmol;

// -------------------------------------------------------------
//                       Enums
// -------------------------------------------------------------

    // enum to control input and application
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
    struct Trait {
        string name;
        uint32 price;
        uint32 amountClaimed;
        uint32 maxSupply;
        bool uncappedSupply;
        bool forSale;
        bytes32 merkleRoot;
    }
   
   // struct to act as inventory slots for equipping traits to smols
    struct SmolBrain {
        uint16 background;
        uint16 body;
        uint16 hair;
        uint16 clothes;
        uint16 glasses;
        uint16 hat;
        uint16 mouth;
        uint16 costume;
        bool isWearingCostume;
    }

//might just return arrays instead of loading struct depending on what front end prefers
    // struct to act as a smols inventory which holds arrays containing all unlocked ids for each trait type
    struct SmolInventory {
        uint256[] background;
        uint256[] body;
        uint256[] hair;
        uint256[] clothes;
        uint256[] glasses;
        uint256[] hat;
        uint256[] mouth;
        uint256[] costume;
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

    /// @notice Get all id numbers for one trait type that are currently for sale.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @return Array of trait id numbers that can be bought for a trait type.
    function getTraitsForSale(
        TraitType _traitType) 
    external view returns (uint256[] memory) {
        return traitIdsForSale[_traitType].values();
    }

// might just return the arrays instead of loading it all into a struct depending on what the front end prefers
    /// @notice Get all id numbers for all trait types that are currently for sale.
    /// @return SmolInventory struct full of arrays containing trait id numbers that can be bought for each trait type.
    function getAllTraitsForSale() 
    external view returns (SmolInventory memory) {
        SmolInventory memory shopInventory;
        shopInventory.background = traitIdsForSale[TraitType.Background].values();
        shopInventory.body = traitIdsForSale[TraitType.Body].values();
        shopInventory.hair = traitIdsForSale[TraitType.Hair].values();
        shopInventory.clothes = traitIdsForSale[TraitType.Clothes].values();
        shopInventory.glasses = traitIdsForSale[TraitType.Glasses].values();
        shopInventory.hat = traitIdsForSale[TraitType.Hat].values();
        shopInventory.mouth = traitIdsForSale[TraitType.Mouth].values();
        shopInventory.costume = traitIdsForSale[TraitType.Costume].values();
        return shopInventory;
    }

    /// @notice Get all id numbers for one trait type that are currently for sale.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @param _traitType Enum(0-7) representing which type of trait is being referenced.
    /// @return Array of trait id numbers that can be bought for a trait type.
    function getTraitsOwnedBySmol(
        uint256 _smolId,
        TraitType _traitType) 
    external view returns (uint256[] memory) {
        return traitIdsOwnedBySmol[_smolId][_traitType].values();
    }

// might just return the arrays instead of loading it all into a struct depending on what the front end prefers
    /// @notice Get all id numbers for every trait type that is currently owned by selected smol.
    /// @param _smolId Id number of selected Smol Brain token.
    /// @return SmolInventory struct full of arrays containing trait id numbers that have been unlocked for smol.
    function getAllTraitsOwnedBySmol(
        uint256 _smolId) 
    external view returns (SmolInventory memory) {
        SmolInventory memory smolInventory;
        smolInventory.background = traitIdsOwnedBySmol[_smolId][TraitType.Background].values();
        smolInventory.body = traitIdsOwnedBySmol[_smolId][TraitType.Body].values();
        smolInventory.hair = traitIdsOwnedBySmol[_smolId][TraitType.Hair].values();
        smolInventory.clothes = traitIdsOwnedBySmol[_smolId][TraitType.Clothes].values();
        smolInventory.glasses = traitIdsOwnedBySmol[_smolId][TraitType.Glasses].values();
        smolInventory.hat = traitIdsOwnedBySmol[_smolId][TraitType.Hat].values();
        smolInventory.mouth = traitIdsOwnedBySmol[_smolId][TraitType.Mouth].values();
        smolInventory.costume = traitIdsOwnedBySmol[_smolId][TraitType.Costume].values();
        return smolInventory;
    }

// -------------------------------------------------------------
//                  Internal View Functions
// -------------------------------------------------------------

    /// @dev Various checks that must be made before any trait purchase.
    function _checkBeforePurchase(
        uint256 _smolId,
        TraitType _traitType,
        uint256 _traitId) 
    internal view returns(uint256 price){
        _checkTraitId(_traitType, _traitId);
        _checkSmolOwnership(_smolId);
        Trait memory trait = traitToInfo[_traitType][_traitId];
        if (traitIdsOwnedBySmol[_smolId][_traitType].contains(_traitId)) revert TraitAlreadyUnlockedForSmol(_smolId, uint(_traitType), _traitId);
        if (!trait.forSale) revert TraitNotCurrentlyForSale(uint(_traitType), _traitId);
        if (!trait.uncappedSupply) {
            if (trait.amountClaimed + 1 > trait.maxSupply) revert TraitIdSoldOut(uint(_traitType), _traitId);
        }
        price = trait.price;
        if (price != 0){
            _checkMagicBalance(price);
        }
    }

    /// @dev Verify msg.sender is owner of smol.
    function _checkSmolOwnership(
        uint256 _smolId) 
    internal view {
        if (smolBrains.ownerOf(_smolId) != msg.sender) revert MustBeOwnerOfSmol();
    }

    /// @dev Check balance of magic for msg.sender.
    function _checkMagicBalance(
        uint256 _amount) 
    internal view {
        uint256 bal = magicToken.balanceOf(msg.sender);
        if (bal < _amount) revert InsufficientBalance(bal, _amount);
    }

    /// @dev Verify merkle proof for user and check if allocation has been claimed.
    function _checkWhitelistStatus(
        TraitType _traitType,
        uint256 _traitId,
        bytes32[] calldata _proof) 
    internal view {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            if (!MerkleProofUpgradeable.verify(_proof, traitToInfo[_traitType][_traitId].merkleRoot, leaf)) revert InvalidMerkleProof();
            if (userAllocationClaimed[msg.sender][_traitType][_traitId]) revert WhitelistAllocationExceeded();
    }

    /// @dev Check used for ownership when equipping upgrades.
    function _checkBeforeEquip (
        uint256 _smolId,
        TraitType _traitType, 
        uint256 _traitId) 
    internal view {
        if (!traitIdsOwnedBySmol[_smolId][_traitType].contains(_traitId)) revert TraitNotUnlockedForSmol(_smolId, uint(_traitType), _traitId);
    }

// -------------------------------------------------------------
//                       Initializer
// -------------------------------------------------------------

    function __SmolTraitShopView_init() internal initializer {
        SmolTraitShopAdmin.__SmolTraitShopAdmin_init();
    }
}