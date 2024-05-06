/**
                                             .::.
                                          .=***#*+:
                                        .=*********+.
                                      .=++++*********=.
                                    .=++=++++++++******-
                                  .=++=++++++++++++******-
                                .=++==+++++++++++==+******+:
                              .=+===+++++++++++++===+*******=
                            .=+===+++++++++++++++===-=*******=
                           .=====++++++++++++++++====-=*****#*.
                           :-===++++++++++++++++++====--+*###=
                          :==+++++++++++++++++++++====---=+*-
                        :=++***************++++++++====--:-
                      .-+*########*************++++++===-:
                     .=##%%##################*****++++===-.
                     =#%%%%%%###########%%#######***+++==--
                     +%@@#****************##%%%#####**++==-.
                     -%#==*##**********##*****#%%%####**+==:
                      *-=*%+##*******##%@@#******#%%###**+=-
                      :=+%%#@%******#%=*@@%*********#%##*++-
                      :=*%@@@**####*#@@@@@%********++*###*+.
                      =+**##*#######*#@@@%#####****++++**+-
                +*-  .+**#**#########*****######****+++=+-
               -#**+:-**++**########***###%%%%##**+++++=.
             ::-**+-=*#*=+**#######***#*###%%%##**++++*+=         :=-
            -###****##%==+**######*******#######**+===*#*+-::::-=*##*
            .#%#******==+***##%%%#********######**++==+%%%##**#####%*
              +#%##******###%%%####****+++*#%%%##*********#%%%%%%%%*.
               :%%%%%%%#%%%%###=.+##**********##########%%##%%%###=
                 #%#%%%%%##**=.  :########%%#:-**#%%%%%##*+++*+-:
                  ::+#**#+=-.     =#%%%%#%%#*.  :=*****=:
                                   :+##*##+=       ..
                                     :-.::

*/
// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IRouter.sol";

/**
 * @title Router Contract
 * @dev Contract that holds addresses of crucial subsquid contracts
 * Contract is designed to be upgradeable
 * All setters can only be called by admin
 */
