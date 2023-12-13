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
pragma solidity ^0.8.20;

import {Limiter, LimiterLibrary, Transfer} from "./Limiter.sol";
import {LinkedList, LinkedListLibrary} from "./LinkedList.sol";

using LimiterLibrary for Limiter;
using LinkedListLibrary for LinkedList;

struct InternalBeneficiary {
    address account;
    Limiter limiter;
    uint enabledAt;
}

using InternalBeneficiaryLibrary for InternalBeneficiary;

library InternalBeneficiaryLibrary {
    function convert(InternalBeneficiary storage self) internal view returns (Beneficiary memory) {
        return
            Beneficiary({
                account: self.account,
                enabledAt: self.enabledAt,
                limit: self.limiter.limit,
                remainingLimit: self.limiter.remainingLimit(),
                transfers: self.limiter.transfers()
            });
    }
}

struct Beneficiary {
    address account;
    uint enabledAt;
    uint limit;
    int remainingLimit;
    Transfer[] transfers;
}

struct Beneficiaries {
    LinkedList _keys;
    mapping(uint128 => InternalBeneficiary) _beneficiaries;
    mapping(address => uint128) _addressKeys;
}

using BeneficiariesLibrary for Beneficiaries;

library BeneficiariesLibrary {
    error BeneficiaryAlreadyExists(address beneficiary);
    error BeneficiaryNotEnabled(address beneficiary);
    error BeneficiaryNotDefined(address beneficiary);
    error BeneficiaryLimitExceeded(address beneficiary);

    function addBeneficiary(
        Beneficiaries storage self,
        address _beneficiary,
        uint _interval,
        uint _limit,
        uint _cooldown
    ) internal {
        if (self._addressKeys[_beneficiary] != 0) {
            revert BeneficiaryAlreadyExists(_beneficiary);
        }
        uint128 key = self._keys.generate();
        self._beneficiaries[key].account = _beneficiary;
        self._beneficiaries[key].enabledAt = block.timestamp + _cooldown;
        self._beneficiaries[key].limiter.interval = _interval;
        self._beneficiaries[key].limiter.limit = _limit;
        self._addressKeys[_beneficiary] = key;
    }

    function setBeneficiaryLimit(Beneficiaries storage self, address _beneficiary, uint _limit) internal {
        InternalBeneficiary storage beneficiary = _getBeneficiary(self, _beneficiary);
        beneficiary.limiter.limit = _limit;
    }

    function temporarilyIncreaseBeneficiaryLimit(
        Beneficiaries storage self,
        address _beneficiary,
        uint _limitIncrease
    ) internal {
        InternalBeneficiary storage beneficiary = _getBeneficiary(self, _beneficiary);
        beneficiary.limiter.temporarilyIncreaseLimit(_limitIncrease);
    }

    function temporarilyDecreaseBeneficiaryLimit(
        Beneficiaries storage self,
        address _beneficiary,
        uint _limitDecrease
    ) internal {
        InternalBeneficiary storage beneficiary = _getBeneficiary(self, _beneficiary);
        beneficiary.limiter.temporarilyDecreaseLimit(_limitDecrease);
    }

    function addBeneficiaryTransfer(Beneficiaries storage self, address _beneficiary, uint _amount) internal {
        InternalBeneficiary storage beneficiary = _getBeneficiary(self, _beneficiary);
        if (block.timestamp < beneficiary.enabledAt) {
            revert BeneficiaryNotEnabled(_beneficiary);
        }
        if (!beneficiary.limiter.addTransfer(_amount)) {
            revert BeneficiaryLimitExceeded(_beneficiary);
        }
    }

    function _getBeneficiaryKey(Beneficiaries storage self, address _beneficiary) private view returns (uint128) {
        uint128 key = self._addressKeys[_beneficiary];
        if (key == 0) {
            revert BeneficiaryNotDefined(_beneficiary);
        }
        return key;
    }

    function _getBeneficiary(
        Beneficiaries storage self,
        address _beneficiary
    ) private view returns (InternalBeneficiary storage) {
        return self._beneficiaries[_getBeneficiaryKey(self, _beneficiary)];
    }

    function getBeneficiary(
        Beneficiaries storage self,
        address _beneficiary
    ) internal view returns (Beneficiary memory) {
        return _getBeneficiary(self, _beneficiary).convert();
    }

    function removeBeneficiary(Beneficiaries storage self, address _beneficiary) internal {
        uint128 key = _getBeneficiaryKey(self, _beneficiary);
        delete self._beneficiaries[key];
        self._keys.remove(key);
    }

    function getBeneficiaries(Beneficiaries storage self) internal view returns (Beneficiary[] memory) {
        Beneficiary[] memory beneficiaries = new Beneficiary[](self._keys.length());
        uint index = 0;
        uint128 key = self._keys.first();
        while (key != 0) {
            beneficiaries[index] = self._beneficiaries[key].convert();
            key = self._keys.next(key);
            index++;
        }
        return beneficiaries;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract ExtendedAccessControlUpgradeable is AccessControlUpgradeable {
    /// @custom:storage-location erc7201:fortesecurities.ExtendedAccessControlUpgradeable
    struct ExtendedAccessControlUpgradeableStorage {
        bytes32[] roles;
    }

    // keccak256(abi.encode(uint256(keccak256("fortesecurities.ExtendedAccessControlUpgradeable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ExtendedAccessControlUpgradeableStorageLocation =
        0x19b29a04048f51eb9591acef31c8d25631a0f178287c237da958990d82c90400;

    function _getExtendedAccessControlUpgradeableStorage()
        private
        pure
        returns (ExtendedAccessControlUpgradeableStorage storage $)
    {
        assembly {
            $.slot := ExtendedAccessControlUpgradeableStorageLocation
        }
    }

    function __ExtendedAccessControl_init() internal initializer {
        __ExtendedAccessControl_init_unchained();
    }

    function __ExtendedAccessControl_init_unchained() internal initializer {
        _addRole(DEFAULT_ADMIN_ROLE);
    }

    /**
     * @dev Returns the list of roles.
     * @return bytes32[] List of roles.
     */
    function roles() public view returns (bytes32[] memory) {
        ExtendedAccessControlUpgradeableStorage storage $ = _getExtendedAccessControlUpgradeableStorage();
        return $.roles;
    }

    /**
     * @dev Adds a role to the list of roles.
     * @param role Role to be added.
     */
    function _addRole(bytes32 role) internal {
        ExtendedAccessControlUpgradeableStorage storage $ = _getExtendedAccessControlUpgradeableStorage();
        $.roles.push(role);
    }

    /**
     * @dev Grants all roles to a specified address.
     * @param _address Address to be granted roles.
     */
    function _grantRoles(address _address) internal {
        bytes32[] memory _roles = roles();
        for (uint256 i = 0; i < _roles.length; i++) {
            _grantRole(_roles[i], _address);
        }
    }

    /**
     * @dev Grants all roles to a specified address.
     * Can only be called by an account with the DEFAULT_ADMIN_ROLE.
     * @param _address Address to be granted roles.
     */
    function grantRoles(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRoles(_address);
    }

    /**
     * @dev Revokes all roles from a specified address.
     * Can only be called by an account with the DEFAULT_ADMIN_ROLE.
     * @param _address Address to be revoked roles.
     */
    function revokeRoles(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32[] memory _roles = roles();
        for (uint256 i = 0; i < _roles.length; i++) {
            _revokeRole(_roles[i], _address);
        }
    }

    /**
     * @dev Revokes all roles held by `from` account, and grants those roles to `to` account
     * Can only be called by an account with the DEFAULT_ADMIN_ROLE.
     * @param from Address to be revoked roles.
     * @param to Address to be granted roles.
     */
    function transferRoles(address from, address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes32[] memory _roles = roles();
        for (uint256 i = 0; i < _roles.length; i++) {
            bytes32 role = _roles[i];
            if (hasRole(role, from)) {
                _grantRole(role, to);
                _revokeRole(role, from);
            }
        }
    }

    /**
     * @dev Revokes all roles held by the sender, and grants those roles to `to` account
     * Can only be called by an account with the DEFAULT_ADMIN_ROLE.
     * @param to Address to be granted roles.
     */
    function transferRoles(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        transferRoles(_msgSender(), to);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LinkedListLibrary, LinkedList} from "./LinkedList.sol";

using LinkedListLibrary for LinkedList;

struct Transfer {
    int amount;
    uint timestamp;
}

struct Limiter {
    uint interval;
    uint limit;
    LinkedList _keys;
    mapping(uint128 => Transfer) _transfers;
}

using LimiterLibrary for Limiter;

library LimiterLibrary {
    function transfers(Limiter storage self) internal view returns (Transfer[] memory) {
        Transfer[] memory _transfers = new Transfer[](self._keys.length());
        uint index = 0;
        uint128 key = self._keys.first();
        while (key != 0) {
            _transfers[index] = self._transfers[key];
            key = self._keys.next(key);
            index++;
        }
        return _transfers;
    }

    function temporarilyIncreaseLimit(Limiter storage self, uint _limitIncrease) internal {
        _addUncheckedTransfer(self, -int(_limitIncrease));
    }

    function temporarilyDecreaseLimit(Limiter storage self, uint _limitDecrease) internal {
        _addUncheckedTransfer(self, int(_limitDecrease));
    }

    function remainingLimit(Limiter storage self) internal view returns (int) {
        return int(self.limit) - self.usedLimit();
    }

    function usedLimit(Limiter storage self) internal view returns (int) {
        int _sum = 0;
        uint128 key = self._keys.first();
        while (key != 0) {
            if (self._transfers[key].timestamp > block.timestamp - self.interval) {
                _sum += self._transfers[key].amount;
            }
            key = self._keys.next(key);
        }
        return _sum;
    }

    function _filterTransfers(Limiter storage self) private {
        uint128 key = self._keys.first();
        while (key != 0) {
            if (self._transfers[key].timestamp > block.timestamp - self.interval) {
                break;
            }
            delete self._transfers[key];
            key = self._keys.remove(key);
        }
    }

    function _addTransferNode(Limiter storage self, int _amount) private {
        uint128 key = self._keys.generate();
        self._transfers[key] = Transfer({amount: int(_amount), timestamp: block.timestamp});
    }

    function _addUncheckedTransfer(Limiter storage self, int _amount) private {
        _filterTransfers(self);
        _addTransferNode(self, _amount);
    }

    function addTransfer(Limiter storage self, uint _amount) internal returns (bool) {
        _addUncheckedTransfer(self, int(_amount));
        return self.remainingLimit() >= 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

using LinkedListLibrary for LinkedList;

struct Node {
    uint128 previous;
    uint128 next;
}

struct LinkedList {
    uint128 _first;
    uint128 _last;
    uint128 _next;
    uint128 _length;
    mapping(uint128 => Node) _nodes;
}

/**
 * @dev Library for a doubly linked list that stores mono-increasing uint128 values.
 * The list is 1-indexed, with 0 used as a sentinel value.
 * Uses uint128 for storage efficiency.
 */
library LinkedListLibrary {
    /**
     * @dev Generates a new mono-increasing value, pushes it to back of the list and returns it.
     * @param self The linked list.
     */
    function generate(LinkedList storage self) internal returns (uint128) {
        self._next++;
        if (self._last != 0) {
            self._nodes[self._next].previous = self._last;
            self._nodes[self._last].next = self._next;
        } else {
            self._first = self._next;
        }
        self._last = self._next;
        self._length++;
        return self._next;
    }

    /**
     * @dev Returns the length of the list.
     * @param self The linked list.
     */
    function length(LinkedList storage self) internal view returns (uint128) {
        return self._length;
    }

    /**
     * @dev Returns the first value of the list (zero if the list is empty).
     * @param self The linked list.
     */
    function first(LinkedList storage self) internal view returns (uint128) {
        return self._first;
    }

    /**
     * @dev Returns the next value in the list following a specific value (zero if no next value).
     * @param self The linked list.
     * @param _value The value to query the next value of.
     */
    function next(LinkedList storage self, uint128 _value) internal view returns (uint128) {
        return self._nodes[_value].next;
    }

    /**
     * @dev Removes a value in the list.
     * @param self The linked list.
     * @param _value The value to remove.
     */
    function remove(LinkedList storage self, uint128 _value) internal returns (uint128) {
        Node storage node = self._nodes[_value];
        if (node.previous != 0) {
            self._nodes[node.previous].next = node.next;
        } else {
            self._first = node.next;
        }
        if (node.next != 0) {
            self._nodes[node.next].previous = node.previous;
        } else {
            self._last = node.previous;
        }
        uint128 _next = self._nodes[_value].next;
        delete self._nodes[_value];
        self._length--;
        return _next;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Limiter, LimiterLibrary, Transfer} from "./Limiter.sol";
import {Beneficiary, Beneficiaries, BeneficiariesLibrary} from "./Beneficiaries.sol";
import {ExtendedAccessControlUpgradeable} from "./ExtendedAccessControlUpgradeable.sol";

using LimiterLibrary for Limiter;
using BeneficiariesLibrary for Beneficiaries;

interface IToken is IERC20 {
    function mint(uint256 _amount) external;

    function burn(uint256 _amount) external;
}

contract Wallet is ExtendedAccessControlUpgradeable {
    error LimitExceeded();

    // Define constants for various roles using the keccak256 hash of the role names.
    bytes32 public constant BENEFICIARY_ROLE = keccak256("BENEFICIARY_ROLE");
    bytes32 public constant BENEFICIARY_LIMIT_ROLE = keccak256("BENEFICIARY_LIMIT_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant LIMIT_ROLE = keccak256("LIMIT_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    IToken public token; // Reference to the token contract.
    Limiter private limiter; // Limits the amount of transfers possible within a given timeframe.
    Beneficiaries private beneficiaries; // Keeps track of beneficiaries allowed by this contract.

    /**
     * @dev Emitted when a beneficiary with address `address`, 24-hour transfer limit `limit`
     * and cooldown period `period` (in seconds) is added to the list of beneficiaries.
     */
    event BeneficiaryAdded(address beneficiary, uint limit, uint cooldown);

    /**
     * @dev Emitted when the 24-hour transfer limit of beneficiary with address `address`
     * is changed to `limit`.
     */
    event BeneficiaryLimitChanged(address beneficiary, uint limit);

    /**
     * @dev Emitted when the 24-hour transfer limit of beneficiary with address `address`
     * is temporarily decreased by `limitDecrease`.
     */
    event BeneficiaryLimitTemporarilyDecreased(address beneficiary, uint limitDecrease);

    /**
     * @dev Emitted when the 24-hour transfer limit of beneficiary with address `address`
     * is temporarily increased by `limitIncrease`.
     */
    event BeneficiaryLimitTemporarilyIncreased(address beneficiary, uint limitIncrease);

    /**
     * @dev Emitted when the beneficiary with address `address` is removed from the list of beneficiaries.
     */
    event BeneficiaryRemoved(address beneficiary);

    /**
     * @dev Emitted when the 24-hour transfer limit is changed to `limit`.
     */
    event LimitChanged(uint limit);

    /**
     * @dev Emitted when the 24-hour transfer limit is temporarily decreased by `limitDecrease`.
     */
    event LimitTemporarilyDecreased(uint limitDecrease);

    /**
     * @dev Emitted when the 24-hour transfer limit is temporarily increased by `limitIncrease`.
     */
    event LimitTemporarilyIncreased(uint limitIncrease);

    /**
     * @dev Emitted when `amount` of tokens are transferred to `beneficiary`.
     */
    event Transferred(address beneficiary, uint amount);

    /**
     * @dev Emitted when `amount` of `token` are transferred to `to`.
     */
    event Transferred(IERC20 token, address to, uint amount);

    /**
     * @dev Emitted when an `amount` of tokens is minted.
     */
    event Minted(uint amount);

    /**
     * @dev Emitted when an `amount` of tokens is burned.
     */
    event Burned(uint amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with an admin and the address of the token.
     * @param _admin Address of the admin to be granted roles.
     * @param _token Address of the token contract.
     */
    function initialize(address _admin, IToken _token) public initializer {
        __ExtendedAccessControl_init();
        _addRole(BENEFICIARY_ROLE);
        _addRole(BENEFICIARY_LIMIT_ROLE);
        _addRole(BURN_ROLE);
        _addRole(LIMIT_ROLE);
        _addRole(MINT_ROLE);
        _addRole(TRANSFER_ROLE);
        _grantRoles(_admin);
        token = _token;
        limiter.interval = 24 hours;
    }

    /**
     * @dev Adds a beneficiary with a default 24-hour transfer limit of 0 and a default cooldown period of 24 hours.
     * Can only be called by an account with the BENEFICIARY_ROLE.
     * @param _beneficiary Address of the beneficiary to be added.
     */
    function addBeneficiary(address _beneficiary) public onlyRole(BENEFICIARY_ROLE) {
        addBeneficiary(_beneficiary, 0);
    }

    /**
     * @dev Adds a beneficiary with a specified 24-hour transfer limit and a default cooldown period of 24 hours.
     * Can only be called by an account with the BENEFICIARY_ROLE.
     * @param _beneficiary Address of the beneficiary to be added.
     * @param _limit Limit value for the beneficiary.
     */
    function addBeneficiary(address _beneficiary, uint _limit) public onlyRole(BENEFICIARY_ROLE) {
        addBeneficiary(_beneficiary, _limit, 24 hours);
    }

    /**
     * @dev Adds a beneficiary with a specified 24-hour transfer limit and specified cooldown period.
     * Can only be called by an account with the BENEFICIARY_ROLE.
     * @param _beneficiary Address of the beneficiary to be added.
     * @param _limit Limit value for the beneficiary.
     * @param _cooldown Cooldown period for the beneficiary.
     */
    function addBeneficiary(address _beneficiary, uint _limit, uint _cooldown) public onlyRole(BENEFICIARY_ROLE) {
        beneficiaries.addBeneficiary(_beneficiary, 24 hours, _limit, _cooldown);
        emit BeneficiaryAdded(_beneficiary, _limit, _cooldown);
    }

    /**
     * @dev Returns the list of all beneficiaries.
     */
    function getBeneficiaries() public view returns (Beneficiary[] memory) {
        return beneficiaries.getBeneficiaries();
    }

    /**
     * @dev Returns the details of a specific beneficiary.
     * @param _beneficiary Address of the beneficiary.
     */
    function getBeneficiary(address _beneficiary) public view returns (Beneficiary memory) {
        return beneficiaries.getBeneficiary(_beneficiary);
    }

    /**
     * @dev Returns the timestamp when a beneficiary gets enabled.
     * @param _beneficiary Address of the beneficiary.
     */
    function getBeneficiaryEnabledAt(address _beneficiary) public view returns (uint) {
        return beneficiaries.getBeneficiary(_beneficiary).enabledAt;
    }

    /**
     * @dev Returns the current 24-hour transfer limit for a specific beneficiary.
     * @param _beneficiary Address of the beneficiary.
     */
    function getBeneficiaryLimit(address _beneficiary) public view returns (uint) {
        return beneficiaries.getBeneficiary(_beneficiary).limit;
    }

    /**
     * @dev Returns the remaining 24-hour transfer limit for a specific beneficiary.
     * @param _beneficiary Address of the beneficiary.
     */
    function getBeneficiaryRemainingLimit(address _beneficiary) public view returns (int) {
        return beneficiaries.getBeneficiary(_beneficiary).remainingLimit;
    }

    /**
     * @dev Returns the list of transfers to a specific beneficiary within the last 24 hours.
     * @param _beneficiary Address of the beneficiary.
     */
    function getBeneficiaryTransfers(address _beneficiary) public view returns (Transfer[] memory) {
        return beneficiaries.getBeneficiary(_beneficiary).transfers;
    }

    /**
     * @dev Returns the current 24-hour transfer limit.
     */
    function getLimit() public view returns (uint) {
        return limiter.limit;
    }

    /**
     * @dev Returns the remaining 24-hour transfer limit.
     */
    function getRemainingLimit() public view returns (int) {
        return limiter.remainingLimit();
    }

    /**
     * @dev Returns the list of all transfers within the last 24 hours.
     */
    function getTransfers() public view returns (Transfer[] memory) {
        return limiter.transfers();
    }

    /**
     * @dev Removes a beneficiary from the list of whitelisted beneficiaries.
     * Can only be called by an account with the BENEFICIARY_ROLE.
     * @param _beneficiary Address of the beneficiary to be removed.
     */
    function removeBeneficiary(address _beneficiary) public onlyRole(BENEFICIARY_ROLE) {
        beneficiaries.removeBeneficiary(_beneficiary);
        emit BeneficiaryRemoved(_beneficiary);
    }

    /**
     * @dev Sets the 24-hour transfer limit for a specific beneficiary.
     * Can only be called by an account with the BENEFICIARY_LIMIT_ROLE.
     * @param _beneficiary Address of the beneficiary.
     * @param _limit The limit value to be set for the beneficiary.
     */
    function setBeneficiaryLimit(address _beneficiary, uint _limit) public onlyRole(BENEFICIARY_LIMIT_ROLE) {
        beneficiaries.setBeneficiaryLimit(_beneficiary, _limit);
        emit BeneficiaryLimitChanged(_beneficiary, _limit);
    }

    /**
     * @dev Sets the 24-hour transfer limit.
     * Can only be called by an account with the LIMIT_ROLE.
     * @param _limit The limit value to be set.
     */
    function setLimit(uint _limit) public onlyRole(LIMIT_ROLE) {
        limiter.limit = _limit;
        emit LimitChanged(_limit);
    }

    /**
     * @dev Temporarily increases the 24-hour transfer limiter for a specific beneficiary.
     * Can only be called by an account with the BENEFICIARY_LIMIT_ROLE.
     * @param _beneficiary Address of the beneficiary.
     * @param _limitIncrease Amount by which the limit should be increased.
     */
    function temporarilyIncreaseBeneficiaryLimit(
        address _beneficiary,
        uint _limitIncrease
    ) public onlyRole(BENEFICIARY_LIMIT_ROLE) {
        beneficiaries.temporarilyIncreaseBeneficiaryLimit(_beneficiary, _limitIncrease);
        emit BeneficiaryLimitTemporarilyIncreased(_beneficiary, _limitIncrease);
    }

    /**
     * @dev Temporarily decreases the 24-hour transfer limiter for a specific beneficiary.
     * Can only be called by an account with the BENEFICIARY_LIMIT_ROLE.
     * @param _beneficiary Address of the beneficiary.
     * @param _limitDecrease Amount by which the limit should be decreased.
     */
    function temporarilyDecreaseBeneficiaryLimit(
        address _beneficiary,
        uint _limitDecrease
    ) public onlyRole(BENEFICIARY_LIMIT_ROLE) {
        beneficiaries.temporarilyDecreaseBeneficiaryLimit(_beneficiary, _limitDecrease);
        emit BeneficiaryLimitTemporarilyDecreased(_beneficiary, _limitDecrease);
    }

    /**
     * @dev Temporarily increases the 24-hour transfer limiter.
     * Can only be called by an account with the LIMIT_ROLE.
     * @param _limitIncrease Amount by which the limit should be increased.
     */
    function temporarilyIncreaseLimit(uint _limitIncrease) public onlyRole(LIMIT_ROLE) {
        limiter.temporarilyIncreaseLimit(_limitIncrease);
        emit LimitTemporarilyIncreased(_limitIncrease);
    }

    /**
     * @dev Temporarily decreases the 24-hour transfer limiter.
     * Can only be called by an account with the LIMIT_ROLE.
     * @param _limitDecrease Amount by which the limit should be decreased.
     */
    function temporarilyDecreaseLimit(uint _limitDecrease) public onlyRole(LIMIT_ROLE) {
        limiter.temporarilyDecreaseLimit(_limitDecrease);
        emit LimitTemporarilyDecreased(_limitDecrease);
    }

    /**
     * @dev Transfers the token to a specified beneficiary, subject to 24 hours limits.
     * Can only be called by an account with the TRANSFER_ROLE.
     * @param _beneficiary Address of the beneficiary to receive the tokens.
     * @param _amount Amount of tokens to be transferred.
     */
    function transfer(address _beneficiary, uint _amount) public onlyRole(TRANSFER_ROLE) {
        if (!limiter.addTransfer(_amount)) {
            revert LimitExceeded();
        }
        beneficiaries.addBeneficiaryTransfer(_beneficiary, _amount);
        token.transfer(_beneficiary, _amount);
        emit Transferred(_beneficiary, _amount);
    }

    /**
     * @dev Transfers a specified token to a specified address.
     * Can only be called by an account with the DEFAULT_ADMIN_ROLE.
     * @param _token Token to be transferred.
     * @param _to Address to receive the tokens.
     * @param _amount Amount of tokens to be transferred.
     */
    function transfer(IERC20 _token, address _to, uint _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _token.transfer(_to, _amount);
        emit Transferred(_token, _to, _amount);
    }

    /**
     * @dev Mints tokens to the wallet.
     * Can only be called by an account with the MINT_ROLE.
     * @param _amount Amount of tokens to be minted.
     */
    function mint(uint _amount) public onlyRole(MINT_ROLE) {
        token.mint(_amount);
        emit Minted(_amount);
    }

    /**
     * @dev Burns tokens from the wallet.
     * Can only be called by an account with the BURN_ROLE.
     * @param _amount Amount of tokens to be minted.
     */
    function burn(uint _amount) public onlyRole(BURN_ROLE) {
        token.burn(_amount);
        emit Burned(_amount);
    }
}