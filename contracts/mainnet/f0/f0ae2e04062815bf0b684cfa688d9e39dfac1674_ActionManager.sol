// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/IAction.sol";
import "../interfaces/CommonErrors.sol";
import "../interfaces/Constants.sol";
import "../access/SpoolAccessControllable.sol";

contract ActionManager is IActionManager, SpoolAccessControllable {
    /* ========== STATE VARIABLES ========== */

    /// @notice True if actions for given smart vault were already initialized
    mapping(address => bool) public actionsInitialized;

    /// @notice Action address whitelist
    mapping(address => bool) public actionWhitelisted;

    /// @notice Action registry
    mapping(address => mapping(RequestType => address[])) public actions;

    constructor(ISpoolAccessControl accessControl) SpoolAccessControllable(accessControl) {}

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice Set executable actions for given smart vault
     * @param smartVault SmartVault address
     * @param actions_ array of actions
     * @param requestTypes when an action should be triggered
     */
    function setActions(address smartVault, IAction[] calldata actions_, RequestType[] calldata requestTypes)
        external
        onlyRole(ROLE_SMART_VAULT_INTEGRATOR, msg.sender)
    {
        _checkInitialized(smartVault);

        if (actions_.length != requestTypes.length) {
            revert InvalidArrayLength();
        }

        for (uint256 i; i < actions_.length; ++i) {
            IAction action = actions_[i];
            _onlyWhitelistedAction(address(action));
            actions[smartVault][requestTypes[i]].push(address(action));

            if (actions[smartVault][requestTypes[i]].length > MAX_ACTION_COUNT) {
                revert TooManyActions();
            }

            if (requestTypes[i] != RequestType.Deposit && requestTypes[i] != RequestType.Withdrawal) {
                revert WrongActionRequestType(requestTypes[i]);
            }

            emit ActionSet(smartVault, address(action), requestTypes[i]);
        }

        actionsInitialized[smartVault] = true;
    }

    /**
     * @notice Run actions for smart vault with given context
     * @param actionCtx action execution context
     */
    function runActions(ActionContext calldata actionCtx) external onlyRole(ROLE_SMART_VAULT_MANAGER, msg.sender) {
        if (!_actionsExist(actionCtx.smartVault, actionCtx.requestType)) {
            return;
        }

        address[] memory actions_ = actions[actionCtx.smartVault][actionCtx.requestType];

        for (uint256 i; i < actions_.length; ++i) {
            _executeAction(actions_[i], actionCtx);
        }
    }

    /**
     * @notice Whitelist an action address
     * @param action Action address
     * @param whitelist Whether to whitelist or not
     */
    function whitelistAction(address action, bool whitelist) external onlyRole(ROLE_SPOOL_ADMIN, msg.sender) {
        if (actionWhitelisted[action] == whitelist) revert ActionStatusAlreadySet();
        actionWhitelisted[action] = whitelist;

        emit ActionListed(action, whitelist);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _actionsExist(address smartVault, RequestType requestType) private view returns (bool) {
        return actions[smartVault][requestType].length > 0;
    }

    function _executeAction(address action_, ActionContext memory actionCtx) private {
        IAction(action_).executeAction(actionCtx);
    }

    function _checkInitialized(address smartVault) private view {
        if (actionsInitialized[smartVault]) {
            revert ActionsAlreadyInitialized({smartVault: smartVault});
        }
    }

    function _onlyWhitelistedAction(address action) private view {
        if (!actionWhitelisted[action]) {
            revert InvalidAction({address_: action});
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./RequestType.sol";

/**
 * @notice Used when trying to set an invalid action for a smart vault.
 * @param address_ Address of the invalid action.
 */
error InvalidAction(address address_);

/**
 * @notice Used when trying to whitelist already whitelisted action.
 */
error ActionStatusAlreadySet();

/**
 * @notice Used when trying to set actions for smart vault that already has actions set.
 */
error ActionsAlreadyInitialized(address smartVault);

/**
 * @notice Too many actions have been passed when creating a vault.
 */
error TooManyActions();

/**
 * @notice Used when wrong request type is set for an action.
 * @param requestType Wrong request type.
 */
error WrongActionRequestType(RequestType requestType);

/**
 * @notice Represents a context that is sent to actions.
 * @custom:member smartVault Smart vault address
 * @custom:member recipient In case of deposit, recipient of deposit NFT; in case of withdrawal, recipient of assets.
 * @custom:member executor In case of deposit, executor of deposit action; in case of withdrawal, executor of claimWithdrawal action.
 * @custom:member owner In case of deposit, owner of assets; in case of withdrawal, owner of withdrawal NFT.
 * @custom:member requestType Request type that triggered the action.
 * @custom:member tokens Tokens involved.
 * @custom:member amount Amount of tokens.
 */
struct ActionContext {
    address smartVault;
    address recipient;
    address executor;
    address owner;
    RequestType requestType;
    address[] tokens;
    uint256[] amounts;
}

interface IAction {
    /**
     * @notice Executes the action.
     * @param actionCtx Context for action execution.
     */
    function executeAction(ActionContext calldata actionCtx) external;
}

interface IActionManager {
    /**
     * @notice Sets actions for a smart vault.
     * @dev Requirements:
     * - caller needs role ROLE_SMART_VAULT_INTEGRATOR
     * @param smartVault Smart vault for which the actions will be set.
     * @param actions Actions to set.
     * @param requestTypes Specifies for each action, which request type triggers that action.
     */
    function setActions(address smartVault, IAction[] calldata actions, RequestType[] calldata requestTypes) external;

    /**
     * @notice Runs actions for a smart vault.
     * @dev Requirements:
     * - caller needs role ROLE_SMART_VAULT_MANAGER
     * @param actionCtx Execution context for the actions.
     */
    function runActions(ActionContext calldata actionCtx) external;

    /**
     * @notice Adds or removes an action from the whitelist.
     * @dev Requirements:
     * - caller needs role ROLE_SPOOL_ADMIN
     * @param action Address of an action to add or remove from the whitelist.
     * @param whitelist If true, action will be added to the whitelist, if false, it will be removed from it.
     */
    function whitelistAction(address action, bool whitelist) external;

    /**
     * @notice Emitted when an action is added or removed from the whitelist.
     * @param action Address of the action that was added or removed from the whitelist.
     * @param whitelisted True if it was added, false if it was removed from the whitelist.
     */
    event ActionListed(address indexed action, bool whitelisted);

    /**
     * @notice Emitted when an action is set for a vault
     * @param smartVault Address of the smart vault
     * @param action Address of the action that was added
     * @param requestType Trigger for executing the action
     */
    event ActionSet(address indexed smartVault, address indexed action, RequestType requestType);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @notice Used when an array has invalid length.
 */
error InvalidArrayLength();

/**
 * @notice Used when group of smart vaults or strategies do not have same asset group.
 */
error NotSameAssetGroup();

/**
 * @notice Used when configuring an address with a zero address.
 */
error ConfigurationAddressZero();

/**
 * @notice Used when constructor or intializer parameters are invalid.
 */
error InvalidConfiguration();

/**
 * @notice Used when fetched exchange rate is out of slippage range.
 */
error ExchangeRateOutOfSlippages();

/**
 * @notice Used when an invalid strategy is provided.
 * @param address_ Address of the invalid strategy.
 */
error InvalidStrategy(address address_);

/**
 * @notice Used when doing low-level call on an address that is not a contract.
 * @param address_ Address of the contract
 */
error AddressNotContract(address address_);

/**
 * @notice Used when invoking an only view execution and tx.origin is not address zero.
 * @param address_ Address of the tx.origin
 */
error OnlyViewExecution(address address_);

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev Number of seconds in an average year.
uint256 constant SECONDS_IN_YEAR = 31_556_926;

/// @dev Number of seconds in an average year.
int256 constant SECONDS_IN_YEAR_INT = 31_556_926;

/// @dev Represents 100%.
uint256 constant FULL_PERCENT = 100_00;

/// @dev Represents 100%.
int256 constant FULL_PERCENT_INT = 100_00;

/// @dev Represents 100% for yield.
int256 constant YIELD_FULL_PERCENT_INT = 10 ** 12;

/// @dev Represents 100% for yield.
uint256 constant YIELD_FULL_PERCENT = uint256(YIELD_FULL_PERCENT_INT);

/// @dev Maximal management fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant MANAGEMENT_FEE_MAX = 5_00;

/// @dev Maximal deposit fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant DEPOSIT_FEE_MAX = 5_00;

/// @dev Maximal smart vault performance fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant SV_PERFORMANCE_FEE_MAX = 20_00;

/// @dev Maximal ecosystem fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant ECOSYSTEM_FEE_MAX = 20_00;

/// @dev Maximal treasury fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant TREASURY_FEE_MAX = 10_00;

/// @dev Maximal risk score a strategy can be assigned.
uint8 constant MAX_RISK_SCORE = 10_0;

/// @dev Minimal risk score a strategy can be assigned.
uint8 constant MIN_RISK_SCORE = 1;

/// @dev Maximal value for risk tolerance a smart vautl can have.
int8 constant MAX_RISK_TOLERANCE = 10;

/// @dev Minimal value for risk tolerance a smart vault can have.
int8 constant MIN_RISK_TOLERANCE = -10;

/// @dev If set as risk provider, system will return fixed risk score values
address constant STATIC_RISK_PROVIDER = address(0xaaa);

/// @dev Fixed values to use if risk provider is set to STATIC_RISK_PROVIDER
uint8 constant STATIC_RISK_SCORE = 1;

/// @dev Maximal value of deposit NFT ID.
uint256 constant MAXIMAL_DEPOSIT_ID = 2 ** 255;

/// @dev Maximal value of withdrawal NFT ID.
uint256 constant MAXIMAL_WITHDRAWAL_ID = 2 ** 256 - 1;

/// @dev How many shares will be minted with a NFT
uint256 constant NFT_MINTED_SHARES = 10 ** 6;

/// @dev Each smart vault can have up to STRATEGY_COUNT_CAP strategies.
uint256 constant STRATEGY_COUNT_CAP = 16;

/// @dev Maximal DHW base yield. Expressed in terms of FULL_PERCENT.
uint256 constant MAX_DHW_BASE_YIELD_LIMIT = 10_00;

/// @dev Smart vault and strategy share multiplier at first deposit.
uint256 constant INITIAL_SHARE_MULTIPLIER = 1000;

/// @dev Strategy initial locked shares. These shares will never be unlocked.
uint256 constant INITIAL_LOCKED_SHARES = 10 ** 12;

/// @dev Strategy initial locked shares address.
address constant INITIAL_LOCKED_SHARES_ADDRESS = address(0xdead);

/// @dev Maximum number of guards a smart vault can be configured with
uint256 constant MAX_GUARD_COUNT = 10;

/// @dev Maximum number of actions a smart vault can be configured with
uint256 constant MAX_ACTION_COUNT = 10;

/// @dev ID of null asset group. Should not be used by any strategy or smart vault.
uint256 constant NULL_ASSET_GROUP_ID = 0;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/ISpoolAccessControl.sol";
import "../interfaces/CommonErrors.sol";
import "./Roles.sol";

/**
 * @notice Account access role verification middleware
 */
abstract contract SpoolAccessControllable {
    /* ========== CONSTANTS ========== */

    /**
     * @dev Spool access control manager.
     */
    ISpoolAccessControl internal immutable _accessControl;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param accessControl_ Spool access control manager.
     */
    constructor(ISpoolAccessControl accessControl_) {
        if (address(accessControl_) == address(0)) revert ConfigurationAddressZero();

        _accessControl = accessControl_;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @dev Reverts if an account is missing a role.\
     * @param role Role to check for.
     * @param account Account to check.
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_accessControl.hasRole(role, account)) {
            revert MissingRole(role, account);
        }
    }

    /**
     * @dev Revert if an account is missing a role for a smartVault.
     * @param smartVault Address of the smart vault.
     * @param role Role to check for.
     * @param account Account to check.
     */
    function _checkSmartVaultRole(address smartVault, bytes32 role, address account) internal view {
        if (!_accessControl.hasSmartVaultRole(smartVault, role, account)) {
            revert MissingRole(role, account);
        }
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (_accessControl.paused()) {
            revert SystemPaused();
        }
    }

    function _checkNonReentrant() internal view {
        _accessControl.checkNonReentrant();
    }

    function _nonReentrantBefore() internal {
        _accessControl.nonReentrantBefore();
    }

    function _nonReentrantAfter() internal {
        _accessControl.nonReentrantAfter();
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Only allows accounts with granted role.
     * @dev Reverts when the account fails check.
     * @param role Role to check for.
     * @param account Account to check.
     */
    modifier onlyRole(bytes32 role, address account) {
        _checkRole(role, account);
        _;
    }

    /**
     * @notice Only allows accounts with granted role for a smart vault.
     * @dev Reverts when the account fails check.
     * @param smartVault Address of the smart vault.
     * @param role Role to check for.
     * @param account Account to check.
     */
    modifier onlySmartVaultRole(address smartVault, bytes32 role, address account) {
        _checkSmartVaultRole(smartVault, role, account);
        _;
    }

    /**
     * @notice Only allows accounts that are Spool admins or admins of a smart vault.
     * @dev Reverts when the account fails check.
     * @param smartVault Address of the smart vault.
     * @param account Account to check.
     */
    modifier onlyAdminOrVaultAdmin(address smartVault, address account) {
        _accessControl.checkIsAdminOrVaultAdmin(smartVault, account);
        _;
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
     * @dev Prevents a contract from calling itself, or other contracts using this modifier.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    /**
     * @dev Check if a system has already entered in the non-reentrant state.
     */
    modifier checkNonReentrant() {
        _checkNonReentrant();
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @notice Different request types for guards and actions.
 * @custom:member Deposit User is depositing into a smart vault.
 * @custom:member Withdrawal User is requesting withdrawal from a smart vault.
 * @custom:member TransferNFT User is transfering deposit or withdrawal NFT.
 * @custom:member BurnNFT User is burning deposit or withdrawal NFT.
 * @custom:member TransferSVTs User is transferring smart vault tokens.
 */
enum RequestType {
    Deposit,
    Withdrawal,
    TransferNFT,
    BurnNFT,
    TransferSVTs
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/access/IAccessControlUpgradeable.sol";

/**
 * @notice Used when an account is missing a required role.
 * @param role Required role.
 * @param account Account missing the required role.
 */
error MissingRole(bytes32 role, address account);

/**
 * @notice Used when interacting with Spool when the system is paused.
 */
error SystemPaused();

/**
 * @notice Used when setting smart vault owner
 */
error SmartVaultOwnerAlreadySet(address smartVault);

/**
 * @notice Used when a contract tries to enter in a non-reentrant state.
 */
error ReentrantCall();

/**
 * @notice Used when a contract tries to call in a non-reentrant function and doesn't have the correct role.
 */
error NoReentrantRole();

interface ISpoolAccessControl is IAccessControlUpgradeable {
    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets owner of a smart vault.
     * @param smartVault Smart vault.
     * @return owner Owner of the smart vault.
     */
    function smartVaultOwner(address smartVault) external view returns (address owner);

    /**
     * @notice Looks if an account has a role for a smart vault.
     * @param smartVault Address of the smart vault.
     * @param role Role to look for.
     * @param account Account to check.
     * @return hasRole True if account has the role for the smart vault, false otherwise.
     */
    function hasSmartVaultRole(address smartVault, bytes32 role, address account)
        external
        view
        returns (bool hasRole);

    /**
     * @notice Checks if an account is either Spool admin or admin for a smart vault.
     * @dev The function reverts if account is neither.
     * @param smartVault Address of the smart vault.
     * @param account to check.
     */
    function checkIsAdminOrVaultAdmin(address smartVault, address account) external view;

    /**
     * @notice Checks if system is paused or not.
     * @return isPaused True if system is paused, false otherwise.
     */
    function paused() external view returns (bool isPaused);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Pauses the whole system.
     * @dev Requirements:
     * - caller must have role ROLE_PAUSER
     */
    function pause() external;

    /**
     * @notice Unpauses the whole system.
     * @dev Requirements:
     * - caller must have role ROLE_UNPAUSER
     */
    function unpause() external;

    /**
     * @notice Grants role to an account for a smart vault.
     * @dev Requirements:
     * - caller must have either role ROLE_SPOOL_ADMIN or role ROLE_SMART_VAULT_ADMIN for the smart vault
     * @param smartVault Address of the smart vault.
     * @param role Role to grant.
     * @param account Account to grant the role to.
     */
    function grantSmartVaultRole(address smartVault, bytes32 role, address account) external;

    /**
     * @notice Revokes role from an account for a smart vault.
     * @dev Requirements:
     * - caller must have either role ROLE_SPOOL_ADMIN or role ROLE_SMART_VAULT_ADMIN for the smart vault
     * @param smartVault Address of the smart vault.
     * @param role Role to revoke.
     * @param account Account to revoke the role from.
     */
    function revokeSmartVaultRole(address smartVault, bytes32 role, address account) external;

    /**
     * @notice Renounce role for a smart vault.
     * @param smartVault Address of the smart vault.
     * @param role Role to renounce.
     */
    function renounceSmartVaultRole(address smartVault, bytes32 role) external;

    /**
     * @notice Grant ownership to smart vault and assigns admin role.
     * @dev Ownership can only be granted once and it should be done at vault creation time.
     * @param smartVault Address of the smart vault.
     * @param owner address to which grant ownership to
     */
    function grantSmartVaultOwnership(address smartVault, address owner) external;

    /**
     * @notice Checks and reverts if a system has already entered in the non-reentrant state.
     */
    function checkNonReentrant() external view;

    /**
     * @notice Sets the entered flag to true when entering for the first time.
     * @dev Reverts if a system has already entered before.
     */
    function nonReentrantBefore() external;

    /**
     * @notice Resets the entered flag after the call is finished.
     */
    function nonReentrantAfter() external;

    /**
     * @notice Emitted when ownership of a smart vault is granted to an address
     * @param smartVault Smart vault address
     * @param address_ Address of the new smart vault owner
     */
    event SmartVaultOwnershipGranted(address indexed smartVault, address indexed address_);

    /**
     * @notice Smart vault specific role was granted
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account to which the role was granted
     */
    event SmartVaultRoleGranted(address indexed smartVault, bytes32 indexed role, address indexed account);

    /**
     * @notice Smart vault specific role was revoked
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account for which the role was revoked
     */
    event SmartVaultRoleRevoked(address indexed smartVault, bytes32 indexed role, address indexed account);

    /**
     * @notice Smart vault specific role was renounced
     * @param smartVault Smart vault address
     * @param role Role ID
     * @param account Account that renounced the role
     */
    event SmartVaultRoleRenounced(address indexed smartVault, bytes32 indexed role, address indexed account);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @dev Grants permission to:
 * - acts as a default admin for other roles,
 * - can whitelist an action with action manager,
 * - can manage asset group registry.
 *
 * Is granted to the deployer of the SpoolAccessControl contract.
 *
 * Equals to the DEFAULT_ADMIN_ROLE of the OpenZeppelin AccessControl.
 */
bytes32 constant ROLE_SPOOL_ADMIN = 0x00;

/**
 * @dev Grants permission to integrate a new smart vault into the Spool ecosystem.
 *
 * Should be granted to smart vault factory contracts.
 */
bytes32 constant ROLE_SMART_VAULT_INTEGRATOR = keccak256("SMART_VAULT_INTEGRATOR");

/**
 * @dev Grants permission to
 * - manage rewards on smart vaults,
 * - manage roles on smart vaults,
 * - redeem for another user of a smart vault.
 */
bytes32 constant ROLE_SMART_VAULT_ADMIN = keccak256("SMART_VAULT_ADMIN");

/**
 * @dev Grants permission to manage allowlists with AllowlistGuard for a smart vault.
 *
 * Should be granted to whoever is in charge of maintaining allowlists with AllowlistGuard for a smart vault.
 */
bytes32 constant ROLE_GUARD_ALLOWLIST_MANAGER = keccak256("GUARD_ALLOWLIST_MANAGER");

/**
 * @dev Grants permission to manage assets on master wallet.
 *
 * Should be granted to:
 * - the SmartVaultManager contract,
 * - the StrategyRegistry contract,
 * - the DepositManager contract,
 * - the WithdrawalManager contract.
 */
bytes32 constant ROLE_MASTER_WALLET_MANAGER = keccak256("MASTER_WALLET_MANAGER");

/**
 * @dev Marks a contract as a smart vault manager.
 *
 * Should be granted to:
 * - the SmartVaultManager contract,
 * - the DepositManager contract.
 */
bytes32 constant ROLE_SMART_VAULT_MANAGER = keccak256("SMART_VAULT_MANAGER");

/**
 * @dev Marks a contract as a strategy registry.
 *
 * Should be granted to the StrategyRegistry contract.
 */
bytes32 constant ROLE_STRATEGY_REGISTRY = keccak256("STRATEGY_REGISTRY");

/**
 * @dev Grants permission to act as a risk provider.
 *
 * Should be granted to whoever is allowed to provide risk scores.
 */
bytes32 constant ROLE_RISK_PROVIDER = keccak256("RISK_PROVIDER");

/**
 * @dev Grants permission to act as an allocation provider.
 *
 * Should be granted to contracts that are allowed to calculate allocations.
 */
bytes32 constant ROLE_ALLOCATION_PROVIDER = keccak256("ALLOCATION_PROVIDER");

/**
 * @dev Grants permission to pause the system.
 */
bytes32 constant ROLE_PAUSER = keccak256("SYSTEM_PAUSER");

/**
 * @dev Grants permission to unpause the system.
 */
bytes32 constant ROLE_UNPAUSER = keccak256("SYSTEM_UNPAUSER");

/**
 * @dev Grants permission to manage rewards payment pool.
 */
bytes32 constant ROLE_REWARD_POOL_ADMIN = keccak256("REWARD_POOL_ADMIN");

/**
 * @dev Grants permission to reallocate smart vaults.
 */
bytes32 constant ROLE_REALLOCATOR = keccak256("REALLOCATOR");

/**
 * @dev Grants permission to be used as a strategy.
 */
bytes32 constant ROLE_STRATEGY = keccak256("STRATEGY");

/**
 * @dev Grants permission to manually set strategy apy.
 */
bytes32 constant ROLE_STRATEGY_APY_SETTER = keccak256("STRATEGY_APY_SETTER");

/**
 * @dev Grants permission to manage role ROLE_STRATEGY.
 */
bytes32 constant ADMIN_ROLE_STRATEGY = keccak256("ADMIN_STRATEGY");

/**
 * @dev Grants permission vault admins to allow redeem on behalf of other users.
 */
bytes32 constant ROLE_SMART_VAULT_ALLOW_REDEEM = keccak256("SMART_VAULT_ALLOW_REDEEM");

/**
 * @dev Grants permission to manage role ROLE_SMART_VAULT_ALLOW_REDEEM.
 */
bytes32 constant ADMIN_ROLE_SMART_VAULT_ALLOW_REDEEM = keccak256("ADMIN_SMART_VAULT_ALLOW_REDEEM");

/**
 * @dev Grants permission to run do hard work.
 */
bytes32 constant ROLE_DO_HARD_WORKER = keccak256("DO_HARD_WORKER");

/**
 * @dev Grants permission to immediately withdraw assets in case of emergency.
 */
bytes32 constant ROLE_EMERGENCY_WITHDRAWAL_EXECUTOR = keccak256("EMERGENCY_WITHDRAWAL_EXECUTOR");

/**
 * @dev Grants permission to swap with swapper.
 *
 * Should be granted to the DepositSwap contract.
 */
bytes32 constant ROLE_SWAPPER = keccak256("SWAPPER");

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