contract Router is Initializable, AccessControl, IRouter {
  IWorkerRegistration public workerRegistration;
  IStaking public staking;
  address public rewardTreasury;
  INetworkController public networkController;
  IRewardCalculation public rewardCalculation;

  event WorkerRegistrationSet(IWorkerRegistration workerRegistration);
  event StakingSet(IStaking staking);
  event RewardTreasurySet(address rewardTreasury);
  event NetworkControllerSet(INetworkController networkController);
  event RewardCalculationSet(IRewardCalculation rewardCalculation);

  function initialize(
    IWorkerRegistration _workerRegistration,
    IStaking _staking,
    address _rewardTreasury,
    INetworkController _networkController,
    IRewardCalculation _rewardCalculation
  ) external initializer {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    workerRegistration = _workerRegistration;
    staking = _staking;
    rewardTreasury = _rewardTreasury;
    networkController = _networkController;
    rewardCalculation = _rewardCalculation;
  }

  function setWorkerRegistration(IWorkerRegistration _workerRegistration) external onlyRole(DEFAULT_ADMIN_ROLE) {
    workerRegistration = _workerRegistration;

    emit WorkerRegistrationSet(_workerRegistration);
  }

  function setStaking(IStaking _staking) external onlyRole(DEFAULT_ADMIN_ROLE) {
    staking = _staking;

    emit StakingSet(_staking);
  }

  function setRewardTreasury(address _rewardTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
    rewardTreasury = _rewardTreasury;

    emit RewardTreasurySet(_rewardTreasury);
  }

  function setNetworkController(INetworkController _networkController) external onlyRole(DEFAULT_ADMIN_ROLE) {
    networkController = _networkController;

    emit NetworkControllerSet(_networkController);
  }

  function setRewardCalculation(IRewardCalculation _rewardCalculation) external onlyRole(DEFAULT_ADMIN_ROLE) {
    rewardCalculation = _rewardCalculation;

    emit RewardCalculationSet(_rewardCalculation);
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
// OpenZeppelin Contracts (last updated v5.0.0) (access/AccessControl.sol)

pragma solidity ^0.8.20;

import {IAccessControl} from "./IAccessControl.sol";
import {Context} from "../utils/Context.sol";
import {ERC165} from "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    mapping(bytes32 role => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with an {AccessControlUnauthorizedAccount} error including the required role.
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
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
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
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
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
        if (hasRole(role, account)) {
            _roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

import "./IWorkerRegistration.sol";
import "./IStaking.sol";
import "./INetworkController.sol";
import "./IRewardCalculation.sol";

interface IRouter {
  function workerRegistration() external view returns (IWorkerRegistration);
  function staking() external view returns (IStaking);
  function rewardTreasury() external view returns (address);
  function networkController() external view returns (INetworkController);
  function rewardCalculation() external view returns (IRewardCalculation);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/IAccessControl.sol)

pragma solidity ^0.8.20;

/**
 * @dev External interface of AccessControl declared to support ERC-165 detection.
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC-165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

interface IWorkerRegistration {
  /// @dev Emitted when a worker is registered
  event WorkerRegistered(
    uint256 indexed workerId, bytes peerId, address indexed registrar, uint256 registeredAt, string metadata
  );

  /// @dev Emitted when a worker is deregistered
  event WorkerDeregistered(uint256 indexed workerId, address indexed account, uint256 deregistedAt);

  /// @dev Emitted when the bond is withdrawn
  event WorkerWithdrawn(uint256 indexed workerId, address indexed account);

  /// @dev Emitted when a excessive bond is withdrawn
  event ExcessiveBondReturned(uint256 indexed workerId, uint256 amount);

  /// @dev Emitted when metadata is updated
  event MetadataUpdated(uint256 indexed workerId, string metadata);

  function register(bytes calldata peerId, string calldata metadata) external;

  /// @return The number of active workers.
  function getActiveWorkerCount() external view returns (uint256);
  function getActiveWorkerIds() external view returns (uint256[] memory);

  /// @return The ids of all worker created by the owner account
  function getOwnedWorkers(address who) external view returns (uint256[] memory);

  function nextWorkerId() external view returns (uint256);

  function isWorkerActive(uint256 workerId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

interface IStaking {
  struct StakerRewards {
    /// @dev the sum of (amount_i / totalStaked_i) for each distribution of amount_i when totalStaked_i was staked
    uint256 cumulatedRewardsPerShare;
    /// @dev the value of cumulatedRewardsPerShare when the user's last action was performed (deposit or withdraw)
    mapping(address staker => uint256) checkpoint;
    /// @dev the amount of tokens staked by the user
    mapping(address staker => uint256) depositAmount;
    /// @dev block from which withdraw is allowed for staker
    mapping(address staker => uint128) withdrawAllowed;
    /// @dev the total amount of tokens staked
    uint256 totalStaked;
  }

  /// @dev Emitted when rewards where distributed by the distributor
  event Distributed(uint256 epoch);
  /// @dev Emitted when a staker delegates amount to the worker
  event Deposited(uint256 indexed worker, address indexed staker, uint256 amount);
  /// @dev Emitted when a staker undelegates amount to the worker
  event Withdrawn(uint256 indexed worker, address indexed staker, uint256 amount);
  /// @dev Emitted when new claimable reward arrives
  event Rewarded(uint256 indexed workerId, address indexed staker, uint256 amount);
  /// @dev Emitted when a staker claims rewards
  event Claimed(address indexed staker, uint256 amount, uint256[] workerIds);
  /// @dev Emitted when max delegations is changed
  event EpochsLockChanged(uint128 epochsLock);

  event MaxDelegationsChanged(uint256 maxDelegations);

  /// @dev Deposit amount of tokens in favour of a worker
  /// @param worker workerId in WorkerRegistration contract
  /// @param amount amount of tokens to deposit
  function deposit(uint256 worker, uint256 amount) external;

  /// @dev Withdraw amount of tokens staked in favour of a worker
  /// @param worker workerId in WorkerRegistration contract
  /// @param amount amount of tokens to withdraw
  function withdraw(uint256 worker, uint256 amount) external;

  /// @dev Claim rewards for a staker
  /// @return amount of tokens claimed
  function claim(address staker) external returns (uint256);

  /// @return claimable amount
  /// MUST return same value as claim(address staker) but without modifying state
  function claimable(address staker) external view returns (uint256);

  /// @dev total staked amount for the worker
  function delegated(uint256 worker) external view returns (uint256);

  /// @dev Distribute tokens to stakers in favour of a worker
  /// @param workers array of workerIds in WorkerRegistration contract
  /// @param amounts array of amounts of tokens to distribute for i-th worker
  function distribute(uint256[] calldata workers, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

interface INetworkController {
  /// @dev Emitted when epoch length is updated
  event EpochLengthUpdated(uint128 epochLength);
  /// @dev Emitted when bond amount is updated
  event BondAmountUpdated(uint256 bondAmount);
  /// @dev Emitted when storage per worker is updated
  event StoragePerWorkerInGbUpdated(uint128 storagePerWorkerInGb);
  event StakingDeadlockUpdated(uint256 stakingDeadlock);
  event AllowedVestedTargetUpdated(address target, bool isAllowed);
  event TargetCapacityUpdated(uint256 target);
  event RewardCoefficientUpdated(uint256 coefficient);

  /// @dev Amount of blocks in one epoch
  function epochLength() external view returns (uint128);

  /// @dev Amount of tokens required to register a worker
  function bondAmount() external view returns (uint256);

  /// @dev Block when next epoch starts
  function nextEpoch() external view returns (uint128);

  /// @dev Number of current epoch (starting from 0 when contract is deployed)
  function epochNumber() external view returns (uint128);

  /// @dev Number of unrewarded epochs after which staking will be blocked
  function stakingDeadlock() external view returns (uint256);

  /// @dev Number of current epoch (starting from 0 when contract is deployed)
  function targetCapacityGb() external view returns (uint256);

  /// @dev Amount of storage in GB each worker is expected to provide
  function storagePerWorkerInGb() external view returns (uint128);

  /// @dev Can the `target` be used as a called by the vesting contract
  function isAllowedVestedTarget(address target) external view returns (bool);

  /// @dev Max part of initial reward pool that can be allocated during a year, in basis points
  /// example: 3000 will mean that on each epoch, max 30% of the initial pool * epoch length / 1 year can be allocated
  function yearlyRewardCapCoefficient() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.20;

interface IRewardCalculation {
  function currentApy() external view returns (uint256);

  function boostFactor(uint256 duration) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
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
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}